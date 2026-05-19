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

import { BreakpointType, CommonConstants } from 'base';
import { BUY_SELL_SHARES, SELL_SHARES, SUBMISSION_TIME, transactionDetails } from '../model/DataModel';
import { StockDetails } from './CommonViews';

@Component
export struct StockDealDetails {
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  private concludeDetailsScroller: Scroller = new Scroller();
  private readonly breakpointPadding = new BreakpointType(8.25, 8.25, 8.25, 9, 9);

  build() {
    Row() {
      Column({ space: 2 }) {
        Text($r('app.string.market_conditions'))
          .width(CommonConstants.FULL_PERCENT)
          .height(20)
          .fontColor('#FA7137')
          .backgroundColor('#FFEFEE')
          .fontSize(10)
          .textAlign(TextAlign.Center)
        ForEach(SELL_SHARES, (item: transactionDetails, index: number) => {
          Row() {
            StockDetails(item.title, item.price, item.amount, index + 1)
          }
          .padding({
            right: this.breakpointPadding.getValue(this.widthBp),
            left: this.breakpointPadding.getValue(this.widthBp)
          })
        }, (item: transactionDetails, index: number) => (item.price + index).toString())
        Row() {
          Slider({
            value: 60,
            min: 0,
            max: 100,
            style: SliderStyle.NONE
          })
            .trackColor('#1DB775')
            .selectedColor('#FA4337')
        }
        .width(CommonConstants.FULL_PERCENT)
        .height(10)

        ForEach(BUY_SELL_SHARES, (item: transactionDetails, index: number) => {
          Row() {
            StockDetails(item.title, item.price, item.amount, index + 1)
          }
          .padding({
            right: this.breakpointPadding.getValue(this.widthBp),
            left: this.breakpointPadding.getValue(this.widthBp)
          })
        }, (item: transactionDetails, index: number) => (item.price + index).toString())

        Text($r('app.string.transaction_details'))
          .width(CommonConstants.FULL_PERCENT)
          .height(20)
          .backgroundColor('#F4F3F8')
          .fontSize(10)
          .textAlign(TextAlign.Center)

        Scroll(this.concludeDetailsScroller) {
          Column() {
            ForEach(SUBMISSION_TIME, (item: transactionDetails, index: number) => {
              Row() {
                StockDetails(item.title, item.price, item.amount, index + 1, false)
              }
              .padding({
                top: 2,
                right: this.breakpointPadding.getValue(this.widthBp),
                bottom: 2,
                left: this.breakpointPadding.getValue(this.widthBp)
              })
            }, (item: transactionDetails, index: number) => (item.price + index).toString())
          }
        }
        .height(new BreakpointType(70, 70, 70, 102, 102).getValue(this.widthBp))
        .scrollBar(BarState.Off)
      }
      .height(CommonConstants.FULL_PERCENT)
      .width(CommonConstants.FULL_PERCENT)
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({
        top: 4,
        bottom: 12
      })
    }
    .width(new BreakpointType(103, 103, 103, 192, 192).getValue(this.widthBp))
    .height(CommonConstants.FULL_PERCENT)
    .padding({
      left: 4
    })
  }
}