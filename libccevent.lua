-- libccevent.lua
-- lib-ComputerCraft-event
--
-- A library for registering ComputerCraft event handlers and processing them in order.
-- Event handler callbacks should return 'true' to indicate that the event has been handled, or 'false' to continue
-- processing with the next event handler.
--

os.loadAPI("libccclass")

ccEvent = libccclass.class(function(cce, debugFlag)
	-- Constructor
	cce._handlers = {}
	cce._debugFlag = debugFlag
	cce._periodicTimerID = -1
end)

function ccEvent:register(event, callback)
	if (self._debugFlag) then
		print("Registering handler for " .. event)
	end
	-- If nobody's registered for this event yet, initialize to empty handler list
	if self._handlers[event] == nil then
		self._handlers[event] = {}
	end

	-- Add handler to the end of the list
	table.insert(self._handlers[event], callback)

	if (self._debugFlag) then
		print("There are now " .. #self._handlers[event] .. " handlers for " .. event)
	end
end

function ccEvent:doEventLoop()
	-- Kick off periodic timer
	self._periodicTimerID = os.startTimer(1.0)
	while true do
		local result = {os.pullEvent()}
		local event = result[1]

		if (self._debugFlag) then
			print("Event: [" .. table.concat(result, "] [") .. "]")
		end

		-- Special processing for our periodic timer
		if (event == "timer" and result[2] == self._periodicTimerID) then
			-- Reset the timer
			self._periodicTimerID = os.startTimer(1.0)
			
			-- Call *all* timer handlers - different from default behavior
			if self._handlers["periodic_timer"] ~= nil then
				parallel.waitForAll(unpack(self._handlers["periodic_timer"]))
			end
		elseif self._handlers[event] ~= nil then
			for k,handler in pairs(self._handlers[event]) do
				if (self._debugFlag) then
					print("Trying handler " .. tostring(k) .. ": " .. tostring(handler))
				end

				if handler(unpack(result)) then break end
			end
		end
	end
end