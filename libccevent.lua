-- libccevent.lua
-- lib-ComputerCraft-event
--
-- A library for registering ComputerCraft event handlers and processing them in order.
-- Event handler callbacks should return 'true' to indicate that the event has been handled, or 'false' to continue
-- processing with the next event handler.
--

os.loadAPI("libccclass")

-- Utility method to combine simple list tables together
function appendAll(tableDest, tableSrc)
	for i, el in pairs(tableSrc) do
		table.insert(tableDest, el)
	end
end

ccEvent = libccclass.class(function(cce, debugFlag)
	-- Constructor
	cce._handlers = {}
	cce._debugFlag = debugFlag
	cce._periodicTimerID = -1
	cce._periodicTimerTickCount = 0

	-- Provide blank handler lists for periodic timer events
	-- Saves on error-checking code below
	cce._handlers["periodic_timer_1s"] = {}
	cce._handlers["periodic_timer_5s"] = {}
	cce._handlers["periodic_timer_30s"] = {}
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
		if (event == "timer" and result[2] == self._periodicTimerID)
		then
			-- Reset the timer
			self._periodicTimerID = os.startTimer(1.0)

			-- Count ticks
			self._periodicTimerTickCount = self._periodicTimerTickCount + 1

			-- Start with handlers for 1-second timer
			-- Don't do a shallow copy or we'll end up accidentally modifying the list of 1s handlers
			local timerHandlers = {}
			appendAll(timerHandlers, self._handlers["periodic_timer_1s"])

			if (self._periodicTimerTickCount % 5 == 0)
			then
				appendAll(timerHandlers, self._handlers["periodic_timer_5s"])
			end

			if (self._periodicTimerTickCount % 30 == 0)
			then
				-- Reset tick count - this should only be done in the largest periodic timer!
				self._periodicTimerTickCount = 0

				appendAll(timerHandlers, self._handlers["periodic_timer_30s"])
			end

			-- Call *all* timer handlers - different from default behavior
			if #timerHandlers > 0
			then
				parallel.waitForAll(unpack(timerHandlers))
			end
		elseif self._handlers[event] ~= nil
		then
			for k,handler in pairs(self._handlers[event])
			do
				if (self._debugFlag)
				then
					print("Trying handler " .. tostring(k) .. ": " .. tostring(handler))
				end

				if handler(unpack(result)) then break end
			end
		end
	end
end