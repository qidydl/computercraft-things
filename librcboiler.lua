-- librcboiler.lua
-- lib-Railcraft-Boiler
--
-- A library for monitoring Railcraft boilers and generating events based on detected changes.
--

os.loadAPI("libccclass")
os.loadAPI("libccevent")

BoilerMonitor = libccclass.class(function (this, side, boilerName, alerts)
	this._network = peripheral.wrap(side)
	this._boilerName = boilerName
	this._state = {
		temperature = -1,
		lowTemp = false,
		criticalTemp = false,
		needsFuel = false,
		tanks = {
			water = {
				amount = -1,
				level = -1,
				low = false,
				critical = false
			},
			steam = {
				amount = -1,
				level = -1,
				low = false,
				critical = false
			}
		}
	}
	if alerts ~= nil then
		this._alerts = alerts
	else
		this._alerts = {
			lowTemp = 500,
			criticalTemp = 250,
			tanks = {
				water = {
					low = 0.66,
					critical = 0.33
				},
				steam = {
					low = 0.5,
					critical = 0.25
				}
			}
		}
	end
end)

function BoilerMonitor:updateTank(tankName, capacity, amount)
	if (capacity ~= self._state.tanks[tankName].capacity) then
		self._state.tanks[tankName].capacity = capacity
		os.queueEvent("railcraft_boiler", self._boilerName, tankName .. "_capacity", capacity)
	end

	if (amount ~= self._state.tanks[tankName].amount) then
		self._state.tanks[tankName].amount = amount
		os.queueEvent("railcraft_boiler", self._boilerName, tankName .. "_amount", amount)
	end

	-- Check for alert levels
	local percentFull = amount / capacity

	if (percentFull > self._alerts.tanks[tankName].low) then
		self._state.tanks[tankName].low = false
		self._state.tanks[tankName].critical = false
	elseif (percentFull > self._alerts.tanks[tankName].critical) then
		-- At or below the low level but still above critical
		-- If it was not previously low, we've hit an edge, so fire an event
		if not self._state.tanks[tankName].low then
			os.queueEvent("railcraft_boiler", self._boilerName, tankName .. "_low")
		end
		self._state.tanks[tankName].low = true
		self._state.tanks[tankName].critical = false
	else
		-- At or below the critical level
		-- If it was not previously critical, we've hit an edge, so fire an event
		if not self._state.tanks[tankName].critical then
			os.queueEvent("railcraft_boiler", self._boilerName, tankName .. "_critical")
		end
		self._state.tanks[tankName].low = true
		self._state.tanks[tankName].critical = true
	end
end

function BoilerMonitor:registerWith(cce)
	cce:register("periodic_timer_5s", function()
		-- Check temperature
		local temperature = tonumber(self._network.callRemote(self._boilerName, "getTemperature"))
		-- If it's changed, save the new state and fire an event
		if (temperature ~= self._state.temperature) then
			self._state.temperature = temperature
			os.queueEvent("railcraft_boiler", self._boilerName, "temperature", temperature)
		end
		if (temperature < self._alerts.criticalTemp) then
			if not self._state.criticalTemp then
				os.queueEvent("railcraft_boiler", self._boilerName, "temp_critical")
			end
			self._state.lowTemp = true
			self._state.criticalTemp = true
		elseif (temperature < self.alerts.lowTemp) then
			if not self._state.lowTemp then
				os.queueEvent("railcraft_boiler", self._boilerName, "temp_low")
			end
			self._state.lowTemp = true
			self._state.criticalTemp = false
		else
			self._state.lowTemp = false
			self._state.criticalTemp = false
		end

		-- Check to see if we need fuel
		local needsFuel = self._network.callRemote(self._boilerName, "needsFuel")

		-- Look at every attached tank - side might not matter?
		local tanks = self._network.callRemote(self._boilerName, "getTanks", "up")
		for i, tank in pairs(tanks) do
			if (tank.name ~= nil) then
				self:updateTank(tank.name:sub(1,1):lower() .. tank.name:sub(2), tonumber(tank.capacity), tonumber(tank.amount))
			end
		end
		
		-- Now check to see if tanks were not detected
		for tankName, tankState in pairs(self._state.tanks) do
			if (tankState.amount == -1) then
				if not self._state.tanks[tankName].critical then
					os.queueEvent("railcraft_boiler", self._boilerName, tankName .. "_critical")
				end
				self._state.tanks[tankName].low = true
				self._state.tanks[tankName].critical = true
			end
		end
	end)
end