import { BackupExtensionAbility } from '@kit.CoreFileKit';
import { BundleVersion } from '@kit.AbilityKit';

const TAG: string = `DefaultBackupAbility`;

export default class DefaultBackupAbility extends BackupExtensionAbility {
  async onBackup(): Promise<void> {
    console.log(TAG, `onBackup ok`);
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    console.log(TAG, `onRestore ok ${JSON.stringify(bundleVersion)}`);
    if (bundleVersion.name.startsWith('0.0.0.0')) {
      console.log(TAG, `onRestore ok`);
    }
  }
}
