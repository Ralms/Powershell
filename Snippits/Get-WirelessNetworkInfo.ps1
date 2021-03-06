﻿$sources = Get-ChildItem -Recurse -Path 'C:\ProgramData\Microsoft\Wlansvc\Profiles\Interfaces' -Filter '*.xml'
$wlans = @()
$sources | Foreach {
    $xml = [xml](Get-Content $_.FullName)
    $wlans += New-Object psobject -property @{
        'SSID' = $xml.WLANProfile.name
        'auth' = $xml.WLANProfile.MSM.security.authEncryption.authentication
        'enc' = $xml.WLANProfile.MSM.security.authEncryption.encryption
        'profile' = $xml.WLANProfile
    }
}
