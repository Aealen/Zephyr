import { ZephyrTheme } from '../../theme/ZephyrTheme';
import { PlayerManager } from '../../player/PlayerManager';
import { PlayMode } from '../../model/PlayMode';
import { LyricLine, sampleLyrics } from '../../model/LyricLine';
import { LrcParser } from '../../model/LrcParser';
import { LyricsView } from './LyricsView';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

/** 格式化毫秒为 m:ss */
function fmt(ms: number): string {
  const total: number = Math.floor(ms / 1000);
  const m: number = Math.floor(total / 60);
  const s: number = total % 60;
  return `${m.toString()}:${s < 10 ? '0' + s.toString() : s.toString()}`;
}

/**
 * 正在播放页（全屏层）：封面 + 大字歌名 + 进度条 + 控制行五元素 + 歌词切换
 * 布局遵循原型定稿：播放列表 | 上一曲 | 播放/暂停(大圆) | 下一曲 | 播放顺序
 */
@Component
export struct NowPlayingPage {
  @StorageLink('currentTitle') title: string = '未在播放';
  @StorageLink('currentArtist') artist: string = '';
  @StorageLink('isPlaying') isPlaying: boolean = false;
  @StorageLink('positionMs') positionMs: number = 0;
  @StorageLink('durationMs') durationMs: number = 0;
  @StorageLink('playMode') playMode: PlayMode = PlayMode.LOOP;
  @State showLyrics: boolean = false;
  @State dragRatio: number = -1;
  @State lrcLines: LyricLine[] = [];
  @State hasLrc: boolean = false;
  private player: PlayerManager = PlayerManager.getInstance();
  private fallbackLyrics: LyricLine[] = sampleLyrics();
  private barWidthVp: number = 0;

  aboutToAppear(): void {
    this.loadLyrics();
  }

  /** 尝试读取当前曲目的同名 .lrc（音频 uri 去扩展名 + .lrc）；失败回退示例歌词 */
  private loadLyrics(): void {
    const uris: string[] = AppStorage.get<string[]>('libraryUris') ?? [];
    const index: number = this.player.getCurrentIndex();
    this.hasLrc = false;
    this.lrcLines = [];
    if (index < 0 || index >= uris.length) {
      return;
    }
    const lrcUri: string = uris[index].replace(/\.[a-zA-Z0-9]+$/, '.lrc');
    try {
      const file = fs.openSync(lrcUri, fs.OpenMode.READ_ONLY);
      const stat = fs.statSync(file.fd);
      const buf = new ArrayBuffer(stat.size);
      fs.readSync(file.fd, buf);
      fs.closeSync(file);
      const content: string = String.fromCharCode(...new Uint8Array(buf));
      const parsed: LyricLine[] = LrcParser.parse(content);
      if (parsed.length > 0) {
        this.lrcLines = parsed;
        this.hasLrc = true;
        console.info(`[Zephyr] lrc loaded: ${parsed.length} lines`);
        return;
      }
    } catch (e) {
      const err = e as BusinessError;
      console.info(`[Zephyr] no lrc for current track (${err.code})`);
    }
  }

  /** 进度比例（拖动中优先取拖动值） */
  private progress(): number {
    if (this.dragRatio >= 0) {
      return this.dragRatio;
    }
    if (this.durationMs <= 0) {
      return 0;
    }
    return Math.min(1, this.positionMs / this.durationMs);
  }

  /** 歌词当前行：有 LRC 用二分定位，无 LRC 按播放比例映射示例歌词 */
  private lyricIndex(): number {
    if (this.hasLrc) {
      return LrcParser.currentIndex(this.lrcLines, this.positionMs);
    }
    if (this.durationMs <= 0 || !this.isPlaying) {
      return -1;
    }
    const idx: number = Math.floor(this.progress() * this.fallbackLyrics.length);
    return Math.min(this.fallbackLyrics.length - 1, Math.max(0, idx));
  }

  private activeLyrics(): LyricLine[] {
    return this.hasLrc ? this.lrcLines : this.fallbackLyrics;
  }

  /** 播放顺序图标随状态切换（单按钮多状态） */
  private modeSymbol(): Resource {
    if (this.playMode === PlayMode.SEQUENTIAL) {
      return $r('sys.symbol.arrow_right');
    }
    if (this.playMode === PlayMode.ONE) {
      return $r('sys.symbol.repeat_1');
    }
    if (this.playMode === PlayMode.RANDOM) {
      return $r('sys.symbol.shuffle');
    }
    return $r('sys.symbol.repeat');
  }

  build() {
    Column() {
      // 顶栏：收起 | 正在播放 | 歌词切换
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(22)
          .fontColor([ZephyrTheme.textPrimary])
          .padding(8)
          .onClick(() => {
            AppStorage.setOrCreate('nowPlayingVisible', false);
          })
        Blank()
        Text('正在播放')
          .fontSize(12)
          .fontColor(ZephyrTheme.textSecondary)
          .letterSpacing(3)
        Blank()
        Text('歌词')
          .fontSize(12)
          .fontColor(this.showLyrics ? ZephyrTheme.textPrimary : ZephyrTheme.textSecondary)
          .padding(8)
          .onClick(() => {
            this.showLyrics = !this.showLyrics;
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8 })

      if (!this.showLyrics) {
        Column() {
          Blank()
          // 专辑封面（占位色块；媒体元数据接入后换真实封面）
          Column()
            .width('76%')
            .aspectRatio(1)
            .borderRadius(ZephyrTheme.radiusLg)
            .backgroundColor(ZephyrTheme.coverGreen)
          Blank()
          // 歌名区（杂志排版：左对齐大字）
          Column({ space: 6 }) {
            Text(this.title)
              .fontSize(34)
              .fontWeight(700)
              .letterSpacing(3)
              .fontColor(ZephyrTheme.textPrimary)
              .maxLines(1)
            Text(this.artist)
              .fontSize(13)
              .fontColor(ZephyrTheme.textSecondary)
              .maxLines(1)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Start)
          .margin({ top: 24 })

          // 进度组
          Column({ space: 8 }) {
            Stack({ alignContent: Alignment.Start }) {
              Column()
                .width('100%')
                .height(2)
                .borderRadius(1)
                .backgroundColor(ZephyrTheme.trackBase)
              Column()
                .width(`${(this.progress() * 100).toFixed(1)}%`)
                .height(2)
                .borderRadius(1)
                .backgroundColor(ZephyrTheme.accent)
              Column()
                .width(10)
                .height(10)
                .borderRadius(5)
                .backgroundColor(ZephyrTheme.accent)
                .margin({ left: `${(this.progress() * 100).toFixed(1)}%` })
            }
            .width('100%')
            .height(14)
            .onAreaChange((_old: Area, newArea: Area) => {
              this.barWidthVp = newArea.width as number;
            })
            .onClick((event: ClickEvent) => {
              if (this.barWidthVp > 0 && this.durationMs > 0) {
                this.player.seek((event.x / this.barWidthVp) * this.durationMs);
              }
            })
            Row() {
              Text(fmt(this.positionMs))
                .fontSize(11)
                .fontColor(ZephyrTheme.textSecondary)
              Blank()
              Text(fmt(this.durationMs))
                .fontSize(11)
                .fontColor(ZephyrTheme.textSecondary)
            }
            .width('100%')
          }
          .width('100%')
          .margin({ top: 20 })

          // 控制行五元素：播放列表 | 上一曲 | 播放/暂停(大圆) | 下一曲 | 播放顺序
          Row() {
            SymbolGlyph($r('sys.symbol.list_bullet'))
              .fontSize(20)
              .fontColor([ZephyrTheme.textPrimary])
              .padding(10)
              .onClick(() => {
                // 两全屏层互斥：打开队列页时收起播放页（返回队列页自带收起到主层）
                AppStorage.setOrCreate('queueVisible', true);
                AppStorage.setOrCreate('nowPlayingVisible', false);
              })
            Blank()
            SymbolGlyph($r('sys.symbol.backward_end_fill'))
              .fontSize(26)
              .fontColor([ZephyrTheme.textPrimary])
              .padding(10)
              .onClick(() => {
                this.player.previous();
              })
            Blank()
            Column() {
              if (this.isPlaying) {
                SymbolGlyph($r('sys.symbol.pause_fill'))
                  .fontSize(24)
                  .fontColor([ZephyrTheme.onAccent])
              } else {
                SymbolGlyph($r('sys.symbol.play_fill'))
                  .fontSize(24)
                  .fontColor([ZephyrTheme.onAccent])
              }
            }
            .width(72)
            .height(72)
            .borderRadius(36)
            .backgroundColor(ZephyrTheme.accent)
            .justifyContent(FlexAlign.Center)
            .onClick(() => {
              this.player.toggle();
            })
            Blank()
            SymbolGlyph($r('sys.symbol.forward_end_fill'))
              .fontSize(26)
              .fontColor([ZephyrTheme.textPrimary])
              .padding(10)
              .onClick(() => {
                this.player.next();
              })
            Blank()
            SymbolGlyph(this.modeSymbol())
              .fontSize(20)
              .fontColor([ZephyrTheme.textPrimary])
              .padding(10)
              .onClick(() => {
                this.player.cyclePlayMode();
              })
          }
          .width('100%')
          .margin({ top: 16, bottom: 24 })
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 28, right: 28 })
      } else {
        // ===== 歌词模式 =====
        Column() {
          LyricsView({ lyrics: this.activeLyrics(), currentIndex: this.lyricIndex() })
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 28, right: 28, top: 12, bottom: 12 })

        // 歌词模式保留精简控制（上一曲|小圆播放|下一曲，对齐原型歌词页）
        Row() {
          Blank()
          SymbolGlyph($r('sys.symbol.backward_end_fill'))
            .fontSize(22)
            .fontColor([ZephyrTheme.textSecondary])
            .padding(10)
            .onClick(() => {
              this.player.previous();
            })
          Column() {
            if (this.isPlaying) {
              SymbolGlyph($r('sys.symbol.pause_fill'))
                .fontSize(18)
                .fontColor([ZephyrTheme.onAccent])
            } else {
              SymbolGlyph($r('sys.symbol.play_fill'))
                .fontSize(18)
                .fontColor([ZephyrTheme.onAccent])
            }
          }
          .width(48)
          .height(48)
          .borderRadius(24)
          .backgroundColor(ZephyrTheme.accent)
          .justifyContent(FlexAlign.Center)
          .margin({ left: 28, right: 28 })
          .onClick(() => {
            this.player.toggle();
          })
          SymbolGlyph($r('sys.symbol.forward_end_fill'))
            .fontSize(22)
            .fontColor([ZephyrTheme.textSecondary])
            .padding(10)
            .onClick(() => {
              this.player.next();
            })
          Blank()
        }
        .width('100%')
        .padding({ bottom: 24 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ZephyrTheme.bgMist)
  }
}
