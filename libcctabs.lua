-- libcctabs.lua
-- lib-ComputerCraft-Tabs
--
-- A GUI library for drawing tabbed interfaces. Uses libCCButton to draw the tabs themselves.
--

os.loadAPI("libccclass")
os.loadAPI("libccevent")
os.loadAPI("libccbutton")

-- Validate a monitor to see if it can be used
function checkMonitor(monitorSide)
	if peripheral.getType(monitorSide) == "monitor" then
		local monitor = peripheral.wrap(monitorSide)
		if monitor.isColor() then
			return monitor
		end
	end

	return nil
end

-- Define the tabbed interface class and constructor
Tabs = libccclass.class(function (this, monitorSide)
	-- Initialize to no tabs
	this._tabs = {}
	this._selectedTab = nil
	this._lastID = 0

	-- Check specified monitor side
	if monitorSide ~= nil then
		local monitor = checkMonitor(monitorSide)
		if monitor ~= nil then
			this.monitorSide = monitorSide
			this.monitor = monitor
		end
	else
		-- See if there's a usable monitor and go with the first one we find
		for i, side in pairs(rs.getSides()) do
			local monitor = checkMonitor(side)
			if monitor ~= nil then
				this.monitorSide = side
				this.monitor = monitor
				break
			end
		end
	end

	-- Verify we have a monitor attached to the computer
	if not this.monitor then
		error("Tabs API requires an Advanced Monitor")
	end
end)

function Tabs:addTab(text, callback)
	local tabID = self._lastID + 1
	local buttonX = 1
	local lastTab = self:getTab(self._lastID)
	if lastTab ~= nil then
		-- calculate from existing buttons
		buttonX = lastTab.button.x.max + 1
	end

	local newButton = libccbutton.Button(text, function(button)
		self:selectTab(tabID)
		return true
	end, buttonX, buttonX + string.len(text) + 2, 1, 3, { disabled = colors.black }, self.monitorSide)

	if lastTab ~= nil then
		newButton:disable()
	else
		self._selectedTab = tabID
	end

	table.insert(self._tabs,
		{ id = tabID, text = text, button = newButton, callback = callback })

	self._lastID = self._lastID + 1

	self:display()

	return tabID
end

function Tabs:getTab(id)
	for i, tab in pairs(self._tabs) do
		if tab.id == id then
			return tab
		end
	end

	return nil
end

function Tabs:selectTab(id)
	-- Inform old selected tab that it needs to clean up
	local selectedTab = self:getTab(self._selectedTab)
	if selectedTab ~= nil then
		selectedTab.callback(self, false)
	end

	-- Update button state
	for i, tab in pairs(self._tabs) do
		if tab.id == id then
			tab.button:enable()
		else
			tab.button:disable()
		end
	end

	-- Update selected tab
	self._selectedTab = id

	self:display()
end

function Tabs:display()
	self.monitor.clear()

	-- Draw tab buttons
	for i, tab in pairs(self._tabs) do
		tab.button:display()
	end

	-- Draw tab separator
	local w, h = self.monitor.getSize()
	self.monitor.setTextColor(colors.white)
	self.monitor.setCursorPos(1, 4)
	self.monitor.write(string.rep("-", w))

	-- Draw current tab, if it exists
	local selectedTab = self:getTab(self._selectedTab)
	if selectedTab ~= nil then
		selectedTab.callback(self, true)
	end
end

function Tabs:registerWith(cce)
	for i, tab in pairs(self._tabs) do
		tab.button:registerWith(cce)
	end
end

function Tabs:setMonitor(monitorSide)
	local monitor = checkMonitor(monitorSide)
	if monitor == nil then
		error("Tabs API requires an Advanced Monitor")
	else
		-- Clear the old monitor
		self.monitor.clear()

		-- Move to the new monitor
		self.monitorSide = monitorSide
		self.monitor = monitor

		for i, tab in pairs(self._tabs) do
			tab.button:setMonitor(monitorSide)
		end

		self:display()
	end
end