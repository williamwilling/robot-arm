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

robot_arm:move_right()
robot_arm:move_right()
print(robot_arm:scan())
robot_arm:grab()
print(robot_arm:scan())

robot_arm:move_right()
print(robot_arm:scan())
robot_arm:drop()
print(robot_arm:scan())

robot_arm:move_left()
robot_arm:wait()