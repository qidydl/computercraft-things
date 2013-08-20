computercraft-things
====================

qid's libraries and programs for <a href="http://www.computercraft.info/">ComputerCraft</a>, a mod for Minecraft.

Tested with ComputerCraft v1.53 for Minecraft v1.5.2.

### Table of Contents
* [libCCClass](#libccclass)
* [libCCEvent](#libccevent)
* [libCCButton](#libccbutton)
* [Demo](#demo)

<a name="libccclass"/>
libCCClass
----------

Basic class library, not my code, will explain more later.

<a name="libccevent"/>
libCCEvent
----------

Event handling library, is my code, need to document.

<a name="libccbutton"/>
libCCButton
-----------

GUI Button library, only partially my code, need to document and explain.

<a name="demo"/>
Demo
----

Here's an example of how it all fits together:

```os.loadAPI("libccevent")
os.loadAPI("libccbutton")

eventHandler = libccevent.ccEvent()

testButton = libccbutton.Button("Test", function(button)
		print "Test button clicked!"
		button:toggle()
		return true
	end, 5, 15, 5, 15)

testButton2 = libccbutton.Button("Test2", function(button)
		print "Test2 button clicked!"
		button:toggle()
		return true
	end, 20, 30, 5, 15)

testButton:registerWith(eventHandler)
testButton2:registerWith(eventHandler)

eventHandler:doEventLoop()```