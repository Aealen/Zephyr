import { ZephyrTheme } from '../../theme/ZephyrTheme';
import { SongInfo, formatDuration } from '../../model/SongInfo';
import { PlayerManager } from '../../player/PlayerManager';
import { LibraryStore } from '../../model/LibraryStore';
import { picker } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

/** 资料库：本地音乐导入（音频选择器，批量追加）+ 持久化曲库列表 */
@Component
export struct LibraryPage {
  @StorageLink('librarySongs') songs: SongInfo[] = [];
  @StorageLink('libraryUris') uris: string[] = [];
  private tabs: string[] = ['歌曲', '专辑', '歌单', '艺人'];

  /** 打开系统音频选择器，批量追加到曲库并持久化 */
  private pickMusic(): void {
    const audioPicker = new picker.AudioViewPicker();
    const options = new picker.AudioSelectOptions();
    audioPicker.select(options).then(async (uris: string[]) => {
      if (uris.length === 0) {
        return;
      }
      const startIndex: number = this.songs.length;
      for (let i = 0; i < uris.length; i++) {
        this.songs.push(this.parseFromUri(uris[i], startIndex + i));
        this.uris.push(uris[i]);
      }
      // 首次导入：设队列；已有队列：追加后若未在播则游标保持
      if (PlayerManager.getInstance().getQueueSize() === 0) {
        PlayerManager.getInstance().setQueue(this.songs, this.uris);
        PlayerManager.getInstance().playIndex(startIndex);
      }
      await LibraryStore.saveLibrary(this.songs, this.uris);
    }).catch((err: BusinessError) => {
      console.error(`[Zephyr] pick failed: ${err.code} ${err.message}`);
    });
  }

  /** 从文件 uri 解析歌名/歌手（"歌手 - 歌名.ext" 约定，否则以文件名为歌名） */
  private parseFromUri(uri: string, index: number): SongInfo {
    let name: string = uri;
    const slash: number = name.lastIndexOf('/');
    if (slash >= 0) {
      name = name.substring(slash + 1);
    }
    try {
      name = decodeURIComponent(name);
    } catch (e) {
      // 保留原名
    }
    const dot: number = name.lastIndexOf('.');
    const stem: string = dot > 0 ? name.substring(0, dot) : name;
    const dash: number = stem.indexOf(' - ');
    const title: string = dash > 0 ? stem.substring(dash + 3).trim() : stem.trim();
    const artist: string = dash > 0 ? stem.substring(0, dash).trim() : '本地音乐';
    const format: string = dot > 0 ? name.substring(dot + 1).toUpperCase() : 'AUDIO';
    const song: SongInfo = {
      id: index.toString(),
      title: title,
      artist: artist,
      album: '',
      durationMs: 0,
      format: format
    };
    return song;
  }

  @Builder
  songRow(index: number, song: SongInfo) {
    Row({ space: 14 }) {
      Text(String(index + 1).padStart(2, '0'))
        .fontSize(11)
        .fontColor(ZephyrTheme.textSecondary)
      Column({ space: 2 }) {
        Text(song.title)
          .fontSize(12.5)
          .fontWeight(600)
          .fontColor(ZephyrTheme.textPrimary)
          .maxLines(1)
        Text(song.artist)
          .fontSize(10.5)
          .fontColor(ZephyrTheme.textSecondary)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(song.format)
        .fontSize(10)
        .fontColor(ZephyrTheme.textSecondary)
      if (song.durationMs > 0) {
        Text(formatDuration(song.durationMs))
          .fontSize(10.5)
          .fontColor(ZephyrTheme.textSecondary)
      }
    }
    .width('100%')
    .padding({ top: 4, bottom: 4 })
    .onClick(() => {
      PlayerManager.getInstance().playIndex(index);
    })
  }

  build() {
    Column({ space: 18 }) {
      Text('资料库')
        .fontSize(24)
        .fontWeight(700)
        .letterSpacing(2)
        .fontColor(ZephyrTheme.textPrimary)
        .width('100%')

      // 导入本地音乐（文件选择器）
      Row({ space: 12 }) {
        Column()
          .width(34)
          .height(34)
          .borderRadius(ZephyrTheme.radiusSm)
          .backgroundColor(ZephyrTheme.accent)
        Column({ space: 3 }) {
          Text('导入本地音乐')
            .fontSize(12.5)
            .fontWeight(600)
            .fontColor(ZephyrTheme.textPrimary)
          Text('选择音频文件 · 支持 FLAC / WAV / MP3 / AAC 等')
            .fontSize(10.5)
            .fontColor(ZephyrTheme.textSecondary)
            .maxLines(1)
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)
        Text('›')
          .fontSize(16)
          .fontColor(ZephyrTheme.textSecondary)
      }
      .width('100%')
      .padding(14)
      .borderRadius(ZephyrTheme.radiusMd)
      .backgroundColor(ZephyrTheme.surfaceGlass)
      .onClick(() => {
        this.pickMusic();
      })

      // 分栏（骨架：歌曲高亮）
      Row({ space: 22 }) {
        ForEach(this.tabs, (tab: string) => {
          Text(tab)
            .fontSize(13)
            .fontWeight(tab === '歌曲' ? 600 : 400)
            .fontColor(tab === '歌曲' ? ZephyrTheme.textPrimary : ZephyrTheme.textSecondary)
        })
      }
      .width('100%')

      // 歌曲列表（导入前为空态提示）
      if (this.songs.length === 0) {
        Column({ space: 8 }) {
          Text('曲库还是空的')
            .fontSize(13)
            .fontColor(ZephyrTheme.textDistant)
          Text('点击上方卡片导入本地音乐')
            .fontSize(11)
            .fontColor(ZephyrTheme.textDistant)
        }
        .width('100%')
        .padding({ top: 32 })
      } else {
        Column({ space: 15 }) {
          ForEach(this.songs, (song: SongInfo, index: number) => {
            this.songRow(index, song)
          }, (song: SongInfo) => song.id)
        }
        .width('100%')
      }
    }
    .padding({
      left: ZephyrTheme.pagePadding,
      right: ZephyrTheme.pagePadding,
      top: 12,
      bottom: 8
    })
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
