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

import { display, window } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { AvPlayerUtil, CommonConstants, Logger, WindowOrientationHelper } from 'base';

// [Start videoPlayer]
@Component
export struct VideoPlayer {
  // [StartExclude videoPlayer]
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @StorageLink(CommonConstants.AV_PLAYER_CURRENT_TIME) currentTime: string = CommonConstants.INITIAL_TIME;
  @StorageLink('totalTime') totalTime: string = CommonConstants.INITIAL_TIME;
  // [EndExclude videoPlayer]
  @StorageLink('isHalfFolded') isHalfFolded: boolean = false;
  // [StartExclude videoPlayer]
  @StorageLink('creaseRegion') creaseRegion: number[] = [];
  @StorageLink('progress') progress: number = 0;
  @StorageLink(CommonConstants.AV_PLAYER_STATE) avplayerState: string = '';
  @StorageLink('isFullScreen') isFullScreen: boolean = false;
  @StorageLink('isClick') isClick: boolean = false;
  @Link videoHeight: number;
  @Link isShowingSideBar: boolean;
  @Link foldStatus: display.FoldStatus;
  @Consume pathStack: NavPathStack;
  windowObj: window.Window | undefined = undefined;
  private avPlayerUtil?: AvPlayerUtil;
  private xComponentController: XComponentController = new XComponentController();
  // [EndExclude videoPlayer]
  private onFoldStatusChange: Callback<display.FoldStatus> = (data: display.FoldStatus) => {
    this.foldStatus = data;
    if (canIUse('SystemCapability.Window.SessionManager')) {
      if (data === display.FoldStatus.FOLD_STATUS_EXPANDED || data === display.FoldStatus.FOLD_STATUS_FOLDED ||
        data === display.FoldStatus.FOLD_STATUS_EXPANDED_WITH_SECOND_EXPANDED ||
        data === display.FoldStatus.FOLD_STATUS_FOLDED_WITH_SECOND_EXPANDED) {
        let widthBp: WidthBreakpoint = this.getUIContext().getWindowWidthBreakpoint();
        AppStorage.setOrCreate(CommonConstants.WIDTH_BREAK_POINT, widthBp);
        let heightBp: HeightBreakpoint = this.getUIContext().getWindowHeightBreakpoint();
        AppStorage.setOrCreate(CommonConstants.HEIGHT_BREAK_POINT, heightBp);
      }
      if (this.isFullScreen) {
        if (data === display.FoldStatus.FOLD_STATUS_FOLDED_WITH_SECOND_EXPANDED) {
          this.windowObj?.setPreferredOrientation(WindowOrientationHelper.select({
            mode: 'autoRotate',
            range: 'LANDSCAPE_ONLY'
          }))
            .catch((err: BusinessError) => {
              Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
            });
        }
      } else {
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
  };

  aboutToAppear(): void {
    // [StartExclude videoPlayer]
    try {
      this.windowObj = (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage.getMainWindowSync()
    } catch (err) {
      Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
    }

    this.avPlayerUtil = AvPlayerUtil.getInstance(this.getUIContext());
    // [EndExclude videoPlayer]
    if (canIUse('SystemCapability.Window.SessionManager')) {
      try {
        display.on('foldStatusChange', this.onFoldStatusChange);
      } catch (error) {
        let err = error as BusinessError;
        Logger.error('VideoPlayer', `onFoldStatusChange failed, code = ${err.code}, message = ${err.message}`);
      }
    }
  }

  // [StartExclude videoPlayer]
  aboutToDisappear(): void {
    if (canIUse('SystemCapability.Window.SessionManager')) {
      try {
        display.off('foldStatusChange', this.onFoldStatusChange);
      } catch (error) {
        let err = error as BusinessError;
        Logger.error('VideoPlayer', `onFoldStatusChange failed, code = ${err.code}, message = ${err.message}`);
      }
    }
  }

  // [EndExclude videoPlayer]

  build() {
    // [StartExclude videoPlayer]
    Stack({ alignContent: this.isFullScreen ? Alignment.Center : Alignment.Bottom }) {
      Flex({
        direction: FlexDirection.Column,
        justifyContent: this.isHalfFolded ? FlexAlign.Start : FlexAlign.Center,
        alignItems: ItemAlign.Start
      }) {
        Column() {
          XComponent({
            id: 'home',
            type: XComponentType.SURFACE,
            controller: this.xComponentController
          })
            .onLoad(() => {
              this.avPlayerUtil?.createAvPlayer(this.xComponentController.getXComponentSurfaceId());
              AppStorage.setOrCreate(CommonConstants.DETAIL_SURFACE_ID,
                this.xComponentController.getXComponentSurfaceId());
            })
            .width(this.isFullScreen ? -1 : this.videoHeight + '%')
            .aspectRatio(1.78)
        }
        .justifyContent(FlexAlign.Center)
        .height(this.isHalfFolded ? this.creaseRegion[0] : (this.isFullScreen ? CommonConstants.FULL_PERCENT : 'auto'))
        .width(CommonConstants.FULL_PERCENT)
      }
      .width(CommonConstants.FULL_PERCENT)
      .onClick(() => {
        if (this.isShowingSideBar) {
          this.isShowingSideBar = false;
        } else {
          this.avPlayerUtil?.playerStateControl();
        }
      })
      .priorityGesture(
        TapGesture({ count: 2 })
          .onAction((event: GestureEvent) => {
            if (event && deviceInfo.deviceType === CommonConstants.DEVICE_2IN1) {
              this.isFullScreen = true;
              this.windowObj?.maximize()
                .catch((err: BusinessError) => {
                  Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
                });
            }
          })
      )

      Column() {
        Row() {
          TimeText({ time: this.currentTime })
            .margin({
              left: 36,
              right: 2
            })

          Slider({
            min: 0,
            max: 100,
            step: 1,
            value: this.progress
          })
            .onChange((value: number, mode: SliderChangeMode) => {
              this.avPlayerUtil?.sliderChange(value, mode);
            })
            .layoutWeight(1)
            .selectedColor($r('app.color.selected_color'))

          TimeText({ time: this.totalTime })
            .margin({
              left: 2,
              right: 36
            })
        }
        .width(CommonConstants.FULL_PERCENT)
        .height(40)
        .alignItems(VerticalAlign.Center)
        .visibility(this.isFullScreen ? Visibility.Visible : Visibility.None)

        Row() {
          Row() {
            Image(this.avplayerState === 'playing' ? $r('app.media.ic_public_pause') : $r('app.media.ic_public_play'))
              .height(24)
              .width(24)
              .margin({ left: 24 })
              .onClick(() => {
                this.avPlayerUtil?.playerStateControl();
              })
            this.ImgIcon($r('app.media.ic_public_play_next'))
            this.ImgIcon($r('app.media.ic_public_view_list_white'))
          }
          .margin({
            top: this.widthBp === WidthBreakpoint.WIDTH_SM ? '0' : 14,
            bottom: this.widthBp === WidthBreakpoint.WIDTH_SM ? 15 : 24
          })

          Blank()

          Row() {
            this.TextButton($r('app.string.selections'), () => {
              this.isShowingSideBar = !this.isShowingSideBar;
            })
            this.TextButton($r('app.string.super'))
            this.TextButton($r('app.string.super'))
          }
          .margin({
            top: this.widthBp === WidthBreakpoint.WIDTH_SM ? 4 : 16,
            bottom: this.widthBp === WidthBreakpoint.WIDTH_SM ? 19 : 28
          })
        }
        .height(60)
        .width(CommonConstants.FULL_PERCENT)
        .visibility(this.isFullScreen ? Visibility.Visible : Visibility.None)
      }
      .height(this.isFullScreen ? CommonConstants.FULL_PERCENT : 'auto')
      .width(CommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.End)
      .visibility(this.isFullScreen && !this.isShowingSideBar ? Visibility.Visible : Visibility.None)
      .priorityGesture(
        TapGesture({ count: 2 })
          .onAction((event: GestureEvent) => {
            if (event && deviceInfo.deviceType === CommonConstants.DEVICE_2IN1) {
              if (this.isFullScreen) {
                this.windowObj?.recover()
                  .catch((err: BusinessError) => {
                    Logger.error(`Invoke window recover failed, code is ${err.code}, message is ${err.message}`)
                  });
                this.isFullScreen = false;
              } else {
                this.windowObj?.maximize()
                  .catch((err: BusinessError) => {
                    Logger.error(`Invoke window maximize failed, code is ${err.code}, message is ${err.message}`)
                  });
                this.isFullScreen = true;
              }
            }
          })
      )

      Row() {
        TimeText({ time: this.currentTime })
          .margin({
            left: 24,
            right: 24
          })

        Slider({
          min: 0,
          max: 100,
          step: 1,
          value: this.progress
        })
          .onChange((value: number, mode: SliderChangeMode) => {
            this.avPlayerUtil?.sliderChange(value, mode);
          })
          .layoutWeight(1)
          .selectedColor($r('app.color.selected_color'))

        TimeText({ time: this.totalTime })
          .margin({
            left: 2,
            right: 8
          })

        Image($r('app.media.ic_public_enlarge'))
          .height(24)
          .width(24)
          .margin({ right: 24 })
          .fillColor(Color.White)
          .onClick(() => {
            this.isClick = true;
            this.isFullScreen = true;
          })

        Image($r('app.media.ic_public_fullscreen'))
          .height(24)
          .width(24)
          .margin({ right: 24 })
          .fillColor(Color.White)
          .visibility(deviceInfo.deviceType === CommonConstants.DEVICE_2IN1 ? Visibility.Visible : Visibility.None)
          .onClick(() => {
            this.isFullScreen = true;
            this.windowObj?.maximize()
              .catch((err: BusinessError) => {
                Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
              });
          })
      }
      .width(CommonConstants.FULL_PERCENT)
      .height(40)
      .alignItems(VerticalAlign.Center)
      .visibility(!this.isFullScreen ? Visibility.Visible : Visibility.None)

      Row() {
        UniversalIcon("#19FFFFFF", $r('sys.symbol.chevron_backward'))
      }
      .opacity(1)
      .position({
        x: 16,
        y: 36
      })
      .onClick(() => {
        if (this.isFullScreen) {
          this.isFullScreen = false;
          this.isClick = false;
        } else {
          this.pathStack?.pop()
        }
      })

    }
    .height('auto')
    .layoutWeight(this.isFullScreen ? 1 : 0)
    .width(CommonConstants.FULL_PERCENT)
    .backgroundColor(Color.Black)
    .focusable(false)
  }

  @Builder
  TextButton(content: ResourceStr = '', callback?: Function) {
    Text(content)
      .fontSize(12)
      .fontWeight(FontWeight.Normal)
      .fontColor(Color.White)
      .margin({ right: 24 })
      .onClick(() => {
        callback && callback()
      })
  }

  @Builder
  ImgIcon(img: ResourceStr = '') {
    Image(img)
      .height(24)
      .width(24)
      .margin({ left: 24 })
  }

  // [EndExclude videoPlayer]
}

// [End videoPlayer]


@Component
struct TimeText {
  @Link time: string;

  build() {
    Text(this.time)
      .fontSize(9)
      .fontColor(Color.White)
      .lineHeight(12)
      .width(38)
  }
}

@Builder
function UniversalIcon(iconBackGroundColor: ResourceColor, icon: Resource) {
  Button({ type: ButtonType.Circle }) {
    SymbolGlyph(icon)
      .fontSize($r('sys.float.Title_M'))
      .fontColor([$r('sys.color.white')])
      .fontWeight(FontWeight.Normal)
  }
  .height(40)
  .aspectRatio(1)
  .backgroundColor(iconBackGroundColor)
}