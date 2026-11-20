local player = Game.localPlayer

local function IsDarius()
    if not player then
        return false
    end
    if player.charName == "Darius" then
        return true
    end
    if Game.HashStringSDBM then
        local ok, hash = pcall(Game.HashStringSDBM, "Darius")
        return ok and hash == player.hash
    end
    return false
end

if IsDarius() then
    Environment.LoadModule("darius")
end