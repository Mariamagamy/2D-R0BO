local StateManager = {}


local states = {
    MENU = "menu",
    PLAYING = "playing",
    PAUSED = "paused",
    GAMEOVER = "gameover",
    VICTORY = "victory",
    INSTRUCTIONS = "instructions",
    NEXT_LEVEL = "nextlevel"
}

local currentState = states.MENU
local previousState = nil

function StateManager:setState(newState)
    previousState = currentState
    currentState = newState
    
    if newState == states.GAMEOVER then
        if _G.main and _G.main.sounds and _G.main.sounds.gameover then
            _G.main.sounds.gameover:play()
        end
        if _G.main and _G.main.sounds and _G.main.sounds.background then
            _G.main.sounds.background:stop()
        end
    elseif newState == states.VICTORY then
        if _G.main and _G.main.sounds and _G.main.sounds.victory then
            _G.main.sounds.victory:play()
        end
    elseif newState == states.PLAYING then

        if _G.main and _G.main.sounds and _G.main.sounds.background then
            _G.main.sounds.background:play()
        end
    elseif newState == states.MENU then

        if _G.main and _G.main.sounds and _G.main.sounds.background then
            _G.main.sounds.background:stop()
        end
    end
    
    print("State changed to: " .. newState)
end

function StateManager:getState()
    return currentState
end

function StateManager:getPreviousState()
    return previousState
end

function StateManager:isPlaying()
    return currentState == states.PLAYING
end

function StateManager:isPaused()
    return currentState == states.PAUSED
end

StateManager.states = states

return StateManager