import { media } from '@kit.MediaKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { SongInfo } from '../model/SongInfo';

/** 队列条目：歌曲信息 + 关联的本地文件 uri（空串表示未关联文件，仅演示数据） */
interface PlayableItem {
  song: SongInfo;
  uri: string;
}

/**
 * 播放内核管理器（MVP：AVPlayer 播放本地文件）
 * - 文件访问：fileIo.openSync 打开 picker 授权 uri 取 fd，以 fdSrc（fd+offset+length）交给 AVPlayer
 *   （AVPlayer 的 url 仅支持 fd:///http(s)，不支持 file:// uri，见 @ohos.multimedia.media.d.ts）
 * - 状态经 AppStorage 与 UI 双向绑定：currentTitle / currentArtist / isPlaying
 * 后续音质阶段将替换为 OHAudio 回调管线 + IEffectChain，UI 绑定不变
 */
export class PlayerManager {
  private static instance: PlayerManager | null = null;
  private player: media.AVPlayer | null = null;
  private file: fs.File | null = null;
  private queue: PlayableItem[] = [];
  private index: number = -1;
  private playToken: number = 0;

  private constructor() {
    AppStorage.setOrCreate('currentTitle', '未在播放');
    AppStorage.setOrCreate('currentArtist', '导入本地音乐后开始');
    AppStorage.setOrCreate('isPlaying', false);
  }

  static getInstance(): PlayerManager {
    if (PlayerManager.instance === null) {
      PlayerManager.instance = new PlayerManager();
    }
    return PlayerManager.instance;
  }

  /** 设置播放队列（导入的本地音乐） */
  setQueue(songs: SongInfo[], uris: string[]): void {
    this.queue = [];
    for (let i = 0; i < songs.length; i++) {
      const uri: string = i < uris.length ? uris[i] : '';
      const item: PlayableItem = { song: songs[i], uri: uri };
      this.queue.push(item);
    }
    this.index = this.queue.length > 0 ? 0 : -1;
  }

  getQueueSize(): number {
    return this.queue.length;
  }

  /** 播放指定下标（未关联文件的演示条目自动跳到下一首有文件的） */
  playIndex(index: number): void {
    if (index < 0 || index >= this.queue.length) {
      return;
    }
    if (this.queue[index].uri.length === 0) {
      this.next();
      return;
    }
    this.index = index;
    const item = this.queue[index];
    AppStorage.setOrCreate('currentTitle', item.song.title);
    AppStorage.setOrCreate('currentArtist', item.song.artist);
    this.start(item.uri);
  }

  /** 按歌名播放（首页"继续播放"卡片） */
  playByTitle(title: string): void {
    for (let i = 0; i < this.queue.length; i++) {
      if (this.queue[i].song.title === title) {
        this.playIndex(i);
        return;
      }
    }
  }

  /** 播放/暂停切换（无播放器时从当前下标起播） */
  toggle(): void {
    if (this.player === null) {
      if (this.index >= 0) {
        this.playIndex(this.index);
      }
      return;
    }
    const p = this.player;
    if (AppStorage.get<boolean>('isPlaying') === true) {
      p.pause().catch((e: BusinessError) => {
        console.error(`[Zephyr] pause failed: ${e.code} ${e.message}`);
      });
    } else {
      p.play().catch((e: BusinessError) => {
        console.error(`[Zephyr] play failed: ${e.code} ${e.message}`);
      });
    }
  }

  /** 下一曲（循环队列，跳过无文件项） */
  next(): void {
    if (this.queue.length === 0) {
      return;
    }
    let idx: number = this.index + 1;
    for (let n = 0; n < this.queue.length; n++) {
      if (idx >= this.queue.length) {
        idx = 0;
      }
      if (this.queue[idx].uri.length > 0) {
        this.playIndex(idx);
        return;
      }
      idx++;
    }
  }

  private start(uri: string): void {
    this.releasePlayer();
    this.playToken++;
    const token = this.playToken;

    let file: fs.File;
    let size: number;
    try {
      file = fs.openSync(uri, fs.OpenMode.READ_ONLY);
      size = fs.statSync(file.fd).size;
      console.info(`[Zephyr] opened uri, fd=${file.fd}, size=${size}`);
    } catch (e) {
      const err = e as BusinessError;
      console.error(`[Zephyr] openSync failed: ${err.code} ${err.message} uri=${uri}`);
      return;
    }

    media.createAVPlayer().then((player: media.AVPlayer) => {
      if (token !== this.playToken) {
        player.release();
        fs.closeSync(file);
        return;
      }
      this.player = player;
      this.file = file;
      player.on('stateChange', (state: string) => {
        if (token !== this.playToken) {
          return;
        }
        console.info(`[Zephyr] state -> ${state}`);
        if (state === 'initialized') {
          // 官方状态机：prepared 仅在 initialized 下显式调用 prepare() 后进入
          player.prepare().then(() => {
            console.info('[Zephyr] prepare done');
          }).catch((e: BusinessError) => {
            console.error(`[Zephyr] prepare failed: ${e.code} ${e.message}`);
          });
        } else if (state === 'prepared') {
          player.play().catch((e: BusinessError) => {
            console.error(`[Zephyr] first play failed: ${e.code} ${e.message}`);
          });
        } else if (state === 'playing') {
          AppStorage.setOrCreate('isPlaying', true);
        } else if (state === 'paused') {
          AppStorage.setOrCreate('isPlaying', false);
        } else if (state === 'completed') {
          AppStorage.setOrCreate('isPlaying', false);
          this.next();
        } else if (state === 'error') {
          AppStorage.setOrCreate('isPlaying', false);
        }
      });
      player.on('error', (err: BusinessError) => {
        console.error(`[Zephyr] player error: ${err.code} ${err.message}`);
        AppStorage.setOrCreate('isPlaying', false);
      });
      player.fdSrc = { fd: file.fd, offset: 0, length: size };
      console.info('[Zephyr] fdSrc set, waiting for prepared...');
    }).catch((err: BusinessError) => {
      console.error(`[Zephyr] createAVPlayer failed: ${err.code} ${err.message}`);
      fs.closeSync(file);
    });
  }

  private releasePlayer(): void {
    this.playToken++;
    if (this.player !== null) {
      const p = this.player;
      this.player = null;
      p.release().catch((e: BusinessError) => {
        console.error(`[Zephyr] release failed: ${e.code}`);
      });
    }
    if (this.file !== null) {
      try {
        fs.closeSync(this.file);
      } catch (e) {
        // fd 已失效，忽略
      }
      this.file = null;
    }
    AppStorage.setOrCreate('isPlaying', false);
  }
}
