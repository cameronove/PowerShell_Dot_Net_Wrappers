function Get-DomainController {
    <#
    .SYNOPSIS
    Gets domain controller for supplied domain.  Does not implement a credential, so if you 
    don't have a trust it won't work on a domain.
    
    .DESCRIPTION
    If you have a trust you can retieve the DC's in a domain using System.DirectoryServices.ActiveDirectory .net object
    
    .PARAMETER domain
    The FQDN of the domain you want retrieve DCs from.
    
    .EXAMPLE
    Get-DomainController -domain mydom.local

    The above command will retrieve the domain controllers from mydom.local if you are logged in or have a trust with the domain.

    #>
    [cmdletbinding()]
    param(
        $domain = $null
    )
    if ($domain -ne $null) {
        $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain", $domain)
        $controllers = [System.DirectoryServices.ActiveDirectory.Domain]::getdomain($context).domaincontrollers
    }
    else {
        $controllers = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain().domaincontrollers
    }
    return $controllers | Select-Object Domain, @{n = 'Name'; e = {$_.Name.split('.')[0]}}, IPAddress, Roles
}  #End Get-DomainController function
