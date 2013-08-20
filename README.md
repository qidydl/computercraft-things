computercraft-things
====================

qid's libraries and programs for <a href="http://www.computercraft.info/">ComputerCraft</a>, a mod for Minecraft.

Tested with ComputerCraft v1.53 for Minecraft v1.5.2.

Note that for all of these files, the .lua extension must be removed if you save them into the ComputerCraft directory.

### Table of Contents
* [libCCClass](#libccclass)
* [libCCEvent](#libccevent)
* [libCCButton](#libccbutton)
* [Combined Demo](#demo)

<a name="libccclass"/>
libCCClass
----------

This is a low-level library that adds some syntactical sugar for defining a "class". Lua doesn't have a first-order
concept of classes, but you can sort of fake it. The code was sourced from
<a href="http://lua-users.org/wiki/SimpleLuaClasses">the Lua Users Wiki</a>, all I did was clean it up a bit.

<a name="libccevent"/>
libCCEvent
----------

This is a unified event-handling library that allows various components to register themselves as handlers for different
types of events. The event handler is passed all of the parameters of the event as provided by ComputerCraft. Handlers
are called in the order in which they register. If an event handler returns `true`, processing of that event ends and
the loop resumes waiting for the next event. If an event handler returns `false`, libCCEvent will continue on with the
list of handlers.

I might see if there's any way to do some sort of threading or coroutines or something that allows processing of
different events to occur simultaneously, so that a blocking event handler can't stop up the whole system. That might be
beyond the scope or capabilities of ComputerCraft.

Note also that the granularity is only by event type at the moment; e.g. you can only register for all redstone events,
not a specific type of redstone event. I'm thinking the best approach would be to create sub-libraries for specific
event types, such as a "libCCEvent-Redstone" that handles all redstone events, but can distinguish between them in more
detail, and then callbacks can be registered with the sub-library. If you then made some premade callback templates for
different kinds of operations, you could effectively make an unlimited Programmable Rednet Controller. In theory.

### ccEvent methods
Method name | Description
------------|------------
`register(event, callback)` | Registers a handler for the given `event`. `callback` should accept the parameters provided by ComputerCraft for `event`, including the event name itself. For example, `monitor_touch` should accept `(event, side, x, y)`
`doEventLoop()` | Begins the event loop. Currently there is no way to exit out.

<a name="libccbutton"/>
libCCButton
-----------

This is an API for ComputerCraft's touch monitors, and is almost entirely lifted from
<a href="https://github.com/chuesler/computercraft-programs">chuesler's computercraft programs</a>. However, I have
modified it to use libCCClass for cleaner syntax, and to use libCCEvent which makes it much easier to combine with
other event handlers.

Buttons can be added to multiple monitors:
![Buttons displayed on a left and right monitor](Screenshots/2013-08-19_22.45.38.png)

Clicking on a button correctly toggles the one on the monitor you clicked on:
![Button on right monitor has been clicked and toggled to red](Screenshots/2013-08-19_22.45.51.png)

And a log of the output from clicking on the button
![Log output from clicking on the right button](Screenshots/2013-08-19_22.45.57.png)

### Button methods
Method name | Description
------------|------------
`Button(text, callback, xMin, xMax, yMin, yMax, colors, monitorSide)` | Constructor; creates a new button. Colors is an optional table with keys `text`, `background`, `enabled` and `disabled`. They are all optional and default to `colors.white`, `colors.black`, `colors.lime` and `colors.red`, respectively. MonitorSide specifies the side of the computer that the monitor you want to use is attached to. If left blank, it defaults to the first advanced monitor found.
`disable()` | Disables a button. Default is enabled. Note that unlike cheusler's original code, you can click on a disabled button, but not an invisible one.
`display()` | Display the button on screen.
`enable()` | Enables a button. Default is enabled.
`flash(interval)` | Disables the button, waits for the interval, and enables it again. The interval argument is optional and defaults to 0.15s.
`hide()` | Hide the button. Default is visible.
`show()` | Show the button. Default is visible.
`toggle()` | Toggle the button between enabled and disabled.

### Button attributes
Attribute | Description
----------|------------
`callback` | Callback function, gets called with the button as argument when the button gets clicked.
`colors` | Table with keys `background`, `disabled`, `enabled`, `text`. See the colors API for valid values.
`enabled` | True if the button is enabled. Switches the color used when rendering, can be used by the callback for other uses.
`monitor` | Monitor the button is rendered to. See `setMonitor` above for remarks about multi-monitor use.
`text` | Button text.
`visible` | True if the button is visible. If false, the button cannot be clicked.
`x` | Table with min/max values on the x axis (horizontal)
`y` | Table with min/max values on the y axis (vertical)

<a name="demo"/>
Combined Demo
-------------

Here's an example of how it all fits together:

```lua
os.loadAPI("libccevent")
os.loadAPI("libccbutton")

eventHandler = libccevent.ccEvent()

testButton = libccbutton.Button("Test", function(button)
		print "Test button clicked!"
		button:setMonitor("right")
		button:toggle()
		return true
	end, 5, 15, 5, 15)

testButton2 = libccbutton.Button("Test2", function(button)
		print "Test2 button clicked!"
		button:toggle()
		return true
	end, 20, 30, 5, 15)

testButtonRight = libccbutton.Button("TestRight", function(button)
		print "TestRight button clicked!"
		button:toggle()
		return true
	end, 20, 30, 5, 15, nil, "right")


testButton:registerWith(eventHandler)
testButton2:registerWith(eventHandler)
testButtonRight:registerWith(eventHandler)

eventHandler:doEventLoop()
```
