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

local menu = UI.Menu.CreateMenu("LSZaahen", "LS 亚恒", 2)
Champions.CreateBaseMenu(menu, 0)

local predictionMenu = menu:AddMenu("prediction", "预判")
local wHitchance = predictionMenu:AddList("w_hitchance", "W 命中率", { "低", "中", "高", "极高" }, 2)

local comboMenu = menu:AddMenu("combo", "连招")
local comboQ = comboMenu:AddCheckBox("combo_q", "连招使用 Q", true)
local comboW = comboMenu:AddCheckBox("combo_w", "连招使用 W", true)
local comboE = comboMenu:AddCheckBox("combo_e", "连招使用 E", true)
local comboEAlways = comboMenu:AddCheckBox("combo_e_always", "普攻距离内也使用 E", false)
local comboEGapClose = comboMenu:AddCheckBox("combo_e_gap", "使用 E 接近", true)
local comboR = comboMenu:AddCheckBox("combo_r", "连招使用 R", true)
local comboRMode = comboMenu:AddList("combo_r_mode", "R 模式", { "可击杀", "总是", "目标血量 ≤ X%" }, 0)
local comboRHp = comboMenu:AddSlider("combo_r_hp", "R 目标血量 ≤ %", 40, 0, 100)
local towerDive = comboMenu:AddKeyBind("toverdive_key", "塔下强杀按键", string.byte("T"), false, true)
towerDive:PermaShow(true, true)

local harassMenu = menu:AddMenu("harass", "骚扰")
local harassQ = harassMenu:AddCheckBox("harass_q", "骚扰使用 Q", true)
local harassW = harassMenu:AddCheckBox("harass_w", "骚扰使用 W", true)
local harassE = harassMenu:AddCheckBox("harass_e", "骚扰使用 E", false)

local killstealMenu = menu:AddMenu("killsteal", "击杀")
local killstealQ = killstealMenu:AddCheckBox("killsteal_q", "使用 Q 击杀", true)
local killstealW = killstealMenu:AddCheckBox("killsteal_w", "使用 W 击杀", true)
local killstealE = killstealMenu:AddCheckBox("killsteal_e", "使用 E 击杀", false)
local killstealR = killstealMenu:AddCheckBox("killsteal_r", "使用 R 击杀", true)

local farmMenu = menu:AddMenu("farm", "清线")
local farmQ = farmMenu:AddCheckBox("farm_q", "使用 Q 清线", true)
local farmW = farmMenu:AddCheckBox("farm_w", "使用 W 清线", true)
local farmWMin = farmMenu:AddSlider("farm_w_min", "W 最少小兵数", 3, 1, 6)

local feelMenu = menu:AddMenu("feel", "手感")
local qResetDelay = feelMenu:AddSlider("q_reset_delay", "Q 重置延时 (ms)", 30, 0, 150)

Champions.CreateColorMenu(menu:AddMenu("draw", "绘制"), false)

local drawMenu = menu:AddMenu("drawmisc", "其他绘制")
local drawDamage = drawMenu:AddCheckBox("draw_damage", "绘制连招伤害", true)
local drawPassive = drawMenu:AddCheckBox("draw_passive", "绘制被动层数", true)
local drawQ2 = drawMenu:AddCheckBox("draw_q2", "绘制 Q2 就绪", true)
local drawR = drawMenu:AddCheckBox("draw_r", "绘制 R 可击杀", true)
local drawLine = drawMenu:AddCheckBox("draw_line", "绘制到敌人的连线", false)

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

local pendingQ = nil

local function QModeEnabled()
    if comboQ.value and bit.band(Orbwalker.activeMode, OrbwalkerMode.Combo) ~= 0 then
        return true
    end
    if harassQ.value and bit.band(Orbwalker.activeMode, OrbwalkerMode.Harass) ~= 0 then
        return true
    end
    return false
end

local function QueueQ(target)
    if pendingQ then
        return
    end
    if not target or not target.isHero or not target:IsValid() or not target.isAlive then
        return
    end
    if not InAutoAttackRange(target) or not CanCast(Q) or not QModeEnabled() then
        return
    end
    pendingQ = {
        target = target,
        time = Game.GetTime() + qResetDelay.value / 1000,
    }
end

local function TryCastPendingQ()
    if not pendingQ then
        return false
    end
    local now = Game.GetTime()
    if now < pendingQ.time then
        return false
    end
    local target = pendingQ.target
    pendingQ = nil
    if not QModeEnabled() then
        return false
    end
    if not target or not target:IsValid() or not target.isAlive then
        return false
    end
    if not InAutoAttackRange(target) or not CanCast(Q) then
        return false
    end
    if player:IsWindingUp() then
        return false
    end
    Q:Cast()
    return true
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

            if killstealQ.value and CanCast(Q) and InAutoAttackRange(enemy) and not player:IsWindingUp() and GetQDamage(enemy) >= GetRealHealth(enemy, DamageType.Physical) then
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

    if farmQ.value and CanCast(Q) and not player:IsWindingUp() then
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

    if farmQ.value and CanCast(Q) and not player:IsWindingUp() then
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
        Renderer.DrawWorldText("Q2 就绪", player.position, Math.Vector2(-35, -105), 16, 0xFFFFAA00)
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

    if TryCastPendingQ() then
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

if CallbackType.OnAfterAttack then
    Callback.Bind(CallbackType.OnAfterAttack, function(args)
        if args and args.target then
            QueueQ(args.target)
        end
    end)
end

Callback.Bind(CallbackType.OnImguiDraw, function()
    Draw()
end)

Callback.Bind(CallbackType.OnUnload, function()
    return OnUnload()
end)