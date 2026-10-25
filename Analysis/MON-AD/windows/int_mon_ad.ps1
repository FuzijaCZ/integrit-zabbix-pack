<#
  Integrit MON-AD agent script for domain controllers (Zabbix agent 2 UserParameters). Read-only, PowerShell 5.1+,
  ActiveDirectory module (present on every DC). Runs as LocalSystem = the DC computer account (enough to read AD).
  Output: one line of compact JSON (UTF-8).

  -Mode repl    : replication partners of this DC (last success age, consecutive failures)
  -Mode sysvol  : SYSVOL / NETLOGON shared, DFS-R state of the SYSVOL replicated folder
  -Mode time    : offset of this DC to the PDC emulator (0 on the PDC itself)
  -Mode backup  : age of the last AD backup of the domain naming context (dSASignature)
  -Mode dcdiag  : number of failed dcdiag tests (slow, run daily)
  -Mode pdc     : domain-wide data, ONLY on the PDC emulator ({"pdc":0} elsewhere):
                  privileged group members, krbtgt password age, locked-out accounts
  -Mode accounts: ONLY on the PDC emulator: service accounts (members of -SvcGroup, or with a servicePrincipalName) whose
                  password expires within -Days or has expired, and enabled accounts whose account expiry date is within -Days
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet('repl', 'sysvol', 'time', 'backup', 'dcdiag', 'pdc', 'accounts')][string]$Mode,
    [int]$Days = 14,
    [string]$SvcGroup = 'INT Service Accounts',
    [string]$Groups = 'Domain Admins,Enterprise Admins,Schema Admins,Administrators,Account Operators,Backup Operators,Server Operators,Print Operators,DnsAdmins,Group Policy Creator Owners'
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
Import-Module ActiveDirectory

function Out-Json($obj) {
    ConvertTo-Json -InputObject $obj -Compress -Depth 4
}

$now = Get-Date
$me = (Get-ADDomainController -Identity $env:COMPUTERNAME)

switch ($Mode) {
    'repl' {
        $list = @()
        foreach ($p in (Get-ADReplicationPartnerMetadata -Target $me.HostName -Scope Server -ErrorAction SilentlyContinue)) {
            $partner = ($p.Partner -split ',')[1] -replace '^CN=', ''
            $age = if ($p.LastReplicationSuccess) { [int]($now - $p.LastReplicationSuccess).TotalSeconds } else { 999999999 }
            $list += [ordered]@{
                partner  = $partner
                nc       = [string]$p.Partition
                key      = ($partner + '|' + $p.Partition) -replace '[^A-Za-z0-9|=,._-]', '_'
                age      = $age
                failures = [int]$p.ConsecutiveReplicationFailures
                result   = [int]$p.LastReplicationResult
            }
        }
        Out-Json (, $list)
    }
    'sysvol' {
        $shares = @(Get-SmbShare -Name SYSVOL, NETLOGON -ErrorAction SilentlyContinue).Count
        $state = -1
        try {
            $f = Get-CimInstance -Namespace root\microsoftdfs -ClassName DfsrReplicatedFolderInfo -Filter "ReplicatedFolderName='SYSVOL Share'"
            if ($f) { $state = [int]$f.State }
        } catch { $state = -1 }   # FRS-replicated SYSVOL (very old domains) has no DFS-R object
        Out-Json ([ordered]@{ shares = $shares; dfsr_state = $state })
    }
    'time' {
        $pdc = (Get-ADDomain).PDCEmulator
        $offset = 0
        if ($pdc -ne $me.HostName) {
            $offset = $null
            foreach ($line in (& w32tm /stripchart /computer:$pdc /samples:1 /dataonly 2>&1)) {
                if ("$line" -match '([+-]\d+[.,]\d+)s\s*$') {
                    $offset = [double]::Parse(($Matches[1] -replace ',', '.'), [Globalization.CultureInfo]::InvariantCulture)
                }
            }
        }
        Out-Json ([ordered]@{ pdc = $pdc; offset = $offset })
    }
    'backup' {
        $nc = (Get-ADRootDSE).defaultNamingContext
        $m = Get-ADReplicationAttributeMetadata -Object $nc -Server $me.HostName -Properties dSASignature |
             Where-Object { $_.AttributeName -eq 'dSASignature' } | Select-Object -First 1
        $age = if ($m -and $m.LastOriginatingChangeTime) { [int]($now - $m.LastOriginatingChangeTime).TotalSeconds } else { 999999999 }
        Out-Json ([ordered]@{ age = $age })
    }
    'dcdiag' {
        $out = & dcdiag /q 2>&1 | Out-String
        $failed = ([regex]::Matches($out, 'failed test')).Count
        $first = (($out -split "`r?`n") | Where-Object { $_ -match 'failed test' } | Select-Object -First 5) -join '; '
        Out-Json ([ordered]@{ failed = $failed; detail = $first.Trim() })
    }
    'pdc' {
        $domain = Get-ADDomain
        if ($domain.PDCEmulator -ne $me.HostName) {
            Out-Json ([ordered]@{ pdc = 0 })
            break
        }
        $groupsOut = @()
        foreach ($g in ($Groups -split ',')) {
            $g = $g.Trim()
            try {
                $members = @(Get-ADGroupMember -Identity $g -Recursive | ForEach-Object { $_.SamAccountName } | Sort-Object -Unique)
                $groupsOut += [ordered]@{ group = $g; count = $members.Count; members = ($members -join ', ') }
            } catch {
                $groupsOut += [ordered]@{ group = $g; count = -1; members = 'ERROR: ' + $_.Exception.Message }
            }
        }
        $krbtgt = Get-ADUser krbtgt -Properties PasswordLastSet
        Out-Json ([ordered]@{
            pdc          = 1
            krbtgt_days  = [int]($now - $krbtgt.PasswordLastSet).TotalDays
            locked       = @(Search-ADAccount -LockedOut -UsersOnly).Count
            groups       = $groupsOut
        })
    }
    'accounts' {
        if ((Get-ADDomain).PDCEmulator -ne $me.HostName) {
            Out-Json ([ordered]@{ pdc = 0 })
            break
        }
        $limit = $now.AddDays($Days)
        $props = 'msDS-UserPasswordExpiryTimeComputed', 'PasswordNeverExpires', 'AccountExpirationDate', 'servicePrincipalName', 'Enabled'
        $svc = @{}
        try {
            foreach ($m in (Get-ADGroupMember -Identity $SvcGroup -Recursive | Where-Object { $_.objectClass -eq 'user' })) { $svc[$m.SamAccountName] = 1 }
        } catch { }   # group does not exist: SPN-based detection only
        foreach ($u in (Get-ADUser -LDAPFilter '(servicePrincipalName=*)' -Properties servicePrincipalName | Where-Object { $_.SamAccountName -ne 'krbtgt' })) {
            $svc[$u.SamAccountName] = 1
        }
        $expiring = @(); $expired = @()
        foreach ($name in $svc.Keys) {
            $u = Get-ADUser -Identity $name -Properties $props
            if (-not $u.Enabled -or $u.PasswordNeverExpires) { continue }
            $raw = $u.'msDS-UserPasswordExpiryTimeComputed'
            if (-not $raw -or $raw -eq 0 -or $raw -eq 9223372036854775807) { continue }
            $exp = [datetime]::FromFileTime($raw)
            if ($exp -lt $now) { $expired += ('{0} ({1:yyyy-MM-dd})' -f $name, $exp) }
            elseif ($exp -lt $limit) { $expiring += ('{0} ({1:yyyy-MM-dd})' -f $name, $exp) }
        }
        $acct = @(Search-ADAccount -AccountExpiring -TimeSpan (New-TimeSpan -Days $Days) -UsersOnly | Where-Object { $_.Enabled } |
                  ForEach-Object { '{0} ({1:yyyy-MM-dd})' -f $_.SamAccountName, $_.AccountExpirationDate })
        Out-Json ([ordered]@{
            pdc = 1; svc_total = $svc.Count
            svc_expiring = $expiring.Count; svc_expiring_list = (($expiring | Select-Object -First 8) -join ', ')
            svc_expired = $expired.Count; svc_expired_list = (($expired | Select-Object -First 8) -join ', ')
            acct_expiring = $acct.Count; acct_expiring_list = (($acct | Select-Object -First 8) -join ', ')
        })
    }
}
