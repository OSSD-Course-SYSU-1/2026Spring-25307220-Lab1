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

export class DetailConstants {
  /**
   * Initial comment image height.
   */
  static readonly INITIAL_COMMENT_IMAGE_HEIGHT: string = '150vp';
  /**
   * Initial comment image width.
   */
  static readonly INITIAL_COMMENT_IMAGE_WIDTH: string = '219vp';
  /**
   * Initial related video height.
   */
  static readonly INITIAL_RELATED_VIDEO_HEIGHT: number = 169;
  /**
   * Initial related video height.
   */
  static readonly INITIAL_VIDEO_HEIGHT: number = 100;
  /**
   * User info name list.
   */
  static readonly USER_INFO_NAMES: string[] = ['m******', 'H******', 'BEI***'];
  /**
   * User info comment list.
   */
  static readonly USER_INFO_COMMENTS: ResourceStr[] = [
    $r('app.string.feel'),
    $r('app.string.love'),
    $r('app.string.design')
  ];
  /**
   * User info date.
   */
  static readonly USER_INFO_DATE: ResourceStr = $r('app.string.July');
  /**
   * Player text list.
   */
  static readonly PLAYER_TEXT_LIST: ResourceStr[] = [$r('app.string.selections'), $r('app.string.just'),
    $r('app.string.super'), $r('app.string.speed')];
  /**
   * Episode list lanes list.
   */
  static readonly EPISODE_LIST_LANES: number[] = [8, 4];
  /**
   * Episodes.
   */
  static readonly PLAYER_EPISODE: string[] = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13', '14',
    '15', '16', '17', '18', '19', '20', '21', '22', '23', '24'];
  /**
   * Offset for scrolling to top.
   */
  static readonly SCROLL_TO_TOP: string = '{"xOffset":0,"yOffset":0}';
  /**
   * Related video title list.
   */
  static readonly RELATED_VIDEO_TITLES: ResourceStr[] =
    [$r('app.string.released'), $r('app.string.released'), $r('app.string.released'),
      $r('app.string.released'), $r('app.string.released'), $r('app.string.released'), $r('app.string.released')];
  /**
   * Peripheral video title list.
   */
  static readonly PERIPHERAL_VIDEO_TITLE: ResourceStr[] = [$r('app.string.series'), $r('app.string.series'),
    $r('app.string.series'), $r('app.string.series'), $r('app.string.series')];
  /**
   * Episodes list.
   */
  static readonly EPISODES_LIST: string[] = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'];
  /**
   * Icon list.
   */
  static readonly ICON_LIST: Resource[] = [$r('app.media.ic_public_favor'), $r('app.media.ic_public_comments'),
    $r('app.media.ic_public_thumb_sup'), $r('app.media.ic_public_download'), $r('app.media.ic_public_share')];
  /**
   * Ten.
   */
  static readonly TEN: number = 10;
  /**
   * Sub title list.
   */
  static readonly SUB_TITLES: ResourceStr[] =
    [$r('app.string.comments'), $r('app.string.related'), $r('app.string.more'), $r('app.string.introduction'),
      $r('app.string.anthology'), $r('app.string.Peripheral')];
  /**
   * Length unit.
   */
  static readonly LENGTH_UNIT: string = 'vp';
}