Robot Arm
===========
Robot Arm is a Lua library for learning how to program. It simulates a robot arm that can grab and drop colored blocks.

The purpose of Robot Arm is similar to that of the classic turtle, but Robot Arm is better suited for slightly more complex program flow. Where the turtle mainly teaches you that the order of instructions is important, Robot Arm allows and encourages you to use loops, functions and data structures to build your own operations and algorithms.

The number of operations Robot Arm supports is intentionally limited. You can (and should) build more complex operations yourself from the basic building blocks.

Prerequisites
-------------
* wxLua

Robot Arm is written to be used in ZeroBrane Studio. It should/might work without ZeroBrane Studio, but that hasn't been tested yet. 

Installation
------------
To use Robot Arm, just copy *robot_arm.lua* (from the *src* folder) to the folder that contains your Lua libraries.

Alternatively, you can copy *robot_arm.lua* to the same folder your program runs in, but then you have to make a copy for each program you write.

Usage
-----
Simply add `require "robot_arm"` to the top of your Lua file.

The robot arm understands six instructions: `move_left()`, `move_right()`, `grab()`, `drop()`, `scan()`, and `wait()`. You can also set the robot arm's `speed` on a scale of 0 to 1. If `speed` is equal to 1, you won't see any animations.

Levels
------
Robot Arm comes with a couple of build-in levels. You can use `load_level(name)` to load a build-in level, where *name* is `"exercise 1"`, `"exercise 2"`, `"exercise 3"`, etc. Note that these build-in levels are subject to change.

You can also create a set of random blocks with `random_level()`. 

Example
-------
    require "robot_arm"

	robot_arm.speed = 0.85
	robot_arm:random_level()
	
	robot_arm:grab()
	robot_arm:move_right()
	robot_arm:drop()
	robot_arm:move_right()
	
	robot_arm:wait(2)
	
	robot_arm:grab()
	
	if robot_arm:scan() == "red" then
	  robot_arm:move_left()
	  robot_arm:move_left()
	end
	
	robot_arm:drop()

Known issues
------------
* You must use the name *robot_arm* when you require the library. This means that library must be on Lua's library path, because something like `require "libs.robot_arm"` won't work.
* In ZeroBrane Studio, you can't use Robot Arm from the local console yet.
