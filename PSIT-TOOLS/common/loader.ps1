# Import support module a config file
try {
    Import-Module (Join-Path $PSScriptRoot '..\modules\support\support.psd1' -Resolve) -Force -DisableNameChecking -ErrorAction Stop
    $global:PsItTools = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'config.psd1' -Resolve)
    'Support module loaded successfully', 'Config file loaded successfully' | Write-PSITDebug
}
catch {
    throw ("Loader halted! {0}" -f $_.exception.message)
}

# Import all other modules
$ModulesPath = Join-Path $PSScriptRoot '..\modules' -Resolve
$PsItTools.ModulePath = $ModulesPath
Add-PSITModulePath $ModulesPath
(Get-ChildItem $ModulesPath -Directory -Exclude 'support').Name | Where-Object {$_} | Import-PSITModule

# Load help file
try {
    $PsItTools.Help = Import-PowerShellDataFile (Join-Path $PSScriptRoot 'help.psd1') -ErrorAction Stop
}
catch {
    Write-PSITWarning "Unable to load help.psd1 file"
}

# Set location to user home
Set-Location $HOME

# Set customized title
if ($PsItTools.EnableCustomTitle){
    [console]::Title = '{0} ({1}) | {2}@{3} | {4}' -f $PsItTools.BaseTitle,$PsItTools.Version,$env:USERNAME,$env:COMPUTERNAME, (Get-Date -f 'dd/MM/yyyy')
}

# Show MD help
if ($PsItTools.ShowMDHelp){
    Write-PSITSeparatorLine
    Get-Content (Join-Path $PSScriptRoot 'README.MD' -Resolve) | ForEach-Object {
        Write-PSITInfo ('{0}{1}' -f (' '*10),$_)
    }
    Write-PSITSeparatorLine
}