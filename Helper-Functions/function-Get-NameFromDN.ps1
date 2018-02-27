function Get-NameFromDN([string]$DN){
    return ($DN.replace('\,',',') -split ",*..=")[1]
} #End Get-NameFromDN function