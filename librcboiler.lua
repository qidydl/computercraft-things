-- librcboiler.lua
-- lib-Railcraft-Boiler
--
-- A library for monitoring Railcraft boilers and generating events based on detected changes.
--

os.loadAPI("libccclass")
os.loadAPI("libccevent")

-- Boiler types: 0 = solid-fueled, 1 = liquid-fueled
BoilerMonitor = libccclass.class(function (this, side, boilerName, boilerType, alerts)
	this._network = peripheral.wrap(side)
	this._boilerName = boilerName
	this._boilerType = boilerType
	this._state = {
		temperature = -1,
		lowTemp = false,
		criticalTemp = false,
		tanks = {
			[1] = {
				name = "water",
				amount = -1,
				capacity = -1,
				low = false,
				critical = false
			},
			[2] = {
				name = "steam",
				amount = -1,
				capacity = -1,
				low = false,
				critical = false
			},
			[3] = {
				name = "fuel",
				amount = -1,
				capacity = -1,
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
				[1] = {
					low = 0.66,
					critical = 0.33
				},
				[2] = {
					low = 0.5,
					critical = 0.25
				},
				[3] = {
					low = 0.5,
					critical = 0.25
				}
			}
		}
	end
end)

function BoilerMonitor:updateTank(tankID, capacity, amount)
	local tankName = self._state.tanks[tankID].name

	if (capacity ~= self._state.tanks[tankID].capacity) then
		self._state.tanks[tankID].capacity = capacity
		os.queueEvent("railcraft_boiler", self._boilerName, tankName .. "_capacity", capacity)
	end

	if (amount ~= self._state.tanks[tankID].amount) then
		self._state.tanks[tankID].amount = amount
		os.queueEvent("railcraft_boiler", self._boilerName, tankName .. "_amount", amount)
	end

	-- Check for alert levels
	local percentFull = 0
	if (amount > 0) and (capacity > 0) then
		percentFull = amount / capacity
	end

	if (percentFull > self._alerts.tanks[tankID].low) then
		self._state.tanks[tankID].low = false
		self._state.tanks[tankID].critical = false
	elseif (percentFull > self._alerts.tanks[tankID].critical) then
		-- At or below the low level but still above critical
		-- If it was not previously low, we've hit an edge, so fire an event
		if not self._state.tanks[tankID].low then
			os.queueEvent("railcraft_boiler", self._boilerName, tankName .. "_low")
		end
		self._state.tanks[tankID].low = true
		self._state.tanks[tankID].critical = false
	else
		-- At or below the critical level
		-- If it was not previously critical, we've hit an edge, so fire an event
		if not self._state.tanks[tankID].critical then
			os.queueEvent("railcraft_boiler", self._boilerName, tankName .. "_critical")
		end
		self._state.tanks[tankID].low = true
		self._state.tanks[tankID].critical = true
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

		-- Solid-fueled boiler: update the "fuel tank" based on inventory
		if (self._boilerType == 0) then
			-- Slot 2 seems to be the primary fuel slot where it goes to burn
			local fuelInv = self._network.callRemote(self._boilerName, "getStackInSlot", 2)

			-- If there's no fuel at all, we get a nil result
			if (fuelInv ~= nil) then
				self:updateTank(3, 64, tonumber(fuelInv.qty))
			else
				self:updateTank(3, 64, -1)
			end
		end

		-- Look at every attached tank - side might not matter?
		local tanks = self._network.callRemote(self._boilerName, "getTanks", "up")
		for i, tank in pairs(tanks) do
			-- Tanks without a name don't have data
			if (tank.name ~= nil) then
				self:updateTank(i, tonumber(tank.capacity), tonumber(tank.amount))
			else
				self:updateTank(i, -1, -1)
			end
		end
		
		-- Now check to see if tanks were not detected
		for tankID, tankState in pairs(self._state.tanks) do
			if (tankState.amount == -1) then
				if not self._state.tanks[tankID].critical then
					os.queueEvent("railcraft_boiler", self._boilerName, tankState.name .. "_critical")
				end
				self._state.tanks[tankID].low = true
				self._state.tanks[tankID].critical = true
			end
		end
	end)
end