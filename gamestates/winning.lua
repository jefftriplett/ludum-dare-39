
-- WinningScreen handles our main title screen

local Gamestate = require('lib.vendor.hump.gamestate')

local Font = nil
local TitleFont = nil
local SubTitleFont = nil

local WinningScreen = Gamestate.new()


function WinningScreen:draw()
    local width = love.graphics.getWidth()
    local height = love.graphics.getHeight()

    love.graphics.setFont(TitleFont)
    love.graphics.printf('LD39: Sokoban', 0, height / 3, width, 'center')

    love.graphics.setFont(TitleFont)
    love.graphics.printf('Congratulations! You won!', 0, (height / 2), width, 'center')

    love.graphics.setFont(SubTitleFont)
    love.graphics.printf('Press Enter to play again', 0, (height / 3) * 2, width, 'center')
end


function WinningScreen:enter()
    TitleFont = love.graphics.newFont('assets/fonts/Kenney Pixel.ttf', 64)
    SubTitleFont = love.graphics.newFont('assets/fonts/Kenney Pixel.ttf', 32)
end


function WinningScreen:keyreleased(key, code)
    if key == 'return' then
        Gamestate.switch(gamestates.title)
    end
end


return WinningScreen
