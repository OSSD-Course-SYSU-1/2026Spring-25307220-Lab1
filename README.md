# 窗口方向 — 鸿蒙多设备窗口旋转策略演示应用

> HarmonyOS 6.0.2+ | DevEco Studio 6.1.0+ | API 22 | 编译通过 ✅ 0 错 0 警告

## 项目简介

本示例以窗口旋转策略实现的高频场景为载体，通过窗口级配置实现多设备的窗口方向变化。项目最初包含 9 个功能模块，**我们在此基础上新增了隔空投送、自由流转两个分布式能力演示模块，并对全部页面进行了大小屏适配改造**。当前共计 **11 个功能模块**：

- 原有 8 个：应用首页（Home）、竖屏游戏（Portrait）、横屏游戏（Landscape）、图库（Photos）、股票详情（Stock）、视频详情（Video）、多窗口协作（MultiWindow）、旋转事件日志（OrientationLog）
- 原有 1 个（扩写）：2048 数字拼图（Game2048）
- **我们新增 2 个**：隔空投送（NearbyShare）、自由流转（FreeFlow）

---

## ⚠️ 首次编译必读

### 1. 安装 ohpm 依赖

在 DevEco Studio 中打开项目后，点击 **Sync** 或菜单栏 `Build → Build Hap(s)` 触发 ohpm install。首次 `products/default/oh_modules/` 为空是正常的，Sync 后自动生成。

### 2. 确保入口模块未被 gitignore 屏蔽

旧版 `.gitignore` 中 `/products/` 会阻止入口模块提交，**已修复**。当前版本只忽略 `/products/build/`。

### 3. 所有 HAR 模块必须声明 deviceTypes

每个 `features/*/src/main/module.json5` 必须包含 `"deviceTypes": ["default"]`，否则编译报错 `00303194 Configuration Error`。

---

## 功能模块总览

| 模块 | 入口名称 | 窗口策略 | 断点适配 | 说明 |
|------|---------|---------|:---:|------|
| Home | 应用首页 | FOLLOW_DESKTOP | ✅ | 首页 Tabs + 瀑布流，侧边栏/底部导航自适应 |
| PortraitModeGame | 竖屏游戏 | FIXED PORTRAIT | ✅ **改造** | 锁定竖屏；列数 4~12 随断点变化 |
| LandscapeModeGame | 横屏游戏 | FIXED LANDSCAPE | ✅ **改造** | 锁定横屏；圆形尺寸+间距随断点缩放 |
| Photos | 图库 | AUTO_ROTATION | ✅ **改造** | lanes 2~6 列随断点动态切换 |
| StockDetail | 股票详情 | FOLLOW_DESKTOP | ✅ 原有 | 图表高度+边距 BreakpointType 自适应 |
| VideoDetail | 视频详情 | AUTO/LANDSCAPE_RESTRICTED | ✅ 原有 | GridRow + 全屏检测 + 折叠屏适配 |
| MultiWindowDemo | 多窗口协作 | FOLLOW_DESKTOP | ✅ 原有 | 模拟多窗口 + 实时录制旋转事件 |
| OrientationLog | 旋转事件日志 | — | ✅ **改造** | 时间轴 + 统计面板；Label 宽度响应式 |
| Game2048 | 2048 拼图 | FOLLOW_DESKTOP | ✅ **改造** | 棋盘缩放；大屏时棋盘+按钮左右并排 |
| **NearbyShare** 🆕 | **隔空投送** | FOLLOW_DESKTOP | ✅ | **我们新增**，设备发现+内容选择+传输+历史记录 |
| **FreeFlow** 🆕 | **自由流转** | FOLLOW_DESKTOP | ✅ | **我们新增**，状态快照+流转模拟+AppStorage 共享 |

---

## 核心功能详解（我们新增/改造）

### 隔空投送（NearbyShare）— 我们新增 🆕

模拟鸿蒙设备间的内容发现与传输：

- **设备发现**：雷达扫描动画 + 6 种模拟设备（手机/平板/折叠屏/笔记本/车机/智慧屏），分阶段逐条发现
- **真实 API 预留**：`DeviceDiscoveryManager` 通过 `canIUse()` 检测分布式能力，真机可用时自动切换到 `distributedDeviceManager`（当前模拟器走模拟降级路径）
- **内容选择**：底部 Sheet — 文本消息（可编辑）、游戏最高分、旋转事件日志
- **传输过程**：进度条 + 速度指示 + 成功面板动画
- **传输历史**：设备名、内容类型、文件大小、耗时、成功/失败状态
- **大屏适配**：LG+ 断点下设备列表与历史面板左右并排

### 自由流转（FreeFlow）— 我们新增 🆕

模拟鸿蒙设备间的无缝任务接续：

- **状态管理**：文本内容 + 计数器 + 滚动位置，使用 `FlowState` class + `FlowState.copy()` 模式
- **快照系统**：保存/加载/删除当前应用状态快照
- **流转模拟**：选择目标设备 → 流转动画 → 完成确认；接收流转（模拟从其他设备恢复状态）
- **真实接续预留**：`EntryAbility` 已实现 `onContinue()`（序列化 → `wantParam`）和 `onCreate()`（恢复 → `AppStorage`），`module.json5` 已配置 `"continuable": true`。真机上系统自动接管设备选择 UI
- **大屏适配**：LG+ 断点下状态面板与控制区左右并排

### 适应大小屏 — 我们改造 ✅

我们在原有项目基础上对以下模块进行了响应式布局改造：

| 模块 | 改造前 | 改造后 |
|------|--------|--------|
| Game2048 | 棋盘固定 72vp | `cellSize()` 随断点 56~94vp；LG+ 时棋盘+按钮左右并排 |
| PortraitModeGame | 固定 8 列 | 列数 4/6/8/10/12 随断点动态切换 |
| LandscapeModeGame | 圆形固定 128vp | 72~180vp 随断点缩放；间距+padding 同步适配 |
| Home | padding 固定 16px | `BreakpointType(12,16,24,32,32)` |
| Photos | lanes 固定 (4,2) | `BreakpointType(2,3,4,5,6)` 动态列数 |
| OrientationLog | label 固定 120vp | `BreakpointType(80,100,140,160,180)` |

### 窗口旋转策略工具（WindowOrientationHelper）

19 种策略枚举 + 三层决策模型（固定/自动/跟随桌面）+ 元数据查询 + 链式调用。所有页面进入时设置策略，退出时恢复 `FIXED.UNSPECIFIED`（锁定当前方向）。

---

## 工程目录（完整）

```
WindowOrientation-master/
├── .gitignore                     # 已修复：/products/ 不再忽略
├── build-profile.json5            # 根构建配置，注册 12 个模块
├── README.md                      # 本文件
├── docs/DEV_NOTES.md              # 从 6 轮 ERROR_REPORT 沉淀的 10 条避坑规则
│
├── commons/base/                  # 公共工具库（HAR）
│   └── src/main/ets/
│       ├── constants/             # BreakpointConstants, CommonConstants, DetailConstants
│       └── utils/                 # BreakpointType, Logger, WindowOrientationHelper,
│                                  #   OrientationLogger, AvPlayerUtil, DeviceScreen, DisplayUtil
│
├── features/                      # 11 个功能 HAR 模块
│   ├── home/                      # 应用首页
│   ├── portrait/                  # 竖屏游戏
│   ├── landscape/                 # 横屏游戏
│   ├── photos/                    # 图库
│   ├── stock/                     # 股票详情 (含 @ohos/mpchart 图表)
│   ├── video/                     # 视频详情 + 全屏播放
│   ├── multiwindow/               # 多窗口协作
│   ├── orientationlog/            # 旋转事件日志
│   ├── game2048/                  # 2048 数字拼图
│   ├── nearbyshare/    🆕         # 隔空投送（我们新增）
│   └── freeflow/       🆕         # 自由流转（我们新增）
│
└── products/default/              # 入口模块（HAP）
    └── src/main/
        ├── module.json5           # EntryAbility + INTERNET + DISTRIBUTED_DATASYNC 权限
        ├── ets/
        │   ├── entryability/      # EntryAbility (断点初始化 + onContinue/onCreate)
        │   ├── pages/             # Index.ets (11 张卡片入口 + NavPathStack 导航)
        │   ├── model/             # CardListModel
        │   └── viewmodel/         # CardListViewModel (11 个功能入口)
        └── resources/base/profile/
            ├── main_pages.json
            └── backup_config.json
```

---

## 技术栈

| 技术点 | 说明 |
|-------|------|
| 架构 | 1 HAP（Entry）+ 1 HAR（commons）+ 11 HAR（features） |
| 路由 | Navigation + NavPathStack + HAR router_map |
| 响应式 | BreakpointType\<T\>（XS/SM/MD/LG/XL 五级断点）|
| 状态管理 | @State, @StorageLink, @Provide/@Consume, AppStorage |
| 数据持久化 | Preferences（旋转日志、2048 最高分、流转快照） |
| 窗口管理 | window.Window API（setPreferredOrientation） |
| 分布式能力 | DeviceDiscoveryManager（canIUse 检测 + 模拟降级）；EntryAbility onContinue/onCreate（流转） |
| 手势处理 | PanGesture 滑动识别 |
| 图表 | @ohos/mpchart（股票 K 线图） |

---

## 编译与运行

### 环境要求

| 项目 | 版本 |
|------|------|
| HarmonyOS SDK | 6.1.0 Release (API 23, 兼容 6.0.2/API 22) |
| DevEco Studio | 6.1.0 Release+ |
| 设备类型 | 手机、折叠屏、平板、2in1 |

### 首次编译

1. 打开 DevEco Studio → Open Project → 选择本目录
2. 等待 IDE 自动 Sync（安装 ohpm 依赖到 `products/default/oh_modules/`）
3. `Build → Build Hap(s)` 或 Ctrl+F9
4. 选择模拟器/Previewer 运行

### 常见编译错误

| 错误码 | 现象 | 解决 |
|--------|------|------|
| `00303149` | Path not found: products/default | `.gitignore` 中 `/products/` 不能忽略 |
| `00303194` | Unable to obtain deviceTypes | HAR 模块 `module.json5` 加 `"deviceTypes": ["default"]` |
| `00305015` | Unexpected token (动态 import) | ArkTS 不支持 `import()` 表达式，用静态 import |
| `10605099` | arkts-no-spread | 禁止 `...obj` 展开；状态对象用 class + 逐字段赋值 |
| `10605144` | arkts-limited-stdlib | `Object.assign` 也被禁止 |
| `10903329` | Unknown resource name (sys.symbol) | HAR 模块不认 `$r('sys.symbol.xxx')`，改用 Unicode 或自定义图标 |
| `10505001` | layoutWeight on Builder | `@Builder` 返回不能 `.layoutWeight()`，用 Column/Row 包裹 |

---

## 权限声明

| 权限 | 用途 | 状态 |
|------|------|:--:|
| `ohos.permission.INTERNET` | 网络访问 | ✅ 已声明 |
| `ohos.permission.DISTRIBUTED_DATASYNC` | 分布式数据同步 + 设备发现 | ✅ 已声明 |
| `ohos.permission.GET_BLUETOOTH_PEERS_MAC` | 蓝牙设备发现（NearbyShare 真实 API 需要） | ⚠️ 真机时补充 |

---

## ⚠️ 注意事项（10 条实战经验）

> 以下规则从本项目 6 轮 DevEco Studio 错误报告中沉淀，详见 `docs/DEV_NOTES.md`。

1. **`.gitignore` 不能屏蔽 `/products/`** — 入口模块是编译入口，屏蔽将导致 `00303149` 错误
2. **HAR 模块必须声明 `deviceTypes`** — 每个 `module.json5` 都要 `"deviceTypes": ["default"]`
3. **首次打开必须 IDE Sync** — `oh_modules` 不会自动生成，需手动触发
4. **`$r('sys.symbol.xxx')` 在 HAR 模块不可用** — 改用 Unicode emoji 或自定义图标资源
5. **ArkTS 严格模式禁止 spread 和 Object.assign** — 状态对象用 `class` + 静态 `copy()` 方法
6. **动态 `import()` 不支持** — 用静态 `import`，运行时 `canIUse()` 检测
7. **`@Builder` 返回值不能 `.layoutWeight()`** — 在 Builder 内层或包裹的 Column/Row 上设置
8. **Entry 模块用 `"pages"`，HAR 模块用 `"routerMap"`** — 字段名不同，混用导致路由失效
9. **断点系统必须在 `EntryAbility.onWindowStageCreate` 中初始化** — `windowSizeChange` 事件监听
10. **分布式 API 必须 `canIUse()` 运行时检测 + 模拟降级** — 模拟器/Previewer 不支持分布式能力

---

## 约束与限制

1. 支持设备：直板机、双折叠、三折叠、平板、2in1
2. HarmonyOS: 6.1.0 Release+
3. DevEco Studio: 6.1.0 Release+
4. 隔空投送与自由流转的**真实分布式 API** 需在真机上验证（模拟器使用模拟降级路径）
5. `@ohos/mpchart` 图表库仅在 stock 模块使用，为第三方依赖
