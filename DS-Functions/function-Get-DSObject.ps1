function Get-DSObject {
    <#
    .SYNOPSIS
        Get .Net DirectoryServices Object
    .DESCRIPTION
        Uses .Net System.DirectoryServices.DirectorySearcher to get properties of a user.
        It can be used against any domain as long as proper credentials are provided.
        Credentials are always needed even if searching default domain. (may change when I have time)
    .PARAMETER Identity
        "Supports * wild card, DNs, Email Addresses, first and last names, or object names"
        If useing a distinguishedName there is no need to supply the SearchRoot parameter.
    .PARAMETER SearchRoot
        It will become the ADsPath to the OU you want to search
            For specific domains it will support the following formats:
                distinugishedName - i.e. "ou=users,ou=location,dc=some,dc=domain,dc=name"
                Canonical         - i.e. "some.domain.name/location/users"
    
            If you want to search an entire domain then just provide the domain name 
            in the following formats:
                distinguishedName - i.e. "dc=some,dc=domain,dc=name
                FQDN              - i.e. "some.domain.name"
            
            If the 'Identity' parameter is supplied in the form of a distinguishedName then
            the SearchRoot parameter is not used.
    .PARAMETER Credential
        Is needed and needs to be a PSCredential
    .PARAMETER Type
        Defaults to User and can be overridden with a value from the validated set.
        This parameter is only used if no filter is supplied.
    .PARAMETER Filter
        Not required.  
        If supplied it needs to be an LDAP filter.  It will override the default filter.
        If not supplied a default LDAP is created based on Identity and SearchRoot parameters.
        If using this parameter then the parameter 'Type' will not be used.
    .PARAMETER Properties
        Not required it will return 'distinguishedName' as the default property.
        Can be overridden with any AD Attribute displayName property.
        Can be either a comma delimited string or an array.
        If a single value is entered no need for delimiter or array.
    .EXAMPLE
       .
    .NOTES
        Author: Cameron Ove
        Date  : May 23, 2014    
    #>
        
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        $Identity,
        $SearchRoot = $null,
        [Parameter(Mandatory = $true)]
        $Credential,
        [ValidateSet('User', 'Contact', 'Group', 'OrganizationalUnit')]
        $Type = 'User',
        $Filter = $null,
        [ValidateSet('OneLevel', 'Subtree')]
        $SearchScope = 'Subtree',
        $Properties = 'distinguishedName'
    )
    function Convertfrom-CanonicalName {
        [CmdletBinding()]
        param($Name)
        $CanonicalParts = $Name.split('/')
        Write-Verbose "Canonical parts 0 (domain):  $($CanonicalParts[0])"
        $DomainDN = (".$($CanonicalParts[0])".split('.') -join ',DC=').trimstart(',')
        Write-Verbose "Canonical parts converted to DN:  $DomainDN"
        $PathDN = 'OU=' + ($CanonicalParts[$CanonicalParts.length..1] -join ',OU=').trimstart(',')
        Write-Verbose "Path DN established as:  $($PathDN + ',' + $DomainDN)"
        return $PathDN + ',' + $DomainDN
    }
    
    #Get ADsPath to search
    if ($Identity -match '=') {
        $Search = Get-NameFromDN $Identity
        $SearchRoot = Get-ParentContainer $Identity
    }
    else {
        $Search = $Identity
    }
    if ($SearchRoot -match '\.' -and $SearchRoot -match '\/') {
        $ADsPath = "LDAP://" + (Convertfrom-CanonicalName $SearchRoot)
    }
    elseif ($SearchRoot -match '\.' -and $SearchRoot -notmatch '\/') {
        $ADsPath = "LDAP://" + (".$($SearchRoot)".split('.') -join ',DC=').trimstart(',')
    }
    elseif ($SearchRoot -match 'dc=') {
        $ADsPath = "LDAP://" + $SearchRoot
    }
    else {
        Write-Error -Message "SearchRoot: <$SearchRoot> is not a recognized Domain path."
        return
    }
    Write-Verbose "ADsPath is:  $ADsPath"
    
    #Make sure a PSCredential object is passed
    if ($Credential -isnot [PSCredential]) {
        Write-Verbose -Message "No valid credential was supplied."
        return
    }
    
    #Set default filter if one is not provided.
    if (-not $Filter) {
        if ($Identity -match '\*') {
            $Filter = "(objectClass=$Type)"
        }
        else {
            $Filter = "(&(objectClass=$Type)(|(samaccountname=*$Search*)(givenName=*$Search*)(sn=*$Search*)(displayName=*$search*)(proxyaddresses=*$search*)(name=*$search*)))"
        }
    }
        
    
    Write-Verbose "Set Filter to:  $Filter"
    
    #Convert Properties into an array.
    if ($Properties -isnot [array]) {
        Write-Verbose "Properties = $Properties"
        $ReturnProperties = $Properties.split(',')
    }
    else {
        Write-Verbose "Properties = $Properties"
        $ReturnProperties = $Properties
    }
    
    #Build ADSISearcher
    $DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry($ADsPath, $Credential.username, $Credential.GetNetworkCredential().password)
    $DirectorySearcher = New-Object System.DirectoryServices.DirectorySearcher($DirectoryEntry, $Filter)
    Write-Verbose "Checking Filter again:  $($DirectorySearcher.Filter)"
    $ReturnProperties | Foreach-Object {
        Write-Verbose "Adding property:  $_"
        $null = $DirectorySearcher.PropertiesToLoad.Add("$_")
    }
    
    #Set search scope:
    $DirectorySearcher.SearchScope = $SearchScope
    Write-Verbose "Set searchScope to:  $($DirectorySearcher.SearchScope)"
    
    #Set additional ADSISearcher properties:
    $DirectorySearcher.PageSize = 200
    
    #Go get the data 
    try {
        Write-Verbose "Path:  $($DirectorySearcher.SearchRoot.Path)"
        $Result = $DirectorySearcher.FindAll() #Will always do a findall() because return properties can be controlled. .findone() returns all properties
    }
    catch {
        $SearchAttributes = @{ADsPath = $ADsPath; Filter = $Filter}
        $EventMsg = "Get-DSObject Error:  Error finding user in home AD with Get-DSObject cmdlet`n" + $SearchAttributes + "`n" + $error[0]
        Write-Verbose $EventMsg
        return
    }
    
    if ($Result) {
        return $Result | Foreach-Object {[PSCustomObject]$_.Properties} | Select-Object $ReturnProperties
    }
} #End Get-DSObject Function
    