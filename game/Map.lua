require 'Util'

Map = Class{}

TILE_MIDGROUND = 2
TILE_TOPSOIL = 1
TILE_EMPTY = -1

MAGMA_LEFT = 3
MAGMA_MIDDLE = 4
MAGMA_RIGHT = 5

CLOUD_LEFT = 6
CLOUD_RIGHT = 7

PLATFORM_LEFT = 9
PLATFORM_MIDDLE = 10
PLATFORM_RIGHT = 11

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

    -- dialogue variable
    self.dialogue_Fininshed = false
    self.dialogue_number = 1

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
        Character(VIRTUAL_WIDTH - 100, SPY, {
            'I am a spy!'
        }),
        Character(VIRTUAL_WIDTH * 2 - 100, NEUTRAL_A, {
            'Im neutral a!'
        }),
        Character(VIRTUAL_WIDTH * 3 - 100, BAD_A, {
            'im a baddie!'
        }),
        Character(VIRTUAL_WIDTH * 4 - 100, NEUTRAL_C, {
            'neutral c!'
        }),
        Character(VIRTUAL_WIDTH * 5 - 100, BAD_B, {
            'baddie b!'
        }),
        Character(VIRTUAL_WIDTH * 6 - 100, NEUTRAL_B, {
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

    local x = 1
    while x < self.mapWidth do
        
        -- generate clouds
        if x < self.mapWidth - 2 then
            if math.random(5) == 1 then
                
                -- choose a random vertical spot above where blocks generate
                local cloudStart = math.random(self.mapHeight / 2 - 6)

                self:setTile(x, cloudStart, CLOUD_LEFT)
                self:setTile(x + 1, cloudStart, CLOUD_RIGHT)
            end
        end

        -- 10% chance to generate a magma puddle
        -- make sure we're 2 tiles from edge at least
        if x < self.mapWidth - 3 and x ~= self.characters[self.screen + 1].x and x ~= self.characters[self.screen + 1].x - 1 and x ~= self.characters[self.screen + 1].x - 2 and x ~= self.player.x then
            if math.random(7) == 1 then

                self:setTile(x, self.mapHeight / 2, MAGMA_LEFT)
                self:setTile(x + 1, self.mapHeight / 2, MAGMA_MIDDLE)
                self:setTile(x + 2, self.mapHeight / 2, MAGMA_RIGHT)

                local RISE = math.random(2,4)
                self:setTile(x, self.mapHeight / 2 - RISE, PLATFORM_LEFT)
                self:setTile(x + 1, self.mapHeight / 2 - RISE, PLATFORM_MIDDLE)
                self:setTile(x + 2, self.mapHeight / 2 - RISE, PLATFORM_RIGHT)
            end
            
        end
        x = x + 3
    end


    -- TODO: start the background music
    --self.music:setLooping(true)
    -- self.music:play()
end

-- return whether a given tile is collidable
function Map:collides(tile)
    -- define our collidable tiles
    local collidables = {
        TILE_TOPSOIL, MAGMA_LEFT, MAGMA_MIDDLE, MAGMA_RIGHT, PLATFORM_LEFT, PLATFORM_MIDDLE, PLATFORM_RIGHT
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

function Map:deathCollide(tile)
    -- define death tiles
    local collidables = {
        MAGMA_LEFT, MAGMA_MIDDLE, MAGMA_RIGHT

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
    if self.player.x >= self.characters[self.screen + 1].x - 48 and self.player.x < (self.screen + 1) * VIRTUAL_WIDTH then -- ARIEL!! once we get to the end this function stops working, won't be an issue later just wanted to let you know 
        print('in range of ',self.screen + 1)
        return true
    end
    return false
end

-- function to update camera offset with delta time
function Map:update(dt)
    self.player:update(dt)

    if self.player.x < self.screen * VIRTUAL_WIDTH then
        self.player.x = self.screen * VIRTUAL_WIDTH
    end
    
    if self.player.x > (self.screen + 1) * VIRTUAL_WIDTH - self.player.width then
        self.screen = self.screen + 1
        self.player.x = self.screen * VIRTUAL_WIDTH
    end

    if self:inRange() and not self.dialogue_Fininshed then
        -- player.playerState = 'dialogue'
        -- if enter pressed then
        self.characters[self.screen + 1]:displayDialogue()
    else
        self.characters[self.screen + 1]:stopDialogue()
    end

    -- for _, character in self.characters do
    --     if self.player:collides(character) then
    --         character.displayDialogue()

    --         self.currentTalkingThreshold = character.x + 100
    --     end
    -- end

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
--     if gameState = 'end' then
--         for index, status in character_status do
--             points = character_status[index] * character_worth[index]
--             sum = sum + points
--         end
--         if sum == 22 then -- BBN
--             savePercentage = 100
--         elseif sum == 21 then -- BBS
--             savePercentage = 20
--         elseif sum == 14 then -- BNN
--             savePercentage = 70
--         elseif sum == 13 then -- BNS
--             savePercentage = 10
--         elseif sum == 6 then -- NNN
--             savePercentage = 50
--         else if sum == 5 then -- NNS
--             savePercentage = 0
--         else -- WRONG
--             savePercentage = 6969
--         end
--     end
--     return savePercentage
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