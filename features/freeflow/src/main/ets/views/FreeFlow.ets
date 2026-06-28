import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BreakpointType, CommonConstants, Logger, WindowOrientationHelper } from 'base';
import {
  APP_STORAGE_KEY_FLOW_STATE, APP_STORAGE_KEY_RECOVERED,
  DEFAULT_FLOW_STATE, FlowRecord, FlowSnapshot, FlowState,
  SIMULATED_TARGET_DEVICES, deserializeFlowState, serializeFlowState
} from '../model/FlowStateModel';

@Builder
export function FreeFlowBuilder() {
  FreeFlow();
}

@Component
export struct FreeFlow {
  windowObj: window.Window | undefined = undefined;
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @State flowState: FlowState = FlowState.copy(DEFAULT_FLOW_STATE);
  @State isContinuing: boolean = false;
  @State showDevicePicker: boolean = false;
  @State showSnapshots: boolean = false;
  @State continueResult: string = '';
  @State snapshots: FlowSnapshot[] = [];
  @State flowHistory: FlowRecord[] = [];
  @State historyId: number = 0;
  @State snapshotId: number = 0;
  @State snapshotName: string = '';

  aboutToAppear(): void {
    try {
      this.windowObj = (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage.getMainWindowSync();
      this.windowObj?.setPreferredOrientation(WindowOrientationHelper.presets.FOLLOW_DESKTOP)
        .catch((err: BusinessError) => {
          Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
        });
    } catch (err) {
      Logger.error(`Invoke getMainWindowSync failed, code is ${err.code}, message is ${err.message}`)
    }

    const recovered: string | undefined = AppStorage.get<string>(APP_STORAGE_KEY_RECOVERED);
    if (recovered) {
      try {
        this.flowState = deserializeFlowState(recovered);
        this.continueResult = '已接收来自其他设备的流转状态';
        AppStorage.setOrCreate<string>(APP_STORAGE_KEY_RECOVERED, '');
        setTimeout(() => { this.continueResult = ''; }, 4000);
      } catch (err) {
        Logger.error(`Failed to recover: ${JSON.stringify(err)}`);
      }
    }

    this.syncToAppStorage();
  }

  aboutToDisappear(): void {
    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.presets.FIXED.UNSPECIFIED)
      .catch((err: BusinessError) => {
        Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
      });
  }

  syncToAppStorage(): void {
    const json: string = serializeFlowState(this.flowState);
    AppStorage.setOrCreate<string>(APP_STORAGE_KEY_FLOW_STATE, json);
  }

  updateState(partial: Partial<FlowState>): void {
    const updated: FlowState = FlowState.copy(this.flowState);
    if (partial.textContent !== undefined) { updated.textContent = partial.textContent; }
    if (partial.counter !== undefined) { updated.counter = partial.counter; }
    if (partial.scrollOffset !== undefined) { updated.scrollOffset = partial.scrollOffset; }
    if (partial.selectedTab !== undefined) { updated.selectedTab = partial.selectedTab; }
    updated.lastUpdateTime = Date.now();
    this.flowState = updated;
    this.syncToAppStorage();
  }

  continueToDevice(deviceName: string): void {
    this.showDevicePicker = false;
    this.isContinuing = true;
    this.continueResult = '';

    const snapshotName: string = `${deviceName} 流转`;
    this.saveSnapshot(snapshotName);

    setTimeout(() => {
      this.isContinuing = false;
      this.continueResult = `已成功流转到 ${deviceName}`;
      const now: Date = new Date();
      const record: FlowRecord = {
        id: ++this.historyId, direction: 'out', deviceName: deviceName,
        snapshotName: snapshotName, timestamp: now.getTime(), timeStr: this.formatTime(now),
      };
      this.flowHistory = [record].concat(this.flowHistory);
      setTimeout(() => { this.continueResult = ''; }, 4000);
    }, 2000);
  }

  simulateReceiveState(): void {
    const source: string = SIMULATED_TARGET_DEVICES[Math.floor(Math.random() * SIMULATED_TARGET_DEVICES.length)];
    this.isContinuing = true;
    this.continueResult = '';
    setTimeout(() => {
      this.updateState({
        textContent: `来自 ${source} 的流转内容 - ${Date.now()}`,
        counter: Math.floor(Math.random() * 50),
      });
      this.flowState.sourceDevice = source;
      this.syncToAppStorage();
      this.isContinuing = false;
      this.continueResult = `已接收来自 ${source} 的流转状态`;
      const now: Date = new Date();
      const record: FlowRecord = {
        id: ++this.historyId, direction: 'in', deviceName: source,
        snapshotName: '', timestamp: now.getTime(), timeStr: this.formatTime(now),
      };
      this.flowHistory = [record].concat(this.flowHistory);
      setTimeout(() => { this.continueResult = ''; }, 4000);
    }, 1500);
  }

  saveSnapshot(name: string): void {
    const snapshot: FlowSnapshot = {
      id: ++this.snapshotId,
      name: name || `快照 ${this.snapshotId + 1}`,
      state: FlowState.copy(this.flowState),
      timestamp: Date.now(),
      timeStr: this.formatTime(new Date()),
    };
    this.snapshots = [snapshot].concat(this.snapshots);
  }

  loadSnapshot(snapshot: FlowSnapshot): void {
    this.flowState = FlowState.copy(snapshot.state);
    this.flowState.lastUpdateTime = Date.now();
    this.syncToAppStorage();
    this.showSnapshots = false;
    this.continueResult = `已加载快照: ${snapshot.name}`;
    setTimeout(() => { this.continueResult = ''; }, 2000);
  }

  resetState(): void {
    this.flowState = FlowState.copy(DEFAULT_FLOW_STATE);
    this.flowState.lastUpdateTime = Date.now();
    this.syncToAppStorage();
    this.continueResult = '';
  }

  formatTime(date: Date): string {
    const h: string = String(date.getHours()).padStart(2, '0');
    const m: string = String(date.getMinutes()).padStart(2, '0');
    const s: string = String(date.getSeconds()).padStart(2, '0');
    return `${h}:${m}:${s}`;
  }

  formatDate(ts: number): string {
    const d: Date = new Date(ts);
    const M: string = String(d.getMonth() + 1).padStart(2, '0');
    const D: string = String(d.getDate()).padStart(2, '0');
    return `${M}-${D} ${this.formatTime(d)}`;
  }

  headerFontSize(): number {
    return new BreakpointType(13, 14, 15, 16, 17).getValue(this.widthBp);
  }

  @Builder
  StateCard(label: ResourceStr, value: string, icon: string) {
    Row() {
      Text(icon).fontSize(20)
      Column({ space: 2 }) {
        Text(label).fontSize(11).fontColor($r('sys.color.font_secondary'))
        Text(value).fontSize(16).fontWeight(FontWeight.Medium).fontColor($r('sys.color.font_primary'))
      }.alignItems(HorizontalAlign.Start).margin({ left: 10 }).layoutWeight(1)
    }
    .width(CommonConstants.FULL_PERCENT).padding(12)
    .backgroundColor($r('app.color.state_bg')).borderRadius(10)
    .border({ width: 1, color: $r('app.color.state_border') })
  }

  @Builder
  DevicePickerItem(deviceName: string) {
    Row() {
      Text('\u{1F4F1}').fontSize(24)
      Text(deviceName).fontSize(14).fontColor($r('sys.color.font_primary')).margin({ left: 10 }).layoutWeight(1)
      Text('\u{25B6}').fontSize(14)
    }
    .width(CommonConstants.FULL_PERCENT).padding(12)
    .backgroundColor($r('app.color.state_bg')).borderRadius(10)
    .onClick(() => { this.continueToDevice(deviceName); })
  }

  @Builder
  HistoryItem(record: FlowRecord) {
    Row() {
      Text(record.direction === 'out' ? '\u{27A1}' : '\u{2B05}')
        .fontSize(16)
      Column({ space: 2 }) {
        Text(`${record.direction === 'out' ? '流转至' : '接收自'} ${record.deviceName}`)
          .fontSize(12).fontColor($r('sys.color.font_primary'))
        Text(record.timeStr).fontSize(10).fontColor($r('sys.color.font_tertiary'))
      }.alignItems(HorizontalAlign.Start).margin({ left: 8 }).layoutWeight(1)
    }
    .width(CommonConstants.FULL_PERCENT).padding({ top: 8, bottom: 8 })
    .border({ width: { bottom: 0.5 }, color: { bottom: $r('app.color.state_border') } })
  }

  @Builder
  SnapshotItem(snap: FlowSnapshot) {
    Row() {
      Column({ space: 2 }) {
        Text(snap.name).fontSize(14).fontWeight(FontWeight.Medium).fontColor($r('sys.color.font_primary'))
        Text(`计数:${snap.state.counter} · ${snap.timeStr}`)
          .fontSize(11).fontColor($r('sys.color.font_secondary'))
        Text(snap.state.textContent.substring(0, 25))
          .fontSize(10).fontColor($r('sys.color.font_tertiary')).maxLines(1)
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)
      Button('加载').fontSize(11).type(ButtonType.Capsule)
        .backgroundColor($r('app.color.flow_primary')).borderRadius(14).height(28)
        .onClick(() => { this.loadSnapshot(snap); })
    }
    .width(CommonConstants.FULL_PERCENT).padding(10)
    .backgroundColor($r('app.color.state_bg')).borderRadius(8)
  }

  build() {
    NavDestination() {
      Column() {
        Row() {
          Text($r('app.string.flow_desc')).fontSize(this.headerFontSize()).fontColor($r('sys.color.font_secondary'))
        }.width(CommonConstants.FULL_PERCENT).padding({ top: 4, bottom: 6 })

        if (this.continueResult !== '') {
          Row() {
            Text('\u{2705}').fontSize(18)
            Text(this.continueResult).fontSize(13).fontColor('#4CAF50').fontWeight(FontWeight.Medium).margin({ left: 6 })
          }.width(CommonConstants.FULL_PERCENT).padding(10)
           .backgroundColor('#E8F5E9').borderRadius(8).margin({ bottom: 6 })
        }

        if (this.isContinuing) {
          Row({ space: 8 }) {
            LoadingProgress().width(24).height(24).color($r('app.color.flow_primary'))
            Text($r('app.string.transfer_animating')).fontSize(14).fontColor($r('app.color.flow_primary'))
          }.width(CommonConstants.FULL_PERCENT).padding(14)
           .backgroundColor('#E3F2FD').borderRadius(8).justifyContent(FlexAlign.Center)
        }

        if (this.widthBp >= WidthBreakpoint.WIDTH_LG) {
          Row({ space: 16 }) {
            Column() { this.StatePanelView() }.layoutWeight(3)
            Column({ space: 10 }) { this.ControlPanelView(); this.HistoryPanelView() }.layoutWeight(2)
          }.width(CommonConstants.FULL_PERCENT).layoutWeight(1).alignItems(VerticalAlign.Top)
        } else {
          this.StatePanelView()
          this.ControlPanelView()
          this.HistoryPanelView()
        }
      }
      .width(CommonConstants.FULL_PERCENT).height(CommonConstants.FULL_PERCENT)
      .padding({
        left: new BreakpointType(12, 16, 24, 32, 32).getValue(this.widthBp),
        right: new BreakpointType(12, 16, 24, 32, 32).getValue(this.widthBp),
        top: 8, bottom: 8
      })
    }
    .height(CommonConstants.FULL_PERCENT).width(CommonConstants.FULL_PERCENT)
    .title($r('app.string.flow_title'), { backgroundColor: $r('app.color.common_bg') })
    .backgroundColor($r('app.color.common_bg'))
  }

  @Builder
  StatePanelView() {
    Column({ space: 8 }) {
      Text($r('app.string.current_state')).fontSize(14).fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.font_primary')).width(CommonConstants.FULL_PERCENT)

      this.StateCard($r('app.string.state_text'), this.flowState.textContent, '\u{1F4C4}')
      this.StateCard($r('app.string.state_count'), `${this.flowState.counter}`, '\u{0023}')
      this.StateCard($r('app.string.state_position'), `${this.flowState.scrollOffset}vp`, '\u{2195}')

      if (this.flowState.sourceDevice) {
        Row() {
          Text('\u{1F4F1}').fontSize(16)
          Text(`${$r('app.string.flow_from_device')}: ${this.flowState.sourceDevice}`)
            .fontSize(12).fontColor($r('sys.color.font_secondary')).margin({ left: 6 })
        }.width(CommonConstants.FULL_PERCENT).padding(8).backgroundColor('#E3F2FD').borderRadius(8)
      }

      Text(`最后更新: ${this.formatDate(this.flowState.lastUpdateTime)}`)
        .fontSize(10).fontColor($r('sys.color.font_tertiary')).width(CommonConstants.FULL_PERCENT)

      Row({ space: 6 }) {
        Button($r('app.string.increment')).fontSize(11).type(ButtonType.Capsule)
          .backgroundColor($r('app.color.flow_primary')).borderRadius(14).height(30)
          .onClick(() => { this.updateState({ counter: this.flowState.counter + 1 }); })
        Button($r('app.string.decrement')).fontSize(11).type(ButtonType.Capsule)
          .backgroundColor($r('app.color.flow_warning')).borderRadius(14).height(30)
          .onClick(() => { this.updateState({ counter: Math.max(0, this.flowState.counter - 1) }); })
        Button($r('app.string.edit_text')).fontSize(11).type(ButtonType.Capsule)
          .backgroundColor($r('app.color.state_border')).borderRadius(14).height(30)
          .fontColor($r('sys.color.font_primary'))
          .onClick(() => { this.updateState({ textContent: '修改后的文本 ' + Date.now() }); })
      }.width(CommonConstants.FULL_PERCENT).margin({ top: 4 })

      Button() {
        Row({ space: 4 }) {
          Text('\u{1F4E5}').fontSize(16)
          Text('保存当前状态快照').fontSize(12).fontColor($r('app.color.flow_primary'))
        }
      }.type(ButtonType.Capsule).backgroundColor($r('app.color.state_bg')).borderRadius(16).height(32)
       .border({ width: 1, color: $r('app.color.flow_primary') })
       .onClick(() => { this.saveSnapshot(`快照 ${this.snapshotId + 1}`); })
    }
    .width(CommonConstants.FULL_PERCENT).padding(12)
    .backgroundColor($r('app.color.card_bg')).borderRadius(12)
    .shadow({ radius: 4, color: '#0D000000', offsetX: 0, offsetY: 1 }).margin({ bottom: 10 })
  }

  @Builder
  ControlPanelView() {
    Column({ space: 8 }) {
      Text('设备间流转').fontSize(13).fontWeight(FontWeight.Bold).fontColor($r('sys.color.font_primary'))
        .width(CommonConstants.FULL_PERCENT)

      Button() {
        Row({ space: 6 }) {
          Text('\u{27A1}').fontSize(18)
          Text($r('app.string.continue_btn')).fontSize(15).fontColor(Color.White)
        }
      }.width(CommonConstants.FULL_PERCENT).height(44)
       .backgroundColor($r('app.color.btn_continue')).borderRadius(22)
       .onClick(() => { this.showDevicePicker = true; })

      Text('提示: 在真机上可从最近任务向上滑动触发系统流转')
        .fontSize(10).fontColor($r('sys.color.font_tertiary')).textAlign(TextAlign.Center)
        .padding({ left: 8, right: 8 })

      Button() {
        Row({ space: 6 }) {
          Text('\u{2B05}').fontSize(18)
          Text($r('app.string.receive_btn')).fontSize(15).fontColor(Color.White)
        }
      }.width(CommonConstants.FULL_PERCENT).height(44)
       .backgroundColor($r('app.color.btn_receive')).borderRadius(22)
       .onClick(() => { this.simulateReceiveState(); })

      Button($r('app.string.reset_state')).fontSize(13).type(ButtonType.Capsule)
        .backgroundColor($r('app.color.btn_reset')).borderRadius(18).height(34).fontColor(Color.White)
        .onClick(() => { this.resetState(); })

      if (this.snapshots.length > 0) {
        Button() {
          Text(`查看快照 (${this.snapshots.length})`).fontSize(12).fontColor($r('app.color.flow_primary'))
        }.type(ButtonType.Capsule).backgroundColor($r('app.color.state_bg')).borderRadius(16).height(32)
         .border({ width: 1, color: $r('app.color.flow_primary') })
         .onClick(() => { this.showSnapshots = !this.showSnapshots; })

        if (this.showSnapshots) {
          Column({ space: 6 }) {
            ForEach(this.snapshots, (snap: FlowSnapshot) => {
              this.SnapshotItem(snap)
            }, (snap: FlowSnapshot) => snap.id.toString())
          }.width(CommonConstants.FULL_PERCENT)
        }
      }
    }
    .width(CommonConstants.FULL_PERCENT).padding(12)
    .backgroundColor($r('app.color.card_bg')).borderRadius(12)
    .shadow({ radius: 4, color: '#0D000000', offsetX: 0, offsetY: 1 }).margin({ bottom: 10 })

    if (this.showDevicePicker) {
      Column({ space: 6 }) {
        Text($r('app.string.select_device')).fontSize(13).fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary')).width(CommonConstants.FULL_PERCENT)
        ForEach(SIMULATED_TARGET_DEVICES, (device: string) => {
          this.DevicePickerItem(device)
        }, (device: string) => device)
        Button('取消').fontSize(12).type(ButtonType.Capsule)
          .backgroundColor($r('app.color.btn_reset')).borderRadius(14).height(30).fontColor(Color.White)
          .onClick(() => { this.showDevicePicker = false; })
      }.width(CommonConstants.FULL_PERCENT).padding(12)
       .backgroundColor($r('app.color.card_bg')).borderRadius(12)
       .border({ width: 2, color: $r('app.color.flow_primary') })
       .shadow({ radius: 8, color: '#1A000000', offsetX: 0, offsetY: 4 }).margin({ bottom: 10 })
    }
  }

  @Builder
  HistoryPanelView() {
    if (this.flowHistory.length > 0) {
      Column() {
        Text('流转记录').fontSize(13).fontWeight(FontWeight.Bold)
          .fontColor($r('sys.color.font_primary')).width(CommonConstants.FULL_PERCENT).margin({ bottom: 6 })
        ForEach(this.flowHistory, (record: FlowRecord) => {
          this.HistoryItem(record)
        }, (record: FlowRecord) => record.id.toString())
      }.width(CommonConstants.FULL_PERCENT).padding(12)
       .backgroundColor($r('app.color.card_bg')).borderRadius(12)
       .shadow({ radius: 4, color: '#0D000000', offsetX: 0, offsetY: 1 }).margin({ top: 4, bottom: 10 })
    }
  }
}
