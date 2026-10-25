<#
  Integrit MON-SECEVT agent script (Zabbix agent 2 UserParameter). Read-only, PowerShell 5.1+, runs as LocalSystem.
  Counts failed logons (Security 4625) in the last N minutes, so Zabbix stores counts, not every event of a brute force.
  Output: {"count":N,"accounts":"top 3 target accounts","ips":"top 3 source addresses"}
#>
param(
    [int]$Minutes = 5
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$events = @()
try {
    $events = @(Get-WinEvent -FilterHashtable @{ LogName = 'Security'; Id = 4625; StartTime = (Get-Date).AddMinutes(-$Minutes) })
} catch [Exception] {
    if ($_.Exception.Message -notmatch 'No events were found') { throw }   # no matching events is not an error
}

function Top3($values) {
    ($values | Where-Object { $_ -and $_ -ne '-' } | Group-Object | Sort-Object Count -Descending | Select-Object -First 3 |
        ForEach-Object { '{0} ({1})' -f $_.Name, $_.Count }) -join ', '
}

# 4625 event data: [5] TargetUserName, [19] IpAddress
$accounts = Top3 ($events | ForEach-Object { $_.Properties[5].Value })
$ips = Top3 ($events | ForEach-Object { $_.Properties[19].Value })
ConvertTo-Json -Compress -InputObject ([ordered]@{ count = $events.Count; accounts = $accounts; ips = $ips })
