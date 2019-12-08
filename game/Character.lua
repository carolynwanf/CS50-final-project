Character = Class{}

SPY = 11
NEUTRAL_A = 5 -- neutral character a
NEUTRAL_B = 7 -- neutral character b, etc
NEUTRAL_C = 9
BAD_A = 1
BAD_B = 3


function Character:init(x, spriteID, dialogueOptions)

    -- initiate all character variables for one character
    self.spritesheet = love.graphics.newImage('graphics/npcs.png')
    self.sprites = generateQuads(self.spritesheet, 16, 20)
    self.dialogue_Options = dialogueOptions
    self.sprite = self.sprites[spriteID]
    self.x = x
    
    -- initiate speech bubble variables
    self.bubTexture = love.graphics.newImage('graphics/bub.png')
    self.speechBubble = false
end

function Character:render()

    if map.screen >= map.titleLen then

        if map.characters[map.screen + 1 - map.titleLen].speechBubble == true then
            -- draw speech bubble image next to character
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.draw(self.bubTexture, map.characters[map.screen + 1 - map.titleLen].x - 160, 120)
            love.graphics.setColor(0,0,0,255)
            -- print their dialogue
            love.graphics.print(map.characters[map.screen + 1 - map.titleLen].dialogue_Options[map.dialogue_number], map.characters[map.screen + 1 - map.titleLen].x - 80, 135)
            love.graphics.setColor(1,1,1,1)
        else
        end
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.spritesheet, self.sprite, self.x, 188)
end