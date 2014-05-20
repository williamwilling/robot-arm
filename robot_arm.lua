local print = print
require 'wx'
_G.print = print

local require = require
_G.require = function(modname)
  if modname ~= 'robot_arm' then
    require(modname)
  end
end

local t = debug.getinfo(3)

local arm = {
  position = 0
}

local frame = wx.wxFrame(
  wx.NULL,
  wx.wxID_ANY,
  "Robot Arm",
  wx.wxDefaultPosition,
  wx.wxSize(450, 450),
  wx.wxDEFAULT_FRAME_STYLE)

local station_width = 50
local block_width = 40
local block_height = 40

local function draw_arm(dc)
  local left = arm.position * station_width + 5
  local mid = left + (station_width / 2 - 5)
  local right = mid + (station_width / 2 - 5)

  dc:DrawLine(mid, 0, mid, 10)
  dc:DrawLine(left, 10, right, 10)
  dc:DrawLine(left, 10, left, 20)
  dc:DrawLine(right, 10, right, 20)
  
  if type(arm.holding) == 'string' then
    dc:DrawRectangle(left + 1, 11, station_width - 10 - 1, station_width - 10)
  end
end

local function draw_assembly_line(dc)
  for i = 1, 10 do
    local left = (i - 1) * station_width
    local right = left + station_width
    
    dc:DrawLine(left, 200, right, 200)
    dc:DrawLine(left, 195, left, 200)
    dc:DrawLine(right, 195, right, 200)
    
    local stack = robot_arm.assembly_line[i]
    if type(stack) == 'table' then
      for level, block in ipairs(stack) do
        dc:DrawRectangle(left + 5, 200 - block_height * level, block_width, block_height)
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

frame:Show(true)
frame:Connect(wx.wxEVT_PAINT, paint)

frame:Connect(wx.wxEVT_ACTIVATE, function()
    t.func()
    os.exit()
  end)

robot_arm = {}
robot_arm.assembly_line = {}

function robot_arm:move_right()
  local old = arm.position
  
  for i = arm.position, arm.position + 1, 0.01 do
    arm.position = i
    
    frame:Refresh()
    frame:Update()
    wx.wxMilliSleep(10)
  end
  
  arm.position = old + 1
end

function robot_arm:move_left()
  local old = arm.position
  
  for i = arm.position, arm.position - 1, -0.01 do
    arm.position = i
    
    frame:Refresh()
    frame:Update()
    wx.wxMilliSleep(10)
  end
  
  arm.position = old + 1
end

function robot_arm:grab()
  local stack = robot_arm.assembly_line[arm.position + 1]
  arm.holding = stack[#stack]
  stack[#stack] = nil
end

function robot_arm:drop()
  local stack = robot_arm.assembly_line[arm.position + 1]
  table.insert(stack, arm.holding)
  arm.holding = nil
end

wx.wxGetApp():MainLoop()