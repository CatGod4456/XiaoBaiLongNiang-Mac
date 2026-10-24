# 主要贡献、来源与致谢

本仓库由 CatGod4456 独立维护，是基于 [T7moris/GPT-Niang v1.3.5](https://github.com/T7moris/GPT-Niang/tree/v1.3.5) 的 macOS WebView 衍生改进版。主体应用、原生 Mac 基础和素材创作分别归功于下列作者；本次贡献集中在实际使用后的交互完善、界面适配、测试与打包。

## 主要贡献一览

| 贡献者或来源 | 具体贡献 | 本改版的使用或加工 |
| --- | --- | --- |
| [T7moris / GPT-Niang](https://github.com/T7moris/GPT-Niang) | 项目创作、维护、额度查询后台与整体应用基础 | 直接源码基础为 v1.3.5，提交 `b6f5eb8972d1802821006b7208d20a834fa6a08b`；保留 Git 历史、版权和 MIT 文本 |
| [meaqua9420](https://github.com/meaqua9420) | [上游 PR #3](https://github.com/T7moris/GPT-Niang/pull/3) 的 SwiftUI / AppKit 原生 Mac 移植，包括窗口跟随、菜单栏、设置、音效移植及构建基础 | 本次 WebView 改进建立在该原生移植之上；其他整合与修复见 [完整上游记录](UPSTREAM-CREDITS.md) |
| [GPT-Niang 的其他贡献者](UPSTREAM-CREDITS.md) | 额度兼容、刷新与生命周期、安装更新、DPI、图库、审查、复现及建议 | 完整保留上游对贡献内容和合并状态的区分，不把上游既有功能列成本改版首次实现 |
| [MeteorNOX / DeepSeek-Balance-Whale-Widget](https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget) | 创意与交互参考、经典气泡几何、上游沿用的语录 | 气泡参考提交 `5247dd6813d6e4430728f39ccc63d43cda046022`；分别保留参考代码与语录 MIT 许可 |
| [ZipZipPipe](https://space.bilibili.com/4168597/) · UID 4168597 | 维护者提供的龙娘形象出处 | 普通立绘由维护者提供并原样保留；坐姿、低额度加工和衍生图标继续标注形象来源 |
| [疚刃](https://space.bilibili.com/107716290/) · UID 107716290 | 当前兔兔跳舞与拳击原版动画 | 原画面、尺寸、透明度和延时保留；App 只移除自带无限循环标记，由设置控制次数 |
| [这个刀子真甜](https://space.bilibili.com/23315338/) · UID 23315338 | 《[大肥鱼一键跟跳](https://www.bilibili.com/video/BV1ovpE66Es8/)》视频素材及对应项目用途同意 | 该素材用于此前版本；当前已替换，仍保留作者贡献与原视频出处 |
| [CatGod4456](https://github.com/CatGod4456) / [邱会作](https://space.bilibili.com/319500223/) | 本次需求、使用反馈、选择与验证、维护和发布整理 | 菜单栏额度、主窗口优先、人物贴底、普通短按完整反馈、彩蛋开关与次数、本地 WebView、文档与分发完善 |
| CatGod4456 使用 Codex 辅助制作 | App 图标排版、菜单栏图标适配及本改版代码与测试 | 图标角色来自上述普通立绘；渐变圆角底板、阴影、缩放和多尺寸导出由程序生成，不将角色设计归为本改版原创 |
| ImageGen 工具 | 当前坐姿 stretch 图片、低额度图片的生成或加工 | 根据维护者提供的角色参考处理；角色设计归属不因工具加工而改变，stretch 运动由程序实现 |
| [Node.js 项目及其依赖贡献者](https://nodejs.org/) | 安装包内置 Node.js 运行时 | 构建时从官方分发站获取并核对 SHA-256；完整 Node 及所含第三方许可随包保留 |

## App 图标与菜单栏图标

App 图标由 `gpt-niang-usage/assets/gpt-dragon-niang-bust.png` 制作，该 PNG 是维护者提供的普通立绘，内容未改动。形象出处按维护者提供的信息署名 ZipZipPipe。图标排版由 CatGod4456 使用 Codex 辅助完成，制作脚本为 `script/create-app-icon.swift`：程序绘制淡紫渐变圆角底板、阴影和边线，将角色缩放排版，再导出 macOS 所需的多尺寸图像和 `AppIcon.icns`。

菜单栏图标从当前普通形象缩放为 20 × 20；用户导入普通形象后，菜单栏图标随之更新。缩放适配同样不改变角色设计归属。详情见 [图标来源记录](../gpt-niang-usage/assets/ICON-SOURCE.txt)。

## 当前动图与授权

| 用途 | 原作品与作者 | 当前资源 |
| --- | --- | --- |
| 跳舞彩蛋 | [疚刃《若不是你突然闯进我生活》](https://www.bilibili.com/video/BV16Vap6yEGP/) | 70 帧、7 秒，950 × 950，每帧 100 ms |
| 零额度拳击 | [疚刃《我小兔子也绝非善类》](https://www.bilibili.com/video/BV1SZpR6hEcv/) | 98 帧、9.8 秒，500 × 406，每帧 100 ms |

维护者于 **2026-10-24 确认两份原版动图已获本项目用途授权**。本项目保留作者与原作品链接，并遵循作者实际同意的使用条件。拳击来源页另注明“动作来自：抖音渝欢”，此处保留该动作来源说明。授权记录见 [ASSET-PERMISSIONS](ASSET-PERMISSIONS.md)。

展示 GIF 与维护者提供的文件逐字节一致；App 副本只去掉无限循环扩展，所有帧图像与延时不变。没有对这两份原版动图进行重绘、插帧、裁切或重新抠图。

## 音效与运行时

`press.wav`、`release.wav` 原样沿用 GPT-Niang v1.3.5，对比上述基线字节一致；按下、松开音效及其原生移植贡献继续归于上游。未据此宣称本改版创作了音源，也未新增对音源的单独转授权声明；适用条件依上游及原音源权利方的实际许可。

App 包内保留 `LICENSE`、`Whale-Widget-LICENSE.txt`、`quotes-LICENSE.txt`、`Node-LICENSE.txt`、`Node-SOURCE.txt` 及本来源记录。Node 许可证同时包含其分发包列明的第三方声明；系统框架由 macOS 提供。

## 代码许可与社区协作

代码和一般文档沿用上游 [MIT License](../LICENSE)，保留 T7moris 与 GPT-Niang contributors 的原版权行。MIT 允许在其条件下复用、修改及商业分发代码；本项目当前免费分发，不将这种分发选择改写成对上游 MIT 代码的额外限制。角色、图标、音视频与第三方标识按各自来源条件处理，代码许可不统一重新许可这些素材。

本仓库独立维护衍生版本，尊重上游作者和其他贡献者，完整保留来源与历史。原有功能、此处新增改动和素材创作分别署名；工具协助生成、测试和整理的工作也单独说明。对上游的实际代码回馈，以对应 PR 与合并记录为准。欢迎在本仓库提交可复现问题和 PR，见 [参与贡献](../CONTRIBUTING.md)。

本项目为非官方 Codex 额度工具，与 OpenAI 无隶属、赞助或背书关系。作品来源说明、维护者贡献和第三方品牌权利分别处理，不代表任何第三方为本改版提供背书。

[关注主播](https://space.bilibili.com/319500223/) 谢谢喵

感谢提供主体代码、原生 Mac 基础、创意、形象、动图以及反馈的所有创作者与贡献者。
