<#
    This module demonstrates how to wrap .net cleases into PowerShell functions
    As I add to this module I'll reference which classes I'm demonstrating.

    Classes so far (with functions using class listed below class:
    Directory Services:
        System.DirectoryServices.DirectoryEntry
            Get-DSObject
            Set-DSObject
        System.DirectoryServices.DirectorySearcher
            Get-DSObject
        System.DirectoryServices.ActiveDirectory.Domain
            Get-Domain
            Get-DomainController
        System.DirectoryServices.ActiveDirectory.Forest
            Get-ForestTrustInfo
    
    Networking:
        System.Net.NetworkInformation.Ping
            Ping-Host


#>

<#----------Helper Functions----------#>
function Get-NameFromDN([string]$DN){
    return ($DN.replace('\,',',') -split ",*..=")[1]
} 

function Get-ParentContainer{
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        $DN,
        [ValidateSet('distinguishedName','CannonicalName')]
        $ReturnFormat = 'distinguishedName'
    )
    [arraylist]$elem = $DN.split(',')
    <#
        ActiveDirectory allows commas in the names of objects i.e. 'CN=LastName\, FirstName'
        The following drops the first element in the $elem array regardless of name and makes 
        the first elemet in $ParentContainer the next element in $elem that starts with cn= or ou=. 
        This works whether there is a comma in the first name or not.
    #>
    $ParentContainer = $elem[$elem.IndexOf(($elem[1..$elem.Count] -match 'ou=|cn=')[0])..$elem.Count] -join ','
    if($ReturnFormat -match 'distinguishedName'){
        return $ParentContainer
    }else{
        return Get-CanonicalNameFromDN $ParentContainer
    }
}

function Get-CanonicalNameFromDN($DN){
    $DomainParts = $DN -split ",*dc="
    $DomainLength = $DomainParts.count
    $DNParts = $DN.replace('\,',',') -split ",*..="
    $DNLength = $DNParts.count
    $CanonicalName = $($DomainParts[1..$DomainLength] -join '.') + "/" + $($DNParts[($DNLength - $DomainLength)..1] -join '/')
    return $CanonicalName
}
<#----------End Helper Functions----------#>

<#----------DirectoryService-Namespace Functions----------#>
function Get-DSObject{
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
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullOrEmpty()]
        $Identity,
        $SearchRoot = $null,
        [Parameter(Mandatory=$true)]
        $Credential,
        [ValidateSet('User','Contact','Group','OrganizationalUnit')]
        $Type='User',
        $Filter=$null,
        [ValidateSet('OneLevel','Subtree')]
        $SearchScope = 'Subtree',
        $Properties='distinguishedName'
    )
    function Convertfrom-CanonicalName{
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
    if($Identity -match '='){
        $Search = Get-NameFromDN $Identity
        $SearchRoot = Get-ParentContainer $Identity
    }else{
        $Search = $Identity
    }
    if($SearchRoot -match '\.' -and $SearchRoot -match '\/'){
        $ADsPath = "LDAP://" + (Convertfrom-CanonicalName $SearchRoot)
    }elseif($SearchRoot -match '\.' -and $SearchRoot -notmatch '\/'){
        $ADsPath = "LDAP://" + (".$($SearchRoot)".split('.') -join ',DC=').trimstart(',')
    }elseif($SearchRoot -match 'dc='){
        $ADsPath = "LDAP://" + $SearchRoot
    }else{
        Write-Error -Message "SearchRoot: <$SearchRoot> is not a recognized Domain path."
        return
    }
    Write-Verbose "ADsPath is:  $ADsPath"

    #Make sure a PSCredential object is passed
    if($Credential -isnot [PSCredential]){
        Write-Verbose -Message "No valid credential was supplied."
        return
    }

    #Set default filter if one is not provided.
    if(-not $Filter){
        if($Identity -match '\*'){
            $Filter = "(objectClass=$Type)"
        }else{
            $Filter = "(&(objectClass=$Type)(|(samaccountname=*$Search*)(givenName=*$Search*)(sn=*$Search*)(displayName=*$search*)(proxyaddresses=*$search*)(name=*$search*)))"
        }
    }
    

    Write-Verbose "Set Filter to:  $Filter"

    #Convert Properties into an array.
    if($Properties -isnot [array]){
        Write-Verbose "Properties = $Properties"
        $ReturnProperties = $Properties.split(',')
    }else{
        Write-Verbose "Properties = $Properties"
        $ReturnProperties = $Properties
    }

    #Build ADSISearcher
    $DirectoryEntry = New-Object System.DirectoryServices.DirectoryEntry($ADsPath, $Credential.username, $Credential.GetNetworkCredential().password)
    $DirectorySearcher = New-Object System.DirectoryServices.DirectorySearcher($DirectoryEntry,$Filter)
    Write-Verbose "Checking Filter again:  $($DirectorySearcher.Filter)"
    $ReturnProperties | %{
        Write-Verbose "Adding property:  $_"
        $null = $DirectorySearcher.PropertiesToLoad.Add("$_")
    }

    #Set search scope:
    $DirectorySearcher.SearchScope = $SearchScope
    Write-Verbose "Set searchScope to:  $($DirectorySearcher.SearchScope)"

    #Set additional ADSISearcher properties:
    $DirectorySearcher.PageSize = 200

    #Go get the data 
    try{
        Write-Verbose "Path:  $($DirectorySearcher.SearchRoot.Path)"
        $Result = $DirectorySearcher.FindAll() #Will always do a findall() because return properties can be controlled. .findone() returns all properties
    }catch{
        $SearchAttributes = @{ADsPath = $ADsPath;Filter = $Filter}
        $EventMsg = "Get-DSObject Error:  Error finding user in home AD with Get-DSObject cmdlet`n" + $SearchAttributes + "`n" + $error[0]
        Write-Verbose $EventMsg
        return
    }

    if($Result){
        return $Result | %{[PSCustomObject]$_.Properties} | select $ReturnProperties
    }
}

function Set-DSObject{
    Param(
        $distinguishedName,
        $Credential,
        $ObjectAttributes
    )
    if($ObjectAttributes -isnot [hashtable]){
        Write-Error 'ObjectAttributes needs to be a [hashtable]'
        return
    }

    $User = New-Object System.DirectoryServices.DirectoryEntry("LDAP://$distinguishedName",$Credential.username,$Credential.GetNetworkCredential().password)
    foreach($Attribute in $ObjectAttributes.Keys){
        $User.properties.$Attribute = $ObjectAttributes.$Attribute
    }
    $User.CommitChanges()
    return Invoke-Expression "`$User | select distinguishedName,$($ObjectAttributes.keys -join ',')"
}

function Get-Domain{  
    param(
            [string]$TargetDomain='',
            [Management.Automation.PSCredential]$Credential,
            [switch]$Trusts,
            [switch]$DCs,
            [switch]$GUID
          )
    $currentDomainLDAP = (([System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain()).GetDirectoryEntry()).distinguishedName
    if($TargetDomain -ne ''){
        if($Credential){            
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$TargetDomain,$Credential.username,$Credential.GetNetworkCredential().password)            
        }else{
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$TargetDomain)
        }    
        $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::getdomain($context)          
    }else{
        $CurrentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain()
        if($Credential){          
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$CurrentDomain.name,$Credential.username,$Credential.GetNetworkCredential().password)
            $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::getdomain($context)
        }else{
            $Domain = $CurrentDomain
        }                                              
    }
    
    if($Trusts){return $Domain.GetAllTrustRelationships()} 
    if($DCs){return $Domain.DomainControllers | select name,IPAddress,Roles,@{n='IsGlobalCatalog';e={"$($_.isglobalcatalog())"}},SiteName} 
    if($GUID){return $Domain.GetDirectoryEntry().guid}
  
    return $Domain
}

function Get-DomainController($domain=$null){
    if($domain -ne $null){
        $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$domain)
        $controllers = [System.DirectoryServices.ActiveDirectory.Domain]::getdomain($context).domaincontrollers
    }else{
        $controllers = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain().domaincontrollers
    }
    return $controllers | select Domain,@{n='Name';e={$_.Name.split('.')[0]}},IPAddress,Roles
}  

function Get-ForestTrustInfo($Forest,$Credential=$null){
    $TrustDirection = @{
        '1' = 'Inbound'
        '2' = 'Outbound'
        '3' = 'Bidirectional'
    }
    $SortOrder = 1
    $DomainSIDList = '' | select SourceDomain,TrustedDomain,NetBIOSName,SID,Direction,TrustIsOk,TrustStatusString,Order
    $Results = @()
    
    if($Forest -ne ''){
        if($Credential){            
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Forest",$Forest,$Credential.username,$Credential.GetNetworkCredential().password)            
        }else{
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Forest",$Forest)
        }    
        $ForestData = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($context)          
    }else{
        $CurrentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
        if($Credential){          
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Forest",$CurrentForest.name,$Credential.username,$Credential.GetNetworkCredential().password)
            $ForestData = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($context)
        }else{
            $ForestData = $CurrentForest
        }                                              
    }
    
    $ForestDC = $ForestData.Domains | ?{$_.name -eq $_.forest}|%{$_.PdcRoleOwner.IPAddress}
    $ForestLocal = Get-WmiObject -Namespace root\MicrosoftActiveDirectory -Class Microsoft_LocalDomainInfo -ComputerName $ForestDC -Credential $Credential
    $DomainSIDList.SourceDomain = $ForestLocal.DNSname
    $DomainSIDList.TrustedDomain = "ForestRoot::$($ForestLocal.DNSname)"
    $DomainSidList.NetBIOSName = $ForestLocal.FlatName
    $DomainSIDList.SID = $ForestLocal.SID
    $DomainSIDList.Direction = 'ROOT'
    $DomainSIDList.TrustIsOk = 'N/A'
    $DomainSIDList.TrustStatusString = 'N/A'
    $DomainSIDList.Order = 0
    $Results += $DomainSIDList | select *
    
    Foreach($Domain in $ForestData.Domains){
        $Source = $Domain.Name
        $Order = if($Domain.parent -eq $null){1}else{$SortOrder += 1;$SortOrder}
        $Trusts = Get-WmiObject -Namespace root\MicrosoftActiveDirectory -Class Microsoft_DomainTrustStatus -ComputerName $Domain.PdcRoleOwner.IPAddress -Credential $Credential
        foreach($Trust in $Trusts){
            $DomainSIDList.SourceDomain = $Source
            $DomainSIDList.TrustedDomain = $Trust.TrustedDomain
            $DomainSIDList.NetBIOSName = $Trust.FlatName
            $DomainSIDList.SID = $Trust.SID
            $DomainSIDList.Direction = $TrustDirection.([string]$Trust.TrustDirection)
            $DomainSIDList.TrustIsOk = $Trust.TrustIsOk
            $DomainSIDList.TrustStatusString = $Trust.TrustStatusString
            $DomainSIDList.Order = $Order
            $Results += $DomainSIDList | select *
        }
    }
    return $Results | sort Order | select SourceDomain,TrustedDomain,NetBIOSName,SID,Direction,TrustIsOk,TrustStatusString
}

<#----------End DirectoryService-Namespace Functions---------#>

<#----------Networking----------#>
function Ping-Host($NetHost,$Attempts=1){
    $Collect = ''|select Host,IPAddress,Status
    $result = @()
    $ping = New-Object System.Net.NetworkInformation.Ping
    for($i=1;$i -le $Attempts;$i++){
        $ping.Send($NetHost,20) | %{$Collect.Host = $NetHost;$Collect.IPAddress = $_.address.IPaddressToString;$Collect.Status = $_.Status}
        $result += $Collect
    }
    return $result
}

