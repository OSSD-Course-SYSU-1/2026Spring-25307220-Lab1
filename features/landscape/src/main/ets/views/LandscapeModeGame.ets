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

@Builder
export function LandscapeModeGameBuilder() {
  LandscapeModeGame()
}

@Component
export struct LandscapeModeGame {
  windowObj: window.Window | undefined = undefined;
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;

  aboutToAppear(): void {
    try {
      this.windowObj = (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage.getMainWindowSync()
    } catch (err) {
      Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
    }
    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.presets.FIXED.LANDSCAPE)
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

  build() {
    NavDestination() {
      Row({ space: new BreakpointType(8, 10, 16, 24, 32).getValue(this.widthBp) }) {
        Row()
          .width(new BreakpointType(72, 100, 128, 160, 180).getValue(this.widthBp))
          .aspectRatio(1)
          .borderRadius('50%')
          .backgroundColor($r('app.color.common_background_color'))

        Row()
          .width(new BreakpointType(72, 100, 128, 160, 180).getValue(this.widthBp))
          .aspectRatio(1)
          .borderRadius('50%')
          .backgroundColor($r('app.color.common_background_color'))
      }
      .height(CommonConstants.FULL_PERCENT)
      .width(CommonConstants.FULL_PERCENT)
      .padding({
        left: new BreakpointType(24, 48, 72, 90, 110).getValue(this.widthBp),
        right: new BreakpointType(24, 48, 72, 90, 110).getValue(this.widthBp),
        bottom: 24,
      })
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Bottom)
    }
    .height(CommonConstants.FULL_PERCENT)
    .width(CommonConstants.FULL_PERCENT)
    .align(Alignment.Center)
    .title($r("app.string.landscape_game"))

  }
}