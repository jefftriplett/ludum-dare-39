
-- PauseScreen handles our pause screen

local Gamestate = require('lib.vendor.hump.gamestate')

local Font = nil

local PauseScreen = Gamestate.new()


function PauseScreen:enter(from)
    self.from = from
    Font = love.graphics.newFont('assets/fonts/Kenney Pixel.ttf', 32)
    love.graphics.setFont(Font)
end


function PauseScreen:draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    self.from:draw()

    love.graphics.setColor(0, 0, 0, 100)
    love.graphics.rectangle('fill', 0, 0, width, height)

    love.graphics.setColor(255, 255, 255)
    love.graphics.printf('Pause', 0, height / 2, width, 'center')
    -- love.graphics.printf('Press Enter to continue', 16, 32)
end


function PauseScreen:keypressed(key, code)
    if key == 'return' or key == 'p' then
        return Gamestate.pop()
    end
end


return PauseScreen
