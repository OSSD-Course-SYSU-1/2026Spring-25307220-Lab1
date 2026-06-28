# WindowOrientation 项目开发避坑文档

> 从 6 轮 DevEco Studio 错误报告中沉淀的 10 条实战经验。
> 每一条背后都对应一次真实的编译失败。

---

## 1. `.gitignore` 不能屏蔽 `/products/`

```gitignore
# ❌ 错误 — 入口模块被忽略，编译报 00303149 Configuration Error
/products/

# ✅ 正确 — 只忽略构建产物
/products/build/
```

**经验**：`products/default/` 是整个项目的编译入口。丢失该目录意味着 EntryAbility、Index、main_pages.json、module.json5 全部缺失。

---

## 2. HAR 模块必须声明 `deviceTypes`

```json5
// ❌ 错误 — 缺少 deviceTypes，编译报 00303194
{
  "module": { "name": "nearbyshare", "type": "har", "routerMap": "$profile:router_map" }
}

// ✅ 正确
{
  "module": {
    "name": "nearbyshare", "type": "har",
    "deviceTypes": ["default"],
    "routerMap": "$profile:router_map"
  }
}
```

**经验**：我们创建 nearbyshare 和 freeflow 时漏掉了这个字段，导致编译器无法获取模块设备类型。所有 11 个 HAR 模块都需要。

---

## 3. 首次打开必须 IDE Sync

**经验**：创建 `products/default/` 后，`oh_modules/` 目录不存在。`import { BreakpointType } from 'base'` 会报 `Cannot find module 'base'`。这是预期行为——需要 DevEco Studio 中 Sync 触发 ohpm install。

**投机取巧的后果**：我们曾在 Index.ets 中内联了一份 `BreakpointType` 副本作为权宜之计，这导致了代码重复。Sync 后应改回 `import from 'base'`。

---

## 4. `$r('sys.symbol.xxx')` 在 HAR 模块中不可用

```typescript
// ❌ 错误 — 在 HAR 模块中使用系统符号
SymbolGlyph($r('sys.symbol.iphone'))

// ✅ 可行方案 A — Unicode 文本
Text('\u{1F4F1}')

// ✅ 可行方案 B — 自定义资源
Image($r('app.media.my_custom_icon'))
```

**经验**：添加 `deviceTypes: ["default"]` 后进入完整 ArkTS 编译模式，9 个系统符号全部报 Unknown resource。NearbyShare 模块的 9 处 sys.symbol 全部替换为 Unicode emoji。

---

## 5. ArkTS 严格模式禁止 spread 和 Object.assign

```typescript
// ❌ 错误 — 两个都被 ArkTS 禁止
const updated = { ...original, ...partial };     // arkts-no-spread
const updated = Object.assign({}, original);      // arkts-limited-stdlib

// ✅ 正确 — class + 逐字段赋值
export class FlowState {
  textContent: string = '';
  counter: number = 0;
  // ...
  static copy(src: FlowState): FlowState {
    const f = new FlowState();
    f.textContent = src.textContent;
    f.counter = src.counter;
    return f;
  }
}
const updated = FlowState.copy(original);
updated.textContent = partial.textContent ?? updated.textContent;
```

**经验**：我们先用 spread（报 10605099），改用 Object.assign（报 10605144），最终改为 class + 静态 copy() 才通过。interface 类型在 ArkTS 严格模式下无法进行任何形式的快速拷贝。

---

## 6. 动态 `import()` 不支持

```typescript
// ❌ 错误 — ArkTS 编译器的 rollup 阶段直接拒绝
const dm = import('@kit.DistributedServiceKit').then(...)

// ✅ 正确 — 静态 import + 运行时 try/catch
import { distributedDeviceManager } from '@kit.DistributedServiceKit';
// 使用时：
try {
  const manager = distributedDeviceManager.createDeviceManager(...);
} catch (_err) {
  // 降级到模拟
}
```

**经验**：我们在 DeviceDiscoveryManager 中最初用了动态 import，触发 00305015 rollup 错误。最终改为 real API 路径留空壳（直接 fallback），真机时再补静态 import。

---

## 7. `@Builder` 返回值不能链式 `.layoutWeight()`

```typescript
// ❌ 错误 — Builder 方法返回值上没有 layoutWeight 属性
this.BoardArea().layoutWeight(1)

// ✅ 正确 — 用 Column/Row 包裹
Column() { this.BoardArea() }.layoutWeight(1)
```

**经验**：在 Game2048、NearbyShare、FreeFlow 三个模块中共 4 处出现此错误。修复方式统一为 Builder 外层包裹容器。

---

## 8. Entry 模块用 `"pages"`，HAR 模块用 `"routerMap"`

```json5
// Entry 模块 (products/default/src/main/module.json5):
"pages": "$profile:main_pages"

// HAR 模块 (features/home/src/main/module.json5):
"routerMap": "$profile:router_map"
```

**经验**：我们在初版中给 entry 模块用了 `"routerMap"`，这是错误的。Entry 模块的路由注册字段是 `"pages"`，HAR 模块才是 `"routerMap"`。

---

## 9. 断点系统必须在 EntryAbility 中初始化

```typescript
// EntryAbility.onWindowStageCreate:
mainWindow.on('windowSizeChange', () => {
  AppStorage.setOrCreate('widthBp', uiContext.getWindowWidthBreakpoint());
  AppStorage.setOrCreate('heightBp', uiContext.getWindowHeightBreakpoint());
});
```

**经验**：不要依赖各页面自行初始化断点。EntryAbility 是唯一可靠的初始化位置。VideoPlayer 中有零散的局部断点更新，但那只是折叠屏状态变化的补偿，不覆盖所有场景。

---

## 10. 分布式 API 必须 `canIUse()` 检测 + 模拟降级

```typescript
// DeviceDiscoveryManager 内部:
if (canIUse('SystemCapability.DistributedHardware.DeviceManager')) {
  // 真实设备发现
} else {
  // 模拟设备池 (SIMULATED_DEVICE_POOL + setInterval)
}
```

**经验**：模拟器和 DevEco Previewer 不支持分布式能力。所有分布式功能必须在代码中同时提供真实 API 路径和模拟降级路径，编译时都要编译过去，运行时自动选择。

---

## 错误报告演进史

| 版本 | 错误数 | 关键问题 |
|:---:|:---:|------|
| v1 | 34 | 入口模块缺失、依赖断裂 |
| v2 | 0 | 首次编译成功（但模块未经完整校验）|
| v3 | 1 | nearbyshare/freeflow 缺 deviceTypes |
| v4 | 23 | 修复 deviceTypes 后触发 ArkTS 完整严格模式 |
| v5 | 12 | NearbyShare 修完，FreeFlow Object.assign 被拒 |
| v6 | 0 | FlowState 改 class + copy()，全部通过 |

---

*从 34 个错误归零的历程告诉我们：HarmonyOS 的 ArkTS 严格模式是一层一层剥开的洋葱，修好一类错误，下一类的限制才会暴露。*

*本文档随项目持续更新，每条规则都对应真实的错误码和修复代码。*
