# ZaahenLS

基于 LegendSense SDK 的“不落魔锋”亚恒（Zaahen，ID 904）脚本，模块结构参考 `Darius-Training/LSDarius`。数值取自同目录上一级的 `Zaahen-Research/README.md`（26.23 / Data Dragon 16.23.1 / CommunityDragon 16.23）。

## 目录与安装

```
ZaahenLS/
├── module.lua   入口，检测英雄并加载 zaahen.lua
├── zaahen.lua   英雄逻辑、菜单、绘制
└── README.md
```

把整个 `ZaahenLS` 文件夹复制到脚本平台的 `GS\tier3\ZaahenLS\`，由平台读取 `module.lua`。根菜单名为 **LS 亚恒**，位于第 2 页。

`module.lua` 与 `zaahen.lua` 都做了英雄检测：`charName == "Zaahen"`，或 `Game.HashStringSDBM("Zaahen") == player.hash`。

## 技能建模

| 技能 | 建模 | 施法方式 |
| --- | --- | --- |
| Q 暗裔长刀 | 强化普攻，射程按普攻 175 + 25 处理 | `Q:Cast()` |
| W 厄影回锋 | 850 直线两段，0.5 秒前摇、70 宽度、2900 速度 | `W:Cast(target, hitchance)` |
| E 赤金突袭 | 最远 350 的位置突进，落点伤害内圈 200 / 外圈 375 | `E:Cast(落点)` |
| R 大赦 | 600 范围位置跃进，落地半径 550 | `R:Cast(预测落点)` |

Q1 / Q2 都是普攻重置。脚本不会在普攻前抢放 Q，而是在 `OnAfterAttack` 捕获普攻后按“Q 重置延时”排队施放，并在施放前检查 `player:IsWindingUp()`，避免打断下一发普攻。Q2 是否就绪通过 `ZaahenQ2` buff 判断，伤害随之切换为 Q2 数值。Q 的击杀检测会额外 `Game.IssueOrder(IssueOrderType.AttackUnit, target)`，确保强化普攻确实打出。

## 伤害模型

物理伤害用 `DamageLib.CalculatePhysicalDamage`，魔法伤害用 `DamageLib.CalculateMagicalDamage`，普攻用 `DamageLib.CalculateAutoAttackDamage`。

### Q

- Q1 额外伤害：`15/30/45/60/75 + 20%/25%/30%/35%/40% × 额外 AD`
- Q2 额外伤害：`30/60/90/120/150 + 20%/25%/30%/35%/40% × 额外 AD`
- 一次 Q 的伤害按 `普攻伤害 + 额外伤害` 计算
- 对野怪时额外伤害按 2 倍处理
- Q1 治疗（5%–9% 最大生命）未纳入伤害计算

### W

- 第一段：`40/60/80/100/120 + 50% × 额外 AD`
- 第二段：`30/50/70/90/110 + 30% × 额外 AD`
- 脚本按两段合计计算：`两段基础值之和 + 80% × 额外 AD`

### E

- 内圈 `r ≤ 200`：`40/60/80/100/120 + 50% × 额外 AD` 物理
- 外圈 `200 < r ≤ 375`：内圈物理的 `1.5 倍`，再加 `4%/4.5%/5%/5.5%/6%` 目标最大生命魔法
- 对野怪：物理额外 `+50`，外圈百分比魔法上限 `400`
- 实际落点由 `GetECastPosition` 计算：目标距离 50–650 时，落点在目标外圈 300 处；650–725 时沿直线突进 350 取外圈；超过 725 时只作为位移使用

### R

- `250/400/550 + 200% × 额外 AD` 物理
- 使用 `MovementPrediction.GetPrediction(target, 0.5)` 预测落点
- 未计入 R 的 10%/20%/30% 被动护甲穿透、33% 命中英雄回复，以及施放期间 50% 减伤

### 被动

`ZaahenPassiveBuff` 的层数只用于绘制（上限 12）。果决提供的攻击力已经包含在 `player.totalAttackDamage` / `totalBonusAttackDamage` 中，因此伤害公式会自动吃到面板增益。满层复活没有自动操作。

## 连招逻辑

普攻距离内以 **A → Q** 起手：

```
Orbwalker 普攻
  → OnAfterAttack 捕获普攻
  → 按“Q 重置延时”排队 Q
  → 检查 IsWindingUp 后施放 Q
  → 下一发强化普攻
```

远程先用 W/E 接近，进入普攻距离后再 A → Q：

```
R（满足条件且目标在 600 内）
  → W（目标在 850 内且不在普攻距离）
  → E（目标不在普攻距离，或开启“普攻距离内也使用 E”）
  → 等待普攻出手后 Q
```

- Q 不会在普攻前施放；只有普攻已经出手且目标在普攻距离内才会排队
- Q 施放前检查 `player:IsWindingUp()`，正在前摇时跳过本次 Q，避免断平 A
- 高攻速下如果下一发普攻已开始前摇，脚本会放弃这次 Q，等下一次普攻后再重置
- R 按模式判断：可击杀 / 总是 / 目标血量阈值；目标在敌方塔下时默认不 R
- W 是远程两段伤害并拉近目标，用于先手补距离
- E 优先落在目标外圈，触发 1.5 倍物理伤害和最大生命百分比魔法伤害
- 目标超出 E 伤害范围但仍在 W 射程内时，可按设置用 E 作为位移接近
- 目标在普攻距离时默认不 E，除非开启“普攻距离内也使用 E”
- 塔下默认不连招；按住“塔下强杀按键”（默认 T）可强制 E/R
- 每个技能施放前检查等级、冷却和法力（`CanCast`）

R 模式：

| 模式 | 行为 |
| --- | --- |
| 可击杀 | R 伤害 ≥ 物理有效生命时施放 |
| 总是 | 目标在 R 范围内且可用时施放 |
| 目标血量 ≤ X% | 目标生命百分比低于滑条值时施放 |

## 功能特性

### 连招

- Q / W / E / R 独立开关
- E 是否在普攻距离内也使用
- E 是否允许单纯用于接近
- R 三种模式与血量阈值
- 塔下强杀按键

### 骚扰

- W 默认开启，目标不在普攻距离时从 850 距离消耗并拉近
- Q 默认开启，进入普攻距离后等普攻出手再 A → Q
- E 默认关闭，避免骚扰时突进过深

### 击杀

- R：目标在 600 内且 R 伤害足够
- W：预测命中且两段伤害足够
- E：按外圈/内圈伤害判断，默认关闭
- Q：强化普攻 + 普攻伤害足够时施放，要求当前不在普攻前摇，并补攻击指令
- 任一技能成功施放后本 tick 不再继续

### 清线 / 打野

- W 使用 `GetCastOnBestFarmPosition` 找角度清线，默认至少 3 个目标
- Q 在 Orbwalker 目标为小兵或野怪且进入普攻距离时强化普攻
- 清线遵循 `Champions.CanSpellFarm()`

### 手感

- `Q 重置延时 (ms)`：默认 30。`OnAfterAttack` 后等待该时间再尝试 Q；设为 0 表示下一次 OnTick 立即尝试
- Q 施放前始终检查普攻前摇，宁可少放一次 Q 也不打断平 A

### 绘制

- `Champions.CreateColorMenu` 提供官方 Q/W/E/R 范围
- 被动果决层数（`P x/12`）
- `Q2 就绪` 提示
- 连招伤害条（`Renderer.DamageIndicatorRendering`）
- R 可击杀标记
- 到敌方英雄的连线

## 可调参数

在 `zaahen.lua` 顶部：

- `Q1_BASE`、`Q2_BASE`、`Q_COEFF`
- `W1_BASE`、`W2_BASE`、`W1_COEFF`、`W2_COEFF`
- `E_BASE`、`E_COEFF`、`E_MIN_RADIUS`、`E_MAX_RADIUS`、`E_DASH`
- `E_HP_PERCENT`、`E_MONSTER_BONUS`、`E_MONSTER_CAP`
- `R_BASE`、`R_COEFF`
- `Q2_BUFF`、`PASSIVE_BUFF`

## 已知限制

- Q1/Q2 的可用状态依赖 `ZaahenQ2` buff 和 `SDKSpell:Ready()`；不同客户端的 buff 名可能需要调整
- Q 重置依赖 `OnAfterAttack`；如果平台没有该回调，Q 不会自动接在普攻后
- Q1 治疗、被动满层复活、R 命中英雄回复未自动使用
- R 的被动护甲穿透与施放期间减伤未计入伤害/生存模型
- E 落点几何假设平坦地形；墙体或位移阻挡可能让实际落点与计算结果不同
- W 预测速度采用数据中的 movement component `2900`，与记录里的 `missileSpeed = 1600` 不同，实机可能需要微调
- 伤害指示为理论连招伤害，未逐帧模拟 W 两段结算、E 落点判定和暴击/装备特效

## 验证

- 使用 luaparse 做 Lua 5.1 语法检查
- 使用 fengari + SDK 桩环境跑通：模块加载、骚扰 W、A→Q、Q 不打断普攻前摇、连招 R/W/E 外圈、击杀 W/E/Q/R、清线、打野、绘制与卸载
- LegendSense 运行时依赖游戏客户端，最终效果建议在训练模式中校准