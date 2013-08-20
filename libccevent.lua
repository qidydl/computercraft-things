-- libccevent.lua
-- lib-ComputerCraft-event
--
-- A library for registering ComputerCraft event handlers and processing them in order.
-- Event handler callbacks should return 'true' to indicate that the event has been handled, or 'false' to continue
-- processing with the next event handler.
--

os.loadAPI("libccclass")

ccEvent = libccclass.class(function(cce)
	-- Constructor
	cce._handlers = {}
end)

function ccEvent:register(event, callback)
	print("Registering handler for " .. event)
	-- If nobody's registered for this event yet, initialize to empty handler list
	if self._handlers[event] == nil then
		self._handlers[event] = {}
	end

	-- Add handler to the end of the list
	table.insert(self._handlers[event], callback)

	print("There are now " .. #self._handlers[event] .. " handlers for " .. event)
end

function ccEvent:doEventLoop()
	while true do
		local result = {os.pullEvent()}
		print("Event: [" .. table.concat(result, "] [") .. "]")
		local event = result[1]

		if self._handlers[event] ~= nil then
			for k,handler in pairs(self._handlers[event]) do
				print("Trying handler " .. tostring(k) .. ": " .. tostring(handler))
				if handler(unpack(result)) then break end
			end
		end
	end
end