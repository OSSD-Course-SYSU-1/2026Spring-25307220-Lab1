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
import { Logger } from '../../../../Index';

export class DisplayUtil {
  static getFoldCreaseRegion(uiContext: UIContext): void {
    if (canIUse('SystemCapability.Window.SessionManager')) {
      try {
        if (display.isFoldable()) {
          let foldRegion: display.FoldCreaseRegion = display.getCurrentFoldCreaseRegion();
          let rect: display.Rect = foldRegion.creaseRects[0];
          let creaseRegion: number[] = [uiContext!.px2vp(rect.top), uiContext!.px2vp(rect.height)];
          AppStorage.setOrCreate('creaseRegion', creaseRegion);
        }
      } catch (error) {
        let err = error as BusinessError;
        Logger.error('DisplayUtil', `geetIsFoldable failed, code = ${err.code}, message = ${err.message}`);
      }
    }
  }
}

