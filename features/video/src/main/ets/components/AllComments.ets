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

import { CommonConstants } from 'base';
import { UserInfo, UserViewModel } from '../viewmodel/UserViewModel';

@Component
export struct AllComments {
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @Link commentImgHeight: string;
  @Link commentImgWidth: string;
  private commentsList: UserInfo[] = new UserViewModel().getRelatedVideoList();

  build() {
    Column() {
      Row() {
        this.TitleText($r('app.string.comments'))
      }
      .padding({
        left: 24,
        right: 24
      })
      .height(48)
      .width(CommonConstants.FULL_PERCENT)

      Column() {
        ForEach(this.commentsList, (item: UserInfo, index: number) => {
          Row() {
            Image(item.getImageSrc())
              .height(36)
              .width(36)
              .margin({ right: 16 })

            this.TitleText(item.getName())
          }
          .height(48)
          .width(CommonConstants.FULL_PERCENT)
          .margin({ top: 10 })
          .alignItems(VerticalAlign.Center)

          Row() {
            Text(item.getComment())
              .margin({ left: 52 })
              .opacity(0.6)
              .fontSize(14)
              .lineHeight(28)
              .fontWeight(500)
          }
          .margin({ top: 4 })
          .width(CommonConstants.FULL_PERCENT)
          .justifyContent(FlexAlign.Start)

          // Row() {
          // }
          // .padding({ left: $r('app.float.all_comments_img_row_padding') })
          // .margin({ top: $r('app.float.all_comments_img_row_margin') })
          // .width(CommonConstants.FULL_PERCENT)
          // .justifyContent(FlexAlign.Start)
          // .visibility(!item.getCommentImageSrc() ? Visibility.None : Visibility.Visible)

          Row() {
            Text(item.getTime())
              .opacity(0.6)
              .fontSize(12)
              .lineHeight(18)
              .fontWeight(FontWeight.Normal)
              .margin({ left: 52 })

            Blank()
            Row({ space: 24 }) {
              this.IconImage($r('app.media.ic_public_comments'))
              this.IconImage($r('app.media.ic_public_thumb_sup'))
              this.IconImage($r('app.media.ic_public_share'))
            }
          }
          .margin({ top: 14 })
          .width(CommonConstants.FULL_PERCENT)
          .justifyContent(FlexAlign.Start)

          Divider()
            .color(Color.Black)
            .opacity(0.05)
            .margin({
              top: 12
            })
            .height(1)
            .width(CommonConstants.FULL_PERCENT)
            .visibility(index === this.commentsList.length - 1 ? Visibility.None : Visibility.Visible)
        }, (item: UserInfo, index: number) => index + JSON.stringify(item))
      }
      .alignItems(HorizontalAlign.Start)
      .padding({
        left: 24,
        right: 24
      })
      .width(CommonConstants.FULL_PERCENT)
    }
    .width(CommonConstants.FULL_PERCENT)
    .backgroundColor(Color.White)
    .justifyContent(FlexAlign.Start)
  }

  @Builder
  TitleText(content: ResourceStr) {
    Text(content)
      .fontSize(16)
      .lineHeight(22)
      .fontWeight(500)
  }

  @Builder
  IconImage(image: Resource | null = null) {
    Image(image)
      .height(16)
      .width(16)
  }
}