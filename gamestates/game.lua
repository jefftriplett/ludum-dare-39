
-- GameScreen handles our main title screen

local Anim8 = require('lib.vendor.anim8.anim8')
local Bump = require('lib.vendor.bump.bump')
local Gamestate = require('lib.vendor.hump.gamestate')
local Inspect = require('lib.vendor.inspect.inspect')
local Sti = require('lib.vendor.sti')


local GameScreen = Gamestate.new()

local Font = nil
local Map = nil
local World = nil
local Debug = true  -- TODO: Change before release

local Player = {
    x = nil,
    y = nil,
    offset_x = 16,  -- I eyeballed the x and y to get "right"
    offset_y = 32,
    rotation = 0,
    width = 32,
    height = 16,
    speed = 128,
    collidable = true,
    sensor = true,
    durations = 0.25,  -- or this can be {0.5, 0.1, ...} based on each frame
    animation = nil,  -- our index for holding which Quad we are displaying
    animations = nil,  -- our Quads
    spritesheet = nil,  -- our image spritesheet which holds all of our images
}


-- GameScreen handles our actual game play

function GameScreen:enter()

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

    Map = Sti('assets/levels/level0001.lua', {'bump'})

    World = Bump.newWorld(64)

    -- Prepare collision objects
    Map:bump_init(World)

    Map:addCustomLayer('Sprite Layer', 4)

    local sprite_layer = Map.layers['Sprite Layer']

    for k, object in pairs(Map.objects) do
        if object.name == 'Player' then
            spawn_point = object
            Player.x = spawn_point.x
            Player.y = spawn_point.y
            World:add(Player, Player.x, Player.y, Player.width, Player.height)
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
            if Debug then
                love.graphics.rectangle(
                    'fill',
                    math.floor(sprite.x),
                    math.floor(sprite.y),
                    math.floor(sprite.width),
                    math.floor(sprite.height)
                )
            end
        end
    end

    -- Remove unneeded object layer
    Map:removeLayer('Spawn Point')
end


function GameScreen:draw()
    -- Draw hud
    love.graphics.setColor(255, 255, 255)
    -- love.graphics.setColor(89, 106, 108)
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
    if Debug then
        love.graphics.setColor(0, 0, 255)
        Map:bump_draw(World, 0, 64, 1, 1)
    end
end


function GameScreen:update(deltatime)
    -- Update our Map to keep everything in sync
    Map:update(deltatime)

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

    Player.x, Player.y, collisions, collision_len = World:move(Player, Player.x, Player.y)
    if collision_len > 0 then
        if Debug then
            print(collision_len)
            print(Inspect(collisions))
            for i=1,collision_len do
                local collision = collisions[i]
                print(collision.other)
            end
        end
    end

    -- TODO: Do something with this...
    for i,v in ipairs (collisions) do
        if collisions[i].normal.y == -1 then
            -- player.yvel = 0
            -- player.grounded = true
            -- debug = debug.."Collided "
            if Debug then
                print('Collided')
            end
        elseif collisions[i].normal.y == 1 then
            -- player.yvel = -player.yvel/4
        end
        if collisions[i].normal.x ~= 0 then
            -- player.xvel = 0
        end
    end
end


function GameScreen:keypressed(key, code)
    if love.keyboard.isDown('escape') or love.keyboard.isDown('q') then
        love.event.quit()
    end

    if love.keyboard.isDown('tab') then
        Debug = not Debug
    end

    if love.keyboard.isDown('p') then
        Gamestate.push(gamestates.pause)
    end
end


function GameScreen:quit()
    print('Thank you for playing!')
    return false
end


return GameScreen
