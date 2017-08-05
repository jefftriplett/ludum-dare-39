
-- GameScreen handles our actual game play

local Anim8 = require('lib.vendor.anim8.anim8')
local Baton = require('lib.vendor.baton.baton')
local Bump = require('lib.vendor.bump.bump')
local Class = require('lib.vendor.middleclass.middleclass')
local Gamestate = require('lib.vendor.hump.gamestate')
local Inspect = require('lib.vendor.inspect.inspect')
local Sti = require('lib.vendor.sti')

local GameScreen = Gamestate.new()

local Font = nil
local TitleFont = nil
local Grid = nil
local Map = nil
local World = nil
local Debug = false  -- TODO: Change before release


local Controls = {
    left = {
        'key:left',
        'key:a',
        'axis:leftx-',
        'button:dpleft'
    },
    right = {
        'key:right',
        'key:d',
        'axis:leftx+',
        'button:dpright'
    },
    up = {
        'key:up',
        'key:w',
        'axis:lefty-',
        'button:dpup'
    },
    down = {
        'key:down',
        'key:s',
        'axis:lefty+',
        'button:dpdown'
    },
    debug = {
        'key:tab',
        'key:`',
    },
    pause = {
        'key:p',
    },
    quit = {
        'key:escape',
        'key:q',
    },
    reload = {
        'key:r',
    },
}

local Input = Baton.new(Controls, love.joystick.getJoysticks()[1])

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

local Entities = nil
local Targets = nil

local CurrentTargets = nil
local TotalTargets = nil

local Player = nil

local Spritesheet = love.graphics.newImage('assets/images/sokoban_tilesheet.png')
local Grid = Anim8.newGrid(64, 64, Spritesheet:getWidth(), Spritesheet:getHeight())


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
    self.properties = {}
    self.properties.movable = true
end


function Entity:tile_id()
    return (math.floor(self.x / 64 ) + 1)
        + (math.floor(self.y / 64) + 1) * Map.width
        + 1
end

function Entity:covers_target()
    if Targets[self:tile_id()] then
        return true
    else
        return false
    end
end

-- TODO: Turn our player into an Entity
local PlayerClass = Class('PlayerClass', Entity)

function PlayerClass:initialize()
    Entity.initialize(self)
    self.offset_x = 16  -- I eyeballed the x and y to get "right"
    self.offset_y = 32
    self.rotation = 0
    self.width = 32
    self.height = 16
    self.speed = 128
    self.type = 'player'
    -- self.collidable = true
    -- self.sensor = true
    self.durations = 0.25  -- or this can be {0.5, 0.1, ...} based on each frame
    self.animations = {
        down = Anim8.newAnimation(
            Grid(
                1, 6,
                2, 6,
                1, 6,
                3, 6
            ),
            self.durations
        ),
        up = Anim8.newAnimation(
            Grid(
                4, 6,
                5, 6,
                4, 6,
                6, 6
            ),
            self.durations
        ),
        right = Anim8.newAnimation(
            Grid(
                1, 8,
                2, 8,
                1, 8,
                3, 8
            ),
            self.durations
        ),
        left = Anim8.newAnimation(
            Grid(
                4, 8,
                5, 8,
                4, 8,
                5, 8
            ),
            self.durations
        ),
    }

    -- Default player to facing us
    self.animation = self.animations.down
end


function PlayerClass:up(deltatime)
    self.y = self.y - self.speed * deltatime
    self.animation = self.animations.up
end


function PlayerClass:down(deltatime)
    self.y = self.y + self.speed * deltatime
    self.animation = self.animations.down
end


function PlayerClass:left(deltatime)
    self.x = self.x - self.speed * deltatime
    self.animation = self.animations.left
end


function PlayerClass:right(deltatime)
    self.x = self.x + self.speed * deltatime
    self.animation = self.animations.right
end

local Box = Class('Box', Entity)

function Box:initialize()
    Entity.initialize(self)
    self.type = 'box'
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
end


function GameScreen:draw()
    -- Draw hud
    love.graphics.setColor(255, 255, 255)
    -- love.graphics.setColor(89, 106, 108)
    love.graphics.setFont(TitleFont)
    love.graphics.print(Levels[CurrentLevel].title, 16, 16)

    love.graphics.setFont(Font)

    if Debug then
        fps = love.timer.getFPS()
        love.graphics.print(
            'fps: '..('%3d'):format(fps),
            love.graphics.getWidth() - 128, -- eyeballed
            16
        )
        love.graphics.print(
            'Targets: '..('%3d'):format(TotalTargets),
            love.graphics.getWidth() - 128, -- eyeballed
            16
        )
        love.graphics.print(
            'Current: '..('%3d'):format(CurrentTargets),
            love.graphics.getWidth() - 128, -- eyeballed
            32
        )
        love.graphics.print(
            'Map Tile: (x:' .. ('%d'):format(Player.x / 64 + 1) .. ', y:' .. ('%d'):format(Player.y / 64 + 1) .. '); ' ..
            'Player: (x:' .. ('%d'):format(Player.x) .. ', y:' .. ('%d'):format(Player.y) .. ')',
            16,
            32
        )
    end

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
    TitleFont = love.graphics.newFont('assets/fonts/Kenney Pixel.ttf', 64)

    love.graphics.setFont(Font)
    love.physics.setMeter(32)

    Player = PlayerClass()

    GameScreen:load_level(Levels[CurrentLevel].filename)
end


function GameScreen:keypressed(key, code)

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

    -- Reset to keep from accumulating entities from other levels
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

    -- Update callback for our Spite Layer
    function sprite_layer:update(deltatime)
        for _, sprite in pairs(self.sprites) do
            if sprite.type ~= 'player' then
                for _, entity_sprite in pairs(sprite) do
                    if entity_sprite:covers_target() and entity_sprite.animation ~= entity_sprite.animations.on_target then
                        entity_sprite.animation = entity_sprite.animations.on_target
                        CurrentTargets = CurrentTargets + 1
                    elseif not entity_sprite:covers_target() and entity_sprite.animation ~= entity_sprite.animations.default then
                        entity_sprite.animation = entity_sprite.animations.default
                        CurrentTargets = CurrentTargets - 1
                    end
                end
            end
        end
    end

    -- Draw callback for Custom Layer
    function sprite_layer:draw()
        for _, sprite in pairs(self.sprites) do
            if sprite.type == 'player' then
                Player.animation:draw(
                    Spritesheet,
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
                        Spritesheet,
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

    local sprite_layer = Map.layers['Sprite Layer']
    local target_group = Map.layers['targets']

    -- TODO: We need to refactor / move this target finding code

    Targets = {}
    CurrentTargets = 0
    TotalTargets = 0

    for y, target in ipairs(target_group.data) do
        if next(target) ~= nil then
            for x, tile in pairs(target) do
                tile_index = x + (y * target_group.width) + 1
                Targets[tile_index] = true
                TotalTargets = TotalTargets + 1
            end
        end
    end
end


function GameScreen:quit()
    print('Thank you for playing!')
    return false
end


function GameScreen:update(deltatime)
    Input:update()

    -- Update our Map to keep everything in sync
    Map:update(deltatime)

    -- We only want to animate the player animation when we are moving
    animate_player = false

    if Input:pressed 'debug' then
        Debug = not Debug
    end

    if Input:pressed 'pause' then
        Gamestate.push(gamestates.pause)
    end

    if Input:pressed 'quit' then
        love.event.quit()
    end

    if Input:pressed 'reload' then
        GameScreen:load_level(Levels[CurrentLevel].filename)
    end

    if Input:down 'up' then
        Player:up(deltatime)
        animate_player = true
    elseif Input:down 'down' then
        Player:down(deltatime)
        animate_player = true
    elseif Input:down 'left' then
        Player:left(deltatime)
        animate_player = true
    elseif Input:down 'right' then
        Player:right(deltatime)
        animate_player = true
    end

    if animate_player then
        Player.animation:update(deltatime)
    end

    Player.x, Player.y, collisions, collision_len = World:move(Player, Player.x, Player.y)
    if collision_len > 0 then
        for i=1,collision_len do
            local collision = collisions[i]
            if collision and collision.other.properties.movable then
                destination_x = collision.other.x
                destination_y = collision.other.y

                -- object_group = Map.objects
                -- for _, sprite in pairs(object_group) do
                --     -- if sprite.rotation then
                --     --     sprite.rotation = sprite.rotation + math.rad(90 * deltatime)
                --     -- end
                -- end

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

    if CurrentTargets > 0 and TotalTargets > 0 and CurrentTargets == TotalTargets then
        CurrentLevel = CurrentLevel + 1
        if CurrentLevel > #Levels then
            Gamestate.switch(gamestates.winning)
        else
            GameScreen:load_level(Levels[CurrentLevel].filename)
        end
    end

    -- TODO: Do something with this...
    -- for i,v in ipairs (collisions) do
    --     if collisions[i].normal.y == -1 then
    --         -- player.yvel = 0
    --         -- player.grounded = true
    --         -- debug = debug.."Collided "
    --         if Debug then
    --             print('Collided')
    --         end
    --     elseif collisions[i].normal.y == 1 then
    --         -- player.yvel = -player.yvel/4
    --     end
    --     if collisions[i].normal.x ~= 0 then
    --         -- player.xvel = 0
    --     end
    -- end
end


return GameScreen
