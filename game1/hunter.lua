local Hunter = {}
local anim8 = require("libb.anim8")

function Hunter:new(player)
    local e = {}
    e.x = 500
    e.y = 500
    e.width = 150
    e.height = 150
    e.speed = 50
    e.chaseSpeed = 70
    
    e.startX = e.x
    e.startY = e.y
    e.patrolRange = 200
    e.detectionRange = 250
    e.chaseRange = 300
    e.returnRange = 350
    
    e.player = player
    e.state = "patrol"
    
    e.idleTimer = 0
    e.idleDuration = 1.0
    
    e.spriteSheet = love.graphics.newImage("assets/Attack_1.png")
    e.frameW = 128
    e.frameH = 128
    e.grid = anim8.newGrid(e.frameW, e.frameH,
                           e.spriteSheet:getWidth(),
                           e.spriteSheet:getHeight())
    e.animation = anim8.newAnimation(e.grid('1-4', 1), 0.1)
    
    setmetatable(e, self)
    self.__index = self
    return e
end

function Hunter:update(dt)
    self.animation:update(dt)
    
    if self.idleTimer > 0 then
        self.idleTimer = self.idleTimer - dt
    end
    
    local dx = self.player.x - self.x
    local dy = self.player.y - self.y
    local distToPlayer = math.sqrt(dx*dx + dy*dy)
    
    local dxStart = self.startX - self.x
    local dyStart = self.startY - self.y
    local distFromStart = math.sqrt(dxStart*dxStart + dyStart*dyStart)
    
    if self.state == "idle" then
        if self.idleTimer <= 0 then
            self.state = "patrol"
        end
        return
    end
    
    if self.state == "patrol" then
        self.x = self.x + math.sin(love.timer.getTime()) * 40 * dt
        self.y = self.y + math.cos(love.timer.getTime()) * 40 * dt
        
        if math.abs(self.x - self.startX) > self.patrolRange then
            self.x = self.startX + (self.patrolRange * (self.x > self.startX and 1 or -1))
        end
        if math.abs(self.y - self.startY) > self.patrolRange then
            self.y = self.startY + (self.patrolRange * (self.y > self.startY and 1 or -1))
        end
        
        if distToPlayer < self.detectionRange then
            self.state = "chase"
            self.idleTimer = 0.2
        end
    end
    
    if self.state == "chase" then
        if self.idleTimer > 0 then
            return
        end
        
        if distToPlayer > self.chaseRange then
            self.state = "return"
            self.idleTimer = 0.3
            return
        end
        
        if distToPlayer > 0 then
            dx = dx / distToPlayer
            dy = dy / distToPlayer
            self.x = self.x + dx * self.chaseSpeed * dt
            self.y = self.y + dy * self.chaseSpeed * dt
        end
    end
    
    if self.state == "return" then
        if self.idleTimer > 0 then
            return
        end
        
        if distFromStart < 50 then
            self.state = "idle"
            self.idleTimer = self.idleDuration
            return
        end
        
        if distFromStart > 0 then
            dxStart = dxStart / distFromStart
            dyStart = dyStart / distFromStart
            self.x = self.x + dxStart * self.speed * dt
            self.y = self.y + dyStart * self.speed * dt
        end
    end
end

function Hunter:draw()
    if self.state == "chase" then
        love.graphics.setColor(1, 0.2, 0.2, 1)
    elseif self.state == "return" then
        love.graphics.setColor(1, 0.6, 0.2, 0.9)
    elseif self.state == "idle" then
        love.graphics.setColor(0.5, 0.5, 1, 0.8)
    else
        love.graphics.setColor(0.8, 0.4, 0.8, 0.8)
    end
    
    self.animation:draw(self.spriteSheet, self.x, self.y, 0, 
                        self.width/self.frameW, self.height/self.frameH)
    love.graphics.setColor(1, 1, 1)
end

return Hunter