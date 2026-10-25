param([string]$OutputDirectory)
$ErrorActionPreference='Stop'
$app=Split-Path $PSScriptRoot -Parent
Add-Type -AssemblyName PresentationFramework,PresentationCore,WindowsBase,System.Drawing,System.Windows.Forms
. ([ScriptBlock]::Create([IO.File]::ReadAllText((Join-Path $app 'runtime\windows-port.ps1'),[Text.Encoding]::UTF8)))
$references=@('System.dll','System.Drawing.dll',([Windows.Media.Imaging.BitmapSource].Assembly.Location),([Windows.Controls.Image].Assembly.Location),([Windows.Threading.Dispatcher].Assembly.Location))
Add-Type -TypeDefinition ([IO.File]::ReadAllText((Join-Path $app 'runtime\widget-motion.cs'),[Text.Encoding]::UTF8)) -ReferencedAssemblies $references
Add-Type -TypeDefinition ([IO.File]::ReadAllText((Join-Path $app 'runtime\widget-tray.cs'),[Text.Encoding]::UTF8)) -ReferencedAssemblies @('System.dll','System.Drawing.dll','System.Windows.Forms.dll',([Windows.Media.Imaging.BitmapSource].Assembly.Location),([Windows.Threading.Dispatcher].Assembly.Location))
$checks=0
function Assert-Port([bool]$Value,[string]$Message){if(!$Value){throw $Message};$script:checks++}
function Pump-Port([int]$Milliseconds){
  $deadline=[DateTime]::UtcNow.AddMilliseconds($Milliseconds)
  do{[Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{},[Windows.Threading.DispatcherPriority]::Background);Start-Sleep -Milliseconds 5}while([DateTime]::UtcNow-lt $deadline)
}
Initialize-WidgetPortSettings $null
$normal=@{squish=0;dance=0;zero=0};$empty=@{squish=0;dance=0;zero=0}
foreach($i in 0..5999){
  $roll=($i+.5)/6000
  $kind=[GptWidgetMotionMath]::SelectEgg($roll,$false,$true,$true,$true,$true);if($kind){$normal[$kind]++}
  $kind=[GptWidgetMotionMath]::SelectEgg($roll,$true,$true,$true,$true,$true);if($kind){$empty[$kind]++}
}
Assert-Port ($normal.squish-eq 150 -and $normal.dance-eq 150 -and $normal.zero-eq 0) 'Normal allocation must be 2.5% per egg.'
Assert-Port ($empty.squish-eq 100 -and $empty.dance-eq 100 -and $empty.zero-eq 100) 'Zero allocation must share a single 5% interval equally.'
Assert-Port ($null-eq [GptWidgetMotionMath]::SelectEgg(.01,$false,$true,$false,$true,$true)) 'Disabled slots must not transfer probability.'
Assert-Port ($null-eq [GptWidgetMotionMath]::SelectEgg(.01,$true,$false,$true,$true,$true)) 'Global disable must suppress every random egg.'
Assert-Port ($null-eq [GptWidgetMotionMath]::SelectEgg(.05,$true,$true,$true,$true,$true)) 'The upper bound must be excluded.'
$now=1900000000000L
function New-PortStatus($Remaining){@{ok=$true;queryOk=$true;observedAt=$now;windows=@(@{minutes=10080;remaining=$Remaining;resetsAt=($now/1000+600)})}}
Assert-Port ((Get-WidgetQuotaFacts (New-PortStatus 0) $now).zero) 'Fresh exact zero must be eligible.'
Assert-Port (!(Get-WidgetQuotaFacts (New-PortStatus .00001) $now).zero) 'A rounded positive amount is not zero.'
$bad=New-PortStatus 0;$bad.observedAt=$now-180001;Assert-Port (!(Get-WidgetQuotaFacts $bad $now).zero) 'Old snapshots must not trigger the zero egg.'
$bad=New-PortStatus 0;$bad.windows[0].resetsAt=$now/1000;Assert-Port (!(Get-WidgetQuotaFacts $bad $now).zero) 'Reset windows must not trigger the zero egg.'
$bad=New-PortStatus 0;$bad.queryOk=$false;Assert-Port (!(Get-WidgetQuotaFacts $bad $now).zero) 'Failed reads must not trigger the zero egg.'
$bad=New-PortStatus 0;$bad.observedAt=$now+6000;Assert-Port (!(Get-WidgetQuotaFacts $bad $now).zero) 'Future timestamps must not be treated as fresh.'
$bad=New-PortStatus ([double]::NaN);Assert-Port (!(Get-WidgetQuotaFacts $bad $now).fresh) 'Nonfinite quota values must be ignored.'
Initialize-WidgetPortSettings ([pscustomobject]@{pressSpeed=30;danceRepeats=100;zeroRepeats=-1;squishRepeats=0;easterEggsEnabled=$false;pressImmediate=$true})
Assert-Port ($script:portSettings.pressSpeed-eq 1 -and $script:portSettings.danceRepeats-eq 1 -and $script:portSettings.zeroRepeats-eq 1) 'Malformed settings must keep bounded defaults.'
Assert-Port ($script:portSettings.squishRepeats-eq 0 -and !$script:portSettings.easterEggsEnabled -and $script:portSettings.pressImmediate) 'Explicit loop and switch values must survive.'
$work=Join-Path ([IO.Path]::GetTempPath()) ('xiaobai-port-test-'+[Guid]::NewGuid().ToString('N'))
$null=[IO.Directory]::CreateDirectory($work)
$window=$null;$motion=$null;$tray=$null
try{
  $tokens=$null;$errors=$null;$ast=[Management.Automation.Language.Parser]::ParseInput([IO.File]::ReadAllText((Join-Path $app 'widget.ps1'),[Text.Encoding]::UTF8),[ref]$tokens,[ref]$errors)
  Assert-Port ($errors.Count-eq 0) 'Full widget must parse in Windows PowerShell 5.1.'
  foreach($name in @('Write-WidgetJson','Save-Settings')){$node=$ast.Find({param($n)$n-is [Management.Automation.Language.FunctionDefinitionAst] -and $n.Name-eq $name},$true);. ([ScriptBlock]::Create($node.Extent.Text))}
  $settingsFile=Join-Path $work 'settings.json';Save-Settings
  $saved=[IO.File]::ReadAllText($settingsFile)|ConvertFrom-Json
  Initialize-WidgetPortSettings $saved
  Assert-Port ($script:portSettings.squishRepeats-eq 0 -and $script:portSettings.pressImmediate -and !$script:portSettings.easterEggsEnabled) 'Playback and press settings must survive a real save/reload.'
  foreach($case in @(@{file='egg-dance.gif';frames=70;duration=7000},@{file='egg-zero.gif';frames=98;duration=9800})){
    $gif=[GptWidgetGif]::new((Join-Path $app ('assets\'+$case.file)))
    try{
      Assert-Port ($gif.FrameCount-eq $case.frames -and $gif.Duration-eq $case.duration) ('Original timing mismatch: '+$case.file)
      foreach($i in 0..($case.frames-1)){Assert-Port ($gif.Delays[$i]-eq 100 -and $gif.FrameAt($i*100)-eq $i) 'Every original frame must keep its 100ms slot.'}
      Assert-Port ($gif.FrameAt($case.duration-1)-eq $case.frames-1 -and $gif.FrameAt($case.duration)-eq 0) 'Only an actual cycle boundary may loop.'
      foreach($i in @(0,[int]($case.frames/2),($case.frames-1))){
        $frame=$gif.Decode($i);Assert-Port ($frame.IsFrozen -and $frame.PixelWidth-le 640 -and $frame.PixelHeight-le 640) 'Decoded GIF frames must be detached and bounded.'
        if($OutputDirectory){$null=[IO.Directory]::CreateDirectory($OutputDirectory);$encoder=[Windows.Media.Imaging.PngBitmapEncoder]::new();$encoder.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($frame));$stream=[IO.File]::Create((Join-Path $OutputDirectory ($case.file+'-'+$i+'.png')));try{$encoder.Save($stream)}finally{$stream.Dispose()}}
      }
    }finally{$gif.Dispose()}
  }
  $window=[Windows.Markup.XamlReader]::Parse('<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Width="350" Height="350" Left="-20000" Top="-20000" ShowInTaskbar="False"><Canvas><Image x:Name="Girl" Width="208" Height="208"/></Canvas></Window>')
  $girl=$window.FindName('Girl');$press=[Windows.Media.ScaleTransform]::new();$motion=[GptWidgetMotion]::new($girl,$press)
  $image=[Windows.Media.Imaging.BitmapImage]::new([Uri]::new((Join-Path $app 'assets\gpt-dragon-niang-bust.png')));$image.Freeze();$motion.SetBaseImage($image)
  $window.Show();Pump-Port 30
  $motion.Press($true);$motion.Press($false);Pump-Port 90
  Assert-Port ($motion.PressActive -and $press.ScaleY-lt .99) 'A same-frame short tap must reach a visible compressed pose.'
  Pump-Port 500;Assert-Port (!$motion.PressActive -and [Math]::Abs($press.ScaleY-1)-lt .001) 'A short tap must finish the complete rebound.'
  $motion.Immediate=$true;$motion.Press($true);Assert-Port ([Math]::Abs($press.ScaleY-.89)-lt .001) 'Immediate press must reach its target synchronously.'
  $motion.Press($false);Pump-Port 400;Assert-Port (!$motion.PressActive) 'Immediate press must still release completely.'
  $scale=[GptWidgetMotionMath]::Stretch(240);Assert-Port ([Math]::Abs($scale[0]-1.2)-lt .0001 -and [Math]::Abs($scale[1]-.75)-lt .0001) 'Stretch must expand/compress in place without rotation.'
  $motion.Play('squish',(Join-Path $app 'assets\egg-squish.png'),1);Pump-Port 1000
  Assert-Port (!$motion.Active -and $motion.CompletedCycles-eq 1) 'A single-cycle selection must stop after one cycle.'
  $motion.Play('squish',(Join-Path $app 'assets\egg-squish.png'),0);Pump-Port 900;Assert-Port ($motion.Active) 'Continuous playback must wait for an explicit stop.';$motion.Stop()
  $tray=[GptWidgetTray]::new();$tray.SetPortrait($image);$tray.Update('89','每周 89%',$false);$tray.Update('?','额度已过期，请刷新',$true)
  Assert-Port ($true) 'Tray icon must support quota, stale data and disposal without handle errors.'
}finally{if($tray){$tray.Dispose()};if($motion){$motion.Dispose()};if($window){$window.Close()};Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue}
Write-Output ('PASS: Windows port checks: '+$checks)
