-- boilermonitortab.lua
--
-- Program to monitor a Railcraft boiler and display status information on it in a tabbed dialog

os.loadAPI("libccclass")
os.loadAPI("libccevent")
os.loadAPI("libcctabs")
os.loadAPI("librcboiler")

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
	monitor.write("Boiler Monitor Tab for " .. self._boilerName)
	monitor.setCursorPos(1, 6)
	monitor.write("Boiler Temperature: " .. self._boilerMonitor._state.temperature .. " C")
end

function BoilerMonitorTab:registerWith(cce)
	self._boilerMonitor:registerWith(cce)

	cce:register("railcraft_boiler", function(event, boilerID, boilerEvent, param)
		if (boilerID == self._boilerID) then
			-- Handle events
			print("BMTab received [" .. event .. "] [" .. boilerID .. "] [" .. boilerEvent .. "]")

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