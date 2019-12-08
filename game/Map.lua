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

-- a speed to multiply delta time to scroll map; smooth value
local SCROLL_SPEED = 62

-- constructor for our map object
function Map:init()

     -- endgame variables
    self.characterCount = 6
    self.killCount = 3
    self.sum = 0
    self.savePercentage = 0

    self.spritesheet = love.graphics.newImage('graphics/map.png')
    self.sprites = generateQuads(self.spritesheet, 16, 16)
    -- TODO self.music = love.audio.newSource('sounds/music.wav', 'static')

    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 216
    self.mapHeight = 28
    self.tiles = {}

    -- dialogue variable
    self.dialogue_Finished = false
    self.dialogue_number = 1
    self.max_dialogue = 4

    -- kill + die option or only kill/ die option
    self.canKill = true
    self.canDodge = true

    -- 0 is alive and 1 is dead
    self.character_status = {0, 0, 0, 0, 0, 0}

    -- corresponds with status, their "worth for each character"
    self.character_worth = {1, 2, 10, 2, 10 ,2}

    -- key for character worth
    self.character_type = {'spy', 'neutral', 'bad', 'neutral', 'bad', 'neutral'}

    -- applies positive Y influence on anything affected
    self.gravity = 20

    --  associate player with map
    self.player = Player(self)

    -- camera offsets
    self.camX = 0
    self.camY = -3

    -- screen for boundary checking
    self.screen = 0

    -- npc character array with (x coordinate, name of npc, dialogue array)
    self.characters = {
        Character(VIRTUAL_WIDTH - 100, SPY, {
            'I am a spy!', 'i said something', 'i said two', 'bitch do i live or die'
        }),
        Character(VIRTUAL_WIDTH * 2 - 100, NEUTRAL_A, {
            'Im neutral a!', 'i said something', 'i said two', 'bitch do i live or die'
        }),
        Character(VIRTUAL_WIDTH * 3 - 100, BAD_A, {
            'im a baddie!', 'i said something', 'i said two', 'bitch do i live or die'
        }),
        Character(VIRTUAL_WIDTH * 4 - 100, NEUTRAL_C, {
            'neutral c!', 'i said something', 'i said two', 'bitch do i live or die'
        }),
        Character(VIRTUAL_WIDTH * 5 - 100, BAD_B, {
            'baddie b!', 'i said something', 'i said two', 'bitch do i live or die'
        }),
        Character(VIRTUAL_WIDTH * 6 - 100, NEUTRAL_B, {
            'n b!', 'i said something', 'i said two', 'bitch do i live or die'
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

    -- filling ground tiles
    for y = self.mapHeight / 2, self.mapHeight do
        for x = 1, self.mapWidth do
            -- grass tiles
            if y == self.mapHeight / 2 then
                self:setTile(x, y, TILE_TOPSOIL)
            -- dirt tiles
            else
                self:setTile(x, y, TILE_MIDGROUND)
            end
        end
    end

    -- generate background tiles
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
        -- make sure we're 3 tiles from edge at least
        if x < self.mapWidth - 3 and x > VIRTUAL_WIDTH * 3 and x ~= self.characters[self.screen + 1].x and x ~= self.characters[self.screen + 1].x - 1 and x ~= self.characters[self.screen + 1].x - 2 and x ~= self.player.x and x ~= self.player.x - 1 and x ~= self.player.x - 2 and x ~= self.player.x - 3 then
            if math.random(7) == 1 then

                -- prints a magma pit
                self:setTile(x, self.mapHeight / 2, MAGMA_LEFT)
                self:setTile(x + 1, self.mapHeight / 2, MAGMA_MIDDLE)
                self:setTile(x + 2, self.mapHeight / 2, MAGMA_RIGHT)

                -- prints a platform above a magma pit
                local RISE = math.random(3,4)
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


-- returns true if player is in range of an npc, resets the dialogue_finished variable to false when player passes npc
function Map:inRange()
    if self.player.x >= self.characters[self.screen + 1].x - 48 and self.player.x <= self.characters[self.screen + 1].x then
        -- print('in range of ',self.screen + 1)
        return true
    elseif self.player.x < self.screen * VIRTUAL_WIDTH + 40 then
        self.dialogue_Finished = false
        return false
    else
        return false
    end
end

-- function to update camera offset with delta time
function Map:update(dt)

    self.player:update(dt)

    if self.player.x < self.screen * VIRTUAL_WIDTH then
        self.player.x = self.screen * VIRTUAL_WIDTH
    end
    
    -- if player moves past right bound then increment screen
    if self.player.x > (self.screen + 1) * VIRTUAL_WIDTH then
        self.screen = self.screen + 1
        self.player.x = self.screen * VIRTUAL_WIDTH
    end

    -- if near npc and before dialogue then turn player state into dialogue, print dialogue
    if self:inRange() and not self.dialogue_Finished then
        self.characters[self.screen + 1].speechBubble = true
        self.player.state = 'dialogue'
    else
        self.characters[self.screen + 1].speechBubble = false
    end

    -- if we have more characters left than there are kills available then player can choose to k or d
    if self.characterCount > self.killCount and self.killCount > 0 then
        self.canKill = true
        self.canDodge = true
    elseif self.characterCount <= self.killCount and self.killCount > 0 then
        self.canKill = true
        self.canDodge = false
    else
        self.canKill = false
        self.canDodge = true
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


function Map:endGame()

    -- tally up product of character status and worth
    for i = 1, 6 do
        self.sum = self.sum + self.character_status[i] * self.character_worth[i]
    end

    -- calculate percentage of saved from sum, look at formula sheet on google drive
    if sum == 22 then -- BBN
        self.savePercentage = 100
    elseif sum == 21 then -- BBS
        self.savePercentage = 20
    elseif sum == 14 then -- BNN
        self.savePercentage = 70
    elseif sum == 13 then -- BNS
        self.savePercentage = 10
    elseif sum == 6 then -- NNN
        self.savePercentage = 50
    else if sum == 5 then -- NNS
        self.savePercentage = 1
    else -- WRONG
        self.savePercentage = 6969
    end
end
end


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

     -- print character count and kill count
    love.graphics.setFont(speechFont)
    love.graphics.setColor(1,1,1,255)
    love.graphics.print("Characters left: ".. self.characterCount, self.camX + 5, 5)
    love.graphics.print('Saved percentage: '.. self.savePercentage, self.camX + 5, 25)

    if map.killCount > 0 then
        love.graphics.print("Kills left: ".. self.killCount, self.camX + 5, 15)
    else
        love.graphics.print("NO KILLS LEFT", self.camX + 5, 15)
    end
    love.graphics.setColor(1,1,1,1)

    -- print title
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1,1,1,255)
    love.graphics.print("RESURRECTION", 55, 90)
    love.graphics.setColor(1,1,1,1)

    -- print instructions
    love.graphics.setFont(instructionsFont)
    love.graphics.setColor(1,1,1,255)
    love.graphics.print("you are a government agent that has been transported to an", 478, 60)
    love.graphics.print("alien planet where many of your fellow earthlings are being", 478, 70) 
    love.graphics.print("held hostage. your partner has been stranded on this planet", 478, 80)  
    love.graphics.print("for the past three months and has been forced to blend in", 478, 90)
    love.graphics.print("from the clutches of the hostile race of block men, you must", 478, 100)  
    love.graphics.print("talk to six characters and determine which ones are evil,", 478, 110)
    love.graphics.print("which ones are innocent civilians, and which one is your", 478, 120) 
    love.graphics.print("partner. kill three characters, spare your partner. the fate", 478, 130)
    love.graphics.print("of the hostages rests in your hands. good luck, agent", 478, 140)
    love.graphics.setColor(1,1,1,1)

end