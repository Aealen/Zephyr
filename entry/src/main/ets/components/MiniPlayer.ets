import { ZephyrTheme } from '../theme/ZephyrTheme';
import { PlayerManager } from '../player/PlayerManager';

/**
 * 迷你播放条（常驻底部导航上方）
 * 绑定 AppStorage：currentTitle / currentArtist / isPlaying
 * 点击条身展开播放页；图标为系统 Symbol 符号
 */
@Component
export struct MiniPlayer {
  @StorageLink('currentTitle') title: string = '未在播放';
  @StorageLink('currentArtist') artist: string = '导入本地音乐后开始';
  @StorageLink('isPlaying') isPlaying: boolean = false;

  build() {
    Row({ space: 12 }) {
      // 封面占位（接入媒体元数据后替换为真实封面）
      Column()
        .width(44)
        .height(44)
        .borderRadius(ZephyrTheme.radiusSm)
        .backgroundColor(ZephyrTheme.coverGreen)

      Column({ space: 2 }) {
        Text(this.title)
          .fontSize(12)
          .fontWeight(600)
          .fontColor(ZephyrTheme.textPrimary)
          .maxLines(1)
        Text(this.artist)
          .fontSize(10)
          .fontColor(ZephyrTheme.textSecondary)
          .maxLines(1)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .onClick(() => {
        AppStorage.setOrCreate('nowPlayingVisible', true);
      })

      // 播放/暂停（Symbol 符号）
      if (this.isPlaying) {
        SymbolGlyph($r('sys.symbol.pause_fill'))
          .fontSize(22)
          .fontColor([ZephyrTheme.textPrimary])
          .padding(6)
          .onClick(() => {
            PlayerManager.getInstance().toggle();
          })
      } else {
        SymbolGlyph($r('sys.symbol.play_fill'))
          .fontSize(22)
          .fontColor([ZephyrTheme.textPrimary])
          .padding(6)
          .onClick(() => {
            PlayerManager.getInstance().toggle();
          })
      }

      // 下一曲
      SymbolGlyph($r('sys.symbol.forward_end_fill'))
        .fontSize(20)
        .fontColor([ZephyrTheme.textSecondary])
        .padding(6)
        .onClick(() => {
          PlayerManager.getInstance().next();
        })
    }
    .width('90%')
    .padding(10)
    .borderRadius(20)
    .backgroundColor(ZephyrTheme.surfaceGlass)
    .onClick(() => {
      AppStorage.setOrCreate('nowPlayingVisible', true);
    })
  }
}
