import { ZephyrTheme } from '../../theme/ZephyrTheme';
import { SongInfo } from '../../model/SongInfo';
import { PlayerManager } from '../../player/PlayerManager';

/** 首页 · 发现（骨架） */
@Component
export struct HomePage {
  private recentSongs: SongInfo[] = [
    { id: '1', title: '雾航', artist: '陶然', album: '雾航', durationMs: 268000, format: 'FLAC' },
    { id: '2', title: '夜航线', artist: '星野', album: '夜航线', durationMs: 232000, format: 'FLAC' }
  ];

  @Builder
  recentCard(song: SongInfo, coverColor: string) {
    Column({ space: 8 }) {
      Column()
        .width(150)
        .height(150)
        .borderRadius(ZephyrTheme.radiusMd)
        .backgroundColor(coverColor)
      Text(song.title)
        .fontSize(12.5)
        .fontWeight(600)
        .fontColor(ZephyrTheme.textPrimary)
      Text(song.artist)
        .fontSize(10.5)
        .fontColor(ZephyrTheme.textSecondary)
    }
    .alignItems(HorizontalAlign.Start)
    .onClick(() => {
      PlayerManager.getInstance().playByTitle(song.title);
    })
  }

  @Builder
  playlistRow(name: string, sub: string, duration: string, coverColor: string) {
    Row({ space: 14 }) {
      Column()
        .width(56)
        .height(56)
        .borderRadius(ZephyrTheme.radiusSm)
        .backgroundColor(coverColor)
      Column({ space: 3 }) {
        Text(name)
          .fontSize(12.5)
          .fontWeight(600)
          .fontColor(ZephyrTheme.textPrimary)
        Text(sub)
          .fontSize(10.5)
          .fontColor(ZephyrTheme.textSecondary)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text(duration)
        .fontSize(10.5)
        .fontColor(ZephyrTheme.textSecondary)
    }
    .width('100%')
  }

  build() {
    Column({ space: 22 }) {
      // 标题行：品牌 + 快捷入口（音效/搜索，图标待符号资源接入）
      Row() {
        Text('ZEPHYR')
          .fontSize(22)
          .fontWeight(700)
          .letterSpacing(4)
          .fontColor(ZephyrTheme.textPrimary)
        Blank()
        Text('音效')
          .fontSize(13)
          .fontColor(ZephyrTheme.textSecondary)
          .padding({ left: 12 })
        Text('搜索')
          .fontSize(13)
          .fontColor(ZephyrTheme.textSecondary)
          .padding({ left: 16 })
      }
      .width('100%')

      Text('今晚听点什么')
        .fontSize(13)
        .fontColor(ZephyrTheme.textSecondary)
        .letterSpacing(2)
        .width('100%')

      // 继续播放（横滑卡片，骨架展示两张）
      Column({ space: 12 }) {
        Text('继 续 播 放')
          .fontSize(11)
          .fontColor(ZephyrTheme.textSecondary)
          .letterSpacing(3)
          .width('100%')
        Row({ space: 14 }) {
          this.recentCard(this.recentSongs[0], ZephyrTheme.coverGreen)
          this.recentCard(this.recentSongs[1], ZephyrTheme.coverBlue)
        }
      }
      .width('100%')

      // 为你精选（歌单列表）
      Column({ space: 12 }) {
        Text('为 你 精 选')
          .fontSize(11)
          .fontColor(ZephyrTheme.textSecondary)
          .letterSpacing(3)
          .width('100%')
        Column({ space: 16 }) {
          this.playlistRow('深夜雾中行', '歌单 · 32 首', '1h 48m', ZephyrTheme.coverWarm)
          this.playlistRow('山谷回声', '歌单 · 18 首', '58m', ZephyrTheme.coverGreen)
        }
        .width('100%')
      }
      .width('100%')
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
