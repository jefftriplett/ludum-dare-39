
-- Modules

local Gamestate = require('lib.vendor.hump.gamestate')


-- Global variables

gamestates = {}
gamestates.game = require('gamestates.game')
gamestates.pause = require('gamestates.pause')
gamestates.title = require('gamestates.title')
gamestates.winning = require('gamestates.winning')


-- Love section

function love.load()
    Gamestate.registerEvents()
    Gamestate.switch(gamestates.title)
end
