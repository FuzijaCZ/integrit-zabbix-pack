<#
  Integrit MON-VIRT agent script for Hyper-V hosts (Zabbix agent 2 UserParameters). Read-only. PowerShell 5.1+.
  Runs as the agent service account (LocalSystem). Output: one line of compact JSON (UTF-8).

  -Mode vms     : all VMs on this host: state, replication health, oldest checkpoint age
  -Mode cluster : failover cluster data (nodes, CSV free space, clustered VM roles), reported ONLY by the node that owns the core "Cluster Group"
                  (other nodes return {"owner":0}); standalone hosts return {"owner":0,"clustered":0}
#>
param(
    [Parameter(Mandatory = $true)][ValidateSet('vms', 'cluster')][string]$Mode
)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

function Out-Json($obj) {
    ConvertTo-Json -InputObject $obj -Compress -Depth 4
}

function Get-VmStatus {
    $now = Get-Date
    $list = @()
    foreach ($vm in (Get-VM)) {
        $age = 0
        $oldest = Get-VMSnapshot -VM $vm -ErrorAction SilentlyContinue | Sort-Object CreationTime | Select-Object -First 1
        if ($oldest) {
            $age = [int][math]::Floor(($now - $oldest.CreationTime).TotalSeconds)
        }
        $list += [ordered]@{
            id                 = [string]$vm.VMId
            name               = $vm.Name
            state              = [string]$vm.State
            replication        = [string]$vm.ReplicationHealth
            checkpoint_age     = $age
            is_clustered       = [int][bool]$vm.IsClustered
        }
    }
    , $list
}

function Get-ClusterStatus {
    if (-not (Get-Service -Name ClusSvc -ErrorAction SilentlyContinue)) {
        return [ordered]@{ owner = 0; clustered = 0 }
    }
    Import-Module FailoverClusters
    $core = Get-ClusterGroup -Name 'Cluster Group'
    if ($core.OwnerNode.Name -ne $env:COMPUTERNAME) {
        return [ordered]@{ owner = 0; clustered = 1 }
    }
    $nodes = @(Get-ClusterNode)
    $csv = @()
    foreach ($c in (Get-ClusterSharedVolume -ErrorAction SilentlyContinue)) {
        foreach ($v in $c.SharedVolumeInfo) {
            $csv += [ordered]@{
                name  = $c.Name
                path  = $v.FriendlyVolumeName
                pfree = [math]::Round($v.Partition.PercentFree, 2)
                state = [string]$c.State
            }
        }
    }
    $roles = @()
    foreach ($g in (Get-ClusterGroup | Where-Object { [string]$_.GroupType -eq 'VirtualMachine' })) {
        $roles += [ordered]@{ name = $g.Name; state = [string]$g.State; node = $g.OwnerNode.Name }
    }
    [ordered]@{
        owner       = 1
        clustered   = 1
        cluster     = (Get-Cluster).Name
        nodes_total = $nodes.Count
        nodes_down  = @($nodes | Where-Object { $_.State -eq 'Down' }).Count
        csv         = $csv
        vm_roles    = $roles
    }
}

switch ($Mode) {
    'vms'     { Out-Json (Get-VmStatus) }
    'cluster' { Out-Json (Get-ClusterStatus) }
}
