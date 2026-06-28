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

import { ListDataSource } from '../viewmodel/ListDataSource';
import { window } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { PhotosBarViewModel } from '../viewmodel/PhotoTabBarViewModel';
import { PhotosBarItemInterface } from '../model/PhotsTabBarModel';
import { BreakpointType, CommonConstants, Logger, WindowOrientationHelper } from 'base';

@Builder
export function PhotosBuilder() {
  Photos()
}

@Component
export struct Photos {
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  windowObj: window.Window | undefined = undefined;
  private photoList: ListDataSource = new ListDataSource();
  scrollerForList: Scroller = new Scroller();
  @State currentIndex: number = 0;
  photosTabBarsInfo: PhotosBarViewModel = new PhotosBarViewModel();

  aboutToAppear(): void {
    try {
      this.windowObj = (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage.getMainWindowSync()
    } catch (err) {
      Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
    }

    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.presets.AUTO_ROTATE.ALL_ORIENTATIONS.UNSPECIFIED)
      .catch((err: BusinessError) => {
        Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
      });
  }

  aboutToDisappear() {
    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.presets.FIXED.UNSPECIFIED)
      .catch((err: BusinessError) => {
        Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
      });
  }

  @Builder
  TabBarBuilder(item: PhotosBarItemInterface, index: number) {
    Column({ space: 4 }) {
      Image(item.icon)
        .width(24)
        .aspectRatio(1)
      Text(item.name)
        .fontSize(12)
        .fontWeight(500)
        .fontColor(index === this.currentIndex ? $r('app.color.tab_select_color') : $r('app.color.tab_normal_color'))
    }
    .height(CommonConstants.FULL_PERCENT)
    .justifyContent(FlexAlign.Center)
  }

  @Builder
  ReusableListItem(params: number) {
    Image($r(`app.media.ic_photos_${params % 7}`))
      .width(CommonConstants.FULL_PERCENT)
      .aspectRatio(1)
      .objectFit(ImageFit.Cover)
  }

  build() {
    NavDestination() {
      Column() {
        Tabs({
          barPosition: this.widthBp === WidthBreakpoint.WIDTH_LG ? BarPosition.Start : BarPosition.End,
          index: this.currentIndex
        }) {
          TabContent() {
            Column() {
              List({ space: 2, initialIndex: 0, scroller: this.scrollerForList }) {
                LazyForEach(this.photoList, (item: number) => {
                  ListItem() {
                    this.ReusableListItem(item)
                  }
                }, (item: number) => item.toString())
              }
              .lanes(new BreakpointType(2, 3, 4, 5, 6).getValue(this.widthBp))
              .width(CommonConstants.FULL_PERCENT)
              .height(CommonConstants.FULL_PERCENT)
              .scrollBar(BarState.Off)
              .cachedCount(2)
            }
            .width(CommonConstants.FULL_PERCENT)
            .height(CommonConstants.FULL_PERCENT)
            .backgroundColor($r("app.color.list_background_color"))
          }
          .tabBar(this.TabBarBuilder(this.photosTabBarsInfo.getTabList()[0], 0))

          TabContent() {
          }
          .tabBar(this.TabBarBuilder(this.photosTabBarsInfo.getTabList()[1], 1))

          TabContent() {
          }
          .tabBar(this.TabBarBuilder(this.photosTabBarsInfo.getTabList()[2], 2))
        }
        .vertical(this.widthBp === WidthBreakpoint.WIDTH_LG)
        .onChange((index: number) => {
          this.currentIndex = index;
        })
        .barHeight(this.widthBp === WidthBreakpoint.WIDTH_LG ? CommonConstants.HALF_PERCENT :
          54)
        .barWidth(this.widthBp === WidthBreakpoint.WIDTH_LG ?
          96 : CommonConstants.FULL_PERCENT)
        .barBackgroundColor($r('app.color.common_background_color'))
        .scrollable(false)
        .height(CommonConstants.FULL_PERCENT)
      }
      .height(CommonConstants.FULL_PERCENT)
      .width(CommonConstants.FULL_PERCENT)
      .backgroundColor($r('app.color.common_background_color'))
      .padding({
        top: 8
      })
    }
    .height(CommonConstants.FULL_PERCENT)
    .width(CommonConstants.FULL_PERCENT)
    .align(Alignment.Center)
    .title($r("app.string.photos"), { backgroundColor: $r('app.color.common_background_color') })
    .backgroundColor($r('app.color.common_background_color'))
  }
}