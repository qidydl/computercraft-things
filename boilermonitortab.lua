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

-- Draws a bar on the screen filled up to fillPercent
function drawBar(monitor, xCoord, yCoord, width, height, fillPercent, colorsParam)
	local barColors = { background = colors.black, outline = colors.white, fill = colors.white }

	-- Override colors with parameters if present
	if colorsParam ~= nil and type(colorsParam) == "table" then
		for k, v in pairs(colorsParam) do
			barColors[k] = v
		end
	end

	-- Calculate bar height
	local innerHeight = height - 2
	local barHeight = math.ceil(innerHeight * fillPercent)
	local spaceHeight = innerHeight - barHeight

	-- Set up monitor
	monitor.setCursorPos(xCoord, yCoord)
	monitor.setBackgroundColor(barColors.background)
	monitor.setTextColor(barColors.outline)

	-- Top line
	monitor.write("+" .. string.rep("-", width - 2) .. "+")

	-- Space lines
	for y=0,spaceHeight do
		-- +1 to account for top line
		monitor.setCursorPos(xCoord, yCoord + y + 1)
		monitor.write("|" .. string.rep(" ", width - 2) .. "|")
	end

	-- Bar lines
	for y=spaceHeight,innerHeight-1 do
		monitor.setCursorPos(xCoord, yCoord + y + 1)
		monitor.write("|")

		monitor.setCursorPos(xCoord + 1, yCoord + y + 1)
		monitor.setBackgroundColor(barColors.fill)
		monitor.write(string.rep(" ", width - 2))

		monitor.setCursorPos(xCoord + width - 1, yCoord + y + 1)
		monitor.setBackgroundColor(barColors.background)
		monitor.write("|")
	end

	-- Bottom line
	monitor.setCursorPos(xCoord, yCoord + height - 1)
	monitor.write("+" .. string.rep("-", width - 2) .. "+")
end

-- Boiler types: 0 = solid-fueled, 1 = liquid-fueled
-- Boiler pressures: 0 = low pressure, 1 = high pressure
BoilerMonitorTab = libccclass.class(function (self, side, boilerID, boilerName, boilerType, boilerPressure)
	self._networkSide = side
	self._boilerID = boilerID
	self._boilerName = boilerName
	self._boilerType = boilerType
	self._boilerPressure = boilerPressure

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

	-- Steam
	local steamTank = self._boilerMonitor._state.tanks[2]
	local steamLevel = steamTank.amount / steamTank.capacity
	local steam = tostring(steamTank.amount)
	if (steamTank.amount == -1) then
		steamLevel = 0
		steam = "Empty"
	end

	monitor.setCursorPos(1, 5)
	monitor.write("Steam")
	drawBar(monitor, 1, 6, 6, 12, steamLevel, { fill = colors.white })
	monitor.setCursorPos(1, 18)
	monitor.write(string.rep(" ", math.floor((6 - string.len(steam)) / 2)) .. steam)

	-- Temperature
	local maxTemp = 500
	if (self._boilerPressure == 1) then
		maxTemp = 1000
	end

	monitor.setCursorPos(8, 5)
	monitor.write("Temp C")
	drawBar(monitor, 8, 6, 6, 12, self._boilerMonitor._state.temperature / maxTemp, { fill = colors.red })
	monitor.setCursorPos(8, 18)
	local temp = formatFloat(self._boilerMonitor._state.temperature, 1)
	monitor.write(string.rep(" ", math.floor((6 - string.len(temp)) / 2)) .. temp)

	-- Fuel
	local fuelTank = self._boilerMonitor._state.tanks[3]
	local fuelLevel = fuelTank.amount / fuelTank.capacity
	local fuel = tostring(fuelTank.amount)
	if (fuelTank.amount == -1) then
		fuelLevel = 0
		fuel = "Empty"
	end

	monitor.setCursorPos(15, 5)
	monitor.write(" Fuel")
	drawBar(monitor, 15, 6, 6, 12, fuelLevel, { fill = colors.orange })
	monitor.setCursorPos(15, 18)
	monitor.write(string.rep(" ", math.floor((6 - string.len(fuel)) / 2)) .. fuel)

	-- Water
	local waterTank = self._boilerMonitor._state.tanks[1]
	local waterLevel = waterTank.amount / waterTank.capacity
	local water = tostring(waterTank.amount)
	if (waterTank.amount == -1) then
		waterLevel = 0
		water = "Empty"
	end

	monitor.setCursorPos(22, 5)
	monitor.write("Water")
	drawBar(monitor, 22, 6, 6, 12, waterLevel, { fill = colors.blue })
	monitor.setCursorPos(22, 18)
	monitor.write(string.rep(" ", math.floor((6 - string.len(water)) / 2)) .. water)
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