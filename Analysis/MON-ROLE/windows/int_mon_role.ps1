<#
  Integrit MON-ROLE agent script for Windows role servers (Zabbix agent 2 UserParameters). Read-only, PowerShell 5.1+,
  runs as LocalSystem. Output: one line of compact JSON (UTF-8). A mode on a server without that role returns [] or {}.

  -Mode dhcp   : DHCP scopes [{scope, name, pct, free}] + failover {failover:[{name, state}]} -> {"scopes":[...],"failover":[...]}
  -Mode shares : SMB shares that are not special/admin shares and whether their path exists [{share, path, ok}]
  -Mode vss    : shadow copies per volume [{volume, count, age_h}] (age of the newest copy in hours, -1 = none)
  -Mode fsrm   : FSRM quotas [{path, pct, limit_gb}]
  -Mode dfsr   : inbound DFS-R backlog per replicated folder [{folder, partner, backlog}] (slow: every 30-60 min)
  -Mode print  : {"error_queues":N,"error_names":"...","stuck_jobs":N,"stuck_names":"..."} (jobs older than -Minutes)
  -Mode rds    : {"grace_days":N,"cal_available":N,"cal_total":N,"licensing_mode":N}  (-1 = not applicable)
  -Mode dns    : {"internal":0/1,"external":0/1,"forwarders":N,"forwarders_bad":N}  (-Internal / -External names)
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet('dhcp', 'shares', 'vss', 'fsrm', 'dfsr', 'print', 'rds', 'dns')][string]$Mode,
    [int]$Minutes = 15,
    [string]$Internal = '',
    [string]$External = 'www.microsoft.com'
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

function Out-Json($obj) {
    ConvertTo-Json -InputObject $obj -Compress -Depth 4
}

$now = Get-Date

switch ($Mode) {
    'dhcp' {
        $scopes = @(); $fo = @()
        foreach ($s in (Get-DhcpServerv4ScopeStatistics -ErrorAction SilentlyContinue)) {
            $sc = Get-DhcpServerv4Scope -ScopeId $s.ScopeId
            if ($sc.State -ne 'Active') { continue }
            $scopes += [ordered]@{ scope = [string]$s.ScopeId; name = [string]$sc.Name; pct = [math]::Round([double]$s.PercentageInUse, 1); free = [int]$s.Free }
        }
        foreach ($f in (Get-DhcpServerv4Failover -ErrorAction SilentlyContinue)) {
            $fo += [ordered]@{ name = [string]$f.Name; state = [string]$f.State }
        }
        Out-Json ([ordered]@{ scopes = $scopes; failover = $fo })
    }
    'shares' {
        $list = @()
        foreach ($s in (Get-SmbShare -Special $false -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Name -notmatch '\$$' })) {
            $list += [ordered]@{ share = [string]$s.Name; path = [string]$s.Path; ok = [int](Test-Path -LiteralPath $s.Path) }
        }
        Out-Json (, $list)
    }
    'vss' {
        $vols = @{}
        foreach ($v in (Get-CimInstance Win32_Volume | Where-Object { $_.DriveType -eq 3 -and $_.DriveLetter })) { $vols[$v.DeviceID] = $v.DriveLetter }
        $copies = @(Get-CimInstance Win32_ShadowCopy -ErrorAction SilentlyContinue)
        $list = @()
        foreach ($id in $vols.Keys) {
            $c = @($copies | Where-Object { $_.VolumeName -eq $id })
            $age = -1
            if ($c.Count) { $age = [math]::Round(($now - ($c | Sort-Object InstallDate -Descending | Select-Object -First 1).InstallDate).TotalHours, 1) }
            $list += [ordered]@{ volume = $vols[$id]; count = $c.Count; age_h = $age }
        }
        Out-Json (, $list)
    }
    'fsrm' {
        $list = @()
        foreach ($q in (Get-FsrmQuota -ErrorAction SilentlyContinue | Where-Object { -not $_.Disabled -and $_.Size -gt 0 })) {
            $list += [ordered]@{ path = [string]$q.Path; pct = [math]::Round(100 * $q.Usage / $q.Size, 1); limit_gb = [math]::Round($q.Size / 1GB, 1) }
        }
        Out-Json (, $list)
    }
    'dfsr' {
        $list = @()
        $me = $env:COMPUTERNAME
        foreach ($c in (Get-DfsrConnection -ErrorAction SilentlyContinue | Where-Object { $_.DestinationComputerName -eq $me -and $_.Enabled })) {
            foreach ($f in (Get-DfsReplicatedFolder -GroupName $c.GroupName -ErrorAction SilentlyContinue)) {
                $n = -1
                try {
                    $n = @(Get-DfsrBacklog -GroupName $c.GroupName -FolderName $f.FolderName -SourceComputerName $c.SourceComputerName `
                           -DestinationComputerName $me -ErrorAction Stop -WarningAction SilentlyContinue).Count
                } catch { $n = -1 }
                $list += [ordered]@{ folder = [string]($c.GroupName + '\' + $f.FolderName); partner = [string]$c.SourceComputerName; backlog = $n }
            }
        }
        Out-Json (, $list)
    }
    'print' {
        $err = @(Get-Printer -ErrorAction SilentlyContinue | Where-Object { [string]$_.PrinterStatus -match 'Error|Offline|PaperJam|PaperOut|NoToner|Door' })
        $stuck = @()
        foreach ($p in (Get-Printer -ErrorAction SilentlyContinue)) {
            foreach ($j in (Get-PrintJob -PrinterName $p.Name -ErrorAction SilentlyContinue)) {
                if (($now - $j.SubmittedTime).TotalMinutes -gt $Minutes) { $stuck += ($p.Name + ': ' + $j.DocumentName) }
            }
        }
        Out-Json ([ordered]@{
            error_queues = $err.Count; error_names = (($err | ForEach-Object { $_.Name + ' (' + $_.PrinterStatus + ')' }) -join ', ')
            stuck_jobs = $stuck.Count; stuck_names = (($stuck | Select-Object -First 5) -join ', ')
        })
    }
    'rds' {
        $grace = -1; $mode = -1; $avail = -1; $total = -1
        try {
            $ts = Get-CimInstance -Namespace root\cimv2\TerminalServices -ClassName Win32_TerminalServiceSetting
            $mode = [int]$ts.LicensingType
            $g = Invoke-CimMethod -InputObject $ts -MethodName GetGracePeriodDays -ErrorAction Stop
            if ($g.ReturnValue -eq 0) { $grace = [int]$g.DaysLeft }
        } catch { }
        try {   # only on the RD Licensing server
            $packs = @(Get-CimInstance Win32_TSLicenseKeyPack -ErrorAction Stop | Where-Object { $_.TypeAndModel -notmatch 'Built-in' })
            if ($packs.Count) {
                $avail = [int](($packs | Measure-Object AvailableLicenses -Sum).Sum)
                $total = [int](($packs | Measure-Object TotalLicenses -Sum).Sum)
            }
        } catch { }
        Out-Json ([ordered]@{ grace_days = $grace; licensing_mode = $mode; cal_available = $avail; cal_total = $total })
    }
    'dns' {
        function Test-Name($name, $server) {
            if (-not $name) { return -1 }
            try { [void](Resolve-DnsName -Name $name -Server $server -DnsOnly -QuickTimeout -ErrorAction Stop); return 1 } catch { return 0 }
        }
        $fw = @((Get-DnsServerForwarder -ErrorAction SilentlyContinue).IPAddress | ForEach-Object { [string]$_ })
        $bad = @($fw | Where-Object { (Test-Name $External $_) -ne 1 })
        Out-Json ([ordered]@{
            internal = (Test-Name $Internal '127.0.0.1'); external = (Test-Name $External '127.0.0.1')
            forwarders = $fw.Count; forwarders_bad = $bad.Count; forwarders_bad_list = ($bad -join ', ')
        })
    }
}
