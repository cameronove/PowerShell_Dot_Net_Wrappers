function Get-SpecialFolderPath {
    [cmdletbinding()]
    param(
        $SpecialFolderName
    )

    $spf = [System.Environment+SpecialFolder]

    if ($SpecialFolderName) {
        $spfmatches = $spf.GetEnumValues()|
        Where-Object {$_ -match $SpecialFolderName} |
        Select-Object   @{n = 'SpecialFolderName'; e = {"$($_)"}},
                        @{n = 'SpecialFolderNumber'; e = {"$($_.value__)"}},
                        @{n = 'SpecialFolderPath';e={"$([System.Environment]::GetFolderPath($_))"}}

        if ($spfmatches.count -eq 1) {
            $Selection = $spfmatches
        }
        elseif ($spfmatches.count -gt 1) {
            $Selection = $spfmatches | Out-GridView -Title 'Multiple folders matched special folder name - please select one.' -PassThru
        }
    }

    if (-not ($SpecialFolderName -or $Selection)) {
        $Selection = $spf.GetEnumValues() |
        Select-Object   @{n = 'SpecialFolderName'; e = {"$($_)"}},
                        @{n = 'SpecialFolderNumber'; e = {"$($_.value__)"}},
                        @{n = 'SpecialFolderPath';e={"$([System.Environment]::GetFolderPath($_))"}} |
        Out-GridView -Title 'Please select special folder' -PassThru
    }

    if ($Selection) {
        return $Selection
    }
    else {
        return
    }
}
