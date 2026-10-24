# 小白龙娘 · macOS WebView 改进版 1.14

> 发布准备中：仓库与 Release 保持私有草稿。两份原版动图已按维护者确认记录本项目用途授权；来源、主要贡献和图标制作分别署名，公开时机由维护者确认。

本项目是非官方的 Codex 额度挂件，与 OpenAI 无隶属、赞助或背书关系。

基于 [T7moris/GPT-Niang v1.3.5](https://github.com/T7moris/GPT-Niang/tree/v1.3.5) 的 Mac 定制改进版：查看 Codex 剩余额度、桌面龙娘、低额度形象与可设置的点击彩蛋。

[查看发布草稿](https://github.com/CatGod4456/XiaoBaiLongNiang-Mac/releases) · [更新公告](docs/RELEASE-1.14.md) · [来源与致谢](docs/CREDITS.md) · [上游项目](https://github.com/T7moris/GPT-Niang)

主体应用代码来自 **T7moris/GPT-Niang**，原生 Mac 移植主要来自 **meaqua9420**，角色形象来源为 **ZipZipPipe**，早期跳舞素材引用 **这个刀子真甜**，当前跳舞与拳击采用用户提供的疚刃原版 GIF。本仓库独立创建并保留上游历史，记录的是我在实际 Mac 使用反馈基础上做的细节改进；本次更新使用 **Codex 辅助生成、修改和验证**。

![模拟额度状态：正常、低额度和恢复](docs/images/demo-quota.png)

以上是采用实际 Web 组件渲染的高清模拟图，数字为演示数据。更多 [菜单栏、彩蛋与实机案例](docs/SHOWCASE.md)。


## 相比原版改进了什么

原版已有 macOS 应用、额度查询、窗口跟随、菜单栏入口和点击音效。实际使用时，我希望少打开一次气泡、减少小窗口抢占、让人物贴底更自然，也能自己决定彩蛋开关与播放次数。此次更新围绕这些需求展开。

| 项目 | 本改进版的变化 |
| --- | --- |
| 界面与气泡 | 使用本地 WKWebView 展示，调整气泡轮廓、布局和淡紫配色；保留原生设置与额度后台 |
| 菜单栏额度 | 菜单栏直接显示剩余百分比；收起桌面挂件后仍继续刷新，并使用龙娘图标 |
| 窗口跟随 | 优先选择较大的 Codex 主窗口，减少小型预览窗口抢占；修正人物可见底边的对齐 |
| 人物与图标 | 使用用户提供的普通立绘，保留跨中线整体镜像，换用对应的 macOS 应用图标 |
| 低额度状态 | 任一有效额度窗口低于 5% 时切换低额度形象和台词；有效额度恢复后自动还原 |
| 图片自定义 | 普通形象与低额度形象分别导入、恢复默认，低额度台词可编辑 |
| 普通点击动画 | 触摸板轻点也完整压下、回弹；可调 0.5–3 倍速度，或选择立即到达压缩姿态；偏好在重启后保留 |
| 点击彩蛋 | 坐姿节奏伸缩、原版兔兔跳舞和零额度拳击；平时两种各 2.5%，有效额度为 0 时三种均分总计 5%，不累积 |
| 彩蛋控制 | 总开关、独立开关；各选 1–10 次或持续循环；点击人物可停止 |
| 独立资源加载 | 网页与彩蛋优先读取 App 内部资源；移开构建资源后仍通过完整启动检查，无需保留源码目录 |
| 安装 | Apple Silicon 安装包内置经过官方校验的 Node.js，无需另外安装 Node.js |

透明空白区域可穿透点击；气泡收起后，原生窗口会裁到人物范围。桌面显示、跟随模式与原有音量等设置继续保留。

## 动画与效果展示

![模拟菜单栏：正常、低额度、等待数据](docs/images/demo-menubar.png)

![彩蛋效果与播放设置说明](docs/images/demo-eggs.png)

设置里可以预览三种彩蛋，也可以独立关闭或调整次数。坐姿 stretch 素材为 AI 根据角色参考生成；当前跳舞、拳击直接使用维护者提供的两份兔兔原版 GIF，作者为 [疚刃](https://space.bilibili.com/107716290/)（UID 107716290）。跳舞 70 帧、7 秒，拳击 98 帧、9.8 秒，均保留每帧 100 毫秒的原始节奏，没有重绘或补帧。普通立绘由用户提供并保留原图内容，各类来源分别记录在 [CREDITS](docs/CREDITS.md)。

| 普通轻点 | 坐姿 stretch |
| --- | --- |
| <img src="docs/media/press-character.gif" width="280" alt="完整点按反馈"> | <img src="docs/media/squish-character.gif" width="280" alt="原位伸缩"> |

| 原版兔兔跳舞 | 原版兔兔零额度拳击 |
| --- | --- |
| <img src="docs/media/dance.gif" width="360" alt="70帧原版跳舞"> | <img src="docs/media/zero.gif" width="280" alt="零额度专属"> |

[点按音效视频](docs/media/press-sound.mp4) · [伸缩与跳舞 GIF 演示](docs/SHOWCASE.md#设置里的小彩蛋)。GIF 无声，视频使用程序内置音效；画面由实际组件渲染，额度为演示数字。

![用户提供的实机截图，主窗口私人内容已遮挡](docs/images/real-cases.png)

这组是实机案例，和上面的模拟渲染分开展示；完整原始聊天截图不会随仓库或应用分发。

## 下载与使用

本改进版的发布版本为 **1.14**；应用及后台的三段版本号记为 `1.14.0`。上游源码基线仍为 `v1.3.5`。

当前预编译包适用于 **Apple Silicon（M 系列芯片）、macOS 13.5 或更新版本**。需要已安装并用 ChatGPT 账号登录的 Codex 桌面端。当前发布包不是 Intel 通用包。

1. 从本仓库的 [Releases](https://github.com/CatGod4456/XiaoBaiLongNiang-Mac/releases) 下载 `XiaoBaiLongNiangMac.zip`，解压后把 `XiaoBaiLongNiangMac.app` 放入“应用程序”。
2. 打开应用。可在桌面拖动人物，点击人物查看额度，右键或从菜单栏进入设置。
3. 在“显示与位置”选择桌面模式或跟随 Codex；在“彩蛋”设置启用状态和播放次数。

应用采用本地临时签名，尚未经过 Apple 公证。若 macOS 阻止首次打开，请核对下载来源后，在系统设置的“隐私与安全性”中按系统提示确认。无需关闭系统安全功能。

本改进版不会被上游自动更新覆盖；新版本从本仓库 Releases 获取。当前包使用独立应用标识，并沿用原偏好目录。安装前应退出已运行的挂件；替换同名应用后会继续使用本机已有偏好。

## 彩蛋说明

- **坐姿伸缩**：在原位按节奏改变宽高，以可见脚底为支点。默认 3 次，每次 0.8 秒。
- **跳舞**：用户提供的原版兔兔 GIF，70 帧、7 秒，默认 1 次。保留原画面、原尺寸与速度；来源为疚刃《若不是你突然闯进我生活》。
- **零额度**：仅在当前有效、未过期的额度窗口精确等于 0 时，点击才参与随机触发。使用原版拳击 GIF，98 帧、9.8 秒，默认 1 次，设置内可直接预览；来源为疚刃《我小兔子也绝非善类》。
- 平时伸缩和跳舞各 2.5%；有效额度为 0 时，三种各占 `5% ÷ 3`（约 1.67%），合计最多 5%。每次点击独立抽取，关闭某种不会把概率转给其他种。失败、旧快照、已过重置时间的窗口或四舍五入看起来为 0 的正数，不触发零额度彩蛋。
- 开关和次数在重启后保留；再次点击人物可以停止播放。设置里的预览按钮可直接查看效果。

## 主要贡献与创作者署名

| 贡献者／来源 | 贡献与本改版关系 |
| --- | --- |
| [T7moris / GPT-Niang](https://github.com/T7moris/GPT-Niang) | 主体代码与项目维护；直接基础为 v1.3.5，保留原版权、MIT 许可和 Git 历史 |
| [meaqua9420](https://github.com/meaqua9420) 与 [其他上游贡献者](docs/UPSTREAM-CREDITS.md) | 原生 Mac 移植及额度、安装、更新、兼容、审查与反馈；本改版在此基础上完善 |
| [MeteorNOX / DeepSeek-Balance-Whale-Widget](https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget) | 创意与交互参考、经典气泡和语录，保留对应 MIT 文本 |
| [ZipZipPipe](https://space.bilibili.com/4168597/) · UID 4168597 | 龙娘形象出处；普通立绘、当前坐姿／低额度加工及衍生图标继续保留形象署名 |
| [疚刃](https://space.bilibili.com/107716290/) · UID 107716290 | 当前[兔兔跳舞](https://www.bilibili.com/video/BV16Vap6yEGP/)和[拳击](https://www.bilibili.com/video/BV1SZpR6hEcv/)原版动图；维护者已确认本项目用途授权 |
| [这个刀子真甜](https://space.bilibili.com/23315338/) · UID 23315338 | 此前《[大肥鱼一键跟跳](https://www.bilibili.com/video/BV1ovpE66Es8/)》素材与项目用途同意，贡献和出处保留 |
| [CatGod4456](https://github.com/CatGod4456) / [邱会作](https://space.bilibili.com/319500223/) | 本次需求、反馈、维护与 macOS WebView 交互完善；代码、测试、图标排版和说明使用 Codex 辅助完成 |
| [Node.js](https://nodejs.org/) 及其依赖贡献者 | 包内运行时，保留官方来源、校验和完整许可 |

<img src="docs/images/app-icon.png" width="128" alt="由龙娘普通立绘制作的 macOS 应用图标">

**App 图标也保留素材署名。** 它由维护者提供的普通龙娘立绘制作，角色出处为 ZipZipPipe；CatGod4456 使用 Codex 辅助完成淡紫渐变底板、圆角、阴影、缩放排版及 macOS 多尺寸导出。菜单栏图标由当前普通形象缩放。图标制作贡献与原角色设计分别记录，见 [图标来源](gpt-niang-usage/assets/ICON-SOURCE.txt)。

当前坐姿和低额度图片的生成／加工工具为 ImageGen；当前两份兔兔动图保留原版。音效原样沿用 GPT-Niang。详细加工、原生 Mac 贡献、运行时及音效来源见 [完整致谢](docs/CREDITS.md)。

## 许可与协作

代码和一般文档沿用 [MIT License](LICENSE)，保留上游版权与许可文本。MIT 允许按其条件复用、修改和商业分发代码；本项目当前免费分发，不改变上游已有许可。

角色、图标、音视频和第三方标识按各自来源条件使用，代码 MIT 不统一重新许可这些素材。两份原版动图按免费、非商业用途使用，保留作者与原作品链接，不用于 AI 训练或重绘；作者同意的沟通记录见 [素材来源与授权](docs/ASSET-PERMISSIONS.md)，本项目保留作者、原作品链接和实际同意的使用条件。

T7moris 已同意修改后自建仓库。本仓库独立维护 macOS 衍生改进，保留上游历史，并按原有功能、本次改动、素材与工具处理分别署名。欢迎向本仓库提交 Issue 和 PR；对上游的实际回馈以对应 PR 和合并记录为准。参与方式见 [CONTRIBUTING](CONTRIBUTING.md)。

[关注主播](https://space.bilibili.com/319500223/) 谢谢喵，也请支持上面提供主体代码、创意、形象和动图的作者。

## 从源码构建

源码构建需要 Node.js 20+、完整 Xcode 和 macOS SDK。运行：

```bash
bash Build-Mac.command
```

构建会执行相关测试，生成并临时签名 `dist/XiaoBaiLongNiangMac.app`，并从 Node.js 官方来源下载和校验对应运行时。普通下载用户不需要 Xcode 或自行构建。

手动构建通用包：

```bash
GPT_NIANG_BUILD_CONFIGURATION=release GPT_NIANG_BUILD_UNIVERSAL=1 bash script/build_and_run.sh --build-only
```

仓库保留上游 Windows 代码作为来源的一部分；本次改进与预编译包面向 macOS。Intel、旧系统、多屏和其他应用全屏切换仍需要更多实机验证，通用构建入口不代表这些环境已完成验证。

## 验证与数据

本次 Mac 改进通过 150 项原生测试和 17 项构建入口 Node 测试，另通过真实浏览器短按完整压缩／回弹与立即压下检查。测试覆盖额度状态、透明区域命中、菜单栏、主窗口选择、彩蛋概率与播放控制；已在一台 Apple Silicon Mac 安装运行。新增控件的完整鼠标验收，以及多屏／全屏组合场景尚未全部完成。

额度沿用上游的本地只读查询，不发起模型生成。WebView 加载本地资源，不接收账号凭证或聊天正文。仓库与下载包不包含本机登录配置、额度快照、聊天截图或个人设置。

本次发布前进行了 [源码与发布包安全／隐私检查](docs/SECURITY-REVIEW.md)：修除编译路径信息，排除登录数据、个人设置及原始聊天截图；在检查范围内未发现明确的后门行为。此结果不是独立安全认证。
