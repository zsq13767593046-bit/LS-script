-- LS SDK 演示脚本 (Demo)
-- 适用于游戏脚本平台运行时, 演示以下 SDK 功能:
--   1. Menu     : 创建菜单 (复选框/滑条/按键绑定/下拉列表/颜色选择器)
--   2. Callback : OnTick(逻辑) / OnDraw(D3D绘制) / OnImguiDraw(ImGui绘制) / OnUnload(清理)
--   3. SDKSpell : 技能实例创建与预测施法
--   4. TargetSelector / ObjectManager : 目标选择与对象遍历
--   5. Renderer : 范围圈、连线、世界文字绘制

--------------------------------------------------------------------------------
-- 菜单
--------------------------------------------------------------------------------

---@type Menu
local menu = Menu:CreateMenu("LSDemo", "LS SDK Demo", 1)

-- 绘制选项子菜单
local drawMenu = menu:AddMenu("Drawing", "绘制选项")
local drawRange    = drawMenu:AddCheckBox("DrawRange", "绘制范围圈", true)
local drawLines    = drawMenu:AddCheckBox("DrawLines", "绘制到敌人的连线", true)
local drawHpText   = drawMenu:AddCheckBox("DrawHpText", "显示敌人生命值", true)
local rangeSlider  = drawMenu:AddSlider("RangeRadius", "范围圈半径", 1000, 100, 3000, 1)
local circleColor  = drawMenu:AddColorPicker("CircleColor", "范围圈颜色", 0xFF00FF00, true, true)

-- 连招选项子菜单
local comboMenu = menu:AddMenu("Combo", "连招选项")
local comboEnabled  = comboMenu:AddCheckBox("ComboEnabled", "启用 Q 连招", true)
local comboKey      = comboMenu:AddKeyBind("ComboKey", "连招按键", string.byte("T"), false, false)
local hitChanceList = comboMenu:AddList("HitChance", "最低命中率", { "Low", "Medium", "High", "VeryHigh" }, 3)

--------------------------------------------------------------------------------
-- 技能实例 (以通用直线技能弹为例, 请按实际英雄调整参数)
--------------------------------------------------------------------------------

---@type SDKSpell
local qSpell = SDKSpell.Create(SpellSlot.Q, 1000, DamageType.Physical)
qSpell:SetSkillshot(
    0.25,                                       -- 施法前摇 (秒)
    80,                                         -- 技能宽度
    1600,                                       -- 弹道速度
    SkillshotType.SkillshotLine,                -- 技能类型: 直线
    true,                                       -- 计算碰撞
    bit.bor(CollisionFlag.CollidesWithYasuoWall, CollisionFlag.CollidesWithMinions),
    HitChance.High,                             -- 默认最低命中率
    true                                        -- 计入目标碰撞半径
)

--------------------------------------------------------------------------------
-- 回调: 游戏逻辑 (每 tick 执行)
--------------------------------------------------------------------------------

Callback.Bind(CallbackType.OnTick, function()
    local player = Game.localPlayer
    if not player or not player:IsValid() then return end
    if not comboEnabled.value then return end
    if not (comboKey.value and comboKey.value ~= 0) then return end
    if not qSpell:Ready() then return end

    -- 选择射程内最佳目标并预测施法
    local target = TargetSelector.GetTarget(qSpell.range, DamageType.Physical)
    if not target then return end

    qSpell:Cast(target, hitChanceList)
end)

--------------------------------------------------------------------------------
-- 回调: D3D 绘制 (每帧执行)
--------------------------------------------------------------------------------

Callback.Bind(CallbackType.OnDraw, function()
    local player = Game.localPlayer
    if not player or not player:IsValid() then return end

    -- 绘制范围圈
    if drawRange.value and circleColor.boolValue then
        Renderer.DrawCircle3D(player.position, rangeSlider.value, 90, 2, circleColor.value)
    end
end)

--------------------------------------------------------------------------------
-- 回调: ImGui 绘制 (每帧执行, 用于文字与 2D/3D 线条)
--------------------------------------------------------------------------------

Callback.Bind(CallbackType.OnImguiDraw, function()
    local player = Game.localPlayer
    if not player or not player:IsValid() then return end

    -- 遍历敌方英雄: 连线 + 血量文字
    for _, enemy in ObjectManager.enemyHeroes:pairs() do
        if enemy:IsValidTarget(rangeSlider.value) then
            if drawLines.value then
                Renderer.DrawLine3D(player.position, enemy.position, Renderer.RGBA(255, 85, 85, 255), 2)
            end

            if drawHpText.value then
                local text = string.format("%s: %.0f / %.0f", enemy.charName, enemy.totalHealth, enemy.totalMaxHealth)
                Renderer.DrawWorldText(text, enemy.position, Math.Vector2(-50, -25), 14, 0xFFFFFFFF)
            end
        end
    end

    -- 标记当前最佳目标
    local target = TargetSelector.GetTarget(rangeSlider.value, DamageType.Physical)
    if target then
        Renderer.DrawWorldText("< 目标 >", target.position, Math.Vector2(-30, 30), 14, 0xFFFFFF00)
    end
end)

--------------------------------------------------------------------------------
-- 回调: 脚本卸载时清理资源
--------------------------------------------------------------------------------

Callback.Bind(CallbackType.OnUnload, function()
    qSpell:Delete()
    return CallbackResult.Dispose
end)

print("[LS SDK Demo] 脚本已加载")
