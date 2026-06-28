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
import { BreakpointType, CommonConstants, Logger, WindowOrientationHelper } from 'base';

const GRID: number = 4;
const WIN: number = 2048;

// 格子背景色
function tileBg(v: number): string {
  if (v === 2) { return '#EEE4DA'; }
  if (v === 4) { return '#EDE0C8'; }
  if (v === 8) { return '#F2B179'; }
  if (v === 16) { return '#F59563'; }
  if (v === 32) { return '#F67C5F'; }
  if (v === 64) { return '#F65E3B'; }
  if (v === 128) { return '#EDCF72'; }
  if (v === 256) { return '#EDCC61'; }
  if (v === 512) { return '#EDC850'; }
  if (v === 1024) { return '#EDC53F'; }
  if (v === 2048) { return '#EDC22E'; }
  if (v >= 4096) { return '#3E3933'; }
  return '#3C3A32';
}

function tileFc(v: number): string {
  if (v <= 4) { return '#776E65'; }
  return '#FFFFFF';
}

function tileFs(v: number): number {
  if (v < 100) { return 30; }
  if (v < 1000) { return 24; }
  return 18;
}

@Builder
export function Game2048Builder() {
  Game2048();
}

@Component
export struct Game2048 {
  @State grid: number[][] = [];
  @State score: number = 0;
  @State best: number = 0;
  @State over: boolean = false;
  @State won: boolean = false;
  @State keep: boolean = false;
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @State tick: number = 0;
  private pref: preferences.Preferences | null = null;
  private windowObj: window.Window | undefined = undefined;

  aboutToAppear(): void {
    const ctx: common.UIAbilityContext =
      this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      this.windowObj = ctx.windowStage.getMainWindowSync();
      this.windowObj?.setPreferredOrientation(WindowOrientationHelper.presets.FOLLOW_DESKTOP)
        .catch((err: BusinessError) => {
          Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
        });
    } catch (err) {
      Logger.error(`Invoke getMainWindowSync failed, code is ${err.code}, message is ${err.message}`)
    }
    preferences.getPreferences(ctx, 'g2048').then((p: preferences.Preferences) => {
      this.pref = p;
      p.get('best', 0).then((v: preferences.ValueType) => {
        this.best = v as number;
      });
    });
    this.reset();
  }

  aboutToDisappear(): void {
    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.presets.FIXED.UNSPECIFIED)
      .catch((err: BusinessError) => {
        Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
      });
  }

  cellSize(): number {
    return new BreakpointType(56, 64, 76, 86, 94).getValue(this.widthBp);
  }

  reset(): void {
    const g: number[][] = [];
    for (let r: number = 0; r < GRID; r++) {
      g.push([0, 0, 0, 0]);
    }
    this.grid = g;
    this.score = 0;
    this.over = false;
    this.won = false;
    this.keep = false;
    this.tick = 0;
    this.addTile();
    this.addTile();
  }

  private addTile(): void {
    const list: number[] = [];
    for (let r: number = 0; r < GRID; r++) {
      for (let c: number = 0; c < GRID; c++) {
        if (this.grid[r][c] === 0) {
          list.push(r * GRID + c);
        }
      }
    }
    if (list.length === 0) { return; }
    const p: number = list[Math.floor(Math.random() * list.length)];
    const r: number = Math.floor(p / GRID);
    const c: number = p % GRID;
    this.grid[r][c] = Math.random() < 0.9 ? 2 : 4;
  }

  private copy(): number[][] {
    const g: number[][] = [];
    for (let r: number = 0; r < GRID; r++) {
      g.push([this.grid[r][0], this.grid[r][1], this.grid[r][2], this.grid[r][3]]);
    }
    return g;
  }

  private same(a: number[][], b: number[][]): boolean {
    for (let r: number = 0; r < GRID; r++) {
      for (let c: number = 0; c < GRID; c++) {
        if (a[r][c] !== b[r][c]) { return false; }
      }
    }
    return true;
  }

  private canMove(): boolean {
    for (let r: number = 0; r < GRID; r++) {
      for (let c: number = 0; c < GRID; c++) {
        if (this.grid[r][c] === 0) { return true; }
        if (c < GRID - 1 && this.grid[r][c] === this.grid[r][c + 1]) { return true; }
        if (r < GRID - 1 && this.grid[r][c] === this.grid[r + 1][c]) { return true; }
      }
    }
    return false;
  }

  private has2048(): boolean {
    for (let r: number = 0; r < GRID; r++) {
      for (let c: number = 0; c < GRID; c++) {
        if (this.grid[r][c] >= WIN) { return true; }
      }
    }
    return false;
  }

  // 左移一行: 压缩 → 合并 → 压缩
  private slide(arr: number[]): number[] {
    // 去掉0
    const a: number[] = [];
    for (let i: number = 0; i < arr.length; i++) {
      if (arr[i] !== 0) { a.push(arr[i]); }
    }
    // 合并
    const b: number[] = [];
    let i: number = 0;
    while (i < a.length) {
      if (i + 1 < a.length && a[i] === a[i + 1]) {
        b.push(a[i] * 2);
        this.score += a[i] * 2;
        if (a[i] * 2 > this.best) {
          this.best = a[i] * 2;
          this.saveBest();
        }
        i += 2;
      } else {
        b.push(a[i]);
        i += 1;
      }
    }
    // 补0
    while (b.length < GRID) { b.push(0); }
    return b;
  }

  private saveBest(): void {
    if (this.pref) {
      this.pref.put('best', this.best);
      this.pref.flush();
    }
  }

  private moveLeft(): boolean {
    const old: number[][] = this.copy();
    const ng: number[][] = [];
    for (let r: number = 0; r < GRID; r++) {
      ng.push(this.slide([this.grid[r][0], this.grid[r][1], this.grid[r][2], this.grid[r][3]]));
    }
    this.grid = ng;
    return !this.same(old, ng);
  }

  private moveRight(): boolean {
    const old: number[][] = this.copy();
    const ng: number[][] = [];
    for (let r: number = 0; r < GRID; r++) {
      const rev: number[] = [this.grid[r][3], this.grid[r][2], this.grid[r][1], this.grid[r][0]];
      const sl: number[] = this.slide(rev);
      ng.push([sl[3], sl[2], sl[1], sl[0]]);
    }
    this.grid = ng;
    return !this.same(old, ng);
  }

  // 转置
  private flip(): void {
    const ng: number[][] = [];
    for (let r: number = 0; r < GRID; r++) {
      ng.push([0, 0, 0, 0]);
    }
    for (let r: number = 0; r < GRID; r++) {
      for (let c: number = 0; c < GRID; c++) {
        ng[r][c] = this.grid[c][r];
      }
    }
    this.grid = ng;
  }

  private moveUp(): boolean {
    this.flip();
    const m: boolean = this.moveLeft();
    this.flip();
    return m;
  }

  private moveDown(): boolean {
    this.flip();
    const m: boolean = this.moveRight();
    this.flip();
    return m;
  }

  move(dir: string): void {
    if (this.over) { return; }
    if (this.won && !this.keep) { return; }

    let ok: boolean = false;
    if (dir === 'left') { ok = this.moveLeft(); }
    else if (dir === 'right') { ok = this.moveRight(); }
    else if (dir === 'up') { ok = this.moveUp(); }
    else if (dir === 'down') { ok = this.moveDown(); }

    if (!ok) { return; }

    this.addTile();
    this.tick++;

    if (!this.won && this.has2048()) {
      this.won = true;
    }
    if (!this.canMove()) {
      this.over = true;
    }
  }

  fmt(n: number): string {
    if (n >= 100000) { return (n / 1000).toFixed(0) + 'K'; }
    return String(n);
  }

  build() {
    NavDestination() {
      Column() {
        // 标题行
        Row() {
          Text('2048')
            .fontSize(new BreakpointType(28, 32, 36, 40, 44).getValue(this.widthBp))
            .fontWeight(FontWeight.Bold)
            .fontColor('#776E65')
            .layoutWeight(1)
          Column() {
            Text('得分').fontSize(11).fontColor('#EEE4DA').fontWeight(FontWeight.Bold)
            Text(this.fmt(this.score)).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          }
          .width(this.cellSize()).height(this.cellSize() * 0.62)
          .backgroundColor('#BBADA0').borderRadius(5)
          .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
          .margin({ left: 8 })
          Column() {
            Text('最高').fontSize(11).fontColor('#EEE4DA').fontWeight(FontWeight.Bold)
            Text(this.fmt(this.best)).fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          }
          .width(this.cellSize()).height(this.cellSize() * 0.62)
          .backgroundColor('#BBADA0').borderRadius(5)
          .alignItems(HorizontalAlign.Center).justifyContent(FlexAlign.Center)
          .margin({ left: 8 })
        }
        .width(CommonConstants.FULL_PERCENT)
        .padding({ bottom: new BreakpointType(8, 10, 12, 16, 16).getValue(this.widthBp) })

        // 大屏：棋盘和控制区并排；小屏：上下排列
        if (this.widthBp >= WidthBreakpoint.WIDTH_LG) {
          Row({ space: 24 }) {
            Column() { this.BoardArea() }
              .layoutWeight(1)
              .constraintSize({ maxWidth: this.cellSize() * 4 + 40 })
            this.ControlArea()
          }
          .width(CommonConstants.FULL_PERCENT)
          .alignItems(VerticalAlign.Center)
        } else {
          this.BoardArea()
          this.ControlArea()
        }
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
      .padding({
        left: new BreakpointType(12, 16, 24, 32, 32).getValue(this.widthBp),
        right: new BreakpointType(12, 16, 24, 32, 32).getValue(this.widthBp),
        top: 12,
        bottom: 24
      })
      .backgroundColor('#FAF8EF')
    }
    .height(CommonConstants.FULL_PERCENT)
    .width(CommonConstants.FULL_PERCENT)
    .backgroundColor('#FAF8EF')
    .hideTitleBar(true)
  }

  @Builder
  BoardArea() {
    Stack() {
      // 背景网格
      Column({ space: this.cellSize() * 0.1 }) {
        ForEach([0, 1, 2, 3], (ri: number) => {
          Row({ space: this.cellSize() * 0.1 }) {
            ForEach([0, 1, 2, 3], (ci: number) => {
              Row()
                .width(this.cellSize()).height(this.cellSize())
                .backgroundColor('#CDC1B4').borderRadius(5)
            }, (ci: number) => `bg${this.tick}_${ri}_${ci}`)
          }
        }, (ri: number) => `br${this.tick}_${ri}`)
      }
      .padding(this.cellSize() * 0.1)
      .backgroundColor('#BBADA0').borderRadius(8)

      // 数字层
      Column({ space: this.cellSize() * 0.1 }) {
        ForEach(this.grid, (row: number[], ri: number) => {
          Row({ space: this.cellSize() * 0.1 }) {
            ForEach(row, (v: number, ci: number) => {
              if (v > 0) {
                Text(String(v))
                  .fontSize(tileFs(v))
                  .fontWeight(FontWeight.Bold)
                  .fontColor(tileFc(v))
                  .width(this.cellSize()).height(this.cellSize())
                  .backgroundColor(tileBg(v))
                  .borderRadius(5)
                  .textAlign(TextAlign.Center)
              } else {
                Blank().width(this.cellSize()).height(this.cellSize())
              }
            }, (v: number, ci: number) => `t${this.tick}_${ri}_${ci}`)
          }
        }, (row: number[], ri: number) => `tr${this.tick}_${ri}`)
      }
      .padding(this.cellSize() * 0.1)
      .hitTestBehavior(HitTestMode.Transparent)

      // 游戏结束
      if (this.over) {
        Column({ space: 16 }) {
          Text('游戏结束!')
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#776E65')
          Button('重新开始')
            .fontSize(16)
            .backgroundColor('#8F7A66')
            .fontColor('#FFFFFF')
            .borderRadius(8)
            .height(44)
            .padding({ left: 28, right: 28 })
            .onClick(() => { this.reset(); })
        }
        .width(CommonConstants.FULL_PERCENT)
        .height(CommonConstants.FULL_PERCENT)
        .backgroundColor('#EDE0C8EE')
        .borderRadius(8)
        .justifyContent(FlexAlign.Center)
      }

      // 胜利
      if (this.won && !this.keep && !this.over) {
        Column({ space: 16 }) {
          Text('恭喜! 你赢了!')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor('#776E65')
          Row({ space: 16 }) {
            Button('继续')
              .fontSize(15)
              .backgroundColor('#8F7A66')
              .fontColor('#FFFFFF')
              .borderRadius(8)
              .height(42)
              .padding({ left: 22, right: 22 })
              .onClick(() => { this.keep = true; })
            Button('重来')
              .fontSize(15)
              .backgroundColor('#8F7A66')
              .fontColor('#FFFFFF')
              .borderRadius(8)
              .height(42)
              .padding({ left: 22, right: 22 })
              .onClick(() => { this.reset(); })
          }
        }
        .width(CommonConstants.FULL_PERCENT)
        .height(CommonConstants.FULL_PERCENT)
        .backgroundColor('#EDCF72EE')
        .borderRadius(8)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width(CommonConstants.FULL_PERCENT)
    .aspectRatio(1)
    .gesture(
      PanGesture({ fingers: 1, direction: PanDirection.All, distance: 8 })
        .onActionEnd((event: GestureEvent) => {
          const dx: number = event.offsetX;
          const dy: number = event.offsetY;
          if (Math.abs(dx) < 20 && Math.abs(dy) < 20) { return; }
          if (Math.abs(dx) > Math.abs(dy)) {
            this.move(dx > 0 ? 'right' : 'left');
          } else {
            this.move(dy > 0 ? 'down' : 'up');
          }
        })
    )
    .focusable(true)
  }

  @Builder
  ControlArea() {
    Column({ space: 4 }) {
      Row() {
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_up'))
            .fontSize(new BreakpointType(22, 24, 28, 30, 32).getValue(this.widthBp))
            .fontColor([$r('sys.color.icon_primary')])
        }
        .width(this.cellSize() * 0.82).height(this.cellSize() * 0.58)
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .borderRadius(8)
        .onClick(() => { this.move('up'); })
      }

      Row({ space: 4 }) {
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_backward'))
            .fontSize(new BreakpointType(22, 24, 28, 30, 32).getValue(this.widthBp))
            .fontColor([$r('sys.color.icon_primary')])
        }
        .width(this.cellSize() * 0.82).height(this.cellSize() * 0.58)
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .borderRadius(8)
        .onClick(() => { this.move('left'); })

        Button('重开')
          .width(this.cellSize() * 0.82).height(this.cellSize() * 0.58)
          .fontSize(new BreakpointType(12, 13, 14, 15, 16).getValue(this.widthBp))
          .backgroundColor('#8F7A66')
          .fontColor('#FFFFFF')
          .borderRadius(8)
          .onClick(() => { this.reset(); })

        Button() {
          SymbolGlyph($r('sys.symbol.chevron_forward'))
            .fontSize(new BreakpointType(22, 24, 28, 30, 32).getValue(this.widthBp))
            .fontColor([$r('sys.color.icon_primary')])
        }
        .width(this.cellSize() * 0.82).height(this.cellSize() * 0.58)
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .borderRadius(8)
        .onClick(() => { this.move('right'); })
      }

      Row() {
        Button() {
          SymbolGlyph($r('sys.symbol.chevron_down'))
            .fontSize(new BreakpointType(22, 24, 28, 30, 32).getValue(this.widthBp))
            .fontColor([$r('sys.color.icon_primary')])
        }
        .width(this.cellSize() * 0.82).height(this.cellSize() * 0.58)
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .borderRadius(8)
        .onClick(() => { this.move('down'); })
      }
    }
    .margin({ top: this.widthBp >= WidthBreakpoint.WIDTH_LG ? 0 : 12 })
  }
}
