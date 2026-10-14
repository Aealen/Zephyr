import { ZephyrTheme } from '../../theme/ZephyrTheme';

/** 设置（骨架：播放 / 曲库 / 个性化三组） */
@Component
export struct SettingsPage {
  @Builder
  settingRow(title: string, sub: string, right: string) {
    Row({ space: 12 }) {
      Column({ space: 2 }) {
        Text(title)
          .fontSize(12.5)
          .fontWeight(600)
          .fontColor(ZephyrTheme.textPrimary)
        if (sub.length > 0) {
          Text(sub)
            .fontSize(10)
            .fontColor(ZephyrTheme.textSecondary)
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      if (right.length > 0) {
        Text(right)
          .fontSize(10.5)
          .fontColor(ZephyrTheme.textSecondary)
      } else {
        Text('›')
          .fontSize(16)
          .fontColor(ZephyrTheme.textSecondary)
      }
    }
    .width('100%')
    .padding({ top: 12, bottom: 12, left: 14, right: 14 })
  }

  @Builder
  settingGroup(rows: string[][]) {
    Column() {
      ForEach(rows, (row: string[]) => {
        this.settingRow(row[0], row[1], row.length > 2 ? row[2] : '')
      }, (row: string[]) => row[0])
    }
    .width('100%')
    .borderRadius(ZephyrTheme.radiusMd)
    .backgroundColor(ZephyrTheme.surfaceGlass)
  }

  build() {
    Column({ space: 16 }) {
      Text('设置')
        .fontSize(24)
        .fontWeight(700)
        .letterSpacing(2)
        .fontColor(ZephyrTheme.textPrimary)
        .width('100%')

      this.settingGroup([
        ['音效', '均衡器 · 动态低音 · 空间混响'],
        ['播放设置', '无缝衔接 · 淡入淡出 · 音质优先']
      ])

      this.settingGroup([
        ['扫描本地音乐', 'FLAC / WAV / MP3 / AAC · Hi-Res'],
        ['导入歌单', '网易云 / QQ音乐链接 · m3u 文件']
      ])

      this.settingGroup([
        ['主题', '晕染取色跟随封面 · 自动分档', '自动'],
        ['关于 Zephyr', '', 'v0.1.0']
      ])
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
