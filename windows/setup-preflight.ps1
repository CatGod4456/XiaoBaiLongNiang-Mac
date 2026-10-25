param([string]$AppDir,[switch]$StopExisting)
$ErrorActionPreference='Stop'
if($StopExisting){
  $configPath=Join-Path $AppDir 'installation.json'
  if(!(Test-Path -LiteralPath $configPath)){exit 0}
  $config=Get-Content -LiteralPath $configPath -Raw -Encoding UTF8|ConvertFrom-Json
  if([IO.Path]::GetFullPath([string]$config.appDir).TrimEnd('\')-ine [IO.Path]::GetFullPath($AppDir).TrimEnd('\')){throw 'Installation identity mismatch.'}
  . (Join-Path $AppDir 'runtime\supervisor-task.ps1')
  . (Join-Path $AppDir 'runtime\update-common.ps1')
  Stop-WidgetSupervisorTask -AppDir $AppDir -Configuration $config
  Stop-WidgetGui -AppDir $AppDir -DataDir $config.dataDir
  exit 0
}
$codex=Get-Command codex.exe -ErrorAction SilentlyContinue
if(!$codex){
  $root=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'OpenAI\Codex\bin'
  if(Test-Path -LiteralPath $root){$codex=Get-ChildItem -LiteralPath $root -Filter codex.exe -File -Recurse -ErrorAction SilentlyContinue|Select-Object -First 1}
}
if(!$codex){Write-Error 'Install and open the Codex desktop app before installing this widget.';exit 1}
exit 0
