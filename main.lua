-- Modules

local Anim8 = require('lib/vendor/anim8/anim8')
local Gamestate = require 'lib/vendor/hump/gamestate'


-- Global variables

local Title = {}
local Game = {}
local Player = {
    x = 0,
    y = 0,
    width = 16,
    height = 16,
    speed = 64,
}


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
    love.graphics.setColor(128, 255, 128)
    love.graphics.rectangle(
        'fill',
        Player.x,
        Player.y,
        Player.width,
        Player.height
    )

    love.graphics.setColor(255, 255, 255)
    love.graphics.print('Game:draw()', 16, 16)

    fps = love.timer.getFPS()
    love.graphics.print(
        'fps: '..('%3d'):format(fps),
        love.graphics.getWidth() - 64,
        16
    )

    love.graphics.print(
        'Player: (' .. ('%d'):format(Player.x) .. ', ' .. ('%d'):format(Player.y) .. ')',
        16,
        32
    )
end


function Game:update(deltatime)
    if love.keyboard.isDown('up') or love.keyboard.isDown('w') then
        Player.y = Player.y - Player.speed * deltatime
    elseif love.keyboard.isDown('down') or love.keyboard.isDown('s') then
        Player.y = Player.y + Player.speed * deltatime
    elseif love.keyboard.isDown('left') or love.keyboard.isDown('a') then
        Player.x = Player.x - Player.speed * deltatime
    elseif love.keyboard.isDown('right') or love.keyboard.isDown('d') then
        Player.x = Player.x + Player.speed * deltatime
    end
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
