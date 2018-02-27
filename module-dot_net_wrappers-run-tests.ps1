$naPath = 'C:\code\PS\Public\PowerShell_Dot_Net_Wrappers'
Set-Location $naPath

Import-Module Pester

Invoke-Pester "$naPath\dot_net_wrappers.v0.1.0.code-validity.tests.ps1"

