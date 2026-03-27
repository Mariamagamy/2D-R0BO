local Map = {}

Map.TILE_SIZE = 64
Map.COLS = 30
Map.ROWS = 22

Map.FLOOR = 0
Map.WALL = 1

Map.currentLevel = 1

function Map:new()
    local map = {}
    map.tiles = {}
    map.width = Map.COLS * Map.TILE_SIZE
    map.height = Map.ROWS * Map.TILE_SIZE
    
    for row = 1, Map.ROWS do
        map.tiles[row] = {}
        for col = 1, Map.COLS do
            local isEdge = (row == 1 or row == Map.ROWS or col == 1 or col == Map.COLS)
            if isEdge then
                map.tiles[row][col] = Map.WALL
            else
                if love.math.random() < 0.35 then
                    map.tiles[row][col] = Map.WALL
                else
                    map.tiles[row][col] = Map.FLOOR
                end
            end
        end
    end
    
    map = self:cleanMap(map)
    
    setmetatable(map, self)
    self.__index = self
    return map
end

function Map:setLevel(level)
    self.currentLevel = level
end

function Map:cleanMap(map)
    for row = 2, Map.ROWS - 1 do
        for col = 2, Map.COLS - 1 do
            if map.tiles[row][col] == Map.WALL then
                local wallCount = 0
                if map.tiles[row-1][col] == Map.WALL then wallCount = wallCount + 1 end
                if map.tiles[row+1][col] == Map.WALL then wallCount = wallCount + 1 end
                if map.tiles[row][col-1] == Map.WALL then wallCount = wallCount + 1 end
                if map.tiles[row][col+1] == Map.WALL then wallCount = wallCount + 1 end
                
                if wallCount <= 1 then
                    map.tiles[row][col] = Map.FLOOR
                end
            end
        end
    end
    return map
end

function Map:isWalkable(px, py, entityWidth, entityHeight)
    local col = math.floor((px) / Map.TILE_SIZE) + 1
    local row = math.floor((py) / Map.TILE_SIZE) + 1
    
    if row < 1 or row > Map.ROWS or col < 1 or col > Map.COLS then
        return false
    end
    
    return self.tiles[row][col] == Map.FLOOR
end

function Map:draw()
    local darkness = 1 - (self.currentLevel - 1) * 0.15
    
    for row = 1, Map.ROWS do
        for col = 1, Map.COLS do
            local x = (col - 1) * Map.TILE_SIZE
            local y = (row - 1) * Map.TILE_SIZE
            
            if self.tiles[row][col] == Map.WALL then
                love.graphics.setColor(0.1 * darkness, 0.08 * darkness, 0.2 * darkness, 1)
                love.graphics.rectangle("fill", x, y, Map.TILE_SIZE, Map.TILE_SIZE)
                love.graphics.setColor(0.3 * darkness, 0.15 * darkness, 0.4 * darkness, 0.8)
                love.graphics.rectangle("line", x, y, Map.TILE_SIZE, Map.TILE_SIZE)
                love.graphics.setColor(0.55 * darkness, 0.25 * darkness, 0.75 * darkness, 0.7)
                love.graphics.line(x + Map.TILE_SIZE/4, y + Map.TILE_SIZE/4, 
                                   x + Map.TILE_SIZE*3/4, y + Map.TILE_SIZE*3/4)
                love.graphics.line(x + Map.TILE_SIZE*3/4, y + Map.TILE_SIZE/4, 
                                   x + Map.TILE_SIZE/4, y + Map.TILE_SIZE*3/4)
            else
                local glow = 0.15 + math.sin(love.timer.getTime() * 2) * 0.08
                love.graphics.setColor((0.3 + glow) * darkness, (0.35 + glow) * darkness, (0.65 + glow) * darkness, 0.95)
                love.graphics.rectangle("fill", x, y, Map.TILE_SIZE, Map.TILE_SIZE)
                love.graphics.setColor(0.5 * darkness, 0.4 * darkness, 0.7 * darkness, 0.7)
                love.graphics.rectangle("line", x, y, Map.TILE_SIZE, Map.TILE_SIZE)
                love.graphics.setColor(0.75 * darkness, 0.45 * darkness, 0.95 * darkness, 0.7)
                love.graphics.circle("fill", x + Map.TILE_SIZE/2, y + Map.TILE_SIZE/2, 6)
            end
        end
    end
end

return Map