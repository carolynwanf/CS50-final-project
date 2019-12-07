Character = Class{}

SPY = 11
NEUTRAL_A = 5 -- neutral character a
NEUTRAL_B = 7 -- neutral character b, etc
NEUTRAL_C = 9
BAD_A = 1
BAD_B = 3


function Character:init(x, spriteID, dialogueOptions)
    -- TODO generate all characters in the map
    self.spritesheet = love.graphics.newImage('graphics/npcs.png')
    self.sprites = generateQuads(self.spritesheet, 16, 20)

    self.bubTexture = love.graphics.newImage('graphics/bub.png')

    self.dialogue_Options = dialogueOptions

    self.sprite = self.sprites[spriteID]
    self.x = x


    self.npcWidth = 16
    self.npcHeight = 20
    self.npcs = {}
    
    self.speechBubble = false
end

-- function Character:displayDialogue()
--    self.speechBubble = true
-- end

-- function Character:stopDialogue()
--     self.speechBubble = false
--     print('stopped')
-- end


-- function Character:update(dt)
--     -- find some way to determine when to disable speech bubble
--     if then
        
--     end
-- end

function Character:render()


    if map.characters[map.screen + 1].speechBubble == true then
        -- draw speech bubble image next to character
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(self.bubTexture, map.characters[map.screen + 1].x - 160, 120)
        love.graphics.setColor(0,0,0,255)
        -- print(map.characters[map.screen + 1].dialogue_Options[map.dialogue_number])
        love.graphics.print(map.characters[map.screen + 1].dialogue_Options[map.dialogue_number], map.characters[map.screen + 1].x - 80, 135)
        love.graphics.setColor(1,1,1,1)
    else
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.spritesheet, self.sprite, self.x, 188)
end