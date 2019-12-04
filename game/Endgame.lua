Endgame = Class{}

function Endgame:init()
    self.characterCount = 6
    self.killCount = 3
    self.sum = 0
end

function Endgame:savecount()
    self.sum = characters.spyCount +
    characters.neutralCount * 2 +
    characters.badCount * 10

    if self.sum == 22 then -- BBN
        return 100 -- percentage saved
    elseif self.sum == 21 then -- BBS
        return 20
    elseif self.sum == 14 then -- BNN
        return 70
    elseif self.sum == 13 then -- BNS
        return 10
    elseif self.sum == 6 then -- NNN
        return 50
    else if self.sum == 5 then -- NNS
        return 0
    else -- WRONG
        return 6969
    end
    
    end
end


