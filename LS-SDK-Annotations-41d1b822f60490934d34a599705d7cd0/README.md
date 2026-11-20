# LS SDK Annotations 开发环境

本仓库是 LS 脚本平台的 Lua 类型注解 SDK（EmmyLua / LuaLS 格式），配合语言服务器可获得完整的代码补全、类型检查和跳转。

## 环境配置

1. 安装 [VS Code](https://code.visualstudio.com/)
2. 安装 [Lua (sumneko.lua)](https://marketplace.visualstudio.com/items?itemName=sumneko.lua) 扩展（打开本目录时会自动推荐）
3. 用 VS Code 打开本目录即可 —— 根目录的 `.luarc.json` 已配置好:
   - 运行时: LuaJIT
   - 已关闭因 SDK 函数重载产生的误报（`duplicate-set-field` 等）

无需额外步骤，打开任意 `.lua` 文件即可获得 SDK 全局类型（`Game`、`Callback`、`Renderer`、`Menu` 等）的智能提示。

## Demo

示例脚本位于 [demo/DemoScript.lua](demo/DemoScript.lua)，演示了：

| 模块 | 内容 |
| --- | --- |
| `Menu` | 复选框、滑条、按键绑定、下拉列表、颜色选择器 |
| `Callback` | `OnTick` 逻辑、`OnDraw` D3D 绘制、`OnImguiDraw` ImGui 绘制、`OnUnload` 清理 |
| `SDKSpell` | 创建技能实例、直线技能弹预测施法 |
| `TargetSelector` / `ObjectManager` | 最佳目标选择、敌方英雄遍历 |
| `Renderer` | 范围圈、连线、世界文字 |

使用方法：将 `DemoScript.lua` 复制到脚本平台的脚本目录加载（脚本依赖游戏内运行时，无法在本地 Lua 解释器中直接执行）。

## 目录结构

```
├── callbacks/                 # 回调系统与事件类型
├── class/                     # 游戏对象类 (AIHeroClient, SpellBook 等)
├── enums/                     # 枚举 (SpellSlot, DamageType 等)
├── environment/               # 脚本环境
├── library/                   # 内置库 (bit, clipper, queue)
├── math/                      # 数学库 (Vector2/3/4)
├── renderer/                  # 渲染 (D3D 与 ImGui)
├── sdk-types-and-functions/   # SDK 高级功能 (预测/躲避/菜单/走砍等)
├── game.lua                   # Game 全局函数
├── objectmanager.lua          # 对象管理器
└── demo/DemoScript.lua        # 演示脚本
```
