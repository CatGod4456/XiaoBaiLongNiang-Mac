# 动画展示素材

- `press-character.gif`：仅人物、透明背景的普通轻点，完整压下和回弹。
- `squish-character.gif`：仅人物、透明背景的原位伸缩，三次后停留再展示。
- `press-sound.mp4`：实际组件的三次点按，混入应用内置按下和松开音效，72% / 89% 为演示数据。
- `dance.gif`：当前白发跳舞的循环预览，140 帧、7 秒。
- `zero.gif`：按用户拳击 GIF 动作参考重绘的白发龙娘循环预览，98 帧、9.8 秒。
- `dance-keyframes.png`：ImageGen 重绘的 28 张舞蹈关键帧，保留为生成来源。形象参考只用于长裙、龙角、发饰和尾巴；动作以用户提供的 140 帧 GIF 为准，再按原时间和整体姿态变化补间。

- `zero-keyframes-prompt.txt`：本次 ImageGen 关键帧生成的完整提示词，不含账号或本机路径。
- `zero-keyframes.png`：ImageGen 重绘的 25 张白发龙娘拳击关键帧，保留长裙、双角、发饰和龙尾；按用户原拳击 GIF 的时间与整体姿态变化补间。

说明页的 GIF 循环用于展示。App 内对应 GIF 不带无限循环标记，由设置决定次数；两者不要混用。GIF 不含声音。

角色形象来源 ZipZipPipe，普通立绘由用户提供，坐姿、跳舞与拳击关键帧通过 ImageGen 根据角色参考制作；音效沿用上游 GPT-Niang。新动作参考及零额度动图的原作者与公开许可待确认。生成和展示不改变原素材权利，见 [CREDITS](../CREDITS.md) 及 [素材许可记录](../ASSET-PERMISSIONS.md)。
