function Get-CanonicalNameFromDN($DN){
    $DomainParts = $DN -split ",*dc="
    $DomainLength = $DomainParts.count
    $DNParts = $DN.replace('\,',',') -split ",*..="
    $DNLength = $DNParts.count
    $CanonicalName = $($DomainParts[1..$DomainLength] -join '.') + "/" + $($DNParts[($DNLength - $DomainLength)..1] -join '/')
    return $CanonicalName
} #End Get-CanonicalNameFromDN function