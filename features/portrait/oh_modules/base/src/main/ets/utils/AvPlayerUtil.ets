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

import { media } from '@kit.MediaKit';
import { common } from '@kit.AbilityKit';
import { resourceManager } from '@kit.LocalizationKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Logger from './Logger';
import { CommonConstants } from '../constants/CommonConstants';

export class AvPlayerUtil {
  private avPlayer?: media.AVPlayer;
  private context: common.UIAbilityContext;
  private url: resourceManager.RawFileDescriptor | null = null;
  private surfaceId: string = '';
  private sliderBegin: number = 0;
  private isMoving: boolean = false;
  private onError: (err: BusinessError) => void = (err: BusinessError) => {
    Logger.error(`Invoke avPlayer failed, code is ${err.code}, message is ${err.message}`);
    this.avPlayer?.reset().catch((error: BusinessError) => {
      Logger.error('AvPlayerUtil', `reset failed, code = ${error.code}, message = ${error.message}`);
    });
  };
  private onTimeUpdateFunction: (updateTime: number) => void = (updateTime: number) => {
    AppStorage.setOrCreate<string>(CommonConstants.AV_PLAYER_CURRENT_TIME, this.formatTime(updateTime));
    AppStorage.setOrCreate<number>(CommonConstants.AV_PLAYER_UPDATE_TIME, updateTime);
    AppStorage.setOrCreate<number>(CommonConstants.AV_PLAYER_PROGRESS, updateTime / this.avPlayer!.duration *
    CommonConstants.PROGRESS_HUNDRED);
  };
  private onStateChange: (state: media.AVPlayerState) => void = async (state: media.AVPlayerState) => {
    switch (state) {
      case CommonConstants.AV_PLAYER_IDLE_STATE:
        this.handleIdleState();
        break;
      case CommonConstants.AV_PLAYER_INITIALIZED_STATE:
        this.handleInitializedState();
        break;
      case CommonConstants.AV_PLAYER_PREPARED_STATE:
        this.handlePreparedState();
        break;
      case CommonConstants.AV_PLAYER_PLAYING_STATE:
        this.handlePlayingState();
        break;
      case CommonConstants.AV_PLAYER_PAUSED_STATE:
        this.handlePausedState();
        break;
      case CommonConstants.AV_PLAYER_COMPLETED_STATE:
        this.handleCompletedState();
        break;
      case CommonConstants.AV_PLAYER_STOPPED_STATE:
        this.handleStoppedState();
        break;
      case CommonConstants.AV_PLAYER_RELEASE_STATE:
        this.handleReleaseState();
        break;
      case CommonConstants.AV_PLAYER_ERROR_STATE:
        this.handleErrorState();
        break;
      default:
        Logger.info('AVPlayer state unknown called.');
        break;
    }
  };

  constructor(uiContext: UIContext) {
    this.context = uiContext.getHostContext() as common.UIAbilityContext;
  }

  static getInstance(uiContext: UIContext): AvPlayerUtil | undefined {
    if (!AppStorage.get<AvPlayerUtil>(CommonConstants.AV_PLAYER_UTIL)) {
      AppStorage.setOrCreate(CommonConstants.AV_PLAYER_UTIL, new AvPlayerUtil(uiContext));
    } else {
      Logger.info(`AppStorage does not have avPlayerUtil`);
    }
    return AppStorage.get<AvPlayerUtil>(CommonConstants.AV_PLAYER_UTIL);
  }

  async createAvPlayer(surfaceId: string): Promise<void> {
    if (!this.avPlayer || this.avPlayer.state === CommonConstants.AV_PLAYER_RELEASE_STATE) {
      try {
        this.avPlayer = await media.createAVPlayer();
        this.surfaceId = surfaceId;
        Logger.info('Created AvPlayer successfully.');
        // Entering idle state.
        this.url = await this.context.resourceManager.getRawFd(CommonConstants.PRODUCT_VIDEO_NAME);
        this.avPlayer.fdSrc = this.url;
        this.setAVPlayerCallback();
      } catch (error) {
        let err = error as BusinessError;
        Logger.error('testTag', `createAVPlayer failed, code = ${err.code}, message = ${err.message}`);
      }

    } else {
      Logger.info(`AvPlayer has been created`);
    }
  }

  setAVPlayerCallback(): void {
    this.avPlayer?.on('error', this.onError);
    this.onTimeUpdate();
    this.setStateChange();
  }

  onTimeUpdate(): void {
    this.avPlayer?.on('timeUpdate', this.onTimeUpdateFunction);
  }

  offTimeUpdate(): void {
    try {
      this.avPlayer?.off('timeUpdate');
    } catch (exception) {
      Logger.error('Failed to unregister callback. Code: ' + JSON.stringify(exception));
    }
  }

  setStateChange(): void {
    this.avPlayer?.on('stateChange', this.onStateChange);
  }

  release(): void {
    if (this.avPlayer && this.avPlayer.state !== CommonConstants.AV_PLAYER_RELEASE_STATE) {
      AppStorage.setOrCreate(CommonConstants.AV_PLAYER_UTIL, undefined);
      try {
        this.avPlayer.off('error');
        this.avPlayer.off('stateChange');
        this.offTimeUpdate();
      } catch (exception) {
        Logger.error('Failed to unregister callback. Code: ' + JSON.stringify(exception));
      }
      this.avPlayer.release().catch((error: BusinessError) => {
        Logger.error('AvPlayerUtil', `release failed, code = ${error.code}, message = ${error.message}`);
      });
    } else {
      Logger.info(`AvPlayer release failed`);
    }
  }

  sliderChange(value: number, mode: SliderChangeMode): void {
    let seekType: media.SeekMode = value > this.sliderBegin ? media.SeekMode.SEEK_PREV_SYNC :
      media.SeekMode.SEEK_NEXT_SYNC;
    switch (mode) {
      case SliderChangeMode.Begin:
        Logger.info(`AvPlayer SliderChangeMode Begin`);
        this.sliderBegin = value;
        this.avPlayer?.pause().catch((error: BusinessError) => {
          Logger.error('AvPlayerUtil', `pause failed, code = ${error.code}, message = ${error.message}`);
        });
        break;
      case SliderChangeMode.Moving:
        Logger.info(`AvPlayer SliderChangeMode Moving`);
        this.isMoving = true;
        break;
      case SliderChangeMode.End:
        Logger.info(`AvPlayer SliderChangeMode End`);
        if (this.isMoving) {
          this.avPlayer?.seek(value / CommonConstants.PROGRESS_HUNDRED * this.avPlayer.duration, seekType);
          this.isMoving = false;
        }
        this.avPlayer?.play().catch((error: BusinessError) => {
          Logger.error('AvPlayerUtil', `play failed, code = ${error.code}, message = ${error.message}`);
        });
        break;
      case SliderChangeMode.Click:
        Logger.info(`AvPlayer SliderChangeMode Click`);
        this.avPlayer?.seek(this.sliderBegin / CommonConstants.PROGRESS_HUNDRED * this.avPlayer.duration, seekType);
        break;
      default:
        break;
    }
  }

  playerStateControl(): void {
    if (this.avPlayer?.state === CommonConstants.AV_PLAYER_STOPPED_STATE) {
      this.avPlayer.prepare().catch((error: BusinessError) => {
        Logger.error('AvPlayerUtil', `prepare failed, code = ${error.code}, message = ${error.message}`);
      });
    } else if (this.avPlayer?.state === CommonConstants.AV_PLAYER_PAUSED_STATE) {
      this.avPlayer.play().catch((error: BusinessError) => {
        Logger.error('AvPlayerUtil', `play failed, code = ${error.code}, message = ${error.message}`);
      });
    } else if (this.avPlayer?.state === CommonConstants.AV_PLAYER_PLAYING_STATE) {
      this.avPlayer.pause().catch((error: BusinessError) => {
        Logger.error('AvPlayerUtil', `pause failed, code = ${error.code}, message = ${error.message}`);
      });
    }
  }

  fastForward(): void {
    if (this.avPlayer?.state === CommonConstants.AV_PLAYER_PLAYING_STATE || this.avPlayer?.state ===
    CommonConstants.AV_PLAYER_PAUSED_STATE) {
      this.avPlayer.seek(this.avPlayer.currentTime + 5000);
    }
  }

  rewind(): void {
    if (this.avPlayer?.state === CommonConstants.AV_PLAYER_PLAYING_STATE || this.avPlayer?.state ===
    CommonConstants.AV_PLAYER_PAUSED_STATE) {
      this.avPlayer.seek(this.avPlayer.currentTime - 5000);
    }
  }

  formatTime(duration: number): string {
    let totalSecond: number = Math.round(duration / CommonConstants.PROGRESS_THOUSAND);
    let hourNum: number = Math.floor(totalSecond / CommonConstants.SECOND_IN_HOUR);
    let minNum: number = Math.floor((totalSecond % CommonConstants.SECOND_IN_HOUR) / CommonConstants.SECOND_IN_MINUTE);
    let secNum: number = (totalSecond % CommonConstants.SECOND_IN_HOUR) % CommonConstants.SECOND_IN_MINUTE;
    return this.formatUnitTime(hourNum) + CommonConstants.COLON + this.formatUnitTime(minNum) + CommonConstants.COLON +
    this.formatUnitTime(secNum);
  }

  formatUnitTime(time: number): string {
    if (time >= CommonConstants.ONE && time < CommonConstants.TEN) {
      let zero: string = CommonConstants.TIME_PREFIX;
      return zero.concat(time.toString());
    }
    if (time >= CommonConstants.ZERO && time < CommonConstants.ONE) {
      return CommonConstants.EMPTY_TIME;
    }
    return time.toString();
  }

  async handleIdleState() {
    if (this.avPlayer === undefined) {
      Logger.error(`AvPlayer is undefined`);
      return;
    }
    try {
      this.url = await this.context.resourceManager.getRawFd(CommonConstants.PRODUCT_VIDEO_NAME);
      this.avPlayer.fdSrc = this.url;
      Logger.info('AVPlayer state idle called.');
    } catch (error) {
      let err = error as BusinessError;
      Logger.error('AvPlayerUtil', `getRawFd failed, code = ${err.code}, message = ${err.message}`);
    }
  }

  handleInitializedState() {
    if (this.avPlayer === undefined) {
      Logger.error(`AvPlayer is undefined`);
      return;
    }
    Logger.info('AVPlayer initialized called.');
    this.avPlayer.surfaceId = this.surfaceId;
    this.avPlayer.prepare()
      .catch((error: BusinessError) => {
        Logger.error('AvPlayerUtil', `prepare failed, code = ${error.code}, message = ${error.message}`);
        return Promise.reject(error);
      })
      .then(() => {
        Logger.info('AVPlayer prepare succeeded.');
      }, (err: BusinessError) => {
        Logger.error(`Invoke prepare failed, code is ${err.code}, message is ${err.message}`);
        this.avPlayer!.reset().catch((error: BusinessError) => {
          Logger.error('AvPlayerUtil', `reset failed, code = ${error.code}, message = ${error.message}`);
        });
      });
  }

  handlePreparedState() {
    if (this.avPlayer === undefined) {
      Logger.error(`AvPlayer is undefined`);
      return;
    }
    this.avPlayer.videoScaleType = media.VideoScaleType.VIDEO_SCALE_TYPE_FIT;
    Logger.info('AVPlayer state prepared called.');
    this.avPlayer.play().catch((error: BusinessError) => {
      Logger.error('AvPlayerUtil', `play failed, code = ${error.code}, message = ${error.message}`);
    });
    AppStorage.setOrCreate<string>(CommonConstants.AV_PLAYER_TOTAL_TIME, this.formatTime(this.avPlayer.duration));
  }

  handlePlayingState() {
    if (this.avPlayer === undefined) {
      Logger.error(`AvPlayer is undefined`);
      return;
    }
    Logger.info('AVPlayer state playing called.');
    AppStorage.setOrCreate(CommonConstants.AV_PLAYER_STATE, this.avPlayer.state);
  }

  handlePausedState() {
    if (this.avPlayer === undefined) {
      Logger.error(`AvPlayer is undefined`);
      return;
    }
    Logger.info('AVPlayer state paused called.');
    AppStorage.setOrCreate(CommonConstants.AV_PLAYER_STATE, this.avPlayer.state);
  }

  handleCompletedState() {
    if (this.avPlayer === undefined) {
      Logger.error(`AvPlayer is undefined`);
      return;
    }
    Logger.info('AVPlayer state completed called.');
    AppStorage.setOrCreate(CommonConstants.AV_PLAYER_STATE, this.avPlayer.state);
    this.avPlayer.stop().catch((error: BusinessError) => {
      Logger.error('AvPlayerUtil', `stop failed, code = ${error.code}, message = ${error.message}`);
    });
  }

  handleStoppedState() {
    Logger.info('AVPlayer state stopped called.');
  }

  handleReleaseState() {
    Logger.info('AVPlayer state released called.');
  }

  handleErrorState() {
    Logger.error('AVPlayer state error called.');
  }
}