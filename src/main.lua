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
