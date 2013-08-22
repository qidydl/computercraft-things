-- libccmultimon.lua
-- lib-ComputerCraft-MultipleMonitor
--
-- A base class library providing support for multiple monitors
--

os.loadAPI("libccclass")

-- Validate a monitor to see if it can be used
function checkMonitor(monitorSide, requireAdvanced)
	if peripheral.getType(monitorSide) == "monitor" then
		local monitor = peripheral.wrap(monitorSide)
		if (not requireAdvanced) or monitor.isColor() then
			return monitor
		end
	end

	return nil
end

MultiMon = libccclass.class(function (self, monitorSide, requireAdvanced)
	-- Shift parameters if necessary
	if (monitorSide ~= nil) and (type(monitorSide) ==  "boolean")
	then
		requireAdvanced = monitorSide
		monitorSide = nil
	end

	-- Default to false if not provided or provided wrong
	if (requireAdvanced == nil) or (type(requireAdvanced) ~= "boolean")
	then
		requireAdvanced = false
	end

	-- Save advanced monitor requirement flag
	self.requireAdvanced = requireAdvanced

	-- Check specified monitor side
	if monitorSide ~= nil then
		local monitor = checkMonitor(monitorSide, requireAdvanced)
		if monitor ~= nil then
			self.monitorSide = monitorSide
			self.monitor = monitor
		end
	else
		-- See if there's a usable monitor and go with the first one we find
		for i, side in pairs(rs.getSides()) do
		local monitor = checkMonitor(side, requireAdvanced)
			if monitor ~= nil then
				self.monitorSide = side
				self.monitor = monitor
				break
			end
		end
	end

	-- Verify we have a monitor attached to the computer
	if not self.monitor then
		error("MultiMon API requires an attached Monitor")
	end
end)

function MultiMon:setMonitor(monitorSide)
	local monitor = checkMonitor(monitorSide, self.requireAdvanced)

	if monitor == nil then
		error("MultiMon API requires an attached Monitor")
	else
		-- Transfer to new monitor
		self.monitorSide = monitorSide
		self.monitor = monitor
	end
end