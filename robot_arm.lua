require 'wx'

local frame = wx.wxFrame(
  wx.NULL,
  wx.wxID_ANY,
  "Robot Arm",
  wx.wxDefaultPosition,
  wx.wxSize(450, 450),
  wx.wxDEFAULT_FRAME_STYLE)

local function paint()
  local dc = wx.wxPaintDC(frame)
  
  dc:DrawLine(25, 0, 25, 10)
  dc:DrawLine(5, 10, 45, 10)
  dc:DrawLine(5, 10, 5, 20)
  dc:DrawLine(45, 10, 45, 20)
  
  dc:delete()
end

frame:Show(true)
frame:Connect(wx.wxEVT_PAINT, paint)

robot_arm = {}

function robot_arm:wait()
  wx.wxGetApp():MainLoop()
end