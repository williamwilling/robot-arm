require 'robot_arm'

robot_arm.assembly_line = { 'r', 'g', 'b', '', 'y' }

robot_arm:move_right()
robot_arm:move_right()
robot_arm:move_left()
robot_arm:move_left()