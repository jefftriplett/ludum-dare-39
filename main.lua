
-- Modules

local Gamestate = require('lib.vendor.hump.gamestate')


-- Global variables

local Font = nil

gamestates = {}
gamestates.game = require('gamestates.game')
gamestates.pause = require('gamestates.pause')
gamestates.title = require('gamestates.title')


-- Love section

function love.load()
    -- Set our global font
    Font = love.graphics.newFont('assets/fonts/Kenney Pixel.ttf', 32)
    love.graphics.setFont(Font)

    Gamestate.registerEvents()
    Gamestate.switch(gamestates.title)
end
