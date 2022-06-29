cls
$SoftwareList = @()
$6432SoftwareList = @()

Function BetterDateFormat {
    param($date)
    if ($date.GetValue("InstallDate")) {
        $date = $date.GetValue("InstallDate")
        $date = $date.Insert(6," "); $date = $date.Insert(4," ")
        $cult = Get-Culture
        $itemdate = [datetime]::Parse($date,$cult)
        return $itemdate.ToShortDateString()
    }else{
        return ""
    }
}

#Registry Hives

$uninstallhive = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
$6432UninstallHive = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"

$list = Get-ChildItem $uninstallhive
foreach ($a in $list) {
    $item = Get-Item "HKLM:$a"
    $Properties = [ordered] @{
        DisplayName     = $item.GetValue("DisplayName")
        Publisher       = $item.GetValue("Publisher")
        DisplayVersion  = $item.GetValue("DisplayVersion")
        InstallLocation = $item.GetValue("InstallLocation")
        InstallDate     = BetterDateFormat -date $item
        RegistryPath    = $item.Name
    }
    if ($item.GetValue("DisplayName")) {
        $SoftwareObject = New-Object psobject -Property $Properties
        $SoftwareList += $SoftwareObject
    }    
}

$list = Get-ChildItem $6432uninstallhive
foreach ($a in $list) {
    $item = Get-Item "HKLM:$a"
    $Properties = [ordered] @{
        DisplayName     = $item.GetValue("DisplayName")
        Publisher       = $item.GetValue("Publisher")
        DisplayVersion  = $item.GetValue("DisplayVersion")
        InstallLocation = $item.GetValue("InstallLocation")
        InstallDate     = BetterDateFormat -date $item
        RegistryPath    = $item.Name
    }
    if ($item.GetValue("DisplayName")) {
        $SoftwareObject = New-Object psobject -Property $Properties
        $SoftwareList += $SoftwareObject
    }    
}
$SoftwareList

#Start Menu

$StartMenu = Get-ChildItem "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\" -Recurse | ? {$_.Name -match ".lnk"}
foreach ($link in $StartMenu) {
    $exe = (New-Object -ComObject WScript.Shell).CreateShortcut($link.FullName) | Select -Exp TargetPath
    foreach ($item in $exe) {
        (Get-Item $item).VersionInfo | Select -Property FileVersionRaw,ProductVersionRaw,CompanyName,FileName,FileVersion,ProductVersion
    }
}