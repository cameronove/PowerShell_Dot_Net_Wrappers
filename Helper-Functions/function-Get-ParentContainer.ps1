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
} #End Get-ParentContainer function
