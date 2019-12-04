Characters = Class{}

SPY = 11
N_A = 5 -- neutral character a
N_B = 7 -- neutral character b, etc
N_C = 9
BAD_A = 1
BAD_B = 3

function Characters:init(map)
    -- TODO generate all characters in the map
    self.spritesheet = love.graphics.newImage('graphics/npcs.png')
    self.sprites = generateQuads(self.spritesheet, 16, 20)

    self.npcWidth = 16
    self.npcHeight = 20
    self.npcs = {}

    self.y = map.tileHeight * ((map.mapHeight - 2) / 2) - self.npcHeight

    self.spySprite = self.sprites[SPY] -- label the quads
   
    self.spyx = map.tileWidth * 18
end

function Characters:render()
    love.graphics.draw(self.spritesheet, self.spySprite, self.spyx, self.y)
   end

function Characters:inRange(tile)
    -- define NPC tiles
    local collidables = {
        SPY, N_A, N_B, N_C, BAD_A, BAD_B
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

    
        