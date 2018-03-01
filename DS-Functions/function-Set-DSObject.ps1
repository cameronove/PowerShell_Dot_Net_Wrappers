function Set-DSObject {
    <#
    .SYNOPSIS
    Used to set properties on AD objects
    
    .DESCRIPTION
    Wrapped a set function around .net because it was much faster than Quest cmdlets and somewhat faster than
    MS ActiveDirectory cmdlets
    
    .PARAMETER distinguishedName
    Accepts the distinguishedName of the object you want to set properties on.
    
    .PARAMETER Credential
    Requires a PSCredential object with Admin access into the domain where the object resides
    
    .PARAMETER ObjectAttributes
    Requires the [hashtable]: Keys equaling attribute names and value equaling value of attribute.
    
    #>
    [cmdletbinding()]
    Param(
        [string]$distinguishedName,
        [PSCredential]$Credential,
        [hashtable]$ObjectAttributes
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