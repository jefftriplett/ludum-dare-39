-- Modules

local Gamestate = require 'lib/vendor/hump/gamestate'


-- Global variables

local Title = {}
local Game = {}


-- Love section

function love.load()
    Gamestate.registerEvents()
    Gamestate.switch(Title)
end


-- Title section

function Title:draw()
    love.graphics.print('Title:draw()', 16, 16)
    love.graphics.print('Press Enter to continue', 16, 32)
end


function Title:keyreleased(key, code)
    if key == 'return' then
        Gamestate.switch(Game)
    end
end


-- Main game section

function Game:draw()
    love.graphics.print('Game:draw()', 16, 16)
    fps = love.timer.getFPS()
    love.graphics.print(
        'fps: '..('%3d'):format(fps),
        love.graphics.getWidth() - 64,
        16
    )
end


function Game:keypressed(key, code)
    if love.keyboard.isDown('escape') or love.keyboard.isDown('q') then
        love.event.quit()
    end
end


function Game:quit()
    print('Thank you for playing!')
    return false
end
