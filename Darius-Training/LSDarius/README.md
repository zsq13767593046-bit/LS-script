# LSDarius

基于 LegendSense SDK 的德莱厄斯（Darius）脚本。数值与公式取自 `Darius-Training/README.md`（召唤师峡谷 26.23 / Data Dragon 16.23.1），模块组织方式参考 `LSDarkAio-Zed`。

## 目录与安装

```
LSDarius/
├── module.lua   入口，检测英雄并加载 darius.lua
├── darius.lua   英雄逻辑、菜单、绘制
└── README.md
```

把整个 `LSDarius` 文件夹复制到脚本平台的 `GS\tier3\LSDarius\`，由平台读取 `module.lua`。根菜单名为 **LS Darius**，位于第 2 页。

`module.lua` 与 `darius.lua` 都做了英雄检测：`charName == "Darius"`，或 `Game.HashStringSDBM("Darius") == player.hash`，避免在其他英雄上误加载。

## 设计思路

### 1. 模块结构

沿用 Zed 脚本的分层方式：

- `module.lua` 只负责英雄判定和 `Environment.LoadModule("darius")`
- `darius.lua` 负责全部运行时逻辑
- 技能实例统一注册为 `Champions.Q/W/E/R`，卸载时调用 `Champions.Clean()`
- 脚本顶部调用 `Champions.CppScriptMaster(false)`，关闭内置的 Cpp 英雄逻辑，避免与自定义逻辑重复施法

### 2. 技能建模

| 技能 | 建模 | 施法方式 |
| --- | --- | --- |
| Q 大杀四方 | 自身圆形 AoE，范围 425，0.75 秒前摇 | `Q:Cast()` |
| W 致残打击 | 自身强化普攻，按普攻距离 175 处理 | `W:Cast()` |
| E 无情铁手 | 锥形拉取，范围 535 | `E:Cast(预测位置)` |
| R 诺克萨斯断头台 | 指向性，范围 460，真实伤害 | `R:SetTargetted(...)` + `R:CastOnUnit(target)` |

Q 不依赖弹道预测，只在目标“0.75 秒前摇后的预测位置”仍处于范围内时施放。目标距离小于 `Q_INNER`（默认 180）时视为斧柄命中，伤害按 35% 计算；可通过“Q Only at Blade Range”选项禁止近身 Q。

E 只在目标处于 E 范围、但不在 Q 范围时使用，定位为“补距离的拉取”，连招中先 E 再等下一 tick 的 Q，避免同 tick 用拉取前的位置判断 Q 射程。

### 3. 伤害模型

物理伤害统一用 `DamageLib.CalculatePhysicalDamage` 结算，普攻用 `DamageLib.CalculateAutoAttackDamage`。核心公式：

- Q 斧刃：`(50/80/110/140/170 + 100%/110%/120%/130%/140% 总 AD)`
- Q 斧柄：斧刃的 35%
- W：`140%/145%/150%/155%/160% 总 AD`
- 出血：每层 `(12 + 英雄等级 + 0.30 × 额外 AD)`，持续 5 秒的原始物理伤害
- R：`(125/250/375 + 0.75 × 额外 AD) × (1 + 0.20 × 出血层数)`，真实伤害

出血层数通过 `target:GetBuffStacks(Game.fnvhash("DariusHemo"))` 读取，读取不到时回退到 `DariusHemoMarker`，并限制在 0–5 层。R 是否可击杀用真实伤害与 `target:GetRealHealth(0, DamageType.True)` 比较，护盾会计入有效生命。

诺克萨斯之力提供的额外攻击力已经包含在 `player.totalBonusAttackDamage` 中，因此 R 与出血计算会自动吃到该增益，不再单独检测 buff。

### 4. 连招优先级

```
E（拉近） → W（强化普攻） → Q（0.75s 预测） → R（满足条件时）
```

- W 在普攻距离内施放，让 Orbwalker 的下一发普攻吃到强化
- Q 优先在目标仍会留在范围内时施放
- R 放在最后，读取当前出血层数；如果 Q 尚未落地，则按较低层数保守判断，避免高估伤害
- 每个技能施放前检查等级、冷却、法力（`CanCast`）
- 塔下默认不连招，按住“Tower Dive Key”（默认 T）可强制塔下操作

R 模式：

| 模式 | 行为 |
| --- | --- |
| If Killable | R 伤害 ≥ 有效生命时施放 |
| Always | 只要目标在 R 范围内且可施法 |
| 5 Bleed Stacks | 目标满 5 层出血时施放 |
| Target HP <= X% | 目标生命百分比低于滑条值时施放 |

## 功能特性

### Combo

- 可单独开关 Q / W / E / R
- Q 斧刃范围限制
- R 四种触发模式与血量阈值
- 塔下强杀按键

### Harass

- Q / W 独立开关，默认开启；不提供 E，骚扰模式不用 E 起手
- 起手为 A：进入普攻距离后先让 Orbwalker 打出普攻，脚本不抢放 Q
- `OnAfterAttack` 检测到普攻出手后开始计时，默认等待 50ms（`W Reset Delay` 滑条，0–200ms），再放 W 重置普攻后摇并打出强化普攻，形成 A → W 起手
- 等待计时由 `OnTick` 检查并施放 W；W 进入冷却后 Harass 才会使用 Q
- 最低法力百分比滑条，默认 40%
- 复用 `Champions.CanHarass()`，自动处理骚扰开关与塔下限制

### Killsteal

每 tick 扫描 `ObjectManager.enemyHeroes`：

- R：可击杀且 `Champions.ValidUlt` 通过时优先使用
- Q：预测 0.75 秒后的位置，按斧刃/斧柄分别计算伤害
- W：W 伤害加一次普攻伤害足够击杀时施放
- 任一技能成功施放后，本 tick 不再执行后续模式逻辑，避免重复投入技能

### Farm / JungleClear

- Q 按“范围内敌方小兵 + 野怪数量”判断，默认至少 3 个目标
- W 在 Orbwalker 目标为大型野怪、炮车或超级兵时施放
- 清线法力百分比滑条默认 35%
- 清线使用 `Champions.CanSpellFarm()`，遵循平台的法术清线开关

### 绘制

- `Champions.CreateColorMenu` 提供 Q/W/E/R 的官方范围绘制
- Draw Misc 子菜单额外提供：
  - 连招伤害条（`Renderer.DamageIndicatorRendering`）
  - 目标出血层数
  - “R KILL”可击杀标记
  - 到敌方英雄的连线

### 生命周期

- `OnTick`：骚扰 W 重置计时 → 击杀检测 → 按 `Orbwalker.activeMode` 执行 Combo / Harass / LaneClear / JungleClear
- `OnAfterAttack`：记录刚出手的普攻，在 Harass 模式下安排延时 W 重置
- `OnImguiDraw`：绘制
- `OnUnload`：`Champions.Clean()` 并返回 `CallbackResult.Dispose`
- 所有模式逻辑都受 `Orbwalker.CanUseSpell()` 保护，避免打断普攻节奏

## 可调参数

在 `darius.lua` 顶部：

- `Q_INNER`：斧柄/斧刃分界，默认 180
- `Q_BASE`、`Q_RATIO`、`W_RATIO`、`R_BASE`：与 `Darius-Training/README.md` 对应的数值表
- `HEMO_HASH`、`HEMO_MARKER_HASH`：出血 buff 名

## 已知限制

- Q 内圈半径 180 为近似值，实机手感可能需要微调
- W 只计算技能本身的 AD 倍率，未逐项模拟攻击特效、暴击与装备 on-hit
- 出血按“完整持续时间”计算，连招伤害条中的 5 层出血属于理论值
- E 被动护甲穿透（20%–40%）未在脚本内再次折算，依赖 `DamageLib.CalculatePhysicalDamage` 是否已包含
- R 的 20 秒重置窗口依赖 `SDKSpell:Ready()` 的判定，未额外检测重置 buff
- 普攻衔接依赖平台 Orbwalker，脚本不主动发送攻击指令

## 验证

- 使用 luaparse 做了 Lua 5.1 语法检查
- 使用 fengari + SDK 桩环境跑通：模块加载、R 击杀、W/Q 连招、R Always 模式、Harass（先等普攻、`OnAfterAttack` 延时 W 重置）、Farm、JungleClear、绘制回调与卸载回调
- LegendSense 运行时依赖游戏客户端，最终效果仍建议在训练模式中校准