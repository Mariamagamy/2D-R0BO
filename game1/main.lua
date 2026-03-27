local gameTime = 0

local Player = require("player")
local Patrol = require("patrol")
local Hunter = require("hunter")
local collision = require("collision")
local UI = require("ui")
local StateManager = require("statemanager")
local RoomGen = require("roomgen")
local Map = require("map")

_G.main = {}

local shakeIntensity = 0
local shakeDuration = 0

local particles = {}
local damageNumbers = {}
local enemyDeaths = {}
local powerups = {}
local powerupTimer = 0
local activePowerup = nil

local door = nil
local doorTransition = false
local transitionTimer = 0
local transitionDuration = 1.0
local doorCreated = false

local levelTimer = 0
local levelTimeLimit = 120

local firstPlay = true
local firstPlayMessage = false

local levelColors = {
    {0.35, 0.25, 0.55},
    {0.25, 0.2, 0.45},
    {0.15, 0.15, 0.35},
    {0.08, 0.1, 0.25},
    {0.03, 0.05, 0.15}
}

function createCollectParticles(x, y)
    for i = 1, 8 do
        table.insert(particles, {
            x = x + 15, y = y + 15,
            vx = math.random(-100, 100) * 0.5,
            vy = math.random(-200, 0) * 0.5,
            life = 1, maxLife = 1, size = math.random(4, 8),
            color = {0.5, 0.3, 0.9}
        })
    end
end

function createDamageNumber(x, y, amount)
    table.insert(damageNumbers, {x = x, y = y, amount = amount, life = 1, maxLife = 1, vy = -50})
end

function createEnemyDeath(x, y)
    for i = 1, 12 do
        table.insert(enemyDeaths, {
            x = x + 20, y = y + 20,
            vx = math.random(-150, 150), vy = math.random(-200, -50),
            life = 1, maxLife = 1, size = math.random(4, 10),
            color = {0.6, 0.3, 0.8, math.random()}
        })
    end
end

function spawnPowerup()
    local attempts = 0
    while attempts < 50 do
        local col = love.math.random(2, Map.COLS - 1)
        local row = love.math.random(2, Map.ROWS - 1)
        if worldMap.tiles[row][col] == Map.FLOOR then
            local types = {"speed", "shield"}
            local pType = types[math.random(#types)]
            table.insert(powerups, {
                x = (col - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 15,
                y = (row - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 15,
                width = 30, height = 30,
                type = pType,
                collected = false
            })
            break
        end
        attempts = attempts + 1
    end
end

function applyPowerup(type)
    activePowerup = type
    powerupTimer = 5
    if type == "speed" then
        player.speed = player.speed * 1.5
        if main.sounds and main.sounds.powerup then
            main.sounds.powerup:stop()
            main.sounds.powerup:play()
        end
    elseif type == "shield" then
        player.invulnerable = true
        player.invulnerableTimer = 5
        if main.sounds and main.sounds.powerup then
            main.sounds.powerup:stop()
            main.sounds.powerup:play()
        end
    end
end

function createDoor()
    local attempts = 0
    local placed = false
    
    while not placed and attempts < 100 do
        local col = love.math.random(3, Map.COLS - 2)
        local row = love.math.random(3, Map.ROWS - 2)
        
        if worldMap.tiles[row][col] == Map.FLOOR then
            local playerCol = math.floor((player.x + player.width/2) / Map.TILE_SIZE) + 1
            local playerRow = math.floor((player.y + player.height/2) / Map.TILE_SIZE) + 1
            local distance = math.sqrt((col - playerCol)^2 + (row - playerRow)^2)
            
            local enemyNear = false
            for _, p in ipairs(patrols) do
                local enemyCol = math.floor((p.x + p.width/2) / Map.TILE_SIZE) + 1
                local enemyRow = math.floor((p.y + p.height/2) / Map.TILE_SIZE) + 1
                if math.abs(enemyCol - col) < 2 and math.abs(enemyRow - row) < 2 then
                    enemyNear = true
                    break
                end
            end
            for _, h in ipairs(hunters) do
                local enemyCol = math.floor((h.x + h.width/2) / Map.TILE_SIZE) + 1
                local enemyRow = math.floor((h.y + h.height/2) / Map.TILE_SIZE) + 1
                if math.abs(enemyCol - col) < 2 and math.abs(enemyRow - row) < 2 then
                    enemyNear = true
                    break
                end
            end
            
            if distance > 6 and not enemyNear then
                door = {
                    x = (col - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 30,
                    y = (row - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 30,
                    width = 60,
                    height = 60,
                    col = col,
                    row = row
                }
                placed = true
                doorCreated = true
            end
        end
        attempts = attempts + 1
    end
    
    if not door then
        door = {
            x = (Map.COLS - 2) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 30,
            y = (Map.ROWS - 2) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 30,
            width = 60,
            height = 60,
            col = Map.COLS - 2,
            row = Map.ROWS - 2
        }
        doorCreated = true
    end
end

function generateNewWorld()
    local seed = os.time()
    worldMap = RoomGen.generateMap(seed, currentLevel)
    _G.worldMap = worldMap
    
    walls = RoomGen.mapToWalls(worldMap)
    _G.walls = walls
    
    world.width = worldMap.width
    world.height = worldMap.height
    
    energyCells = RoomGen.spawnEnergy(worldMap, 20 + currentLevel * 5)
    
    local spawn = RoomGen.findSpawnPoint(worldMap)
    player.x = spawn.x
    player.y = spawn.y
    
    spawnEnemies()
    
    powerups = {}
    for i = 1, 3 do
        spawnPowerup()
    end
    
    door = nil
    doorCreated = false
    doorTransition = false
    
    levelTimer = 0
end

function spawnEnemies()
    local playerGridX = math.floor(player.x / Map.TILE_SIZE) + 1
    local playerGridY = math.floor(player.y / Map.TILE_SIZE) + 1
    
    local patrolPositions, hunterPositions = RoomGen.spawnEnemies(worldMap, playerGridX, playerGridY, currentLevel)
    
    patrols = {}
    hunters = {}
    
    for _, pos in ipairs(patrolPositions) do
        local newPatrol = Patrol:new()
        newPatrol.x = pos.x
        newPatrol.y = pos.y
        newPatrol.horizontal = pos.horizontal
        newPatrol.startX = pos.x
        newPatrol.endX = pos.x + 300
        table.insert(patrols, newPatrol)
    end
    
    for _, pos in ipairs(hunterPositions) do
        local newHunter = Hunter:new(player)
        newHunter.x = pos.x
        newHunter.y = pos.y
        newHunter.startX = pos.x
        newHunter.startY = pos.y
        table.insert(hunters, newHunter)
    end
end

function resetLevel()
    player.health = player.maxHealth
    player.energy = 0
    gameTime = 0
    activePowerup = nil
    powerupTimer = 0
    player.speed = 180
    levelTimer = 0
end

function nextLevel()
    if currentLevel < maxLevel then
        currentLevel = currentLevel + 1
        
        if currentLevel == 1 then targetEnergy = 150
        elseif currentLevel == 2 then targetEnergy = 300
        elseif currentLevel == 3 then targetEnergy = 500
        elseif currentLevel == 4 then targetEnergy = 800
        elseif currentLevel == 5 then targetEnergy = 1200
        end
        
        local bgColor = levelColors[currentLevel]
        love.graphics.setBackgroundColor(bgColor[1], bgColor[2], bgColor[3])
        
        generateNewWorld()
        player.health = player.maxHealth
        player.energy = 0
        activePowerup = nil
        powerupTimer = 0
        player.speed = 180
    end
end

function love.load()
    player = Player:new()
    patrol = Patrol:new()
    hunter = Hunter:new(player)
    
    patrols = {}
    hunters = {}
    world = {}
    
    StateManager:setState(StateManager.states.MENU)
    
    currentLevel = 1
    maxLevel = 5
    targetEnergy = 150
    
    local bgColor = levelColors[currentLevel]
    love.graphics.setBackgroundColor(bgColor[1], bgColor[2], bgColor[3])
    
    main.sounds = {}
    main.sounds.hit = love.audio.newSource("assets/universfield-cinematic-impact-hit-352702.mp3", "static")
    main.sounds.hit:setVolume(1)
    main.sounds.hit:setLooping(false)

    local collectFile = love.filesystem.getInfo("assets/coin.wav")
    if collectFile then
        main.sounds.collect = love.audio.newSource("assets/coin.wav", "static")
        main.sounds.collect:setVolume(1)
    end
    
    local dashFile = love.filesystem.getInfo("assets/dragon-studio-whoosh-effect-382717.mp3")
    if dashFile then
        main.sounds.dash = love.audio.newSource("assets/dragon-studio-whoosh-effect-382717.mp3", "static")
        main.sounds.dash:setVolume(0.3)
    end
    
    local gameoverFile = love.filesystem.getInfo("assets/freesound_community-wrong-buzzer-6268 (1).mp3")
    if gameoverFile then
        main.sounds.gameover = love.audio.newSource("assets/freesound_community-wrong-buzzer-6268 (1).mp3", "static")
        main.sounds.gameover:setVolume(0.6)
    end
    
    local victoryFile = love.filesystem.getInfo("assets/freesound_community-8-bit-victory-sound-101319.mp3")
    if victoryFile then
        main.sounds.victory = love.audio.newSource("assets/freesound_community-8-bit-victory-sound-101319.mp3", "static")
        main.sounds.victory:setVolume(0.6)
    end
    
    local bgFile = love.filesystem.getInfo("assets/white_records-little-charlie-synthwave-version-background-music-for-video-vlog-204016.mp3")
    if bgFile then
        main.sounds.background = love.audio.newSource("assets/white_records-little-charlie-synthwave-version-background-music-for-video-vlog-204016.mp3", "stream")
        main.sounds.background:setLooping(true)
        main.sounds.background:setVolume(0.1)
    end
    
    local powerupFile = love.filesystem.getInfo("assets/powerup.wav")
    if powerupFile then
        main.sounds.powerup = love.audio.newSource("assets/powerup.wav", "static")
        main.sounds.powerup:setVolume(0.5)
    end
    
    local levelupFile = love.filesystem.getInfo("assets/levelup.wav")
    if levelupFile then
        main.sounds.levelup = love.audio.newSource("assets/levelup.wav", "static")
        main.sounds.levelup:setVolume(0.6)
    end

    energyImage = love.graphics.newImage("assets/download (9).png")
    backgroundImage = love.graphics.newImage("assets/Minecraft Sculk Block Texture Pixel Art.jpeg")
    doorImage = love.graphics.newImage("assets/The Awakening Swirl.jpeg")
    powerupSpeedImage = love.graphics.newImage("assets/electric_11732948.png")
    powerupShieldImage = love.graphics.newImage("assets/freepik_assistant_1774579605481.png")

    generateNewWorld()
    resetLevel()
end

function love.update(dt)
    local currentState = StateManager:getState()
    
    if currentState == StateManager.states.MENU or 
       currentState == StateManager.states.PAUSED or
       currentState == StateManager.states.GAMEOVER or
       currentState == StateManager.states.VICTORY or
       currentState == StateManager.states.INSTRUCTIONS then
        return
    end
    
    if firstPlay and not firstPlayMessage then
        firstPlayMessage = true
        return
    end
    
    gameTime = gameTime + dt
    levelTimer = levelTimer + dt
    
    if levelTimer >= levelTimeLimit then
        StateManager:setState(StateManager.states.GAMEOVER)
    end
    
    if powerupTimer > 0 then
        powerupTimer = powerupTimer - dt
        if powerupTimer <= 0 then
            if activePowerup == "speed" then
                player.speed = 180
            end
            activePowerup = nil
        end
    end
    
    if shakeDuration > 0 then
        shakeDuration = shakeDuration - dt
    else
        shakeIntensity = 0
    end
    
    local difficulty = 1 + gameTime * 0.02
    
    for _, p in ipairs(patrols) do
        p.speed = 70 * difficulty
        p:update(dt)
    end
    
    for _, h in ipairs(hunters) do
        h.speed = 50 * difficulty
        h.chaseSpeed = 70 * difficulty
        h.detectionRange = 250 + gameTime * 3
        h:update(dt)
    end

    player:update(dt)

    for _, p in ipairs(patrols) do
        if collision.check(player, p) then
            if activePowerup ~= "shield" then
                player:takeDamage(3)
                createDamageNumber(player.x, player.y, 3)
                shakeIntensity = 10
                shakeDuration = 0.2
                if main.sounds and main.sounds.hit then
                    main.sounds.hit:stop()
                    main.sounds.hit:play()
                end
            end
        end
    end
    
    for _, h in ipairs(hunters) do
        if collision.check(player, h) then
            if activePowerup ~= "shield" then
                player:takeDamage(4)
                createDamageNumber(player.x, player.y, 4)
                shakeIntensity = 10
                shakeDuration = 0.2
                if main.sounds and main.sounds.hit then
                    main.sounds.hit:stop()
                    main.sounds.hit:play()
                end
            end
        end
    end

    if player.health <= 0 then
        StateManager:setState(StateManager.states.GAMEOVER)
    end

    player.score = player.score + dt

    for i = #particles, 1, -1 do
        local p = particles[i]
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        p.vy = p.vy + 200 * dt
        p.life = p.life - dt * 2
        if p.life <= 0 then table.remove(particles, i) end
    end

    for i = #damageNumbers, 1, -1 do
        local d = damageNumbers[i]
        d.y = d.y + d.vy * dt
        d.life = d.life - dt * 1.5
        if d.life <= 0 then table.remove(damageNumbers, i) end
    end

    for i = #enemyDeaths, 1, -1 do
        local e = enemyDeaths[i]
        e.x = e.x + e.vx * dt
        e.y = e.y + e.vy * dt
        e.vy = e.vy + 300 * dt
        e.life = e.life - dt * 2
        if e.life <= 0 then table.remove(enemyDeaths, i) end
    end

    for i = #powerups, 1, -1 do
        local pu = powerups[i]
        if collision.check(player, pu) then
            applyPowerup(pu.type)
            table.remove(powerups, i)
        end
    end

    for i = #energyCells, 1, -1 do
        local cell = energyCells[i]
        if collision.check(player, cell) then
            local energyGain = 20
            if currentLevel == 1 then
                energyGain = 25
            end
            player.energy = math.min(player.energy + energyGain, player.maxEnergy)
            player.score = player.score + 10
            createCollectParticles(cell.x, cell.y)
            if main.sounds and main.sounds.collect then
                main.sounds.collect:stop()
                main.sounds.collect:play()
            end
            table.remove(energyCells, i)
            
            if not door and not doorCreated and player.energy >= targetEnergy * 0.5 then
                createDoor()
            end
        end
    end
    
    if door and not doorTransition then
        if player.x < door.x + door.width and
           player.x + player.width > door.x and
           player.y < door.y + door.height and
           player.y + player.height > door.y then
           
            if player.energy >= targetEnergy then
                if currentLevel < maxLevel then
                    doorTransition = true
                    transitionTimer = transitionDuration
                    if main.sounds and main.sounds.levelup then
                        main.sounds.levelup:play()
                    end
                    if main.sounds and main.sounds.background then
                        main.sounds.background:stop()
                    end
                else
                    StateManager:setState(StateManager.states.VICTORY)
                end
            end
        end
    end
    
    if doorTransition then
        transitionTimer = transitionTimer - dt
        if transitionTimer <= 0 then
            doorTransition = false
            if currentLevel < maxLevel then
                nextLevel()
            end
            if main.sounds and main.sounds.background then
                main.sounds.background:play()
            end
        end
    end
end

function love.draw()
    if StateManager:getState() ~= StateManager.states.MENU and 
       StateManager:getState() ~= StateManager.states.INSTRUCTIONS then
        love.graphics.push()
        
        local shakeX, shakeY = 0, 0
        if shakeDuration > 0 then
            shakeX = math.random(-shakeIntensity, shakeIntensity)
            shakeY = math.random(-shakeIntensity, shakeIntensity)
        end
        
        love.graphics.translate(-player.x + love.graphics.getWidth()/2 + shakeX, -player.y + love.graphics.getHeight()/2 + shakeY)

        if backgroundImage then
            love.graphics.setColor(1, 1, 1)
            for x = 0, world.width, backgroundImage:getWidth() do
                for y = 0, world.height, backgroundImage:getHeight() do
                    love.graphics.draw(backgroundImage, x, y)
                end
            end
        end

        if worldMap and worldMap.draw then
            worldMap:draw()
        end

        if door then
            if doorImage then
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(doorImage, door.x, door.y, 0, door.width/doorImage:getWidth(), door.height/doorImage:getHeight())
            else
                local glow = 0.5 + math.sin(love.timer.getTime() * 3) * 0.3
                love.graphics.setColor(0.6, 0.3, 0.9, glow)
                love.graphics.rectangle("fill", door.x, door.y, door.width, door.height)
                love.graphics.setColor(0.8, 0.5, 1, 1)
                love.graphics.rectangle("line", door.x, door.y, door.width, door.height)
                love.graphics.setFont(love.graphics.newFont(12))
                love.graphics.setColor(1, 1, 1, 0.9)
                love.graphics.print("EXIT", door.x + 15, door.y + 20)
                love.graphics.setFont(love.graphics.newFont(16))
            end
        end

        for _, pu in ipairs(powerups) do
            if pu.type == "speed" then
                if powerupSpeedImage then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.draw(powerupSpeedImage, pu.x, pu.y, 0, pu.width/powerupSpeedImage:getWidth(), pu.height/powerupSpeedImage:getHeight())
                else
                    love.graphics.setColor(1, 1, 0, 0.9)
                    love.graphics.rectangle("fill", pu.x, pu.y, pu.width, pu.height)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print("⚡", pu.x + 8, pu.y + 5)
                end
            else
                if powerupShieldImage then
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.draw(powerupShieldImage, pu.x, pu.y, 0, pu.width/powerupShieldImage:getWidth(), pu.height/powerupShieldImage:getHeight())
                else
                    love.graphics.setColor(0.5, 0.5, 1, 0.9)
                    love.graphics.rectangle("fill", pu.x, pu.y, pu.width, pu.height)
                    love.graphics.setColor(1, 1, 1)
                    love.graphics.print("🛡", pu.x + 8, pu.y + 5)
                end
            end
        end

        for _, cell in ipairs(energyCells) do
            local dx, dy = player.x - cell.x, player.y - cell.y
            local distance = math.sqrt(dx*dx + dy*dy)
            if distance < 300 then
                local glow = 0.6 + math.sin(love.timer.getTime()*5) * 0.4
                love.graphics.setColor(0.6, glow, 1)
                love.graphics.draw(energyImage, cell.x, cell.y, 0, cell.width/energyImage:getWidth(), cell.height/energyImage:getHeight())
            else
                love.graphics.setColor(0.5, 0.3, 0.8, 0.5)
                love.graphics.circle("fill", cell.x + 10, cell.y + 10, 6)
            end
        end

        love.graphics.setColor(1,1,1)
        player:draw()
        
        for _, p in ipairs(patrols) do p:draw() end
        for _, h in ipairs(hunters) do h:draw() end

        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.ellipse("fill", player.x + player.width/2, player.y + player.height - 10, 30, 15)

        for _, p in ipairs(particles) do
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.life / p.maxLife)
            love.graphics.circle("fill", p.x, p.y, p.size * (p.life / p.maxLife))
        end

        for _, d in ipairs(damageNumbers) do
            love.graphics.setColor(1, 0.3, 0.6, d.life / d.maxLife)
            love.graphics.print("-" .. d.amount, d.x, d.y - 20)
        end

        for _, e in ipairs(enemyDeaths) do
            love.graphics.setColor(e.color[1], e.color[2], e.color[3], e.life / e.maxLife)
            love.graphics.circle("fill", e.x, e.y, e.size * (e.life / e.maxLife))
        end
        
        if door and not doorTransition then
            local angle = math.atan2(door.y + door.height/2 - (player.y + player.height/2), 
                                     door.x + door.width/2 - (player.x + player.width/2))
            local arrowX = player.x + player.width/2 + math.cos(angle) * 80
            local arrowY = player.y + player.height/2 + math.sin(angle) * 80
            love.graphics.setColor(1, 1, 0, 0.8)
            love.graphics.polygon("fill", 
                arrowX, arrowY - 10,
                arrowX + 15, arrowY,
                arrowX, arrowY + 10)
        end
        
        love.graphics.pop()
    end

    if doorTransition then
        local alpha = transitionTimer / transitionDuration
        love.graphics.setColor(0.5, 0.3, 0.8, 1 - alpha)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
    end

    if firstPlay and not firstPlayMessage and StateManager:getState() == StateManager.states.PLAYING then
        love.graphics.setColor(0, 0, 0, 0.85)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(20))
        love.graphics.printf("Collect blue orbs to charge energy!", 0, 180, love.graphics.getWidth(), "center")
        love.graphics.printf("Find the EXIT door when energy is full!", 0, 230, love.graphics.getWidth(), "center")
        love.graphics.printf("Yellow ⚡ = Speed Boost | Blue 🛡 = Shield", 0, 280, love.graphics.getWidth(), "center")
        love.graphics.printf("Press SPACE to continue", 0, 350, love.graphics.getWidth(), "center")
        
        if love.keyboard.isDown("space") then
            firstPlay = false
        end
    end

    local currentState = StateManager:getState()
    
    if currentState == StateManager.states.PLAYING or currentState == StateManager.states.PAUSED then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(love.graphics.newFont(16))
        UI:drawHealthBar(player)
        UI:drawEnergyBar(player)
        love.graphics.print("Level: " .. currentLevel, love.graphics.getWidth() - 100, 10)
        love.graphics.print("Goal: " .. math.floor(player.energy) .. "/" .. targetEnergy, love.graphics.getWidth() - 100, 35)
        love.graphics.print("Score: " .. math.floor(player.score or 0), 10, 60)
        love.graphics.print("Time: " .. math.floor(levelTimer) .. "s", 10, 85)
        
        if activePowerup then
            love.graphics.print(activePowerup == "speed" and "⚡ SPEED BOOST" or "🛡 SHIELD ACTIVE", 
                               love.graphics.getWidth()/2 - 70, 100)
        end
        
        if door and not doorTransition then
            love.graphics.setColor(0.7, 0.4, 1, 0.9)
            love.graphics.print("FIND THE EXIT!", love.graphics.getWidth()/2 - 70, 120)
        end
    end

    if currentState == StateManager.states.MENU then require("menu"):draw()
    elseif currentState == StateManager.states.INSTRUCTIONS then require("instructions"):draw()
    elseif currentState == StateManager.states.PAUSED then require("pause"):draw()
    elseif currentState == StateManager.states.GAMEOVER then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(0.6, 0.3, 0.9)
        love.graphics.setFont(love.graphics.newFont(48))
        love.graphics.printf("GAME OVER", 0, 200, love.graphics.getWidth(), "center")
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.printf("Press R to Restart", 0, 300, love.graphics.getWidth(), "center")
        love.graphics.printf("Press M for Menu", 0, 350, love.graphics.getWidth(), "center")
    elseif currentState == StateManager.states.VICTORY then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
        love.graphics.setColor(0.5, 0.3, 1)
        love.graphics.setFont(love.graphics.newFont(48))
        love.graphics.printf("VICTORY!", 0, 150, love.graphics.getWidth(), "center")
        love.graphics.setFont(love.graphics.newFont(24))
        love.graphics.printf("Final Score: " .. math.floor(player.score), 0, 250, love.graphics.getWidth(), "center")
        love.graphics.printf("Time: " .. math.floor(levelTimer) .. " seconds", 0, 300, love.graphics.getWidth(), "center")
        love.graphics.printf("Energy Collected: " .. math.floor(player.energy), 0, 350, love.graphics.getWidth(), "center")
        if currentLevel < maxLevel then
            love.graphics.printf("Press N for Next Level", 0, 450, love.graphics.getWidth(), "center")
        else
            love.graphics.printf("YOU WIN! Final Level", 0, 450, love.graphics.getWidth(), "center")
        end
        love.graphics.printf("Press M for Menu", 0, 500, love.graphics.getWidth(), "center")
    end
end

function love.keypressed(key)
    if key == "m" and StateManager:getState() ~= StateManager.states.MENU then
        StateManager:setState(StateManager.states.MENU)
        return
    end
    
    local currentState = StateManager:getState()
    
    if currentState == StateManager.states.MENU then require("menu"):keypressed(key); return end
    if currentState == StateManager.states.INSTRUCTIONS then require("instructions"):keypressed(key); return end
    if currentState == StateManager.states.PAUSED then require("pause"):keypressed(key); return end
    
    if currentState == StateManager.states.PLAYING and key == "escape" then
        StateManager:setState(StateManager.states.PAUSED)
    end
    
    if currentState == StateManager.states.GAMEOVER then
        if key == "r" then
            currentLevel = 1
            targetEnergy = 150
            player.score = 0
            local bgColor = levelColors[1]
            love.graphics.setBackgroundColor(bgColor[1], bgColor[2], bgColor[3])
            generateNewWorld()
            resetLevel()
            StateManager:setState(StateManager.states.PLAYING)
            if main.sounds and main.sounds.background then main.sounds.background:play() end
        elseif key == "m" then
            currentLevel = 1
            targetEnergy = 150
            player.score = 0
            local bgColor = levelColors[1]
            love.graphics.setBackgroundColor(bgColor[1], bgColor[2], bgColor[3])
            love.load()
        end
    end
    
    if currentState == StateManager.states.VICTORY then
        if key == "n" and currentLevel < maxLevel then
            nextLevel()
            StateManager:setState(StateManager.states.PLAYING)
        elseif key == "m" then
            currentLevel = 1
            targetEnergy = 150
            player.score = 0
            local bgColor = levelColors[1]
            love.graphics.setBackgroundColor(bgColor[1], bgColor[2], bgColor[3])
            love.load()
        end
    end
end