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
  level = 0
}

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

robot_arm = {}
robot_arm.assembly_line = {}

function animate(start_value, end_value, duration)
  return coroutine.create(function()
    local diff = end_value - start_value
    local stop_watch = wx.wxStopWatch()
    stop_watch:Start()
    
    local fraction = 0
    
    while fraction < 1 do
      coroutine.yield(start_value + diff * fraction)
      fraction = math.min(1, stop_watch:Time() / duration)
    end
    
    return end_value
  end)
end

local function loop_non_blocking(func)
  local timer = wx.wxTimer(frame)
  local frame_time = 33
  
  on_timer = function()
    if func() then
      timer:Start(frame_time, true)
    else
      on_timer = nil
      coroutine.resume(main)
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

function animate_arm(property_name, start_value, end_value, duration)
  local value = animate(start_value, end_value, duration)
  
  loop_non_blocking(function()
    refresh_arm(true)
    _, arm[property_name] = coroutine.resume(value)
    refresh_arm(false)
    
    return coroutine.status(value) ~= 'dead'
  end)
end

function robot_arm:move_right()
  local position = animate(arm.position, arm.position + 1, 1000)
  
  loop_non_blocking(function()
    refresh_arm(true)
    _, arm.position = coroutine.resume(position)
    refresh_arm(false)
    
    return coroutine.status(position) ~= 'dead'
  end)
end

function robot_arm:move_left()
  local position = animate(arm.position, arm.position - 1, 1000)
  
  loop_non_blocking(function()
    _, arm.position = coroutine.resume(position)
    frame:Refresh()
    
    return coroutine.status(position) ~= 'dead'
  end)
end

function robot_arm:grab()
  local stack = robot_arm.assembly_line[arm.position + 1]
  
  animate_arm('level', 0, level_count - #stack, 1000)
  
  arm.holding = stack[#stack]
  stack[#stack] = nil
  
  animate_arm('level', level_count - (#stack + 1), 0, 1000)
end

function robot_arm:drop()
  local stack = robot_arm.assembly_line[arm.position + 1]
  
  animate_arm('level', 0, level_count - (#stack + 1), 1000)
  
  table.insert(stack, arm.holding)
  arm.holding = nil
  
  animate_arm('level', level_count - #stack, 0, 1000)
end

function robot_arm:scan()
  return arm.holding
end

function robot_arm:wait(ms)
  if type(ms) == 'number' then
    wx.wxMilliSleep(ms)
  else
    while true do
      wx.wxMilliSleep(1000)
    end
  end
end

frame = wx.wxFrame(
  wx.NULL,
  wx.wxID_ANY,
  "Robot Arm",
  wx.wxDefaultPosition,
  wx.wxSize(550, 450),
  wx.wxDEFAULT_FRAME_STYLE)

frame:Show(true)
frame:Connect(wx.wxEVT_PAINT, paint)

frame:Connect(wx.wxEVT_ACTIVATE, function()
  frame:Disconnect(wx.wxEVT_ACTIVATE)
  coroutine.resume(main)
end)

frame:Connect(wx.wxEVT_TIMER, function()
  if type(on_timer) == 'function' then
    on_timer()
  end
end)

wx.wxGetApp():MainLoop()
os.exit()