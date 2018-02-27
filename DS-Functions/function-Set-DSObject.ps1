function Set-DSObject {
    Param(
        $distinguishedName,
        $Credential,
        $ObjectAttributes
    )
    if ($ObjectAttributes -isnot [hashtable]) {
        Write-Error 'ObjectAttributes needs to be a [hashtable]'
        return
    }

    $User = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$distinguishedName", $Credential.username, $Credential.GetNetworkCredential().password)
    foreach ($Attribute in $ObjectAttributes.Keys) {
        $User.properties.$Attribute = $ObjectAttributes.$Attribute
    }
    $User.CommitChanges()
    return Invoke-Expression "`$User | Select-Object distinguishedName,$($ObjectAttributes.keys -join ',')"
} #End Set-DSObject function