require 'Util'

Map = Class{}

-- ID for tiles in sprite sheet
TILE_MIDGROUND = 2
TILE_TOPSOIL = 1
TILE_EMPTY = -1

MAGMA_LEFT = 3
MAGMA_MIDDLE = 4
MAGMA_RIGHT = 5

CLOUD_LEFT = 6
CLOUD_RIGHT = 7

PINK_SHROOM = 8

PLATFORM_LEFT = 9
PLATFORM_MIDDLE = 10
PLATFORM_RIGHT = 11

MUSHROOM_1 = 13
MUSHROOM_2 = 14
MUSHROOM_3 = 17
MUSHROOM_4 = 18

-- map scrolling speed, multiplied by dt
local SCROLL_SPEED = 62

-- constructor for map object
function Map:init()

     -- initialize endgame variables
    self.characterCount = 6
    self.killCount = 3
    self.sum = 0
    self.savePercentage = 0
    self.finalScore = false

    -- initialize spritesheet
    self.spritesheet = love.graphics.newImage('graphics/map.png')
    self.sprites = generateQuads(self.spritesheet, 16, 16)

    -- initialize music
    -- music from https://opengameart.org/content/the-adventure-begins-8-bit-remix
    self.music = love.audio.newSource('sounds/music.ogg', 'static')

    -- initialize tile and map dimensions
    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 300
    self.mapHeight = 28
    self.tiles = {}
    
    -- map width in pixels
    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight

    -- dialogue variable
    self.dialogue_Finished = false
    self.dialogue_number = 1
    self.max_dialogue = 4

    -- print instructions variable
    self.printInstructions = false

    -- option to kill or dodge npc
    self.canKill = true
    self.canDodge = true

    -- status of npcs, 0 is alive and 1 is dead
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
    self.titleLen = 2

    -- npc character array with (x coordinate, name of npc, dialogue array)
    self.characters = {
        Character(VIRTUAL_WIDTH * (1 + self.titleLen) - 100, SPY, {
            'WHO ARE YOU?!', 'you must stop here', "if you don't stop i'm telling",
             "hey hey no"
        }),
        Character(VIRTUAL_WIDTH * (2 + self.titleLen) - 100, NEUTRAL_A, {
            'come by!', 'Have cereal', 'and eggs too!', 'I am becoming you'
        }),
        Character(VIRTUAL_WIDTH * (3 + self.titleLen) - 100, BAD_A, {
            'i have four lines?', 'wait what', 'now i have two?', 'wait no'
        }),
        Character(VIRTUAL_WIDTH * (4 + self.titleLen) - 100, NEUTRAL_C, {
            'HEY STINKY', 'look at my dancing', 'shoot my phone died', 'call you later?'
        }),
        Character(VIRTUAL_WIDTH * (5 + self.titleLen) - 100, BAD_B, {
            'excuse me?', 'do you have lice', 'no?', 'okay :('
        }),
        Character(VIRTUAL_WIDTH * (6 + self.titleLen) - 100, NEUTRAL_B, {
            'HEY PUNK', 'wanna go to berg?', 'i think you do!', 'lets go'
        })
    }

    -- fill map with empty tiles
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
        
        -- 1/c change to generate clouds
        if x < self.mapWidth - 2 and x > 84 then
            if math.random(3) == 1 then
                
                -- choose a random vertical spot above where blocks generate
                local cloudStart = math.random(self.mapHeight / 2 - 6)

                self:setTile(x, cloudStart, CLOUD_LEFT)
                self:setTile(x + 1, cloudStart, CLOUD_RIGHT)
            end
        end

        -- 1/7 chance of generating a magma puddle, can be same column as cloud
        -- make sure we're 3 tiles from edge, not within the expository screens, and not within a character
        if x < self.mapWidth - 3 and x > 84 and x ~= self.characters[self.screen + 1].x and x ~= self.characters[self.screen + 1].x - 1 and x ~= self.characters[self.screen + 1].x - 2 then
            if math.random(6) == 1 then

                -- prints a magma pit
                self:setTile(x, self.mapHeight / 2, MAGMA_LEFT)
                self:setTile(x + 1, self.mapHeight / 2, MAGMA_MIDDLE)
                self:setTile(x + 2, self.mapHeight / 2, MAGMA_RIGHT)

                -- prints a platform above a magma pit
                local RISE = math.random(3,6)
                self:setTile(x, self.mapHeight / 2 - RISE, PLATFORM_LEFT)
                self:setTile(x + 1, self.mapHeight / 2 - RISE, PLATFORM_MIDDLE)
                self:setTile(x + 2, self.mapHeight / 2 - RISE, PLATFORM_RIGHT)

                if RISE == 5 or RISE == 6 then
                    self:setTile(x - 3, self.mapHeight / 2 - 3, PLATFORM_LEFT)
                    self:setTile(x - 2, self.mapHeight / 2 - 3, PLATFORM_MIDDLE)
                    self:setTile(x - 1, self.mapHeight / 2 - 3, PLATFORM_RIGHT)
                end
                --mushroom on top of platform
                if math.random(2) == 1 then
                    local DIST = math.random(0,2)
                    self:setTile(x + DIST, self.mapHeight / 2 - RISE - 1, PINK_SHROOM)
                end


            end

            -- increment x so magma puddle does not overlap
            x = x + 3
            
        end

        if x < self.mapWidth - 3 and x > 84 then
            if math.random(5) == 1 then
                self:setTile(x, self.mapHeight / 2 - 2, MUSHROOM_1)
                self:setTile(x + 1, self.mapHeight / 2 - 2, MUSHROOM_2)
                self:setTile(x, self.mapHeight / 2 - 1, MUSHROOM_3)
                self:setTile(x + 1, self.mapHeight / 2 - 1, MUSHROOM_4)
            end
        end

        -- increment x so mushroom does not overlap
        x = x + 3
    end


    -- start the background music
    self.music:setLooping(true)
    self.music:play()
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

-- checks if tile is magma tile
function Map:onFire(tile)
    local fireables = {
        MAGMA_LEFT, MAGMA_MIDDLE, MAGMA_RIGHT
    }
    -- iterate and return true if our tile type matches
    for _, v in ipairs(fireables) do
        if tile.id == v then
            return true
        end
    end

    return false
end

-- returns if player is in range of an npc, resets the dialogue_finished variable to false when player passes npc
function Map:inRange()
    if map.screen >= self.titleLen then
        if self.player.x >= self.characters[self.screen + 1 - self.titleLen].x - 48 and self.player.x <= self.characters[self.screen + 1 - self.titleLen].x then
            return true
        elseif self.player.x < self.screen * VIRTUAL_WIDTH + 40 then
            self.dialogue_Finished = false
            return false
        else
            return false
        end
    else
        return false
    end
end

-- function to update camera offset with delta time + change screen bounds
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
        self.characters[self.screen + 1 - self.titleLen].speechBubble = true
        self.player.state = 'dialogue'
    elseif self.screen >= self.titleLen then
        self.characters[self.screen + 1 - self.titleLen].speechBubble = false
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
    
    -- keep camera's X coordinate following the player, preventing camera from
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


-- determines percentage of prisoners saved based on which npcs were killed
function Map:endGame()

    -- tally up product of character status and worth
    self.sum = 0
    for i = 1, 6 do
        self.sum = self.sum + self.character_status[i] * self.character_worth[i]
    end

    -- calculate percentage of saved from sum, look at formula sheet on google drive
    if self.sum == 22 then -- BBN
        self.savePercentage = 100
    elseif self.sum == 21 then -- BBS
        self.savePercentage = 21
    elseif self.sum == 14 then -- BNN
        self.savePercentage = 76
    elseif self.sum == 13 then -- BNS
        self.savePercentage = 16
    elseif self.sum == 6 then -- NNN
        self.savePercentage = 52
    else if self.sum == 5 then -- NNS
        self.savePercentage = 1
    
    -- RANDOM PERCENTAGE to throw off player 
    else 
        self.savePercentage = math.random(100)
    end

end
end


-- renders our map to the screen, to be called by main's render
function Map:render()

    self.player:render()

    -- fill the map with the background tile
    for y = 1, self.mapHeight do
        for x = 1, self.mapWidth do
            local tile = self:getTile(x, y)
            if tile ~= TILE_EMPTY then
                love.graphics.draw(self.spritesheet, self.sprites[tile],
                    (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
            end
        end
    end

    -- render each charactesr
    for key, character in ipairs(self.characters) do
        if self.character_status[key] == 1 then 
            character:deadRender()
        else
            character:render()
        end
    end    
    
    -- print prisoner saved percentage and kill count if past title screen
    if self.screen > 1 then

        love.graphics.setColor(1,1,1,255)
        love.graphics.setFont(speechFont)
        -- print big for last screen
        if not self.finalScore then
            love.graphics.print('PRISONERS SAVED: '.. self.savePercentage .. '%', self.camX + 245, 25)
        else
            love.graphics.setFont(headerFont)
            love.graphics.print('PRISONERS SAVED: '.. self.savePercentage .. '%', self.camX + 160, 25)
            love.graphics.setFont(speechFont)
        end
        
        love.graphics.print("Characters left: ".. self.characterCount, self.camX + 5, 5)

        if map.killCount > 0 then
            love.graphics.print("Kills left: ".. self.killCount, self.camX + 5, 15)
        else
            love.graphics.print("NO KILLS LEFT", self.camX + 5, 15)
        end
        -- reset colour to black
        love.graphics.setColor(1,1,1,1)
    end

    

    -- print title on screen 0
    love.graphics.setFont(titleFont)
    love.graphics.setColor(1,1,1,255)
    love.graphics.print("UNDERTONE", VIRTUAL_WIDTH / 2 - 235, 80)
    love.graphics.setColor(1,1,1,1)

    -- print backstory on screen 1
    love.graphics.setFont(instructionsFont)
    love.graphics.setColor(1,1,1,255)
    love.graphics.print("you are a government agent that has been transported to an", 1.5 * VIRTUAL_WIDTH, 60)
    love.graphics.print("alien planet where many of your fellow earthlings are being", 1.5 * VIRTUAL_WIDTH, 70) 
    love.graphics.print("held hostage. your partner has been stranded on this planet", 1.5 * VIRTUAL_WIDTH, 80)  
    love.graphics.print("for the past three months and has been forced to blend in.", 1.5 * VIRTUAL_WIDTH, 90)
    love.graphics.print("to save these hostages from the clutches of the hostile race", 1.5 * VIRTUAL_WIDTH, 100)  
    love.graphics.print("of block men, you must talk to six characters and determine", 1.5 * VIRTUAL_WIDTH, 110)
    love.graphics.print("which ones are evil, which ones are civilians, and which one", 1.5 * VIRTUAL_WIDTH, 120) 
    love.graphics.print("is your partner. kill three characters, spare your partner.", 1.5 * VIRTUAL_WIDTH, 130)
    love.graphics.print("the fate of the hostages rests in your hands. good luck, agent", 1.5 * VIRTUAL_WIDTH, 140)
    love.graphics.setColor(1,1,1,1)

    
    -- print error message
    if love.keyboard.isDown('k') and self.dialogue_number >= self.max_dialogue and not self.canKill then
        love.graphics.print("you already killed 3!", self.camX + 440, 5)
    elseif love.keyboard.isDown('d') and map.dialogue_number >= map.max_dialogue and not map.canDodge then
        love.graphics.print("you must kill 3 characters", self.camX + 400, 15)
    end        

    -- print instructions for kill or dodge
    if self.printInstructions == true then
        love.graphics.print("Press k to kill or d to dodge", self.camX + 200, 50)
    end

end