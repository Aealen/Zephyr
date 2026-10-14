import { ZephyrTheme } from '../../theme/ZephyrTheme';
import { SongInfo } from '../../model/SongInfo';
import { PlayerManager } from '../../player/PlayerManager';

/**
 * 播放队列页（全屏层）：正在播放高亮行 + 队列列表
 * 遵循原型：顶部不放播放顺序控件（顺序仅在播放页控制行展示）
 */
@Component
export struct QueuePage {
  @StorageLink('currentTitle') currentTitle: string = '';
  @State queueSongs: SongInfo[] = [];
  @State currentIndex: number = -1;
  private player: PlayerManager = PlayerManager.getInstance();

  aboutToAppear(): void {
    this.refresh();
  }

  refresh(): void {
    this.queueSongs = this.player.getQueueSongs();
    this.currentIndex = this.player.getCurrentIndex();
  }

  @Builder
  nowRow(song: SongInfo) {
    Row({ space: 12 }) {
      Column()
        .width(40)
        .height(40)
        .borderRadius(10)
        .backgroundColor(ZephyrTheme.coverGreen)
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
      // 动效音条（静态三条，播放指示）
      Row({ space: 2 }) {
        Column().width(3).height(6).borderRadius(1).backgroundColor(ZephyrTheme.accent)
        Column().width(3).height(11).borderRadius(1).backgroundColor(ZephyrTheme.accent)
        Column().width(3).height(8).borderRadius(1).backgroundColor(ZephyrTheme.accent)
      }
      .alignItems(VerticalAlign.Bottom)
    }
    .width('100%')
    .padding(12)
    .borderRadius(ZephyrTheme.radiusMd)
    .backgroundColor('#CCFFFFFF')
  }

  @Builder
  queueRow(index: number, song: SongInfo) {
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
    }
    .width('100%')
    .padding({ top: 6, bottom: 6 })
    .onClick(() => {
      this.player.playIndex(index);
      this.refresh();
    })
  }

  build() {
    Column() {
      // 顶栏：收起 | 播放队列 | 清空占位
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(22)
          .fontColor([ZephyrTheme.textPrimary])
          .padding(8)
          .onClick(() => {
            // 从队列页返回：若之前从播放页进入则回到播放页，否则回主层
            AppStorage.setOrCreate('queueVisible', false);
            AppStorage.setOrCreate('nowPlayingVisible', true);
          })
        Blank()
        Text('播放队列')
          .fontSize(12)
          .fontColor(ZephyrTheme.textSecondary)
          .letterSpacing(3)
        Blank()
        Column().width(38)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8 })

      Column({ space: 16 }) {
        if (this.queueSongs.length === 0) {
          Column({ space: 8 }) {
            Text('队列为空')
              .fontSize(13)
              .fontColor(ZephyrTheme.textDistant)
            Text('导入本地音乐后这里显示播放队列')
              .fontSize(11)
              .fontColor(ZephyrTheme.textDistant)
          }
          .width('100%')
          .padding({ top: 48 })
        } else {
          Text('正 在 播 放')
            .fontSize(11)
            .fontColor(ZephyrTheme.textSecondary)
            .letterSpacing(3)
            .width('100%')
          if (this.currentIndex >= 0 && this.currentIndex < this.queueSongs.length) {
            this.nowRow(this.queueSongs[this.currentIndex])
          }
          Text('接 下 来')
            .fontSize(11)
            .fontColor(ZephyrTheme.textSecondary)
            .letterSpacing(3)
            .width('100%')
            .margin({ top: 6 })
          Column({ space: 12 }) {
            ForEach(this.queueSongs, (song: SongInfo, index: number) => {
              if (index !== this.currentIndex) {
                this.queueRow(index, song)
              }
            }, (song: SongInfo, index: number) => `${index}-${song.id}`)
          }
          .width('100%')
        }
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 28, right: 28, top: 12 })

      // Home 指示条
      Row() {
        Column()
          .width(120)
          .height(4)
          .borderRadius(2)
          .backgroundColor(ZephyrTheme.accent)
          .opacity(0.3)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ZephyrTheme.bgMist)
  }
}
