-- boilermonitortab.lua
--
-- Program to monitor a Railcraft boiler and display status information on it in a tabbed dialog

os.loadAPI("libccclass")
os.loadAPI("libccevent")
os.loadAPI("libcctabs")
os.loadAPI("librcboiler")

-- Note: this function truncates, it does not round! This is fine for this case, we don't really care about
-- that much precision for boiler temperature, but do not re-use this code elsewhere without considering the
-- consequences.
--
-- Also note: string.format("%.2f", value) does not work at all; it just prints out the value with no precision
-- formatting. Perhaps ComputerCraft's Lua is out of date and/or broken?
function formatFloat(value, prec)
	local str = string.format("%f", value)
	local sep, junk = str:find(".", 1, true)

	return str:sub(1, sep + prec)
end

-- Boiler types: 0 = solid-fueled, 1 = liquid-fueled
BoilerMonitorTab = libccclass.class(function (self, side, boilerID, boilerName, boilerType)
	self._networkSide = side
	self._boilerID = boilerID
	self._boilerName = boilerName
	self._boilerType = boilerType

	self._boilerMonitor = librcboiler.BoilerMonitor(side, boilerID, boilerType)
end)

function BoilerMonitorTab:registerTab(tabs)
	self._tabDialog = tabs
	self._tabID = self._tabDialog:addTab(self._boilerName, function(tabs, visible)
		-- Tab display callback
		if visible then
			self:display()
		else
			-- Hide stuff if necessary - screen will be wiped but buttons and such need to have status updated
		end
	end)
end

function BoilerMonitorTab:display()
	local monitor = self._tabDialog.monitor

	-- Display boiler information
	monitor.setCursorPos(1, 5)
	monitor.clearLine()
	monitor.write("Boiler Monitor Tab for " .. self._boilerName)
	monitor.setCursorPos(1, 6)
	monitor.clearLine()
	monitor.write("Boiler Temperature: " .. formatFloat(self._boilerMonitor._state.temperature, 2) .. " C")
	monitor.setCursorPos(1, 7)
	monitor.clearLine()
	monitor.write("Boiler Water: ")
	if (self._boilerMonitor._state.tanks[1].capacity == -1) then
		monitor.write("empty!")
	else
		monitor.write(self._boilerMonitor._state.tanks[1].amount .. "/" .. self._boilerMonitor._state.tanks[1].capacity)
	end
	monitor.setCursorPos(1, 8)
	monitor.clearLine()
	monitor.write("Boiler Fuel: ")
	if (self._boilerMonitor._state.tanks[3].capacity == -1) then
		monitor.write("empty!")
	else
		monitor.write(self._boilerMonitor._state.tanks[3].amount .. "/" .. self._boilerMonitor._state.tanks[3].capacity)
	end
	monitor.setCursorPos(1, 9)
	monitor.clearLine()
	monitor.write("Boiler Steam: ")
	if (self._boilerMonitor._state.tanks[2].capacity == -1) then
		monitor.write("empty!")
	else
		monitor.write(self._boilerMonitor._state.tanks[2].amount .. "/" .. self._boilerMonitor._state.tanks[2].capacity)
	end
end

function BoilerMonitorTab:registerWith(cce)
	self._boilerMonitor:registerWith(cce)

	cce:register("railcraft_boiler", function(event, boilerID, boilerEvent, param)
		if (boilerID == self._boilerID) then
			-- Handle events
			if (self._tabDialog._selectedTab == self._tabID) then
				self:display()
			else
				-- Highlight if necessary
				if (boilerEvent:sub(-3) == "low") then
					self._tabDialog:highlightTab(self._tabID, "warning")
				elseif (boilerEvent:sub(-8) == "critical") then
					self._tabDialog:highlightTab(self._tabID, "danger")
				end
			end
		end
	end)
end