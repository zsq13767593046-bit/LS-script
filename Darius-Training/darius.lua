-- Offline calculations for Summoner's Rift, patch 26.23.
local patch = "26.23"
local qBase = {50, 80, 110, 140, 170}
local qRatio = {1, 1.10, 1.20, 1.30, 1.40}
local qCooldown = {9, 7.75, 6.5, 5.25, 4}
local qMana = {25, 30, 35, 40, 45}
local wRatio = {1.40, 1.45, 1.50, 1.55, 1.60}
local ePen = {0.20, 0.25, 0.30, 0.35, 0.40}
local eCooldown = {26, 23.5, 21, 18.5, 16}
local eMana = {70, 60, 50, 40, 30}
local rBase = {125, 250, 375}
local rCooldown = {120, 100, 80}
local rMana = {100, 100, 0}

local function showHelp()
    print("Darius offline calculator | Summoner's Rift " .. patch)
    print([=[
Usage:
  lua darius.lua stats <level>
  lua darius.lua p <level> <bonusAD> <stacks> [champion|monster]
  lua darius.lua q <rank> <totalAD> <missingHP> <bladeHits>
  lua darius.lua w <rank> <totalAD>
  lua darius.lua e <rank> <targetArmor>
  lua darius.lua r <rank> <bonusAD> [stacks [targetHP [shield]]]

Leave R stacks blank to compare all six stack counts.
For Q healing, count only champions and large monsters hit by the blade.
Use bonus AD at the moment being modeled, including Noxian Might if active.
]=])
end

local function readNumber(args, index, name, minimum, maximum, integral)
    local value = tonumber(args[index])
    if not value or value ~= value or value == math.huge or value == -math.huge
        or value < minimum or value > maximum or (integral and value % 1 ~= 0) then
        error("Invalid " .. name .. ": " .. tostring(args[index]), 0)
    end
    return value
end

-- Include ample headroom for hypothetical scenarios and reject outlier input.
local maxInput = 1000000

local function readRank(args, maximum)
    return readNumber(args, 2, "skill rank (1-" .. maximum .. ")", 1, maximum, true)
end

local function readLevel(args)
    return readNumber(args, 2, "champion level (1-18)", 1, 18, true)
end

local function readStacks(args, index)
    return readNumber(args, index, "Hemorrhage stacks (0-5)", 0, 5, true)
end

local function showStats(args)
    local level = readLevel(args)
    local growth = (level - 1) * (0.685 + 0.0175 * level)

    print(("Darius level %d | base stats before items, runes and buffs"):format(level))
    print(("HP %.2f | Mana %.2f | AD %.2f"):format(
        652 + 114 * growth, 263 + 58 * growth, 64 + 5 * growth))
    print(("Armor %.2f | MR %.2f"):format(37 + 5.2 * growth, 32 + 2.05 * growth))
    print(("HP/5 %.2f | Mana/5 %.2f | Attacks/s %.4f"):format(
        10 + 0.95 * growth, 6.6 + 0.35 * growth, 0.625 * (1 + 0.01 * growth)))
    print("Move speed 340 | Attack range 175 | Crit chance 0%")
end

local function noxianMight(level)
    local earlyLevels = math.min(level - 1, 9)
    local middleLevels = math.min(math.max(level - 10, 0), 3)
    local lateLevels = math.max(level - 13, 0)
    return 30 + earlyLevels * 5 + middleLevels * 10 + lateLevels * 25
end

local function showPassive(args)
    local level = readLevel(args)
    local bonusAD = readNumber(args, 3, "bonus AD", 0, maxInput)
    local stacks = readStacks(args, 4)
    local target = args[5] or "champion"
    if target ~= "champion" and target ~= "monster" then
        error("Target must be champion or monster.", 0)
    end

    local multiplier = target == "monster" and 2.5 or 1
    local damage = (12 + level + 0.30 * bonusAD) * stacks * multiplier
    print(("P | %d stacks vs %s | full-duration raw physical damage %.2f"):format(
        stacks, target, damage))
    print(("Noxian Might at level %d grants +%d AD when active."):format(
        level, noxianMight(level)))
end

local function showQ(args)
    local rank = readRank(args, 5)
    local totalAD = readNumber(args, 3, "total AD", 0, maxInput)
    local missingHP = readNumber(args, 4, "missing HP", 0, maxInput)
    local hits = readNumber(args, 5, "eligible blade hits", 0, maxInput, true)
    local bladeDamage = qBase[rank] + qRatio[rank] * totalAD
    local healRate = 0.17 * math.min(hits, 3)

    print(("Q rank %d | Blade %.2f | Handle %.2f (raw physical damage)"):format(
        rank, bladeDamage, bladeDamage * 0.35))
    print(("Healing %.2f (%d%% of missing HP) | CD %.2fs | Mana %d"):format(
        missingHP * healRate, math.min(hits, 3) * 17, qCooldown[rank], qMana[rank]))
end

local function showW(args)
    local rank = readRank(args, 5)
    local totalAD = readNumber(args, 3, "total AD", 0, maxInput)
    print(("W rank %d | Empowered attack %.2f physical, before armor and crit"):format(
        rank, wRatio[rank] * totalAD))
    print("90% slow for 1s | CD 5s | Mana 40")
end

local function showE(args)
    local rank = readRank(args, 5)
    local armor = readNumber(args, 3, "target armor", 0, maxInput)
    local effectiveArmor = armor * (1 - ePen[rank])
    local damageMultiplier = 100 / (100 + effectiveArmor)
    print(("E rank %d | Armor penetration %.0f%% | Effective armor %.2f"):format(
        rank, ePen[rank] * 100, effectiveArmor))
    print(("Physical damage retained %.2f%% | CD %.2fs | Mana %d"):format(
        damageMultiplier * 100, eCooldown[rank], eMana[rank]))
end

local function showR(args)
    local rank = readRank(args, 3)
    local bonusAD = readNumber(args, 3, "bonus AD", 0, maxInput)
    local stacks = args[4] and readStacks(args, 4)
    local health = args[5] and readNumber(args, 5, "target HP", 0, maxInput)
    local shield = args[6] and readNumber(args, 6, "applicable shield", 0, maxInput) or 0
    local baseDamage = rBase[rank] + 0.75 * bonusAD

    print(("R rank %d | CD %ds | Mana %d"):format(rank, rCooldown[rank], rMana[rank]))
    for count = stacks or 0, stacks or 5 do
        local damage = baseDamage * (1 + 0.20 * count)
        print(("%d stacks | %.2f true damage"):format(count, damage))
        if health then
            local margin = damage - health - shield
            print(("  Damage minus HP and applicable shield: %+.2f"):format(margin))
        end
    end
end

local commands = {
    stats = {run = showStats, min = 2, max = 2},
    p = {run = showPassive, min = 4, max = 5},
    q = {run = showQ, min = 5, max = 5},
    w = {run = showW, min = 3, max = 3},
    e = {run = showE, min = 3, max = 3},
    r = {run = showR, min = 3, max = 6},
}

local function main(args)
    local name = args[1]
    if not name or name == "help" or name == "--help" or name == "-h" then
        showHelp()
        return
    end

    local command = commands[name]
    if not command or #args < command.min or #args > command.max then
        error("Unknown command or wrong argument count. Run with --help.", 0)
    end
    command.run(args)
end

local ok, message = pcall(main, arg)
if not ok then
    io.stderr:write(tostring(message), "\n")
    os.exit(1)
end
