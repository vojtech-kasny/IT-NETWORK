######################################################################################
# This is PSIT-TOOLS configuration file
# Do NOT manipulate with the content without approval of the developers of this tool
# This config is loaded to global variable $PsItTools
######################################################################################
@{
    # Logging option
    DebugEnabled      = $true #$true|$false
    DebugLevel        = 1 #1|2|3

    # Common
    Version = '1.0.0.1'
    ShowMDHelp = $true #$true|$false
    ModulePath = $null #this value is filled by loader
    Help = $null #this value is filled by loader

    # Console option
    EnableCustomTitle = $true #$true|$false
    BaseTitle = 'PS-IT Tools'
}