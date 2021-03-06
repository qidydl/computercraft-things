-- redstoneDebug.lua
--
-- Displays all redstone bundled input signals being received by a computer and updates whenever they change.
--

os.loadAPI("libccclass")
os.loadAPI("libccevent")
os.loadAPI("libccbutton")
os.loadAPI("libccmultimon")

RedstoneDebug = libccclass.class(libccmultimon.MultiMon, function (this, x, y, monitorSide)
	libccmultimon.MultiMon.init(this, monitorSide, true)

	-- Build button collection
	this._colors = { colors.white, colors.orange, colors.magenta, colors.lightBlue, colors.yellow, colors.lime,
					 colors.pink, colors.gray, colors.lightGray, colors.cyan, colors.purple, colors.blue, colors.brown,
					 colors.green, colors.red, colors.black }
	this._buttons = {}

	-- Sanitize offsets
	if x == nil then x = 0 end
	if y == nil then y = 0 end

	this._offsetX = x
	this._offsetY = y

	local buttonX = 10 + x -- Leave some space for labels
	local buttonY = 1 + y

	for i, side in pairs(rs.getSides()) do
		this._buttons[side] = {}
		for j, color in pairs(this._colors) do
			-- Create a button for the color
			-- The "X" in the text is displayed, mostly so we can see something for black
			this._buttons[side][color] = libccbutton.Button("X " .. side .. ":" .. color,
				function(button) end, buttonX, buttonX + 1, buttonY, buttonY + 1,
				{ enabled = color, disabled = colors.black }, this.monitorSide)
			buttonX = buttonX + 1
			this._buttons[side][color]:hide()
		end
		buttonX = 10
		buttonY = buttonY + 1
	end

	this:display()
end)

function RedstoneDebug:display()
	for i, side in pairs(rs.getSides()) do
		-- Print a label
		self.monitor.setCursorPos(1 + self._offsetX, i + self._offsetY)
		self.monitor.write(side:sub(1,1):upper() .. side:sub(2) .. ":")

		local state = rs.getBundledInput(side)

		for j, color in pairs(self._colors) do
			if (colors.test(state, color)) then
				self._buttons[side][color]:show()
			else
				self._buttons[side][color]:hide()
			end
		end
	end
end

function RedstoneDebug:registerWith(cce)
	cce:register("redstone", function (event)
		self:display()
		-- Allow others to continue to process redstone events
		return false
	end)
end

function RedstoneDebug:setMonitor(monitorSide)
	local monitor = libccmultimon.checkMonitor(monitorSide)
	if monitor == nil then
		error("RedstoneDebug API requires an Advanced Monitor")
	else
		-- Transfer buttons to new monitor
		for i, side in pairs(rs.getSides()) do
			-- Blank out the old label
			self.monitor.setCursorPos(1 + self._offsetX, i + self._offsetY)
			self.monitor.write("       ")

			for j, color in pairs(self._colors) do
				self._buttons[side][color]:setMonitor(monitorSide)
			end
		end

		self.monitorSide = monitorSide
		self.monitor = monitor
		self:display()
	end
end