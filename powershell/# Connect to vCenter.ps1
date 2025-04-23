# Connect to vCenter server
$vcServer = "aus-vmprod310.company.pvt"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "Alkebulan1129"

# Connect to vCenter server
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Get Datacenters and export
$datacenters = Get-Datacenter | Select Name, VMHost, VMStorage
$datacenters | Export-Csv -Path "C:\ps\VMware_Configs\Datacenters.csv" -NoTypeInformation

# Get Clusters and export
$clusters = Get-Cluster | Select Name, HAEnabled, DRSEnabled, FTEnabled, DrsAutomationLevel
$clusters | Export-Csv -Path "C:\ps\VMware_Configs\Clusters.csv" -NoTypeInformation

# Get Hosts and export
$hosts = Get-VMHost | Select Name, Version, State, ProcessorUsage, MemoryUsage, NetworkUsage, CPUCount, MemoryGB
$hosts | Export-Csv -Path "C:\ps\VMware_Configs\Hosts.csv" -NoTypeInformation

# Get Networking (vSwitches, dvSwitches, etc.) and export
$networking = Get-VirtualSwitch | Select Name, NumPorts, MTU, SwitchType, NetworkLabel
$networking | Export-Csv -Path "C:\ps\VMware_Configs\Networking.csv" -NoTypeInformation

# Get Datastores and export
$datastores = Get-Datastore | Select Name, Type, CapacityGB, FreeSpaceGB, ProvisionedSpaceGB
$datastores | Export-Csv -Path "C:\ps\VMware_Configs\Datastores.csv" -NoTypeInformation

# Get Virtual Machines and export
$vms = Get-VM | Select Name, PowerState, NumCpu, MemoryMB, Guest, IPAddress, Datastore
$vms | Export-Csv -Path "C:\ps\VMware_Configs\VMs.csv" -NoTypeInformation

# Get Resource Pools and export
$resourcePools = Get-ResourcePool | Select Name, CPUAllocation, MemoryAllocation, Limit, Shares
$resourcePools | Export-Csv -Path "C:\ps\VMware_Configs\ResourcePools.csv" -NoTypeInformation

# Get VMware Distributed Virtual Switch (dvSwitch) and export
$dvSwitches = Get-VDSwitch | Select Name, Version, Uplinks, MTU
$dvSwitches | Export-Csv -Path "C:\ps\VMware_Configs\dvSwitches.csv" -NoTypeInformation

# Get Virtual Machine Snapshots and export
$snapshots = Get-Snapshot | Select VM, Name, Created, Description
$snapshots | Export-Csv -Path "C:\ps\VMware_Configs\Snapshots.csv" -NoTypeInformation

# Get VMware licenses and export
$licenses = Get-LicenseData | Select LicenseKey, Name, Edition, ExpiryDate
$licenses | Export-Csv -Path "C:\ps\VMware_Configs\Licenses.csv" -NoTypeInformation

# Disconnect from vCenter server
Disconnect-VIServer -Server $vcServer -Confirm:$false

Write-Host "Export complete. Configuration files are saved in C:\ps\VMware_Configs"
