import { LyricLine } from './LyricLine';

/**
 * LRC 歌词解析器
 * 支持标准格式 `[mm:ss.xx]歌词`（多时间戳同行、多标签行容错）
 * 解析结果按时间升序，供 LyricsView 按播放进度二分定位当前行
 */
export class LrcParser {
  /** 解析 LRC 文本；无有效时间戳行时返回空数组（调用方回退均匀分布模式） */
  static parse(content: string): LyricLine[] {
    const result: LyricLine[] = [];
    const lines: string[] = content.split(/\r?\n/);
    // [mm:ss.xx] 或 [mm:ss] ；一行可含多个时间戳
    const timeRegex = /\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]/g;

    for (const raw of lines) {
      const text: string = raw.replace(timeRegex, '').trim();
      timeRegex.lastIndex = 0;
      let match: RegExpExecArray | null = timeRegex.exec(raw);
      let hasTime: boolean = false;
      while (match !== null) {
        hasTime = true;
        const min: number = parseInt(match[1], 10);
        const sec: number = parseInt(match[2], 10);
        let fracStr: string = match[3] ?? '0';
        // 2 位按百分秒、3 位按毫秒
        const frac: number = fracStr.length === 1
          ? parseInt(fracStr, 10) * 100
          : fracStr.length === 2
            ? parseInt(fracStr, 10) * 10
            : parseInt(fracStr, 10);
        const timeMs: number = min * 60000 + sec * 1000 + frac;
        if (text.length > 0) {
          const line: LyricLine = { text: text, timeMs: timeMs };
          result.push(line);
        }
        match = timeRegex.exec(raw);
      }
      // 纯文本行（无时间戳）且尚未有任何时间戳行时保留（兜底展示）
      if (!hasTime && text.length > 0 && result.length === 0) {
        const line: LyricLine = { text: text, timeMs: -1 };
        result.push(line);
      }
    }

    if (result.length > 0 && result[0].timeMs >= 0) {
      result.sort((a: LyricLine, b: LyricLine) => a.timeMs - b.timeMs);
      return result;
    }
    return [];
  }

  /** 二分查找当前播放行索引（timeMs <= position 的最后一行）；无时间戳返回 -1 */
  static currentIndex(lines: LyricLine[], positionMs: number): number {
    if (lines.length === 0 || lines[0].timeMs < 0) {
      return -1;
    }
    let lo: number = 0;
    let hi: number = lines.length - 1;
    let ans: number = -1;
    while (lo <= hi) {
      const mid: number = (lo + hi) >> 1;
      if (lines[mid].timeMs <= positionMs) {
        ans = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }
    return ans;
  }
}
