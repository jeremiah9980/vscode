#get-VM-LOGS
Connect-VIServer -Server aus-vmprod310 -User "administrator@vsphere.local" -Password "Alkebulan1129"

# Define log storage directory
$LogDir = "C:\PS\VMwareLogs"
if (!(Test-Path $LogDir)) { New-Item -ItemType Directory -Path $LogDir }

$vcLogFile = "$LogDir\vCenter_SystemLogs.csv"
Get-VIEvent -MaxSamples 5000 | Select-Object CreatedTime, UserName, FullFormattedMessage |
    Export-Csv -Path $vcLogFile -NoTypeInformation
Write-Host "✅ vCenter logs saved to: $vcLogFile"

$esxiLogFile = "$LogDir\ESXi_HostLogs.csv"
$allLogs = @()

Get-VMHost | ForEach-Object {
    $esxiHost = $_.Name
    $logs = Get-Log -VMHost $_ -LogName vmkernel | Select-Object -ExpandProperty Entries
    foreach ($log in $logs) {
        $allLogs += [PSCustomObject]@{
            Host = $esxiHost
            LogEntry = $log
        }
    }
}
$allLogs | Export-Csv -Path $esxiLogFile -NoTypeInformation
Write-Host "✅ ESXi logs saved to: $esxiLogFile"



$changeLogs = Get-VIEvent -Start $startTime | Where-Object {
    $_.EventTypeId -match "VmCreatedEvent|VmRemovedEvent|VmReconfiguredEvent|VmMigratedEvent|VmPoweredOnEvent|VmPoweredOffEvent|VmSuspendedEvent|HostConnectionLostEvent|HostConnectedEvent|DrsVmMigratedEvent|TaskEvent|AlarmStatusChangedEvent"
} | Select-Object CreatedTime, UserName, EventTypeId, FullFormattedMessage

