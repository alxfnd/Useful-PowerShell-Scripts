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
        UninstallString = $item.GetValue("UninstallString")
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
        UninstallString = $item.GetValue("UninstallString")
        RegistryPath    = $item.Name
    }
    if ($item.GetValue("DisplayName")) {
        $SoftwareObject = New-Object psobject -Property $Properties
        $SoftwareList += $SoftwareObject
    }    
}
$SoftwareList | Sort DisplayName | Out-GridView
