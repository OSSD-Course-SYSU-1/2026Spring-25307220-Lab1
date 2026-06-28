import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, TAG, 'Ability onCreate');
    if (want.parameters && want.parameters['flowState'] !== undefined) {
      try {
        const stateJson: string = want.parameters['flowState'] as string;
        AppStorage.setOrCreate<string>('recoveredFlowState', stateJson);
        hilog.info(0x0000, TAG, `Recovered flow state from continuation`);
      } catch (err) {
        hilog.error(0x0000, TAG, `Failed to recover flow state: ${JSON.stringify(err)}`);
      }
    }
  }

  onDestroy(): void {
    hilog.info(0x0000, TAG, 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(0x0000, TAG, 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(0x0000, TAG, `Failed to load the content. Cause: ${JSON.stringify(err)}`);
        return;
      }
      hilog.info(0x0000, TAG, 'Succeeded in loading the content.');

      const mainWindow = windowStage.getMainWindowSync();
      if (mainWindow) {
        mainWindow.on('windowSizeChange', (size: window.Size) => {
          const widthBp: WidthBreakpoint =
            mainWindow.getUIContext().getWindowWidthBreakpoint();
          AppStorage.setOrCreate<WidthBreakpoint>('widthBp', widthBp);

          const heightBp: HeightBreakpoint =
            mainWindow.getUIContext().getWindowHeightBreakpoint();
          AppStorage.setOrCreate<HeightBreakpoint>('heightBp', heightBp);

          hilog.debug(0x0000, TAG,
            `windowSizeChange: widthBp=${widthBp}, heightBp=${heightBp}, ` +
            `size=${size.width}x${size.height}`);
        });

        const initWidthBp: WidthBreakpoint =
          mainWindow.getUIContext().getWindowWidthBreakpoint();
        const initHeightBp: HeightBreakpoint =
          mainWindow.getUIContext().getWindowHeightBreakpoint();
        AppStorage.setOrCreate<WidthBreakpoint>('widthBp', initWidthBp);
        AppStorage.setOrCreate<HeightBreakpoint>('heightBp', initHeightBp);
        hilog.info(0x0000, TAG,
          `Initial breakpoints: widthBp=${initWidthBp}, heightBp=${initHeightBp}`);
      }
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(0x0000, TAG, 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(0x0000, TAG, 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(0x0000, TAG, 'Ability onBackground');
  }

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    try {
      const flowStateJson: string | undefined =
        AppStorage.get<string>('flowStateForContinue');
      if (flowStateJson) {
        wantParam['flowState'] = flowStateJson;
        hilog.info(0x0000, TAG, `Continue with flow state: ${flowStateJson.substring(0, 50)}...`);
        return AbilityConstant.OnContinueResult.AGREE;
      }
    } catch (err) {
      hilog.error(0x0000, TAG, `onContinue failed: ${JSON.stringify(err)}`);
    }
    return AbilityConstant.OnContinueResult.MISMATCH;
  }
}
