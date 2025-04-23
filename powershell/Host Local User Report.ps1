#Host Local User Report

# Host Local User Report

# Connect to vCenter server
$vcServer = "aus-vmprod310.company.pvt"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "Alkebulan1129"

# Connect to vCenter server
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Initialize an array to hold the output data
$report = @()

# Retrieve all ESXi hosts
$vmhosts = Get-VMHost

foreach ($vmhost in $vmhosts) {
    # Retrieve local user accounts
    $localUsers = Get-VMHostAccount -VMHost $vmhost

    foreach ($user in $localUsers) {
        $report += [PSCustomObject]@{
            Host               = $vmhost.Name
            UserType           = 'LocalUser'
            UserId             = $user.Id
            FullName           = $user.FullName
            Description        = $user.Description
            LockdownException  = $false
        }
    }

    # Retrieve Lockdown Mode exception users
    $hostView = Get-View $vmhost
    $hostAccessManager = Get-View $hostView.ConfigManager.HostAccessManager
    $exceptionUsers = $hostAccessManager.QueryLockdownExceptions()

    foreach ($exceptionUser in $exceptionUsers) {
        $report += [PSCustomObject]@{
            Host               = $vmhost.Name
            UserType           = 'ExceptionUser'
            UserId             = $exceptionUser
            FullName           = ''
            Description        = ''
            LockdownException  = $true
        }
    }
}

# Export the report to a CSV file
$report | Export-Csv -Path "C:\ps\VMware_Configs\Host_Local_Users.csv" -NoTypeInformation
