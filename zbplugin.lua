return {
  name = "Robot Arm",
  description = "A simulation of a robot arm that helps you to learn how to program.",
  author = "William Willing",
  version = 1,
  
  install = function()
    local remotePath = "http://zerobranestore.blob.core.windows.net/robot-arm/"
    download(remotePath .. "robot_arm.lua", idePath .. "lualibs/robot_arm.lua")
    download(remotePath .. "plugin.lua", idePath .. "packages/robot_arm.lua")
  end
}