-- Modules

local Anim8 = require('lib/vendor/anim8/anim8')
local Gamestate = require 'lib/vendor/hump/gamestate'


-- Global variables

local Title = {}
local Game = {}
local Player = {
    x = 0,
    y = 0,
    width = 64,
    height = 64,
    speed = 128,
    durations = 0.5  -- or this can be {0.5, 0.1, ...} based on each frame
}

local Image


-- Love section

function love.load()
    Gamestate.registerEvents()
    Gamestate.switch(Title)

    Image = love.graphics.newImage('assets/sokoban_tilesheet.png')
    local grid = Anim8.newGrid(64, 64, Image:getWidth(), Image:getHeight())

    Player.animations = {
        down = Anim8.newAnimation(
            grid('1-3', 6),
            Player.durations
        ),
        up = Anim8.newAnimation(
            grid('4-6', 6),
            Player.durations
        ),
        right = Anim8.newAnimation(
            grid('1-3', 8),
            Player.durations
        ),
        left = Anim8.newAnimation(
            grid('4-6', 8),
            Player.durations
        ),
    }

    -- Default player to facing us
    Player.animation = Player.animations.down
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
    -- Draw hud
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

    -- Draw our player
    Player.animation:draw(Image, Player.x, Player.y)
end


function Game:update(deltatime)
    if love.keyboard.isDown('up') or love.keyboard.isDown('w') then
        Player.y = Player.y - Player.speed * deltatime
        Player.animation = Player.animations.up
    end

    if love.keyboard.isDown('down') or love.keyboard.isDown('s') then
        Player.y = Player.y + Player.speed * deltatime
        Player.animation = Player.animations.down
    end

    if love.keyboard.isDown('left') or love.keyboard.isDown('a') then
        Player.x = Player.x - Player.speed * deltatime
        Player.animation = Player.animations.left
    end

    if love.keyboard.isDown('right') or love.keyboard.isDown('d') then
        Player.x = Player.x + Player.speed * deltatime
        Player.animation = Player.animations.right
    end

    Player.animation:update(deltatime)
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
