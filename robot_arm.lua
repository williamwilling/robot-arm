local print_backup = print
require 'wx'
print = print_backup

package.loaded.robot_arm = true

local t = debug.getinfo(3)

local arm = {
  position = 0
}

local frame = wx.wxFrame(
  wx.NULL,
  wx.wxID_ANY,
  "Robot Arm",
  wx.wxDefaultPosition,
  wx.wxSize(550, 450),
  wx.wxDEFAULT_FRAME_STYLE)

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

wx.wxGetApp():MainLoop()