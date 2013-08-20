-- libcctabs.lua
-- lib-ComputerCraft-Tabs
--
-- A GUI library for drawing tabbed interfaces. Uses libCCButton to draw the tabs themselves.
--

os.loadAPI("libccclass")
os.loadAPI("libccevent")
os.loadAPI("libccbutton")

-- Define the tabbed interface class and constructor
Tabs = libccclass.class(function (this)
	-- Initialize to no tabs
	this._tabs = {}
	this._selectedTab = nil
end)

function Tabs:addTab(text, callback)
	--TODO: callback needs to do a lot more, positions need to be calculated, etc.
	local newButton = libccbutton.Button(text, function(button)
		button:enable()
		return true
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