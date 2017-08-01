
-- TitleScreen handles our main title screen

local Gamestate = require('lib.vendor.hump.gamestate')

local Font = nil
local TitleFont = nil
local SubTitleFont = nil

local TitleScreen = Gamestate.new()


function TitleScreen:draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    love.graphics.setFont(TitleFont)

    love.graphics.printf('LD39: Sokoban', 0, height / 5, width, 'center')

    love.graphics.setFont(SubTitleFont)

    love.graphics.printf('', 0, height / 4 + 64, width, 'center')

    love.graphics.printf(
        'By Jeff Triplett\n' ..
        'Graphics by Kenney Vleugels (Kenney.nl)\n\n' ..
        'Arrow keys or WASD to move\n' ..
        '"R" to restart the level\n' ..
        '"1" - "0" to warp to another level\n' ..
        '"P" to pause\n' ..
        '"Q" to quit\n\n' ..
        'Press Return or Enter to continue',
        0, (height / 3), width, 'center')
end


function TitleScreen:enter()
    TitleFont = love.graphics.newFont('assets/fonts/Kenney Pixel.ttf', 64)
    SubTitleFont = love.graphics.newFont('assets/fonts/Kenney Pixel.ttf', 32)
end


function TitleScreen:keyreleased(key, code)
    if key == 'return' then
        Gamestate.switch(gamestates.game)
    end
end


return TitleScreen
