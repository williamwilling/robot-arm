require 'robot_arm'

robot_arm.assembly_line = { {'r', 'g'}, {'g'}, {'b'}, {}, {'y'} }


robot_arm:move_right()
robot_arm:grab()

robot_arm:move_right()
robot_arm:drop()

robot_arm:move_left()