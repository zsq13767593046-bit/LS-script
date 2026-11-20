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

if not IsDarius() then
    return
end

Champions.CppScriptMaster(false)

Champions.Q = SDKSpell.Create(SpellSlot.Q, 425, DamageType.Physical)
Champions.W = SDKSpell.Create(SpellSlot.W, 175, DamageType.Physical)
Champions.E = SDKSpell.Create(SpellSlot.E, 535, DamageType.Physical)
Champions.R = SDKSpell.Create(SpellSlot.R, 460, DamageType.True)

Champions.R:SetTargetted(0.25, math.flt_max, SkillshotType.SkillshotLine, false, CollisionFlag.CollidesWithNothing, HitChance.High, true)

local Q = Champions.Q
local W = Champions.W
local E = Champions.E
local R = Champions.R

local Q_BASE = { 50, 80, 110, 140, 170 }
local Q_RATIO = { 1.00, 1.10, 1.20, 1.30, 1.40 }
local W_RATIO = { 1.40, 1.45, 1.50, 1.55, 1.60 }
local R_BASE = { 125, 250, 375 }
local Q_INNER = 180
local HEMO_HASH = Game.fnvhash("DariusHemo")
local HEMO_MARKER_HASH = Game.fnvhash("DariusHemoMarker")

local menu = Menu:CreateMenu("LSDarius", "LS Darius", 2)
Champions.CreateBaseMenu(menu, 0)

local comboMenu = menu:AddMenu("combo", "Combo")
local comboQ = comboMenu:AddCheckBox("combo_q", "Use Q in Combo", true)
local comboQBlade = comboMenu:AddCheckBox("combo_q_blade", "Q Only at Blade Range", false)
local comboW = comboMenu:AddCheckBox("combo_w", "Use W in Combo", true)
local comboE = comboMenu:AddCheckBox("combo_e", "Use E in Combo", true)
local comboR = comboMenu:AddCheckBox("combo_r", "Use R in Combo", true)
local comboRMode = comboMenu:AddList("combo_r_mode", "R Mode", { "If Killable", "Always", "5 Bleed Stacks", "Target HP <= X%" }, 0)
local comboRHp = comboMenu:AddSlider("combo_r_hp", "R Target HP <= %", 40, 0, 100)
local towerDive = comboMenu:AddKeyBind("toverdive_key", "Tower Dive Key", string.byte("T"), false, true)
towerDive:PermaShow(true, true)

local harassMenu = menu:AddMenu("harass", "Harass")
local harassQ = harassMenu:AddCheckBox("harass_q", "Use Q in Harass", true)
local harassW = harassMenu:AddCheckBox("harass_w", "Use W to Reset Auto Attack", true)
local harassWDelay = harassMenu:AddSlider("harass_w_delay", "W Reset Delay (ms)", 50, 0, 200)
local harassMana = harassMenu:AddSlider("harass_mana", "Min Mana %", 40, 0, 100)

local killstealMenu = menu:AddMenu("killsteal", "Killsteal")
local killstealQ = killstealMenu:AddCheckBox("killsteal_q", "Killsteal with Q", true)
local killstealW = killstealMenu:AddCheckBox("killsteal_w", "Killsteal with W", false)
local killstealR = killstealMenu:AddCheckBox("killsteal_r", "Killsteal with R", true)

local farmMenu = menu:AddMenu("farm", "Farm")
local farmQ = farmMenu:AddCheckBox("farm_q", "Farm with Q", true)
local farmW = farmMenu:AddCheckBox("farm_w", "Farm with W", true)
local farmQMin = farmMenu:AddSlider("farm_q_min", "Q Min Minions", 3, 1, 6)
local farmMana = farmMenu:AddSlider("farm_mana", "Min Mana %", 35, 0, 100)

Champions.CreateColorMenu(menu:AddMenu("draw", "Drawing"), false)

local drawMenu = menu:AddMenu("drawmisc", "Draw Misc")
local drawDamage = drawMenu:AddCheckBox("draw_damage", "Draw Combo Damage", true)
local drawStacks = drawMenu:AddCheckBox("draw_stacks", "Draw Bleed Stacks", true)
local drawKillable = drawMenu:AddCheckBox("draw_killable", "Draw R Killable", true)
local drawLine = drawMenu:AddCheckBox("draw_line", "Draw Line to Enemies", false)

local function GetBleedStacks(target)
    if not target then
        return 0
    end
    local stacks = target:GetBuffStacks(HEMO_HASH)
    if not stacks or stacks < 1 then
        stacks = target:GetBuffStacks(HEMO_MARKER_HASH)
    end
    stacks = stacks or 0
    if stacks < 0 then
        stacks = 0
    elseif stacks > 5 then
        stacks = 5
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

local function GetQDamage(target, blade)
    local rank = Q:Level()
    if rank < 1 then
        return 0
    end
    if rank > 5 then
        rank = 5
    end
    local raw = Q_BASE[rank] + Q_RATIO[rank] * player.totalAttackDamage
    if not blade then
        raw = raw * 0.35
    end
    return DamageLib.CalculatePhysicalDamage(player, target, raw)
end

local function GetWDamage(target)
    local rank = W:Level()
    if rank < 1 then
        return 0
    end
    if rank > 5 then
        rank = 5
    end
    local raw = W_RATIO[rank] * player.totalAttackDamage
    return DamageLib.CalculatePhysicalDamage(player, target, raw)
end

local function GetBleedDamage(target, stacks)
    if stacks <= 0 then
        return 0
    end
    local raw = (12 + player:Level() + 0.30 * player.totalBonusAttackDamage) * stacks
    return DamageLib.CalculatePhysicalDamage(player, target, raw)
end

local function GetRDamage(target)
    local rank = R:Level()
    if rank < 1 then
        return 0
    end
    if rank > 3 then
        rank = 3
    end
    local stacks = GetBleedStacks(target)
    return (R_BASE[rank] + 0.75 * player.totalBonusAttackDamage) * (1 + 0.20 * stacks)
end

local function IsRKillable(target)
    if not target or not target:IsValidTarget(R.range) then
        return false
    end
    return GetRDamage(target) >= GetRealHealth(target, DamageType.True)
end

local function GetComboDamage(target)
    local damage = DamageLib.CalculateAutoAttackDamage(player, target)
    if Q:Ready() then
        damage = damage + GetQDamage(target, true)
    end
    if W:Ready() then
        damage = damage + GetWDamage(target)
    end
    damage = damage + GetBleedDamage(target, math.max(GetBleedStacks(target), 5))
    if R:Ready() then
        damage = damage + GetRDamage(target)
    end
    return damage
end

local function CanCast(spell)
    return spell:Level() > 0 and spell:Ready() and player.mp >= spell:ManaCost()
end

local function GetPredictedPosition(target, delay)
    local prediction = MovementPrediction.GetPrediction(target, delay)
    if prediction and prediction.unitPosition then
        return prediction.unitPosition
    end
    return target.serverPosition
end

local function GetComboTarget()
    local range = math.max(E.range, R.range)
    return TargetSelector.GetTarget(range, DamageType.Physical, player.serverPosition, true)
end

local function CountJungleInRange(range)
    local count = 0
    for _, minion in ObjectManager.jungleMinions:pairs() do
        if minion and minion:IsValidTarget(range, true, player.serverPosition) then
            count = count + 1
        end
    end
    return count
end

local function Combo()
    local target = GetComboTarget()
    if not target then
        return
    end
    if not towerDive.value and player.serverPosition:IsUnderEnemyTurret() then
        return
    end

    if comboE.value and CanCast(E) and target:IsValidTarget(E.range) and not target:IsValidTarget(Q.range) then
        E:Cast(GetPredictedPosition(target, 0.25))
    end

    if comboW.value and CanCast(W) and Orbwalker.IsInAutoAttackRange(player, target) then
        W:Cast()
    end

    if comboQ.value and CanCast(Q) then
        local position = GetPredictedPosition(target, 0.75)
        local distance = player.serverPosition:Distance(position)
        if distance <= Q.range and (distance >= Q_INNER or not comboQBlade.value) then
            Q:Cast()
        end
    end

    if comboR.value and CanCast(R) and target:IsValidTarget(R.range) and Champions.ValidUlt(target, 0.25) then
        local mode = comboRMode.value
        local cast = false
        if mode == 0 then
            cast = IsRKillable(target)
        elseif mode == 1 then
            cast = true
        elseif mode == 2 then
            cast = GetBleedStacks(target) >= 5
        elseif mode == 3 then
            cast = target.hpPercent <= comboRHp.value
        end
        if cast then
            R:CastOnUnit(target, false)
        end
    end
end

local pendingHarassW = nil

local function QueueHarassW(target)
    if pendingHarassW then
        return
    end
    if bit.band(Orbwalker.activeMode, OrbwalkerMode.Harass) == 0 then
        return
    end
    if not harassW.value or not CanCast(W) then
        return
    end
    if not target or not target.isHero or not target:IsValid() or not target.isAlive then
        return
    end
    pendingHarassW = {
        target = target,
        time = Game.GetTime() + harassWDelay.value / 1000,
    }
end

local function TryCastPendingHarassW()
    if not pendingHarassW then
        return false
    end
    local now = Game.GetTime()
    if now < pendingHarassW.time then
        return false
    end
    local target = pendingHarassW.target
    pendingHarassW = nil
    if bit.band(Orbwalker.activeMode, OrbwalkerMode.Harass) == 0 then
        return false
    end
    if not target or not target:IsValid() or not target.isAlive then
        return false
    end
    if not harassW.value or not CanCast(W) then
        return false
    end
    if not Orbwalker.IsInAutoAttackRange(player, target) then
        return false
    end
    W:Cast()
    return true
end

local function Harass()
    if not Champions.CanHarass() then
        return
    end
    if player.mpPercent < harassMana.value then
        return
    end

    local target = TargetSelector.GetTarget(Q.range, DamageType.Physical, player.serverPosition, true)
    if not target then
        return
    end

    local orbTarget = Orbwalker.GetTarget()
    if harassW.value and CanCast(W) and orbTarget and orbTarget.isHero and orbTarget:IsValid()
        and orbTarget.networkId == target.networkId
        and Orbwalker.IsInAutoAttackRange(player, orbTarget) then
        return
    end

    if harassQ.value and CanCast(Q) then
        local position = GetPredictedPosition(target, 0.75)
        local distance = player.serverPosition:Distance(position)
        if distance <= Q.range and (distance >= Q_INNER or not comboQBlade.value) then
            Q:Cast()
        end
    end
end

local function Killsteal()
    for _, enemy in ObjectManager.enemyHeroes:pairs() do
        if enemy and enemy.isAlive and enemy:IsValidTarget(R.range) then
            if killstealR.value and CanCast(R) and IsRKillable(enemy) and Champions.ValidUlt(enemy, 0.25) then
                R:CastOnUnit(enemy, false)
                return true
            end

            if killstealQ.value and CanCast(Q) and enemy:IsValidTarget(Q.range) then
                local position = GetPredictedPosition(enemy, 0.75)
                local distance = player.serverPosition:Distance(position)
                if distance <= Q.range and GetQDamage(enemy, distance >= Q_INNER) >= GetRealHealth(enemy, DamageType.Physical) then
                    Q:Cast()
                    return true
                end
            end

            if killstealW.value and CanCast(W) and Orbwalker.IsInAutoAttackRange(player, enemy) then
                local damage = GetWDamage(enemy) + DamageLib.CalculateAutoAttackDamage(player, enemy)
                if damage >= GetRealHealth(enemy, DamageType.Physical) then
                    W:Cast()
                    return true
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
    if player.mpPercent < farmMana.value then
        return
    end

    if farmQ.value and CanCast(Q) then
        local count = player.serverPosition:CountEnemyLaneMinionsInRange(Q.range) + CountJungleInRange(Q.range)
        if count >= farmQMin.value then
            Q:Cast()
        end
    end

    if farmW.value and CanCast(W) then
        local target = Orbwalker.GetTarget()
        if target and target:IsValid() and target.isAlive and Orbwalker.IsInAutoAttackRange(player, target)
            and (target.isLargeMonster or target.isSiegeMinion or target.isSuperMinion) then
            W:Cast()
        end
    end
end

local function JungleClear()
    if player.mpPercent < farmMana.value then
        return
    end

    if farmQ.value and CanCast(Q) and CountJungleInRange(Q.range) >= 2 then
        Q:Cast()
    end

    if farmW.value and CanCast(W) then
        local target = Orbwalker.GetTarget()
        if target and target:IsValid() and target.isAlive and target.isLargeMonster and Orbwalker.IsInAutoAttackRange(player, target) then
            W:Cast()
        end
    end
end

local function Draw()
    if not player.isAlive then
        return
    end

    for _, enemy in ObjectManager.enemyHeroes:pairs() do
        if enemy and enemy:IsValid() and enemy.isAlive and enemy.isVisibleOnScreen then
            if drawLine.value then
                Renderer.DrawLine3D(player.position, enemy.position, Renderer.RGBA(255, 85, 85, 255), 2)
            end
            if drawDamage.value then
                Renderer.DamageIndicatorRendering(enemy, GetComboDamage(enemy), DamageType.Physical, 0, false)
            end
            if drawStacks.value then
                local stacks = GetBleedStacks(enemy)
                if stacks > 0 then
                    Renderer.DrawWorldText(tostring(stacks) .. "x", enemy.position, Math.Vector2(-10, -60), 16, 0xFFFF4500)
                end
            end
            if drawKillable.value and R:Ready() and IsRKillable(enemy) then
                Renderer.DrawWorldText("R KILL", enemy.position, Math.Vector2(-30, -85), 18, 0xFFFF0000)
            end
        end
    end
end

local function OnTick()
    if not player or not player:IsValid() or not player.isAlive then
        return
    end

    if TryCastPendingHarassW() then
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

Callback.Bind(CallbackType.OnAfterAttack, function(args)
    if args and args.target then
        QueueHarassW(args.target)
    end
end)

Callback.Bind(CallbackType.OnImguiDraw, function()
    Draw()
end)

Callback.Bind(CallbackType.OnUnload, function()
    return OnUnload()
end)