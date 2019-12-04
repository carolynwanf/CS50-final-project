require 'Util'

Map = Class{}

TILE_MIDGROUND = 2
TILE_TOPSOIL = 1
TILE_EMPTY = -1

 -- endgame variables
 characterCount = 6
 killCount = 3
 sum = 0

 badCount = 0
 spyCount = 0
 neutralCount = 0
 savePercentage = nil

characterList = {'spy', ''}

-- a speed to multiply delta time to scroll map; smooth value
local SCROLL_SPEED = 62

-- constructor for our map object
function Map:init()

    self.spritesheet = love.graphics.newImage('graphics/map.png')
    self.sprites = generateQuads(self.spritesheet, 16, 16)
    -- TODO self.music = love.audio.newSource('sounds/music.wav', 'static')

    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 216 -- 27 (virt width) * 8 screens
    self.mapHeight = 28
    self.tiles = {}

    -- initialize gamestate
    gameState = 'start'

    character_status = {0, 0, 0, 0, 0, 0}
    character_worth = {1, 2, 10, 2, 10 ,2}

    -- applies positive Y influence on anything affected
    self.gravity = 20

    --  associate player with map
    self.player = Player(self)

    -- camera offsets
    self.camX = 0
    self.camY = -3

    self.currentTalkingCharacter = nil
    self.currentTalkingThreshold = 100

    -- screen for boundary checking
    self.screen = 0


    self.characters = {
        Character(self.tileWidth * 18, SPY, {
            'I am a spy!'
        }),
        Character(self.tileWidth * 30 * 3, NEUTRAL_A, {
            'Im neutral a!'
        }),
        Character(self.tileWidth * 30 * 4, BAD_A, {
            'im a baddie!'
        }),
        Character(self.tileWidth * 30 * 5, NEUTRAL_C, {
            'neutral c!'
        }),
        Character(self.tileWidth * 30 * 6, BAD_B, {
            'baddie b!'
        }),
        Character(self.tileWidth * 30 * 7, NEUTRAL_B, {
            'n b!'
        })
    }


    -- cache width and height of map in pixels
    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight

    -- first, fill map with empty tiles
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            
            -- support for multiple sheets per tile; storing tiles as tables 
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    -- TODO: generate terrain
    for y = self.mapHeight / 2, self.mapHeight do
        for x = 1, self.mapWidth do
            if y == self.mapHeight / 2 then
                self:setTile(x, y, TILE_TOPSOIL)
            else
            
                -- support for multiple sheets per tile; storing tiles as tables 
                self:setTile(x, y, TILE_MIDGROUND) --floor
            end
        end
    end


    -- TODO: start the background music
    --self.music:setLooping(true)
    -- self.music:play()
end

-- return whether a given tile is collidable
function Map:collides(tile)
    -- define our collidable tiles
    local collidables = {
        TILE_TOPSOIL
    }

    -- iterate and return true if our tile type matches
    -- how to iterate over key-value pairs in lua
    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        end
    end

    return false
end

function Map:inRange()
    if self.player.x >= characters[self.screen + 1].x - 48 then
        return true
    end
    return false
end

-- function to update camera offset with delta time
function Map:update(dt)
    self.player:update(dt)

    if self.player.x < self.screen * 432 then
        self.player.x = self.screen * 432
    end
    
    if self.player.x > (self.screen + 1) * 432 - self.player.width then
        self.screen = self.screen + 1
        self.player.x = self.screen * 432
    end

    for _, character in self.characters do
        if self.player:collides(character) then
            character.displayDialogue()

            self.currentTalkingThreshold = character.x + 100
        end
    end

    if self.player.x >= self.currentTalkingThreshold then

    end

    if characterCount > killCount then
        gameState = 'two options'
        if love.keyboard.wasPressed('k') then
            killCount = killCount - 1
            character_status[self.screen] = 1
        end
        characterCount = characterCount - 1
    elseif characterCount == killCount and killCount ~= 0 then
        gameState = 'one option'
        character_status[self.screen] = 1
        killCount = killCount - 1
        characterCount = characterCount - 1
    -- set game state to end, when gamestate = end tally up dead
    else
        gameState = 'end'
    end


            

    
    -- TODO keep camera's X coordinate following the player, preventing camera from
    -- scrolling past 0 to the left and the map's width (clamps)
    self.camX = math.max(0, math.min(self.player.x - VIRTUAL_WIDTH / 2,
    math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x)))
end

-- gets the tile type at a given pixel coordinate
function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end

-- returns an integer value for the tile at a given x-y coordinate
function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

-- sets a tile at a given x-y coordinate to an integer value
function Map:setTile(x, y, id)
    self.tiles[(y - 1) * self.mapWidth + x] = id
end

-- function Map:endGame()
--     self.sum = self.spyCount +
--     self.neutralCount * 2 +
--     self.badCount * 10

--     if self.sum == 22 then -- BBN
--         self.savePercentage = 100 -- percentage saved
--     elseif self.sum == 21 then -- BBS
--         self.savePercentage = 20
--     elseif self.sum == 14 then -- BNN
--         self.savePercentage = 70
--     elseif self.sum == 13 then -- BNS
--         self.savePercentage = 10
--     elseif self.sum == 6 then -- NNN
--         self.savePercentage = 50
--     else if self.sum == 5 then -- NNS
--         self.savePercentage = 0
--     else -- WRONG
--         self.savePercentage = 6969
--     end
    
-- end


-- renders our map to the screen, to be called by main's render
function Map:render()

    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spritesheet, self.sprites[tile],
                    (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
            end
        end
    end

    self.player:render()

    for key, character in ipairs(self.characters) do
        character:render()
    end
    
end