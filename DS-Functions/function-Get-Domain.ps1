function Get-Domain {
    <#
    .SYNOPSIS
    Multi-purpose function that gets a [System.DirectoryServices.ActiveDirectory] object
    Adding parameters will allow you to get 'Trusts' or 'DCs' for a domain

    .DESCRIPTION
    If no parameters are you get the ActiveDirectory object back that allows you to drill into 
    various properties.

    .PARAMETER TargetDomain
    The domain you are retrieving information on. If blank get's current domain.  Can use FQDN or NetBIOS name.
    
    .PARAMETER Credential
    A PSCredential object with rights into the 'TargetDomain'
    
    .PARAMETER Trusts
    [switch] parameter that will retrieve the Trusts from the 'TargetDomain'
    
    .PARAMETER DCs
    [switch] parameter that will retrieve the DCs from the 'TargetDomain'
    
    .PARAMETER GUID
    [switch] parameter to return the GUID of the 'TargetDomain'
    
    .EXAMPLE
    $Credential = Get-Credential 'targetdomain\username'
    Get-Domain -TargetDomain yourdomain.local -Credential $Credential -Trusts

    Will retrieve the trusts from the TargetDomain
    #> 
    [cmdletbinding()] 
    param(
        [string]$TargetDomain = '',
        [Management.Automation.PSCredential]$Credential,
        [switch]$Trusts,
        [switch]$DCs,
        [switch]$GUID
    )
    $currentDomainLDAP = (([System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain()).GetDirectoryEntry()).distinguishedName
    if ($TargetDomain -ne '') {
        if ($Credential) {            
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain", $TargetDomain, $Credential.username, $Credential.GetNetworkCredential().password)            
        }
        else {
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain", $TargetDomain)
        }    
        $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::getdomain($context)          
    }
    else {
        $CurrentDomain = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain()
        if ($Credential) {          
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain", $CurrentDomain.name, $Credential.username, $Credential.GetNetworkCredential().password)
            $Domain = [System.DirectoryServices.ActiveDirectory.Domain]::getdomain($context)
        }
        else {
            $Domain = $CurrentDomain
        }                                              
    }
    
    if ($Trusts) {return $Domain.GetAllTrustRelationships()} 
    if ($DCs) {return $Domain.DomainControllers | Select-Object name, IPAddress, Roles, @{n = 'IsGlobalCatalog'; e = {"$($_.isglobalcatalog())"}}, SiteName
    } 
    if ($GUID) {return $Domain.GetDirectoryEntry().guid}
  
    return $Domain
} # End Get-Domain function