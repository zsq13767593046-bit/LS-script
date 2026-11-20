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

if not IsZaahen() then
    return
end

Champions.CppScriptMaster(false)

Champions.Q = SDKSpell.Create(SpellSlot.Q, 200, DamageType.Physical)
Champions.W = SDKSpell.Create(SpellSlot.W, 850, DamageType.Physical)
Champions.E = SDKSpell.Create(SpellSlot.E, 350, DamageType.Physical)
Champions.R = SDKSpell.Create(SpellSlot.R, 600, DamageType.Physical)

Champions.W:SetSkillshot(0.5, 70, 2900, SkillshotType.SkillshotLine, true, CollisionFlag.CollidesWithYasuoWall, HitChance.High, true)

local Q = Champions.Q
local W = Champions.W
local E = Champions.E
local R = Champions.R

local Q1_BASE = { 15, 30, 45, 60, 75 }
local Q2_BASE = { 30, 60, 90, 120, 150 }
local Q_COEFF = { 0.20, 0.25, 0.30, 0.35, 0.40 }
local Q_MONSTER_MULT = 2.0
local W1_BASE = { 40, 60, 80, 100, 120 }
local W2_BASE = { 30, 50, 70, 90, 110 }
local W1_COEFF = 0.50
local W2_COEFF = 0.30
local E_BASE = { 40, 60, 80, 100, 120 }
local E_COEFF = 0.50
local E_MIN_RADIUS = 200
local E_MAX_RADIUS = 375
local E_DASH = 350
local E_OUTER_MULT = 1.5
local E_HP_PERCENT = { 0.04, 0.045, 0.05, 0.055, 0.06 }
local E_MONSTER_BONUS = 50
local E_MONSTER_CAP = 400
local R_BASE = { 250, 400, 550 }
local R_COEFF = 2.0
local AA_RANGE = 175
local Q_RANGE_BONUS = 25
local Q2_BUFF = Game.fnvhash("ZaahenQ2")
local PASSIVE_BUFF = Game.fnvhash("ZaahenPassiveBuff")
local PASSIVE_MAX = 12

local menu = UI.Menu.CreateMenu("LSZaahen", "LS Zaahen", 2)
Champions.CreateBaseMenu(menu, 0)

local predictionMenu = menu:AddMenu("prediction", "Prediction")
local wHitchance = predictionMenu:AddList("w_hitchance", "W Hitchance", { "Low", "Medium", "High", "Very High" }, 2)

local comboMenu = menu:AddMenu("combo", "Combo")
local comboQ = comboMenu:AddCheckBox("combo_q", "Use Q in Combo", true)
local comboW = comboMenu:AddCheckBox("combo_w", "Use W in Combo", true)
local comboE = comboMenu:AddCheckBox("combo_e", "Use E in Combo", true)
local comboEAlways = comboMenu:AddCheckBox("combo_e_always", "E Even in Auto Attack Range", false)
local comboEGapClose = comboMenu:AddCheckBox("combo_e_gap", "E to Gap Close", true)
local comboR = comboMenu:AddCheckBox("combo_r", "Use R in Combo", true)
local comboRMode = comboMenu:AddList("combo_r_mode", "R Mode", { "If Killable", "Always", "Target HP <= X%" }, 0)
local comboRHp = comboMenu:AddSlider("combo_r_hp", "R Target HP <= %", 40, 0, 100)
local towerDive = comboMenu:AddKeyBind("toverdive_key", "Tower Dive Key", string.byte("T"), false, true)
towerDive:PermaShow(true, true)

local harassMenu = menu:AddMenu("harass", "Harass")
local harassQ = harassMenu:AddCheckBox("harass_q", "Use Q in Harass", true)
local harassW = harassMenu:AddCheckBox("harass_w", "Use W in Harass", true)
local harassE = harassMenu:AddCheckBox("harass_e", "Use E in Harass", false)

local killstealMenu = menu:AddMenu("killsteal", "Killsteal")
local killstealQ = killstealMenu:AddCheckBox("killsteal_q", "Killsteal with Q", true)
local killstealW = killstealMenu:AddCheckBox("killsteal_w", "Killsteal with W", true)
local killstealE = killstealMenu:AddCheckBox("killsteal_e", "Killsteal with E", false)
local killstealR = killstealMenu:AddCheckBox("killsteal_r", "Killsteal with R", true)

local farmMenu = menu:AddMenu("farm", "Farm")
local farmQ = farmMenu:AddCheckBox("farm_q", "Farm with Q", true)
local farmW = farmMenu:AddCheckBox("farm_w", "Farm with W", true)
local farmWMin = farmMenu:AddSlider("farm_w_min", "W Min Minions", 3, 1, 6)

Champions.CreateColorMenu(menu:AddMenu("draw", "Drawing"), false)

local drawMenu = menu:AddMenu("drawmisc", "Draw Misc")
local drawDamage = drawMenu:AddCheckBox("draw_damage", "Draw Combo Damage", true)
local drawPassive = drawMenu:AddCheckBox("draw_passive", "Draw Passive Stacks", true)
local drawQ2 = drawMenu:AddCheckBox("draw_q2", "Draw Q2 Ready", true)
local drawR = drawMenu:AddCheckBox("draw_r", "Draw R Killable", true)
local drawLine = drawMenu:AddCheckBox("draw_line", "Draw Line to Enemies", false)

local function IsQ2Ready()
    return player:FindBuff(Q2_BUFF) ~= nil
end

local function GetPassiveStacks()
    local stacks = player:GetBuffStacks(PASSIVE_BUFF) or 0
    if stacks < 0 then
        stacks = 0
    elseif stacks > PASSIVE_MAX then
        stacks = PASSIVE_MAX
    end
    return stacks
end

local function GetRealHealth(target, damageType)
    local health = target:GetRealHealth(0, damageType)
    if health == nil then
        health = target.totalHealth + (target.totalShield or 0)
    end
    return health
end

local function GetQExtra(target)
    local rank = Q:Level()
    if rank < 1 then
        return 0
    end
    if rank > 5 then
        rank = 5
    end
    local extra
    if IsQ2Ready() then
        extra = Q2_BASE[rank]
    else
        extra = Q1_BASE[rank]
    end
    extra = extra + Q_COEFF[rank] * player.totalBonusAttackDamage
    if target.isMonster then
        extra = extra * Q_MONSTER_MULT
    end
    return DamageLib.CalculatePhysicalDamage(player, target, extra)
end

local function GetQDamage(target)
    return DamageLib.CalculateAutoAttackDamage(player, target) + GetQExtra(target)
end

local function GetWDamage(target)
    local rank = W:Level()
    if rank < 1 then
        return 0
    end
    if rank > 5 then
        rank = 5
    end
    local raw = W1_BASE[rank] + W2_BASE[rank] + (W1_COEFF + W2_COEFF) * player.totalBonusAttackDamage
    return DamageLib.CalculatePhysicalDamage(player, target, raw)
end

local function GetEInnerRaw(target)
    local rank = E:Level()
    if rank < 1 then
        return 0
    end
    if rank > 5 then
        rank = 5
    end
    local raw = E_BASE[rank] + E_COEFF * player.totalBonusAttackDamage
    if target.isMonster then
        raw = raw + E_MONSTER_BONUS
    end
    return raw
end

local function GetEDamage(target, outer)
    local rank = E:Level()
    if rank < 1 then
        return 0
    end
    if rank > 5 then
        rank = 5
    end
    local raw = GetEInnerRaw(target)
    if not outer then
        return DamageLib.CalculatePhysicalDamage(player, target, raw)
    end
    local physical = DamageLib.CalculatePhysicalDamage(player, target, raw * E_OUTER_MULT)
    local magicRaw = E_HP_PERCENT[rank] * target.totalMaxHealth
    if target.isMonster and magicRaw > E_MONSTER_CAP then
        magicRaw = E_MONSTER_CAP
    end
    return physical + DamageLib.CalculateMagicalDamage(player, target, magicRaw)
end

local function GetRDamage(target)
    local rank = R:Level()
    if rank < 1 then
        return 0
    end
    if rank > 3 then
        rank = 3
    end
    local raw = R_BASE[rank] + R_COEFF * player.totalBonusAttackDamage
    return DamageLib.CalculatePhysicalDamage(player, target, raw)
end

local function GetComboDamage(target)
    local damage = DamageLib.CalculateAutoAttackDamage(player, target)
    if Q:Ready() then
        damage = damage + GetQExtra(target)
    end
    if W:Ready() then
        damage = damage + GetWDamage(target)
    end
    if E:Ready() then
        damage = damage + GetEDamage(target, true)
    end
    if R:Ready() and target:IsValidTarget(R.range) then
        damage = damage + GetRDamage(target)
    end
    return damage
end

local function CanCast(spell)
    if spell:Level() <= 0 or not spell:Ready() then
        return false
    end
    local cost = spell:ManaCost()
    return cost <= 0 or player.mp >= cost
end

local function InAutoAttackRange(target)
    return Orbwalker.IsInAutoAttackRange(player, target, Q_RANGE_BONUS)
end

local function GetECastPosition(target)
    local from = player.serverPosition
    local dx = target.serverPosition.x - from.x
    local dz = target.serverPosition.z - from.z
    local distance = math.sqrt(dx * dx + dz * dz)
    if distance < 1 then
        return target.serverPosition, false, true
    end

    local ux, uz = dx / distance, dz / distance
    if distance >= 50 and distance <= 650 then
        local a = E_DASH
        local b = 300
        local cosAlpha = (distance * distance + a * a - b * b) / (2 * distance * a)
        if cosAlpha > 1 then
            cosAlpha = 1
        elseif cosAlpha < -1 then
            cosAlpha = -1
        end
        local alpha = math.acos(cosAlpha)
        local c, s = math.cos(alpha), math.sin(alpha)
        local rx = ux * c - uz * s
        local rz = ux * s + uz * c
        local position = Math.Vector3(from.x + rx * a, from.y, from.z + rz * a)
        return position, true, true
    end

    if distance > 650 and distance <= 725 then
        return from:Extended(target.serverPosition, E_DASH), true, true
    end

    local dash = math.min(distance, E_DASH)
    local position = from:Extended(target.serverPosition, dash)
    if distance > 725 then
        return position, false, false
    end
    local radius = math.abs(distance - dash)
    return position, radius > E_MIN_RADIUS and radius <= E_MAX_RADIUS, true
end

local function GetRPosition(target)
    local prediction = MovementPrediction.GetPrediction(target, 0.5)
    local position = prediction and prediction.unitPosition or target.serverPosition
    if player.serverPosition:Distance(position) > R.range then
        position = target.serverPosition
    end
    return position
end

local function GetComboTarget()
    local range = math.max(AA_RANGE + Q_RANGE_BONUS, E_DASH + E_MAX_RADIUS)
    if comboW.value then
        range = math.max(range, W.range)
    end
    if comboR.value and CanCast(R) then
        range = math.max(range, R.range)
    end
    return TargetSelector.GetTarget(range, DamageType.Physical, player.serverPosition, true)
end

local function Combo()
    local target = GetComboTarget()
    if not target then
        return
    end
    if not towerDive.value and player.serverPosition:IsUnderEnemyTurret() then
        return
    end

    if comboR.value and CanCast(R) and target:IsValidTarget(R.range) and Champions.ValidUlt(target, 0.5) then
        local mode = comboRMode.value
        local cast = false
        if mode == 0 then
            cast = GetRDamage(target) >= GetRealHealth(target, DamageType.Physical)
        elseif mode == 1 then
            cast = true
        elseif mode == 2 then
            cast = target.hpPercent <= comboRHp.value
        end
        if cast and (towerDive.value or not target.serverPosition:IsUnderEnemyTurret()) then
            if R:Cast(GetRPosition(target)) then
                return
            end
        end
    end

    if comboW.value and CanCast(W) and target:IsValidTarget(W.range) and not InAutoAttackRange(target) then
        if W:Cast(target, wHitchance) then
            return
        end
    end

    if comboE.value and CanCast(E) then
        local shouldCast = comboEAlways.value or not InAutoAttackRange(target)
        if shouldCast then
            local position, outer, canHit = GetECastPosition(target)
            if position and (towerDive.value or not position:IsUnderEnemyTurret()) then
                if canHit or comboEGapClose.value then
                    if E:Cast(position) then
                        return
                    end
                end
            end
        end
    end

    if comboQ.value and CanCast(Q) and InAutoAttackRange(target) then
        Q:Cast()
    end
end

local function Harass()
    if not Champions.CanHarass() then
        return
    end

    local range = AA_RANGE + Q_RANGE_BONUS
    if harassW.value then
        range = math.max(range, W.range)
    end
    local target = TargetSelector.GetTarget(range, DamageType.Physical, player.serverPosition, true)
    if not target then
        return
    end

    if harassW.value and CanCast(W) and target:IsValidTarget(W.range) and not InAutoAttackRange(target) then
        if W:Cast(target, wHitchance) then
            return
        end
    end

    if harassE.value and CanCast(E) and not InAutoAttackRange(target) then
        local position, outer, canHit = GetECastPosition(target)
        if position and canHit and (towerDive.value or not position:IsUnderEnemyTurret()) then
            if E:Cast(position) then
                return
            end
        end
    end

    if harassQ.value and CanCast(Q) and InAutoAttackRange(target) then
        Q:Cast()
    end
end

local function Killsteal()
    for _, enemy in ObjectManager.enemyHeroes:pairs() do
        if enemy and enemy.isAlive and enemy:IsValidTarget(W.range) then
            if killstealR.value and CanCast(R) and enemy:IsValidTarget(R.range) and GetRDamage(enemy) >= GetRealHealth(enemy, DamageType.Physical) and Champions.ValidUlt(enemy, 0.5) then
                if towerDive.value or not enemy.serverPosition:IsUnderEnemyTurret() then
                    R:Cast(GetRPosition(enemy))
                    return true
                end
            end

            if killstealW.value and CanCast(W) and enemy:IsValidTarget(W.range) and GetWDamage(enemy) >= GetRealHealth(enemy, DamageType.Physical) then
                local prediction = W:GetPrediction(enemy)
                if prediction and prediction.hitchance >= HitChance.High then
                    W:Cast(prediction.castPosition)
                    return true
                end
            end

            if killstealE.value and CanCast(E) and enemy:IsValidTarget(E_DASH + E_MAX_RADIUS) then
                local position, outer, canHit = GetECastPosition(enemy)
                if position and canHit and GetEDamage(enemy, outer) >= GetRealHealth(enemy, DamageType.Physical) then
                    if towerDive.value or not position:IsUnderEnemyTurret() then
                        E:Cast(position)
                        return true
                    end
                end
            end

            if killstealQ.value and CanCast(Q) and InAutoAttackRange(enemy) and GetQDamage(enemy) >= GetRealHealth(enemy, DamageType.Physical) then
                if towerDive.value or not player.serverPosition:IsUnderEnemyTurret() then
                    if Q:Cast() then
                        Game.IssueOrder(IssueOrderType.AttackUnit, enemy)
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function Farm()
    if not Champions.CanSpellFarm() then
        return
    end

    if farmW.value and CanCast(W) then
        local position = W:GetCastOnBestFarmPosition(farmWMin.value, false)
        if position then
            W:Cast(position)
        end
    end

    if farmQ.value and CanCast(Q) then
        local target = Orbwalker.GetTarget()
        if target and target:IsValid() and target.isAlive and InAutoAttackRange(target) then
            Q:Cast()
        end
    end
end

local function JungleClear()
    if farmW.value and CanCast(W) then
        local position = W:GetCastOnBestFarmPosition(1, true)
        if position then
            W:Cast(position)
        end
    end

    if farmQ.value and CanCast(Q) then
        local target = Orbwalker.GetTarget()
        if target and target:IsValid() and target.isAlive and target.isMonster and InAutoAttackRange(target) then
            Q:Cast()
        end
    end
end

local function Draw()
    if not player.isAlive then
        return
    end

    if drawPassive.value then
        local stacks = GetPassiveStacks()
        if stacks > 0 then
            Renderer.DrawWorldText(string.format("P %d/%d", stacks, PASSIVE_MAX), player.position, Math.Vector2(-25, -80), 16, 0xFFFFAA00)
        end
    end

    if drawQ2.value and IsQ2Ready() then
        Renderer.DrawWorldText("Q2 READY", player.position, Math.Vector2(-35, -105), 16, 0xFFFFAA00)
    end

    for _, enemy in ObjectManager.enemyHeroes:pairs() do
        if enemy and enemy:IsValid() and enemy.isAlive and enemy.isVisibleOnScreen then
            if drawLine.value then
                Renderer.DrawLine3D(player.position, enemy.position, Renderer.RGBA(255, 170, 85, 255), 2)
            end
            if drawDamage.value then
                Renderer.DamageIndicatorRendering(enemy, GetComboDamage(enemy), DamageType.Physical, 0, false)
            end
            if drawR.value and R:Ready() and enemy:IsValidTarget(R.range) and GetRDamage(enemy) >= GetRealHealth(enemy, DamageType.Physical) then
                Renderer.DrawWorldText("R KILL", enemy.position, Math.Vector2(-30, -85), 18, 0xFFFFAA00)
            end
        end
    end
end

local function OnTick()
    if not player or not player:IsValid() or not player.isAlive then
        return
    end

    if Killsteal() then
        return
    end

    if bit.band(Orbwalker.activeMode, OrbwalkerMode.Combo) ~= 0 and Orbwalker.CanUseSpell() then
        Combo()
    end
    if bit.band(Orbwalker.activeMode, OrbwalkerMode.Harass) ~= 0 and Orbwalker.CanUseSpell() then
        Harass()
    end
    if bit.band(Orbwalker.activeMode, OrbwalkerMode.LaneClear) ~= 0 and Orbwalker.CanUseSpell() then
        Farm()
    end
    if bit.band(Orbwalker.activeMode, OrbwalkerMode.JungleClear) ~= 0 and Orbwalker.CanUseSpell() then
        JungleClear()
    end
end

local function OnUnload()
    Champions.Clean()
    return CallbackResult.Dispose
end

Callback.Bind(CallbackType.OnTick, function()
    OnTick()
end)

Callback.Bind(CallbackType.OnImguiDraw, function()
    Draw()
end)

Callback.Bind(CallbackType.OnUnload, function()
    return OnUnload()
end)