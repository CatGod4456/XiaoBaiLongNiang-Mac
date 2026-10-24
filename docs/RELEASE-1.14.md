> 私有发布草稿，尚未公开。两份原版动图已按维护者确认记录本项目用途授权；代码、原生 Mac 移植、角色、App 图标和本次改进分别署名。

# 小白龙娘 1.14 · macOS WebView 改进版

本项目是非官方的 Codex 额度挂件，与 OpenAI 无隶属、赞助或背书关系。

基于 [T7moris/GPT-Niang v1.3.5](https://github.com/T7moris/GPT-Niang/tree/v1.3.5) 的 Mac 定制改进。原版已有额度查询、窗口跟随、菜单栏入口和点击音效；本版根据实际使用反馈，完善菜单栏读数、贴底、主窗口选择与点击反馈，再补上可控制播放次数的小彩蛋。

主体源码和角色设计来自原作者。本次需求与使用反馈由 CatGod4456 整理，更新使用 Codex 辅助生成、修改和验证。

## 这次更新了什么

- 菜单栏直接显示剩余额度，换用龙娘图标；收起桌面挂件后继续刷新。
- 优先跟随较大的 Codex 主窗口，减少小窗口抢占，修正人物可见底边对齐；保留跨中线整体镜像。
- 本地 WebView 展示气泡和人物，继续使用原生设置与额度后台。普通、低额度形象可分别导入；低额度台词可编辑。
- 触摸板轻点也完整播完压下和回弹，支持 0.5–3 倍速度，或立即到达压缩姿态。
- 跳舞彩蛋换为用户提供的兔兔原版 GIF：70 帧、7 秒，保留原角色、画面和速度，不再重绘或补帧。
- 零额度拳击换为兔兔原版 GIF：98 帧、9.8 秒，保留原画面和速度。只有新鲜、有效、未过期的额度窗口精确等于 0 时，点击才参与随机触发。
- 三种彩蛋分别可开关、预览，选择 1–10 次或持续循环；再次点击人物可以停止，偏好在重启后保留。
- 内置经过官方校验的 Node.js；网页和动图读取 App 内部资源，独立安装无需保留源码目录。

## 动作与概率

![三种彩蛋与设置说明](images/demo-eggs.png)

| 额度状态 | 原位 stretch | 原版兔兔跳舞 | 零额度彩蛋 | 合计 |
| --- | --- | --- | --- | --- |
| 没有有效零额度窗口 | 2.5% | 2.5% | 不触发 | 最多 5% |
| 存在有效零额度窗口 | 5% ÷ 3 | 5% ÷ 3 | 5% ÷ 3 | 最多 5% |

每次点击独立抽取，不累计。关闭某种或素材不可用时，不把它的概率转给其他种。旧快照、查询失败、已过重置时间的窗口，以及显示时四舍五入为 0 的正数，都不算有效零额度。

| 普通轻点 | 原位 stretch |
| --- | --- |
| <img src="media/press-character.gif" width="280" alt="完整压下与回弹"> | <img src="media/squish-character.gif" width="280" alt="原位节奏伸缩"> |

<small>伸缩示例：弹跳高松灯.gif</small>

| 新跳舞，替换原版本 | 原版兔兔拳击，零额度专属 |
| --- | --- |
| <img src="media/dance.gif" width="360" alt="70帧原版兔兔跳舞"> | <img src="media/zero.gif" width="280" alt="零额度彩蛋"> |

<small>跳舞示例：兔兔.gif</small>

默认伸缩 3 次（每次 0.8 秒），跳舞 1 次（7 秒），零额度彩蛋 1 次（9.8 秒）。上面的展示 GIF 会重复播放；应用资源自身不无限循环，由设置决定播放次数。

两份原 GIF 均为每帧 100 毫秒（10 fps）。只去掉应用副本的无限循环标记，其余编码帧和延时保留，播放次数由设置控制。详见 [动画制作说明](media/MOTION-PROCESS.md)。

[播放带内置点按音效的演示](media/press-sound.mp4)。GIF 没有声音，视频使用程序原有的按下、松开音效。

## 额度与使用案例

![正常、低额度与恢复状态](images/demo-quota.png)

![菜单栏额度排版](images/demo-menubar.png)

以上采用模拟数字和本地组件渲染，菜单栏图为放大的排版示意。下面是用户提供的实机案例，聊天、任务列表和账号区域已遮挡。

![经过隐私遮挡的实机案例](images/real-cases.png)

## 下载与安装

本页的 `XiaoBaiLongNiangMac.zip` 是预编译应用，适用于 **Apple Silicon（M 系列芯片）、macOS 13.5+**。需要已安装并用 ChatGPT 账号登录 Codex 桌面端。解压后把 `XiaoBaiLongNiangMac.app` 放入“应用程序”，退出旧版后打开；原有偏好继续保留。

发布版本为 **1.14**，应用和后台三段版本号为 `1.14.0`。本包内置 Node.js，下载用户不需要自行安装 Node.js 或 Xcode；GitHub 自动附带的 Source code 是源码。可以用 `SHA256SUMS.txt` 核对安装包。

当前包采用本地临时签名，尚未经过 Apple 公证。首次打开若被系统阻止，请核对下载来源后，按 macOS“隐私与安全性”的提示确认；无需关闭系统安全功能。当前为 Apple Silicon 包，Intel、旧系统及多屏／全屏组合仍需更多实机验证。

## 主要贡献与创作者署名

| 贡献者／来源 | 贡献与本改版关系 |
| --- | --- |
| [T7moris / GPT-Niang](https://github.com/T7moris/GPT-Niang) | 主体代码与项目维护；直接基础为 v1.3.5，保留原版权、MIT 许可和 Git 历史 |
| [meaqua9420](https://github.com/meaqua9420) 与 [其他上游贡献者](UPSTREAM-CREDITS.md) | 原生 Mac 移植及额度、安装、更新、兼容、审查与反馈；本改版在此基础上完善 |
| [MeteorNOX / DeepSeek-Balance-Whale-Widget](https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget) | 创意与交互参考、经典气泡和语录，保留对应 MIT 文本 |
| [ZipZipPipe](https://space.bilibili.com/4168597/) · UID 4168597 | 龙娘形象出处；普通立绘、当前坐姿／低额度加工及衍生图标继续保留形象署名 |
| [疚刃](https://space.bilibili.com/107716290/) · UID 107716290 | 当前[兔兔跳舞](https://www.bilibili.com/video/BV16Vap6yEGP/)和[拳击](https://www.bilibili.com/video/BV1SZpR6hEcv/)原版动图；维护者已确认本项目用途授权 |
| [这个刀子真甜](https://space.bilibili.com/23315338/) · UID 23315338 | 此前《[大肥鱼一键跟跳](https://www.bilibili.com/video/BV1ovpE66Es8/)》素材与项目用途同意，贡献和出处保留 |
| [CatGod4456](https://github.com/CatGod4456) / [邱会作](https://space.bilibili.com/319500223/) | 本次需求、反馈、维护与 macOS WebView 交互完善；代码、测试、图标排版和说明使用 Codex 辅助完成 |
| [Node.js](https://nodejs.org/) 及其依赖贡献者 | 包内运行时，保留官方来源、校验和完整许可 |

<img src="images/app-icon.png" width="128" alt="由龙娘普通立绘制作的 macOS 应用图标">

**App 图标也保留素材署名。** 它由维护者提供的普通龙娘立绘制作，角色出处为 ZipZipPipe；CatGod4456 使用 Codex 辅助完成淡紫渐变底板、圆角、阴影、缩放排版及 macOS 多尺寸导出。菜单栏图标由当前普通形象缩放。图标制作贡献与原角色设计分别记录，见 [图标来源](../gpt-niang-usage/assets/ICON-SOURCE.txt)。

当前坐姿和低额度图片的生成／加工工具为 ImageGen；当前两份兔兔动图保留原版。音效原样沿用 GPT-Niang。详细加工、原生 Mac 贡献、运行时及音效来源见 [完整致谢](CREDITS.md)。

## 许可与协作

代码和一般文档沿用 [MIT License](../LICENSE)，保留上游版权与许可文本。MIT 允许按其条件复用、修改和商业分发代码；本项目当前免费分发，不改变上游已有许可。

角色、图标、音视频和第三方标识按各自来源条件使用，代码 MIT 不统一重新许可这些素材。两份原版动图按免费、非商业用途使用，保留作者与原作品链接，不用于 AI 训练或重绘；作者同意的沟通记录见 [素材来源与授权](ASSET-PERMISSIONS.md)，本项目保留作者、原作品链接和实际同意的使用条件。

T7moris 已同意修改后自建仓库。本仓库独立维护 macOS 衍生改进，保留上游历史，并按原有功能、本次改动、素材与工具处理分别署名。欢迎向本仓库提交 Issue 和 PR；对上游的实际回馈以对应 PR 和合并记录为准。参与方式见 [CONTRIBUTING](../CONTRIBUTING.md)。

[关注主播](https://space.bilibili.com/319500223/) 谢谢喵，也请支持上面提供主体代码、创意、形象和动图的作者。

## 验证范围

通过 150 项原生测试；完整 Node 脚本测试共 156 项，149 项通过、7 项因平台条件跳过、0 项失败，覆盖零额度有效性、5% 固定抽取区间、开关和次数保存、GIF 解码与周期、普通短按反馈等。应用、后台和动图均为本地资源；额度通过本机 Codex 进行只读查询，不发起模型生成。Codex 客户端会联网取得额度，不能将整个运行链路描述为只访问 GitHub。本定制包关闭更新下载，来源链接由用户点击后在外部浏览器打开。

已检查发布包结构、签名、个人路径与常见凭证模式；具体边界见 [安全与隐私检查](SECURITY-REVIEW.md)。完整新增控件的鼠标操作、多屏与全屏组合尚未全部验收，检查结果不等同独立安全认证。
