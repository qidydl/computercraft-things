-- libcctabs.lua
-- lib-ComputerCraft-Tabs
--
-- A GUI library for drawing tabbed interfaces. Uses libCCButton to draw the tabs themselves.
--

os.loadAPI("libccclass")
os.loadAPI("libccevent")
os.loadAPI("libccbutton")
os.loadAPI("libccmultimon")

-- Define the tabbed interface class and constructor
Tabs = libccclass.class(libccmultimon.MultiMon, function (this, color, monitorSide)
	libccmultimon.MultiMon.init(this, monitorSide, true)

	-- Initialize to no tabs
	this._tabs = {}
	this._selectedTab = nil
	this._lastID = 0

	-- Populate default colors, override if any are passed in
	this._tabColors = { text = colors.white, background = colors.black, enabled = colors.lime, disabled = colors.black, warning = colors.orange, danger = colors.red }
	if color ~= nil and type(color) == "table" then
		for k, v in pairs(color) do
			this._tabColors[k] = v
		end
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
	end, buttonX, buttonX + string.len(text) + 2, 1, 3, self._tabColors, self.monitorSide)

	if lastTab ~= nil then
		newButton:disable()
	else
		self._selectedTab = tabID
	end

	table.insert(self._tabs,
		{ id = tabID, text = text, button = newButton, callback = callback, highlight = self._tabColors.background })

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
			tab.highlight = self._tabColors.background
		else
			tab.button:disable()
		end
	end

	-- Update selected tab
	self._selectedTab = id

	self:display()
end

function Tabs:highlightTab(tabID, highlightType)
	local highlightTab = self:getTab(tabID)

	if		(self._tabColors[highlightType] ~= nil)
		and (highlightTab ~= nil) 
		and (self._selectedTab ~= tabID)
	then
		highlightTab.highlight = highlightType
		self:display()
	end
end

function Tabs:display()
	self.monitor.clear()

	-- Draw tab buttons
	for i, tab in pairs(self._tabs) do
		tab.button:display()
		-- If button is highlighted and not selected, draw highlight line
		if (self._selectedTab ~= tab.id) and (tab.highlight ~= self._tabColors.background) then
			self.monitor.setBackgroundColor(self._tabColors[tab.highlight])
			self.monitor.setCursorPos(tab.button.x.min + 1, 3)
			self.monitor.write(string.rep(" ", string.len(tab.text)))
		end
	end

	-- Draw tab separator
	local w, h = self.monitor.getSize()
	self.monitor.setBackgroundColor(self._tabColors.background)
	self.monitor.setTextColor(self._tabColors.text)
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
	local monitor = libccmultimon.checkMonitor(monitorSide)
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