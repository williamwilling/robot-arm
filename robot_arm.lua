-- Since the main scripts (i.e. the script that requires the robot_arm library)
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
local next_function

local function suspend_event_loop()
  -- here we are inside the event loop
  coroutine.resume(main)
  
  -- here we are inside the event loop
  next_function()
end

local function resume_event_loop()
  -- here we are inside the main script
  coroutine.yield()
  
  -- here we are inside the main script
end

local arm = {
  position = 0
}

local station_width = 50
local station_count = 10
local block_width = 40
local block_height = 40
local line_position = 400

local function draw_arm(dc)
  local left = arm.position * station_width + 5
  local mid = left + (station_width / 2 - 5)
  local right = mid + (station_width / 2 - 5)

  dc:DrawLine(mid, 0, mid, 10)
  dc:DrawLine(left, 10, right, 10)
  dc:DrawLine(left, 10, left, 20)
  dc:DrawLine(right, 10, right, 20)
  
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
    dc:DrawRectangle(left + 1, 11, station_width - 10 - 1, station_width - 10)
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

local function move_right()
  local timer = wx.wxTimer(frame)
  local count = 0
  local new_position = arm.position + 1
  
  local frames = 25
  
  frame:Connect(wx.wxEVT_TIMER, function()
    arm.position = arm.position + 1 / frames
    frame:Refresh()
    frame:Update()
    
    count = count + 1
    if count == frames then
      arm.position = new_position
      frame:Disconnect(wx.wxEVT_TIMER)
      
      next_function = nil
      suspend_event_loop()
    end
  end)

  timer:Start(1000 / frames)
end

function robot_arm:move_right()
  next_function = move_right
  
  --[[
  frame:Connect(wx.wxEVT_IDLE, function()
    print(coroutine.status(main))
    frame:Disconnect(wx.wxEVT_IDLE)
    
    if next_function ~= nil then
      next_function()
    end
  end)
--]]
  
  resume_event_loop()
end

function robot_arm:move_left()
  local old = arm.position
  
  for i = arm.position, arm.position - 1, -0.01 do
    arm.position = i
    
    frame:Refresh()
    frame:Update()
    wx.wxMilliSleep(10)
  end
  
  arm.position = old - 1
end

function robot_arm:grab()
  local stack = robot_arm.assembly_line[arm.position + 1]
  arm.holding = stack[#stack]
  stack[#stack] = nil
  
  frame:Refresh()
  frame:Update()
end

function robot_arm:drop()
  local stack = robot_arm.assembly_line[arm.position + 1]
  table.insert(stack, arm.holding)
  arm.holding = nil
  
  frame:Refresh()
  frame:Update()
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
  suspend_event_loop()
end)

--[[
frame:Connect(wx.wxEVT_IDLE, function()
  frame:Disconnect(wx.wxEVT_IDLE)
  
  if next_function ~= nil then
    next_function()
  end
end)
--]]
wx.wxGetApp():MainLoop()