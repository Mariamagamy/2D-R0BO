local RoomGen = {}
local Map = require("map")

RoomGen.tileSize = Map.TILE_SIZE
RoomGen.mapWidth = Map.COLS
RoomGen.mapHeight = Map.ROWS

function RoomGen.generateMap(seed, level)
    if seed then
        math.randomseed(seed)
    else
        math.randomseed(os.time())
    end
    
    local map = Map:new()
    map:setLevel(level or 1)
    return map
end

function RoomGen.mapToWalls(map)
    local walls = {}
    for row = 1, Map.ROWS do
        for col = 1, Map.COLS do
            if map.tiles[row][col] == Map.WALL then
                table.insert(walls, {
                    x = (col - 1) * Map.TILE_SIZE,
                    y = (row - 1) * Map.TILE_SIZE,
                    width = Map.TILE_SIZE,
                    height = Map.TILE_SIZE
                })
            end
        end
    end
    return walls
end

function RoomGen.spawnEnergy(map, count)
    local energyCells = {}
    local placed = 0
    local attempts = 0
    
    local actualCount = count
    if _G.currentLevel == 1 then
        actualCount = count * 1.5
    end
    
    while placed < actualCount and attempts < 800 do
        local col = love.math.random(2, Map.COLS - 1)
        local row = love.math.random(2, Map.ROWS - 1)
        
        if map.tiles[row][col] == Map.FLOOR then
            local x = (col - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 15
            local y = (row - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 15
            
            local tooClose = false
            for _, cell in ipairs(energyCells) do
                local cellX = cell.x / Map.TILE_SIZE + 1
                local cellY = cell.y / Map.TILE_SIZE + 1
                if math.abs(cellX - col) < 2 and math.abs(cellY - row) < 2 then
                    tooClose = true
                    break
                end
            end
            
            if not tooClose then
                table.insert(energyCells, {x = x, y = y, width = 30, height = 30})
                placed = placed + 1
            end
        end
        attempts = attempts + 1
    end
    
    return energyCells
end

function RoomGen.findSpawnPoint(map)
    local attempts = 0
    
    while attempts < 200 do
        local col = love.math.random(4, Map.COLS - 3)
        local row = love.math.random(4, Map.ROWS - 3)
        
        if map.tiles[row][col] == Map.FLOOR then
            local safe = true
            for dy = -2, 2 do
                for dx = -2, 2 do
                    if map.tiles[row+dy][col+dx] == Map.WALL then
                        safe = false
                        break
                    end
                end
            end
            
            if safe then
                return {
                    x = (col - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 75,
                    y = (row - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 75,
                    gridX = col,
                    gridY = row
                }
            end
        end
        attempts = attempts + 1
    end
    
    local centerCol = math.floor(Map.COLS/2)
    local centerRow = math.floor(Map.ROWS/2)
    return {
        x = (centerCol - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 75,
        y = (centerRow - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 75,
        gridX = centerCol,
        gridY = centerRow
    }
end

function RoomGen.spawnEnemies(map, playerGridX, playerGridY, level)
    local patrols = {}
    local hunters = {}
    
    local numPatrols = 3 + math.floor(level * 1.5)
    local numHunters = 2 + math.floor(level)
    
    local attempts = 0
    local maxAttempts = 400
    
    while #patrols < numPatrols and attempts < maxAttempts do
        local col = love.math.random(2, Map.COLS - 1)
        local row = love.math.random(2, Map.ROWS - 1)
        
        if map.tiles[row][col] == Map.FLOOR then
            local distToPlayer = math.sqrt((col - playerGridX)^2 + (row - playerGridY)^2)
            
            if distToPlayer > 6 then
                local tooClose = false
                for _, p in ipairs(patrols) do
                    if math.abs(p.gridX - col) < 4 and math.abs(p.gridY - row) < 4 then
                        tooClose = true
                        break
                    end
                end
                
                if not tooClose then
                    table.insert(patrols, {
                        x = (col - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 40,
                        y = (row - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 40,
                        gridX = col,
                        gridY = row,
                        horizontal = love.math.random() > 0.5
                    })
                end
            end
        end
        attempts = attempts + 1
    end
    
    attempts = 0
    
    while #hunters < numHunters and attempts < maxAttempts do
        local col = love.math.random(2, Map.COLS - 1)
        local row = love.math.random(2, Map.ROWS - 1)
        
        if map.tiles[row][col] == Map.FLOOR then
            local distToPlayer = math.sqrt((col - playerGridX)^2 + (row - playerGridY)^2)
            
            if distToPlayer > 8 then
                local tooClose = false
                for _, h in ipairs(hunters) do
                    if math.abs(h.gridX - col) < 5 and math.abs(h.gridY - row) < 5 then
                        tooClose = true
                        break
                    end
                end
                
                if not tooClose then
                    table.insert(hunters, {
                        x = (col - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 75,
                        y = (row - 1) * Map.TILE_SIZE + Map.TILE_SIZE/2 - 75,
                        gridX = col,
                        gridY = row
                    })
                end
            end
        end
        attempts = attempts + 1
    end
    
    return patrols, hunters
end

return RoomGen