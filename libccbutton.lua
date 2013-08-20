-- libccbutton.lua
-- lib-ComputerCraft-button
--
-- A library for drawing buttons on a monitor and processing the results.
-- Sourced from https://github.com/chuesler/computercraft-programs
-- Modified to work with libccevent
--

os.loadAPI("libccclass")
os.loadAPI("libccevent")

-- Define the Button class and constructor
Button = libccclass.class(function (b, text, callback, xMin, xMax, yMin, yMax, color)
	-- add a new button. colors are optional.
	b.text = text
	b.callback = callback
	b.x = { min = xMin, max = xMax }
	b.y = { min = yMin, max = yMax }

	b.enabled = true
	b.visible = true

	b.colors = { text = colors.white, background = colors.black, enabled = colors.lime, disabled = colors.red }
	if color ~= nil and type(color) == "table" then
		for k, v in pairs(color) do
			b.colors[k] = v
		end
	end

	b:display()
end)

-- Find the monitor attached to the computer
for i, side in pairs(rs.getSides()) do
	if peripheral.getType(side) == "monitor" then
		local monitor = peripheral.wrap(side)
		if monitor.isColor() then
			Button.monitor = monitor
			break
		end
	end
end

-- Verify we have a monitor attached to the computer
if not Button.monitor then
	error("Button api requires an Advanced Monitor")
end

-- Draw the button on the designated monitor
function Button:display()
	local color = self.visible and (self.enabled and self.colors.enabled or self.colors.disabled) or self.colors.background

	self.monitor.setBackgroundColor(color)
	self.monitor.setTextColor(self.colors.text)

	local center = math.floor((self.y.min + self.y.max) / 2)

	for j = self.y.min, self.y.max do
		self.monitor.setCursorPos(self.x.min, j)

		if j == center and self.visible then
			local length = self.x.max - self.x.min
			local space = string.rep(" ", (length - string.len(self.text)) / 2)

			self.monitor.write(space)
			self.monitor.write(self.text)
			self.monitor.write(space)

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

function Button:registerEvent(cce)
	cce:register("monitor_touch", function(event, side, x, y)
		if self.enabled and self.x.min <= x and self.x.max >= x and self.y.min <= y and self.y.max >= y then
			-- Pass self as a callback argument so the callback can manipulate the button
			return self.callback(self)
		else
			return false
		end
	end)
end

function setMonitor(monitor)
	if monitor == nil or not monitor.isColor() then
		error("Button api requires an Advanced Monitor")
	end

	Button.monitor = monitor
end