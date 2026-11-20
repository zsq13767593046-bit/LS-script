# 亚恒英雄属性与技能资料

适用版本为 PC 版《英雄联盟》召唤师峡谷 **26.23**，对应 Riot Data Dragon **16.23.1**，核对日期为 **2026 年 11 月 20 日**。不落魔锋亚恒（Zaahen，ID `904`）是使用法力的近战战士，于 25.23 版本上线。下文的伤害公式为护甲、魔抗及其他伤害修正前的数值。[Riot 英雄页](https://www.leagueoflegends.com/en-us/champions/zaahen/) · [上线公告](https://www.leagueoflegends.com/en-au/news/game-updates/patch-25-23-notes/#zaahen) · [26.23 版本公告](https://www.leagueoflegends.com/en-us/news/game-updates/league-of-legends-patch-26-23-notes/)

## 基础属性

| 属性 | 1 级 | 成长系数 | 18 级 |
| --- | ---: | ---: | ---: |
| 生命值 | 640 | +114 | 2578 |
| 法力值 | 350 | +55 | 1285 |
| 攻击力 | 63 | +4 | 131 |
| 护甲 | 36 | +5 | 121 |
| 魔抗 | 32 | +2.05 | 66.85 |
| 每 5 秒生命回复 | 7.5 | +0.8 | 21.1 |
| 每 5 秒法力回复 | 8.15 | +0.75 | 20.9 |
| 攻速（次/秒） | 0.625 | +2.5% | 0.890625 |
| 移动速度 | 345 | — | 345 |
| 普攻距离 | 175 | — | 175 |
| 暴击率 | 0% | — | 0% |

18 级数值按累计 17 份成长计算，排除装备、符文和果决增益。Data Dragon 的攻击力成长字段为 `0`，表中采用同版本客户端角色记录 `damagePerLevelModifiable.baseValue` 的 `4`。[16.23.1 中文英雄数据](https://ddragon.leagueoflegends.com/cdn/16.23.1/data/zh_CN/champion/Zaahen.json) · [16.23 客户端数据镜像](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/zaahen.bin.json)

## 技能速查

| 技能 | 基础冷却（秒） | 法力 | 范围与效果 |
| --- | --- | ---: | --- |
| P 不落之志 | 300 / 240 / 180 / 120（复活冷却） | — | 伤害敌方英雄叠果决，上限 12 层。满层且复活可用时承受致命伤害会触发复活。 |
| Q 暗裔长刀 | 8 / 7.5 / 7 / 6.5 / 6 | 25 | 第一次强化普攻双斩并回复，第二次强化普攻击飞。两次强化均增加 25 普攻距离。 |
| W 厄影回锋 | 14 / 13.5 / 13 / 12.5 / 12 | 50 | 850 距离直线两段物理伤害，第二段拉近目标，客户端最大拉拽距离为 225。 |
| E 赤金突袭 | 10 / 9.5 / 9 / 8.5 / 8 | 40 | 以 900 单位/秒冲刺最多 350 单位，到达后挥砍。落点的内圈半径为 200，外圈最大半径为 375。 |
| R 大赦 | 110 / 95 / 80 | 100 | 最远跃进 600，落地伤害半径 550。施放期间获得 50% 伤害减免。 |

Q 和 E 在 Data Dragon 的通用 `range` 字段都是 `25000`。上表采用 Q 的强化普攻额外距离和 E 的 `DashDistance`、`MinimumRadius`、`MaximumRadius` 字段。Q、W 冷却以 Data Dragon 和客户端 `Cooldown.values` 为准，两者均与对应版本公告一致。客户端另有一组旧的 `cooldownTime` 值。[Data Dragon 技能数据](https://ddragon.leagueoflegends.com/cdn/16.23.1/data/zh_CN/champion/Zaahen.json) · [客户端技能数据](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/zaahen.bin.json) · [26.22 Q 调整](https://www.leagueoflegends.com/en-us/news/game-updates/league-of-legends-patch-26-22-notes/#zaahen) · [26.13 W 调整](https://www.leagueoflegends.com/en-sg/news/game-updates/league-of-legends-patch-26-13-notes/#zaahen)

## P 不落之志

- 普攻和伤害技能命中敌方英雄积累果决，命中可刷新计时。客户端记录果决的衰减起始时间为 **5 秒**，上限 **12 层**。
- 客户端每层攻击力系数随等级从 **1.5% 到 2.8%**，满层增益带有 **2 倍**倍率。这里列的是技能数据中的系数，面板增益还取决于实际攻击力。
- 满层且复活可用时，致命伤害会触发 **4 秒**复活过程。复活回复和冷却在 **1、6、11、16 级**各有一档。

| 亚恒等级 | 复活回复（自身最大生命值） | 复活冷却 |
| --- | ---: | ---: |
| 1–5 | 30% | 300 秒 |
| 6–10 | 45% | 240 秒 |
| 11–15 | 60% | 180 秒 |
| 16–18 | 75% | 120 秒 |

[Riot 技能介绍](https://www.leagueoflegends.com/en-us/news/game-updates/zaahen-abilities-rundown/) · [25.24 公告中的被动热修记录](https://www.leagueoflegends.com/en-au/news/game-updates/patch-25-24-notes/) · [客户端被动公式](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/zaahen.bin.json)

## Q 暗裔长刀

- **Q1** 强化下一次普攻，将这一击分为两次斩击。合计原始物理伤害为普通攻击伤害加 `15 / 30 / 45 / 60 / 75 + 20% / 25% / 30% / 35% / 40% × 额外 AD`。两段共享这一份技能额外伤害。
- **Q1 治疗**按亚恒自身最大生命计算。对英雄为 **5% / 6% / 7% / 8% / 9%**，对小兵和野怪减半。攻击守卫、植物或建筑物时不治疗。
- **Q2** 在第一次强化普攻打出后，约 **1.5 秒**进入可重施状态，重施窗口 **4 秒**。第二次强化普攻附加 `30 / 60 / 90 / 120 / 150 + 20% / 25% / 30% / 35% / 40% × 额外 AD` 物理伤害，并击飞 **0.75 秒**。
- Riot 26.3 公告将 Q 对野怪的伤害倍率提高至 **2 倍**。从 26.18 起，Q 已激活时若进入复活状态，会立刻开始冷却。26.21 修复了已出手的 Q 因中途进入复活而不结算的问题。

[中文技能提示](https://ddragon.leagueoflegends.com/cdn/16.23.1/data/zh_CN/champion/Zaahen.json) · [客户端 Q 公式](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/zaahen.bin.json) · [25.24 热修](https://www.leagueoflegends.com/en-au/news/game-updates/patch-25-24-notes/) · [26.3 野怪调整](https://www.leagueoflegends.com/en-us/news/game-updates/patch-26-3-notes/) · [26.18 Q2 与复活改动](https://www.leagueoflegends.com/en-us/news/game-updates/league-of-legends-patch-26-18-notes/) · [26.21 修复](https://www.leagueoflegends.com/en-us/news/game-updates/league-of-legends-patch-26-21-notes/)

## W 厄影回锋

先向指定方向刺出长刀，再将被命中的敌人拉向亚恒。客户端记录施法时间 **0.5 秒**。

| 命中阶段 | 原始物理伤害 |
| --- | --- |
| 第一段戳刺 | 40 / 60 / 80 / 100 / 120 + 50% 额外 AD |
| 第二段拉回 | 30 / 50 / 70 / 90 / 110 + 30% 额外 AD |
| 两段合计 | 70 / 110 / 150 / 190 / 230 + 80% 额外 AD |

[中文技能提示](https://ddragon.leagueoflegends.com/cdn/16.23.1/data/zh_CN/champion/Zaahen.json) · [客户端 W 公式](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/zaahen.bin.json) · [26.6 二段伤害调整](https://www.leagueoflegends.com/en-us/news/game-updates/league-of-legends-patch-26-6-notes/#zaahen)

### W 前摇与命中帧

W 是一次有前摇的施法。以施法开始为 **第 0 帧**，客户端 `mCastTime = 0.5` 秒，对应 **30 FPS 的第 15 帧、60 FPS 的第 30 帧**。若把开始画面编号为第 1 帧，表中的帧号统一加 1。

| 事件 | 从施法开始算 | 30 FPS | 60 FPS |
| --- | ---: | ---: | ---: |
| 前摇结束、开始刺出 | 0.500 秒 | 15 | 30 |
| 第一段命中约 425 单位处的目标 | 约 0.647 秒 | 约 19 | 约 39 |
| 刺击到 850 单位终点，第二段开始拉回 | 约 0.793 秒 | 约 24 | 约 48 |

第一段随刺击命中，时间按 `0.5 + 目标距刺击起点的距离 / 2900` 估算。第二段按到达 850 单位终点估算。这里使用弹体规格 `mMissileSpec.movementComponent.mSpeed = 2900`，同一记录另有 `missileSpeed = 1600`。表中的帧数按时间四舍五入，目标体积、弹体起点和结算时点都可能造成偏差。[16.23 客户端 W 数据](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/zaahen.bin.json) · [Riot W 演示](https://lol.dyn.riotcdn.net/x/videos/champion-abilities/0904/ability_0904_W1.mp4)

Riot 的 W 演示源片为 **60 FPS**。以画面中亚恒开始起手的约 **0.77 秒**为第 0 帧，约 **1.28 秒**可见刺出（第 **31** 帧），约 **1.60 秒**可见目标开始被拉动（第 **50** 帧）。这两个帧号是演示中的视觉标记。视频没有显示伤害结算时点，也无法用于确定服务器帧号。[Riot W 演示原片](https://lol.dyn.riotcdn.net/x/videos/champion-abilities/0904/ability_0904_W1.mp4)

客户端还记录 `castFrame = 7.5`、`spellCastTime = 0.25` 和 `spellTotalTime = 1.0`。原皮动画中，带 W 预警特效的 `Spell2` 片段把朝向锁定事件标在内部第 **16–18** 帧。以上字段和事件都不能直接当作第一段伤害或第二段拉回的结算帧。[客户端技能记录](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/zaahen.bin.json) · [原皮动画事件](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/animations/skin0.bin.json)

## E 赤金突袭

E 分为**突袭**和**挥砍**两个阶段。亚恒先向指定位置冲刺，到达落点后才以自身为圆心挥砍，伤害在落点周围结算。[Riot 中文技能提示](https://ddragon.leagueoflegends.com/cdn/16.23.1/data/zh_CN/champion/Zaahen.json) · [Riot E 演示](https://lol.dyn.riotcdn.net/x/videos/champion-abilities/0904/ability_0904_E1.mp4)

### 突袭速度与移动距离

客户端 `DashSpeed` 为固定 **900 单位/秒**，技能数据未列出普通移速加成项。无地形阻挡或中断时，直线模型用 `冲刺距离 = min(起点到指向点的距离, 350)`，`冲刺用时 = 实际位移距离 / 900`。指向较近位置可以缩短位移与用时。[16.23 客户端 E 数据](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/zaahen.bin.json)

| 实际位移 | 理论冲刺用时 |
| ---: | ---: |
| 100 单位 | 0.111 秒 |
| 200 单位 | 0.222 秒 |
| 350 单位（最远） | 0.389 秒 |

满距离的纯位移用时约合 **11.7 帧（30 FPS）或 23.3 帧（60 FPS）**。这是由速度和距离换算的时间，挥砍画面和伤害结算可能出现在不同帧。客户端施法时间字段 `spellCastTime` 为 `0`。[16.23 客户端 E 数据](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/zaahen.bin.json)

### 落点伤害范围与内外圈

令 `r` 为目标中心到**实际落点**的平面距离。下面用中心点模型区分内外圈，目标碰撞体和实际落点可能影响边界命中。外圈的物理伤害为内圈的 **1.5 倍**，并额外造成魔法伤害。[中文技能提示](https://ddragon.leagueoflegends.com/cdn/16.23.1/data/zh_CN/champion/Zaahen.json) · [客户端 E 半径及伤害公式](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/zaahen.bin.json)

| 命中位置 | 原始物理伤害 | 原始魔法伤害 |
| --- | --- | --- |
| 内圈，`r ≤ 200` | 40 / 60 / 80 / 100 / 120 + 50% 额外 AD | — |
| 外圈，`200 < r ≤ 375` | 60 / 90 / 120 / 150 / 180 + 75% 额外 AD | 目标最大生命值的 4% / 4.5% / 5% / 5.5% / 6% |
| 圈外，`r > 375` | — | — |

沿冲刺方向位移满 **350** 单位时，从起点算，正前方最远的内圈边界为 **550**，外圈边界为 **725**。例如，正前方 **500** 单位的目标距落点 **150**，属于内圈。正前方 **650** 单位的目标距落点 **300**，属于外圈。**725** 是冲刺叠加伤害圆的理论覆盖上限，角色的位移上限仍为 **350**。

客户端还记录了对野怪 **50** 点额外伤害和外圈百分比伤害对野怪的 **400** 点上限。[客户端 E 数据](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/zaahen.bin.json) · [26.6 野怪伤害调整](https://www.leagueoflegends.com/en-us/news/game-updates/league-of-legends-patch-26-6-notes/#zaahen)

## R 大赦

- **被动**提供 **10% / 20% / 30%** 护甲穿透。
- **主动**跃至目标地点，落地冲击对附近敌人造成 `250 / 400 / 550 + 200% × 额外 AD` 物理伤害。客户端记录起手施法时间为 **0.5 秒**，施放期间减伤 **50%**。
- **回复**只按命中的敌方英雄计算，技能提示给出的系数为 **33%**。以原始技能伤害做纸面估算时，每命中一名英雄为 `82.5 / 132 / 181.5 + 66% × 额外 AD`，实战的护盾和减疗交互需要单独验证。

[中文技能提示](https://ddragon.leagueoflegends.com/cdn/16.23.1/data/zh_CN/champion/Zaahen.json) · [客户端 R 公式](https://raw.communitydragon.org/16.23/game/data/characters/zaahen/zaahen.bin.json)

## 版本差异与算例

- **26.22** 缩短了 Q 前四级的冷却。**26.23** 公告中亚恒的承伤倍率从 100% 调至 105%，这项改动列在 **ARAM: Mayhem** 部分。上文采用召唤师峡谷数值。[26.22 官方公告](https://www.leagueoflegends.com/en-us/news/game-updates/league-of-legends-patch-26-22-notes/) · [26.23 官方公告](https://www.leagueoflegends.com/en-us/news/game-updates/league-of-legends-patch-26-23-notes/)
- **满级 E 算例**中，亚恒有 100 额外 AD，敌方有 2000 最大生命。内圈为 **170 物理伤害**，外圈为 **255 物理伤害 + 120 魔法伤害**，两种伤害分别计算减免。
- **三级 R 算例**中，100 额外 AD 对应 **750 原始物理伤害**。按 33% 系数估算，命中两名敌方英雄合计回复 **495 生命值**，受实际治疗交互影响。
