# Add Powershell, Powershell (Administrator) and Cygwin to the windows folder context menus.

# Shouldn't actually need to be running 4.0+, just have these for convenience.
#requires -version 4.0
#requires -runasadministrator

$script:ContextMenuPaths = @("Registry::HKEY_CLASSES_ROOT\Directory\Background","Registry::HKEY_CLASSES_ROOT\Directory"<#,"Registry::HKEY_CLASSES_ROOT\Drive"#>)

function script:Add-Context-Entry {
    Param(
    [parameter(Mandatory=$true)]
    [String]
    $BasePath,
    [parameter(Mandatory=$true)]
    [String]
    $Name,
    [parameter(Mandatory=$true)]
    [String]
    $Label,
    [parameter(Mandatory=$true)]
    [String]
    $Command
    )

    if (Test-Path -Path "$BasePath\shell") {
        New-Item -Path "$BasePath\shell" -Name "$Name"
        Set-Item -Path "$BasePath\shell\$Name" -Value $Label
        New-ItemProperty -Path "$BasePath\shell\$Name" -Name "NoWorkingDirectory" -Value "" -PropertyType String
        # Include shield icon for runas (Admin).
        if ($Name -eq "runas") {
            New-ItemProperty -Path "$BasePath\shell\$Name" -Name "HasLUAShield" -Value "" -PropertyType String
        }
        New-Item -Path "$BasePath\shell\$Name" -Name "command"
        Set-Item -Path "$BasePath\shell\$Name\command" -Value $Command
    }
}

function script:Add-Context-Entries {
    Param(
    [parameter(Mandatory=$true)]
    [String]
    $Name,
    [parameter(Mandatory=$true)]
    [String]
    $Label,
    [parameter(Mandatory=$true)]
    [String]
    $Command
    )

    ForEach ($path in $ContextMenuPaths) {
        Add-Context-Entry $path $Name $Label $Command
    }
}

function script:Uninstall-Context-Entries {
    ForEach ($path in $ContextMenuPaths) {
        if (Test-Path -Path "$path\shell\cygwin") {
            Remove-Item -Path "$path\shell\cygwin" -Recurse -Force
        }
        if (Test-Path -Path "$path\shell\powershell") {
            Remove-Item -Path "$path\shell\powershell" -Recurse -Force
        }
        if (Test-Path -Path "$path\shell\runas") {
            Remove-Item -Path "$path\shell\runas" -Recurse -Force
        }
    }
}

function script:Get-RegistryItemString {
    [OutputType([String])]
    Param(
    [parameter(Mandatory=$true)]
    [String]
    $Path,
    [parameter(Mandatory=$true)]
    [String]
    $Property
    )

    $result = $null
    if (Test-Path -Path $Path) {
        $result = $(Get-ItemProperty -Path $Path).$Property
    }
    return $result
}

function script:Get-Cygwin-Directory {
    [OutputType([String])]

    # Maybe I just had a broken installation, but installs seem
    # to be a little inconsistent, so checking everything.
    $registryPath = "HKLM:\SOFTWARE\Cygwin\setup"
    $registryProp = "rootdir"
    $installDir = Get-RegistryItemString $registryPath $registryProp
    if (![string]::IsNullOrEmpty($installDir) -and (Test-Path -Path $installDir)) {
        return $installDir
    }

    $registryPath = "HKCU:\SOFTWARE\Cygwin\setup"
    $installDir = Get-RegistryItemString $registryPath $registryProp
    if (![string]::IsNullOrEmpty($installDir) -and (Test-Path -Path $installDir)) {
        return $installDir
    }
    
    if (Test-Path -Path "C:\cygwin\bin\mintty.exe") {
        return "C:\cygwin"
    } elseif (Test-Path -Path "C:\cygwin64\bin\mintty.exe") {
        return "C:\cygwin64"
    }

    return $null;
}

function script:Install-Context-Entries {
    # Install Cygwin entries (if Cygwin appears to be installed).
    $cygwinDir = Get-Cygwin-Directory
    if ($cygwinDir) {
        $cygwinDir = $cygwinDir -replace '\\*$', '' # Don't want any trailing slashes in command.
        $cygwinDirDoubleSlash = $cygwinDir -replace "\\", "\\"
        Add-Context-Entries "cygwin" "Open cygwin window here" "$cygwinDirDoubleSlash\\bin\\mintty.exe -i /Cygwin-Terminal.ico $cygwinDir\bin\bash.exe  -l -c ""cd \""%V\"" ; exec bash"""
    }

    # Install Powershell entries.
    Add-Context-Entries "powershell" "Open powershell window here" "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -NoExit -Command Set-Location -LiteralPath '%V'"

    # Install Powershell (Admin) entries.
    Add-Context-Entries "runas" "Open powershell window here (Admin)" "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe -NoExit -Command Set-Location -LiteralPath '%V'"
}

Uninstall-Context-Entries
Install-Context-Entries
