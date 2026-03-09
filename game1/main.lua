local gameover = false
local gameTime = 0

local Player = require("player")
local Patrol = require("patrol")
local Hunter = require("hunter")
local collision = require("collision")
local UI = require("ui")

function spawnEnergyCell()
    local newCell = {
        x = player.x + math.random(-600, 600),
        y = player.y + math.random(-600, 600),
        width = 30,
        height = 30
    }

    newCell.x = math.max(50, math.min(world.width - 50, newCell.x))
    newCell.y = math.max(50, math.min(world.height - 50, newCell.y))

    table.insert(energyCells, newCell)
end

function love.load()
    world = {}
    world.width = 2000
    world.height = 2000

    walls = {
        {x=0, y=0, width=world.width, height=40},
        {x=0, y=world.height-40, width=world.width, height=40},
        {x=0, y=0, width=40, height=world.height},
        {x=world.width-40, y=0, width=40, height=world.height},
    }

    _G.walls = walls

    player = Player:new()
    patrol = Patrol:new()
    hunter = Hunter:new(player)

    gameover = false
    gameTime = 0

    hitsound = love.audio.newSource(
        "assets/zapsplat_warfare_gun_gel_blaster_scar_2_auto_rifle_magazine_release_unload_003_95549.mp3",
        "stream"
    )
    hitsound:setVolume(0.5)

    love.graphics.setBackgroundColor(0.04, 0.04, 0.08)
    energyImage = love.graphics.newImage("assets/download (9).png")

    energyCells = {}
    for i = 1, 10 do
        spawnEnergyCell()
    end
end

function love.update(dt)
    if not gameover then
        gameTime = gameTime + dt
        
        local difficulty = 1 + gameTime * 0.05
        patrol.speed = 100 * difficulty
        hunter.speed = 80 * difficulty
        hunter.detectionRange = 300 + gameTime * 10

        player:update(dt)
        patrol:update(dt)
        hunter:update(dt)

        if collision.check(player, patrol) or collision.check(player, hunter) then
            player:takeDamage(10)
            hitsound:stop()
            hitsound:play()
        end

        if player.health <= 0 then
            gameover = true
        end
    end

    player.score = player.score + dt


    for i = #energyCells, 1, -1 do
        local cell = energyCells[i]

        if collision.check(player, cell) then
            player.energy = math.min(player.energy + 30, player.maxEnergy)
            table.remove(energyCells, i)
            spawnEnergyCell()
        end
    end
end

function love.draw()
    love.graphics.push()
    love.graphics.translate(
        -player.x + love.graphics.getWidth()/2,
        -player.y + love.graphics.getHeight()/2
    )


    for x = 0, world.width, 64 do
        for y = 0, world.height, 64 do
            love.graphics.setColor(0.1, 0.1, 0.15)
            love.graphics.rectangle("fill", x, y, 64, 64)
            love.graphics.setColor(0.15, 0.15, 0.2)
            love.graphics.rectangle("line", x, y, 64, 64)
        end
    end


    for _, wall in ipairs(walls) do
        love.graphics.setColor(0.15, 0.15, 0.2)
        love.graphics.rectangle("fill", wall.x, wall.y, wall.width, wall.height)
    end


    for _, cell in ipairs(energyCells) do
        local dx = player.x - cell.x
        local dy = player.y - cell.y
        local distance = math.sqrt(dx*dx + dy*dy)
        
        if distance < 300 then
            local glow = 0.6 + math.sin(love.timer.getTime()*5) * 0.4
            love.graphics.setColor(glow, glow, glow)
            love.graphics.draw(energyImage, cell.x, cell.y, 0,
                              cell.width/energyImage:getWidth(),
                              cell.height/energyImage:getHeight())
        else
            love.graphics.setColor(0, 0.8, 0.8, 0.5)
            love.graphics.circle("fill", cell.x + 10, cell.y + 10, 6)
        end
    end

    love.graphics.setColor(1,1,1)
    player:draw()
    patrol:draw()
    hunter:draw()
    
    love.graphics.pop()

  
    love.graphics.setColor(1, 1, 1)
    UI:drawHealthBar(player)
    UI:drawEnergyBar(player)
    love.graphics.print("Score: " .. math.floor(player.score), 10, 60)

    if gameover then
        love.graphics.setColor(1, 1, 1)
        love.graphics.print("GAME OVER Press R to Restart", 200, 200)
    end
end

function love.keypressed(key)
    if key == "r" and gameover then
        love.load()
    end
end