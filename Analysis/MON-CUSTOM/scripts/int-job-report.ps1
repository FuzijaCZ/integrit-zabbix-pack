<#
  Integrit MON-CUSTOM job reporting (Windows). Sends a job result to Zabbix (template "INT MON-CUSTOM Job")
  with zabbix_sender.exe, using the local agent 2 config (server, host name, TLS PSK).

  Wrap a command:
    powershell -File int-job-report.ps1 -Job erp-export -Run "C:\ERP\export.cmd" -Arguments "/full"
  Report from inside your own script (at the end):
    & "C:\Program Files\Zabbix Agent 2\scripts\int-job-report.ps1" -Job erp-export -ExitCode $LASTEXITCODE -Duration 312 -Records 1840 -Message "ok"

  The job name must be listed in the host macro {$INT.CUSTOM.JOBS}. With -Run the script exits with the command's exit code.
#>
param(
    [Parameter(Mandatory = $true)][string]$Job,
    [string]$Run,
    [string]$Arguments = '',
    [int]$ExitCode = 0,
    [double]$Duration = 0,
    [double]$Records = -1,
    [string]$Message = '',
    [string]$AgentDir = 'C:\Program Files\Zabbix Agent 2'
)

$Job = $Job -replace '["\[\]\\]', ''
if ($Run) {
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $p = Start-Process -FilePath $Run -ArgumentList $Arguments -NoNewWindow -Wait -PassThru
    $sw.Stop()
    $ExitCode = $p.ExitCode
    $Duration = [math]::Round($sw.Elapsed.TotalSeconds)
    if (-not $Message) { $Message = "exit code $ExitCode" }
}

$Message = ($Message -replace '"', "'" -replace '[\r\n]+', ' ')
if ($Message.Length -gt 500) { $Message = $Message.Substring(0, 500) }
$lines = @(
    ('- "int.custom.job.status[\"{0}\"]" {1}' -f $Job, $ExitCode),
    ('- "int.custom.job.duration[\"{0}\"]" {1}' -f $Job, [string]$Duration),
    ('- "int.custom.job.message[\"{0}\"]" "{1}"' -f $Job, $Message)
)
if ($Records -ge 0) { $lines += ('- "int.custom.job.records[\"{0}\"]" {1}' -f $Job, [string]$Records) }

$tmp = [IO.Path]::GetTempFileName()
[IO.File]::WriteAllLines($tmp, $lines, (New-Object Text.UTF8Encoding $false))
& (Join-Path $AgentDir 'zabbix_sender.exe') -c (Join-Path $AgentDir 'zabbix_agent2.conf') -i $tmp | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Warning "int-job-report: zabbix_sender failed for job $Job" }
Remove-Item $tmp -ErrorAction SilentlyContinue
if ($Run) { exit $ExitCode }
