param([string]$AppDir,[switch]$NoStartup,[switch]$Uninstall)
$ErrorActionPreference='Stop'
$log=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'GPTNiangUsage\setup-status.txt'
$null=[IO.Directory]::CreateDirectory((Split-Path $log -Parent))
try{
  if($Uninstall){
    if(Test-Path -LiteralPath (Join-Path $AppDir 'installation.json')){& (Join-Path $AppDir 'Uninstall.ps1')}
  }else{& (Join-Path $AppDir 'Install.ps1') -NoStartup:$NoStartup}
  [IO.File]::WriteAllText($log,'Setup completed.',[Text.UTF8Encoding]::new($false))
  exit 0
}catch{
  # Do not persist command output, account responses or environment contents.
  [IO.File]::WriteAllText($log,'Setup failed. Install/open Codex, stop any previous widget installation and retry. Saved user preferences are not deleted.',[Text.UTF8Encoding]::new($false))
  exit 1
}
