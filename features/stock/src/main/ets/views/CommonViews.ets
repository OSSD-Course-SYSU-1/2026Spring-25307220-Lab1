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

import { BreakpointType, CommonConstants } from "base";
import { OTHER_TITLE, StockInForm } from "../model/DataModel";

@Component
export struct StockInFormList {
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  public item?: StockInForm;
  public index: number = 0;
  @Consume('isExpand') isExpand: boolean = false;

  build() {
    Row() {
      Column({ space: 3 }) {
        Row() {
          Text(this.item?.title1)
            .textStocksTitle()
          Text(this.item?.value1)
            .fontColor(this.item?.color1)
            .textStocksValue()
        }
        .textStocksTitleValue()

        Row() {
          Text(this.item?.title2)
            .textStocksTitle()
          Text(this.item?.value2)
            .fontColor(this.item?.color2)
            .textStocksValue()
        }
        .textStocksTitleValue()

        Row() {
          Text(this.item?.title3)
            .textStocksTitle()
          Text(this.item?.value3)
            .fontColor(this.item?.color3)
            .textStocksValue()
        }
        .textStocksTitleValue()
      }
      .padding({
        right: new BreakpointType(16, 16, 24, 32, 32).getValue(this.widthBp),
        left: new BreakpointType(16, 16, 24, 32, 32).getValue(this.widthBp)
      })

      Divider()
        .vertical(true)
        .height('85%')
        .color('#979797')
        .visibility(this.widthBp === WidthBreakpoint.WIDTH_SM ?
          ((this.index + 1) % 2 === 0 ? Visibility.Hidden : Visibility.Visible) :
          this.widthBp === WidthBreakpoint.WIDTH_MD ?
            ((this.index + 1) % 3 === 0 || this.index === 3 ? Visibility.Hidden : Visibility.Visible) :
            ((this.index + 1) % 4 === 0 ? Visibility.Hidden : Visibility.Visible))
    }
    .width(CommonConstants.FULL_PERCENT)
    .height(51)
    .margin({
      bottom: 6
    })
    .visibility(this.widthBp === WidthBreakpoint.WIDTH_SM ?
      ((this.index + 1) > 2 ? (!this.isExpand ? Visibility.None : Visibility.Visible) : Visibility.Visible) :
      this.widthBp === WidthBreakpoint.WIDTH_MD ?
        ((this.index + 1) > 3 ? (!this.isExpand ? Visibility.None : Visibility.Visible) : Visibility.Visible) :
        ((this.index + 1) > 4 ? (!this.isExpand ? Visibility.None : Visibility.Visible) : Visibility.Visible))
  }
}

@Component
export struct CommSlide {
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @Link tabIndexSelected: number;
  public commSlideData: ResourceStr[] = OTHER_TITLE;

  build() {
    List({
      space: new BreakpointType(46, 46, 90, 150, 150).getValue(this.widthBp)
    }) {
      ForEach(this.commSlideData, (item: string, index: number) => {
        ListItem() {
          Column() {
            Text(item)
              .fontSize(16)
              .fontWeight(this.tabIndexSelected === index ? 700 : 400)
              .fontColor(this.tabIndexSelected === index ? '#000000' : '#999999')
              .height(21)
              .focusable(true)
              .groupDefaultFocus(index === 0)
          }
        }
        .margin({
          top: 9,
          right: this.commSlideData.length === index + 1 ?
            new BreakpointType(16, 16, 24, 32, 32).getValue(this.widthBp) : 0,
          left: index === 0 ? new BreakpointType(16, 16, 24, 32, 32).getValue(this.widthBp) : 0,
        })
        .border({
          width: {
            bottom: this.tabIndexSelected === index ? 2 : 0
          },
          color: {
            bottom: this.tabIndexSelected === index ? '#FA4337' : ''
          },
          style: {
            bottom: BorderStyle.Solid
          }
        })
        .onClick(() => {
          this.tabIndexSelected = index;
        })
      }, (item: string, index: number) => (index + item).toString())
    }
    .width('auto')
    .height('auto')
    .scrollBar(BarState.Off)
    .listDirection(Axis.Horizontal)
  }
}

@Builder
export function StockDetails(title: ResourceStr = '', price: string = '', amount: number = 0, index: number = 0,
  isShowNumber: boolean = true) {
  Row() {
    Text(title) {
      Span(title)
      if (isShowNumber) {
        Span(index.toString())
      }
    }
    .textType()
    .fontColor('#666666')

    Text(price)
      .textType()
      .fontColor(index % 2 === 0 ? '#FA4337' : '#1DB775')
    Text(amount.toString())
      .textType()
      .fontColor('#666666')
      .alignSelf(ItemAlign.End)
  }
  .width(CommonConstants.FULL_PERCENT)
  .justifyContent(FlexAlign.SpaceBetween)
}

@Builder
export function TitleIcon(icon?: Resource, title?: Resource) {
  Column() {
    SymbolGlyph(icon)
      .fontColor([$r('sys.color.icon_primary')])
      .fontSize(24)
    Text(title)
      .fontSize(10)
      .lineHeight(13)
      .fontColor('#999999')
      .margin({
        top: 4
      })
  }
  .width(40)
  .height(42)
  .justifyContent(FlexAlign.Center)
  .alignItems(HorizontalAlign.Center)
}

@Builder
export function UniversalIcon(iconBackGroundColor: ResourceColor, icon: Resource) {
  Button({ type: ButtonType.Circle }) {
    SymbolGlyph(icon)
      .fontSize($r('sys.float.Title_M'))
      .fontColor([$r('sys.color.icon_primary')])
      .fontWeight(FontWeight.Normal)
  }
  .height(40)
  .aspectRatio(1)
  .backgroundColor(iconBackGroundColor)
}

@Extend(Text)
function textType() {
  .fontWeight(FontWeight.Regular)
  .fontSize(10)
  .lineHeight(14)
}

@Extend(Text)
function textStocksValue() {
  .fontSize(11)
  .fontWeight(FontWeight.Medium)
}

@Extend(Text)
function textStocksTitle() {
  .fontSize(11)
  .fontColor('#999999')
}

@Extend(Row)
function textStocksTitleValue() {
  .width(CommonConstants.FULL_PERCENT)
  .justifyContent(FlexAlign.SpaceBetween)
}