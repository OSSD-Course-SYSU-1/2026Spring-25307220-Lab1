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

import { common } from "@kit.AbilityKit";
import { window } from "@kit.ArkUI";
import { VideoDetailView } from "./VideoDetailView";
import { KeyCode } from "@kit.InputKit";
import {
  AvPlayerUtil,
  CommonConstants,
  DetailConstants,
  BreakpointConstants,
  DeviceScreen,
  Logger,
  DisplayUtil,
  WindowOrientationHelper
} from "base";

@Builder
export function VideoDetailBuilder() {
  VideoDetail()
}

// [Start videoDetail]
// [Start videoDetailLifeCycle]
// [Start onWindowSizeChange]
// [Start windowSizeChange]
// [Start windowHelper]
@Component
export struct VideoDetail {
  // [StartExclude windowSizeChange]
  windowObj: window.Window | undefined = undefined;
  // [StartExclude onWindowSizeChange]
  // [StartExclude videoDetailLifeCycle]
  // [StartExclude windowHelper]
  @StorageLink('isFullScreen') @Watch('onFullScreenChange') isFullScreen: boolean = false;
  // [StartExclude videoDetail]
  // [EndExclude windowSizeChange]
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @StorageLink(CommonConstants.HEIGHT_BREAK_POINT) heightBp: HeightBreakpoint = HeightBreakpoint.HEIGHT_SM;
  // [StartExclude windowSizeChange]
  @StorageLink(CommonConstants.AV_PLAYER_STATE) avplayerState: string = '';
  @StorageLink('isClick') isClick: boolean = false;
  @Provide pathStack: NavPathStack = new NavPathStack();
  private screenHeight: number = 0;
  @State relatedVideoHeight: number = DetailConstants.INITIAL_RELATED_VIDEO_HEIGHT;
  @State videoHeight: number = DetailConstants.INITIAL_VIDEO_HEIGHT;
  private avPlayerUtil?: AvPlayerUtil = AvPlayerUtil.getInstance(this.getUIContext());
  @State commentImgHeight: string = DetailConstants.INITIAL_COMMENT_IMAGE_HEIGHT;
  @State commentImgWidth: string = DetailConstants.INITIAL_COMMENT_IMAGE_WIDTH;

  // [EndExclude videoDetail]
  // [EndExclude videoDetailLifeCycle]
  // [EndExclude onWindowSizeChange]
  // [EndExclude windowSizeChange]
  // [EndExclude windowHelper]

  // [StartExclude windowSizeChange]
  aboutToAppear() {
    // [StartExclude videoDetail]
    // [StartExclude windowHelper]
    try {
      this.windowObj = (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage.getMainWindowSync()
    } catch (err) {
      Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
    }

    // [StartExclude videoDetailLifeCycle]
    // [StartExclude onWindowSizeChange]
    DisplayUtil.getFoldCreaseRegion(this.getUIContext());
    this.screenHeight = DeviceScreen.getDeviceHeight();
    // [EndExclude videoDetail]
    // [EndExclude onWindowSizeChange]
    this.windowObj?.on('windowSizeChange', this.onWindowSizeChange);
    // [EndExclude videoDetailLifeCycle]
    // [EndExclude windowHelper]

    // [StartExclude videoDetail]
    // Dynamically select an appropriate rotation strategy through a selector.
    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.select({
      mode: 'autoRotate',
      range: 'ALL_ORIENTATIONS',
      preferred: 'UNSPECIFIED'
    }))
      .catch((err: BusinessError) => {
        Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
      });
    // [EndExclude videoDetail]
    // [EndExclude onWindowSizeChange]
  }

  // [StartExclude videoDetailLifeCycle]
  // [StartExclude onWindowSizeChange]
  onFullScreenChange(): void {
    if (this.isFullScreen) {
      if (this.isClick) {
        if (this.widthBp === WidthBreakpoint.WIDTH_SM || this.widthBp === WidthBreakpoint.WIDTH_LG ||
          this.heightBp === HeightBreakpoint.HEIGHT_LG) {
          // Dynamically select an appropriate rotation strategy through a selector.
          this.windowObj?.setPreferredOrientation(WindowOrientationHelper.select({
            mode: 'autoRotate',
            range: 'LANDSCAPE_ONLY'
          }))
            .catch((err: BusinessError) => {
              Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
            });
        }
      }
    } else {
      // Dynamically select an appropriate rotation strategy through a selector.
      this.windowObj?.setPreferredOrientation(WindowOrientationHelper.select({
        mode: 'autoRotate',
        range: 'ALL_ORIENTATIONS',
        preferred: 'UNSPECIFIED'
      }))
        .catch((err: BusinessError) => {
          Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
        });
    }
  }

  // [EndExclude windowSizeChange]

  private onWindowSizeChange: (windowSize: window.Size) => void = () => {
    if (this.isClick) {
      return;
    }
    if (this.widthBp === WidthBreakpoint.WIDTH_SM) {
      this.isFullScreen = false
      // Dynamically select an appropriate rotation strategy through a selector.
      this.windowObj?.setPreferredOrientation(WindowOrientationHelper.select({
        mode: 'autoRotate',
        range: 'ALL_ORIENTATIONS',
        preferred: 'UNSPECIFIED'
      }))
        .catch((err: BusinessError) => {
          Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
        });
    }

    if (this.widthBp === WidthBreakpoint.WIDTH_MD && this.heightBp === HeightBreakpoint.HEIGHT_SM) {
      this.isFullScreen = true;
    }
  };

  // [StartExclude videoDetail]
  // [Start offWindowSizeChange]
  // [StartExclude windowSizeChange]
  async aboutToDisappear() {
    // [StartExclude offWindowSizeChange]
    // [StartExclude windowHelper]
    this.isFullScreen = false;
    this.avPlayerUtil?.offTimeUpdate();
    // [EndExclude windowHelper]
    // Dynamically select an appropriate rotation strategy through a selector.
    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.select({
      mode: 'autoRotate',
      range: 'ALL_ORIENTATIONS',
      preferred: 'UNSPECIFIED'
    }))
      .catch((err: BusinessError) => {
        Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
      });
    // [EndExclude offWindowSizeChange]
    // [StartExclude windowHelper]
    this.windowObj?.off('windowSizeChange')
    // [EndExclude windowHelper]
  }

  // [End offWindowSizeChange]
  // [EndExclude videoDetail]
  // [EndExclude videoDetailLifeCycle]
  // [EndExclude windowSizeChange]

  build() {
    // [StartExclude windowHelper]
    // [StartExclude videoDetail]
    // [StartExclude videoDetailLifeCycle]
    // [StartExclude windowSizeChange]
    NavDestination() {
      GridRow({
        columns: {
          sm: BreakpointConstants.GRID_ROW_COLUMNS[2],
          md: BreakpointConstants.GRID_ROW_COLUMNS[0],
          lg: BreakpointConstants.GRID_ROW_COLUMNS[0]
        }
      }) {
        GridCol({
          span: {
            sm: BreakpointConstants.GRID_COLUMN_SPANS[5],
            md: BreakpointConstants.GRID_COLUMN_SPANS[0],
            lg: BreakpointConstants.GRID_COLUMN_SPANS[0]
          }
        }) {
          Column() {
            // Content area.
            VideoDetailView({
              screenHeight: this.screenHeight,
              relatedVideoHeight: this.relatedVideoHeight,
              videoHeight: this.videoHeight
            })
              .layoutWeight(1)
          }
          .height(CommonConstants.FULL_PERCENT)
          .width(CommonConstants.FULL_PERCENT)
        }
        .height(CommonConstants.FULL_PERCENT)
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(CommonConstants.FULL_PERCENT)
      .onBreakpointChange((breakPoints) => {
        if (breakPoints !== BreakpointConstants.BREAKPOINT_LG &&
          this.videoHeight < DetailConstants.INITIAL_VIDEO_HEIGHT) {
          this.relatedVideoHeight = 0;
        } else if (breakPoints === BreakpointConstants.BREAKPOINT_LG) {
          this.relatedVideoHeight = DetailConstants.INITIAL_RELATED_VIDEO_HEIGHT;
        } else {
          Logger.info(`No specific function`);
        }
      })
    }
    .ignoreLayoutSafeArea()
    .height(LayoutPolicy.matchParent)
    .hideTitleBar(true)
    .onShown(() => {
      if (this.avplayerState !== CommonConstants.AV_PLAYER_PLAYING_STATE) {
        this.avPlayerUtil!.playerStateControl();
      }
    })
    .onKeyEvent((event?: KeyEvent) => {
      if (!event || event.type !== KeyType.Down) {
        return;
      }
      if (event.keyCode === KeyCode.KEYCODE_SPACE) {
        this.avPlayerUtil!.playerStateControl();
      }
      if (event.keyCode === KeyCode.KEYCODE_ESCAPE) {
        this.windowObj?.recover()
          .catch((err: BusinessError) => {
            Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
          });
      }
      if (event.keyCode === KeyCode.KEYCODE_DPAD_RIGHT) {
        this.avPlayerUtil!.fastForward();
      }
      if (event.keyCode === KeyCode.KEYCODE_DPAD_LEFT) {
        this.avPlayerUtil!.rewind();
      }
    })
    .onReady((context: NavDestinationContext) => {
      this.pathStack = context.pathStack;
    })
    .onWillDisappear(() => {
      this.avPlayerUtil?.release()
    })
    // [EndExclude windowHelper]
    // [EndExclude videoDetail]
    // [EndExclude videoDetailLifeCycle]
  }

  // [EndExclude onWindowSizeChange]
  // [EndExclude windowSizeChange]
}
// [End windowHelper]
// [End videoDetail]
// [End videoDetailLifeCycle]
// [End onWindowSizeChange]
// [End windowSizeChange]