function Get-DomainController($domain=$null){
    if($domain -ne $null){
        $context = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("domain",$domain)
        $controllers = [System.DirectoryServices.ActiveDirectory.Domain]::getdomain($context).domaincontrollers
    }else{
        $controllers = [System.DirectoryServices.ActiveDirectory.Domain]::getcurrentdomain().domaincontrollers
    }
    return $controllers | Select-Object Domain,@{n='Name';e={$_.Name.split('.')[0]}},IPAddress,Roles
}  #End Get-DomainController function
