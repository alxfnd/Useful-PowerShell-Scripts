#requires -RunAsAdministrator

<#
Exit Codes:
0 = Success
1 = PS3 drivers still remain after force removal
2 = PCL6 drivers still remain after force removal
3 = PS3 and PCL6 drivers still remain after force removal
8 = Safe failure during initial cleanup stage
9 = Failure during initial cleanup stage + possibly file loss
10 = Failure during new printer installation stage
99 = explorer.exe didn't restart, remote support required
#>

# Log function for output
Function Log {
    param(
        [string]$Text
    )
    $Date = Get-Date
    $TimeStamp = "[" + $Date.ToShortDateString() + " " + $Date.TimeOfDay.ToString().Substring(0,8) + "] "
    Write-Output ($TimeStamp + $Text)
}

# Function to tidy up files copied during process
Function Cleanup {
    Sleep 2
    Remove-Item C:\tmp\PrintersConfig -Recurse -Force
    Sleep 1
    if (Test-Path C:\tmp\PrintersConfig) {
        Log "Copied files not fully removed"
    }
}

Function RollBack {
    #Import Registry
    . "C:\Windows\System32\reg.exe" import "C:\tmp\ServersExport.reg"
    #Return 3 folder
    if (Test-Path C:\tmp\PrintersConfig\Backup\3) {
        Copy-Item C:\tmp\PrintersConfig\Backup\3 $3Path.Trim("\3") -Recurse -Force -ErrorAction Ignore
    }
    #Return SERVERS folder
    if (Test-Path C:\tmp\PrintersConfig\Backup\SERVERS) {
        Copy-Item C:\tmp\PrintersConfig\Backup\SERVERS $ServerPath.Trim("\SERVERS") -Recurse -Force -ErrorAction Ignore
    }
}

# Test if this is an internal machine AND it can connect to studio storage
if (!(Test-Path ("\\"+($ENV:COMPUTERNAME).Split("-")[1]+"Software\IT_Software\PrintersConfig"))) {
    Log "Can't access PrintersConfig"
    Log "Exiting"
    Exit 8
}

# Copy PrintersConfig folder from studio storage to c:\tmp folder
# Then validate total files match
Log "Copying files from studio storage to c:\tmp"
Copy-Item ("\\"+($ENV:COMPUTERNAME).Split("-")[1]+"Software\IT_Software\PrintersConfig") "C:\tmp" -Recurse
$StorageFiles = (Get-ChildItem ("\\"+($ENV:COMPUTERNAME).Split("-")[1]+"Software\IT_Software\PrintersConfig") -Recurse).Length
$LocalFiles = (Get-ChildItem "C:\tmp\PrintersConfig" -Recurse).Length
if ($StorageFiles -ne $LocalFiles) {
    Log "Failed to copy all files."
    Cleanup
    Log "Exiting"
    Exit 8
}
Log "Copy successful"

# Run con2prt.exe with /f to remove all printer connections
Log "Removing Printer Connections"
# using -wait on con2prt.exe leaves the process hanging and gets stuck
# Sleep 5 is workaround, con2prt.exe should finish before then
Start-Process -FilePath "C:\tmp\PrintersConfig\Tools\con2prt.exe" -ArgumentList "/f" -NoNewWindow
Sleep 5
if (Get-Printer *Canon | Where {$_.type -eq 'Local'}) {
    Remove-Printer *Canon
    Remove-PrinterPort *Canon*
}
if ((Get-Printer *Canon* -ErrorAction Ignore) -or (Get-Printer *Plotter* -ErrorAction Ignore)) {
    Log "Detected connected printer. Failed to remove all."
    Cleanup
    Log "Exiting for investigation..."
    Exit 8
}else{
    Log "Printer Connections removed."
}

# Remove lingering printer drivers
if (Get-PrinterDriver *Canon* -ErrorAction Ignore) {
    Remove-PrinterDriver *Canon* -ErrorAction Ignore
}

# Export then remove Servers registry key
Log "Checking Servers Key from registry"
$ServerKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Print\Providers\Client Side Rendering Print Provider\Servers"
if (Test-Path $ServerKey\*) {
    Log "Exporting Servers Key from registry"
    # Count total items in key in case we need to roll back and validate
    $ServerKeyTotal = 0; foreach ($key in $ServerKey) { $ServerKeyTotal += (Get-ChildItem $key -Recurse).Length }
    $ExportKey = $ServerKey.replace(':','')
    #Start-Process -FilePath "C:\Windows\System32\reg" -ArgumentList "export $ExportKey C:\tmp\ServersExport.reg" -Wait -NoNewWindow
    #Used a . call, above line wasn't working - error: "Incorrect syntax"
    . "C:\Windows\System32\reg.exe" export $ExportKey "C:\tmp\ServersExport.reg" /y
    if (Test-Path C:\tmp\ServersExport.reg) {
        Log "Removing Servers key from registry"
        Get-ChildItem $ServerKey | Remove-Item -Force -Recurse -Confirm:$false
        if (Test-Path $ServerKey\*) {
            Log "Servers key is still present in regedit. Will restore to default"
            Log "Attempting reg import"
            #Start-Process -FilePath "C:\Windows\System32\reg" -ArgumentList "import C:\tmp\ServersExport.reg" -Wait -NoNewWindow
            . "C:\Windows\System32\reg.exe" import "C:\tmp\ServersExport.reg"
            $ServerKeyCheck = 0; foreach ($key in $ServerKey) { $ServerKeyCheck += (Get-ChildItem $key -Recurse).Length }
            if ($ServerKeyCheck -ne $ServerKeyTotal) {
                Log "Failed to restore import correctly."
                Cleanup
                Log "Exiting.."
                Exit 9
            }else{
                Log "Restored import correctly."
                Cleanup
                Log "Exiting.."
                Exit 8
            }
        }
    }else{
        Log "Failed to export reg files."
        Cleanup
        Log "Exiting.."
        Exit 8
    }
}

# Restart explorer to remove process connections
Log "Restarting explorer.exe"
Get-Process explorer | Stop-Process -Force
Sleep 5
$BreakoutCount = 0
while (!(Get-Process explorer -ErrorAction Ignore)) {
    Sleep 2
    Start-Process explorer
    $BreakoutCount++
    if ($BreakoutCount -eq 5) {
        Log "Can't restart explorer.exe. Manual support required"
        Cleanup
        Exit 99
    }
}

# Delete excess folders from "3" directory and "Servers" directory in "\spool"
Log "Deleting 3 and Servers folder from spool directory"
$3Path = "C:\Windows\System32\spool\drivers\x64\3"
$ServerPath = "C:\Windows\System32\spool\SERVERS"

if (Test-Path $3Path) {
    $3PathCount = (Get-ChildItem $3Path -Recurse -Force).Length
    Copy-Item $3Path C:\tmp\PrintersConfig\Backup -Recurse -Force
    # Validate backup copy was successful
    if ($3PathCount -ne ((Get-ChildItem C:\tmp\PrintersConfig\Backup\3 -Recurse -Force).Length)) {
        Log "Failed to copy $3Path correctly for restoration.`nExpected due to permissions/usage."
        Log "Continuing..."
    }
    Log "Deleting $3Path"
    Remove-Item $3Path -Recurse -Force -Confirm:$false -ErrorAction Ignore
    if (Test-Path $3Path) {
        Log "Some files in $3Path remain"
        Log "Continuing..."
    }else{
        Log "Successfully removed all files."
    }
}
if (Test-Path $ServerPath) {
    $ServerPathCount = (Get-ChildItem $ServerPath -Recurse -Force).Length
    Copy-Item $ServerPath C:\tmp\PrintersConfig\Backup -Recurse -Force -ErrorAction Ignore
    if ($serverPathCount -ne ((Get-ChildItem C:\tmp\PrintersConfig\Backup\SERVERS -Recurse -Force).Length)) {
        Log "Failed to copy $ServerPath correctly for restoration.`nExpected due to permissions/usage."
        Log "Continuing..."
    }
    Log "Deleting $ServerPath"
    Remove-Item $ServerPath -Recurse -Force -Confirm:$false -ErrorAction Ignore
    if (Test-Path $ServerPath) {
        Log "Some files in $ServerPath remain"
        Log "Continuing..."
    }else{
        Log "Successfully removed all files."
    }
}

# Find leftover driver packages installed
Log "Locating Canon PS3 driver packages"
# Locate OEM names for all PS3 installed driver packages
$PS3OEMList = Get-WindowsDriver -online | Where {$_.OriginalFileName -like '*\cns30ma64.inf'} | Select -exp Driver
if ($PS3OEMList.Count -gt 0) {
    #Remove Packages with pnputil
    foreach ($driver in $PS3OEMList) {
        Log "Uninstalling $driver"
        Start-Process -FilePath "C:\Windows\System32\pnputil" -ArgumentList "/d $driver /uninstall" -Wait -NoNewWindow
    }
}
# Some packages may still be lingering due to device conflicts. If true, force remove the package
$PS3OEMList = Get-WindowsDriver -online | Where {$_.OriginalFileName -like '*\cns30ma64.inf'} | Select -exp Driver
if ($PS3OEMList.Count -gt 0) {
    #Remove Packages with pnputil
    foreach ($driver in $PS3OEMList) {
        Log "Force removing $driver"
        Start-Process -FilePath "C:\Windows\System32\pnputil" -ArgumentList "/d $driver /uninstall /force" -Wait -NoNewWindow
    }
}

Log "Locating Canon PCL6 driver packages"
# Locate OEM names for all PCL6 installed driver packages
$PCL6OEMList = Get-WindowsDriver -online | Where {$_.OriginalFileName -like '*\cnp60ma64.inf'} | Select -exp Driver
if ($PCL6OEMList.Count -gt 0) {
    #Remove Packages with pnputil
    foreach ($driver in $PCL6OEMList) {
        Log "Uninstalling $driver"
        Start-Process -FilePath "C:\Windows\System32\pnputil" -ArgumentList "/d $driver /uninstall" -Wait -NoNewWindow
    }
}
# Some packages may still be lingering due to device conflicts. If true, force remove the package
$PCL6OEMList = Get-WindowsDriver -online | Where {$_.OriginalFileName -like '*\cnp60ma64.inf'} | Select -exp Driver
if ($PCL6OEMList.Count -gt 0) {
    #Remove Packages with pnputil
    foreach ($driver in $PCL6OEMList) {
        Log "Force removing $driver"
        Start-Process -FilePath "C:\Windows\System32\pnputil" -ArgumentList "/d $driver /uninstall /force" -Wait -NoNewWindow
    }
}

# Confirm driver packages removed
$PS3OEMList = Get-WindowsDriver -online | Where {$_.OriginalFileName -like '*\cns30ma64.inf'} | Select -exp Driver
$PCL6OEMList = Get-WindowsDriver -online | Where {$_.OriginalFileName -like '*\cnp60ma64.inf'} | Select -exp Driver

$ExitCode = 0
if ($PS3OEMList.Count -gt 0) {
    Log "PS3 exists."
    $ExitCode++
}
if ($PCL6OEMList.Count -gt 0) {
    Log "PCL6 exists"
    $ExitCode += 2
}
if ($ExitCode -gt 0) {
    Log "Discovered leftover driver packages."
    RollBack
    Cleanup
    Log "Exiting.."
    Exit $ExitCode
}

# Now install new Printer driver and configure Printer connection
# Copied items already validated
Log "All driver packages and printers removed. Now installing new configuration"
if (Test-Path "C:\tmp\PrintersConfig\CanonPS3Driver\cns30ma64.inf") {
    Log "Installing new Canon PS3 Driver"
    Start-Process -FilePath "C:\Windows\System32\pnputil" -ArgumentList "/a C:\tmp\PrintersConfig\CanonPS3Driver\CNS30MA64.INF /install" -Wait -NoNewWindow
    if (!(Test-Path "C:\Windows\System32\DriverStore\FileRepository\cns30ma64.inf_amd64_225c01f1cf876425\cns30ma64.inf")) {
        Log "Failed to install using pnputil."
        Cleanup
        Exit 10
    }
}else{
    Log "Could not find .inf file in C:\tmp\PrintersConfig\CanonPS3Driver."
    Cleanup
    Exit 10
}

# Create new printer driver
Add-PrinterDriver -Name "Canon Generic Plus PS3" -InfPath C:\Windows\System32\DriverStore\FileRepository\cns30ma64.inf_amd64_225c01f1cf876425\cns30ma64.inf
if (!(Get-PrinterDriver -Name "Canon Generic Plus PS3" -ErrorAction Ignore)) {
    Log "Failed to create printer driver."
    Cleanup
    Exit 10
}

# Variables to configure printers based on office

switch (($ENV:COMPUTERNAME).Split("-")[1]) {
    "SH" {
        $PortName = "x_CanonPort"
        $Address = "x.x.x.x"
        $PrinterName = "x_Canon"
    }
    "LN" {
        $PortName = "x_CanonPort"
        $Address = "x.x.x.x"
        $PrinterName = "x_Canon"
    }
    "GL" {
        $PortName = "x_CanonPort"
        $Address = "x.x.x.x"
        $PrinterName = "x_Canon"
    }
    "CF" {
        $PortName = "x_CanonPort"
        $Address = "x.x.x.x"
        $PrinterName = "x_Canon"
    }
    "BF" {
        $PortName = "x_CanonPort"
        $Address = "x.x.x.x"
        $PrinterName = "x_Canon"
    }
    # No default, the switch was validated at the start of the script
}

if (!(Test-Connection $Address)) {
    Log "Can't detect printer."
    Log "Installing anyway."
}

# Configure Printer Port and Printer
try { Add-PrinterPort -Name $PortName -PrinterHostAddress $Address }
catch {
    Log "Error adding printer port"
    Cleanup
    Exit 10
}
try { Add-Printer -DriverName "Canon Generic Plus PS3" -Name $PrinterName -PortName $PortName }
catch {
    if (!(Get-PrinterPort -Name $PortName -ErrorAction Ignore)) {
        Log "Error adding printer because port appeared to install, but can't be found."
        Cleanup
        Exit 10
    }else{
        Log "Error adding printer, port successfully installed"
        Cleanup
        Exit 10
    }
}

# Final check before exit
if (Get-Printer -Name $PrinterName -ErrorAction Ignore) {
    Log "Printer succesfully installed."
    Cleanup
    Exit 0
}else{
    Log "Printer appeared to install correctly, but can't be found."
    Exit 10
}
