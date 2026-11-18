# 测试3d平台跳跃

通过 [map_select.tscn](map_select.tscn) 选择赛道或陷阱房，亦可直接在编辑器打开地图。

## 平台跳跃长赛道

`maps/` 下的场景可直接在 Godot 编辑器打开并按 F6 运行。8 张地图均为多玩家实体共享的一条连续赛道，默认 2 人，根节点 `player_count` 可设为 1–4；统一准备倒计时 5 秒、比赛限时 450 秒（7 分 30 秒）。根节点 Inspector 仍可调整时间、移动、跳跃和惯性参数。

本版将原有机关段组合为 7–16 段长路线，增加段间连接道、进度门、段数标牌和主题背景，以约 5 分钟一局为调节目标。自动路线时间用于确认长度与可达性，不代表真人平均成绩；失误、探路和多人阻挡仍需试玩调节。

| 地图场景 | 段数 | 主题装饰 | 自动路线耗时 |
| --- | ---: | --- | ---: |
| [carnival_rush.tscn](maps/carnival_rush.tscn) | 10 | 彩色气球、旗杆、横幅 | 4:23 |
| [glacier_drift.tscn](maps/glacier_drift.tscn) | 7 | 冰山、雪帽、冷色天空 | 5:01 |
| [clockwork_ascent.tscn](maps/clockwork_ascent.tscn) | 14 | 工业支架、管道、警示灯 | 4:58 |
| [jungle_fork.tscn](maps/jungle_fork.tscn) | 16 | 树冠、树干、遗迹石柱 | 4:57 |
| [lighthouse_loop.tscn](maps/lighthouse_loop.tscn) | 12 | 连续灯塔、海礁、云层与海面底景 | 4:46 |
| [neon_skyline.tscn](maps/neon_skyline.tscn) | 13 | 发光圆环、灯柱、紫色背景 | 4:40 |
| [rooftop_relay.tscn](maps/rooftop_relay.tscn) | 15 | 远景高楼、发光窗带 | 4:49 |
| [toy_tempo.tscn](maps/toy_tempo.tscn) | 13 | 彩色积木、玩具球 | 4:43 |

所有背景为原生可编辑场景节点，无需外部素材下载。公共机关段位于 `res://games/assets/GP_platformer_3d_components/maps/sections/`，主地图保存每段位置、主题装饰和顺序检查点；修改机关段会作用于其全部实例。装饰不参与物理碰撞，连接道侧边条是视觉边界，坠落仍会触发复活。



## 俯视陷阱房

打开 [trap_room.tscn](top_down/trap_room.tscn) 按 F6。镜头沿用人物系统 `StandardViewRig` 的 `TOP_DOWN` 模式，由 `StandardTopDownView` 以透视投影跟随本机控制的角色；距离、FOV、俯仰角来自角色预设的 Camera / Top Down 配置。只用 WASD 按屏幕方向跑动；没有跳跃、冲刺、交互、鼠标瞄准、缩放或视角切换。默认 3 秒准备、5 分钟生存回合、3 点生命，受击后有 1.2 秒无敌闪烁；所有人淘汰或时间到即结算，单独预览地图时 5 秒后自动重开，小游戏模式进入结算。存活者优先，淘汰者按存活时长排序，存活者按剩余生命排序。

复用 `character_system` 角色、静态碰撞平台、炮台造型、炮弹扫掠碰撞和伤害资源。陷阱预制体位于 `GP_platformer_3d_components/top_down/`。

| 预制体 | 行为与可调参数 |
| --- | --- |
| `laser_trap.tscn` | 黄色地面条预警后发射红色激光；可调长度、宽度、预警、发射时长、冷却、首次延迟与伤害资源 |
| `trap_emitter.tscn` | 预警时锁定直射方向，再发射炮弹；可调预警时长、弹速、寿命、弹体场景和伤害资源 |
| `weak_missile.tscn` | 低速、有限转向追踪，默认每秒最多 30°、制导 2.5 秒，之后直飞；目标淘汰后也直飞 |
| `saw_bomb.tscn` | 锁定地面圆形落点，预警后落下旋转锯盘；落地才伤害，短暂停留后消失，可调半径、落高和各阶段时长 |

房间根节点 Inspector 暴露跑速、生命、无敌时间、人数、回合与重开时间、三类发射间隔和最终频率倍率；攻击逐渐变密，预警时长和弹速保持不变。激光参数在 `Lasers` 各子节点调整，发射参数在 `Emitters` 子节点调整。

默认 `player_count = 1`，仍使用同一多人实体流程，可设为 1–4。`keyboard_player_index` 指定唯一接收本机 WASD 的玩家，其他实体通过 `racers[index].set_motion_input(direction)` 接入控制；未注入输入时原地待命，无自动机器人、分屏或网络同步。所有实体都强制使用跑步速度，传入跳跃或冲刺请求也不会生效。
