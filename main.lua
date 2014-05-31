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

while true do
  direction = robot_arm.move_right
  
  if math.random() > 0.5 then
    direction = robot_arm.move_left
  end
  
  for i = 1, math.random(5) do
    direction(robot_arm)
  end
  
  robot_arm:grab()
  
  direction = robot_arm.move_right
  
  if math.random() > 0.5 then
    direction = robot_arm.move_left
  end
  
  for i = 1, math.random(5) do
    direction(robot_arm)
  end
  
  robot_arm:drop()
end