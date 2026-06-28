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

import { display } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { CommonConstants } from '../constants/CommonConstants';
import Logger from './Logger';

export class DeviceScreen {
  /**
   * Get the screen height.
   *
   * @returns screen height.
   */
  public static getDeviceHeight(): number {
    try {
      let displayObject = display.getDefaultDisplaySync();
      let screenPixelHeight = displayObject.height;
      let screenDensityDPI = displayObject.densityDPI;
      return screenPixelHeight * (CommonConstants.SCREEN_DPI_CONSTANT / screenDensityDPI);
    } catch (error) {
      let err = error as BusinessError;
      Logger.error('DeviceScreen', `getDefaultDisplaySync failed, code = ${err.code}, message = ${err.message}`);
    }
    return 0;
  }

  /**
   * Get the screen width.
   *
   * @returns screen width.
   */
  public static getDeviceWidth(): number {
    try {
      let displayObject = display.getDefaultDisplaySync();
      let screenPixelWidth = displayObject.width;
      let screenDensityDPI = displayObject.densityDPI;
      return screenPixelWidth * (CommonConstants.SCREEN_DPI_CONSTANT / screenDensityDPI);
    } catch (error) {
      let err = error as BusinessError;
      Logger.error('DeviceScreen', `getDefaultDisplaySync failed, code = ${err.code}, message = ${err.message}`);
    }
    return 0;

  }
}