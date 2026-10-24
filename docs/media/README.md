# 动画展示素材

- `press.gif`：实际 Web 组件的普通轻点动画；同一帧按下／松开，完整压下与回弹。GIF 无声。
- `squish.gif`：实际 Web 组件的坐姿伸缩，默认三次，每次 0.8 秒；末尾停留后重新展示。
- `press-sound.mp4`：三次普通轻点，混入应用内置 `press.wav`、`release.wav`，按原生音效的先后时序播放。

画面为本地组件渲染，使用模拟额度 72% / 89%，不代表实际账号数据。角色形象来源 ZipZipPipe，普通立绘由用户提供，坐姿图通过 ImageGen 根据角色参考制作；音效沿用上游 GPT-Niang。生成展示不改变原素材权利，见 [CREDITS](../CREDITS.md) 及 [素材声明](../../gpt-niang-usage/assets/CHARACTER-NOTICE.txt)。

- `press-character.gif`、`squish-character.gif`：仅人物、透明背景的点按与伸缩导出，不含外层 UI。
- `dance-keyframes.png`：当前新跳舞的 28 张 ImageGen 关键帧；只作生成来源保留，不代表 140 张逐帧手绘。最终 GIF 位于 App 的 WebWidget 资源目录，140 帧、7 秒，按用户参考 GIF 的时间顺序与整体姿态变化补间。

- `dance.gif`、`zero.gif`：用于说明页的循环预览。App 内对应资源不带无限循环标记，按设置次数播放；两者不要混用。
