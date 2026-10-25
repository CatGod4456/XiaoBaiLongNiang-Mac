#ifndef AppVersion
  #define AppVersion "1.14.1"
#endif
#ifndef PayloadDir
  #error PayloadDir must be supplied by the verified build script
#endif
#ifndef OutputDir
  #error OutputDir must be supplied by the build script
#endif

[Setup]
AppId={{D763DC9B-C9C0-47BC-9461-D7A7B5D1CB88}
AppName=小白龙娘
AppVersion={#AppVersion}
AppPublisher=CatGod4456 and upstream contributors
AppPublisherURL=https://github.com/CatGod4456/XiaoBaiLongNiang-Mac
AppSupportURL=https://github.com/CatGod4456/XiaoBaiLongNiang-Mac/issues
DefaultDirName={localappdata}\Programs\XiaoBaiLongNiang
DefaultGroupName=小白龙娘
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
WizardStyle=modern
Compression=lzma2/ultra64
SolidCompression=yes
OutputDir={#OutputDir}
OutputBaseFilename=XiaoBaiLongNiang-{#AppVersion}-Windows-x64-Setup
SetupIconFile={#PayloadDir}\gpt-niang-usage\assets\AppIcon.ico
UninstallDisplayIcon={app}\XiaoBaiLongNiang.exe
LicenseFile={#PayloadDir}\LICENSE
InfoBeforeFile={#PayloadDir}\WINDOWS-README.txt
CloseApplications=yes
RestartApplications=no
Uninstallable=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
#if FileExists(AddBackslash(CompilerPath) + "Languages\ChineseSimplified.isl")
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
#endif

[Tasks]
Name: "startup"; Description: "登录 Windows 时启动 / Start when I sign in"; Flags: unchecked
Name: "desktopicon"; Description: "创建桌面快捷方式 / Desktop shortcut"; Flags: unchecked

[Files]
Source: "{#PayloadDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs; Excludes: "setup-preflight.ps1"
Source: "{#PayloadDir}\setup-preflight.ps1"; Flags: dontcopy

[Icons]
Name: "{autoprograms}\小白龙娘"; Filename: "{app}\XiaoBaiLongNiang.exe"; WorkingDir: "{app}"
Name: "{autodesktop}\小白龙娘"; Filename: "{app}\XiaoBaiLongNiang.exe"; WorkingDir: "{app}"; Tasks: desktopicon
Name: "{autoprograms}\小白龙娘使用说明"; Filename: "{app}\WINDOWS-README.txt"

[Run]
Filename: "{app}\XiaoBaiLongNiang.exe"; Description: "启动小白龙娘 / Launch widget"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
Type: files; Name: "{app}\gpt-niang-usage\installation.json"

[Code]
function PowerShell: String;
begin
  Result := ExpandConstant('{sys}\WindowsPowerShell\v1.0\powershell.exe');
end;

function PrepareToInstall(var NeedsRestart: Boolean): String;
var
  Code: Integer;
  Script: String;
begin
  Result := '';
  ExtractTemporaryFile('setup-preflight.ps1');
  Script := ExpandConstant('{tmp}\setup-preflight.ps1');
  if (not Exec(PowerShell, '-NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + Script + '"', '', SW_HIDE, ewWaitUntilTerminated, Code)) or (Code <> 0) then
  begin
    Result := '请先安装并打开 Codex 桌面端，再安装小白龙娘。 / Install and open the Codex desktop app first.';
    exit;
  end;
  if FileExists(ExpandConstant('{app}\gpt-niang-usage\installation.json')) then
    if (not Exec(PowerShell, '-NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + Script + '" -StopExisting -AppDir "' + ExpandConstant('{app}\gpt-niang-usage') + '"', '', SW_HIDE, ewWaitUntilTerminated, Code)) or (Code <> 0) then
      Result := '旧版挂件未能退出，请关闭旧版后重试。 / Close the previous widget and retry.';
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Code: Integer;
  Options: String;
begin
  if CurStep = ssPostInstall then
  begin
    Options := '';
    if not WizardIsTaskSelected('startup') then Options := ' -NoStartup';
    if (not Exec(PowerShell, '-NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + ExpandConstant('{app}\setup-register.ps1') + '" -AppDir "' + ExpandConstant('{app}\gpt-niang-usage') + '"' + Options, '', SW_HIDE, ewWaitUntilTerminated, Code)) or (Code <> 0) then
      RaiseException('Codex 组件注册失败。请安装并打开 Codex，停用其他位置的旧版挂件后重新运行安装包。个人设置会保留。 / Codex registration failed. Open Codex, disable any previous widget installation and retry.');
  end;
end;

function InitializeUninstall: Boolean;
var
  Code: Integer;
begin
  Result := Exec(PowerShell, '-NoLogo -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + ExpandConstant('{app}\setup-register.ps1') + '" -AppDir "' + ExpandConstant('{app}\gpt-niang-usage') + '" -Uninstall', '', SW_HIDE, ewWaitUntilTerminated, Code) and (Code = 0);
  if not Result then MsgBox('请先关闭挂件和 Codex 中正在使用此插件的任务，然后重试卸载。用户设置不会删除。 / Close the widget and retry uninstalling.', mbError, MB_OK);
end;
