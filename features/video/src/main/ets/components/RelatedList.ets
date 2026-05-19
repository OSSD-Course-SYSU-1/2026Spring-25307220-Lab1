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

import { CurrentOffsetUtil, DetailConstants, CommonConstants } from 'base';
import { RelatedVideo, RelatedVideoViewModel } from '../viewmodel/RelatedVideoViewModel';
import { AllComments } from './AllComments';

@Component
export struct RelatedList {
  @StorageLink(CommonConstants.WIDTH_BREAK_POINT) widthBp: WidthBreakpoint = WidthBreakpoint.WIDTH_SM;
  @StorageLink('isFullScreen') isFullScreen: boolean = false;
  @State commentImgHeight: string = DetailConstants.INITIAL_COMMENT_IMAGE_HEIGHT;
  @State commentImgWidth: string = DetailConstants.INITIAL_COMMENT_IMAGE_WIDTH;
  @Link relatedVideoHeight: number;
  @Link videoHeight: number;
  public screenHeight: number = 0;
  private relatedVideoList: RelatedVideo[] = new RelatedVideoViewModel().getRelatedVideoList();
  private peripheralVideoList: RelatedVideo[] = new RelatedVideoViewModel().getPeripheralVideoList();
  private episodes: string[] = DetailConstants.EPISODES_LIST;
  private currentIndex: number = 2;
  private iconList: Resource[] = DetailConstants.ICON_LIST;
  private scroller: Scroller = new Scroller();

  build() {
    Scroll(this.scroller) {
      Column() {
        this.RelatedVideoComponent()
        this.VideoIntroduction()
        AllComments({ commentImgHeight: this.commentImgHeight, commentImgWidth: this.commentImgWidth })
          .visibility(this.widthBp === WidthBreakpoint.WIDTH_LG ? Visibility.None : Visibility.Visible)
      }
      .width(CommonConstants.FULL_PERCENT)
      .alignItems(HorizontalAlign.Start)
      .padding({ bottom: 10 })
    }
    .layoutWeight(1)
    .scrollBar(BarState.Off)
    .visibility(!this.isFullScreen ? Visibility.Visible : Visibility.None)
    .onScrollFrameBegin((offset: number) => {
      if (this.widthBp === WidthBreakpoint.WIDTH_LG) {
        if ((offset > 0) && (this.videoHeight > 53)) {
          let offsetPercent = (Math.abs(offset) * 100) / this.screenHeight;
          let heightOffset = offsetPercent < this.videoHeight - 53 ? offsetPercent : this.videoHeight - 53;
          this.videoHeight = this.videoHeight - heightOffset;
          return { offsetRemain: 0 };
        } else if ((offset < 0) && (this.videoHeight < 100) &&
          (CurrentOffsetUtil.scrollToTop(JSON.stringify(this.scroller.currentOffset())))) {
          let offsetPercent = (Math.abs(offset) * 100) / this.screenHeight;
          let heightOffset = offsetPercent < 100 - this.videoHeight ? offsetPercent : 100 - this.videoHeight;
          this.videoHeight = this.videoHeight + heightOffset;
          return { offsetRemain: 0 };
        }
        return { offsetRemain: offset };
      } else {
        if ((offset > 0) && (this.videoHeight === 100) && (this.relatedVideoHeight > 0)) {
          let offsetPercent = (Math.abs(offset) * DetailConstants.TEN) / this.screenHeight;
          this.relatedVideoHeight = (this.relatedVideoHeight - offsetPercent * 169) <
            0 ? 0 : (this.relatedVideoHeight - offsetPercent * 169);
          return { offsetRemain: 0 };
        } else if ((offset > 0) && (this.videoHeight > 53) &&
          (this.relatedVideoHeight === 0)) {
          let offsetPercent = (Math.abs(offset) * 100) / this.screenHeight;
          let heightOffset = offsetPercent < this.videoHeight - 53 ? offsetPercent : this.videoHeight - 53;
          this.videoHeight = this.videoHeight - heightOffset;
          return { offsetRemain: 0 };
        } else if ((offset > 0) && (this.videoHeight === 53) && (this.relatedVideoHeight === 0)) {
          return { offsetRemain: offset };
        } else if ((offset < 0) && (this.videoHeight < 100) && (this.relatedVideoHeight === 0)) {
          if (CurrentOffsetUtil.scrollToTop(JSON.stringify(this.scroller.currentOffset()))) {
            let offsetPercent = (Math.abs(offset) * 100) / this.screenHeight;
            let heightOffset = offsetPercent < 100 - this.videoHeight ? offsetPercent : 100 - this.videoHeight;
            this.videoHeight = this.videoHeight + heightOffset;
            return { offsetRemain: 0 };
          }
          return { offsetRemain: offset };
        } else if ((offset < 0) && (this.videoHeight === 100) && (this.relatedVideoHeight >= 0)) {
          let offsetPercent = (Math.abs(offset) * DetailConstants.TEN) / this.screenHeight;
          this.relatedVideoHeight = (this.relatedVideoHeight + offsetPercent * 169) > 169 ? 169 :
            (this.relatedVideoHeight + offsetPercent * 169);
          return { offsetRemain: 0 };
        }
        return { offsetRemain: 0 };
      }
    })
  }

  @Builder
  RelatedVideoComponent() {
    Column() {
      this.SubTitleAndMore(DetailConstants.SUB_TITLES[1])

      Row() {
        List({ space: 12 }) {
          ForEach(this.relatedVideoList, (item: RelatedVideo, index: number) => {
            ListItem() {
              Column() {
                Image(item.getImageSrc())
                  .height(76)
                  .width(135)
                  .objectFit(ImageFit.Cover)
                  .borderRadius(8)
                  .margin({ bottom: 8 })

                Text(item.getName())
                  .fontSize(14)
                  .lineHeight(19)
                  .fontWeight(500)
                  .opacity(0.6)
                  .fontColor(index === 0 ? $r('app.color.episodes_font') : Color.Black)
              }
            }
            .margin({
              top: 8,
              bottom: 10
            })
          }, (item: RelatedVideo, index: number) => index + JSON.stringify(item))
        }
        .width("auto")
        .height("auto")
        .listDirection(Axis.Horizontal)
        .scrollBar(BarState.Off)
      }
      .padding({
        left: 24,
        bottom: 10
      })
      .height(121)
      .width(CommonConstants.FULL_PERCENT)
    }
    .height(this.relatedVideoHeight + DetailConstants.LENGTH_UNIT)
  }

  @Builder
  VideoIntroduction() {
    Column() {
      this.SubTitle($r('app.string.introduction'))

      Column() {
        this.IntroductionContent($r('app.string.product'))
        this.IntroductionContent($r('app.string.play'))
      }
      .padding({
        left: '24vp',
        right: '24vp'
      })
      .width(CommonConstants.FULL_PERCENT)
      .alignItems(HorizontalAlign.Start)

      Row() {
        ForEach(this.iconList, (item: Resource) => {
          Image(item)
            .height('24vp')
            .width('24vp')
        }, (item: Resource, index: number) => index + JSON.stringify(item))
      }
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({
        top: 12,
        bottom: 12,
        left: 24,
        right: 24
      })
      .height(48)
      .width(CommonConstants.FULL_PERCENT)

      this.SubTitle($r('app.string.anthology'))

      List({ space: 12 }) {
        ForEach(this.episodes, (item: string, index: number) => {
          ListItem() {
            Row() {
              Image($r('app.media.ic_video_playing'))
                .height(10)
                .width(10)
                .position({ x: 8, y: 36 })
                .visibility((index + 1) === this.currentIndex ? Visibility.Visible : Visibility.None)

              Text(item)
                .fontSize(18)
                .fontWeight(FontWeight.Normal)
                .height(24)
                .fontColor((index + 1) === this.currentIndex ? $r('app.color.episodes_font') : Color.Black)
            }
            .justifyContent(FlexAlign.Center)
            .backgroundColor($r('app.color.episodes_background'))
            .height(54)
            .width(68)
            .borderRadius(8)
          }
        }, (item: string, index: number) => index + JSON.stringify(item))
      }
      .scrollBar(BarState.Off)
      .listDirection(Axis.Horizontal)
      .padding({ left: 24 })
      .margin({ bottom: 24 })
      .width(CommonConstants.FULL_PERCENT)
      .height("auto")

      this.SubTitleAndMore($r('app.string.Peripheral'))

      List({ space: '12vp' }) {
        ForEach(this.peripheralVideoList, (item: RelatedVideo) => {
          ListItem() {
            Column() {
              Image(item.getImageSrc())
                .height(230)
                .width(164)
                .margin({ bottom: 4 })
                .borderRadius(16)

              Text(item.getName())
                .lineHeight(19)
                .fontSize(14)
                .opacity(0.6)
                .fontWeight(500)
            }
          }
        }, (item: RelatedVideo, index: number) => index + JSON.stringify(item))
      }
      .scrollBar(BarState.Off)
      .listDirection(Axis.Horizontal)
      .margin({ top: 12 })
      .padding({
        left: 24,
        right: 24
      })
      .width(CommonConstants.FULL_PERCENT)
      .height("auto")
    }
    .width(CommonConstants.FULL_PERCENT)
    .backgroundColor(Color.White)
    .visibility(this.widthBp === WidthBreakpoint.WIDTH_LG ? Visibility.Visible : Visibility.None)
  }

  @Builder
  SubTitle(subtitle: ResourceStr) {
    Row() {
      Text(subtitle)
        .fontSize(16)
        .lineHeight(22)
        .fontWeight(500)
    }
    .padding({
      left: 24,
      right: 24
    })
    .height(48)
    .width(CommonConstants.FULL_PERCENT)
  }

  @Builder
  SubTitleAndMore(subtitle: ResourceStr) {
    Row() {
      Text(subtitle)
        .fontSize(16)
        .lineHeight(22)
        .fontWeight(500)
      Blank()
      Text($r('app.string.more'))
        .fontSize(14)
        .lineHeight(19)
        .fontWeight(FontWeight.Normal)
        .opacity(0.6)
      Image($r('app.media.ic_public_arrow_right'))
        .height(24)
        .width(24)
    }
    .padding({
      left: 24,
      right: 24
    })
    .height(48)
    .width(CommonConstants.FULL_PERCENT)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  IntroductionContent(content: ResourceStr) {
    Text(content)
      .fontSize(14)
      .lineHeight(28)
      .fontWeight(500)
      .opacity(0.6)
  }
}