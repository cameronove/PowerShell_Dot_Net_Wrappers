function Test-ScriptForAlias{
    <#
    .SYNOPSIS
    Test a script file or a script block for presence of PowerShell aliases.

    Returns True if it finds an alias

    Returns False if it doesn't find an alias
    
    .DESCRIPTION
    Created test so that I can use it in Pester tests to test that code is properly formatted
    
    .PARAMETER ScriptFile
    File name or path of script you want to test - will be used with 'Get-Content'
    
    .PARAMETER Script
    Can be a string with a set of commands or a script block
    
    .EXAMPLE
    $Script = "gc somefile.txt |?{$_ -match 'blahblahblah'} | %{write-host $_}"
    Test-ScriptForAlias -Script $Script

    The above example shows that the function can be used against a string with script commands in it.

    .EXAMPLE
    Test-ScriptForAlias -ScriptFile "env:homefolder\project\module\module1.psm1"

    You can supply the -ScriptFile parameter a path or filename to test.
    
    .NOTES
    This will be a good function to use in Pester test to ensure code is properly formatted
    #>
    [cmdletbinding()]
    param(
        [Parameter(ParameterSetName = 'File')]
        [string]$ScriptFile,
        [Parameter(ParameterSetName = 'Script')]
        [string]$Script
    )

    if($ScriptFile){
        $ScriptContent = Get-Content $ScriptFile
    }elseif($Script){
        $ScriptContent = $Script
    }else{
        throw 'Need a script to analyze...'
    }

    $errors = $null
    $ScriptTokens = [System.Management.Automation.PSParser]::Tokenize($ScriptContent, [ref]$errors)
    $Aliases = $ScriptTokens | Where-Object{$_.type -eq 'Command'} | 
        ForEach-Object{get-command $_.content -ErrorAction SilentlyContinue} | 
        Where-Object{$_.commandtype -eq 'Alias'}
    if($Aliases){
        return $true
    }else{
        return $false
    }
} #End Test-ScriptForAlias function