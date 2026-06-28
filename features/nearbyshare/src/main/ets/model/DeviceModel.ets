export interface NearbyDevice {
  id: string;
  deviceId: string;
  networkId: string;
  name: string;
  type: string;
  typeLabel: ResourceStr;
  iconColor: Resource;
  signal: number;
  distance: string;
  capabilities: string[];
  isFavorite: boolean;
  lastConnected: string;
}

export interface TransferProgress {
  contentName: string;
  contentSize: string;
  transferred: number;
  total: number;
  speed: string;
  state: 'connecting' | 'transferring' | 'complete' | 'error';
}

export interface TransferRecord {
  id: number;
  deviceName: string;
  contentType: string;
  contentSize: string;
  duration: string;
  timestamp: number;
  timeStr: string;
  success: boolean;
}

export enum DiscoveryState {
  IDLE = 'idle',
  SCANNING = 'scanning',
  COMPLETE = 'complete',
}

export enum SendStage {
  SELECT_DEVICE = 'selectDevice',
  SELECT_CONTENT = 'selectContent',
  CONFIRM = 'confirm',
  TRANSFERRING = 'transferring',
  COMPLETE = 'complete',
}

export const CONTENT_TYPES: string[] = ['文本消息', '游戏最高分', '旋转事件日志'];
