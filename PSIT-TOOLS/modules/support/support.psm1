function Add-PSITModulePath {
    # This simple function adds full path string to $env:PSModulePath env. variable
    param (
        [parameter(ValueFromPipeline = $true)]$Path
    )
    process {
        if (($env:PSModulePath -split ';') -notcontains $Path) {
            Write-PSITDebug ('Adding path {0} to $env:PSModulePath' -f $Path)
            $env:PSModulePath = $env:PSModulePath + ";$Path"
        }
        else {
            Write-PSITDebug ('Path {0} is already present in $env:PSModulePath' -f $Path)
        }
    }
}
function Import-PSITModule {
    # This simple function forcefully loads PS modules to session. Also skips mmodule members name checking
    param (
        [parameter(ValueFromPipeline = $true)][string]$Name
    )
    process {
        Write-PSITDebug "Loading module '$Name'"
        if ($Name) {
            try {
                switch ($Name) {
                    { $_ -match '\.psd1' } {
                        Import-Module "$Name" -DisableNameChecking -Force -ErrorAction stop
                    }
                    default {
                        Import-Module -Name $Name -Force -ErrorAction stop -DisableNameChecking
                    }
                }
            }
            catch {
                Write-PSITWarning ('Unable to load module {0}. {1}' -f $Name, $_)
            }
        }
    }
}
function Write-PSITDebug {
    # This simple function logs debug entry to console. Use -PassThru parameter to create entry object
    param (
        [parameter(ValueFromPipeline)]$Message,
        [switch]$PassThru
    )
    process {
        switch ($PsItTools.DebugEnabled) {
            $true {
                switch ($PassThru) {
                    $true {
                        New-PSITLogObject 'debug' "$Message" "$env:COMPUTERNAME" "$env:USERNAME" "$env:USERDOMAIN"
                    }
                    default {
                        Write-Host "[dbg] ${Message}" -ForegroundColor Magenta
                    }
                }
            }
            default {}
        }
    }
}
function Write-PSITWarning {
    # This simple function logs warning entry to console. Use -PassThru parameter to create entry object
    param (
        [parameter(ValueFromPipeline)]$Message,
        [switch]$PassThru
    )
    process {
        switch ($PassThru) {
            $true {
                New-PSITLogObject 'warning' "$Message" "$env:COMPUTERNAME" "$env:USERNAME" "$env:USERDOMAIN"
            }
            default {
                Write-Host "[warn] ${Message}" -ForegroundColor Yellow
            }
        }
    }
}
function Write-PSITInfo {
    # This simple function logs info entry to console. Use -PassThru parameter to create entry object
    param (
        [parameter(ValueFromPipeline)]$Message,
        [switch]$PassThru
    )
    process {
        switch ($PassThru) {
            $true {
                New-PSITLogObject 'info' "$Message" "$env:COMPUTERNAME" "$env:USERNAME" "$env:USERDOMAIN"
            }
            default {
                Write-Host "${Message}"
            }
        }
    }
}
function Write-PSITError {
    # This simple function logs error entry to console. Use -PassThru parameter to create entry object
    param (
        [parameter(ValueFromPipeline)]$Message,
        [switch]$PassThru
    )
    process {
        switch ($PassThru) {
            $true {
                New-PSITLogObject 'error' "$Message" "$env:COMPUTERNAME" "$env:USERNAME" "$env:USERDOMAIN"
            }
            default {
                Write-Host "[err] ${Message}" -ForegroundColor Red
            }
        }
    }
}
function New-PSITLogObject {
    # This simple function creates log entry object
    param (
        [ValidateSet('debug', 'warning', 'error')]
        [parameter(Mandatory)]$Type,
        $Message,
        $ComputerName,
        $UserName,
        $UserDomain
    )
    $hash = [ordered]@{
        Type         = $Type
        TimeStamp    = Get-Date -f 'yyyy-dd-MM HH:mm:ss.fffff'
        Message      = $Message
        ComputerName = $ComputerName
        UserName     = $UserName
        UserDomain   = $UserDomain
    }
    New-Object psobject -Property $hash
}
function Write-PSITSeparatorLine {
    <#
    .SYNOPSIS
        Write output separator
    .DESCRIPTION
        Write output separator and eventually include message. Also can write vsts section using -AsSection parameter
    .EXAMPLE
        Write-SeparatorLine
        .EXAMPLE
        Write-SeparatorLine -Separator '*' -Count 200 -Message 'Hello there'
    .INPUTS
        System.Int32, System.String, Switch
    .OUTPUTS
        Output (if any)
    #>
    param (
        # Message to log
        $Message,
        # Separator symbol
        $Separator = '.',
        # Separator length
        [int]$Count = 80
    )

    if ($Message) {
        if ($Count -gt $Message.Length) {
            $SeparatorHalf = ((($Count - $Message.Length) - 2) / 2 -as [int])
            $Message = '{0} {1} {0}' -f ($Separator * $SeparatorHalf), $Message
            if ($Message.Length -gt $Count) {
                $Message = $Message.Substring(0, $Count)
            }
            elseif ($Message.Length -lt $Count) {
                $Message = "$Message{0}" -f ($Separator * ($Count - $Message.Length))
            }
            Write-PSITInfo "$Message"
        }
        else {
            $Message = "{0} $Message {0}" -f $Separator
            Write-PSITInfo "$Message"
        }
    }
    else {
        $Message = '{0}' -f ($Separator * $Count)
        Write-PSITInfo "$Message"
    }
}
function Show-PSITHelp {
    param (
        [switch]$Module,
        [switch]$About
    )
    if ($PSBoundParameters.Keys.Count -eq 0){
        $PSBoundParameters.Add('Base',$null)
    }
    switch ($PSBoundParameters.Keys) {
        'module' {
            $PsItTools.Help.Module
            Get-ChildItem $PsItTools.ModulePath -Directory -Exclude 'support' | ForEach-Object {
                Write-PSITInfo (" > {0}" -f $_.name)
            }
        }
        'about' {
            $PsItTools.Help.About
        }
        'base' {
            $PsItTools.Help.Base
            $PsItTools.Help.Keys | ForEach-Object {
                Write-PSITInfo (" > -{0}({1})" -f $_.Substring(0,1).ToUpper(),$_.Substring(1).ToLower())
            }
            Write-PSITInfo "Example: psithelp -m"
        }
    }
}

New-Alias -Name psithelp -Value Show-PSITHelp

Export-ModuleMember -Function '*' -Alias '*'