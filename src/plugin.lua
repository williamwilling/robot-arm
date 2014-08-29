local api = {
  robot_arm = {
    type = "class",
    description = "A simulation of a robot arm that helps you to learn how to program.",
    
    childs = {
      move_left = {
        type = "method",
        description = "Moves the robot arm one spot to the left. If the robot arm is already at the left-most spot, this function does nothing.",
        args = "()",
        returns = ""
      },
      
      move_right = {
        type = "method",
        description = "Moves the robot arm one spot to the right. If the robot arm is already at the right-most spot, this function does nothing.",
        args = "()",
        returns = ""
      },
      
      grab = {
        type = "method",
        description = "Grabs the block that is on top of the stack the robot arm is hovering over. If the stack is empty, the robot arm still tries to grab a block, but will return empty-handed.",
        args = "()",
        returns = ""
      },
      
      drop = {
        type = "method",
        description = "Drops the block the robot arm is holding on the stack the robot arm is hovering over. If the robot arm isn't holding a block, it still tries to drop a block, but without effect.",
        args = "()",
        returns = ""
      },
      
      scan = {
        type = "method",
        description = "Scans the block the robot arm is currently holding to determine its color. Returns the color as a string, or nil if the robot arm isn't holding a block.",
        args = "()",
        returns = "(string)"
      },
      
      speed = {
        type = "value",
        description = "The speed with which the robot arm moves, ranging from 0 to 1. A speed of 1 means that the robot arm does its job without animating, so will only see the begin situation and the end result."
      },
      
      random_level = {
        type = "method",
        description = "Places blocks randomly throughout the level. You can specify the number of columns (starting at the left) you want to fill with blocks. Default is 5.",
        args = "(columns: number)",
        returns = "()"
      }
    }
  }
}

return {
  name = "Robot Arm",
  description = "A simulation of a robot arm that helps you to learn how to program.",
  author = "William Willing",
  version = 1,
  
  onRegister = function()
    ide:AddAPI("lua", "robot_arm", api)
    table.insert(ide.interpreters.luadeb.api, "robot_arm")
    ReloadLuaAPI()
  end,
  
  onUnRegister = function()
    ide:RemoveAPI("lua", "robot_arm")

    for i, v in ipairs(ide.interpreters.luadeb.api) do
      if v == "robot_arm" then
        table.remove(ide.interpreters.luadeb.api, i)
        break
      end
    end
  end
}