<#
    All functions have their own file and have been dot-sourced into this module

    This is inline with best practices for creating unit/regression/integration testing.

    Once I've created all my testing I'll create a packaging script that will 
    'compile' all of the functions into a single file for distribution.

    In the meantime you will need to bring down the entire file structure for this repo.

    TODO:   Create more Pester tests
            Create install script
#>

<#----------Helper Functions----------#>
. '.\Helper-Functions\function-Get-NameFromDN.ps1'
. '.\Helper-Functions\function-Get-ParentContainer.ps1'
. '.\Helper-Functions\function-Get-CanonicalNameFromDN.ps1'
. '.\Helper-Functions\function-Get-SpecialFolderPath.ps1'


<#----------DirectoryService-Namespace Functions----------#>

. '.\DS-Functions\function-Get-DSObject.ps1'
. '.\DS-Functions\function-Set-DSObject.ps1'
. '.\DS-Functions\function-Get-Domain.ps1'
. '.\DS-Functions\function-Get-DomainController.ps1'
. '.\DS-Functions\function-Get-ForestTrustInfo.ps1'

<#----------Networking----------#>

. '.\Net-Functions\function-Ping-Host.ps1'

<#----------Code Analysis----------#>
. '.\CodeAnalysis-Functions\function-Find-ScriptCommand.ps1'


