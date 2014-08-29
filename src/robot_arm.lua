-- Since the main script (i.e. the script that requires the robot_arm library)
-- is called as a coroutine, we need to enable debugging of coroutines,
-- otherwise you can't debug the main script.
require('mobdebug').coro()

-- The wxLua-library nilifies the print function, so we need to store the print
-- function in a temporary variable and restore it after wxLua is loaded.
local print_backup = print
require 'wx'
print = print_backup

-- Since the robot_arm library calls the chunk that has required the robot_arm
-- library, the robot_arm library will be required twice. To prevent this, we
-- mark the robot_arm library as loaded. Normally, Lua does this automatically
-- at the end of the library script, but since we call the parent chunk before
-- loading of the robot_arm library completes, we need to do it ourselves here.
package.loaded.robot_arm = true

-- The script for the robot_arm library (i.e. the script you are reading now)
-- won't return to its caller, because at the end, we will start the event loop
-- for the window that shows the robot arm and that event loop won't exit.
-- We still need to run the caller's code, though. To do that, we get the
-- code from the caller and turn it into a coroutine. Later on, we'll run the
-- coroutine inside the event loop.
local info = debug.getinfo(3)

if info == nil then
  print("Since robot_arm.lua contains a library and not a program, you should")
  print("not run it directly. Instead, create a new Lua-file and use the")
  print("require-function to create a program that uses the robot_arm")
  print("library. For example:\n")
  print("    require 'robot_arm'\n")
  print("    robot_arm.grab()")
  print("    robot_arm.move_right()")
  print("    robot_arm.drop()\n")
  
  return
end

local main = coroutine.create(info.func)

local frame

local arm = {
  position = 0,
  level = 0,
  actions = 0
}

local max_duration = 2000
local station_width = 50
local station_count = 10
local block_width = 40
local block_height = 40
local arm_height = 10
local hand_height = 10
local level_count = 8
local line_position = arm_height + level_count * block_height

local function draw_arm(dc)
  local mid = (0.5 + arm.position) * station_width
  local left = mid - block_width / 2 - 1
  local right = mid + block_width / 2
  
  local top = arm_height + arm.level * block_height

  dc:DrawLine(mid, 0, mid, top)
  dc:DrawLine(left, top, right, top)
  dc:DrawLine(left, top, left, top + hand_height)
  dc:DrawLine(right, top, right, top + hand_height)
  
  if type(arm.holding) == 'string' then
    local color = wx.wxWHITE_BRUSH
        
    if arm.holding == 'r' or arm.holding == 'red' then
      color = wx.wxRED_BRUSH
    elseif arm.holding == 'g' or arm.holding == 'green' then
      color = wx.wxGREEN_BRUSH
    elseif arm.holding == 'b' or arm.holding == 'blue' then
      color = wx.wxBLUE_BRUSH
    end
    
    dc:SetBrush(color)
    dc:DrawRectangle(left + 1, top + 1, block_width, block_height)
  end
end

local function draw_assembly_line(dc)
  for i = 1, station_count do
    local left = (i - 1) * station_width
    local right = left + station_width
    
    dc:DrawLine(left, line_position, right, line_position)
    dc:DrawLine(left, line_position - 5, left, line_position)
    dc:DrawLine(right, line_position - 5, right, line_position)
    
    local stack = robot_arm.assembly_line[i]
    if type(stack) == 'table' then
      for level, block in ipairs(stack) do
        local color = wx.wxWHITE_BRUSH
        
        if block == 'r' or block == 'red' then
          color = wx.wxRED_BRUSH
        elseif block == 'g' or block == 'green' then
          color = wx.wxGREEN_BRUSH
        elseif block == 'b' or block == 'blue' then
          color = wx.wxBLUE_BRUSH
        end
        
        dc:SetBrush(color)
        dc:DrawRectangle(left + 5, line_position - block_height * level, block_width, block_height)
      end
    end
  end
end

local function paint()
  local dc = wx.wxPaintDC(frame)
  draw_arm(dc)
  draw_assembly_line(dc)
  
  dc:delete()
end

robot_arm = {
  speed = 0.5,
  assembly_line = {}
}

for i = 1, station_count do
  table.insert(robot_arm.assembly_line, {})
end

function animate(start_value, end_value, duration)
  local actual_duration = duration * 0.5
  
  if type(robot_arm.speed) == 'number' then
    actual_duration = duration * (1 - math.min(1, robot_arm.speed))
  end
  
  if actual_duration < 1 then
    actual_duration = 0
  end
  
  return coroutine.create(function()
    local diff = end_value - start_value
    local stop_watch = wx.wxStopWatch()
    stop_watch:Start()
    
    local fraction = math.min(1, stop_watch:Time() / actual_duration)
    
    while fraction < 1 do
      coroutine.yield(start_value + diff * fraction)
      fraction = math.min(1, stop_watch:Time() / actual_duration)
    end
    
    return end_value
  end)
end

local function loop_non_blocking(func)
  local timer = wx.wxTimer(frame)
  local frame_time = 20
  
  on_timer = function()
    if func() then
      timer:Start(frame_time, true)
    else
      on_timer = nil
      success, result = coroutine.resume(main)
      
      if not success then
        error(result)
      end
    end
  end
  
  timer:Start(frame_time, true)
  
  coroutine.yield()
end

local function refresh_arm(erase_background)
  local left = arm.position * station_width
  local width = station_width
  local top = 0
  local height = arm_height + arm.level * block_height + hand_height
  
  if arm.holding ~= nil then
    height = height + block_height
  end
  
  frame:Refresh(erase_background, wx.wxRect(left, top, width, height))
end

local function increase_actions()
  arm.actions = arm.actions + 1
  frame:SetTitle('Robot Arm - steps: ' .. arm.actions)
end

function animate_arm(property_name, start_value, end_value, duration)
  --[[
  if duration <= 0 then
    refresh_arm(true)
    arm[property_name] = end_value
    refresh_arm(false)
    return
  end
  --]]
  
  if robot_arm.speed >= 1 then
    arm[property_name] = end_value
    return
  end
  
  local value = animate(start_value, end_value, duration)
  
  loop_non_blocking(function()
    refresh_arm(true)
    
    success, result = coroutine.resume(value)
    
    if not success then
      error(result)
    else
      arm[property_name] = result
    end
    
    refresh_arm(false)
    
    return coroutine.status(value) ~= 'dead'
  end)
end

function robot_arm:move_right()
  if arm.position >= station_count - 1 then
    return
  end
  
  animate_arm('position', arm.position, arm.position + 1, max_duration)
  increase_actions()
end

function robot_arm:move_left()
  if arm.position <= 0 then
    return
  end
  
  animate_arm('position', arm.position, arm.position - 1, max_duration)
  increase_actions()
end

function robot_arm:grab()
  local stack = robot_arm.assembly_line[arm.position + 1]
  local grab_level = level_count - #stack
  
  if #stack == 0 then
    grab_level = grab_level - 1
  end
  
  if arm.holding ~= nil then
    grab_level = grab_level - 1
  end
  
  animate_arm('level', 0, grab_level, max_duration)
  
  if arm.holding == nil then
    arm.holding = stack[#stack]
    stack[#stack] = nil
  end
  
  animate_arm('level', grab_level, 0, max_duration)
  increase_actions()
end

function robot_arm:drop()
  local stack = robot_arm.assembly_line[arm.position + 1]
  local drop_level = level_count - #stack - 1
  
  animate_arm('level', 0, drop_level, max_duration)
  
  table.insert(stack, arm.holding)
  arm.holding = nil
  
  animate_arm('level', drop_level, 0, max_duration)
  increase_actions()
end

function robot_arm:scan()
  increase_actions()
  return arm.holding
end

function robot_arm:wait(seconds)
  if type(seconds) == 'number' then
    
    on_timer = function()
      on_timer = nil
        
      local success, result = coroutine.resume(main)
      
      if not success then
        error(result)
      end
    end
    
    local timer = wx.wxTimer(frame)
    timer:Start(seconds * 1000, true)
  end
   
  coroutine.yield()
  
  frame:Refresh()
end

-- Predefined levels.
math.randomseed(os.time())

local levels = {
  ['exercise 1'] = { {}, { 'red' } },
  ['exercise 2'] = { { 'blue' }, {}, {}, {}, { 'blue' }, {}, {}, { 'blue' } },
  ['exercise 3'] = { { 'white', 'white', 'white', 'white' } },
  ['exercise 4'] = { { 'blue', 'white', 'green' } },
  ['exercise 5'] = { {}, { 'red', 'red', 'red', 'red', 'red', 'red', 'red' } },
  ['exercise 6'] = { { 'red' }, { 'blue' }, { 'white' }, { 'green' }, { 'green' }, { 'blue' }, { 'red' }, { 'white' } },
  ['exercise 7'] = { {}, { 'blue', 'blue', 'blue', 'blue', 'blue', 'blue' }, {}, { 'blue', 'blue', 'blue', 'blue', 'blue', 'blue' }, {}, { 'blue', 'blue', 'blue', 'blue', 'blue', 'blue' }, {}, { 'blue', 'blue', 'blue', 'blue', 'blue', 'blue' }, {}, { 'blue', 'blue', 'blue', 'blue', 'blue', 'blue' } },
  ['exercise 9'] = { { 'blue' }, { 'green', 'green' }, { 'white', 'white', 'white' }, { 'red', 'red', 'red', 'red' } },
  ['exercise 10'] = { { 'green' }, { 'blue' }, { 'white' }, { 'red' }, { 'blue' } },
  ['exercise 11'] = function()
    for i = 2, station_count do
      local colors = { 'red', 'green', 'white', 'blue' }
      local color = colors[math.random(#colors)]
      robot_arm.assembly_line[i] = { color }
    end
  end,
  ['exercise 12'] = function()
    for i = 1, station_count - 1 do
      local colors = { 'red', 'green', 'white', 'blue' }
      local color = colors[math.random(#colors)]
      robot_arm.assembly_line[i] = { color }
    end
  end,
  ['exercise 13'] = function()
    for i = 1, station_count do
      local colors = { 'red', 'green', 'white', 'blue' }
      local color = colors[math.random(#colors)]
      robot_arm.assembly_line[i] = { color }
    end
  end,
  ['exercise 14'] = function()
    for i = 2, station_count do
      robot_arm.assembly_line[i] = {}
      
      for _ = 1, math.random(3) do
        local colors = { 'red', 'green', 'white', 'blue' }
        local color = colors[math.random(#colors)]
        table.insert(robot_arm.assembly_line[i], color)
      end
    end
  end,
  ['exercise 15'] = function()
    for i = 1, station_count do
      local colors = { 'red', 'green', 'white', 'blue', 'none', 'none' }
      local color = colors[math.random(#colors)]
      
      if color ~= 'none' then
        robot_arm.assembly_line[i] = { color }
      end
    end
  end
}

levels['exercise 8'] = levels['exercise 5']

function robot_arm:load_level(name)
  local level = levels[name]
  
  if type(level) == 'table' then
    robot_arm.assembly_line = level
  elseif type(level) == 'function' then
    level()
  end
  
  for i = 1, station_count do
    if robot_arm.assembly_line[i] == nil then
      robot_arm.assembly_line[i] = {}
    end
  end
end

function robot_arm:random_level(column_count)
  local level = {}
  
  for i = 1, station_count do
    level[i] = {}
  end
  
  for i = 1, column_count or 5 do
    level[i] = {}
    
    for _ = 1, math.random(6) do
      colors = { 'red', 'green', 'blue', 'white' }
      color = colors[math.random(4)]
      table.insert(level[i], color)
    end
  end
  
  robot_arm.assembly_line = level
end

frame = wx.wxFrame(
  wx.NULL,
  wx.wxID_ANY,
  "Robot Arm",
  wx.wxDefaultPosition,
  wx.wxSize(18 + station_count * station_width, arm_height + (level_count + 1) * block_height),
  wx.wxDEFAULT_FRAME_STYLE)

frame:Show(true)
frame:Connect(wx.wxEVT_PAINT, paint)

frame:Connect(wx.wxEVT_ACTIVATE, function()
  frame:Disconnect(wx.wxEVT_ACTIVATE)
  frame:Raise()
  frame:SetFocus()
  
  success, result = coroutine.resume(main)
  
  if not success then
    error(result)
  end
end)

frame:Connect(wx.wxEVT_TIMER, function()
  if type(on_timer) == 'function' then
    on_timer()
  end
end)

if not wx.wxGetApp():IsMainLoopRunning() then
  wx.wxGetApp():MainLoop()
  os.exit()
else
  success, result = coroutine.resume(main)
end