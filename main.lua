require 'robot_arm'

robot_arm.assembly_line = {
  { 'red', 'green' },
  { 'green' },
  { 'blue', 'white', 'blue' },
  { 'green', 'red', 'blue', 'white', 'green'},
  { 'white' },
  { 'red', 'red', 'blue' },
  {},
  {},
  {},
  {}
}

robot_arm.speed = 1

function find_gap()
  local counter = 0
  
  while true do
    robot_arm:grab()
    
    if robot_arm:scan() == nil then
      return counter
    end
    
    robot_arm:drop()
    robot_arm:move_right()
    counter = counter + 1
  end
end

function move_stack_right()
  local counter = 0
  robot_arm:grab()
  
  while robot_arm:scan() ~= nil do
    robot_arm:move_right()
    robot_arm:move_right()
    robot_arm:drop()
    robot_arm:move_left()
    robot_arm:move_left()
    robot_arm:grab()
    counter = counter + 1
  end
  
  return counter
end

function move_stack_left(count)
  for i = 1, count do
    robot_arm:grab()
    robot_arm:move_left()
    robot_arm:drop()
    robot_arm:move_right()
  end
end

local stack_count = find_gap()

for i = 1, stack_count do
  robot_arm:move_left()
  local stack_size = move_stack_right()
  robot_arm:move_right()
  robot_arm:move_right()
  move_stack_left(stack_size)
  robot_arm:move_left()
  robot_arm:move_left()
end

robot_arm:wait()