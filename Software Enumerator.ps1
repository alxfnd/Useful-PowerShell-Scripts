cls
$SoftwareList = @()
$6432SoftwareList = @()
$StartMenuList = @()

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

#Start Menu

$StartMenu = Get-ChildItem "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\" -Recurse | ? {$_.Name -match ".lnk"}
foreach ($link in $StartMenu) {
    $item                 = (New-Object -ComObject WScript.Shell).CreateShortcut($link.FullName) | Select -Exp TargetPath
    $StartMenuItem        = (Get-Item $item -ErrorAction Ignore)
    if ($StartMenuItem.Directory -notlike "C:\Windows\*") {
        $StartMenuItemVersion = $StartMenuItem.VersionInfo | ? {$_.FileName -like "*.exe"} | Select -Property FileVersionRaw,ProductVersionRaw,CompanyName,FileName,FileVersion,ProductVersion,FileDescription
        $StartMenuItemDate    = $StartMenuItem.CreationTime.ToShortDateString()
        $Properties = [ordered] @{
            DisplayName     = $StartMenuItemVersion.FileDescription
            Publisher       = $StartMenuItemVersion.CompanyName
            DisplayVersion  = $StartMenuItemVersion.FileVersion
            InstallLocation = $StartMenuItem.DirectoryName
            InstallDate     = $StartMenuItemDate
            DiscoveryPath   = $StartMenuItemVersion.FileName
        }
        $SoftwareObject = New-Object psobject -Property $Properties
        $SoftwareList += $SoftwareObject
        $Properties = [ordered] @{
            DisplayName       = $StartMenuItemVersion.FileDescription
            Publisher         = $StartMenuItemVersion.CompanyName
            DisplayVersion    = $StartMenuItemVersion.FileVersion
            InstallLocation   = $StartMenuItem.DirectoryName
            InstallDate       = $StartMenuItemDate
            DiscoveryPath     = $StartMenuItemVersion.FileName
            ProductVersion    = $StartMenuItemVersion.ProductVersion
            FileVersionRaw    = $StartMenuItemVersion.FileVersionRaw
            ProductVersionRaw = $StartMenuItemVersion.ProductVersionRaw
        }
        $StartMenuItemObject = New-Object psobject -Property $Properties
        $StartMenuList += $StartMenuItemObject    
    }
}

#$StartMenuList | Sort DisplayName

$SoftwareList | Sort DisplayName | Out-GridView

$SoftwareList | Sort DisplayName | Export-Csv "C:\tmp\soft.csv"
