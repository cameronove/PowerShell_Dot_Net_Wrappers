$here = Split-Path -Parent $MyInvocation.MyCommand.Path 

$module = 'Dot_Net_Wrappers' 


<#
    These test are desiged to test whether the code is valid and some best practices when writing code.
    Individual function tests will be built in seperate files for testing the logic of functions
#>

Describe "$module Module Tests" {

    Context "Root Module Validity" {

        It "has the root module $Module.psm1" {
            "$here\$module.psm1" | Should Exist
        }

        It "has a manifest file of $module.psd1" {
            "$here\$module.psd1" | Should Exist
            "$here\$module.psd1" | Should -FileContentMatchMultiline $module
        }

        It "$module is valid PowerShell code" {
            $PSModuleFile = Get-Content -Path "$here\$module.psm1" -ErrorAction Stop
            $errors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize($PSModuleFile, [ref]$errors)
            $errors.Count | Should Be 0
        }

        $Script:DotSourcedFiles = Get-Content "$here\$module.psm1" | Where-Object{$_ -match "\A\.\s"}
        It "All dot sourcred file paths should be surrounded by single quotes" {
            foreach($FileRef in $Script:DotSourcedFiles){
                $aPath = ($FileRef -replace "\A\.\s","").trim()
                $aPath[0] -eq "'" -and $aPath[-1] -eq "'" | Should be $true
            }
        }

        It "All dot sourced files paths should be in a '<subject>-function' root folder" {
            foreach($FileRef in $Script:DotSourcedFiles){
                $aPath = ($FileRef -replace "\A\.\s","").trim() -replace "\A\'\.\\",""
                $RootFolder = $aPath.split('\/')[0]
                $RootFolder -match "\-functions\Z" | Should be $true
            }
        }
    }

    $Script:FunctionDirectories = Get-ChildItem -Path $here -Filter *functions | Where-Object{$_.PSIsContainer} | Select-Object -ExpandProperty FullName
    foreach($Directory in $Script:FunctionDirectories){
        $ModuleFunctionFiles = Get-ChildItem -Path "$Directory\*.ps1" -Exclude *test.ps1 | Select-Object -ExpandProperty FullName
        foreach($File in $ModuleFunctionFiles){
            $Script:FileName = Split-Path $File -Leaf
            $Script:FunctionName = (Split-Path $File -Leaf) -replace '\.ps1\Z','' -replace '\Afunction\-',''
            Context "Test code validity for function: $Script:FunctionName" {

                It "$Script:FunctionName contains valid PowerShell code" {
                    $PSData = Get-Content $File -ErrorAction Stop
                    $errors = $null
                    $null = [System.Management.Automation.PSParser]::Tokenize($PSData, [ref]$errors)
                    $errors.Count | Should Be 0
                }

                It "$Script:FunctionName should have a help block" {
                    $File | Should -FileContentMatch ([regex]::Escape('<#'))
                    $File | Should -FileContentMatch ([regex]::Escape('#>'))
                }

                It "$Script:FunctionName should be an advanced function" {
                    $File | Should -FileContentMatch 'function.*\{'
                    $File | Should -FileContentMatch ([regex]::Escape('[cmdletbinding()]'))
                    $File | Should -FileContentMatch 'param.*\('
                }

                It "$Script:FunctionName should have an #End comment after the last curly bracket '}'" {
                    $File | Should -FileContentMatch "\}.*\#\s*End $Script:FunctionName function"
                }

                It "$Script:FunctionName has tests - $($File -replace '\.ps1\Z','').test.ps1 should exist" {
                    "$($File -replace '\.ps1\Z').test.ps1" | Should Exist
                }
            }
        }

    }

}