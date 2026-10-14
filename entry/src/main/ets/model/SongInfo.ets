/** 歌曲信息（本地曲库最小模型） */
export interface SongInfo {
  id: string;
  title: string;
  artist: string;
  album: string;
  /** 时长（毫秒） */
  durationMs: number;
  /** 音频格式：FLAC / MP3 / WAV / AAC ... */
  format: string;
}

/** 歌单信息 */
export interface PlaylistInfo {
  id: string;
  name: string;
  songCount: number;
  /** 展示用时长，如 "1h 48m" */
  durationLabel: string;
}

/** 毫秒时长格式化为 m:ss */
export function formatDuration(ms: number): string {
  const totalSec: number = Math.floor(ms / 1000);
  const min: number = Math.floor(totalSec / 60);
  const sec: number = totalSec % 60;
  const secStr: string = sec < 10 ? `0${sec.toString()}` : sec.toString();
  return `${min.toString()}:${secStr}`;
}
