-- Modules

local Anim8 = require('lib/vendor/anim8/anim8')
local Gamestate = require('lib/vendor/hump/gamestate')
local Sti = require('lib/vendor/sti')


-- Global variables

local GameScreen = {}
local TitleScreen = {}

local Font = nil
local Map = nil
local World = nil

local Player = {
    x = nil,
    y = nil,
    offset_x = math.floor(64 / 2),
    offset_y = math.floor(64 / 1.35),
    rotation = 0,
    width = 64,
    height = 64,
    speed = 128,
    durations = 0.25,  -- or this can be {0.5, 0.1, ...} based on each frame
    animation = nil,  -- our index for holding which Quad we are displaying
    animations = nil,  -- our Quads
    spritesheet = nil,  -- our image spritesheet which holds all of our images
}


-- Love section

function love.load()
    Gamestate.registerEvents()
    Gamestate.switch(TitleScreen)

    Font = love.graphics.newFont('assets/fonts/Kenney Pixel.ttf', 32)
    love.graphics.setFont(Font)

    Player.spritesheet = love.graphics.newImage('assets/images/sokoban_tilesheet.png')
    local grid = Anim8.newGrid(64, 64, Player.spritesheet:getWidth(), Player.spritesheet:getHeight())

    Player.animations = {
        down = Anim8.newAnimation(
            grid(
                1, 6,
                2, 6,
                1, 6,
                3, 6
            ),
            Player.durations
        ),
        up = Anim8.newAnimation(
            grid(
                4, 6,
                5, 6,
                4, 6,
                6, 6
            ),
            Player.durations
        ),
        right = Anim8.newAnimation(
            grid(
                1, 8,
                2, 8,
                1, 8,
                3, 8
            ),
            Player.durations
        ),
        left = Anim8.newAnimation(
            grid(
                4, 8,
                5, 8,
                4, 8,
                5, 8
            ),
            Player.durations
        ),
    }

    -- Default player to facing us
    Player.animation = Player.animations.down

    love.physics.setMeter(32)

    Map = Sti('assets/levels/level0001.lua', {'box2d'})

    World = love.physics.newWorld(0, 0)

    -- Prepare collision objects
    Map:box2d_init(World)

    Map:addCustomLayer('Sprite Layer', 4)

    local sprite_layer = Map.layers['Sprite Layer']

    for k, object in pairs(Map.objects) do
        if object.name == 'Player' then
            spawn_point = object
            Player.x = spawn_point.x
            Player.y = spawn_point.y
            break
        end
    end

    -- Attach our player to the Map layer
    sprite_layer.sprites = {
        player = Player
    }

    -- Update callback for Custom Layer
    function sprite_layer:update(deltatime)
        for _, sprite in pairs(self.sprites) do
            -- if sprite.rotation then
            --     sprite.rotation = sprite.rotation + math.rad(90 * deltatime)
            -- end
        end
    end

    -- Draw callback for Custom Layer
    function sprite_layer:draw()
        for _, sprite in pairs(self.sprites) do
            Player.animation:draw(
                sprite.spritesheet,
                math.floor(sprite.x),
                math.floor(sprite.y),
                sprite.rotation,
                1,
                1,
                sprite.offset_x,
                sprite.offset_y
            )

            -- Temporarily draw a point at our location so we know
            -- that our sprite is offset properly
            love.graphics.setPointSize(5)
            love.graphics.points(
                math.floor(sprite.x),
                math.floor(sprite.y)
            )
        end
    end

    -- Remove unneeded object layer
    Map:removeLayer('Spawn Point')
end


-- GameScreen handles our actual game play

function GameScreen:draw()
    -- Draw hud
    love.graphics.setColor(255, 255, 255)
    love.graphics.print('GameScreen:draw()', 16, 16)

    fps = love.timer.getFPS()
    love.graphics.print(
        'fps: '..('%3d'):format(fps),
        love.graphics.getWidth() - 96, -- eyeballed
        16
    )

    love.graphics.print(
        'Player: (' .. ('%d'):format(Player.x) .. ', ' .. ('%d'):format(Player.y) .. ')',
        16,
        32
    )

    -- Draw our Map
    love.graphics.setColor(255, 255, 255)
    Map:draw(0, 64)

    -- Draw Collision Map (useful for debugging)
    love.graphics.setColor(0, 0, 255)
    Map:box2d_draw(0, 64)
end


function GameScreen:update(deltatime)
    -- We only want to animate the player animation when we are moving
    animate_player = false

    if love.keyboard.isDown('up') or love.keyboard.isDown('w') then
        Player.y = Player.y - Player.speed * deltatime
        Player.animation = Player.animations.up
        animate_player = true
    end

    if love.keyboard.isDown('down') or love.keyboard.isDown('s') then
        Player.y = Player.y + Player.speed * deltatime
        Player.animation = Player.animations.down
        animate_player = true
    end

    if love.keyboard.isDown('left') or love.keyboard.isDown('a') then
        Player.x = Player.x - Player.speed * deltatime
        Player.animation = Player.animations.left
        animate_player = true
    end

    if love.keyboard.isDown('right') or love.keyboard.isDown('d') then
        Player.x = Player.x + Player.speed * deltatime
        Player.animation = Player.animations.right
        animate_player = true
    end

    if animate_player then
        Player.animation:update(deltatime)
    end

    -- Update our Map to keep everything in sync
    Map:update(deltatime)
end


function GameScreen:keypressed(key, code)
    if love.keyboard.isDown('escape') or love.keyboard.isDown('q') then
        love.event.quit()
    end
end


function GameScreen:quit()
    print('Thank you for playing!')
    return false
end


-- TitleScreen handles our main title screen

function TitleScreen:draw()
    love.graphics.print('TitleScreen:draw()', 16, 16)
    love.graphics.print('Press Enter to continue', 16, 32)
end


function TitleScreen:keyreleased(key, code)
    if key == 'return' then
        Gamestate.switch(GameScreen)
    end
end
