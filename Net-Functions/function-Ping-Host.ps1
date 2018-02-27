function Ping-Host($NetHost,$Attempts=1){
    $Collect = ''| Select-Object Host,IPAddress,Status
    $result = @()
    $ping = New-Object System.Net.NetworkInformation.Ping
    for($i=1;$i -le $Attempts;$i++){
        $ping.Send($NetHost,20) | Foreach-Object{$Collect.Host = $NetHost;$Collect.IPAddress = $_.address.IPaddressToString;$Collect.Status = $_.Status}
        $result += $Collect
    }
    return $result
} #End Ping-Host function

