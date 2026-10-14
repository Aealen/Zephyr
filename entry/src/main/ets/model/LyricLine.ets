/** 歌词行（MVP：无时间戳的整段展示型歌词；LRC 解析器后续接入） */
export interface LyricLine {
  text: string;
  /** 开始时间（毫秒），-1 表示无时间戳（均匀分布展示） */
  timeMs: number;
}

/**
 * 内置示例歌词（雾航）。真实歌曲的 LRC 解析器接入后，由 LyricRepository 提供。
 */
export function sampleLyrics(): LyricLine[] {
  const lines: string[] = [
    '曾在雾里看不清',
    '潮声淹没姓名',
    '灯塔明明灭灭',
    '而我在雾中航行',
    '风把帆吹满',
    '就不再回头看',
    '雾散的时候',
    ' Already 海面辽阔'
  ];
  const result: LyricLine[] = [];
  for (let i = 0; i < lines.length; i++) {
    const line: LyricLine = { text: lines[i], timeMs: -1 };
    result.push(line);
  }
  return result;
}
