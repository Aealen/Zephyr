import { ZephyrTheme } from '../theme/ZephyrTheme';
import { MiniPlayer } from '../components/MiniPlayer';
import { HomePage } from './home/HomePage';
import { LibraryPage } from './library/LibraryPage';
import { SettingsPage } from './settings/SettingsPage';
import { NowPlayingPage } from './playing/NowPlayingPage';
import { QueuePage } from './playing/QueuePage';

/** 应用主页面：内容区 + 迷你播放条 + 底部三 Tab；播放页/队列页为全屏覆盖层 */
@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  @StorageLink('nowPlayingVisible') nowPlayingVisible: boolean = false;
  @StorageLink('queueVisible') queueVisible: boolean = false;
  private tabLabels: string[] = ['首页', '资料库', '设置'];

  build() {
    Stack() {
      // ===== 主层 =====
      Column({ space: 0 }) {
        Column() {
          if (this.currentTab === 0) {
            HomePage()
          } else if (this.currentTab === 1) {
            LibraryPage()
          } else {
            SettingsPage()
          }
        }
        .layoutWeight(1)
        .width('100%')
        .alignItems(HorizontalAlign.Start)

        MiniPlayer()

        Row() {
          ForEach(this.tabLabels, (label: string, index: number) => {
            Text(label)
              .fontSize(12)
              .fontWeight(this.currentTab === index ? 700 : 400)
              .fontColor(this.currentTab === index ? ZephyrTheme.accent : ZephyrTheme.textSecondary)
              .padding({ top: 8, bottom: 8, left: 16, right: 16 })
              .onClick(() => {
                this.currentTab = index;
              })
          }, (label: string) => label)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 20, right: 20, top: 2, bottom: 10 })
      }
      .width('100%')
      .height('100%')
      .backgroundColor(ZephyrTheme.bgMist)

      // ===== 播放队列全屏层 =====
      if (this.queueVisible) {
        QueuePage()
      }

      // ===== 正在播放全屏层（最上层） =====
      if (this.nowPlayingVisible) {
        NowPlayingPage()
      }
    }
    .width('100%')
    .height('100%')
  }
}
