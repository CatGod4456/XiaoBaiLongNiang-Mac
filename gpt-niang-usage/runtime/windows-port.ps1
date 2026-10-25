# Windows additions use the existing WPF, gallery, music and quota backend.
function Initialize-WidgetPortSettings($Settings) {
  $defaults=@{easterEggsEnabled=$true;squishEnabled=$true;danceEnabled=$true;zeroEnabled=$true;squishRepeats=3;danceRepeats=1;zeroRepeats=1;pressSpeed=1.0;pressImmediate=$false;lowQuotaEnabled=$true;lowQuotaQuote='需要重置……';lowCharacterId='gpt-dragon-low';trayOnly=$false}
  $script:portSettings=$defaults.Clone()
  foreach($name in @('easterEggsEnabled','squishEnabled','danceEnabled','zeroEnabled','pressImmediate','lowQuotaEnabled','trayOnly')) {
    if($Settings.$name-is [bool]){$script:portSettings[$name]=$Settings.$name}
  }
  foreach($name in @('squishRepeats','danceRepeats','zeroRepeats')) {
    $v=$Settings.$name
    if($null-ne $v -and $v-isnot [bool]){try{if([double]$v-ge 0 -and [double]$v-le 10 -and [double]$v-eq [int]$v){$script:portSettings[$name]=[int]$v}}catch{}}
  }
  if($null-ne $Settings.pressSpeed -and $Settings.pressSpeed-isnot [bool]){try{$v=[double]$Settings.pressSpeed;if(![double]::IsNaN($v)-and $v-ge .5 -and $v-le 3){$script:portSettings.pressSpeed=$v}}catch{}}
  if($Settings.lowQuotaQuote-is [string] -and $Settings.lowQuotaQuote.Trim().Length-gt 0 -and $Settings.lowQuotaQuote.Length-le 200){$script:portSettings.lowQuotaQuote=$Settings.lowQuotaQuote}
  if($Settings.lowCharacterId-is [string] -and $Settings.lowCharacterId-match '^(?:[a-z][a-z0-9-]{0,63}|custom-[0-9a-f]{32})$'){$script:portSettings.lowCharacterId=$Settings.lowCharacterId}
  $script:portLow=$false;$script:portImage=$null;$script:portLowImage=$null;$script:portLowId=$null;$script:portStoppedOnPress=$false
  $script:eggRandom=New-Object Random
}
function Get-WidgetQuotaFacts($Status,[long]$Now=([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())) {
  $result=@{fresh=$false;zero=$false;low=$false;minimum=$null;summary='正在读取额度…';badge='?'}
  if(!$Status -or $Status.ok-ne $true -or $Status.queryOk-ne $true -or $Status.error){return $result}
  try{$observed=[double]$Status.observedAt}catch{return $result}
  if([double]::IsNaN($observed)-or [double]::IsInfinity($observed)-or $observed-le 0 -or $observed-gt $Now+5000 -or $Now-$observed-gt 180000){$result.summary='额度已过期，请刷新';return $result}
  $values=@();$labels=@()
  foreach($window in @($Status.windows)) {
    if($window.remaining-is [bool] -or $null-eq $window.remaining){continue}
    try{$left=[double]$window.remaining}catch{continue}
    if([double]::IsNaN($left)-or [double]::IsInfinity($left)-or $left-lt 0 -or $left-gt 100){continue}
    if($null-ne $window.resetsAt){try{$reset=[double]$window.resetsAt;if([double]::IsNaN($reset)-or [double]::IsInfinity($reset)-or $reset-le $Now/1000){continue}}catch{continue}}
    $values+=,$left;$label=if($window.kind-eq 'individual'){'个人'}elseif($window.minutes-eq 300){'5小时'}elseif($window.minutes-eq 10080){'每周'}else{[string]$window.label}
    $labels+=($label+' '+$left.ToString('0.#',[Globalization.CultureInfo]::InvariantCulture)+'%')
  }
  if(!$values.Count){return $result}
  $minimum=($values|Measure-Object -Minimum).Minimum
  $result.fresh=$true;$result.minimum=$minimum;$result.zero=@($values|Where-Object{$_-eq 0}).Count-gt 0;$result.low=$minimum-lt 5
  $result.summary=$labels-join ' · ';$result.badge=([Math]::Round($minimum)).ToString([Globalization.CultureInfo]::InvariantCulture)
  return $result
}
function Initialize-WidgetPort {
  if(!('GptWidgetMotion' -as [type])) {
    $references=@('System.dll','System.Drawing.dll',([Windows.Media.Imaging.BitmapSource].Assembly.Location),([Windows.Controls.Image].Assembly.Location),([Windows.Threading.Dispatcher].Assembly.Location))
    Add-Type -TypeDefinition ([IO.File]::ReadAllText((Join-Path $script:appDir 'runtime\widget-motion.cs'),[Text.Encoding]::UTF8)) -ReferencedAssemblies $references
  }
  $script:portMotion=[GptWidgetMotion]::new($script:ui.Girl,$script:ui.PressScale)
  $script:portMotion.Add_Finished({Set-BubbleState})
  $script:portMotion.SetBaseImage($script:bitmap);$script:portImage=$script:bitmap
  $icon=Join-Path $script:appDir 'assets\AppIcon.ico'
  if([IO.File]::Exists($icon)){$script:window.Icon=[Windows.Media.Imaging.BitmapFrame]::Create([Uri]::new($icon))}
}
function Initialize-WidgetTray {
  if(!('GptWidgetTray' -as [type])){
    Add-Type -TypeDefinition ([IO.File]::ReadAllText((Join-Path $script:appDir 'runtime\widget-tray.cs'),[Text.Encoding]::UTF8)) -ReferencedAssemblies @('System.dll','System.Drawing.dll','System.Windows.Forms.dll',([Windows.Media.Imaging.BitmapSource].Assembly.Location),([Windows.Threading.Dispatcher].Assembly.Location))
  }
  $script:portTray=[GptWidgetTray]::new();$script:portTray.SetPortrait($script:bitmap)
  $script:portTray.Add_Requested({param($action)
    switch($action){
      'quota' {$script:portSettings.trayOnly=$false;Tick-Widget;Show-Quota;Save-Settings}
      'refresh' {Request-Refresh}
      'toggle' {$script:portSettings.trayOnly=!$script:portSettings.trayOnly;if($script:portSettings.trayOnly){$script:window.Hide()};Save-Settings;Tick-Widget}
      'settings' {$script:portSettings.trayOnly=$false;Tick-Widget;Open-WidgetMenu;Save-Settings}
      'exit' {Exit-WidgetForSession}
    }
  })
  Update-WidgetPortState
}
function Update-WidgetPortState {
  if(!$script:portSettings){return}
  $facts=Get-WidgetQuotaFacts $script:status
  $script:portLow=$script:portSettings.lowQuotaEnabled -and $facts.fresh -and $facts.low
  $image=$script:bitmap
  if($script:portLow){
    if(!$script:portLowImage -or $script:portLowId-ne $script:portSettings.lowCharacterId){
      try{$character=Get-WidgetCharacter $script:appDir $script:dataDir $script:portSettings.lowCharacterId;$script:portLowImage=Read-WidgetCharacterImage $character.path;$script:portLowId=$script:portSettings.lowCharacterId}catch{$script:portLowImage=$null}
    }
    if($script:portLowImage){$image=$script:portLowImage}
    if($script:bubbleMode-eq 'quote'){$script:ui.QuoteText.Text=$script:portSettings.lowQuotaQuote}
  }
  if($script:portMotion -and ![object]::ReferenceEquals($script:portImage,$image)){$script:portMotion.SetBaseImage($image);$script:portImage=$image}
  if($script:portMotion){$script:portMotion.Speed=$script:portSettings.pressSpeed;$script:portMotion.Immediate=$script:portSettings.pressImmediate}
  if($script:portTray){$script:portTray.Update($facts.badge,$facts.summary,$script:portSettings.trayOnly)}
}
function Start-WidgetEasterEgg([string]$Kind,[switch]$Preview) {
  if(!$script:portMotion){return}
  $path=Join-Path $script:appDir ('assets\'+@{squish='egg-squish.png';dance='egg-dance.gif';zero='egg-zero.gif'}[$Kind])
  if(![IO.File]::Exists($path)){return}
  if(Test-WidgetMusicActive){Stop-WidgetMusic}
  try{$script:portMotion.Play($Kind,$path,[int]$script:portSettings[$Kind+'Repeats']);foreach($name in @('Bubble','Tail','TailNear')){$script:ui[$name].Visibility=[Windows.Visibility]::Hidden}}
  catch{$script:portMotion.Stop();Set-BubbleState;[Windows.MessageBox]::Show($script:window,'彩蛋素材未能读取，请重新安装完整版本。','小白龙娘')|Out-Null}
}
function Invoke-WidgetEasterEgg {
  if(!$script:portSettings -or !$script:portMotion){return $false}
  if($script:portStoppedOnPress){$script:portStoppedOnPress=$false;return $true}
  if($script:portMotion.Active){$script:portMotion.Stop();Set-BubbleState;return $true}
  $facts=Get-WidgetQuotaFacts $script:status
  $kind=[GptWidgetMotionMath]::SelectEgg($script:eggRandom.NextDouble(),[bool]$facts.zero,[bool]$script:portSettings.easterEggsEnabled,[bool]$script:portSettings.squishEnabled,[bool]$script:portSettings.danceEnabled,[bool]$script:portSettings.zeroEnabled)
  if(!$kind){return $false}
  $path=Join-Path $script:appDir ('assets\'+@{squish='egg-squish.png';dance='egg-dance.gif';zero='egg-zero.gif'}[$kind])
  if(![IO.File]::Exists($path)){return $false}
  Start-WidgetEasterEgg $kind;return $true
}
function Add-WidgetPortMenu {
  $script:settingsMenuUi.Press=Add-SettingsSubmenu '按压与彩蛋' {
    $script:settingsMenuUi.PressImmediate=Add-SettingsAction '立即到达按下姿态' {param($sender,$event)$script:portSettings.pressImmediate=[bool]$sender.IsChecked;Update-WidgetPortState;Save-Settings} -Checkable -ReturnItem
    $speed=New-SettingsSlider '普通按压速度' .5 3 .25;$script:settingsMenuUi.PressSpeed=$speed.Slider;$script:settingsMenuUi.PressSpeedText=$speed.Value;$speed.Slider.Value=$script:portSettings.pressSpeed
    $speed.Slider.Add_ValueChanged({param($sender,$event)if($script:settingsMenuSync){return};$script:portSettings.pressSpeed=[Math]::Round($sender.Value,2);$script:settingsMenuUi.PressSpeedText.Text=$script:portSettings.pressSpeed.ToString()+'×';Update-WidgetPortState;Save-Settings});Add-SettingsPanel $speed.Panel
    Add-SettingsDivider
    $script:settingsMenuUi.EasterEnabled=Add-SettingsAction '开启随机彩蛋' {param($sender,$event)$script:portSettings.easterEggsEnabled=[bool]$sender.IsChecked;if(!$sender.IsChecked){$script:portMotion.Stop();Set-BubbleState};Save-Settings} -Checkable -ReturnItem
    foreach($choice in @(@{id='squish';title='原位 stretch';note='弹跳高松灯.gif'},@{id='dance';title='兔兔跳舞';note='兔兔.gif · 原版 7 秒'},@{id='zero';title='零额度拳击';note='原版 9.8 秒 · 仅有效零额度随机触发'})){
      $script:settingsMenuUi['Egg_'+$choice.id]=Add-SettingsSubmenu $choice.title {
        $enable=Add-SettingsAction '开启' {param($sender,$event)$script:portSettings[([string]$sender.Tag)+'Enabled']=[bool]$sender.IsChecked;Save-Settings} -Checkable -ReturnItem;$enable.Tag=$choice.id;$script:settingsMenuUi['EggEnabled_'+$choice.id]=$enable
        $preview=Add-SettingsAction '预览动画' {param($sender,$event)$script:context.IsOpen=$false;Start-WidgetEasterEgg ([string]$sender.Tag) -Preview} -ReturnItem;$preview.Tag=$choice.id
        $script:settingsMenuUi['EggCounts_'+$choice.id]=@()
        foreach($count in @(1,2,3,4,5,6,7,8,9,10,0)){
          $label=if($count-eq 0){'持续循环'}else{([string]$count)+' 次'}
          $item=Add-SettingsAction $label {param($sender,$event)$script:portSettings[$sender.Tag.id+'Repeats']=[int]$sender.Tag.count;Save-Settings;Update-WidgetPortMenu} -Checkable -ReturnItem;$item.Tag=@{id=$choice.id;count=$count};$item.Uid='radio';$script:settingsMenuUi['EggCounts_'+$choice.id]+=,$item
        }
        Add-SettingsPanel (New-SettingsText $choice.note 11 '#927AAB') -Passive
      } -ReturnItem
    }
    Add-SettingsAction '停止当前彩蛋' {$script:portMotion.Stop();Set-BubbleState}
    Add-SettingsPanel (New-SettingsText '总概率 5%，不累计。普通时两种各 2.5%；有效零额度时三种均分。关闭的概率不转移。' 11 '#927AAB') -Passive
  } -ReturnItem
  $script:settingsMenuUi.LowQuota=Add-SettingsSubmenu '低额度形象与台词' {
    $script:settingsMenuUi.LowEnabled=Add-SettingsAction '剩余低于 5% 时切换形象' {param($sender,$event)$script:portSettings.lowQuotaEnabled=[bool]$sender.IsChecked;Update-WidgetPortState;Save-Settings} -Checkable -ReturnItem
    Add-SettingsAction '选择低额度形象' {Open-WidgetLowCharacterPicker}
    Add-SettingsAction '编辑低额度台词' {Open-WidgetLowQuoteEditor}
    Add-SettingsAction '恢复默认低额度形象' {$script:portSettings.lowCharacterId='gpt-dragon-low';$script:portLowImage=$null;Update-WidgetPortState;Save-Settings}
  } -ReturnItem
  $script:settingsMenuUi.TrayOnly=Add-SettingsAction '仅显示托盘' {param($sender,$event)$script:portSettings.trayOnly=[bool]$sender.IsChecked;if($sender.IsChecked){$script:window.Hide()};Save-Settings;Tick-Widget} -Checkable -ReturnItem
  Add-SettingsSubmenu '作者与素材来源' {
    foreach($link in @(@{name='T7moris · 主体源码';url='https://github.com/T7moris/GPT-Niang'},@{name='meaqua9420 · 原生 Mac 基础';url='https://github.com/T7moris/GPT-Niang/pull/3'},@{name='MeteorNOX · 创意、气泡与语录';url='https://github.com/MeteorNOX/DeepSeek-Balance-Whale-Widget'},@{name='ZipZipPipe · 角色形象与衍生图标';url='https://space.bilibili.com/4168597/'},@{name='疚刃 · 兔兔跳舞';url='https://www.bilibili.com/video/BV16Vap6yEGP/'},@{name='疚刃 · 零额度拳击';url='https://www.bilibili.com/video/BV1SZpR6hEcv/'},@{name='这个刀子真甜 · 此前视频来源';url='https://www.bilibili.com/video/BV1ovpE66Es8/'},@{name='关注主播，谢谢喵';url='https://space.bilibili.com/319500223/'})){
      $item=Add-SettingsAction $link.name {param($sender,$event)Start-Process ([string]$sender.Tag)} -ReturnItem;$item.Tag=$link.url
    }
    Add-SettingsAction '查看完整来源与使用条件' {Start-Process (Join-Path $script:appDir 'notices\CREDITS.md')}
  }
}
function Update-WidgetPortMenu {
  if(!$script:portSettings -or !$script:settingsMenuUi.Press){return}
  $script:settingsMenuUi.PressImmediate.IsChecked=$script:portSettings.pressImmediate;$script:settingsMenuUi.PressSpeed.Value=$script:portSettings.pressSpeed;$script:settingsMenuUi.PressSpeedText.Text=$script:portSettings.pressSpeed.ToString()+'×'
  $script:settingsMenuUi.EasterEnabled.IsChecked=$script:portSettings.easterEggsEnabled;$script:settingsMenuUi.LowEnabled.IsChecked=$script:portSettings.lowQuotaEnabled;$script:settingsMenuUi.TrayOnly.IsChecked=$script:portSettings.trayOnly
  foreach($kind in @('squish','dance','zero')){
    $script:settingsMenuUi['EggEnabled_'+$kind].IsChecked=$script:portSettings[$kind+'Enabled']
    foreach($item in $script:settingsMenuUi['EggCounts_'+$kind]){$item.IsChecked=$script:portSettings[$kind+'Repeats']-eq $item.Tag.count}
  }
}
function Open-WidgetLowCharacterPicker {
  $dialog=[Windows.Markup.XamlReader]::Parse('<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="选择低额度形象" Width="380" Height="240" WindowStartupLocation="CenterOwner"><StackPanel Margin="20"><TextBlock Text="选择图库中的形象，或导入电脑上的图片。" TextWrapping="Wrap"/><ComboBox x:Name="Choices" Margin="0,14" DisplayMemberPath="name"/><Button x:Name="Import" Content="导入图片…" Margin="0,0,0,12"/><Button x:Name="Save" Content="保存"/></StackPanel></Window>')
  $dialog.Owner=$script:window;$choices=$dialog.FindName('Choices');$choices.ItemsSource=@(Get-WidgetCharacters $script:appDir $script:dataDir)
  foreach($row in $choices.Items){if($row.id-eq $script:portSettings.lowCharacterId){$choices.SelectedItem=$row}}
  $dialog.FindName('Import').Add_Click({param($sender,$event)
    $pick=[Microsoft.Win32.OpenFileDialog]::new();$pick.Filter='图片|*.png;*.jpg;*.jpeg;*.bmp;*.gif'
    if($pick.ShowDialog()-eq $true){try{$row=Import-WidgetCharacter $script:dataDir $pick.FileName;$script:portSettings.lowCharacterId=$row.id;$script:portLowImage=$null;Update-WidgetPortState;Save-Settings;$thisWindow=[Windows.Window]::GetWindow($sender);$thisWindow.Close()}catch{[Windows.MessageBox]::Show($_.Exception.Message)|Out-Null}}
  })
  $dialog.FindName('Save').Add_Click({param($sender,$event)$owner=[Windows.Window]::GetWindow($sender);$row=$owner.FindName('Choices').SelectedItem;if($row){$script:portSettings.lowCharacterId=$row.id;$script:portLowImage=$null;Update-WidgetPortState;Save-Settings;$owner.Close()}})
  $null=$dialog.ShowDialog()
}
function Open-WidgetLowQuoteEditor {
  $dialog=[Windows.Markup.XamlReader]::Parse('<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" Title="低额度台词" Width="400" Height="200" WindowStartupLocation="CenterOwner"><StackPanel Margin="20"><TextBox x:Name="Quote" MaxLength="200" AcceptsReturn="True" TextWrapping="Wrap" Height="80"/><Button x:Name="Save" Content="保存" Margin="0,14,0,0"/></StackPanel></Window>')
  $dialog.Owner=$script:window;$dialog.FindName('Quote').Text=$script:portSettings.lowQuotaQuote
  $dialog.FindName('Save').Add_Click({param($sender,$event)$owner=[Windows.Window]::GetWindow($sender);$text=$owner.FindName('Quote').Text.Trim();if($text){$script:portSettings.lowQuotaQuote=$text;Update-WidgetPortState;Save-Settings;$owner.Close()}})
  $null=$dialog.ShowDialog()
}
