
-- Modules

local Gamestate = require('lib.vendor.hump.gamestate')


-- Global variables

local Font = nil

gamestates = {}
gamestates.title = require('gamestates.title')
gamestates.game = require('gamestates.game')


-- Love section

function love.load()
    -- Set our global font
    Font = love.graphics.newFont('assets/fonts/Kenney Pixel.ttf', 32)
    love.graphics.setFont(Font)

    Gamestate.registerEvents()
    Gamestate.switch(gamestates.title)
end
