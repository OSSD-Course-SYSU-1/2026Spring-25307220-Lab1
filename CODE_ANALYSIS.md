# WindowOrientation 项目代码工程解析

---

## 一、项目概要

| 属性 | 值 |
|------|-----|
| **Bundle Name** | `com.example.windoworientation` |
| **版本** | 1.0.0 (versionCode: 1000000) |
| **SDK 版本** | HarmonyOS API 22 (6.0.2) |
| **目标设备** | Phone + Tablet |
| **核心主题** | **窗口旋转策略** 演示应用 |

---

## 二、项目架构：分层多模块设计

```
WindowOrientation-master/
├── AppScope/                             # 应用全局配置
│   └── app.json5                         # bundleName、版本、图标
│
├── products/default/                     # 【Entry 模块 — HAP】应用入口
│   └── src/main/
│       ├── ets/
│       │   ├── entryability/EntryAbility.ets   # UIAbility 入口
│       │   ├── pages/Index.ets                 # 主导航页（卡片列表）
│       │   ├── model/CardListModel.ets         # 卡片数据模型
│       │   ├── viewmodel/CardListViewModel.ets # 卡片列表 ViewModel
│       │   └── defaultbackupability/           # 备份扩展能力
│       ├── module.json5                        # Entry 模块配置
│       └── resources/base/profile/main_pages.json  # 页面路由配置
│
├── commons/base/                         # 【HAR 公共模块】共享工具库
│   ├── Index.ets                         # 统一导出入口
│   └── src/main/ets/
│       ├── constants/
│       │   ├── CommonConstants.ets       # 通用常量
│       │   ├── BreakpointConstants.ets   # 响应式断点常量
│       │   └── DetailConstants.ets       # 视频/详情页常量
│       └── utils/
│           ├── WindowOrientationHelper.ets  # ★ 核心：窗口旋转策略助手
│           ├── AvPlayerUtil.ets             # 视频播放器封装
│           ├── BreakpointType.ets           # 泛型断点类型工具
│           ├── DeviceScreen.ets             # 屏幕尺寸获取
│           ├── DisplayUtil.ets              # 折叠屏折痕检测
│           ├── Logger.ets                   # 日志工具
│           └── CurrentOffsetUtil.ets       # 偏移量工具
│
└── features/                             # 【HAR 业务模块】6个子功能
    ├── home/      ├── portrait/   ├── landscape/
    ├── photos/    ├── stock/      └── video/
```

### 模块依赖关系

```
                    ┌──────────────────────┐
                    │  products/default    │  ← Entry（HAP）
                    │   入口模块            │
                    └──────────┬───────────┘
                               │ 依赖
              ┌────────────────┼─────────────────┐
              ▼                ▼                  ▼
      ┌──────────────┐  ┌──────────┐   ┌──────────────────┐
      │  commons/base│  │ features │   │ features/portrait │
      │    (HAR)     │◄─│  /home   │◄──│ features/landscape│
      │   公共工具库  │  │  (HAR)   │   │ features/photos   │
      └──────────────┘  └──────────┘   │ features/stock    │
                                        │ features/video    │
                                        └──────────────────┘
        ▲──────────────────────────────────────┘
        所有模块均依赖 commons/base
```

---

## 三、★ 核心：WindowOrientationHelper

**文件**：`commons/base/src/main/ets/utils/WindowOrientationHelper.ets`

这是整个项目的灵魂，封装了 HarmonyOS 窗口旋转的**三层决策模型**：

### 3.1 三层决策模型

```
第一层：是否支持旋转？
    ├── 固定方向 (fixed)         → 不支持旋转
    ├── 自动旋转 (autoRotate)    → 支持旋转，受限控制中心
    └── 跟随桌面 (followDesktop) → 继承桌面行为

第二层：支持哪些方向？（仅 autoRotate）
    ├── LANDSCAPE_ONLY     → 仅横屏（正向+反向）
    ├── PORTRAIT_ONLY      → 仅竖屏（正向+反向）
    └── ALL_ORIENTATIONS   → 所有方向

第三层：首选方向？（仅 ALL_ORIENTATIONS）
    ├── UNSPECIFIED       → 无首选
    ├── PORTRAIT          → 首选竖屏
    ├── LANDSCAPE         → 首选横屏
    ├── PORTRAIT_INVERTED → 首选反向竖屏
    └── LANDSCAPE_INVERTED→ 首选反向横屏
```

### 3.2 预置常量 `OrientationPresets`

采用**嵌套对象链式访问**直接获取 `window.Orientation` 枚举值：

```typescript
// 链式调用示例：
OrientationPresets.FOLLOW_DESKTOP                              // 跟随桌面
OrientationPresets.FIXED.PORTRAIT                              // 固定竖屏
OrientationPresets.FIXED.LANDSCAPE                             // 固定横屏
OrientationPresets.FIXED.UNSPECIFIED                           // 锁定当前方向
OrientationPresets.AUTO_ROTATE.LANDSCAPE_ONLY                  // 仅横屏自动旋转（受限）
OrientationPresets.AUTO_ROTATE.PORTRAIT_ONLY                   // 仅竖屏自动旋转（受限）
OrientationPresets.AUTO_ROTATE.ALL_ORIENTATIONS.UNSPECIFIED    // 全向自动旋转
OrientationPresets.AUTO_ROTATE.ALL_ORIENTATIONS.PORTRAIT       // 全向首选竖屏
OrientationPresets.AUTO_ROTATE.ALL_ORIENTATIONS.LANDSCAPE      // 全向首选横屏
```

### 3.3 类型定义一览

| 类型 | 用途 |
|------|------|
| `WindowOrientationType` | 方向类型联合：UNSPECIFIED / PORTRAIT / LANDSCAPE / PORTRAIT_INVERTED / LANDSCAPE_INVERTED |
| `AutoRotateRange` | 旋转范围：LANDSCAPE_ONLY / PORTRAIT_ONLY / ALL_ORIENTATIONS |
| `FixedConfig` | 固定配置：`{ mode: 'fixed', orientation?: ... }` |
| `AutoRotateConfig` | 自动配置：`{ mode: 'autoRotate', range, preferred? }` |
| `FollowDesktopConfig` | 桌面配置：`{ mode: 'followDesktop' }` |
| `OrientationConfig` | 联合配置类型：FixedConfig \| AutoRotateConfig \| FollowDesktopConfig |

### 3.4 选择器 API

| 方法 | 参数 | 功能 |
|------|------|------|
| `fixed(orientation?)` | 方向类型 | 固定方向选择器，缺省则锁当前方向 |
| `followDesktop()` | 无 | 跟随桌面旋转 |
| `autoRotate(range, preferred?)` | 范围 + 首选（可选） | 受限的自动旋转 |
| `autoRotateUnrestricted(range)` | 范围 | 不受限的自动旋转 |
| `select(config)` | 配置对象 | **通用选择器**，根据配置对象动态获取策略 |

### 3.5 辅助查询 API

| 方法 | 功能 |
|------|------|
| `describe(orientation)` | 获取策略详细描述对象 |
| `getName(orientation)` | 获取策略中文名称 |
| `isRestricted(orientation)` | 判断是否受控制中心旋转锁影响 |
| `getCategory(orientation)` | 获取策略分类 |
| `getAllOptions()` | 获取所有策略选项（供 UI 选择器使用） |
| `get presets` | 暴露预置常量对象 |

---

## 四、入口流程详解

### 4.1 EntryAbility 启动流程

```
应用启动
  ↓
EntryAbility.onCreate()
  ↓
EntryAbility.onWindowStageCreate(windowStage)
  ↓
windowStage.loadContent('pages/Index')     ← 加载主页面
  ↓
获取 MainWindow
  ├─ data.getUIContext()                   ← 获取 UI 上下文
  ├─ getWindowWidthBreakpoint()            ← 获取初始宽度断点 → AppStorage('widthBp')
  ├─ getWindowHeightBreakpoint()           ← 获取初始高度断点 → AppStorage('heightBp')
  └─ window.on('windowSizeChange', ...)   ← 监听窗口变化，实时更新断点
```

**关键代码**（EntryAbility.ets）：

```typescript
onWindowSizeChange: (windowSize: window.Size) => void = () => {
  let widthBp: WidthBreakpoint = this.uiContext!.getWindowWidthBreakpoint();
  AppStorage.setOrCreate(CommonConstants.WIDTH_BREAK_POINT, widthBp);
  let heightBp: HeightBreakpoint = this.uiContext!.getWindowHeightBreakpoint();
  AppStorage.setOrCreate(CommonConstants.HEIGHT_BREAK_POINT, heightBp);
}
```

### 4.2 主页面导航流程

```
Index.ets (Navigation + NavPathStack，Stack 模式)
│
└─ List (6个功能卡片)
   ├─ Card[0] → "首页"      pushPathByName("Home")            → features/home/Home
   ├─ Card[1] → "竖屏游戏"   pushPathByName("PortraitModeGame") → features/portrait/PortraitModeGame
   ├─ Card[2] → "横屏游戏"   pushPathByName("LandscapeModeGame") → features/landscape/LandscapeModeGame
   ├─ Card[3] → "照片"      pushPathByName("Photos")           → features/photos/Photos
   ├─ Card[4] → "股票"      pushPathByName("StockDetail")      → features/stock/StockDetail
   └─ Card[5] → "视频"      pushPathByName("VideoDetail")      → features/video/VideoDetail
```

### 4.3 数据模型

**CardListModel**：
```typescript
class CardListModel {
  title: ResourceStr;   // 卡片标题
  desc: string;         // 描述（策略简称）
  pathName: string;     // NavPathStack 路由名称
}
```

**CardListViewModel** — 生成 6 张卡片：
| 标题 | 描述 | 路由名称 |
|------|------|----------|
| 首页 | FOLLOW_DESKTOP | Home |
| 竖屏模式游戏 | PORTRAIT | PortraitModeGame |
| 横屏模式游戏 | LANDSCAPE | LandscapeModeGame |
| 照片 | AUTO_ROTATION_UNSPECIFIED | Photos |
| 股票详情 | FOLLOW_DESKTOP | StockDetail |
| 视频详情 | AUTO_ROTATION_LANDSCAPE_RESTRICTED | VideoDetail |

---

## 五、HAR 路由注册机制

每个功能 HAR 模块通过 `router_map.json` 注册其 Builder 函数：

| 路由名称 | 模块 | 注册文件 | Builder 函数 |
|----------|------|----------|-------------|
| `Home` | home | `router_map.json` | `HomeBuilder()` |
| `PortraitModeGame` | portrait | `router_map.json` | `PortraitModeGameBuilder()` |
| `LandscapeModeGame` | landscape | `router_map.json` | `LandscapeModeGameBuilder()` |
| `Photos` | photos | `router_map.json` | `PhotosBuilder()` |
| `StockDetail` | stock | `router_map.json` | `StockDetailBuilder()` |
| `ABAWindow` | stock | `router_map.json` | `ABAWindowBuilder()` |
| `VideoDetail` | video | `router_map.json` | `VideoDetailBuilder()` |

调用方式：
```typescript
this.pathStack.pushPathByName('Home', null);
```

---

## 六、各模块旋转策略总览

| 模块 | 进入策略 | 退出策略 | 是否受控 |
|------|---------|---------|:---:|
| **Home** | `FOLLOW_DESKTOP` | `FIXED.UNSPECIFIED`（锁当前） | ❌ |
| **PortraitModeGame** | `FIXED.PORTRAIT` | `FIXED.UNSPECIFIED`（锁当前） | ❌ |
| **LandscapeModeGame** | `FIXED.LANDSCAPE` | `FIXED.UNSPECIFIED`（锁当前） | ❌ |
| **Photos** | `AUTO_ROTATE.ALL.UNSPECIFIED` | `FIXED.UNSPECIFIED`（锁当前） | ✅ |
| **StockDetail** | `followDesktop()` | `FIXED.UNSPECIFIED`（锁当前） | ❌ |
| **VideoDetail** | `select(autoRotate, ALL, UNSPECIFIED)` | `select(autoRotate, ALL, UNSPECIFIED)` | ✅ |

---

## 七、VideoDetail — 最复杂策略场景

Video 模块实现了**全屏切换**和**窗口大小变化**时的动态策略切换：

```
                     页面初始化
                          │
         ┌────────────────┼────────────────┐
         ▼                                  ▼
  全向自动旋转                        监听 windowSizeChange
  autoRotate(ALL, UNSPECIFIED)              │
         │                          窄屏(WIDTH_SM) → 退出全屏
         │                          MD宽+SM高 → 进入全屏
         ▼
  @Watch('onFullScreenChange')
  监听 isFullScreen 变化
         │
    ┌────┴────┐
    ▼         ▼
  全屏       非全屏
  isClick?   autoRotate(ALL, UNSPECIFIED)
    │
    ├─ SM/LG宽或LG高 → LANDSCAPE_ONLY（仅横屏）
    │
    └─ 其他 → 不变
```

### 键盘快捷键支持

| 按键 | 功能 |
|------|------|
| `Space` | 播放/暂停切换 |
| `Esc` | 恢复窗口 `windowObj.recover()` |
| `方向右` | 快进 5 秒 |
| `方向左` | 快退 5 秒 |

---

## 八、响应式布局系统

### 8.1 断点定义

```
WidthBreakpoint:   WIDTH_XS(0) → WIDTH_SM(1) → WIDTH_MD(2) → WIDTH_LG(3) → WIDTH_XL(4)
HeightBreakpoint:  HEIGHT_SM(0) → HEIGHT_MD(1) → HEIGHT_LG(2)
```

### 8.2 BreakpointType 泛型工具

```typescript
class BreakpointType<T> {
  xs: T; sm: T; md: T; lg: T; xl: T;
  getValue(currentWidthBreakpoint: number): T { /* 根据断点返回值 */ }
}

// 使用示例：边距随断点变化
new BreakpointType(16, 16, 24, 32, 32).getValue(this.widthBp)
// 窄屏→16  常规→16  中等→24  宽屏→32  超宽→32
```

### 8.3 各模块宽屏适配行为

| 模块 | LG（宽屏）行为 |
|------|---------------|
| **Home** | Tabs 切换为侧边栏模式（`vertical=true`, `barPosition=Start`） |
| **Photos** | Tabs 切换为侧边栏模式 |
| **Stock** | 图表高度 376vp，边距 32vp，底部操作栏右对齐 |
| **Video** | GridRow 12 列布局，显示关联视频列表 |

---

## 九、状态管理与数据流

### 9.1 AppStorage 全局状态

| 键名 | 类型 | 含义 | 设置者 |
|------|------|------|--------|
| `widthBp` | WidthBreakpoint | 当前宽度断点 | EntryAbility |
| `heightBp` | HeightBreakpoint | 当前高度断点 | EntryAbility |
| `isFullScreen` | boolean | 视频是否全屏 | VideoDetailView |
| `avplayerState` | string | 播放器状态 | AvPlayerUtil |
| `isClick` | boolean | 是否手动点击全屏 | VideoPlayer |
| `creaseRegion` | number[] | 折叠屏折痕区域 | DisplayUtil |

### 9.2 组件状态管理

| 装饰器 | 用途 |
|--------|------|
| `@StorageLink` | 双向绑定 AppStorage（组件可读写） |
| `@StorageProp` | 单向绑定 AppStorage（组件只读） |
| `@State` | 组件内私有状态 |
| `@Provide` | 向下级组件提供状态 |
| `@Consume` | 消费上级提供的状态 |
| `@Watch` | 监听属性变化并执行回调 |

---

## 十、工具类一览

| 工具类 | 位置 | 功能 |
|--------|------|------|
| **WindowOrientationHelper** | commons/base/utils | ★ 窗口旋转策略助手 |
| **AvPlayerUtil** | commons/base/utils | AVPlayer 封装（播放/暂停/快进/拖动/状态管理） |
| **BreakpointType<T>** | commons/base/utils | 泛型断点自适应取值 |
| **DeviceScreen** | commons/base/utils | 获取屏幕宽高（px→vp 转换） |
| **DisplayUtil** | commons/base/utils | 折叠屏折痕区域检测 |
| **Logger** | commons/base/utils | 统一日志输出 |
| **CurrentOffsetUtil** | commons/base/utils | 滚动偏移量管理 |

---

## 十一、各模块信息汇总

### Home（首页）
- **路由**：`Home`
- **文件**：`features/home/src/main/ets/views/Home.ets`
- **数据源**：`WaterFlowDataSource`（瀑布流）
- **核心组件**：`WaterFlow` + `LazyForEach` + `Tabs`
- **特点**：支持 Tab 栏底部/侧边栏切换，瀑布流无限加载

### PortraitModeGame（竖屏游戏）
- **路由**：`PortraitModeGame`
- **文件**：`features/portrait/src/main/ets/views/PortraitModeGame.ets`
- **策略**：固定竖屏（`FIXED.PORTRAIT`）
- **视图**：8 列网格布局的方块颜色随机游戏

### LandscapeModeGame（横屏游戏）
- **路由**：`LandscapeModeGame`
- **文件**：`features/landscape/src/main/ets/views/LandscapeModeGame.ets`
- **策略**：固定横屏（`FIXED.LANDSCAPE`）
- **视图**：两个圆形元素并排

### Photos（照片）
- **路由**：`Photos`
- **文件**：`features/photos/src/main/ets/views/Photos.ets`
- **策略**：全向自动旋转（`AUTO_ROTATE.ALL.UNSPECIFIED`）
- **数据源**：`ListDataSource`
- **视图**：4×2 图片网格 + Tab 栏底部/侧边栏

### StockDetail（股票详情）
- **路由**：`StockDetail`（主路由）、`ABAWindow`（子路由）
- **文件**：`features/stock/src/main/ets/views/StockDetail.ets`
- **策略**：跟随桌面（`followDesktop()`）
- **核心组件**：LineChart、BarChart、响应式 GridRow
- **依赖**：`@ohos/mpchart` 图表库

### VideoDetail（视频详情）
- **路由**：`VideoDetail`
- **文件**：`features/video/src/main/ets/views/VideoDetail.ets`
- **策略**：动态切换（全屏→横屏自动 / 非全屏→全向自动）
- **核心组件**：VideoPlayer + GridRow 响应式布局
- **交互**：键盘快捷键 + 全屏手势

---

## 十二、配置文件清单

| 文件 | 模块 | 关键内容 |
|------|------|----------|
| `AppScope/app.json5` | 全局 | bundleName、版本、图标 |
| `build-profile.json5` | 全局 | 模块列表、SDK 版本 6.0.2、签名配置 |
| `oh-package.json5` | 全局 | hypium 测试库、hamock 模拟库 |
| `products/default/.../main_pages.json` | 入口 | 仅注册 `pages/Index` |
| `products/default/.../module.json5` | 入口 | EntryAbility + 备份扩展 |
| `commons/base/.../module.json5` | 公共库 | HAR 类型 |
| `features/*/.../router_map.json` | 各功能 | NavPathStack 路由注册 |
| `features/*/.../module.json5` | 各功能 | HAR 类型 + router_map 引用 |

---

## 十三、技术亮点总结

1. **三层窗口旋转决策模型** — `WindowOrientationHelper` 完整封装了 HarmonyOS 的所有旋转策略
2. **HAR 模块化架构** — 7 个 HAR + 1 个 HAP，公共代码统一抽取到 `commons/base`
3. **NavPathStack 组件内路由** — 通过 HAR 的 `router_map` 注册子页面，延迟加载
4. **双维度响应式布局** — 同时监听 Width/Height 断点，与 `BreakpointType<T>` 泛型工具配合
5. **Video 模块动态策略切换** — 全屏/非全屏、窗口大小变化时自动调整旋转策略
6. **AVPlayer 完整封装** — 播放/暂停/快进/快退/拖动/状态机管理
7. **折叠屏适配** — `DisplayUtil` 检测折痕区域
8. **键盘快捷键支持** — Video 模块支持 Space/Esc/方向键操作

---

*生成日期：2026-05-19*
