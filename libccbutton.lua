-- libccbutton.lua
-- lib-ComputerCraft-button
--
-- A library for drawing buttons on a monitor and processing the results.
-- Sourced from https://github.com/chuesler/computercraft-programs
-- Modified to work with libccevent
--

os.loadAPI("libccclass")
os.loadAPI("libccevent")

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

-- Define the Button class and constructor
Button = libccclass.class(function (this, text, callback, xMin, xMax, yMin, yMax, color, monitorSide)
	-- Add a new button. Colors are optional. Monitor Side is optional; if unspecified, we use the first one we can find.
	this.text = text
	this.callback = callback
	this.x = { min = xMin, max = xMax }
	this.y = { min = yMin, max = yMax }

	this.enabled = true
	this.visible = true

	-- Populate default colors, override if any are passed in
	this.colors = { text = colors.white, background = colors.black, enabled = colors.lime, disabled = colors.red }
	if color ~= nil and type(color) == "table" then
		for k, v in pairs(color) do
			this.colors[k] = v
		end
	end

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
		error("Button API requires an Advanced Monitor")
	end

	this:display()
end)

-- Draw the button on the designated monitor
function Button:display()
	local color = self.visible and (self.enabled and self.colors.enabled or self.colors.disabled) or self.colors.background

	self.monitor.setBackgroundColor(color)
	self.monitor.setTextColor(self.colors.text)

	local center = math.floor((self.y.min + self.y.max) / 2)

	for y = self.y.min, self.y.max do
		self.monitor.setCursorPos(self.x.min, y)

		if y == center and self.visible then
			local length = self.x.max - self.x.min
			local space = ""
			local text = ""
			if length > string.len(self.text) then
				-- Use spaces to center text if there's room
				space = string.rep(" ", (length - string.len(self.text)) / 2)
				text = self.text
			else
				-- Truncate text if there's not enough room
				text = self.text:sub(1,length)
			end

			self.monitor.write(space)
			self.monitor.write(text)
			self.monitor.write(space)

			-- Extra space if we can't center it exactly
			if string.len(space) * 2 + string.len(self.text) < length then
				self.monitor.write(" ")
			end
		else
			self.monitor.write(string.rep(" ", self.x.max - self.x.min))
		end
	end

	self.monitor.setBackgroundColor(self.colors.background)
end

function Button:enable()
	self.enabled = true
	self:display()
end

function Button:disable()
	self.enabled = false
	self:display()
end

function Button:toggle()
	self.enabled = not self.enabled
	self:display()
end

function Button:flash(interval)
	self:disable()
	sleep(interval or 0.15)
	self:enable()
end

function Button:show()
	self.visible = true
	self:display()
end

function Button:hide()
	self.visible = false
	self:display()
end

function Button:registerWith(cce)
	cce:register("monitor_touch", function(event, side, x, y)
		if self.visible
			and side == self.monitorSide
			and self.x.min <= x and self.x.max >= x and self.y.min <= y and self.y.max >= y then
			-- Pass self as a callback argument so the callback can manipulate the button
			return self.callback(self)
		else
			return false
		end
	end)
end

function Button:setMonitor(monitorSide)
	local monitor = checkMonitor(monitorSide)
	if monitor == nil then
		error("Button API requires an Advanced Monitor")
	else
		-- Remove button from existing monitor
		local visibility = self.visible
		self:hide()

		-- Transfer button to new monitor
		self.monitorSide = monitorSide
		self.monitor = monitor

		-- Restore visibility to previous state and refresh display
		self.visible = visibility
		self:display()
	end
end