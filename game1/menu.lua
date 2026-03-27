local Menu = {}
local StateManager = require("statemanager")

function Menu:draw()
  
    love.graphics.setColor(0, 1, 1)
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.printf("ECLIPSE PROTOCOL", 0, 150, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Press SPACE to Start", 0, 300, love.graphics.getWidth(), "center")
    love.graphics.printf("Press I for Instructions", 0, 350, love.graphics.getWidth(), "center")
    love.graphics.printf("Press ESC to Quit", 0, 400, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.setFont(love.graphics.newFont(16))
    love.graphics.printf("WASD: Move | Shift: Dash | Collect energy to advance", 0, 550, love.graphics.getWidth(), "center")
end

function Menu:keypressed(key)
    if key == "space" then
        StateManager:setState(StateManager.states.PLAYING)
    elseif key == "i" then
        StateManager:setState(StateManager.states.INSTRUCTIONS)
    elseif key == "escape" then
        love.event.quit()
    end
end

return Menu