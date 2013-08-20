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
	--TODO: callback needs to do a lot more, positions need to be calculated, etc.
	local newButton = libccbutton.Button(text, function(button)
		button:enable()
		return callback(self, button)
	end, 5, 15, 5, 15)

	table.insert(self._tabs,
		{ text = text, button = newButton, callback = callback })

	self:display()
end

function Tabs:display()
	--TODO: display all buttons
	for tab in self._tabs do
		tab.button:display()
	end
end

function Tabs:registerWith(cce)
	for tab in self._tabs do
		tab.button:registerWith(cce)
	end
end

function Tabs:setMonitor(monitorSide)
	local monitor = checkMonitor(monitorSide)
	if monitor == nil then
		error("Tabs API requires an Advanced Monitor")
	else
		self.monitorSide = monitorSide
		self.monitor = monitor
	end
end