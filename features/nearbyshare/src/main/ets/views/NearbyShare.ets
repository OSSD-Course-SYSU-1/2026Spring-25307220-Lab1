import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { BreakpointType, CommonConstants, Logger, WindowOrientationHelper } from 'base';
import {
  CONTENT_TYPES, DiscoveryState, NearbyDevice, SendStage, TransferProgress, TransferRecord
} from '../model/DeviceModel';
import { DeviceDiscoveryManager } from '../model/DeviceDiscoveryManager';

@Builder
export function NearbyShareBuilder() {
  NearbyShare();
}

@Component
export struct NearbyShare {
  windowObj: window.Window | undefined = undefined;
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  // 发现状态
  @State discoveryState: DiscoveryState = DiscoveryState.IDLE;
  @State discoveredDevices: NearbyDevice[] = [];
  @State selectedDevice: NearbyDevice | null = null;
  // 发送状态
  @State sendStage: SendStage = SendStage.SELECT_DEVICE;
  @State selectedContent: number = 0;
  @State customText: string = '';
  @State transferProgress: TransferProgress | null = null;
  @State transferHistory: TransferRecord[] = [];
  @State historyId: number = 0;
  @State showSheet: boolean = false;

  private manager: DeviceDiscoveryManager = DeviceDiscoveryManager.getInstance();
  private deviceFoundCb: (device: NearbyDevice) => void = (device: NearbyDevice) => {
    this.discoveredDevices = this.manager.getDiscoveredDevices();
  };

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
    this.manager.onDeviceFound(this.deviceFoundCb);
  }

  aboutToDisappear(): void {
    this.manager.stopDiscovery();
    this.manager.offDeviceFound(this.deviceFoundCb);
    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.presets.FIXED.UNSPECIFIED)
      .catch((err: BusinessError) => {
        Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
      });
  }

  startScan(): void {
    this.discoveryState = DiscoveryState.SCANNING;
    this.selectedDevice = null;
    this.sendStage = SendStage.SELECT_DEVICE;
    this.manager.startDiscovery().then(() => {
      this.discoveryState = DiscoveryState.COMPLETE;
    });
  }

  stopScan(): void {
    this.manager.stopDiscovery();
    this.discoveryState = DiscoveryState.IDLE;
  }

  selectDevice(device: NearbyDevice): void {
    this.selectedDevice = device;
    this.showSheet = true;
  }

  startSend(): void {
    this.showSheet = false;
    this.sendStage = SendStage.TRANSFERRING;
    const contentName: string = this.customText ? this.customText.substring(0, 15) : CONTENT_TYPES[this.selectedContent];
    const totalSize: number = this.customText ? this.customText.length * 2 : 1024;
    this.transferProgress = {
      contentName: contentName, contentSize: `${totalSize}B`,
      transferred: 0, total: 100, speed: '0 B/s', state: 'connecting'
    };

    let transferred: number = 0;
    const timer: number = setInterval(() => {
      transferred += Math.floor(Math.random() * 20) + 5;
      if (transferred >= 100) {
        transferred = 100;
        clearInterval(timer);
        if (this.transferProgress) {
          this.transferProgress.transferred = 100;
          this.transferProgress.state = 'complete';
          this.transferProgress.speed = '完成';
        }
        this.sendStage = SendStage.COMPLETE;
        this.addHistoryRecord(true);
      } else if (this.transferProgress) {
        this.transferProgress.transferred = transferred;
        this.transferProgress.state = 'transferring';
        this.transferProgress.speed = `${Math.floor(Math.random() * 20 + 10)} KB/s`;
      }
    }, 200);

    setTimeout(() => {
      if (this.transferProgress && this.transferProgress.state === 'connecting') {
        this.transferProgress.state = 'transferring';
        this.transferProgress.speed = '0 B/s';
      }
    }, 800);
  }

  addHistoryRecord(success: boolean): void {
    if (!this.selectedDevice) { return; }
    const now: Date = new Date();
    const record: TransferRecord = {
      id: ++this.historyId,
      deviceName: this.selectedDevice.name,
      contentType: CONTENT_TYPES[this.selectedContent],
      contentSize: this.transferProgress?.contentSize || 'N/A',
      duration: `${Math.floor(Math.random() * 3) + 1}s`,
      timestamp: now.getTime(),
      timeStr: this.formatTime(now),
      success: success,
    };
    this.transferHistory = [record, ...this.transferHistory];
  }

  resetSend(): void {
    this.sendStage = SendStage.SELECT_DEVICE;
    this.transferProgress = null;
    this.selectedDevice = null;
    this.customText = '';
  }

  formatTime(date: Date): string {
    const h: string = String(date.getHours()).padStart(2, '0');
    const m: string = String(date.getMinutes()).padStart(2, '0');
    const s: string = String(date.getSeconds()).padStart(2, '0');
    return `${h}:${m}:${s}`;
  }

  signalWidth(level: number): number {
    return level * 6;
  }

  deviceIconText(type: string): string {
    switch (type) {
      case 'phone': return '\u{1F4F1}';
      case 'tablet': return '\u{1F4F1}';
      case 'foldable': return '\u{1F4F1}';
      case '2in1': return '\u{1F4BB}';
      case 'car': return '\u{1F697}';
      case 'tv': return '\u{1F4FA}';
      default: return '\u{1F4F1}';
    }
  }

  headerFontSize(): number {
    return new BreakpointType(13, 14, 15, 16, 17).getValue(this.widthBp);
  }

  @Builder
  RadarAnimation() {
    Stack({ alignContent: Alignment.Center }) {
      ForEach([3, 2, 1], (ring: number) => {
        Circle({ width: ring * 32, height: ring * 32 })
          .fill(Color.Transparent)
          .stroke($r('app.color.scan_active'))
          .strokeWidth(1.5)
          .opacity(0.3)
          .scale({ x: this.discoveryState === DiscoveryState.SCANNING ? 1.3 : 1, y: this.discoveryState === DiscoveryState.SCANNING ? 1.3 : 1 })
          .animation({ duration: 1200 * ring, curve: Curve.Linear, iterations: -1, playMode: PlayMode.Normal })
      }, (ring: number) => `ring_${ring}`)
      Text('\u{1F4F6}')
        .fontSize(40)
    }
    .width(120).height(120)
  }

  @Builder
  DeviceCard(device: NearbyDevice) {
    Row() {
      Column() {
        Text(this.deviceIconText(device.type))
          .fontSize(36)
      }
      .width(56).height(56)
      .borderRadius(12)
      .backgroundColor($r('app.color.device_bg'))
      .justifyContent(FlexAlign.Center)

      Column({ space: 3 }) {
        Row({ space: 6 }) {
          Text(device.name).fontSize(15).fontWeight(FontWeight.Medium).fontColor($r('sys.color.font_primary'))
          if (device.isFavorite) {
            Text('\u{2B50}')
              .fontSize(12)
          }
        }
        Row({ space: 4 }) {
          Text(device.typeLabel).fontSize(11).fontColor($r('sys.color.font_secondary'))
          Text(`· ${device.distance}`).fontSize(11).fontColor($r('sys.color.font_tertiary'))
        }
        Row({ space: 2 }) {
          ForEach(device.capabilities, (cap: string) => {
            Text(cap).fontSize(9).fontColor($r('app.color.scan_active'))
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .backgroundColor('#E3F2FD').borderRadius(3)
          }, (cap: string) => `${device.id}_${cap}`)
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)

      Column({ space: 2 }) {
        Row({ space: 1 }) {
          ForEach([0, 1, 2, 3], (idx: number) => {
            Circle({ width: 5 + idx * 2.5, height: 5 + idx * 2.5 })
              .fill(idx < device.signal ? $r('app.color.scan_active') : $r('app.color.device_border'))
          }, (idx: number) => `sig_${device.id}_${idx}`)
        }
        if (this.sendStage === SendStage.SELECT_DEVICE) {
          Button($r('app.string.tap_to_send'))
            .fontSize(11).type(ButtonType.Capsule)
            .backgroundColor($r('app.color.scan_active')).borderRadius(16).height(30)
            .onClick(() => { this.selectDevice(device); })
        }
      }
    }
    .width(CommonConstants.FULL_PERCENT)
    .padding(12)
    .backgroundColor(device === this.selectedDevice ? '#E3F2FD' : $r('app.color.device_bg'))
    .borderRadius(12)
    .border({ width: device === this.selectedDevice ? 1.5 : 0.5, color: device === this.selectedDevice ? $r('app.color.scan_active') : $r('app.color.device_border') })
    .shadow(device === this.selectedDevice ? { radius: 8, color: '#1A1976D2', offsetX: 0, offsetY: 2 } : { radius: 0, color: '#00000000', offsetX: 0, offsetY: 0 })
  }

  @Builder
  HistoryItem(record: TransferRecord) {
    Row() {
      Column({ space: 2 }) {
        Text(record.deviceName).fontSize(13).fontWeight(FontWeight.Medium).fontColor($r('sys.color.font_primary'))
        Text(`${record.contentType} · ${record.contentSize} · ${record.duration}`)
          .fontSize(11).fontColor($r('sys.color.font_secondary'))
      }
      .alignItems(HorizontalAlign.Start).layoutWeight(1)
      Column({ space: 2 }) {
        Text(record.timeStr).fontSize(11).fontColor($r('sys.color.font_tertiary'))
        Row({ space: 4 }) {
          Circle({ width: 6, height: 6 }).fill(record.success ? '#4CAF50' : '#FF1744')
          Text(record.success ? '成功' : '失败').fontSize(10).fontColor($r('sys.color.font_tertiary'))
        }
      }.alignItems(HorizontalAlign.End)
    }
    .width(CommonConstants.FULL_PERCENT).padding({ top: 8, bottom: 8 })
    .border({ width: { bottom: 0.5 }, color: { bottom: $r('app.color.device_border') } })
  }

  @Builder
  ContentSheet() {
    Column({ space: 12 }) {
      Text('选择发送内容').fontSize(16).fontWeight(FontWeight.Bold).fontColor($r('sys.color.font_primary'))
        .width(CommonConstants.FULL_PERCENT)

      Row({ space: 8 }) {
        ForEach(CONTENT_TYPES, (type: string, idx: number) => {
          Text(type)
            .fontSize(13)
            .fontWeight(this.selectedContent === idx ? FontWeight.Bold : FontWeight.Normal)
            .fontColor(this.selectedContent === idx ? '#FFFFFF' : $r('sys.color.font_secondary'))
            .padding({ left: 14, right: 14, top: 7, bottom: 7 })
            .backgroundColor(this.selectedContent === idx ? $r('app.color.scan_active') : $r('app.color.device_bg'))
            .borderRadius(18)
            .onClick(() => { this.selectedContent = idx; this.customText = ''; })
        }, (type: string) => type)
      }

      if (this.selectedContent === 0) {
        TextInput({ text: this.customText, placeholder: '输入要发送的文本内容...' })
          .width(CommonConstants.FULL_PERCENT).height(80)
          .borderRadius(8).backgroundColor($r('app.color.device_bg'))
          .onChange((value: string) => { this.customText = value; })
      } else if (this.selectedContent === 1) {
        Row() {
          Text('\u{23F9}').fontSize(20)
          Text('发送游戏最高分: 2048').fontSize(13).fontColor($r('sys.color.font_secondary'))
        }.padding(12).borderRadius(8).backgroundColor($r('app.color.device_bg')).width(CommonConstants.FULL_PERCENT)
      } else {
        Row() {
          Text('\u{1F4CB}').fontSize(20)
          Text('发送旋转事件日志 (12条)').fontSize(13).fontColor($r('sys.color.font_secondary'))
        }.padding(12).borderRadius(8).backgroundColor($r('app.color.device_bg')).width(CommonConstants.FULL_PERCENT)
      }

      Row({ space: 12 }) {
        Button('取消').fontSize(13).type(ButtonType.Capsule)
          .backgroundColor('#757575').borderRadius(16).height(36).fontColor(Color.White)
          .onClick(() => { this.showSheet = false; })
        Button('确认发送').fontSize(13).type(ButtonType.Capsule)
          .backgroundColor($r('app.color.scan_active')).borderRadius(16).height(36).fontColor(Color.White)
          .layoutWeight(1)
          .onClick(() => { this.startSend(); })
      }.width(CommonConstants.FULL_PERCENT).padding({ top: 4 })
    }
    .width(CommonConstants.FULL_PERCENT)
    .padding(16)
    .backgroundColor(Color.White)
    .borderRadius({ topLeft: 20, topRight: 20 })
  }

  @Builder
  TransferView() {
    Column({ space: 12 }) {
      if (this.transferProgress) {
        Row({ space: 12 }) {
          Text(this.deviceIconText(this.selectedDevice?.type || 'phone'))
            .fontSize(36)
          Column({ space: 4 }) {
            Text(`发送至 ${this.selectedDevice?.name}`).fontSize(15).fontWeight(FontWeight.Medium)
              .fontColor($r('sys.color.font_primary'))
            Text(this.transferProgress.contentName).fontSize(12).fontColor($r('sys.color.font_secondary'))
            Text(`${this.transferProgress.speed}`).fontSize(11).fontColor($r('sys.color.font_tertiary'))
          }.alignItems(HorizontalAlign.Start).layoutWeight(1)
        }.width(CommonConstants.FULL_PERCENT)

        Progress({
          value: this.transferProgress.transferred,
          total: this.transferProgress.total,
          type: ProgressType.Linear
        })
          .width(CommonConstants.FULL_PERCENT)
          .color($r('app.color.scan_active'))
          .animation({ duration: 200 })

        if (this.sendStage === SendStage.COMPLETE) {
          Row({ space: 8 }) {
            Text('\u{2705}').fontSize(28)
            Text('发送成功!').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#4CAF50')
          }.width(CommonConstants.FULL_PERCENT).padding(16)
          .backgroundColor('#E8F5E9').borderRadius(12).justifyContent(FlexAlign.Center)
        }
      }
    }
    .width(CommonConstants.FULL_PERCENT).padding(16)
    .backgroundColor($r('app.color.card_bg')).borderRadius(12)
    .shadow({ radius: 4, color: '#0D000000', offsetX: 0, offsetY: 1 })
  }

  build() {
    Stack() {
      NavDestination() {
        Column() {
        Row() {
          Text($r('app.string.nearby_desc'))
            .fontSize(this.headerFontSize()).fontColor($r('sys.color.font_secondary'))
          if (this.manager.isRealApiAvailable()) {
            Text(' ● 分布式')
              .fontSize(10).fontColor('#4CAF50')
              .padding({ left: 4, right: 4, top: 1, bottom: 1 })
              .backgroundColor('#E8F5E9').borderRadius(4).margin({ left: 6 })
          }
        }.width(CommonConstants.FULL_PERCENT).padding({ top: 4, bottom: 8 })

        if (this.sendStage === SendStage.TRANSFERRING || this.sendStage === SendStage.COMPLETE) {
          this.TransferView()
          if (this.widthBp >= WidthBreakpoint.WIDTH_LG) {
            Row({ space: 16 }) {
              Column() { this.HistoryView() }.layoutWeight(2)
              Column().layoutWeight(3)
            }.width(CommonConstants.FULL_PERCENT).layoutWeight(1).alignItems(VerticalAlign.Top)
          } else {
            this.HistoryView()
          }
        } else {
          Row() {
            Button(this.discoveryState === DiscoveryState.SCANNING ? $r('app.string.stop_scan') : $r('app.string.scan_button'))
              .fontSize(14).type(ButtonType.Capsule)
              .backgroundColor(this.discoveryState === DiscoveryState.SCANNING ? '#FF1744' : $r('app.color.scan_active'))
              .borderRadius(20).height(40)
              .onClick(() => {
                if (this.discoveryState === DiscoveryState.SCANNING) { this.stopScan(); }
                else { this.startScan(); }
              })
            if (this.discoveryState === DiscoveryState.SCANNING) {
              Row({ space: 4 }) {
                LoadingProgress().width(16).height(16).color($r('app.color.scan_active'))
                Text($r('app.string.scanning')).fontSize(12).fontColor($r('sys.color.font_secondary'))
              }.margin({ left: 8 })
            }
            Blank()
            Text(`${this.discoveredDevices.length} 台`).fontSize(12).fontColor($r('sys.color.font_tertiary'))
          }.width(CommonConstants.FULL_PERCENT).padding({ top: 4, bottom: 8 })

          if (this.discoveredDevices.length === 0) {
            Column({ space: 16 }) {
              this.RadarAnimation()
              Text(this.discoveryState === DiscoveryState.SCANNING ? $r('app.string.scanning') : $r('app.string.no_devices'))
                .fontSize(14).fontColor($r('sys.color.font_secondary'))
              if (this.discoveryState === DiscoveryState.IDLE) {
                Text('点击"开始扫描"发现附近设备').fontSize(12).fontColor($r('sys.color.font_tertiary'))
              }
            }
            .width(CommonConstants.FULL_PERCENT)
            .layoutWeight(1).justifyContent(FlexAlign.Center)
          } else if (this.widthBp >= WidthBreakpoint.WIDTH_LG) {
            Row({ space: 16 }) {
              Column() {
                Text($r('app.string.device_found')).fontSize(12).fontColor($r('sys.color.font_tertiary')).margin({ bottom: 6 })
                Scroll() {
                  Column({ space: 8 }) {
                    ForEach(this.discoveredDevices, (device: NearbyDevice) => {
                      this.DeviceCard(device)
                    }, (device: NearbyDevice) => device.id)
                  }
                }.scrollBar(BarState.Off)
              }.layoutWeight(3)
              Column() { this.HistoryView() }.layoutWeight(2)
            }.width(CommonConstants.FULL_PERCENT).layoutWeight(1).alignItems(VerticalAlign.Top)
          } else {
            Text($r('app.string.device_found')).fontSize(12).fontColor($r('sys.color.font_tertiary')).margin({ bottom: 4 })
            Scroll() {
              Column({ space: 8 }) {
                ForEach(this.discoveredDevices, (device: NearbyDevice) => {
                  this.DeviceCard(device)
                }, (device: NearbyDevice) => device.id)
              }.padding({ bottom: 8 })
            }.scrollBar(BarState.Off).layoutWeight(1)
            this.HistoryView()
          }
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
      .title($r('app.string.nearby_title'), { backgroundColor: $r('app.color.common_bg') })
      .backgroundColor($r('app.color.common_bg'))

      if (this.showSheet) {
        Column() { Blank() }
          .width(CommonConstants.FULL_PERCENT).height(CommonConstants.FULL_PERCENT)
          .backgroundColor('#66000000').position({ x: 0, y: 0 })
          .onClick(() => { this.showSheet = false; })
        Column() {
          Blank()
          this.ContentSheet()
        }.width(CommonConstants.FULL_PERCENT).height(CommonConstants.FULL_PERCENT)
         .position({ x: 0, y: 0 })
      }
    }
  }

  @Builder
  HistoryView() {
    if (this.transferHistory.length > 0) {
      Column() {
        Text($r('app.string.transfer_history'))
          .fontSize(14).fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))
          .width(CommonConstants.FULL_PERCENT)
          .margin({ top: 12, bottom: 6 })
        Column() {
          ForEach(this.transferHistory, (record: TransferRecord) => {
            this.HistoryItem(record)
          }, (record: TransferRecord) => record.id.toString())
        }
        .padding(12).backgroundColor($r('app.color.device_bg')).borderRadius(12)
        .border({ width: 0.5, color: $r('app.color.device_border') })
      }.margin({ bottom: 8 })
    }
  }
}
