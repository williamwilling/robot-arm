require 'wx'

local frame = wx.wxFrame(
  wx.NULL,
  wx.wxID_ANY,
  "Robot Arm",
  wx.wxDefaultPosition,
  wx.wxSize(450, 450),
  wx.wxDEFAULT_FRAME_STYLE)

frame:Show(true)

robot_arm = {}

function robot_arm:wait()
  wx.wxGetApp():MainLoop()
end