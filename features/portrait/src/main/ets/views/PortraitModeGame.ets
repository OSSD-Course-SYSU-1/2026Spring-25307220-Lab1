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

import { window } from "@kit.ArkUI";
import { common } from "@kit.AbilityKit";
import { BreakpointType, CommonConstants, Logger, WindowOrientationHelper } from "base";
import { PortraitConstants } from "../constants/PortraitConstants";

@Builder
export function PortraitModeGameBuilder() {
  PortraitModeGame()
}

// [Start windowHelper]
@Component
export struct PortraitModeGame {
  windowObj: window.Window | undefined = undefined;
  // [StartExclude windowHelper]
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @State blockArr: number[] = [];
  @State blockColorArr: Resource[] = PortraitConstants.BLOCK_COLOR_ARR;

  // [EndExclude windowHelper]

  aboutToAppear(): void {
    try {
      this.windowObj = (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage.getMainWindowSync()
    } catch (err) {
      Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
    }

    // Obtain the PORTRAIT rotation strategy enumeration through the function selector.
    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.fixed('PORTRAIT'))
      .catch((err: BusinessError) => {
        Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
      });
    // [StartExclude windowHelper]
    this.initBlockArray();
    // [EndExclude windowHelper]
  }

  // [StartExclude windowHelper]
  aboutToDisappear() {
    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.presets.FIXED.UNSPECIFIED)

      .catch((err: BusinessError) => {
        Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
      });
  }

  // 设置FlowItem的宽/高数组
  initBlockArray() {
    for (let i = 0; i < 64; i++) {
      this.blockArr.push(i);
    }
  }

  randomColor() {
    return this.blockColorArr[Math.floor(Math.random() * 3)];
  }

  // [EndExclude windowHelper]
  build() {
    // [StartExclude windowHelper]
    NavDestination() {
      Column({ space: 8 }) {
        Text($r("app.string.Level2"))
          .width(CommonConstants.FULL_PERCENT)
          .textAlign(TextAlign.Start)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .textIndent(12)
          .fontColor($r('app.color.title_font_color'))
        List() {
          ForEach(this.blockArr, () => {
            ListItem() {
              Column() {
                Text()
                  .width("70%")
                  .aspectRatio(1)
                  .backgroundColor(this.randomColor())
              }
              .width(CommonConstants.FULL_PERCENT)
              .height(CommonConstants.FULL_PERCENT)
              .alignItems(HorizontalAlign.Center)
              .justifyContent(FlexAlign.Center)
            }
            .border({ width: { right: 1, bottom: 1 }, color: $r('app.color.border_color') })
            .aspectRatio(1)
          }, (item: number) => item.toString())
        }
        .width(CommonConstants.FULL_PERCENT)
        .height("auto")
        .lanes(new BreakpointType(4, 6, 8, 10, 12).getValue(this.widthBp))
        .border({ width: { top: 1, left: 1 }, color: $r('app.color.border_color') })
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.portrait_bg'))
      }
      .height(CommonConstants.FULL_PERCENT)
      .width(CommonConstants.FULL_PERCENT)
      .padding({
        left: new BreakpointType(12, 16, 24, 32, 32).getValue(this.widthBp),
        right: new BreakpointType(12, 16, 24, 32, 32).getValue(this.widthBp),
        top: 28
      })
    }
    .height(CommonConstants.FULL_PERCENT)
    .width(CommonConstants.FULL_PERCENT)
    .title($r("app.string.portrait_game"), { backgroundColor: $r('app.color.common_background_color') })
    .backgroundColor($r('app.color.common_background_color'))

    // [EndExclude windowHelper]
  }
}

// [End windowHelper]