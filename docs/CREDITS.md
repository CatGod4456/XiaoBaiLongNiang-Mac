# 来源与致谢

## 源代码

直接基础为 [T7moris/GPT-Niang](https://github.com/T7moris/GPT-Niang)，版本 v1.3.5，提交 `b6f5eb8972d1802821006b7208d20a834fa6a08b`。保留上游 MIT 版权和 Git 历史。本仓库是在这一代码基础上的 macOS WebView 定制改进。

上游原生 Mac 移植主要由 [meaqua9420](https://github.com/meaqua9420) 通过 PR #3 贡献；维护、整合、额度后台及其他贡献者见 [完整上游记录](UPSTREAM-CREDITS.md)。

## 创意与参考代码

感谢 [MeteorNOX/DeepSeek-Balance-Whale-Widget](https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget) 的创意与交互参考。上游 GPT-Niang 已保留其 7 句语录及 MIT 许可。本改版还参考并采用了该项目的经典气泡几何路径，参考提交 `5247dd6813d6e4430728f39ccc63d43cda046022`，在本地 WebView 中适配。

许可文本分别见 `gpt-niang-usage/assets/quotes-LICENSE.txt` 和 `references/whale-widget-LICENSE.txt`。本仓库的直接应用代码基础为 GPT-Niang；创意参考项目和直接源码基础分别列明。

## 角色形象

形象出处由用户提供：[ZipZipPipe](https://space.bilibili.com/4168597/)，Bilibili UID 4168597。此处按形象来源署名，不对未核实的角色最初创作关系或授权范围作扩大声明。

普通立绘为用户提供的 PNG，保留原图内容；来源和哈希见 `gpt-niang-usage/assets/USER-CHARACTER-SOURCE.txt`。应用图标由该图缩放、布局制作。

坐姿彩蛋由 ImageGen 根据同一龙娘参考和坐姿姿态参考制作，保留龙角、银紫长发、紫眼、发饰与服装设计；运行时节奏伸缩由程序实现。低额度形象的处理来源见 `gpt-niang-usage/assets/low-quota-SOURCE.txt`。这些处理不构成对原角色设计的原创声明。

用户提供的 ZipZipPipe 主页截图另有“鲸鱼娘”形象许可说明；本项目不把该特定说明推定为 GPT 龙娘或其他视频素材的统一授权。

## 早期跳舞视频素材（本次已替换）

- 视频作者：[这个刀子真甜](https://space.bilibili.com/23315338/)，Bilibili UID 23315338。
- 视频标题：[大肥鱼一键跟跳](https://www.bilibili.com/video/BV1ovpE66Es8/)。
- 片段：09.0–13.55 秒的中央白色角色，保留原动作，处理为透明 GIF，无音频。
- 结果：91 帧、20 fps、4.55 秒，一个动作周期；程序按用户选择的次数重播。
- 加工：前景分离、背景及邻近角色移除、透明边缘和封闭肤色区域修补。

视频作者已于 2026-10-23 同意将所述跳舞片段处理为透明动图，用于本项目彩蛋，并随源码与安装包发布；保留作者署名和原视频链接。具体范围见 [素材许可记录](ASSET-PERMISSIONS.md)。视频和角色权利仍归相应创作者，代码 MIT 不扩大素材许可。

## 当前跳舞与零额度彩蛋

当前 `egg-dance.gif` 按维护者提供的蓝发角色 GIF（140 帧、7 秒）的动作顺序制作；形象以维护者提供的白发龙娘参考为准，保留长裙、龙角、发饰与龙尾。在原 ImageGen 关键帧之外补绘 24 张过渡姿势，修正背面姿势，按约 24 fps 时间轴逐格保持姿势，输出 168 帧、7 秒（约 24 fps）透明 GIF。补绘源图见 `docs/media/dance-inbetweens.png`。动作参考图的原作者与公开许可尚待维护者确认；它不是上述 Bilibili 片段的再次截取，也不套用该片段的项目用途许可。

`egg-zero.gif` 现按维护者另行提供的兔耳角色拳击 GIF 作为动作参考，重绘为同一白发龙娘。在原 25 张 ImageGen 关键帧之外补绘 24 张过渡姿势，保留长裙、双角、发饰与龙尾，再按原参考节奏逐格保持姿势，合成 235 帧、9.8 秒（约 24 fps）透明 GIF；并非原附件的逐帧无损换装。源关键帧保存在 `docs/media/zero-keyframes.png`，补绘源图为 `docs/media/zero-inbetweens.png`。两段均属于 AI 重绘与逐格保持，不宣称每帧独立手绘。应用版本不带无限循环标记，由设置控制次数。原动作参考作者与公开许可仍待确认。

代码 MIT 不适用于这些角色、动图及参考素材。当前仅保留私有草稿，完整范围见 [素材许可记录](ASSET-PERMISSIONS.md)。

## 本次定制

CatGod4456 提供需求、形象出处、使用反馈并发布此定制改进；代码修改、构建和测试使用 Codex 辅助完成。新增功能以仓库首页的对比表为准。感谢原项目维护者、贡献者以及形象与视频创作者。

## 关注与感谢

[关注主播](https://space.bilibili.com/319500223/) 谢谢喵

感谢提供源码、早期跳舞素材与角色形象的三位 UP 主：

| UP 主 | B 站 UID | 本项目引用来源 |
| --- | --- | --- |
| [T7moris](https://space.bilibili.com/642488914/) | 642488914 | GPT-Niang 源码作者 |
| [这个刀子真甜](https://space.bilibili.com/23315338/) | 23315338 | 《大肥鱼一键跟跳》跳舞素材 |
| [ZipZipPipe](https://space.bilibili.com/4168597/) | 4168597 | 角色形象来源 |

感谢原作者与开源贡献者。

<!-- candidate-animation-sources-20261024 -->
## 待授权原动图来源

以下两个来源链接由维护者于 2026-10-24 提供：

- [来源视频一](https://www.bilibili.com/video/BV1SZpR6hEcv/)
- [来源视频二](https://www.bilibili.com/video/BV16Vap6yEGP/)

维护者正在自行向创作者询问授权，具体答复、署名要求和允许范围待补充。当前记录出处，不标记为已获授权；跳舞、拳击相关制作及发布暂停，现阶段保留弹簧彩蛋。这些是后续原动图使用方案的候选来源，不据此改变此前 AI 改绘试稿的制作记录。
<!-- /candidate-animation-sources-20261024 -->
