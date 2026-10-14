/**
 * Zephyr 设计变量（与 pen.dev 原型 14 token 一一对应）
 * 主题策略：mist（莫兰迪雾感）为默认档；light / dark 由封面取色自动分档（后续接入）
 */
export class ZephyrTheme {
  /** 背景基底 */
  static readonly bgMist: string = '#F1F2EE';
  /** 文字·主（歌名/标题） */
  static readonly textPrimary: string = '#2C2F2A';
  /** 文字·次（歌手/副题） */
  static readonly textSecondary: string = '#777B74';
  /** 文字·远（未匹配/占位） */
  static readonly textDistant: string = '#A9ADA5';
  /** 强调（播放按钮/已播进度） */
  static readonly accent: string = '#2A2D28';
  /** 强调色上的内容（暂停图标等） */
  static readonly onAccent: string = '#F4F5EF';
  /** 进度轨道 */
  static readonly trackBase: string = '#C5C9C1';
  /** 分隔线 */
  static readonly divider: string = '#B9BDB5';
  /** 玻璃面（迷你播放条/卡片） */
  static readonly surfaceGlass: string = '#A6FFFFFF';
  /** 封面占位色（mist 三色） */
  static readonly coverGreen: string = '#C9D5C6';
  static readonly coverBlue: string = '#C6CFD9';
  static readonly coverWarm: string = '#D9D0CC';

  /** 页面左右边距（vp） */
  static readonly pagePadding: number = 28;
  /** 圆角（vp） */
  static readonly radiusSm: number = 12;
  static readonly radiusMd: number = 16;
  static readonly radiusLg: number = 24;
}
