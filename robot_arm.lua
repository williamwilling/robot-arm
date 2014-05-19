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

local function draw_arm(dc)
  local left = arm.position * 50 + 5
  local mid = left + 20
  local right = mid + 20

  dc:DrawLine(mid, 0, mid, 10)
  dc:DrawLine(left, 10, right, 10)
  dc:DrawLine(left, 10, left, 20)
  dc:DrawLine(right, 10, right, 20)
end

local function paint()
  local dc = wx.wxPaintDC(frame)
  draw_arm(dc)
  
  dc:delete()
end

frame:Show(true)
frame:Connect(wx.wxEVT_PAINT, paint)

frame:Connect(wx.wxEVT_ACTIVATE, function()
    t.func()
    os.exit()
  end)

robot_arm = {}

function robot_arm:move_right()
  for i = arm.position, arm.position + 1, 0.01 do
    arm.position = i
    
    frame:Refresh()
    frame:Update()
    wx.wxMilliSleep(10)
  end
end

function robot_arm:move_left()
  for i = arm.position, arm.position - 1, -0.01 do
    arm.position = i
    
    frame:Refresh()
    frame:Update()
    wx.wxMilliSleep(10)
  end
end

wx.wxGetApp():MainLoop()