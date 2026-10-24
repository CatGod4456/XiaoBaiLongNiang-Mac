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

当前跳舞和零额度拳击直接采用维护者提供的两份兔耳角色原版 GIF，作者 [疚刃](https://space.bilibili.com/107716290/)（UID 107716290）。跳舞来源为 [《若不是你突然闯进我生活》](https://www.bilibili.com/video/BV16Vap6yEGP/)，70 帧、7 秒；拳击来源为 [《我小兔子也绝非善类》](https://www.bilibili.com/video/BV1SZpR6hEcv/)，98 帧、9.8 秒。拳击来源页另注明“动作来自：抖音渝欢”，此处保留这一上游动作说明。

展示 GIF 与维护者提供的文件一致。App 副本只移除无限循环扩展，帧图像、透明度、延时与原始尺寸均不变。默认各播放一次，可在设置修改次数；未对这两份原动画进行 AI 重绘、插帧或抠图。原位 stretch 坐姿素材与程序伸缩保持不变。

此前基于 140 帧蓝发角色动作参考的白发龙娘 AI 重绘跳舞，以及白发拳击试稿，均已从当前播放资源和展示 GIF 替换；其历史关键图、补绘图与提示词继续作为未选用方案保留，不代表当前动图的制作方式。

当前素材只加入本机与私有测试包，公开分发授权由维护者询问中。角色和动画权利归相应权利人，代码 MIT 不适用于它们。完整范围见 [素材许可记录](ASSET-PERMISSIONS.md)。

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
## 当前原版动图与授权进度

两份原版 GIF 由维护者于 2026-10-24 提供；视频来源核对为 [疚刃](https://space.bilibili.com/107716290/)，B 站 UID **107716290**：

- 跳舞：[《若不是你突然闯进我生活》](https://www.bilibili.com/video/BV16Vap6yEGP/)，70 帧、7 秒，950 × 950。
- 零额度拳击：[《我小兔子也绝非善类》](https://www.bilibili.com/video/BV1SZpR6hEcv/)，98 帧、9.8 秒，500 × 406。

两份均保留原角色、原动作、每帧 100 毫秒的原始节奏。展示 GIF 原样保留；应用副本只去掉无限循环标记，播放次数由用户设置。没有 AI 重绘、补帧、裁切、缩放或重新抠图。

维护者已明确要求加入并启用本机挂件与私有测试包。创作者对公开分发的具体答复、署名要求和允许范围仍由维护者自行询问，尚未记录为已获授权；仓库保持私有，Release 保持草稿。早期素材的许可不套用到这两份作品，代码 MIT 也不覆盖角色和动图。
<!-- /candidate-animation-sources-20261024 -->
