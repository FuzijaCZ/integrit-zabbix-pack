<#
  Integrit MON-CERT agent script for Windows servers (Zabbix agent 2 UserParameters). Read-only, PowerShell 5.1+.
  Output: one line of compact JSON (UTF-8).

  -Mode store : certificates with a private key in LocalMachine\My. A certificate is left out when a newer certificate with
                the same subject exists (renewed), or when it expired more than 30 days ago (left-over).
                [{thumb, subject, issuer, days, self}]
  -Mode ca    : AD CS only. Current CA certificate of this CA: {"ca":"name","days":N,"subject":"..."} ({"ca":""} = no CA here)
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet('store', 'ca')][string]$Mode
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

function Out-Json($obj) {
    ConvertTo-Json -InputObject $obj -Compress -Depth 4
}

$now = Get-Date

switch ($Mode) {
    'store' {
        $certs = @(Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.HasPrivateKey -and $_.NotAfter -gt $now.AddDays(-30) })
        $list = @()
        foreach ($group in ($certs | Group-Object Subject)) {
            $c = $group.Group | Sort-Object NotAfter -Descending | Select-Object -First 1
            $list += [ordered]@{
                thumb   = $c.Thumbprint
                subject = if ($c.Subject) { $c.Subject } else { $c.DnsNameList -join ',' }
                issuer  = $c.Issuer
                days    = [int][math]::Floor(($c.NotAfter - $now).TotalDays)
                self    = [int]($c.Subject -eq $c.Issuer)
            }
        }
        Out-Json (, $list)
    }
    'ca' {
        $cfg = 'HKLM:\SYSTEM\CurrentControlSet\Services\CertSvc\Configuration'
        if (-not (Test-Path $cfg)) {
            Out-Json ([ordered]@{ ca = '' })
            break
        }
        $active = (Get-ItemProperty $cfg).Active
        $hashes = @((Get-ItemProperty (Join-Path $cfg $active)).CACertHash)
        $thumb = ($hashes[-1] -replace '[^0-9A-Fa-f]', '').ToUpper()
        $c = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Thumbprint -eq $thumb } | Select-Object -First 1
        if (-not $c) {
            $c = Get-ChildItem Cert:\LocalMachine\My | Where-Object { $_.Subject -match ('CN=' + [regex]::Escape($active)) } |
                 Sort-Object NotAfter -Descending | Select-Object -First 1
        }
        Out-Json ([ordered]@{
            ca      = $active
            days    = if ($c) { [int][math]::Floor(($c.NotAfter - $now).TotalDays) } else { -9999 }
            subject = if ($c) { $c.Subject } else { 'CA certificate not found in LocalMachine\My' }
        })
    }
}
