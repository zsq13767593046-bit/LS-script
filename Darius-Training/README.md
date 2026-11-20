# 德莱厄斯英雄属性与 Lua 脚本设计

适用范围为 PC 版《英雄联盟》召唤师峡谷 **26.23**，对应 Data Dragon **16.23.1**。德莱厄斯是使用法力的近战战士兼坦克，英雄 ID 为 `Darius`，数字 ID 为 `122`。脚本根据手动输入计算属性、技能伤害和治疗，用于离线练习和复盘。[26.23 版本公告](https://www.leagueoflegends.com/en-us/news/game-updates/league-of-legends-patch-26-23-notes/) · [Riot 英雄页](https://www.leagueoflegends.com/en-us/champions/darius/) · [Data Dragon 中文英雄数据](https://ddragon.leagueoflegends.com/cdn/16.23.1/data/zh_CN/champion/Darius.json)

## 基础属性

| 属性 | 1 级 | 成长系数 | 18 级 |
| --- | ---: | ---: | ---: |
| 生命值 | 652 | +114 | 2590 |
| 法力值 | 263 | +58 | 1249 |
| 攻击力 | 64 | +5 | 149 |
| 护甲 | 37 | +5.2 | 125.4 |
| 魔抗 | 32 | +2.05 | 66.85 |
| 生命回复 / 5 秒 | 10 | +0.95 | 26.15 |
| 法力回复 / 5 秒 | 6.6 | +0.35 | 12.55 |
| 攻速（次/秒） | 0.625 | +1% | 0.73125 |
| 移动速度 | 340 | — | 340 |
| 普攻距离 | 175 | — | 175 |
| 暴击率 | 0% | — | 0% |

表中数值不计装备、符文和增益。Data Dragon 的攻击力成长字段为 `0`，同版本客户端英雄记录 `damagePerLevelModifiable.baseValue` 为 `5`，脚本采用后者。攻速成长的百分比乘以攻速系数 `0.625` 后计入攻速。[Data Dragon 16.23.1](https://ddragon.leagueoflegends.com/cdn/16.23.1/data/zh_CN/champion/Darius.json) · [16.23 客户端英雄记录，CommunityDragon 镜像](https://raw.communitydragon.org/16.23/game/data/characters/darius/darius.bin.json)

对于等级 `L`，累计成长倍率为 `(L − 1) × (0.685 + 0.0175 × L)`。例如 2 级获得 0.72 份成长，18 级累计获得 17 份成长。[Riot 4.20 成长规则存档](https://lol.fandom.com/wiki/Patch_4.20)

## 技能属性

| 技能 | 基础冷却（秒） | 法力 | 伤害与效果 |
| --- | --- | --- | --- |
| P 出血 | — | — | 持续 5 秒，最多 5 层。每层完整持续时间造成 `12 + 英雄等级 + 0.30 × 额外 AD` 的原始物理伤害，对野怪乘 2.5。 |
| Q 大杀四方 | 9 / 7.75 / 6.5 / 5.25 / 4 | 25 / 30 / 35 / 40 / 45 | 斧刃造成 50 / 80 / 110 / 140 / 170 加 100% / 110% / 120% / 130% / 140% 总 AD 的物理伤害。斧柄伤害为斧刃的 35%，且不叠出血。斧刃每命中一个敌方英雄或大型野怪，回复 17% 已损失生命，最多 51%。 |
| W 致残打击 | 5 | 40 | 强化下一次普攻，整次攻击造成 140% / 145% / 150% / 155% / 160% 总 AD 的物理伤害，减速 90% 持续 1 秒。击杀目标返还法力并缩短 50% 冷却。 |
| E 无情铁手 | 26 / 23.5 / 21 / 18.5 / 16 | 70 / 60 / 50 / 40 / 30 | 被动获得 20% / 25% / 30% / 35% / 40% 护甲穿透。主动拉近并击飞锥形范围内敌人，附加 40% 减速 1 秒。Data Dragon 标示距离为 535。 |
| R 诺克萨斯断头台 | 120 / 100 / 80 | 100 / 100 / 0 | 对目标英雄造成 `(基础伤害 + 0.75 × 额外 AD) × (1 + 0.20 × 出血层数)` 真实伤害。基础伤害为 125 / 250 / 375。击杀后可在 20 秒内再次施放，3 级 R 击杀会完全刷新冷却。Data Dragon 标示距离为 460。 |

[Data Dragon 技能数据](https://ddragon.leagueoflegends.com/cdn/16.23.1/data/zh_CN/champion/Darius.json) · [16.23 客户端技能公式](https://raw.communitydragon.org/16.23/game/data/characters/darius/darius.bin.json) · [25.14 Q 治疗改动](https://www.leagueoflegends.com/en-gb/news/game-updates/patch-25-14-notes/) · [26.4 出血对野怪改动](https://www.leagueoflegends.com/en-ph/news/game-updates/league-of-legends-patch-26-4-notes/)

对敌方英雄叠满出血或用 R 击杀英雄后，会获得诺克萨斯之力。生效期间，通过原本能叠出血的攻击及技能施加满层出血，额外攻击力随等级由 30 增至 230。具体为 1 级 +30，2–10 级每级再加 5，11–13 级每级再加 10，14–18 级每级再加 25。[Riot 英雄页](https://www.leagueoflegends.com/en-us/champions/darius/) · [11.14 诺克萨斯之力改动](https://www.leagueoflegends.com/en-gb/news/game-updates/patch-11-14-notes/) · [16.23 客户端计算断点](https://raw.communitydragon.org/16.23/game/data/characters/darius/darius.bin.json)

26.21 公告将 Q 冷却写为 `9 / 8 / 7 / 6 / 4`。脚本使用 26.23 对应的 Data Dragon 导出值 `9 / 7.75 / 6.5 / 5.25 / 4`。这些是离线计算的版本依据，未用实战计时裁定公告差异。[26.21 公告](https://www.leagueoflegends.com/en-us/news/game-updates/league-of-legends-patch-26-21-notes/) · [Data Dragon 16.23.1](https://ddragon.leagueoflegends.com/cdn/16.23.1/data/zh_CN/champion/Darius.json)

## 脚本设计

- **输入由玩家提供。** `stats` 用等级查看基础属性，`p`、`q`、`w`、`e`、`r` 分别计算每个技能。脚本在本地命令行运行。
- **区分总 AD 与额外 AD。** Q 和 W 读取总 AD，P 和 R 读取额外 AD。如果诺克萨斯之力已经生效，传入的攻击力需要包含该增益。出血以输入层数及额外 AD 在整段持续时间内固定为假设，输出完整持续时间的原始伤害。
- **Q 分开显示斧刃与斧柄伤害。** 恢复量只按斧刃命中的合格单位数算，并将目标数上限设为 3。这样可以直接对比贴身与外圈命中的结果。
- **E 展示护甲穿透的单独作用。** 脚本用 `护甲 × (1 − E 穿透比例)` 计算有效护甲，再用 `100 / (100 + 有效护甲)` 计算物理伤害保留比例。模型接受非负护甲，未计入其他穿透或削减。
- **R 对比层数与伤害余量。** 省略层数可并排查看 0–5 层的伤害。给定单个层数时，可以输入当前生命和能吸收真实伤害的护盾，查看理论伤害差额。模型未计入免死、无敌、特殊伤害规则、其他伤害来源或施法期间发生的变化。

## 运行方式

在有 `lua` 或 `luajit` 的终端进入 `D:\code\Darius-Training`。脚本使用标准 Lua，不依赖第三方 Lua 库。

```powershell
cd D:\code\Darius-Training
lua darius.lua --help
lua darius.lua stats 18
lua darius.lua p 18 100 5 monster
lua darius.lua q 5 200 600 3
lua darius.lua w 3 200
lua darius.lua e 5 100
lua darius.lua r 3 100
lua darius.lua r 3 100 5 800 50
```

例如 Q 的斧刃原始伤害为 450、斧柄为 157.5，三次合格命中回复 306。R 在 3 级、100 额外 AD、5 层出血时造成 900 真实伤害，扣除 800 生命与 50 适用护盾后理论余量为 50。
