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

import { common } from '@kit.AbilityKit';
import {
  BreakpointType,
  CommonConstants,
  Logger,
  OrientationLogger,
  WindowOrientationHelper
} from 'base';
import type { LogStatistics, RotationEvent } from 'base';
import type { BarItemData } from '../model/RotationEventModel';

@Builder
export function OrientationLogBuilder() {
  OrientationLog();
}

@Component
export struct OrientationLog {
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @State currentTabIndex: number = 0;
  @State events: RotationEvent[] = [];
  @State statistics: LogStatistics | null = null;
  @State barData: BarItemData[] = [];
  private logger: OrientationLogger = OrientationLogger.getInstance();

  aboutToAppear(): void {
    try {
      const ctx = (this.getUIContext().getHostContext() as common.UIAbilityContext);
      this.logger.init(ctx);
    } catch (err) {
      Logger.error(`OrientationLog init: ${JSON.stringify(err)}`);
    }
    this.refreshData();
  }

  /**
   * 刷新事件列表和统计数据
   */
  refreshData(): void {
    this.events = this.logger.getEvents().reverse(); // 最新在前
    this.statistics = this.logger.getStatistics();
    this.buildBarData();
  }

  /**
   * 构建条形图数据
   */
  buildBarData(): void {
    if (!this.statistics) {
      this.barData = [];
      return;
    }
    const colors: Resource[] = [
      $r('app.color.bar_color_1'),
      $r('app.color.bar_color_2'),
      $r('app.color.bar_color_3'),
      $r('app.color.bar_color_4'),
      $r('app.color.bar_color_5'),
    ];
    const entries: [string, number][] = [];
    const strategyCounts: Record<string, number> = this.statistics.strategyCounts;
    const keys: string[] = Object.keys(strategyCounts);
    for (let i = 0; i < keys.length; i++) {
      const k: string = keys[i];
      entries.push([k, strategyCounts[k]]);
    }
    const total: number = this.statistics.totalEvents || 1;
    this.barData = entries.map((entry: [string, number], index: number) => {
      const key: string = entry[0];
      const val: number = entry[1];
      const item: BarItemData = {
        label: key,
        value: val,
        color: colors[index % colors.length],
        percent: Math.round((val / total) * 100),
      };
      return item;
    });
  }

  /**
   * 获取触发原因的图标
   */
  getTriggerIcon(reason: string): string {
    switch (reason) {
      case 'windowSizeChange':
        return '📐';
      case 'fullScreenToggle':
        return '🖥️';
      case 'manualSet':
        return '👆';
      default:
        return '📌';
    }
  }

  /**
   * 构建触发原因列表（避免在ForEach回调中使用this）
   */
  private buildTriggerEntries(): string[][] {
    const result: string[][] = [];
    if (this.statistics) {
      const triggerCounts: Record<string, number> = this.statistics.triggerCounts;
      const keys: string[] = Object.keys(triggerCounts);
      for (let i = 0; i < keys.length; i++) {
        const k: string = keys[i];
        const icon: string = this.getTriggerIcon(k);
        result.push([k, icon, String(triggerCounts[k])]);
      }
    }
    return result;
  }

  /**
   * 构建空状态视图
   */
  @Builder
  EmptyView() {
    Column({ space: 12 }) {
      SymbolGlyph($r('sys.symbol.doc_text'))
        .fontSize(48)
        .fontColor([$r('sys.color.icon_tertiary')])
      Text($r('app.string.log_empty'))
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('sys.color.font_secondary'))
      Text($r('app.string.log_empty_hint'))
        .fontSize(13)
        .fontColor($r('sys.color.font_tertiary'))
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .padding({ left: 32, right: 32 })
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(CommonConstants.FULL_PERCENT)
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 构建时间轴单条事件
   */
  @Builder
  TimelineItem(event: RotationEvent, isLast: boolean) {
    Row() {
      // 左侧时间线
      Column() {
        Circle({ width: 10, height: 10 })
          .fill($r('app.color.log_timeline_dot'))
        if (!isLast) {
          Divider()
            .vertical(false)
            .width(2)
            .height(CommonConstants.FULL_PERCENT)
            .color($r('app.color.log_timeline_line'))
        } else {
          Blank()
            .layoutWeight(1)
        }
      }
      .width(24)
      .height(CommonConstants.FULL_PERCENT)
      .alignItems(HorizontalAlign.Center)

      // 右侧内容卡片
      Column({ space: 4 }) {
        // 时间 + 触发原因
        Row() {
          Text(event.timeStr)
            .fontSize(12)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
          Blank()
          Text(this.getTriggerIcon(event.triggerReason) + ' ' + event.triggerReason)
            .fontSize(10)
            .fontColor($r('sys.color.font_tertiary'))
        }
        .width(CommonConstants.FULL_PERCENT)

        // 策略标签
        Row({ space: 6 }) {
          Text(event.strategy)
            .fontSize(10)
            .fontColor('#FFFFFF')
            .padding({ left: 6, right: 6, top: 2, bottom: 2 })
            .backgroundColor('#1976D2')
            .borderRadius(4)
          Text(`断点: ${event.widthBp}/${event.heightBp}`)
            .fontSize(10)
            .fontColor($r('sys.color.font_tertiary'))
        }

        // 方向变化
        Row({ space: 4 }) {
          Text('方向:')
            .fontSize(11)
            .fontColor($r('sys.color.font_secondary'))
          Text(`${event.oldOrientation}`)
            .fontSize(11)
            .fontColor($r('sys.color.font_tertiary'))
          SymbolGlyph($r('sys.symbol.arrow_right'))
            .fontSize(12)
            .fontColor([$r('sys.color.icon_tertiary')])
          Text(`${event.newOrientation}`)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
        }
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.log_card_bg'))
      .borderRadius(10)
      .padding(10)
      .margin({ bottom: 8 })
      .shadow({
        radius: 4,
        color: '#0D000000',
        offsetX: 0,
        offsetY: 1,
      })
    }
    .width(CommonConstants.FULL_PERCENT)
    .alignItems(VerticalAlign.Top)
  }

  /**
   * 时间轴视图
   */
  @Builder
  TimelineView() {
    Scroll() {
      Column() {
        ForEach(this.events, (event: RotationEvent, index: number) => {
          this.TimelineItem(event, index === this.events.length - 1)
        }, (event: RotationEvent) => event.id.toString())
      }
      .width(CommonConstants.FULL_PERCENT)
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })
    }
    .scrollBar(BarState.Off)
    .width(CommonConstants.FULL_PERCENT)
    .layoutWeight(1)
  }

  /**
   * 构建统计卡片
   */
  @Builder
  StatCard(title: ResourceStr, value: string, subtitle?: string) {
    Column({ space: 2 }) {
      Text(title)
        .fontSize(11)
        .fontColor($r('sys.color.font_tertiary'))
      Text(value)
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.stat_highlight'))
      if (subtitle) {
        Text(subtitle)
          .fontSize(10)
          .fontColor($r('sys.color.font_secondary'))
      }
    }
    .width(CommonConstants.FULL_PERCENT)
    .padding(12)
    .backgroundColor($r('app.color.stat_card_bg'))
    .borderRadius(10)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 构建条形图项
   */
  @Builder
  BarRow(data: BarItemData) {
    Row({ space: 8 }) {
      Text(data.label)
        .fontSize(11)
        .fontColor($r('sys.color.font_primary'))
        .width(120)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Row() {
        Row()
          .width(`${data.percent}%`)
          .height(CommonConstants.FULL_PERCENT)
          .backgroundColor(data.color)
          .borderRadius(3)
          .animation({ duration: 600, curve: Curve.EaseOut })
      }
      .layoutWeight(1)
      .height(18)
      .backgroundColor($r('app.color.log_timeline_line'))
      .borderRadius(3)

      Text(`${data.value}次`)
        .fontSize(11)
        .fontColor($r('sys.color.font_secondary'))
        .width(40)
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(28)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 统计分析视图
   */
  @Builder
  StatisticsView() {
    if (!this.statistics) {
      Column() {
        LoadingProgress()
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.Center)
    } else {
      Scroll() {
        Column({ space: 12 }) {
          // 概览数字
          Grid() {
            GridItem() {
              this.StatCard(
                $r('app.string.total_events'),
                `${this.statistics.totalEvents}`,
                '条记录'
              )
            }
            GridItem() {
              this.StatCard(
                $r('app.string.duration'),
                OrientationLogger.formatDuration(this.statistics.durationMs)
              )
            }
            GridItem() {
              this.StatCard(
                $r('app.string.orientation_changes'),
                `${this.statistics.orientationChanges}`,
                '次方向切换'
              )
            }
          }
          .columnsTemplate('1fr 1fr 1fr')
          .columnsGap(8)
          .rowsGap(8)
          .width(CommonConstants.FULL_PERCENT)

          // 策略分布条形图
          Column({ space: 8 }) {
            Row() {
              Text($r('app.string.strategy_distribution'))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_primary'))
            }
            .width(CommonConstants.FULL_PERCENT)

            if (this.barData.length === 0) {
              Text('暂无数据')
                .fontSize(12)
                .fontColor($r('sys.color.font_tertiary'))
                .padding({ top: 8, bottom: 8 })
            }

            ForEach(this.barData, (item: BarItemData) => {
              this.BarRow(item)
            }, (item: BarItemData) => item.label)

            // 图例
            Flex({ wrap: FlexWrap.Wrap }) {
              ForEach(this.barData, (item: BarItemData) => {
                Row({ space: 4 }) {
                  Circle({ width: 8, height: 8 })
                    .fill(item.color)
                  Text(`${item.percent}%`)
                    .fontSize(10)
                    .fontColor($r('sys.color.font_tertiary'))
                }
              }, (item: BarItemData) => `legend_${item.label}`)
            }
            .width(CommonConstants.FULL_PERCENT)
            .padding({ top: 4 })
          }
          .width(CommonConstants.FULL_PERCENT)
          .padding(12)
          .backgroundColor($r('app.color.log_card_bg'))
          .borderRadius(12)
          .shadow({
            radius: 4,
            color: '#0D000000',
            offsetX: 0,
            offsetY: 1,
          })

          // 触发原因分布
          if (this.buildTriggerEntries().length > 0) {
            Column({ space: 8 }) {
              Text($r('app.string.trigger_distribution'))
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('sys.color.font_primary'))

              ForEach(this.buildTriggerEntries(), (entry: string[]) => {
                Row() {
                  Text(`${entry[1]} ${entry[0]}`)
                    .fontSize(12)
                    .fontColor($r('sys.color.font_primary'))
                  Blank()
                  Text(`${entry[2]}次`)
                    .fontSize(12)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.stat_highlight'))
                }
                .width(CommonConstants.FULL_PERCENT)
                .padding({ top: 2, bottom: 2 })
              }, (entry: string[]) => `trigger_${entry[0]}`)
            }
            .width(CommonConstants.FULL_PERCENT)
            .padding(12)
            .backgroundColor($r('app.color.log_card_bg'))
            .borderRadius(12)
            .shadow({
              radius: 4,
              color: '#0D000000',
              offsetX: 0,
              offsetY: 1,
            })
          }

          // 底部间距
          Blank().height(20)
        }
        .width(CommonConstants.FULL_PERCENT)
        .padding({ left: 8, right: 8, top: 8 })
      }
      .scrollBar(BarState.Off)
      .width(CommonConstants.FULL_PERCENT)
      .layoutWeight(1)
    }
  }

  build() {
    NavDestination() {
      Column() {
        // Tab 切换栏
        Row() {
          this.TabButton($r('app.string.log_timeline'), 0)
          this.TabButton($r('app.string.log_statistics'), 1)
        }
        .width(CommonConstants.FULL_PERCENT)
        .height(40)
        .margin({ top: 4, bottom: 4 })

        // 内容区
        if (this.currentTabIndex === 0) {
          if (this.events.length === 0) {
            this.EmptyView()
          } else {
            this.TimelineView()
          }
        } else {
          this.StatisticsView()
        }
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
      .padding({
        left: new BreakpointType(12, 12, 24, 32, 32).getValue(this.widthBp),
        right: new BreakpointType(12, 12, 24, 32, 32).getValue(this.widthBp),
      })
    }
    .height(CommonConstants.FULL_PERCENT)
    .width(CommonConstants.FULL_PERCENT)
    .title($r('app.string.orientation_log'), {
      backgroundColor: $r('app.color.common_background_color')
    })
    .backgroundColor($r('app.color.common_background_color'))
    .menus([
      {
        value: 'refresh',
        icon: $r('sys.media.ohos_ic_public_add'),
        action: (): void => {
          this.refreshData();
        },
      } as NavigationMenuItem,
      {
        value: 'clear',
        icon: $r('sys.media.ohos_ic_public_remove'),
        action: (): void => {
          this.logger.clearEvents();
          this.refreshData();
        },
      } as NavigationMenuItem,
    ])
  }

  /**
   * Tab 按钮构建器
   */
  @Builder
  TabButton(text: ResourceStr, index: number) {
    Text(text)
      .fontSize(14)
      .fontWeight(this.currentTabIndex === index ? FontWeight.Bold : FontWeight.Normal)
      .fontColor(this.currentTabIndex === index ? $r('app.color.stat_highlight') : $r('sys.color.font_secondary'))
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .borderRadius(20)
      .backgroundColor(this.currentTabIndex === index ? '#E3F2FD' : Color.Transparent)
      .onClick(() => {
        this.currentTabIndex = index;
      })
  }
}
