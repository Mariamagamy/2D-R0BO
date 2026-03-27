local Pause = {}
local StateManager = require("statemanager")

function Pause:draw()
    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    
    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(love.graphics.newFont(48))
    love.graphics.printf("PAUSED", 0, 200, love.graphics.getWidth(), "center")
    
    love.graphics.setFont(love.graphics.newFont(24))
    love.graphics.printf("Press P to Resume", 0, 300, love.graphics.getWidth(), "center")
    love.graphics.printf("Press R to Restart", 0, 350, love.graphics.getWidth(), "center")
    love.graphics.printf("Press M for Menu", 0, 400, love.graphics.getWidth(), "center")
end

function Pause:keypressed(key)
    if key == "p" then
        StateManager:setState(StateManager.states.PLAYING)
    elseif key == "r" then
        love.load()
        StateManager:setState(StateManager.states.PLAYING)
    elseif key == "m" then
        love.load()
        StateManager:setState(StateManager.states.MENU)
    end
end

return Pause