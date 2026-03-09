local collision = require("collision")
local anim8 = require("libb.anim8")

local Player = {}

function Player:new()
    local p = {}
    p.x = 100
    p.y = 100
    p.width = 150
    p.height = 150
    p.speed = 200

    p.health = 100
    p.maxHealth = 100
    p.energy = 0
    p.maxEnergy = 5000
    p.score = 0

    p.invulnerable = false
    p.invulnerableTimer = 0

    p.dashSpeed = 400
    p.dashDuration = 0.2
    p.dashCooldown = 1.0
    p.dashTimer = 0
    p.dashCooldownTimer = 0
    p.isDashing = false

    p.isMoving = false
    p.lastDirection = "down"

    p.spriteSheet = love.graphics.newImage("assets/doreen-shi-player-running-sprite-sheet.png")
    
    local frameW = 150
    local frameH = 150
    
    p.grid = anim8.newGrid(frameW, frameH, 
                           p.spriteSheet:getWidth(), 
                           p.spriteSheet:getHeight())
    
    p.animations = {
        down  = anim8.newAnimation(p.grid('1-8', 1), 0.08),
        right = anim8.newAnimation(p.grid('1-8', 2), 0.08),
        up    = anim8.newAnimation(p.grid('1-8', 3), 0.08),
        left  = anim8.newAnimation(p.grid('1-8', 4), 0.08),
    }
    
    p.currentAnim = p.animations.down

    setmetatable(p, self)
    self.__index = self
    return p
end

function Player:update(dt)
    local walls = _G.walls or {}

    local directionX = 0
    local directionY = 0

    if love.keyboard.isDown("left") then
        directionX = directionX - 1
    end
    if love.keyboard.isDown("right") then
        directionX = directionX + 1
    end
    if love.keyboard.isDown("up") then
        directionY = directionY - 1
    end
    if love.keyboard.isDown("down") then
        directionY = directionY + 1
    end

    if directionY > 0 then
        self.currentAnim = self.animations.down
        self.lastDirection = "down"
        self.isMoving = true
    elseif directionY < 0 then
        self.currentAnim = self.animations.up
        self.lastDirection = "up"
        self.isMoving = true
    elseif directionX > 0 then
        self.currentAnim = self.animations.right
        self.lastDirection = "right"
        self.isMoving = true
    elseif directionX < 0 then
        self.currentAnim = self.animations.left
        self.lastDirection = "left"
        self.isMoving = true
    else
        self.currentAnim = self.animations[self.lastDirection]
        self.isMoving = false
    end

    if self.isMoving then
        self.currentAnim:update(dt)
    end

    if self.dashCooldownTimer > 0 then
        self.dashCooldownTimer = self.dashCooldownTimer - dt
    end

    if self.isDashing then
        self.dashTimer = self.dashTimer - dt
        if self.dashTimer <= 0 then
            self.isDashing = false
        end
    end

    if not self.isDashing and self.dashCooldownTimer <= 0 then
        if love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift") then
            self.isDashing = true
            self.dashTimer = self.dashDuration
            self.dashCooldownTimer = self.dashCooldown
        end
    end

    local length = math.sqrt(directionX * directionX + directionY * directionY)
    if length > 0 then
        directionX = directionX / length
        directionY = directionY / length
    end


    self.energy = math.max(self.energy - dt * 5, 0)

    local energyBonus = 1 + (self.energy / self.maxEnergy) * 0.5

    local currentSpeed = self.speed * energyBonus
    if self.isDashing then
        currentSpeed = self.dashSpeed * energyBonus
    end


    local oldX = self.x
    self.x = self.x + directionX * currentSpeed * dt
    for _, wall in ipairs(walls) do
        if collision.check(self, wall) then
            self.x = oldX
            break
        end
    end


    local oldY = self.y
    self.y = self.y + directionY * currentSpeed * dt
    for _, wall in ipairs(walls) do
        if collision.check(self, wall) then
            self.y = oldY
            break
        end
    end

    self.x = math.max(0, math.min(world.width - self.width, self.x))
    self.y = math.max(0, math.min(world.height - self.height, self.y))

    if self.invulnerable then
        self.invulnerableTimer = self.invulnerableTimer - dt
        if self.invulnerableTimer <= 0 then
            self.invulnerable = false
        end
    end
end

function Player:takeDamage(amount)
    if not self.invulnerable then
        self.health = self.health - amount
        self.invulnerable = true
        self.invulnerableTimer = 1
    end
end

function Player:draw()
    if self.isDashing then
        love.graphics.setColor(1, 1, 0) 
    elseif self.invulnerable then
        if math.floor(love.timer.getTime() * 10) % 2 == 0 then
            love.graphics.setColor(1, 0.5, 0.5) 
        else
            love.graphics.setColor(1, 1, 1)      
        end
    else
        love.graphics.setColor(1, 1, 1) 
    end

    self.currentAnim:draw(self.spriteSheet, self.x, self.y)
end

return Player