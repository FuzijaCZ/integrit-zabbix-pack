<#
  Integrit MON-MAIL agent script for Exchange Server 2016 / 2019 / SE (Zabbix agent 2 UserParameters). Read-only, PowerShell 5.1.
  Loads the local Exchange snap-in. Runs as LocalSystem = the Exchange computer account (member of Exchange Trusted Subsystem).
  Output: one line of compact JSON (UTF-8).

  -Mode db    : mailbox database copies on this server: [{db, active, status, ok, copyq, replayq, index}]
                ok = 1 for an active copy that is Mounted or a passive copy that is Healthy
  -Mode cert  : days until the earliest expiry of certificates bound to SMTP or IIS: {"days":N,"subject":"..."}
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet('db', 'cert')][string]$Mode
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
Add-PSSnapin Microsoft.Exchange.Management.PowerShell.SnapIn

function Out-Json($obj) {
    ConvertTo-Json -InputObject $obj -Compress -Depth 4
}

switch ($Mode) {
    'db' {
        $list = @()
        foreach ($c in (Get-MailboxDatabaseCopyStatus -Server $env:COMPUTERNAME)) {
            $status = [string]$c.Status
            $active = [bool]$c.ActiveCopy -or $status -eq 'Mounted'
            $ok = if ($active) { [int]($status -eq 'Mounted') } else { [int]($status -eq 'Healthy') }
            $list += [ordered]@{
                db      = [string]$c.DatabaseName
                active  = [int]$active
                status  = $status
                ok      = $ok
                copyq   = [int]$c.CopyQueueLength
                replayq = [int]$c.ReplayQueueLength
                index   = [string]$c.ContentIndexState
            }
        }
        Out-Json (, $list)
    }
    'cert' {
        $certs = @(Get-ExchangeCertificate -Server $env:COMPUTERNAME | Where-Object { [string]$_.Services -match 'SMTP|IIS' } |
                   Sort-Object NotAfter)
        if ($certs.Count -eq 0) {
            Out-Json ([ordered]@{ days = -9999; subject = 'no certificate bound to SMTP or IIS' })
        } else {
            Out-Json ([ordered]@{ days = [int]($certs[0].NotAfter - (Get-Date)).TotalDays; subject = [string]$certs[0].Subject })
        }
    }
}
