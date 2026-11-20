local player = Game.localPlayer

local function IsZaahen()
    if not player then
        return false
    end
    if player.charName == "Zaahen" then
        return true
    end
    if Game.HashStringSDBM then
        local ok, hash = pcall(Game.HashStringSDBM, "Zaahen")
        return ok and hash == player.hash
    end
    return false
end

if IsZaahen() then
    Environment.LoadModule("zaahen")
end