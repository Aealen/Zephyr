import { ZephyrTheme } from '../../theme/ZephyrTheme';
import { LyricLine } from '../../model/LyricLine';

/**
 * 歌词视图：逐行三层级（当前行/邻近行/远处行），点击行可扩展为跳转进度
 * MVP 为均匀分布展示型（无时间戳）；LRC 接入后由 positionMs 驱动当前行索引
 */
@Component
export struct LyricsView {
  @StorageLink('positionMs') positionMs: number = 0;
  @Prop lyrics: LyricLine[] = [];
  /** 当前行索引（无时间戳时由父组件定时推进或恒为 -1） */
  @Prop currentIndex: number = -1;

  /** 行样式：当前行 23px 粗体，邻近行 16px 中灰，远处行 15px 浅灰（对齐原型） */
  private lineSize(index: number): number {
    if (index === this.currentIndex) {
      return 23;
    }
    if (this.currentIndex >= 0 && Math.abs(index - this.currentIndex) === 1) {
      return 16;
    }
    return 15;
  }

  private lineColor(index: number): string {
    if (index === this.currentIndex) {
      return ZephyrTheme.textPrimary;
    }
    if (this.currentIndex >= 0 && Math.abs(index - this.currentIndex) <= 1) {
      return ZephyrTheme.textSecondary;
    }
    return ZephyrTheme.textDistant;
  }

  private lineWeight(index: number): number {
    return index === this.currentIndex ? 700 : 400;
  }

  build() {
    Column({ space: 22 }) {
      ForEach(this.lyrics, (line: LyricLine, index: number) => {
        Text(line.text)
          .fontSize(this.lineSize(index))
          .fontWeight(this.lineWeight(index))
          .fontColor(this.lineColor(index))
          .letterSpacing(1)
          .width('100%')
          .textAlign(TextAlign.Start)
      }, (line: LyricLine, index: number) => `${index}-${line.text}`)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Start)
  }
}
