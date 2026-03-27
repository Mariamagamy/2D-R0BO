local Instructions = {}
local StateManager = require("statemanager")

function Instructions:draw()
    love.graphics.setColor(0, 0, 0, 0.9)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.setColor(0, 1, 1)
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.printf("HOW TO PLAY", 0, 80, love.graphics.getWidth(), "center")

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(24))
    
    local y = 180
    local lineHeight = 40
    
    love.graphics.printf("WASD: Move", 0, y, love.graphics.getWidth(), "center")
    love.graphics.printf("Shift: Dash", 0, y + lineHeight, love.graphics.getWidth(), "center")
    love.graphics.printf("ESC: Pause", 0, y + lineHeight * 2, love.graphics.getWidth(), "center")
    love.graphics.printf("M: Menu", 0, y + lineHeight * 3, love.graphics.getWidth(), "center")
    love.graphics.printf("Collect energy to advance to next level", 0, y + lineHeight * 4, love.graphics.getWidth(), "center")
    love.graphics.printf("Avoid drones!", 0, y + lineHeight * 5, love.graphics.getWidth(), "center")
    
    love.graphics.setColor(0.5, 0.5, 0.5)
    love.graphics.printf("Press B to go Back", 0, 500, love.graphics.getWidth(), "center")
end

function Instructions:keypressed(key)
    if key == "b" or key == "escape" then
        StateManager:setState(StateManager.states.MENU)
    end
end

return Instructions