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

    self.sprite = self.sprites[spriteID]
    self.x = x
    self.dialogue = dialogueOptions[1]


    self.npcWidth = 16
    self.npcHeight = 20
    self.npcs = {}
end

function Character:displayDialogue()
    self.speechBubble = true
end

function Character:update(dt)
    -- find some way to determine when to disable speech bubble
    self.speechBubble = false
end

function Character:render()

    if self.speechBubble then
        -- draw speech bubble image next to character
        love.graphics.draw(self.bubTexture, self.x - 100, 90)
    end
    
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self.bubTexture, self.x - 160, 120)
    love.graphics.draw(self.spritesheet, self.sprite, self.x, 188)
    love.graphics.setColor(0,0,0,255)
    love.graphics.print(self.dialogue, self.x - 80, 135)
    
end