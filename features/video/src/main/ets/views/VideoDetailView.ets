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

import { display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { CommonConstants, Logger } from 'base';
import { RelatedList } from '../components/RelatedList';
import { VideoPlayer } from '../components/VideoPlayer';

@Component
export struct VideoDetailView {
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @StorageLink('creaseRegion') creaseRegion: number[] = [];
  @StorageLink('isHalfFolded') isHalfFolded: boolean = false;
  @StorageLink('isFullScreen') isFullScreen: boolean = false;
  @Link relatedVideoHeight: number;
  @Link videoHeight: number;
  @State isShowingSideBar: boolean = false;
  @State foldStatus: display.FoldStatus | undefined = undefined
  public screenHeight: number = 0;
  private scroller: Scroller = new Scroller();

  aboutToAppear(): void {
    if (canIUse('SystemCapability.Window.SessionManager')) {
      try {
        this.foldStatus = display.getFoldStatus();
      } catch (error) {
        let err = error as BusinessError;
        Logger.error('VideoDetailView', `getFoldStatus failed, code = ${err.code}, message = ${err.message}`);
      }
    }
  }

  build() {
    Scroll(this.scroller) {
      Column() {
        Row() {
          Column() {
            VideoPlayer({
              videoHeight: this.videoHeight,
              isShowingSideBar: this.isShowingSideBar,
              foldStatus: this.foldStatus
            })

            Blank()
              .height(this.creaseRegion[1])
              .width(CommonConstants.FULL_PERCENT)
              .visibility(this.isHalfFolded && this.isShowingSideBar && this.isFullScreen ? Visibility.Visible :
                Visibility.None)
          }
          .layoutWeight(3)
        }
        .justifyContent(FlexAlign.Start)
        .backgroundColor(Color.Black)
        .height(this.isFullScreen ? CommonConstants.FULL_PERCENT : 'auto')
        .width(CommonConstants.FULL_PERCENT)

        RelatedList({
          relatedVideoHeight: this.relatedVideoHeight,
          videoHeight: this.videoHeight,
          screenHeight: this.screenHeight
        })
      }
      .width(CommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.Start)
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .height(CommonConstants.FULL_PERCENT)
  }
}