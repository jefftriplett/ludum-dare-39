
-- GameScreen handles our actual game play

local Anim8 = require('lib.vendor.anim8.anim8')
local Bump = require('lib.vendor.bump.bump')
local Class = require('lib.vendor.middleclass.middleclass')
local Gamestate = require('lib.vendor.hump.gamestate')
local Inspect = require('lib.vendor.inspect.inspect')
local Sti = require('lib.vendor.sti')

local GameScreen = Gamestate.new()

local Font = nil
local Grid = nil
local Map = nil
local World = nil
local Debug = false  -- TODO: Change before release

local Levels = {
    {
        title = "David Skinner's Microban Level 1",
        filename = 'levels/level0001.lua',
    },
    {
        title = "David Skinner's Microban Level 2",
        filename = 'levels/level0002.lua',
    },
    {
        title = "David Skinner's Microban Level 3",
        filename = 'levels/level0003.lua',
    },
    {
        title = "David Skinner's Microban Level 4",
        filename = 'levels/level0004.lua',
    },
    {
        title = "David Skinner's Microban Level 5",
        filename = 'levels/level0005.lua',
    },
    {
        title = "David Skinner's Microban Level 6",
        filename = 'levels/level0006.lua',
    },
    {
        title = "David Skinner's Microban Level 7",
        filename = 'levels/level0007.lua',
    },
    {
        title = "David Skinner's Microban Level 8",
        filename = 'levels/level0008.lua',
    },
    {
        title = "David Skinner's Microban Level 9",
        filename = 'levels/level0009.lua',
    },
    {
        title = "David Skinner's Microban Level 10",
        filename = 'levels/level0010.lua',
    },
}

local StartingLevel = 1
local CurrentLevel = StartingLevel

-- TODO: Turn our player into an Entity
local Player = {
    x = nil,
    y = nil,
    offset_x = 16,  -- I eyeballed the x and y to get "right"
    offset_y = 32,
    rotation = 0,
    width = 32,
    height = 16,
    speed = 128,
    type = 'player',
    collidable = true,
    sensor = true,
    durations = 0.25,  -- or this can be {0.5, 0.1, ...} based on each frame
    animation = nil,  -- our index for holding which Quad we are displaying
    animations = nil,  -- our Quads
    spritesheet = nil,  -- our image spritesheet which holds all of our images
}

local Targets = nil
local Entities = nil

local Entity = Class('Entity')

function Entity:initialize()
    self.entity_id = nil  -- this is how we tell from entity from another
    self.x = nil
    self.y = nil
    self.offset_x = 0
    self.offset_y = 0
    self.rotation = 0
    self.width = 64
    self.height = 64
    self.speed = 128
    self.type = 'unknown'
    self.collidable = true
    self.sensor = true
    self.durations = 0.25  -- or this can be {0.5, 0.1, ...} based on each frame
    self.animation = nil  -- our index for holding which Quad we are displaying
    self.animations = nil  -- our Quads
    self.spritesheet = nil  -- our image spritesheet which holds all of our images
    self.properties = {}
    self.properties.movable = true

    self.animations = {
        default = Anim8.newAnimation(
            Grid(
                2, 1,
                2, 2
            ),
            self.durations
        ),
        on_target = Anim8.newAnimation(
            Grid(
                2, 2
            ),
            self.durations
        )
    }
    self.animation = self.animations.default
    self.spritesheet = Player.spritesheet
end


local Box = Class('Box', Entity)

function Box:initialize()
    Entity.initialize(self)
    self.type = 'box'
end


function GameScreen:draw()
    -- Draw hud
    love.graphics.setColor(255, 255, 255)
    -- love.graphics.setColor(89, 106, 108)
    love.graphics.print(Levels[CurrentLevel].title, 16, 16)

    fps = love.timer.getFPS()
    love.graphics.print(
        'fps: '..('%3d'):format(fps),
        love.graphics.getWidth() - 96, -- eyeballed
        16
    )

    love.graphics.print(
        'Map Tile: (x:' .. ('%d'):format(Player.x / 64) .. ', y:' .. ('%d'):format(Player.y / 64) .. '); ' ..
        'Player: (x:' .. ('%d'):format(Player.x) .. ', y:' .. ('%d'):format(Player.y) .. ')',
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


function GameScreen:enter()

    Font = love.graphics.newFont('assets/fonts/Kenney Pixel.ttf', 32)
    love.graphics.setFont(Font)

    Player.spritesheet = love.graphics.newImage('assets/images/sokoban_tilesheet.png')
    Grid = Anim8.newGrid(64, 64, Player.spritesheet:getWidth(), Player.spritesheet:getHeight())

    Player.animations = {
        down = Anim8.newAnimation(
            Grid(
                1, 6,
                2, 6,
                1, 6,
                3, 6
            ),
            Player.durations
        ),
        up = Anim8.newAnimation(
            Grid(
                4, 6,
                5, 6,
                4, 6,
                6, 6
            ),
            Player.durations
        ),
        right = Anim8.newAnimation(
            Grid(
                1, 8,
                2, 8,
                1, 8,
                3, 8
            ),
            Player.durations
        ),
        left = Anim8.newAnimation(
            Grid(
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

    GameScreen:load_level(Levels[CurrentLevel].filename)

    local sprite_layer = Map.layers['Sprite Layer']
    local target_group = Map.layers['targets']

    -- TODO: We need to refactor / move this target finding code

    Targets = {}

    print('v================================================================')
    print(Inspect(target_group))
    print('v----------------------------------------------------------------')
    print('height: ' .. target_group.height)
    print('width:  ' .. target_group.width)
    for y, target in ipairs(target_group.data) do
        if next(target) ~= nil then
            print('index: ' .. y)
            print(Inspect(target))

            for x, tile in pairs(target) do
                tile_index = x + y * target_group.width + 1
                print('x: ' .. x)
                print('y: ' .. y)
                print('width:' .. target_group.width)
                print('tile index:' .. tile_index)
                print('is_target:', tile.properties.target)
                print(tile.gid)
                -- tile.gid = 27
                Targets[tile_index] = tile
                -- target_group.data[tile_index] = 27
            end
        end
    end

    print('Targets:')
    print(Inspect(Targets))
    print('^----------------------------------------------------------------')
end


function GameScreen:keypressed(key, code)
    if love.keyboard.isDown('escape') or love.keyboard.isDown('q') then
        love.event.quit()
    end

    if love.keyboard.isDown('`') or love.keyboard.isDown('tab') then
        Debug = not Debug
    end

    if love.keyboard.isDown('p') then
        Gamestate.push(gamestates.pause)
    end

    if Debug then
        if love.keyboard.isDown('1') then
            CurrentLevel = 1
            GameScreen:load_level(Levels[CurrentLevel].filename)
        end

        if love.keyboard.isDown('2') then
            CurrentLevel = 2
            GameScreen:load_level(Levels[CurrentLevel].filename)
        end

        if love.keyboard.isDown('3') then
            CurrentLevel = 3
            GameScreen:load_level(Levels[CurrentLevel].filename)
        end

        if love.keyboard.isDown('4') then
            CurrentLevel = 4
            GameScreen:load_level(Levels[CurrentLevel].filename)
        end

        if love.keyboard.isDown('5') then
            CurrentLevel = 5
            GameScreen:load_level(Levels[CurrentLevel].filename)
        end

        if love.keyboard.isDown('6') then
            CurrentLevel = 6
            GameScreen:load_level(Levels[CurrentLevel].filename)
        end

        if love.keyboard.isDown('7') then
            CurrentLevel = 7
            GameScreen:load_level(Levels[CurrentLevel].filename)
        end

        if love.keyboard.isDown('8') then
            CurrentLevel = 8
            GameScreen:load_level(Levels[CurrentLevel].filename)
        end

        if love.keyboard.isDown('9') then
            CurrentLevel = 9
            GameScreen:load_level(Levels[CurrentLevel].filename)
        end

        if love.keyboard.isDown('0') then
            CurrentLevel = 10
            GameScreen:load_level(Levels[CurrentLevel].filename)
        end
    end
end


function GameScreen:load_level(filename)
    Map = Sti(filename, {'bump'})

    World = Bump.newWorld(32)

    -- Reset Entities to keep from accum
    Entities = nil
    Entities = {}

    -- Prepare collision objects
    Map:bump_init(World)

    Map:addCustomLayer('Sprite Layer', 4)

    local sprite_layer = Map.layers['Sprite Layer']

    for k, object in pairs(Map.objects) do
        if object.name == 'Player' then
            Player.x = object.x + 16
            Player.y = object.y + 32
            World:add(Player, Player.x, Player.y, Player.width, Player.height)

        elseif object.type == 'Box' then
            -- Entities / Boxes
            obj = Box:new()
            obj.x = object.x
            obj.y = object.y
            Entities[k] = obj
            World:add(Entities[k], obj.x, obj.y, obj.width, obj.height)
        end
    end

    -- Attach our player to the Map layer
    sprite_layer.sprites = {
        player = Player,
        entities = Entities
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
            if sprite.type == 'player' then
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
            else
                for _, entity_sprite in pairs(sprite) do
                    entity_sprite.animation:draw(
                        entity_sprite.spritesheet,
                        math.floor(entity_sprite.x),
                        math.floor(entity_sprite.y),
                        entity_sprite.rotation,
                        1,
                        1,
                        entity_sprite.offset_x,
                        entity_sprite.offset_y
                    )
                end
            end

            -- Temporarily draw a point at our location so we know
            -- that our sprite is offset properly
            if Debug then
                if sprite.type == 'player' then
                    love.graphics.rectangle(
                        'fill',
                        math.floor(sprite.x),
                        math.floor(sprite.y),
                        math.floor(sprite.width),
                        math.floor(sprite.height)
                    )
                else
                    for _, entity_sprite in pairs(sprite) do
                    love.graphics.rectangle(
                        'fill',
                        math.floor(entity_sprite.x),
                        math.floor(entity_sprite.y),
                        math.floor(entity_sprite.width),
                        math.floor(entity_sprite.height)
                    )
                    end
                end
            end
        end
    end

    -- Remove unneeded object layer
    Map:removeLayer('Spawn Point')
end


function GameScreen:quit()
    print('Thank you for playing!')
    return false
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
    elseif love.keyboard.isDown('down') or love.keyboard.isDown('s') then
        Player.y = Player.y + Player.speed * deltatime
        Player.animation = Player.animations.down
        animate_player = true
    elseif love.keyboard.isDown('left') or love.keyboard.isDown('a') then
        Player.x = Player.x - Player.speed * deltatime
        Player.animation = Player.animations.left
        animate_player = true
    elseif love.keyboard.isDown('right') or love.keyboard.isDown('d') then
        Player.x = Player.x + Player.speed * deltatime
        Player.animation = Player.animations.right
        animate_player = true
    end

    if animate_player then
        Player.animation:update(deltatime)
    end

    Player.x, Player.y, collisions, collision_len = World:move(Player, Player.x, Player.y)
    if collision_len > 0 then
        -- print(Inspect(collisions))
        for i=1,collision_len do
            local collision = collisions[i]
            -- print(collision.other.id)
            -- print(collision.other.type)
            -- print(collision.other.properties.movable)
            -- print(collision.other.y)
            if collision and collision.other.properties.movable then
                destination_x = collision.other.x
                destination_y = collision.other.y

                object_group = Map.objects
                for _, sprite in pairs(object_group) do
                    -- print(sprite.x == collision.other.x and sprite.y == collision.other.y)
                    -- if sprite.rotation then
                    --     sprite.rotation = sprite.rotation + math.rad(90 * deltatime)
                    -- end
                end

                -- print(Map:convertPixelToTile(collision.other.x, collision.other.y))

                -- There are probably better ways to do this, but we push the block
                -- based on the direction that our player is facing

                if Player.animation == Player.animations.up then
                    destination_y = destination_y - 64
                elseif Player.animation == Player.animations.down then
                    destination_y = destination_y + 64
                elseif Player.animation == Player.animations.left then
                    destination_x = destination_x - 64
                elseif Player.animation == Player.animations.right then
                    destination_x = destination_x + 64
                end

                collision.other.x, collision.other.y, collisions, collision_len = World:move(collision.other, destination_x, destination_y)
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


return GameScreen
