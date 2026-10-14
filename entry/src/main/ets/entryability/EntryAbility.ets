import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { PlayerManager } from '../player/PlayerManager';
import { LibraryStore, PlayerStoreBridge } from '../model/LibraryStore';
import { PlayMode } from '../model/PlayMode';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    // 初始化播放内核与全局状态
    PlayerManager.getInstance();
    // 持久化仓库初始化 + 恢复上次曲库与播放顺序（不自动续播）
    LibraryStore.init(this.context).then(() => {
      return LibraryStore.loadLibrary();
    }).then((songs) => {
      if (songs.length > 0) {
        const uris: string[] = PlayerStoreBridge.pendingUris;
        PlayerManager.getInstance().setQueue(songs, uris);
        AppStorage.setOrCreate('librarySongs', songs);
        AppStorage.setOrCreate('libraryUris', uris);
        return LibraryStore.loadPlayState();
      }
      return [];
    }).then((state) => {
      if (state.length === 3) {
        PlayerManager.getInstance().setPlayMode(state[2] as PlayMode);
        console.info(`[Zephyr] restored library, index=${state[0]}, mode=${state[2]}`);
      }
    }).catch((err: BusinessError) => {
      console.error(`[Zephyr] restore failed: ${err.code} ${err.message}`);
    });
    hilog.info(DOMAIN, 'Zephyr', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}