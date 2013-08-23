-- boilermonitortab.lua
--
-- Program to monitor a Railcraft boiler and display status information on it in a tabbed dialog

os.loadAPI("libccclass")
os.loadAPI("libccevent")
os.loadAPI("libcctabs")
os.loadAPI("librcboiler")

BoilerMonitorTab = libccclass.class(function (self, boilerID, boilerName, tabs)
	self._boilerID = boilerID
	self._boilerName = boilerName
	self._tabDialog = tabs
end)

function BoilerMonitorTab:registerTab()
	self._tabID = self._tabDialog:addTab(self._boilerName, function(tabs, visible)
		-- Tab display callback
		if visible then
			-- Display stuff
		else
			-- Hide stuff
		end
	end)
end

function BoilerMonitorTab:registerWith(cce)
	cce:register("railcraft_boiler", function(event, boilerID, boilerEvent, param)
		if (boilerID == self._boilerID) then
			-- Handle events
			if (self._tabDialog._selectedTab == self._tabID) then
				-- Display stuff
			else
				-- Highlight if necessary
				if (boilerEvent:sub(-3) == "low") then
					self._tabDialog:highlightTab(self._tabID, "warning")
				elseif (boilerEvent:sub(-3) == "critical") then
					self._tabDialog:highlightTab(self._tabID, "danger")
				end
			end
		end
	end)
end