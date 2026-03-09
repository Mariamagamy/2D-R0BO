local UI = {}

function UI:drawHealthBar(player)
    local barWidth = 200
    local barHeight = 20
    local x = 10
    local y = 10

    local healthRatio = player.health / player.maxHealth

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, barWidth, barHeight)

    love.graphics.setColor(0, 1, 0)
    love.graphics.rectangle("fill", x, y, barWidth * healthRatio, barHeight)

    love.graphics.setColor(1, 0.03, 1)
    love.graphics.rectangle("line", x, y, barWidth, barHeight)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Health: " .. math.floor(player.health), x + 5, y + 2)
end

function UI:drawEnergyBar(player)
    local barWidth = 200
    local barHeight = 20
    local x = 10
    local y = 35

    local energyRatio = player.energy / player.maxEnergy

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, barWidth, barHeight)

    love.graphics.setColor(0, 0.8, 1)
    love.graphics.rectangle("fill", x, y, barWidth * energyRatio, barHeight)

    love.graphics.setColor(1, 0.5, 0)
    love.graphics.rectangle("line", x, y, barWidth, barHeight)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Energy: " .. math.floor(player.energy), x + 5, y + 2)
end

return UI