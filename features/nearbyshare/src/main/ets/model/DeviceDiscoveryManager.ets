import type { NearbyDevice } from './DeviceModel';

const SIMULATED_DEVICE_POOL: NearbyDevice[] = [
  {
    id: 'd1', deviceId: 'real-d1-uuid', networkId: 'net-phone-001',
    name: 'P60 Pro', type: 'phone', typeLabel: $r('app.string.device_phone'),
    signal: 4, distance: '0.5m', capabilities: ['share', 'wifi', 'bluetooth'],
    isFavorite: false, lastConnected: '今天 10:30', iconColor: $r('app.color.phone_icon'),
  },
  {
    id: 'd2', deviceId: 'real-d2-uuid', networkId: 'net-tablet-002',
    name: 'MatePad Pro', type: 'tablet', typeLabel: $r('app.string.device_tablet'),
    signal: 3, distance: '2.1m', capabilities: ['share', 'wifi', 'continuation'],
    isFavorite: true, lastConnected: '昨天 15:20', iconColor: $r('app.color.tablet_icon'),
  },
  {
    id: 'd3', deviceId: 'real-d3-uuid', networkId: 'net-fold-003',
    name: 'Mate X6', type: 'foldable', typeLabel: $r('app.string.device_foldable'),
    signal: 4, distance: '1.2m', capabilities: ['share', 'wifi', 'bluetooth', 'continuation'],
    isFavorite: false, lastConnected: '今天 09:00', iconColor: $r('app.color.foldable_icon'),
  },
  {
    id: 'd4', deviceId: 'real-d4-uuid', networkId: 'net-pc-004',
    name: 'MateBook X Pro', type: '2in1', typeLabel: $r('app.string.device_2in1'),
    signal: 2, distance: '3.5m', capabilities: ['share', 'wifi', 'continuation'],
    isFavorite: true, lastConnected: '3天前', iconColor: $r('app.color.pc_icon'),
  },
  {
    id: 'd5', deviceId: 'real-d5-uuid', networkId: 'net-car-005',
    name: '问界 M9', type: 'car', typeLabel: $r('app.string.device_car'),
    signal: 1, distance: '8.0m', capabilities: ['share', 'bluetooth'],
    isFavorite: false, lastConnected: '从未', iconColor: $r('app.color.car_icon'),
  },
  {
    id: 'd6', deviceId: 'real-d6-uuid', networkId: 'net-tv-006',
    name: '智慧屏 V5', type: 'tv', typeLabel: $r('app.string.device_tv'),
    signal: 3, distance: '4.2m', capabilities: ['share', 'wifi'],
    isFavorite: false, lastConnected: '1周前', iconColor: $r('app.color.tv_icon'),
  },
];

type DeviceFoundCallback = (device: NearbyDevice) => void;

export class DeviceDiscoveryManager {
  private static instance: DeviceDiscoveryManager;
  private discoveredDevices: NearbyDevice[] = [];
  private useRealApi: boolean = false;
  private isScanning: boolean = false;
  private scanTimer: number = -1;
  private callbacks: DeviceFoundCallback[] = [];

  static getInstance(): DeviceDiscoveryManager {
    if (!DeviceDiscoveryManager.instance) {
      DeviceDiscoveryManager.instance = new DeviceDiscoveryManager();
    }
    return DeviceDiscoveryManager.instance;
  }

  private constructor() {
    this.useRealApi = this.detectCapability();
  }

  private detectCapability(): boolean {
    try {
      return canIUse('SystemCapability.DistributedHardware.DeviceManager');
    } catch (_err) {
      return false;
    }
  }

  isRealApiAvailable(): boolean {
    return this.useRealApi;
  }

  getDiscoveredDevices(): NearbyDevice[] {
    return [...this.discoveredDevices];
  }

  onDeviceFound(callback: DeviceFoundCallback): void {
    this.callbacks.push(callback);
  }

  offDeviceFound(callback: DeviceFoundCallback): void {
    const idx: number = this.callbacks.indexOf(callback);
    if (idx !== -1) {
      this.callbacks.splice(idx, 1);
    }
  }

  private notifyDeviceFound(device: NearbyDevice): void {
    for (const cb of this.callbacks) {
      cb(device);
    }
  }

  async startDiscovery(): Promise<void> {
    if (this.isScanning) {
      return;
    }
    this.isScanning = true;
    this.discoveredDevices = [];

    if (this.useRealApi) {
      await this.startRealDiscovery();
    } else {
      this.startSimulatedDiscovery();
    }
  }

  stopDiscovery(): void {
    this.isScanning = false;
    if (this.scanTimer !== -1) {
      clearInterval(this.scanTimer);
      this.scanTimer = -1;
    }
  }

  private async startRealDiscovery(): Promise<void> {
    this.useRealApi = false;
    this.startSimulatedDiscovery();
  }

  private startSimulatedDiscovery(): void {
    let idx: number = 0;
    this.scanTimer = setInterval(() => {
      if (!this.isScanning) {
        clearInterval(this.scanTimer);
        return;
      }
      if (idx < SIMULATED_DEVICE_POOL.length) {
        const device: NearbyDevice = SIMULATED_DEVICE_POOL[idx];
        this.discoveredDevices.push(device);
        this.notifyDeviceFound(device);
        idx++;
      } else {
        this.stopDiscovery();
      }
    }, 600);
  }

  setFavorite(deviceId: string, favorite: boolean): void {
    const device: NearbyDevice | undefined = this.discoveredDevices.find((d) => d.id === deviceId);
    if (device) {
      device.isFavorite = favorite;
    }
  }

  private inferType(deviceType: string): string {
    if (deviceType.includes('phone')) { return 'phone'; }
    if (deviceType.includes('pad') || deviceType.includes('tablet')) { return 'tablet'; }
    if (deviceType.includes('pc')) { return '2in1'; }
    if (deviceType.includes('tv')) { return 'tv'; }
    if (deviceType.includes('car')) { return 'car'; }
    return 'phone';
  }

  private inferTypeLabel(deviceType: string): ResourceStr {
    if (deviceType.includes('pad') || deviceType.includes('tablet')) { return $r('app.string.device_tablet'); }
    if (deviceType.includes('pc')) { return $r('app.string.device_2in1'); }
    if (deviceType.includes('tv')) { return $r('app.string.device_tv'); }
    if (deviceType.includes('car')) { return $r('app.string.device_car'); }
    return $r('app.string.device_phone');
  }
}
