function Get-ForestTrustInfo {
    <#
    .SYNOPSIS
    Returns information about the forest root of an AD Domain
    
    .DESCRIPTION
    Uses .net class to gather forest trust information
    
    .PARAMETER Forest
    Accepts an FQDN of the forest.
    
    .PARAMETER Credential
    Only accepts a PSCredential

    .NOTES
    Dev note:  this function needs to be properly documented both by commenting and better vetting of information used by function 
        e.g.  Setting up a validation test for $Forest would prevent certain types of errors with the bonus of helping to document,
        by means of the code itself, what is required for the $Forest parameter.
    
    #>
    [cmdletbinding()]
    param(
        $Forest,
        [PSCredential]$Credential
    )
    $TrustDirection = @{
        '1' = 'Inbound'
        '2' = 'Outbound'
        '3' = 'Bidirectional'
    }
    $SortOrder = 1
    $DomainSIDList = '' | Select-Object SourceDomain, TrustedDomain, NetBIOSName, SID, Direction, TrustIsOk, TrustStatusString, Order
    $Results = @()
    
    if ($Forest -ne '') {
        if ($Credential) {            
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Forest", $Forest, $Credential.username, $Credential.GetNetworkCredential().password)            
        }
        else {
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Forest", $Forest)
        }    
        $ForestData = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($context)          
    }
    else {
        $CurrentForest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
        if ($Credential) {          
            $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("Forest", $CurrentForest.name, $Credential.username, $Credential.GetNetworkCredential().password)
            $ForestData = [System.DirectoryServices.ActiveDirectory.Forest]::GetForest($context)
        }
        else {
            $ForestData = $CurrentForest
        }                                              
    }
    
    $ForestDC = $ForestData.Domains | Where-Object {$_.name -eq $_.forest}| ForEach-Object {$_.PdcRoleOwner.IPAddress}
    $ForestLocal = Get-WmiObject -Namespace root\MicrosoftActiveDirectory -Class Microsoft_LocalDomainInfo -ComputerName $ForestDC -Credential $Credential
    $DomainSIDList.SourceDomain = $ForestLocal.DNSname
    $DomainSIDList.TrustedDomain = "ForestRoot::$($ForestLocal.DNSname)"
    $DomainSidList.NetBIOSName = $ForestLocal.FlatName
    $DomainSIDList.SID = $ForestLocal.SID
    $DomainSIDList.Direction = 'ROOT'
    $DomainSIDList.TrustIsOk = 'N/A'
    $DomainSIDList.TrustStatusString = 'N/A'
    $DomainSIDList.Order = 0
    $Results += $DomainSIDList | Select-Object *
    
    Foreach ($Domain in $ForestData.Domains) {
        $Source = $Domain.Name
        $Order = if ($Domain.parent -eq $null) {1}else {$SortOrder += 1; $SortOrder}
        $Trusts = Get-WmiObject -Namespace root\MicrosoftActiveDirectory -Class Microsoft_DomainTrustStatus -ComputerName $Domain.PdcRoleOwner.IPAddress -Credential $Credential
        foreach ($Trust in $Trusts) {
            $DomainSIDList.SourceDomain = $Source
            $DomainSIDList.TrustedDomain = $Trust.TrustedDomain
            $DomainSIDList.NetBIOSName = $Trust.FlatName
            $DomainSIDList.SID = $Trust.SID
            $DomainSIDList.Direction = $TrustDirection.([string]$Trust.TrustDirection)
            $DomainSIDList.TrustIsOk = $Trust.TrustIsOk
            $DomainSIDList.TrustStatusString = $Trust.TrustStatusString
            $DomainSIDList.Order = $Order
            $Results += $DomainSIDList | Select-Object *
        }
    }
    return $Results | Sort-Object Order | Select-Object SourceDomain, TrustedDomain, NetBIOSName, SID, Direction, TrustIsOk, TrustStatusString
} #End Get-ForestTrustInfo function
