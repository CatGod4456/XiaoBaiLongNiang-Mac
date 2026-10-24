import SwiftUI
import ServiceManagement
import GPTNiangCore

struct SettingsView: View {
    @ObservedObject var model: WidgetModel
    @ObservedObject var updater: NativeUpdater
    @State private var loginError: String?

    var body: some View {
        ScrollView { VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .firstTextBaseline) {
                Text(model.text("小白龙娘")).font(.system(size: 27, weight: .semibold, design: .rounded))
                Text("macOS · \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")").font(.caption).foregroundStyle(.secondary)
                Spacer()
            }
            Text(model.text("讓小龍娘陪你掌握 Codex 額度。")).foregroundStyle(.secondary)
            section1
            section2
            section3
            GroupBox("点击动画") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("动画速度")
                        Slider(value: $model.pressAnimationSpeed, in: 0.5...3, step: 0.25)
                        Text(String(format: "%.2g×", model.pressAnimationSpeed)).frame(width: 42)
                    }
                    Toggle("按下时立即到达压缩姿态", isOn: $model.pressImmediate)
                    Text("触摸板轻点也会播完压下、回弹。开启此项后立即压下，松开仍会回弹；不改变彩蛋概率。")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }.padding(10)
            }
            characterSection
            GroupBox("彩蛋") {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("开启随机彩蛋", isOn: $model.easterEggsEnabled)
                    HStack {
                        Toggle("节奏伸缩", isOn: $model.squishEnabled)
                        loopPicker($model.squishLoops)
                        Button("预览") { model.playEasterEgg(.squish) }
                            .disabled(!model.squishEnabled)
                    }.disabled(!model.easterEggsEnabled)
                    HStack {
                        Toggle("兔兔跳舞（原版）", isOn: $model.danceEnabled)
                        loopPicker($model.danceLoops)
                        Button("预览") { model.playEasterEgg(.dance) }
                            .disabled(!model.danceEnabled || !FileManager.default.fileExists(atPath: model.easterEggURL(.dance).path))
                    }.disabled(!model.easterEggsEnabled)
                    HStack {
                        Toggle("零额度拳击（原版）", isOn: $model.zeroEnabled)
                        loopPicker($model.zeroLoops)
                        Button("预览") { model.playEasterEgg(.zero) }
                            .disabled(!model.zeroEnabled || !FileManager.default.fileExists(atPath: model.easterEggURL(.zero).path))
                    }.disabled(!model.easterEggsEnabled)
                    Text("平时前两种各 2.5%；有效额度为 0 时，三种各约 1.67%，合计最多 5%。每次独立抽取、不累积，关闭一种不转移概率。零额度彩蛋的预览不受额度限制；再次点击人物可停止。")
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    HStack {
                        Link("动图作者：疚刃", destination: URL(string: "https://space.bilibili.com/107716290/")!)
                        Spacer()
                        Link("跳舞来源", destination: URL(string: "https://www.bilibili.com/video/BV16Vap6yEGP/")!)
                        Link("拳击来源", destination: URL(string: "https://www.bilibili.com/video/BV1SZpR6hEcv/")!)
                    }.font(.caption)
                }.padding(10)
            }
            section4
            section5
            if let error = model.settingsError { Text(error).font(.caption).foregroundStyle(.orange) }
            HStack {
                Button(model.text("開啟資料目錄")) { NSWorkspace.shared.open(model.dataDirectory) }
                Spacer()
                Button(model.text("重設位置")) { model.resetPosition() }
                Button(model.text("刷新額度")) { model.refresh() }
            }
            Text(model.text("額度可見時每 60 秒更新。使用目前 Codex 登入，不建立聊天或呼叫模型。"))
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(24) }.frame(width: 500, height: 700)
        .onChange(of: model.language) { _ in model.savePreferences() }
        .onChange(of: model.desktopTopmost) { _ in model.savePreferences() }
        .onChange(of: model.soundOn) { _ in model.audio.updateVolume(); model.savePreferences() }
        .onChange(of: model.pressAnimationSpeed) { _ in model.savePreferences() }
        .onChange(of: model.pressImmediate) { _ in model.savePreferences() }
        .onChange(of: model.hideMenu) { _ in model.savePreferences() }
        .onChange(of: model.completionEnabled) { _ in model.savePreferences() }
        .onChange(of: model.scale) { _ in model.savePreferences() }
        .onChange(of: model.volume) { _ in model.audio.updateVolume(); model.savePreferences() }
        .onChange(of: model.colorMode) { _ in model.updateAppearance(); model.savePreferences() }
        .onChange(of: model.fullChance) { _ in model.updateAppearance(); model.savePreferences() }
        .onChange(of: model.textChance) { _ in model.updateAppearance(); model.savePreferences() }
        .onChange(of: model.colorPaused) { _ in model.savePreferences() }
        .onChange(of: model.specialQuotes) { _ in model.updateAppearance(); model.savePreferences() }
        .onChange(of: model.bubbleTapAdvance) { _ in model.savePreferences() }
        .onChange(of: model.followCodex) { _ in model.savePreferences() }
        .onChange(of: model.menuBarOnly) { _ in model.savePreferences() }
        .onChange(of: model.hideInFullscreen) { _ in model.savePreferences() }
        .onChange(of: model.lowQuotaEnabled) { _ in model.updateLowQuota(); model.savePreferences() }
        .onChange(of: model.easterEggsEnabled) { _ in model.saveEasterEggPreferences() }
        .onChange(of: model.squishEnabled) { _ in model.saveEasterEggPreferences() }
        .onChange(of: model.danceEnabled) { _ in model.saveEasterEggPreferences() }
        .onChange(of: model.zeroEnabled) { _ in model.saveEasterEggPreferences() }
        .onChange(of: model.squishLoops) { _ in model.saveEasterEggPreferences() }
        .onChange(of: model.danceLoops) { _ in model.saveEasterEggPreferences() }
        .onChange(of: model.zeroLoops) { _ in model.saveEasterEggPreferences() }
    }

    private func loopPicker(_ count: Binding<Int>) -> some View {
        Picker("次数", selection: count) {
            ForEach(1...10, id: \.self) { Text("\($0) 次").tag($0) }
            Text("持续循环").tag(0)
        }.labelsHidden().frame(width: 102)
    }

    private var section1: some View {
            GroupBox(model.text("版本與更新")) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(model.text("目前版本 %@", String(describing: updater.currentVersion)))
                        Spacer()
                        if updater.busy { ProgressView().controlSize(.small) }
                        Button(model.text("檢查更新")) { updater.check(manual: true) }.disabled(updater.busy || updater.customBuild)
                    }
                    if updater.customBuild {
                        Text(model.text("自定义 WebView 版本请从源码构建更新。")).font(.caption).foregroundStyle(.secondary)
                    } else {
                        Toggle(model.text("自動檢查並安裝正式版"), isOn: $updater.automatic)
                    }
                    Text(updater.localizedStatus(model.language)).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Text(model.text("下載後關閉此視窗，掛件空閒時才會替換應用。確認新版啟動後清理上一版與下載缓存；偏好和語錄保留。"))
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }.padding(10)
            }
    }

    private var section2: some View {
            GroupBox(model.text("界面语言")) {
                VStack(alignment: .leading, spacing: 10) {
                    Picker(model.text("界面语言"), selection: $model.language) {
                        ForEach(InterfaceLanguage.allCases, id: \.self) { Text(model.text($0.title)).tag($0) }
                    }
                }.padding(10)
            }
    }

    private var section3: some View {
            GroupBox(model.text("外觀與顯示")) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        ForEach([0.8, 1.0, 1.4], id: \.self) { value in
                            Button("\(Int(value * 100))%") { model.scale = value }
                        }
                    }
                    Toggle(model.text("提示音"), isOn: $model.soundOn)
                    WidgetAudioMenu(audio: model.audio)
                    Toggle(model.text("隐藏设置按钮"), isOn: $model.hideMenu)
                    HStack { Text(model.text("角色大小")).frame(width: 70, alignment: .leading); Slider(value: $model.scale, in: 0.6...2.5, step: 0.1); Text("\(Int(model.scale * 100))% ").monospacedDigit().frame(width: 48) }
                    HStack { Text(model.text("提示音量")).frame(width: 70, alignment: .leading); Slider(value: $model.volume, in: 0...1); Text(model.volume == 0 ? model.text("靜音") : "\(Int(model.volume * 100))% ").frame(width: 48) }
                    Picker(model.text("显示与位置"), selection: $model.followCodex) {
                        Text(model.text("仅在 Codex 窗口内")).tag(true)
                        Text(model.text("整个桌面自由拖动")).tag(false)
                    }.pickerStyle(.radioGroup)
                    if !model.followCodex { Toggle(model.text("始终置顶"), isOn: $model.desktopTopmost) }
                    Toggle(model.text("收起到菜单栏"), isOn: $model.menuBarOnly)
                    Toggle(model.text("其他应用全屏时自动隐藏"), isOn: $model.hideInFullscreen)
                    Text(model.text("收起后可在菜单栏查看额度，或选择显示桌面挂件。透明区域不会阻挡点击。"))
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Text(model.text("關閉後，掛件會固定在桌面；開啟時，Codex 隱藏或最小化後掛件也會隱藏。"))
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    if let note = model.trackingNote { Text(note).font(.caption).foregroundStyle(.orange) }
                    Toggle(model.text("回答结束提醒"), isOn: $model.completionEnabled)
                    Toggle(model.text("登入 Mac 時自動開啟"), isOn: $model.loginRequested)
                        .onChange(of: model.loginRequested) { value in
                            do {
                                if value { try SMAppService.mainApp.register() }
                                else { try SMAppService.mainApp.unregister() }
                                model.savePreferences()
                                loginError = nil
                                if SMAppService.mainApp.status == .requiresApproval { loginError = model.text("請在系統設定的「登入項目」允許 小白龙娘。") }
                            } catch { loginError = model.text("登入項目設定失敗：%@", String(describing: error.localizedDescription)) }
                        }
                    if let loginError { Text(loginError).font(.caption).foregroundStyle(.orange) }
                }.padding(10)
            }
    }

    private var section4: some View {
            GroupBox(model.text("原版流光效果")) {
                VStack(alignment: .leading, spacing: 10) {
                    Picker(model.text("配色模式"), selection: $model.colorMode) {
                        ForEach(ColorMode.allCases, id: \.self) { Text(model.text($0.title)).tag($0) }
                    }
                    Toggle(model.text("暫停流光"), isOn: $model.colorPaused)
                    HStack { Text(model.text("全身變色機率")); Slider(value: $model.fullChance, in: 0...100); Text(String(format: "%.1f%%", model.fullChance)).frame(width: 55) }
                    HStack { Text(model.text("僅文字變色機率")); Slider(value: $model.textChance, in: 0...100); Text(String(format: "%.1f%%", model.textChance)).frame(width: 55) }
                    TextField(model.text("特殊語錄（以換行分隔）"), text: $model.specialQuotes)
                    Toggle(model.text("點角色時也切換語錄／收起氣泡"), isOn: $model.bubbleTapAdvance)
                }.padding(10)
            }
    }

    private var characterSection: some View {
        GroupBox(model.text("形象与低额度状态")) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 20) {
                    characterPicker(.normal, title: model.text("普通形象"))
                    characterPicker(.low, title: model.text("低额度形象"))
                }
                Text(model.text("支持 PNG、JPEG、WebP。建议使用透明 PNG；导入后保存本地副本。"))
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Toggle(model.text("额度低于 5% 自动切换形象"), isOn: $model.lowQuotaEnabled)
                TextField(model.text("专属台词"), text: $model.lowQuotaQuote, axis: .vertical)
                    .lineLimit(2...4)
                HStack {
                    Text(model.text("任一有效额度低于 5% 触发；确认额度恢复后自动还原。"))
                        .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button(model.text("保存台词")) { model.saveLowQuotaPreferences() }
                }
            }.padding(10)
        }
    }
    private func characterPicker(_ variant: CharacterVariant, title: String) -> some View {
        VStack(spacing: 8) {
            if let image = model.characterImages.image(variant) {
                Image(nsImage: image).resizable().scaledToFit().frame(width: 120, height: 100)
            }
            Text(title).font(.caption.weight(.semibold))
            HStack {
                Button(model.text("导入图片…")) { model.importCharacter(variant) }
                Button(model.text("恢复默认")) { model.resetCharacter(variant) }
            }
        }.frame(maxWidth: .infinity)
    }

    private var section5: some View {
            GroupBox(model.text("自訂語錄 · 每行一則")) {
                VStack(alignment: .leading, spacing: 10) {
                    TextEditor(text: $model.quoteText).font(.system(size: 13)).frame(height: 145)
                        .scrollContentBackground(.hidden).padding(4)
                        .background(Color.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                    HStack {
                        Button(model.text("還原內建語錄")) { model.resetQuotes() }
                        Spacer()
                        Button(model.text("儲存語錄")) { model.saveQuotes() }.buttonStyle(.borderedProminent)
                    }
                }.padding(10)
            }
    }
}
