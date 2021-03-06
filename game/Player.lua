--[[
    Represents our player in the game, with its own sprite.
]]

Player = Class{}

local WALKING_SPEED = 140
local JUMP_VELOCITY = 400

function Player:init(map)
    
    self.x = 0
    self.y = 0
    self.width = 16
    self.height = 20

    -- offset from top left to center to support sprite flipping
    self.xOffset = 8
    self.yOffset = 10

    -- reference to map for checking tiles
    self.map = map
    self.texture = love.graphics.newImage('graphics/player.png')

    -- sound effects
    self.sounds = {
        ['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
        ['sizzle'] = love.audio.newSource('sounds/sizzle.wav', 'static'),
        ['death'] = love.audio.newSource('sounds/death.wav', 'static')
    }

    -- animation frames
    self.frames = {}

    -- current animation frame
    self.currentFrame = nil

    -- used to determine behavior and animations
    self.state = 'idle'

    -- determines sprite flipping
    self.direction = 'left'

    -- x and y velocity
    self.dx = 0
    self.dy = 0

    -- position on top of map tiles
    self.y = map.tileHeight * ((map.mapHeight - 2) / 2) - self.height
    self.x = map.tileWidth * 10

    -- initialize all player animations
    self.animations = {
        ['idle'] = Animation({
            texture = self.texture,
            frames = {
                love.graphics.newQuad(0, 0, 16, 20, self.texture:getDimensions())
            }
        }),
        ['walking'] = Animation({
            texture = self.texture,
            frames = {
                love.graphics.newQuad(128, 0, 16, 20, self.texture:getDimensions()),
                love.graphics.newQuad(144, 0, 16, 20, self.texture:getDimensions()),
                love.graphics.newQuad(160, 0, 16, 20, self.texture:getDimensions()),
                love.graphics.newQuad(144, 0, 16, 20, self.texture:getDimensions()),
            },
            interval = 0.15
        }),
        ['jumping'] = Animation({
            texture = self.texture,
            frames = {
                love.graphics.newQuad(32, 0, 16, 20, self.texture:getDimensions())
            }
        }),
        ['fire'] = Animation({
            tecture = self.texture,
            frames = {
                love.graphics.newQuad(64, 0, 16, 20, self.texture:getDimensions())
            }
        })
    }

    -- initialize animation and current frame we should render
    self.animation = self.animations['idle']
    self.currentFrame = self.animation:getCurrentFrame()

    -- behavior map we can call based on player state
    self.behaviors = {
        -- first-class functions, functions that can be treated like data
        ['idle'] = function(dt)
            
            -- add spacebar functionality to trigger jump state
            if love.keyboard.wasPressed('space') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('left') then
                self.direction = 'left'
                self.dx = -WALKING_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
            elseif love.keyboard.isDown('right') then
                self.direction = 'right'
                self.dx = WALKING_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
            else
                self.dx = 0
            end

             -- check if there's a tile directly beneath us
            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
             
                -- if so, reset velocity and position and change state
                self.state = 'jumping'
                self.animation = self.animations['jumping']
            end
            -- checks to see if tile under player is magma tile, switches to on fire animation
            if self.map:onFire(self.map:tileAt(self.x, self.y + self.height)) then
                
                self.state = 'fire'
                self.animation = self.animations['fire']
                self.sounds['sizzle']:play()
            end
        end,
        ['walking'] = function(dt)
            
            -- keep track of input to switch movement while walking, or reset
            -- to idle if we're not moving
            if love.keyboard.wasPressed('space') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('left') then
                self.direction = 'left'
                self.dx = -WALKING_SPEED
            elseif love.keyboard.isDown('right') then
                self.direction = 'right'
                self.dx = WALKING_SPEED
            else
                self.dx = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
            end

            -- check for collisions moving left and right
            self:checkRightCollision()
            self:checkLeftCollision()

            -- check if there's a tile directly beneath us
            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
                
                -- if so, reset velocity and position and change state
                self.state = 'jumping'
                self.animation = self.animations['jumping']
            end

            -- checks to see if tile under player is magma tile, switches to on fire animation
            if self.map:onFire(self.map:tileAt(self.x, self.y + self.height)) then
                
                self.state = 'fire'
                self.animation = self.animations['fire']
                self.sounds['sizzle']:play()
            end
        end,
        ['jumping'] = function(dt)
            -- break if we go below the surface
            if self.y > 300 then -- used to be 300, adjust for half of screen
                return
            end

            if love.keyboard.isDown('left') then
                self.direction = 'left'
                self.dx = -WALKING_SPEED
            elseif love.keyboard.isDown('right') then
                self.direction = 'right'
                self.dx = WALKING_SPEED
            else
                self.dx = 0
            end

            -- apply map's gravity before y velocity
            self.dy = self.dy + self.map.gravity

            -- check if there's a tile directly beneath us
            if self.map:collides(self.map:tileAt(self.x, self.y + self.height)) or
                self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
                
                -- if so, reset velocity and position and change state
                self.dy = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
                self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
            end


            -- check for collisions moving left and right
            self:checkRightCollision()
            self:checkLeftCollision()
        end,

        ['fire'] = function(dt)
           -- keep track of input to switch movement while walking, or reset
            -- to idle if we're not moving
            if love.keyboard.wasPressed('space') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('left') and 
                self.map:onFire(self.map:tileAt(self.x, self.y + self.height)) then
                
                self.state = 'walking'
                self.direction = 'left'
                self.animation = self.animations['walking']
                self.dx = -WALKING_SPEED

            elseif love.keyboard.isDown('right') and 
                self.map:onFire(self.map:tileAt(self.x, self.y + self.height)) then

                self.state = 'walking'
                self.direction = 'right'
                self.animation = self.animations['walking']
                self.dx = WALKING_SPEED
            else
                self.dx = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
            end

            -- check for collisions moving left and right
            self:checkRightCollision()
            self:checkLeftCollision()

             -- check if there's a tile directly beneath us
            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
             not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
             
                -- if so, reset velocity and position and change state
                self.state = 'jumping'
                self.animation = self.animations['jumping']
            end

            -- checks to see if tile under player is magma tile, if it is switches to on fire animation, if not, idle
            if self.map:onFire(self.map:tileAt(self.x, self.y + self.height)) == false then
                
                self.state = 'idle'
                self.animation = self.animations['idle']
            elseif self.map:onFire(self.map:tileAt(self.x, self.y + self.height)) then
                self.sounds['sizzle']:play()
                self.state = 'fire'
                self.animation = self.animations['fire']
            end
        end, 
                
                    


        ['dialogue'] = function(dt)
        
            self.dx = 0
            self.dy = 100

            -- check if tile under
            if self.map:collides(self.map:tileAt(self.x, self.y + self.height)) or
                self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
                
                -- if so, reset velocity and position 
                self.dy = 0
                self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
            end
            self.animation = self.animations['idle']

            -- click through dialogue
            if love.keyboard.wasPressed('return') then
               if map.dialogue_number < map.max_dialogue then -- 4 is the number of dialogues
                    map.dialogue_number = map.dialogue_number + 1
               else
                map.printInstructions = true
                end
            
            -- if the player presses k or d then we finish the dialogue
            elseif love.keyboard.isDown('k') and map.dialogue_number >= map.max_dialogue and map.canKill then
                --play kill sound
                self.sounds['death']:play()
                -- decrement character count
                map.characterCount = map.characterCount - 1
                -- decrement kill count
                map.killCount = map.killCount - 1
                -- turn the status from alive (0) to dead (1)
                map.character_status[map.screen + 1 - map.titleLen] = 1
                -- finish dialogue state
                map.dialogue_Finished = true
                -- reset dialogue number to 1 for next character
                map.dialogue_number = 1
                -- back to idle state, allow player to move
                self.state = 'idle'
                -- turn off instructions
                map.printInstructions = false
                -- update saved percentage
                map:endGame()

                -- display final score if last character
                if map.screen >= 7 then
                    map.finalScore = true
                end

            -- same but for dodge
            elseif love.keyboard.isDown('d') and map.dialogue_number >= map.max_dialogue and map.canDodge then
                map.characterCount = map.characterCount - 1
                map.dialogue_Finished = true
                map.dialogue_number = 1
                self.state = 'idle'
                map.printInstructions = false
                map:endGame()
                
                if map.screen >= 7 then
                    map.finalScore = true
                end

            end
        end

    }
end


function Player:update(dt)

    -- can call it and pass in delta time like it's a function because keys 'idle' etc return a function
    self.behaviors[self.state](dt)
    self.animation:update(dt)
    self.currentFrame = self.animation:getCurrentFrame()
    self.x = self.x + self.dx * dt
    self:calculateJumps()

    -- apply velocity
    self.y = self.y + self.dy * dt
end

-- jumping and block hitting logic
function Player:calculateJumps()
    
    -- if we have negative y velocity (jumping), check if we collide with any blocks above us
    if self.dy < 0 then
        if self.map:collides(self.map:tileAt(self.x, self.y)) or
            self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y))then
            -- reset y velocity
            self.dy = 0
        end
    end
end
 


-- checks two tiles to our left to see if a collision occurred
function Player:checkLeftCollision()
    
    if self.dx < 0 then
        -- check if there's a tile directly beneath us
        if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or
            self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) then
            
            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
        end
    end
end

-- checks two tiles to our right to see if a collision occurred
function Player:checkRightCollision() 
    
    if self.dx > 0 then
        -- check if there's a tile directly beneath us
        if self.map:collides(self.map:tileAt(self.x + self.width, self.y)) or
            self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then
            
            -- if so, reset velocity and position and change state
            self.dx = 0
            self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width
        end
    end
end

-- function Player:checkDeath()
--     if self.dx > 0 then
--         if self.map:deathCollide(self.map:tileAt(self.x, self.y)) or 
--             self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) or
--             self.map:collides(self.map:tileAt(self.x - 1, self.y)) or
--             self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) then
                
--             return true
--         end
--     end
--     return false
-- end


function Player:render()
    local scaleX

    -- set negative x scale factor if facing left, which will flip the sprite
    -- when applied
    if self.direction == 'right' then
        scaleX = 1
    else
        scaleX = -1
    end

    -- draw sprite with scale factor and offsets
    -- offsets make it so that sprite doesn't flip in relation to the top left corner, flips in relation to center instead
    love.graphics.draw(self.texture, self.currentFrame, math.floor(self.x + self.xOffset),
        math.floor(self.y + self.yOffset), 0, scaleX, 1, self.xOffset, self.yOffset)
end
