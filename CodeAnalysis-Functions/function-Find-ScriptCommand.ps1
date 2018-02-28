function Find-ScriptCommand{
    <#
    .SYNOPSIS
    Before running a script you can feed the script contents into the function.  It will check to see if the commands in the script are installed or defined in the script and report the result.
    
    .DESCRIPTION
    The script accepts the path of the file you want to check and what you want to show as a result.
    You can show all commands which will have a prefix code to indicate if the command is installed, defined in the script, or not found
    The default output is to show all commands found in script with prefix code.

    
    .PARAMETER ScriptPath
    Specifies the full path to the file you want to examine.
    
    .PARAMETER Show
    Specifies what you want the results to show.
        'ShowAll' - Shows all uniqued commands found in the file with a prefix code indicating if installed, defined, or not installed.
        'ShowInstalled' - (Prefix = GC:) - Shows all commands that the 'Get-Command' cmdlet found installed in your session when checking the script.
        'ShowDefinedInTargetScript' - (Prefix = SD:) Shows all commands that are defined in your script but may not have been installed because you haven't run the script.
        'ShowNotFound' - (Prefix = NF:) - Shows all commands that either aren't installed in your session or not defined in your script - you would need to find these command definitions before running the script.
        'ShowKeyCode' - Same as 'ShowAll' with the addition of a table at the top of the results that displays the prefix codes.
    
    .EXAMPLE
    Get-ScriptCommand -ScriptPath $Path -Show ShowKeyCode
    
    #>
    [cmdletbinding()]
    param(
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$ScriptPath,
        [ValidateSet('ShowAll','ShowInstalled','ShowDefinedInTargetScript','ShowNotFound','ShowKeyCode')]
        [string]$Show = 'ShowAll'
    )

    #Get Script tokens
    $ScriptContent = Get-Content $ScriptPath
    $errors = $null
    $ScriptTokens = [System.Management.Automation.PSParser]::Tokenize($ScriptContent, [ref]$errors)

    $FoundCmds = $ScriptTokens | Where-Object{$_.type -eq 'Command'} | Select-Object -ExpandProperty content -Unique

    $MissingCmdList = [System.Collections.Generic.List[string]]::new()
    $Commands = [System.Collections.Generic.List[string]]::new()
    foreach($cmd in $FoundCmds){
        $vCmd = Get-Command $cmd -ErrorAction SilentlyContinue -ErrorVariable MissingCmds
        if($vCmd){
            $Commands.Add("GC:$($vCmd.name)")
        }
        if($MissingCmds){
            $MissingCmdList.Add($MissingCmds[0].CategoryInfo.TargetName)
        }
    }

    If($MissingCmdList.Count -gt 0){
        $CmdArgs = $ScriptTokens | Where-Object{$_.type -eq 'CommandArgument'} | Select-Object -ExpandProperty content -Unique
        foreach($cmd in $MissingCmdList){
            if($CmdArgs -match $cmd){
                $Commands.Add("SD:$cmd")
            }else{
                $Commands.Add("NF:$cmd")
            }
        }
    }

    switch($Show){
        'ShowAll'{
            return $Commands | Sort-Object
        }
        'ShowInstalled'{
            return $Commands | Where-Object{$_ -match '\AGC:'} | ForEach-Object{$_ -replace "\AGC:",""} | Sort-Object
        }
        'ShowDefinedInTargetScript'{
            return $Commands | Where-Object{$_ -match '\ASD:'} | ForEach-Object{$_ -replace "\ASD:",""} | Sort-Object
        }
        'ShowNotFound'{
            return $Commands | Where-Object{$_ -match '\ANF:'} | ForEach-Object{$_ -replace "\ANF:",""} | Sort-Object
        }
        'ShowKeyCode'{
            $Results = [System.Collections.Generic.list[PSObject]]::new()
            $KeyCodes = [PSCustomObject]@{PrefixCode = '';Description = ''}

            $KeyCodes.PrefixCode = 'GC:'
            $KeyCodes.Description = "Commands that are found by using the 'Get-Command' cmdlet and would be considered as 'Installed'."
            $Results.Add($KeyCodes.PSObject.Copy())

            $KeyCodes.PrefixCode = "SD:"
            $KeyCodes.Description = "Commands that are defined in the script you are checking - they aren't installed in the system but the script would be safe to run because they are defined in the script you plan to run."
            $Results.Add($KeyCodes.PSObject.Copy())

            $KeyCodes.PrefixCode = "NF:"
            $KeyCodes.Description = "Commands that are NOT found with the 'Get-Command' cmdlet NOR defined in the script you are running - you will need to find these command definitions before running your script."
            $Results.Add($KeyCodes.PSObject.Copy())

            $Results | Format-Table -Wrap
            return $Commands | Sort-Object
        }
    }

    return $Commands
} #End Find-ScriptCommand function