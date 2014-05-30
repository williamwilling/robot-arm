require 'robot_arm'

robot_arm.assembly_line = {
  { 'red', 'green' },
  { 'green' },
  { 'blue', 'white', 'blue' },
  {},
  { 'white' },
  {},
  {},
  {},
  {},
  {}
}

robot_arm:grab()
robot_arm:move_right()
robot_arm:move_left()
robot_arm:move_right()
robot_arm:move_left()
robot_arm:move_right()