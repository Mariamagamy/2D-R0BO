local Patrol = {}

function Patrol:new()
    local e = {}
    e.x = 300
    e.y = 300
    e.width = 80  
    e.height = 80
    e.speed = 80 
    e.startX = e.x
    e.endX = e.x + 300  
    e.direction = 1
    
 
    e.horizontal = math.random() > 0.5  
    
    e.image = love.graphics.newImage("assets/—Pngtree—hand drawn cartoon cute cute_5471741.png")
    
    e.color = {0.8, 0.4, 0.8}  
    
    setmetatable(e, self)
    self.__index = self
    return e
end

function Patrol:update(dt)
    if self.horizontal then
        self.x = self.x + self.direction * self.speed * dt
        
        if self.x > self.endX then 
            self.x = self.endX
            self.direction = -1
        end
        if self.x < self.startX then 
            self.x = self.startX
            self.direction = 1
        end
    else
        self.y = self.y + self.direction * self.speed * dt
        
        if self.y > self.endX then 
            self.y = self.endX
            self.direction = -1
        end
        if self.y < self.startX then 
            self.y = self.startX
            self.direction = 1
        end
    end
end

function Patrol:draw()
    love.graphics.setColor(self.color[1], self.color[2], self.color[3], 1)
    love.graphics.draw(self.image, self.x, self.y, 0, 
                       self.width/self.image:getWidth(), 
                       self.height/self.image:getHeight())
    love.graphics.setColor(1, 1, 1)
end

return Patrol