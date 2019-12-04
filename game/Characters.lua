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
    self.n1Sprite = self.sprites[N_A]
    self.n2Sprite = self.sprites[N_B]
    self.n3Sprite = self.sprites[N_C]
    self.bad1Sprite = self.sprites[BAD_A]
    self.bad2Sprite = self.sprites[BAD_B]

    self.n1x = map.tileWidth * 30 * 3
    self.n2x = map.tileWidth * 30 * 7
    self.n3x = map.tileWidth * 30 * 5
    self.bad1x = map.tileWidth * 30 * 4
    self.bad2x = map.tileWidth * 30 * 6
    self.spyx =map.tileWidth * 30 * 2
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

function Characters:render()
    love.graphics.draw(self.spritesheet, self.spySprite, self.spyx, self.y)
    love.graphics.draw(self.spritesheet, self.n1Sprite, self.n1x, self.y)
    love.graphics.draw(self.spritesheet, self.n2Sprite, self.n2x, self.y)
    love.graphics.draw(self.spritesheet, self.n3Sprite, self.n3x, self.y)
    love.graphics.draw(self.spritesheet, self.bad1Sprite, self.bad1x, self.y)
    love.graphics.draw(self.spritesheet, self.bad2Sprite, self.bad2x, self.y)
end