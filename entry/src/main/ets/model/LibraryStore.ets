import { preferences } from '@kit.ArkData';
import { SongInfo } from './SongInfo';

/**
 * 持久化仓库：Preferences 存曲库/队列/播放顺序/上次进度
 * 应用重启后恢复上次状态（MVP 不做自动续播，只恢复队列与游标）
 */
export class LibraryStore {
  private static store: preferences.Preferences | null = null;

  static async init(context: Context): Promise<void> {
    LibraryStore.store = await preferences.getPreferences(context, 'zephyr_store');
  }

  static async saveLibrary(songs: SongInfo[], uris: string[]): Promise<void> {
    if (LibraryStore.store === null) {
      return;
    }
    await LibraryStore.store.put('lib_songs', JSON.stringify(songs));
    await LibraryStore.store.put('lib_uris', JSON.stringify(uris));
    await LibraryStore.store.flush();
  }

  /** 恢复曲库；无存档返回空 */
  static async loadLibrary(): Promise<SongInfo[]> {
    if (LibraryStore.store === null) {
      return [];
    }
    const raw: string = await LibraryStore.store.get('lib_songs', '') as string;
    const rawUris: string = await LibraryStore.store.get('lib_uris', '') as string;
    if (raw.length === 0 || rawUris.length === 0) {
      return [];
    }
    try {
      const songs: SongInfo[] = JSON.parse(raw) as SongInfo[];
      const uris: string[] = JSON.parse(rawUris) as string[];
      PlayerStoreBridge.pendingUris = uris;
      return songs;
    } catch (e) {
      return [];
    }
  }

  static async savePlayState(index: number, positionMs: number, mode: number): Promise<void> {
    if (LibraryStore.store === null) {
      return;
    }
    await LibraryStore.store.put('play_index', index);
    await LibraryStore.store.put('play_position', positionMs);
    await LibraryStore.store.put('play_mode', mode);
    await LibraryStore.store.flush();
  }

  static async loadPlayState(): Promise<number[]> {
    if (LibraryStore.store === null) {
      return [];
    }
    const index: number = await LibraryStore.store.get('play_index', -1) as number;
    const position: number = await LibraryStore.store.get('play_position', 0) as number;
    const mode: number = await LibraryStore.store.get('play_mode', 1) as number;
    return [index, position, mode];
  }
}

/** 桥接容器：loadLibrary 解出的 uris 供 PlayerManager 取用（ArkTS 不允许多返回值对象随意流转） */
export class PlayerStoreBridge {
  static pendingUris: string[] = [];
}
