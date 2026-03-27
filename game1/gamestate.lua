local StateManager = {}


local states = {
    MENU = "menu",
    PLAYING = "playing",
    PAUSED = "paused",
    GAMEOVER = "gameover",
    VICTORY = "victory",
    NEXT_LEVEL = "nextlevel"  
}

local currentState = states.MENU
local previousState = nil

function StateManager:setState(newState)
    previousState = currentState
    currentState = newState
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