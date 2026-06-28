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

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import Logger from './Logger';

/**
 * 旋转事件数据模型
 */
export interface RotationEvent {
  id: number;
  timestamp: number;        // 事件时间戳（毫秒）
  timeStr: string;          // 格式化时间字符串 HH:mm:ss.SSS
  oldOrientation: string;   // 旧方向描述
  newOrientation: string;   // 新方向描述
  triggerReason: string;    // 触发原因
  strategy: string;         // 当前策略名
  widthBp: string;          // 宽度断点
  heightBp: string;         // 高度断点
  windowWidth: number;      // 窗口宽度（vp）
  windowHeight: number;     // 窗口高度（vp）
}

/**
 * 窗口尺寸接口
 */
export interface WindowSize {
  width: number;
  height: number;
}

/**
 * 统计信息接口
 */
export interface LogStatistics {
  totalEvents: number;
  durationMs: number;       // 录制总时长（毫秒）
  strategyCounts: Record<string, number>;   // 各策略触发次数
  triggerCounts: Record<string, number>;    // 各触发原因次数
  orientationChanges: number;               // 方向变化次数
  maxWindowSize: WindowSize;
  minWindowSize: WindowSize;
}

/**
 * 窗口旋转事件录制器
 * 使用 Preferences 持久化存储旋转事件记录，支持回放和统计分析
 */
export class OrientationLogger {
  private static instance: OrientationLogger;
  private events: RotationEvent[] = [];
  private nextId: number = 0;
  private context?: common.UIAbilityContext;
  private dataPreferences?: preferences.Preferences;
  private lastOrientation: string = 'INITIAL';
  private recordStartTime: number = 0;
  private isRecording: boolean = false;

  static getInstance(context?: common.UIAbilityContext): OrientationLogger {
    if (!OrientationLogger.instance) {
      OrientationLogger.instance = new OrientationLogger();
    }
    if (context && !OrientationLogger.instance.context) {
      OrientationLogger.instance.init(context);
    }
    return OrientationLogger.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    try {
      this.dataPreferences = await preferences.getPreferences(context, 'orientation_log_store');
      await this.loadEvents();
    } catch (err) {
      Logger.error(`OrientationLogger init failed: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 从持久化存储加载事件列表
   */
  private async loadEvents(): Promise<void> {
    if (!this.dataPreferences) {
      return;
    }
    try {
      this.nextId = await this.dataPreferences.get('nextId', 0) as number;
      const count = await this.dataPreferences.get('eventCount', 0) as number;
      for (let i = 0; i < count; i++) {
        const eventStr = await this.dataPreferences.get(`evt_${i}`, '') as string;
        if (eventStr) {
          this.events.push(JSON.parse(eventStr) as RotationEvent);
        }
      }
      Logger.info(`Loaded ${this.events.length} rotation events from storage.`);
    } catch (err) {
      Logger.error(`Failed to load events: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 持久化事件列表（最多保留200条）
   */
  private async saveEvents(): Promise<void> {
    if (!this.dataPreferences) {
      return;
    }
    try {
      const maxEvents = 200;
      const saveEvents = this.events.slice(-maxEvents);
      await this.dataPreferences.put('nextId', this.nextId);
      await this.dataPreferences.put('eventCount', saveEvents.length);
      for (let i = 0; i < saveEvents.length; i++) {
        await this.dataPreferences.put(`evt_${i}`, JSON.stringify(saveEvents[i]));
      }
      await this.dataPreferences.flush();
    } catch (err) {
      Logger.error(`Failed to save events: ${JSON.stringify(err)}`);
    }
  }

  /**
   * 开始录制旋转事件
   */
  startRecording(): void {
    this.isRecording = true;
    this.recordStartTime = Date.now();
    Logger.info('OrientationLogger: Recording started.');
  }

  /**
   * 停止录制
   */
  stopRecording(): void {
    this.isRecording = false;
    Logger.info('OrientationLogger: Recording stopped.');
  }

  /**
   * 记录一次旋转事件
   */
  recordEvent(triggerReason: string, strategy: string, widthBp: string, heightBp: string): void {
    if (!this.isRecording) {
      return;
    }
    const now = new Date();
    const event: RotationEvent = {
      id: this.nextId++,
      timestamp: now.getTime(),
      timeStr: this.formatTime(now),
      oldOrientation: this.lastOrientation,
      newOrientation: this.detectOrientation(widthBp, heightBp),
      triggerReason: triggerReason,
      strategy: strategy,
      widthBp: widthBp,
      heightBp: heightBp,
      windowWidth: 0,
      windowHeight: 0,
    };
    this.lastOrientation = event.newOrientation;
    this.events.push(event);
    // 异步保存，不阻塞主线程
    this.saveEvents();
  }

  /**
   * 根据断点推断当前方向描述
   */
  private detectOrientation(widthBp: string, heightBp: string): string {
    const w = parseInt(widthBp.replace('WIDTH_', ''));
    const h = parseInt(heightBp.replace('HEIGHT_', ''));
    if (w >= 3) {
      return 'LANDSCAPE'; // 宽屏视为横屏
    }
    return 'PORTRAIT';    // 窄屏视为竖屏
  }

  /**
   * 获取所有事件
   */
  getEvents(): RotationEvent[] {
    return [...this.events];
  }

  /**
   * 获取从指定索引开始的事件列表（用于分页或增量更新）
   */
  getEventsFrom(startIndex: number): RotationEvent[] {
    return this.events.slice(startIndex);
  }

  /**
   * 获取事件总数
   */
  getEventCount(): number {
    return this.events.length;
  }

  /**
   * 计算统计信息
   */
  getStatistics(): LogStatistics {
    const strategyCounts: Record<string, number> = {};
    const triggerCounts: Record<string, number> = {};
    let maxWidth = 0;
    let maxHeight = 0;
    let minWidth = Number.MAX_VALUE;
    let minHeight = Number.MAX_VALUE;
    let orientationChanges = 0;

    for (const event of this.events) {
      // 统计策略
      const key = event.strategy;
      strategyCounts[key] = (strategyCounts[key] || 0) + 1;
      // 统计触发原因
      const reason = event.triggerReason;
      triggerCounts[reason] = (triggerCounts[reason] || 0) + 1;
      // 方向变化次数
      if (event.oldOrientation !== event.newOrientation && event.oldOrientation !== 'INITIAL') {
        orientationChanges++;
      }
      // 窗口尺寸
      if (event.windowWidth > maxWidth) {
        maxWidth = event.windowWidth;
      }
      if (event.windowHeight > maxHeight) {
        maxHeight = event.windowHeight;
      }
      if (event.windowWidth > 0 && event.windowWidth < minWidth) {
        minWidth = event.windowWidth;
      }
      if (event.windowHeight > 0 && event.windowHeight < minHeight) {
        minHeight = event.windowHeight;
      }
    }

    const durationMs = this.events.length > 0
      ? this.events[this.events.length - 1].timestamp - this.events[0].timestamp
      : 0;

    const maxWinSize: WindowSize = { width: maxWidth, height: maxHeight };
    const minWinSize: WindowSize = {
      width: minWidth === Number.MAX_VALUE ? 0 : minWidth,
      height: minHeight === Number.MAX_VALUE ? 0 : minHeight,
    };
    const stat: LogStatistics = {
      totalEvents: this.events.length,
      durationMs: durationMs,
      strategyCounts: strategyCounts,
      triggerCounts: triggerCounts,
      orientationChanges: orientationChanges,
      maxWindowSize: maxWinSize,
      minWindowSize: minWinSize,
    };
    return stat;
  }

  /**
   * 清空所有记录
   */
  async clearEvents(): Promise<void> {
    this.events = [];
    this.nextId = 0;
    this.lastOrientation = 'INITIAL';
    if (this.dataPreferences) {
      try {
        await this.dataPreferences.clear();
        await this.dataPreferences.flush();
      } catch (err) {
        Logger.error(`Failed to clear events: ${JSON.stringify(err)}`);
      }
    }
    Logger.info('OrientationLogger: All events cleared.');
  }

  /**
   * 格式化时间
   */
  private formatTime(date: Date): string {
    const h = String(date.getHours()).padStart(2, '0');
    const m = String(date.getMinutes()).padStart(2, '0');
    const s = String(date.getSeconds()).padStart(2, '0');
    const ms = String(date.getMilliseconds()).padStart(3, '0');
    return `${h}:${m}:${s}.${ms}`;
  }

  /**
   * 格式化毫秒时长为可读字符串
   */
  static formatDuration(ms: number): string {
    if (ms < 1000) {
      return `${ms}ms`;
    }
    const seconds = Math.floor(ms / 1000);
    if (seconds < 60) {
      return `${seconds}s`;
    }
    const minutes = Math.floor(seconds / 60);
    const remainSec = seconds % 60;
    if (minutes < 60) {
      return `${minutes}m ${remainSec}s`;
    }
    const hours = Math.floor(minutes / 60);
    const remainMin = minutes % 60;
    return `${hours}h ${remainMin}m`;
  }
}
