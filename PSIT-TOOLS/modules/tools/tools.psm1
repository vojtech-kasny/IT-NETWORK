function Get-PSITSystemInfo {
    <#
    .SYNOPSIS
        Collects system info
    .DESCRIPTION
        Collects system information from local or remote system using WMI
    .EXAMPLE
        Get-PSITSystemInfo
    .EXAMPLE
        Get-PSITSystemInfo -ComputerName 'sv1' -Credential (Get-Credential)
    .INPUTS
        System.String, System.Management.Automation.PSCredential
    .OUTPUTS
        PSCustomObject
    #>
    param (
        $ComputerName = $env:COMPUTERNAME,
        [System.Management.Automation.PSCredential]$Credential,
        [ValidateSet('GB', 'MB', 'KB', 'default')]
        $DisplayUnits = 'GB'
    )
    Write-PSITDebug "Collecting data from computer '$ComputerName'"
    try {
        $ComputerSystem = Get-WmiObject win32_ComputerSystem -ComputerName $ComputerName -Credential $Credential
        $OperatingSystem = Get-WmiObject win32_OperatingSystem -ComputerName $ComputerName -Credential $Credential
        $Bios = Get-WmiObject win32_Bios -ComputerName $ComputerName -Credential $Credential
        $SystemDisk = Get-WmiObject win32_LogicalDisk -ComputerName $ComputerName -Credential $Credential -Filter "DeviceID = '$env:SystemDrive'"
    }
    catch {
        throw $_.exception.message
    }
    $SystemInfoHash = [ordered]@{
        ComputerName         = $ComputerSystem.Name
        FQDN                 = '{0}.{1}' -f $ComputerSystem.Name, $ComputerSystem.Domain
        Manufacturer         = $ComputerSystem.Manufacturer
        Model                = $ComputerSystem.Model
        "RAM($DisplayUnits)" = switch ($DisplayUnits) {
            { $_ -in 'GB', 'MB', 'KB' } { $ComputerSystem.TotalPhysicalMemory / "1${DisplayUnits}" -as [int] }
            default { $ComputerSystem.TotalPhysicalMemory }
        }
        SystemDiskLetter = $env:SystemDrive
        "SystemDiskSize($DisplayUnits)" = switch ($DisplayUnits) {
            { $_ -in 'GB', 'MB', 'KB' } { $SystemDisk.Size / "1${DisplayUnits}" -as [int] }
            default { $SystemDisk.Size }
        }
        "SystemDiskFreeSpace($DisplayUnits)" = switch ($DisplayUnits) {
            { $_ -in 'GB', 'MB', 'KB' } { $SystemDisk.FreeSpace / "1${DisplayUnits}" -as [int] }
            default { $SystemDisk.FreeSpace }
        }
        NumberOfProcessors   = $ComputerSystem.NumberOfProcessors
        NumberOfCores        = $ComputerSystem.NumberOfLogicalProcessors
        OSUptime             = $OperatingSystem.ConvertToDateTime($OperatingSystem.LocalDateTime) - $OperatingSystem.ConvertToDateTime($OperatingSystem.LastBootUpTime)
        OSLastBootupTime     = $OperatingSystem.ConvertToDateTime($OperatingSystem.LastBootUpTime)
        OSName               = $OperatingSystem.Caption
        OSVersion            = $OperatingSystem.Version
        OSInstallDate        = $OperatingSystem.ConvertToDateTime($OperatingSystem.InstallDate)
        OSArchitecture       = $OperatingSystem.OSArchitecture
        BiosVersion          = $Bios.Version
        BiosSerialNumber     = $Bios.SerialNumber
        
    }
    New-Object psobject -Property $SystemInfoHash
}
function New-PSITMessageBox {
    <#
        .Synopsis
           Creates popup window
        .DESCRIPTION
           Creates fully customizable popup window based on Windows Presentation Framework (WPF)
        .EXAMPLE
           New-TdsMessageBox -Content 'Hello from PowerShell'
        .EXAMPLE
           New-TdsMessageBox -Content 'Hello from PowerShell' -Title 'Title here'
        .EXAMPLE
           New-TdsMessageBox -Content 'Hello from PowerShell' -Title 'Title here' -TitleBackground 'AliceBlue' -TitleFontWeight Bold -TitleFontSize 18 -TitleTextForeground DarkOrange
        .EXAMPLE
           New-TdsMessageBox -Content 'Hello from PowerShell' -ContentBackground Bisque -ContentTextForeground DarkRed
        .EXAMPLE
           New-TdsMessageBox -Content 'Hello from PowerShell' -ContentBackground Bisque -ContentTextForeground DarkRed -ButtonType Cancel-TryAgain-Continue
           Use predefined buttons
        .EXAMPLE
           New-TdsMessageBox -Content 'Hello from PowerShell' -ContentBackground Bisque -ContentTextForeground DarkRed -ButtonType None -CustomButtons 'Yep','Nope','Wait...'
           Allows you to create own custom buttons
        .EXAMPLE
           New-TdsMessageBox -Content 'Hello from PowerShell' -ContentBackground Bisque -ContentTextForeground DarkRed -ButtonType OK -Timeout 15
           Waits 15 seconds before automatically closes the window
        .EXAMPLE
           New-TdsMessageBox -Content 'Hello from PowerShell' -ContentBackground Bisque -ContentTextForeground DarkRed -ButtonType OK -ReturnButton
           Returns name of the clicked button
        .EXAMPLE
        $Params = @{
            FontFamily = 'Verdana'
            Title = " Warning $([char]9888) "
            TitleFontSize = 16
            TitleTextForeground = 'black'
            TitleBackground = 'darkorange'
            ContentFontSize = 14
            ContentTextForeground = 'white'
            BorderThickness = 1
            ButtonHoverBackground='darkorange'
            ButtonTextForeground='white'
            ContentBackground='Gray'
            Timeout=10
            Sound='Windows Balloon'
            ButtonAreaBackground='Gray'
            CustomButtons='Yep','Nope','Maybe','Wait'
            ButtonType="None"
        }
           "$(Get-Service)" | New-TdsMessageBox @Params
           Fully customized popup window
        .EXAMPLE
        $Params = @{
            FontFamily = 'Verdana'
            Title = " Warning $([char]9889) "
            TitleFontSize = 16
            TitleTextForeground = 'white'
            TitleBackground = 'DarkCyan'
            ContentFontSize = 12
            ContentTextForeground = 'black'
            BorderThickness = 1
            CornerRadius=5
            ButtonHoverBackground='aquamarine'
            ButtonTextForeground='black'
            ContentBackground='white'
            Timeout=0
            Sound='Windows notify'
            ButtonAreaBackground='DarkCyan'
            CustomButtons='Accept','Reject','?'
            ButtonType="None"
            BorderBrush='DarkCyan'
            ObjectBorderBrush='DarkCyan'
            ObjectPropertyNameColor='DarkCyan'
        }
        $Answer=(Get-Process).Name | Select-Object -First 3 | New-TdsMessageBox @Params -ReturnButton
        .INPUTS
           System.String
        .OUTPUTS
           None, System.String
    #>
    [CmdletBinding()]    
    param (
        [parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]$Content, # The popup content
        [parameter()][string]$Title, # The window title
        [parameter()]
        [validateSet('OK', 'OK-Cancel', 'Abort-Retry-Ignore', 'Yes-No-Cancel', 'Yes-No', 'Retry-Cancel', 'Cancel-TryAgain-Continue', 'None')]
        [array]$ButtonType = 'OK', # Default buttons to add
        [parameter()][array]$CustomButtons, # Custom buttons to add
        [parameter()][int]$ContentFontSize = 12,
        [parameter()][int]$TitleFontSize = 16,
        [parameter()][int]$BorderThickness = 0,
        [parameter()][int]$CornerRadius = 15,
        [parameter()][int]$ShadowDepth = 4,
        [parameter()][int]$BlurRadius = 10,
        [parameter()][object]$WindowHost,
        [parameter()][int]$ObjectBorderThickness = 0,
        [parameter()][int]$ObjectBorderRadius = 0,
        [parameter()][int]$ObjectTooltipFontSize = 14,
        [parameter()][int]$Timeout, # Timeout in seconds
        [parameter()][scriptblock]$OnLoaded, # Code for Window Loaded event
        [parameter()][scriptblock]$OnClosed, # Code for Window Closed event
        [switch]$ReturnButton # Returns name of the clicked button
    )#end param

    # Dynamically populated parameters
    DynamicParam {
        # Add assemblies for use in PS Console 
        Write-PSITDebug "Adding types System.Drawing, PresentationCore"
        Add-Type -AssemblyName System.Drawing, PresentationCore
        # ContentBackground
        $ContentBackground = 'ContentBackground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ContentBackground = "White"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ContentBackground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ContentBackground, $RuntimeParameter)
        # FontFamily
        $FontFamily = 'FontFamily'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute)  
        $arrSet = [System.Drawing.FontFamily]::Families | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($FontFamily, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($FontFamily, $RuntimeParameter)
        $PSBoundParameters.FontFamily = "Segui"
        # TitleFontWeight
        $TitleFontWeight = 'TitleFontWeight'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Windows.FontWeights] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.TitleFontWeight = "Bold"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($TitleFontWeight, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($TitleFontWeight, $RuntimeParameter)
        # ContentFontWeight
        $ContentFontWeight = 'ContentFontWeight'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Windows.FontWeights] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ContentFontWeight = "Normal"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ContentFontWeight, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ContentFontWeight, $RuntimeParameter)
        # ContentTextForeground
        $ContentTextForeground = 'ContentTextForeground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ContentTextForeground = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ContentTextForeground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ContentTextForeground, $RuntimeParameter)
        # TitleTextForeground
        $TitleTextForeground = 'TitleTextForeground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.TitleTextForeground = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($TitleTextForeground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($TitleTextForeground, $RuntimeParameter)
        # BorderBrush
        $BorderBrush = 'BorderBrush'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.BorderBrush = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($BorderBrush, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($BorderBrush, $RuntimeParameter)
        # ObjectBorderBrush
        $ObjectBorderBrush = 'ObjectBorderBrush'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ObjectBorderBrush = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ObjectBorderBrush, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ObjectBorderBrush, $RuntimeParameter)
        # TitleBackground
        $TitleBackground = 'TitleBackground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.TitleBackground = "DarkGray"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($TitleBackground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($TitleBackground, $RuntimeParameter)
        # ButtonTextForeground
        $ButtonTextForeground = 'ButtonTextForeground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Brushes] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ButtonTextForeground = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ButtonTextForeground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ButtonTextForeground, $RuntimeParameter)
        # ButtonHoverBackground
        $ButtonHoverBackground = 'ButtonHoverBackground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Color] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ButtonHoverBackground = "White"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ButtonHoverBackground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ButtonHoverBackground, $RuntimeParameter)
        # ButtonAreaBackground
        $ButtonAreaBackground = 'ButtonAreaBackground'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Color] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ButtonAreaBackground = "DarkGray"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ButtonAreaBackground, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ButtonAreaBackground, $RuntimeParameter)
        # ObjectPropertyNameColor
        $ObjectPropertyNameColor = 'ObjectPropertyNameColor'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Color] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ObjectPropertyNameColor = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ObjectPropertyNameColor, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ObjectPropertyNameColor, $RuntimeParameter)
        # ObjectPropertyValueColor
        $ObjectPropertyValueColor = 'ObjectPropertyValueColor'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = [System.Drawing.Color] | Get-Member -Static -MemberType Property | Select-Object -ExpandProperty Name 
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $PSBoundParameters.ObjectPropertyValueColor = "Black"
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ObjectPropertyValueColor, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ObjectPropertyValueColor, $RuntimeParameter)
        # Sound
        $Sound = 'Sound'
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.Mandatory = $False
        #$ParameterAttribute.Position = 14
        $AttributeCollection.Add($ParameterAttribute) 
        $arrSet = (Get-ChildItem "$env:SystemDrive\Windows\Media" -Filter Windows* | Select-Object -ExpandProperty Name).Replace('.wav', '')
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)    
        $AttributeCollection.Add($ValidateSetAttribute)
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($Sound, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($Sound, $RuntimeParameter)

        return $RuntimeParameterDictionary
    }
    begin {
        if ($Host.Version.Major -lt 4) { throw "PowerShell version 4 and higher is required" }
        Add-Type -AssemblyName PresentationFramework
    }
    process {
        # Define the XAML markup
        [XML]$Xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    x:Name="Window"
    Title=""
    SizeToContent="WidthAndHeight"
    Width="950"
    WindowStartupLocation="CenterScreen"
    WindowStyle="None"
    ResizeMode="NoResize"
    AllowsTransparency="True"
    Background="Transparent"
    Opacity="1">
    <Window.Resources>
        <Style TargetType="{x:Type Button}">
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="{x:Type Button}">
                        <Border Background="{TemplateBinding Background}" BorderBrush="white" BorderThickness="0" CornerRadius="$CornerRadius">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="$($PSBoundParameters.ButtonHoverBackground)"/>
                    <Setter Property="Foreground" Value="red"/>
                </Trigger>
            </Style.Triggers>
        </Style>

        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="$($PSBoundParameters.TitleBackground)"/>
            <Setter Property="BorderBrush" Value="$($PSBoundParameters.ContentBackground)"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
        
        <Style TargetType="ToolTip">
            <Setter Property="Foreground" Value="white"/>
            <Setter Property="FontSize" Value="$ObjectTooltipFontSize"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ToolTip">
                        <Border Name="Border" BorderBrush="CadetBlue" CornerRadius="4" BorderThickness="3" Width="{TemplateBinding Width}" Height="{TemplateBinding Height}" Background="CadetBlue">
                           <ContentPresenter Margin="10,5,10,5" HorizontalAlignment="Left" VerticalAlignment="Top"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Setter Property="Content">
                <Setter.Value>
                    <ItemsControl>
                        <ItemsControl.ItemTemplate>
                            <DataTemplate>
                                <TextBlock VerticalAlignment="Center"/>
                            </DataTemplate>
                        </ItemsControl.ItemTemplate>
                    </ItemsControl>
                </Setter.Value>
            </Setter>
        </Style>

    </Window.Resources>
    <Border x:Name="MainBorder" Margin="10" CornerRadius="$CornerRadius" BorderThickness="$BorderThickness" BorderBrush="$($PSBoundParameters.BorderBrush)" Padding="10">
        <Border.Effect>
            <DropShadowEffect x:Name="DSE" Color="Black" Direction="270" BlurRadius="$BlurRadius" ShadowDepth="$ShadowDepth" Opacity="0.6" />
        </Border.Effect>
        <Border.Triggers>
            <EventTrigger RoutedEvent="Window.Loaded">
                <BeginStoryboard>
                    <Storyboard>
                        <DoubleAnimation Storyboard.TargetName="DSE" Storyboard.TargetProperty="ShadowDepth" From="0" To="$ShadowDepth" Duration="0:0:0.0" AutoReverse="False" />
                        <DoubleAnimation Storyboard.TargetName="DSE" Storyboard.TargetProperty="BlurRadius" From="0" To="$BlurRadius" Duration="0:0:0.0" AutoReverse="False" />
                    </Storyboard>
                </BeginStoryboard>
            </EventTrigger>
        </Border.Triggers>
        <Grid >
            <Border Name="Mask" CornerRadius="$CornerRadius" Background="$($PSBoundParameters.ContentBackground)" />
            <Grid x:Name="Grid" Background="$($PSBoundParameters.ContentBackground)">
                <Grid.OpacityMask>
                    <VisualBrush Visual="{Binding ElementName=Mask}"/>
                </Grid.OpacityMask>
                <StackPanel Name="StackPanel">
                    <TextBox Name="TitleBar" IsReadOnly="True" IsHitTestVisible="False" Text="$Title" Padding="20" FontFamily="$($PSBoundParameters.FontFamily)" FontSize="$TitleFontSize" Foreground="$($PSBoundParameters.TitleTextForeground)" FontWeight="$($PSBoundParameters.TitleFontWeight)" Background="$($PSBoundParameters.TitleBackground)" HorizontalAlignment="Stretch" VerticalAlignment="Center" Width="Auto" HorizontalContentAlignment="Center" BorderThickness="0"/>
                    <DockPanel MaxHeight="610" Margin="0,10,0,10">
                        <ScrollViewer IsTabStop="True" HorizontalScrollBarVisibility="Disabled" VerticalScrollBarVisibility="Auto" Width="800">
                            $(
                                if ($Content -is [string]){
                                    '<StackPanel Name="ContentHost" Margin="0,0,0,0"></StackPanel>'
                                }
                                elseif ($Content -is [array]){throw "Array object type is not supported"}
                                elseif ($Content -is [object]){
                                    @"
                            <StackPanel Name="ContentHost" Margin="0,0,0,0" Background="$($PSBoundParameters.ContentBackground)">
                                $(foreach ($member in ($Content | Get-Member -MemberType NoteProperty,Property).Name){
                                    @"
                                        <Border Margin="3,1,3,1" BorderThickness="$($ObjectBorderThickness)" BorderBrush="$($PSBoundParameters.ObjectBorderBrush)" CornerRadius="$($ObjectBorderRadius)">
                                            <StackPanel Orientation="Horizontal" Width="762">
                                                <TextBlock Text="$($member.ToUpper()) &#8226;" Padding="5,5,0,5" HorizontalAlignment="Left" FontWeight="Bold" Foreground="$($PSBoundParameters.ObjectPropertyNameColor)" FontSize="$ContentFontSize">
                                                    <TextBlock.ToolTip>
                                                        <TextBlock TextWrapping='Wrap' MaxWidth="900">$member</TextBlock>
                                                     </TextBlock.ToolTip>
                                                </TextBlock>
                                                <TextBlock Text="$($content.$member)" Padding="5,5,0,5" Foreground="$($PSBoundParameters.ObjectPropertyValueColor)" FontSize="$ContentFontSize">
                                                    <TextBlock.ToolTip>
                                                        <TextBlock TextWrapping='Wrap'>$($content.$member)</TextBlock>
                                                     </TextBlock.ToolTip>
                                                </TextBlock>
                                            </StackPanel>
                                        </Border>
"@
                                })
                            </StackPanel>
"@
                                }
                                else {throw "$($Content.GetType().Name) object type is not supported"}
                             )
                        </ScrollViewer>
                    </DockPanel>
                    <Border CornerRadius="0,0,0,0" Background="$($PSBoundParameters.ButtonAreaBackground)" BorderThickness="0">
                        <DockPanel Name="ButtonHost" LastChildFill="False" HorizontalAlignment="Center"/>
                    </Border>
                </StackPanel>
            </Grid>
        </Grid>
    </Border>
</Window>
"@
        [XML]$ButtonXaml = @"
            <Button 
                xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
                xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
                Width="Auto" 
                Height="30" 
                Background="Transparent" 
                Foreground="White" 
                BorderThickness="1" 
                Margin="10" 
                Padding="20,0,20,0" 
                HorizontalAlignment="Right" 
                Cursor="Hand"
            />
"@
        [XML]$ButtonTextXaml = @"
            <TextBlock 
                xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
                xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
                FontFamily="$($PSBoundParameters.FontFamily)" 
                FontSize="16" 
                Background="Transparent" 
                Foreground="$($PSBoundParameters.ButtonTextForeground)" 
                Padding="20,5,20,5" 
                HorizontalAlignment="Center" 
                VerticalAlignment="Center"
           />
"@
        [XML]$ContentTextXaml = @"
            <TextBlock 
                xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
                xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
                Text="$Content" 
                Foreground="$($PSBoundParameters.ContentTextForeground)" 
                DockPanel.Dock="Right" 
                HorizontalAlignment="Center" 
                VerticalAlignment="Center" 
                FontFamily="$($PSBoundParameters.FontFamily)" 
                FontSize="$ContentFontSize" 
                FontWeight="$($PSBoundParameters.ContentFontWeight)" 
                TextWrapping="Wrap" 
                Height="Auto" 
                MaxWidth="800" 
                MinWidth="50" 
                Padding="10"
            />
"@

        # Load the window from XAML
        $Window = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $xaml))
        # Custom function to add a button
        function Add-Button {
            param(
                [parameter(ValueFromPipeline = $true)]$Content,
                $HoverColor = 'orange'
            )
            process {
                $Button = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ButtonXaml))
                $ButtonText = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ButtonTextXaml))
                $ButtonText.Text = "$Content"
                $Button.Content = $ButtonText
                $Button.BorderThickness = "5"
                $Button.BorderBrush = "red"
                $global:HoverColor = $HoverColor
                $Button.Add_MouseEnter( { $This.BackGround = "$($PSBoundParameters.ButtonHoverBackground)" })
                $Button.Add_MouseLeave( { $This.Background = "#00FFFFFF" })
                $Button.Add_Click( {
                        New-Variable -Name WPFMessageBoxOutput -Value $($This.Content.Text) -Option ReadOnly -Scope script -Force
                        $Window.Close()
                    })
                $Window.FindName('ButtonHost').AddChild($Button)
            }
        }
        switch ($ButtonType) {
            'OK' { 'OK' | Add-Button -HoverColor $PSBoundParameters.ButtonHoverBackground }
            'OK-Cancel' { 'OK', 'Cancel' | Add-Button -HoverColor $PSBoundParameters.ButtonHoverBackground }
            'Abort-Retry-Ignore' { 'Abort', 'Retry', 'Ignore' | Add-Button -HoverColor $PSBoundParameters.ButtonHoverBackground }
            'Yes-No-Cancel' { 'Yes', 'No', 'Cancel' | Add-Button -HoverColor $PSBoundParameters.ButtonHoverBackground }
            'Yes-no' { 'Yes', 'No' | Add-Button -HoverColor $PSBoundParameters.ButtonHoverBackground }
            'Retry-Cancel' { 'Retry', 'Cancel' | Add-Button -HoverColor $PSBoundParameters.ButtonHoverBackground }
            'Cancel-TryAgain-Continue' { 'Cancel', 'Try Again', 'Continue' | Add-Button -HoverColor $PSBoundParameters.ButtonHoverBackground }
            { ($_ -match 'None') -and ($CustomButtons) } { foreach ($CustomButton in $CustomButtons) { $CustomButton | Add-Button -HoverColor $PSBoundParameters.ButtonHoverBackground } }
        }
        # Remove the title bar if no title is provided
        if ($Title -eq "") {
            $TitleBar = $Window.FindName('TitleBar')
            $Window.FindName('StackPanel').Children.Remove($TitleBar)
        }

        # Add Content
        if ($Content -is [String]) {
            # Replace double quotes with single to avoid quote issues in strings
            $Content = $Content.Replace('"', "'")
        
            # Use a text box for a string value...
            $ContentTextBox = [Windows.Markup.XamlReader]::Load((New-Object -TypeName System.Xml.XmlNodeReader -ArgumentList $ContentTextXaml))
            $Window.FindName('ContentHost').AddChild($ContentTextBox)
        }
        # Enable window to move when dragged
        $Window.FindName('Grid').Add_MouseLeftButtonDown( { $Window.DragMove() })
        # Activate the window on loading
        if ($OnLoaded) {
            [void]$Window.Add_Loaded( {
                    $This.Activate()
                    Invoke-Command $OnLoaded
                })
        }
        else { $Window.Add_Loaded( { $This.Activate() }) }#end else
        # Stop the dispatcher timer if exists
        if ($OnClosed) {
            $Window.Add_Closed( {
                    if ($DispatcherTimer) { $DispatcherTimer.Stop() }#end if
                    Invoke-Command $OnClosed
                })
        }
        else {
            [void]$Window.Add_Closed( {
                    if ($DispatcherTimer) { $DispatcherTimer.Stop() }#end if
                })
        }

        # If a window host is provided assign it as the owner
        if ($WindowHost) {
            $Window.Owner = $WindowHost
            $Window.WindowStartupLocation = "CenterOwner"
        }
        # If a timeout value is provided, use a dispatcher timer to close the window when timeout is reached
        if ($Timeout) {
            $Stopwatch = New-object System.Diagnostics.Stopwatch
            $TimerCode = {
                if ($Stopwatch.Elapsed.TotalSeconds -ge $Timeout) {
                    $Stopwatch.Stop()
                    $Window.Close()
                }
            }
            $DispatcherTimer = New-Object -TypeName System.Windows.Threading.DispatcherTimer
            $DispatcherTimer.Interval = [TimeSpan]::FromSeconds(1)
            $DispatcherTimer.Add_Tick($TimerCode)
            $Stopwatch.Start()
            
            $DispatcherTimer.Start()
        }
        # Play a sound
        if ($($PSBoundParameters.Sound)) {
            $SoundFile = "$env:SystemDrive\Windows\Media\$($PSBoundParameters.Sound).wav"
            $SoundPlayer = New-Object System.Media.SoundPlayer -ArgumentList $SoundFile
            $SoundPlayer.Add_LoadCompleted( {
                    $This.Play()
                    $This.Dispose()
                })
            $SoundPlayer.LoadAsync()
        }
        # Display the window
        $null = $window.Dispatcher.InvokeAsync{
            $window.ShowDialog();
        }.Wait()
        if ($PSBoundParameters.ReturnButton) { $WPFMessageBoxOutput }
    }
}
function Show-PSITGuiLog {
    param (
        [ValidateSet('error','warning','info','success')]
        $Type = 'info',
        [parameter(mandatory)]$Message
    )
    switch ($Type){
        'error' {
            $TextColor = 'red'
            $TitleBack = 'darkred'
        }
        'warning' {
            $TextColor = 'orange'
            $TitleBack = 'darkorange'
        }
        'info' {
            $TextColor = 'black'
            $TitleBack = 'lightblue'
        }
        'success' {
            $TextColor = 'green'
            $TitleBack = 'darkgreen'
        }
    }
    New-PSITMessageBox -Content $Message -Title $Type.ToUpper() -TitleBackground $TitleBack -ContentTextForeground $TextColor -CornerRadius 3 -TimeOut 10
}
workflow Invoke-PSITParallel {
    <#
    .SYNOPSIS
        Invokes multiple script blocks in parallel
    .DESCRIPTION
        The Invoke-PSITParallel invokes one or multiple script blocks on local or remote machine(s) in parallel using Windows Workflow Foundation framework
    .EXAMPLE
        Invoke-PSITParallel {Get-Host}
    .EXAMPLE
        Invoke-PSITParallel {Get-Host} -PSComputerName localhost,127.0.0.1
    .EXAMPLE
        Invoke-PSITParallel {Get-Host},{$ENV:ComputerName} -PSComputerName localhost,127.0.0.1
    .INPUTS
        ScriptBlock, ScriptBlock[]
    .OUTPUTS
        Object
    .NOTES
        PowerShell worfklow concepts: https://docs.microsoft.com/en-us/system-center/sma/overview-powershell-workflows?view=sc-sma-2019
    #>
    param (
        [parameter(Mandatory)][scriptblock[]]$ScriptBlock
    )
    foreach -Parallel ($ScriptCall in $ScriptBlock){
        $Result = InlineScript {
            Write-Verbose "Calling '$using:ScriptCall'"
            $ScriptCall = [scriptblock]::Create($using:ScriptCall)
            Invoke-Command -ScriptBlock $ScriptCall
        }
        Write-Output $Result
    }
}