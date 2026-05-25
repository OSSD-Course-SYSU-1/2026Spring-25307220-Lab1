/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import {
  BreakpointType,
  CommonConstants,
  Logger,
  OrientationLogger,
  WindowOrientationHelper
} from 'base';
import type { RotationEvent } from 'base';

// 模拟窗口配置接口
interface SimulatedWindowConfig {
  name: string;
  strategyLabel: string;
  strategy: () => Orientation;
  color: Resource;
  borderColor: Resource;
  icon: string;
}

@Builder
export function MultiWindowDemoBuilder() {
  MultiWindowDemo();
}

@Component
export struct MultiWindowDemo {
  windowObj: window.Window | undefined = undefined;
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @StorageLink(CommonConstants.HEIGHT_BREAK_POINT) heightBp: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM;
  @State currentStrategyName: string = '';
  @State isRecording: boolean = false;
  @State orientationDisplay: string = '竖屏';
  @State eventCount: number = 0;
  private logger: OrientationLogger = OrientationLogger.getInstance();
  private scanTimer: number = -1;
  private simulatedWindows: SimulatedWindowConfig[] = [];

  aboutToAppear(): void {
    try {
      this.windowObj = (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage.getMainWindowSync();
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.logger.init(ctx);
    } catch (err) {
      Logger.error(`MultiWindowDemo init failed: ${err.code}`);
    }

    // 初始化模拟窗口配置
    this.simulatedWindows = [
      {
        name: '窗口A',
        strategyLabel: 'FIXED.PORTRAIT',
        strategy: () => WindowOrientationHelper.presets.FIXED.PORTRAIT,
        color: $r('app.color.window_a_bg'),
        borderColor: $r('app.color.window_a_border'),
        icon: '🔒',
      },
      {
        name: '窗口B',
        strategyLabel: 'FOLLOW_DESKTOP',
        strategy: () => WindowOrientationHelper.presets.FOLLOW_DESKTOP,
        color: $r('app.color.window_b_bg'),
        borderColor: $r('app.color.window_b_border'),
        icon: '🖥️',
      },
      {
        name: '窗口C',
        strategyLabel: 'AUTO_ROTATE.ALL',
        strategy: () => WindowOrientationHelper.presets.AUTO_ROTATE.ALL_ORIENTATIONS.UNSPECIFIED,
        color: $r('app.color.window_c_bg'),
        borderColor: $r('app.color.window_c_border'),
        icon: '🔄',
      },
    ];

    // 主窗口应用 FOLLOW_DESKTOP 策略
    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.presets.FOLLOW_DESKTOP)
      .catch((err: BusinessError) => {
        Logger.error(`Set orientation failed: ${err.message}`);
      });
    this.currentStrategyName = 'FOLLOW_DESKTOP';

    // 更新方向显示
    this.updateOrientationDisplay();

    // 开始录制
    this.startRecording();
  }

  aboutToDisappear(): void {
    // 停止录制
    this.stopRecording();
    // 恢复锁定当前方向
    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.presets.FIXED.UNSPECIFIED)
      .catch((err: BusinessError) => {
        Logger.error(`Restore orientation failed: ${err.message}`);
      });
  }

  /**
   * 开始录制旋转事件
   */
  startRecording(): void {
    if (this.isRecording) {
      return;
    }
    this.logger.startRecording();
    this.isRecording = true;
    // 每 500ms 扫描一次方向变化
    this.scanTimer = setInterval(() => {
      this.updateOrientationDisplay();
      this.recordCurrentState();
      this.eventCount = this.logger.getEventCount();
    }, 500);
    // 初始记录
    this.recordCurrentState();
  }

  /**
   * 停止录制
   */
  stopRecording(): void {
    if (!this.isRecording) {
      return;
    }
    this.logger.stopRecording();
    this.isRecording = false;
    if (this.scanTimer !== -1) {
      clearInterval(this.scanTimer);
      this.scanTimer = -1;
    }
  }

  /**
   * 更新当前方向显示
   */
  updateOrientationDisplay(): void {
    if (this.widthBp >= WidthBreakpoint.WIDTH_LG) {
      this.orientationDisplay = '横屏';
    } else {
      this.orientationDisplay = '竖屏';
    }
  }

  /**
   * 记录当前状态到日志
   */
  recordCurrentState(): void {
    const strategy = this.currentStrategyName || 'FOLLOW_DESKTOP';
    this.logger.recordEvent(
      'windowSizeChange',
      strategy,
      `WIDTH_${this.widthBp}`,
      `HEIGHT_${this.heightBp}`
    );
  }

  /**
   * 构建模拟窗口卡片
   */
  @Builder
  WindowCard(config: SimulatedWindowConfig, index: number) {
    Column() {
      // 窗口标题栏
      Row() {
        Text(config.icon)
          .fontSize(18)
        Text(config.name)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
      }
      .width(CommonConstants.FULL_PERCENT)
      .padding({ left: 10, right: 10, top: 6, bottom: 4 })
      .backgroundColor(config.borderColor)
      .borderRadius({ topLeft: 12, topRight: 12 })
      .opacity(0.9)

      // 窗口内容区
      Column({ space: 8 }) {
        // 策略标签
        Row() {
          Text($r('app.string.strategy_label'))
            .fontSize(11)
            .fontColor($r('sys.color.font_secondary'))
          Text(config.strategyLabel)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor($r('app.color.strategy_tag_bg'))
            .borderRadius(4)
        }
        .width(CommonConstants.FULL_PERCENT)
        .justifyContent(FlexAlign.SpaceBetween)

        // 方向状态
        Row() {
          Text($r('app.string.orientation_label'))
            .fontSize(11)
            .fontColor($r('sys.color.font_secondary'))
          Text(this.getWindowOrientationText(index))
            .fontSize(13)
            .fontWeight(FontWeight.Bold)
            .fontColor(config.borderColor)
        }
        .width(CommonConstants.FULL_PERCENT)
        .justifyContent(FlexAlign.SpaceBetween)

        // 状态指示灯
        Row() {
          Circle({ width: 6, height: 6 })
            .fill(config.borderColor)
          Text(this.isRecording ? $r('app.string.status_active') : $r('app.string.status_inactive'))
            .fontSize(10)
            .fontColor($r('sys.color.font_tertiary'))
        }
        .width(CommonConstants.FULL_PERCENT)
        .justifyContent(FlexAlign.End)

        // 旋转模拟动画区
        Column() {
          SymbolGlyph($r('sys.symbol.arrow_clockwise'))
            .fontSize(24)
            .fontColor([config.borderColor])
            .rotate({
              angle: this.getRotationAngle(index),
              centerX: '50%',
              centerY: '50%',
            })
            .animation({
              duration: 800,
              curve: Curve.EaseInOut,
            })
        }
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      }
      .width(CommonConstants.FULL_PERCENT)
      .layoutWeight(1)
      .padding({ left: 10, right: 10, top: 8, bottom: 8 })
      .backgroundColor(config.color)
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
    .borderRadius(12)
    .border({
      width: 1.5,
      color: config.borderColor,
      style: BorderStyle.Solid,
    })
    .shadow({
      radius: 8,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 2,
    })
  }

  /**
   * 根据当前方向获取模拟窗口的旋转角度
   */
  private getRotationAngle(windowIndex: number): number {
    // 窗口A（固定竖屏）：始终0度
    if (windowIndex === 0) {
      return 0;
    }
    // 窗口B（跟随桌面）：跟随主窗口方向
    if (windowIndex === 1) {
      return this.widthBp >= WidthBreakpoint.WIDTH_LG ? 90 : 0;
    }
    // 窗口C（自动旋转）：用时间做周期性旋转
    return (Date.now() / 20) % 360;
  }

  /**
   * 根据索引获取窗口方向文本
   */
  private getWindowOrientationText(windowIndex: number): string {
    if (windowIndex === 0) {
      return '竖屏（锁定）';
    }
    if (windowIndex === 1) {
      return this.widthBp >= WidthBreakpoint.WIDTH_LG ? '横屏' : '竖屏';
    }
    // 窗口C 根据时间模拟自动旋转
    const phase = Math.floor((Date.now() / 2000) % 4);
    const orientations = ['竖屏', '横屏', '反向竖屏', '反向横屏'];
    return orientations[phase];
  }

  build() {
    NavDestination() {
      Column({ space: 12 }) {
        // 顶部信息栏
        Row() {
          Column({ space: 2 }) {
            Text($r('app.string.multi_window_desc'))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('sys.color.font_primary'))
            Text(`主窗口策略: ${this.currentStrategyName}`)
              .fontSize(12)
              .fontColor($r('sys.color.font_secondary'))
          }
          .alignItems(HorizontalAlign.Start)

          Blank()

          Column({ space: 4 }) {
            // 录制状态
            Row({ space: 4 }) {
              Circle({ width: 8, height: 8 })
                .fill(this.isRecording ? '#FF1744' : '#BDBDBD')
              Text(this.isRecording ? '录制中' : '已停止')
                .fontSize(11)
                .fontColor($r('sys.color.font_secondary'))
            }
            // 事件计数
            Text(`事件: ${this.eventCount}`)
              .fontSize(11)
              .fontColor($r('sys.color.font_tertiary'))
          }
          .alignItems(HorizontalAlign.End)
        }
        .width(CommonConstants.FULL_PERCENT)
        .padding({ left: 4, right: 4 })

        // 主窗口状态卡片
        Row() {
          Column({ space: 6 }) {
            Text($r('app.string.main_window'))
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
            Row({ space: 12 }) {
              this.InfoChip('策略', this.currentStrategyName)
              this.InfoChip('方向', this.orientationDisplay)
              this.InfoChip('断点', `W${this.widthBp}/H${this.heightBp}`)
            }
          }
          .alignItems(HorizontalAlign.Start)
          .width(CommonConstants.FULL_PERCENT)
        }
        .width(CommonConstants.FULL_PERCENT)
        .padding(12)
        .backgroundColor($r('app.color.main_window_bg'))
        .borderRadius(12)
        .border({ width: 1, color: '#E0E0E0' })

        // 三窗口网格
        Grid() {
          GridItem() {
            this.WindowCard(this.simulatedWindows[0], 0)
          }
          GridItem() {
            this.WindowCard(this.simulatedWindows[1], 1)
          }
          GridItem() {
            this.WindowCard(this.simulatedWindows[2], 2)
          }
        }
        .columnsTemplate('1fr')
        .rowsTemplate(this.getGridRowsTemplate())
        .columnsGap(10)
        .rowsGap(10)
        .width(CommonConstants.FULL_PERCENT)
        .layoutWeight(1)

        // 底部控制栏
        Row({ space: 8 }) {
          Button(this.isRecording ? '停止录制' : '开始录制')
            .fontSize(13)
            .type(this.isRecording ? ButtonType.Capsule : ButtonType.Normal)
            .backgroundColor(this.isRecording ? '#FF1744' : '#1976D2')
            .borderRadius(20)
            .height(36)
            .onClick(() => {
              if (this.isRecording) {
                this.stopRecording();
              } else {
                this.startRecording();
              }
            })

          Button('清空日志')
            .fontSize(13)
            .type(ButtonType.Capsule)
            .backgroundColor('#757575')
            .borderRadius(20)
            .height(36)
            .onClick(() => {
              this.logger.clearEvents();
              this.eventCount = 0;
            })
        }
        .width(CommonConstants.FULL_PERCENT)
        .justifyContent(FlexAlign.Center)
        .padding({ top: 4, bottom: 4 })
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
      .padding({
        left: new BreakpointType(12, 12, 24, 32, 32).getValue(this.widthBp),
        right: new BreakpointType(12, 12, 24, 32, 32).getValue(this.widthBp),
        top: 8,
        bottom: 4,
      })
    }
    .height(CommonConstants.FULL_PERCENT)
    .width(CommonConstants.FULL_PERCENT)
    .title($r('app.string.multi_window_demo'), {
      backgroundColor: $r('app.color.common_background_color')
    })
    .backgroundColor($r('app.color.common_background_color'))
  }

  /**
   * 根据断点确定网格行模板
   */
  private getGridRowsTemplate(): string {
    // 宽屏：3列并排
    if (this.widthBp >= WidthBreakpoint.WIDTH_LG) {
      return '1fr';
    }
    // 中屏：2列+1行
    if (this.widthBp >= WidthBreakpoint.WIDTH_MD) {
      return '1fr 1fr';
    }
    // 小屏：3行
    return '1fr 1fr 1fr';
  }

  /**
   * 信息标签构建器
   */
  @Builder
  InfoChip(label: string, value: string) {
    Row({ space: 4 }) {
      Text(label)
        .fontSize(10)
        .fontColor($r('sys.color.font_tertiary'))
      Text(value)
        .fontSize(11)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_primary'))
    }
    .padding({ left: 8, right: 8, top: 3, bottom: 3 })
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
  }
}
