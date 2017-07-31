
-- TitleScreen handles our main title screen

local Gamestate = require('lib.vendor.hump.gamestate')

local Font = nil

local TitleScreen = Gamestate.new()


function TitleScreen:draw()
    love.graphics.print('TitleScreen:draw()', 16, 16)
    love.graphics.print('Press Enter to continue', 16, 32)
end


function TitleScreen:enter()
    Font = love.graphics.newFont('assets/fonts/Kenney Pixel.ttf', 32)
    love.graphics.setFont(Font)
end


function TitleScreen:keyreleased(key, code)
    if key == 'return' then
        Gamestate.switch(gamestates.game)
    end
end


return TitleScreen
