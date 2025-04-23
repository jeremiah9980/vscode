# Connect to vCenter
$vcenter = "aus-vmprod310.company.pvt"
$vcUser = "administrator@vsphere.local"
$vcPass = "Alkebulan1129"
Connect-VIServer -Server $vcenter -User $vcUser -Password $vcPass

# ============================================
# VMware PowerCLI Automation Script
# Configure VDS, Port Groups, Uplinks & VMKernel
# Version: 7.0.3
# ============================================

# ================================
# Define Key Variables
# ================================
$DatacenterName = "Mueller"
$ClusterName = "MUELLER-VRTX1_CLUSTER_01"
$VDSName = "Mueller-VDS"
$PortGroupVMotion = "vMotion-DPG"
$PortGroupManagement = "Management-DPG"
$PortGroupVMs = "VM-Network"
$MTUSize = 9000


# Hosts
$Host1 = "corp-vrtx1-001.company.pvt"
$Host2 = "corp-vrtx1-002.company.pvt"
$ESXiHosts = Get-VMHost -Name $Host1, $Host2

# ================================
# Verify and Create VDS
# ================================
$Datacenter = Get-Datacenter -Name $DatacenterName
$VDS = Get-VDSwitch -Name $VDSName -ErrorAction SilentlyContinue

if ($null -eq $VDS) {
    Write-Host "VDS '$VDSName' not found. Creating VDS (7.0.3)..."
    New-VDSwitch -Name $VDSName -Location $Datacenter -MTU $MTUSize -Version 7.0.3
    Start-Sleep -Seconds 5  # Allow time for creation
    $VDS = Get-VDSwitch -Name $VDSName
} else {
    Write-Host "VDS '$VDSName' already exists. Skipping creation."
}

# Verify VDS Created
Get-VDSwitch -Name $VDSName | Select Name, Version

# ================================
# Add Hosts to VDS
# ================================
foreach ($ESXiHost in $ESXiHosts) {
    $ExistingHosts = Get-VMHost | Where-Object { $_.VDSwitch -eq $VDS }
    if ($ExistingHosts -notcontains $ESXiHost) {
        Write-Host "Adding host $ESXiHost to VDS..."
        Add-VDSwitchVMHost -VDSwitch $VDS -VMHost $ESXiHost
    } else {
        Write-Host "Host $ESXiHost is already added to VDS."
    }
}
# Verify VDS and Port Groups Exist
if ($null -eq $VDS) {
    Write-Host "ERROR: VDS '$VDSName' does not exist. Exiting script."
    exit
}

$PortGroups = Get-VDPortgroup -VDSwitch $VDS

if ($PortGroups.Name -notcontains $PortGroupVMotion -or $PortGroups.Name -notcontains $PortGroupManagement) {
    Write-Host "ERROR: One or more required Port Groups do not exist in VDS. Exiting."
    exit
}

# ================================
# Create Distributed Port Groups
# ================================
Write-Host "Creating Distributed Port Groups..."
$ExistingPortGroups = Get-VDPortgroup -VDSwitch $VDS

if ($ExistingPortGroups.Name -notcontains $PortGroupVMotion) {
    New-VDPortgroup -VDSwitch $VDS -Name $PortGroupVMotion -NumPorts 32
}
if ($ExistingPortGroups.Name -notcontains $PortGroupManagement) {
    New-VDPortgroup -VDSwitch $VDS -Name $PortGroupManagement -NumPorts 32
}
if ($ExistingPortGroups.Name -notcontains $PortGroupVMs) {
    New-VDPortgroup -VDSwitch $VDS -Name $PortGroupVMs -NumPorts 128
}

# ================================
# Configure Uplinks and Load Balancing
# ================================
$Uplink1 = "Uplink 1"
$Uplink2 = "Uplink 2"

foreach ($ESXiHost in $ESXiHosts) {
    # Set teaming policy using the correct method
    $VMotionPG = Get-VDPortgroup -VDSwitch $VDS -Name $PortGroupVMotion
    $MgmtPG = Get-VDPortgroup -VDSwitch $VDS -Name $PortGroupManagement
    $VMsPG = Get-VDPortgroup -VDSwitch $VDS -Name $PortGroupVMs

    Set-VDPortgroup -VDPortgroup $VMotionPG -UplinkTeamingPolicy Active -ActiveUplinkPort $Uplink1 -StandbyUplinkPort $Uplink2
    Set-VDPortgroup -VDPortgroup $MgmtPG -UplinkTeamingPolicy Active -ActiveUplinkPort $Uplink2 -StandbyUplinkPort $Uplink1
    Set-VDPortgroup -VDPortgroup $VMsPG -UplinkTeamingPolicy Active -ActiveUplinkPort $Uplink1, $Uplink2
}

# ================================
# Configure VMKernel for vMotion and Management
# ================================
foreach ($ESXiHost in $ESXiHosts) {
    # Check if vMotion VMKernel Adapter Exists
    $vmkVmotion = Get-VMHostNetworkAdapter -VMHost $ESXiHost | Where-Object { $_.PortGroupName -eq $PortGroupVMotion }
    
    if ($null -eq $vmkVmotion) {
        Write-Host "Creating VMKernel Adapter for vMotion on $ESXiHost..."
        $vmkVmotion = New-VMHostNetworkAdapter -VMHost $ESXiHost -PortGroup $PortGroupVMotion -VirtualSwitch $VDS -IP "192.168.100.$(($ESXiHosts.IndexOf($ESXiHost)) + 2)" -SubnetMask "255.255.255.0"
        Start-Sleep -Seconds 3  # Allow time for provisioning
    } else {
        Write-Host "vMotion Adapter already exists on $ESXiHost. Skipping creation."
    }

    # Enable vMotion
    Set-VMHostNetworkAdapter -VirtualNic $vmkVmotion -VMotionEnabled $true

    # Check if Management VMKernel Adapter Exists
    $vmkMgmt = Get-VMHostNetworkAdapter -VMHost $ESXiHost | Where-Object { $_.PortGroupName -eq $PortGroupManagement }

    if ($null -eq $vmkMgmt) {
        Write-Host "Creating VMKernel Adapter for Management on $ESXiHost..."
        $vmkMgmt = New-VMHostNetworkAdapter -VMHost $ESXiHost -PortGroup $PortGroupManagement -VirtualSwitch $VDS -IP "192.168.1.$(($ESXiHosts.IndexOf($ESXiHost)) + 10)" -SubnetMask "255.255.255.0"
        Start-Sleep -Seconds 3
    } else {
        Write-Host "Management Adapter already exists on $ESXiHost. Skipping creation."
    }

    # Enable Management Traffic
    Set-VMHostNetworkAdapter -VirtualNic $vmkMgmt -ManagementTrafficEnabled $true
}
# ================================
# Migrate VMs to VDS Without Downtime
# ================================
Write-Host "Migrating existing VMs to VDS..."
foreach ($ESXiHost in $ESXiHosts) {
    $VMs = Get-VM | Where-Object { $_.VMHost -eq $ESXiHost }
    foreach ($VM in $VMs) {
        $CurrentNetwork = ($VM | Get-NetworkAdapter).NetworkName
        Write-Host "Migrating VM '$($VM.Name)' from '$CurrentNetwork' to '$PortGroupVMs'..."
        Get-VM -Name $VM.Name | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $PortGroupVMs -Confirm:$false
    }
}

# ================================
# Verify Final Configuration
# ================================
Write-Host "Validating network configuration..."
Get-VMHostNetworkAdapter -VMHost $ESXiHosts | Select-Object VMHost, Name, PortGroupName, IP, SubnetMask

