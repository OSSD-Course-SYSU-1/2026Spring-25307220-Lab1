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
import { StockDetailsInfo } from "./StockDetailsInfo";
import { StockForm, STOCK_FORM } from "../model/DataModel";
import { LineChart } from "@ohos/mpchart";
import { LinesChartModel } from "../chartmodels/LineChartModel";
import { BarChartView } from "../chartmodels/BarChartView";
import { CommonConstants, Logger, WindowOrientationHelper } from "base";

@Builder
export function ABAWindowBuilder() {
  ABAWindow()
}

// [Start windowHelper]
@Component
export struct ABAWindow {
  windowObj: window.Window | undefined = undefined;
  // [StartExclude windowHelper]
  @State stockInForm: StockForm = STOCK_FORM[0];
  @State ChartViewModel: LinesChartModel = new LinesChartModel();
  // [EndExclude windowHelper]

  // [Start ABAWindow]
  aboutToAppear(): void {
    try {
      this.windowObj = (this.getUIContext().getHostContext() as common.UIAbilityContext).windowStage.getMainWindowSync()
    } catch (err) {
      Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
    }

    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.autoRotate("LANDSCAPE_ONLY"))
      .catch((err: BusinessError) => {
        Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
      });
  }

  aboutToDisappear(): void {
    this.windowObj?.setPreferredOrientation(WindowOrientationHelper.followDesktop())
      .catch((err: BusinessError) => {
        Logger.error(`Invoke set preferred orientation failed, code is ${err.code}, message is ${err.message}`)
      });
  }
  // [End ABAWindow]

  build() {
    // [StartExclude windowHelper]
    NavDestination() {
      Column({ space: 10 }) {

        Column() {
          Text() {
            Span($r('app.string.somebody_technology'))
            Span('60**39')
          }
          .fontSize(16)
          .height(21)

          StockDetailsInfo({ stockInForm: this.stockInForm })

          Row() {
            LineChart({ model: this.ChartViewModel.getLineChartModel() })
          }
          .layoutWeight(4)
          .width(CommonConstants.FULL_PERCENT)
          .padding({
            top: 20
          })

          Row() {
            BarChartView()
          }
          .width(CommonConstants.FULL_PERCENT)
          .layoutWeight(1)

        }
        .height(CommonConstants.FULL_PERCENT)
      }
    }
    .height(CommonConstants.FULL_PERCENT)
    .width(CommonConstants.FULL_PERCENT)
    .align(Alignment.Center)
    .title($r('app.string.somebody_technology'))
    // [EndExclude windowHelper]
  }
}
// [EndExclude windowHelper]