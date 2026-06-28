export class FlowState {
  textContent: string = '';
  counter: number = 0;
  scrollOffset: number = 0;
  selectedTab: number = 0;
  lastUpdateTime: number = 0;
  sourceDevice?: string | undefined;

  static copy(src: FlowState): FlowState {
    const f = new FlowState();
    f.textContent = src.textContent;
    f.counter = src.counter;
    f.scrollOffset = src.scrollOffset;
    f.selectedTab = src.selectedTab;
    f.lastUpdateTime = src.lastUpdateTime;
    f.sourceDevice = src.sourceDevice;
    return f;
  }
}

export interface FlowSnapshot {
  id: number;
  name: string;
  state: FlowState;
  timestamp: number;
  timeStr: string;
}

export interface FlowRecord {
  id: number;
  direction: 'out' | 'in';
  deviceName: string;
  snapshotName: string;
  timestamp: number;
  timeStr: string;
}

export const DEFAULT_FLOW_STATE: FlowState = new FlowState();
DEFAULT_FLOW_STATE.textContent = '这是可以在设备间流转的内容';
DEFAULT_FLOW_STATE.lastUpdateTime = Date.now();

export const APP_STORAGE_KEY_FLOW_STATE: string = 'flowStateForContinue';
export const APP_STORAGE_KEY_RECOVERED: string = 'recoveredFlowState';

export function serializeFlowState(state: FlowState): string {
  try {
    return JSON.stringify(state);
  } catch (_err) {
    return JSON.stringify(DEFAULT_FLOW_STATE);
  }
}

export function deserializeFlowState(json: string): FlowState {
  const f: FlowState = new FlowState();
  try {
    const obj: Record<string, Object> = JSON.parse(json) as Record<string, Object>;
    f.textContent = (obj['textContent'] as string) || DEFAULT_FLOW_STATE.textContent;
    f.counter = (obj['counter'] as number) || DEFAULT_FLOW_STATE.counter;
    f.scrollOffset = (obj['scrollOffset'] as number) || DEFAULT_FLOW_STATE.scrollOffset;
    f.selectedTab = (obj['selectedTab'] as number) || DEFAULT_FLOW_STATE.selectedTab;
    f.lastUpdateTime = (obj['lastUpdateTime'] as number) || Date.now();
    f.sourceDevice = obj['sourceDevice'] as string | undefined;
  } catch (_err) {
    f.textContent = DEFAULT_FLOW_STATE.textContent;
    f.lastUpdateTime = Date.now();
  }
  return f;
}

export const SIMULATED_TARGET_DEVICES: string[] = [
  'MatePad Pro (平板)',
  'Mate X6 (折叠屏)',
  'MateBook X Pro (笔记本)',
  'P60 Pro (手机)',
];
