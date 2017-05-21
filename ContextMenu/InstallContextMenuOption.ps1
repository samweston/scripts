# Add Powershell, Powershell (Administrator) and Cygwin to the windows folder context menus.

#requires -version 4.0
#requires -runasadministrator

Param (
    [ValidateSet("cygwin", "powershelladmin", "bashonwindows")]
    [Parameter(Mandatory=$true)]
    [String] $ItemType,
    [Switch] $Uninstall
)

$script:ContextMenuPaths = @("Registry::HKEY_CLASSES_ROOT\Directory\Background","Registry::HKEY_CLASSES_ROOT\Directory"<#,"Registry::HKEY_CLASSES_ROOT\Drive"#>)

function Install-Context-Entry {
    Param(
        [parameter(Mandatory=$true)]
        [String] $BasePath,
        [parameter(Mandatory=$true)]
        [String] $Name,
        [parameter(Mandatory=$true)]
        [String] $Label,
        [parameter(Mandatory=$true)]
        [String] $Command,
        [parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [String] $Icon
    )

    if (Test-Path -Path "$BasePath\shell") {
        New-Item -Path "$BasePath\shell" -Name "$Name" | Out-Null
        Set-Item -Path "$BasePath\shell\$Name" -Value $Label | Out-Null
        New-ItemProperty -Path "$BasePath\shell\$Name" -Name "NoWorkingDirectory" -Value "" -PropertyType String | Out-Null
        # Include shield icon for runas (Admin).
        if ($Name -eq "runas") {
            New-ItemProperty -Path "$BasePath\shell\$Name" -Name "HasLUAShield" -Value "" -PropertyType String | Out-Null
        }
        New-Item -Path "$BasePath\shell\$Name" -Name "command" | Out-Null
        Set-Item -Path "$BasePath\shell\$Name\command" -Value $Command | Out-Null
        if ($Icon) {
            New-ItemProperty -Path "$BasePath\shell\$Name" -Name "Icon" -Value $Icon -PropertyType String | Out-Null
        }
    }
}

function Install-Context-Entries {
    Param(
        [parameter(Mandatory=$true)]
        [String] $Name,
        [parameter(Mandatory=$true)]
        [String] $Label,
        [parameter(Mandatory=$true)]
        [String] $Command,
        [parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [String] $Icon
    )

    ForEach ($path in $ContextMenuPaths) {
        Install-Context-Entry -BasePath $path -Name $Name -Label $Label -Command $Command -Icon $Icon
    }
}

function Uninstall-Context-Entries {
    Param(
        [parameter(Mandatory=$true)]
        [String] $Name
    )
    ForEach ($path in $ContextMenuPaths) {
        if (Test-Path -Path "$path\shell\$Name") {
            Remove-Item -Path "$path\shell\$Name" -Recurse -Force
        }
    }
}

function Get-RegistryItemString {
    [OutputType([String])]
    Param(
        [parameter(Mandatory=$true)]
        [String] $Path,
        [parameter(Mandatory=$true)]
        [String] $Property
    )

    $result = $null
    if (Test-Path -Path $Path) {
        $result = $(Get-ItemProperty -Path $Path).$Property
    }
    return $result
}

function New-Config {
    Param (
        [parameter(Mandatory=$true)]
        [String] $Name,
        [parameter(Mandatory=$true)]
        [String] $Label,
        [parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [String] $Command,
        [parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [String] $Icon
    )
    return New-Object -TypeName PSObject -Property @{
        "Name" = $Name;
        "Label" = $Label;
        "Command" = $Command;
        "Icon" = $Icon;
    }
}

function Get-Cygwin-Config {
    # Maybe I just had a broken installation, but installs seem
    # to be a little inconsistent, so checking everything.
    $registryPath = "HKLM:\SOFTWARE\Cygwin\setup"
    $registryProp = "rootdir"
    $installDir = Get-RegistryItemString -Path $registryPath -Property $registryProp
    
    $directory = $null

    if (![string]::IsNullOrEmpty($installDir) -and (Test-Path -Path $installDir)) {
        $directory = $installDir
    }

    if (!$directory) {
        $registryPath = "HKCU:\SOFTWARE\Cygwin\setup"
        $installDir = Get-RegistryItemString -Path $registryPath -Property $registryProp
        if (![string]::IsNullOrEmpty($installDir) -and (Test-Path -Path $installDir)) {
            $directory = $installDir
        }
    }

    if (!$directory) {
        if (Test-Path -Path "C:\cygwin\bin\mintty.exe") {
            $directory = "C:\cygwin"
        } elseif (Test-Path -Path "C:\cygwin64\bin\mintty.exe") {
            $directory = "C:\cygwin64"
        }
    }

    $name = "cygwin"
    $label = "Open cygwin window here"
    $command = $null

    if ($directory) {
        $directory = $directory -replace "\\*$", "" # Don't want any trailing slashes in command.
        $directoryDblSlash = $directory -replace "\\", "\\"
        $command = "$directoryDblSlash\\bin\\mintty.exe -i /Cygwin-Terminal.ico $directory\bin\bash.exe  -l -c ""cd \""%V\"" ; exec bash"""
    }

    return New-Config -Name $name -Label $label -Command $command -Icon $null
}

function Get-PowershellAdmin-Config {
    $name = "runas"
    $label = "Open powershell window here (Admin)"
    $command = "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -NoExit -Command Set-Location -LiteralPath '%V'"

    return New-Config -Name $name -Label $label -Command $command -Icon $null
}

function Get-BashOnWindows-Config {
    $name = "bashonwindows"
    $label = "Open Bash on Windows here"
    $command = $null
    $icon = $null

    if (Test-Path "C:\Windows\System32\bash.exe") {
        $command = "C:\\Windows\\System32\\cmd.exe /c cd ""%V"" && C:\\Windows\\System32\\bash.exe"
    }

    if (Test-Path "$($env:LOCALAPPDATA)\lxss\bash.ico") {
        $icon = "$($env:LOCALAPPDATA)\lxss\bash.ico" -replace "\\", "\\"
    }

    return New-Config -Name $name -Label $label -Command $command -Icon $icon
}

if ($ItemType -eq "cygwin") {
    $config = Get-Cygwin-Config
} elseif ($ItemType -eq "powershelladmin") {
    $config = Get-PowershellAdmin-Config
} elseif ($ItemType -eq "bashonwindows") {
    $config = Get-BashOnWindows-Config
}

# Uninstall first
if ($config.Name) {
    Uninstall-Context-Entries -Name $config.Name
} else {
    Write-Error "Could not set up config for uninstall"
}

if (!$Uninstall) {
    if ($config.Name -and $config.Label -and $config.Command) {
        Install-Context-Entries -Name $config.Name -Label $config.Label -Command $config.Command -Icon $config.Icon
    } else {
        Write-Error "Could not set up config for install"
    }
}

