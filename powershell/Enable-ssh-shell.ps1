# Path: Enable-SSH-Shell.ps1

$vcServer = "aus-vmprod310.company.pvt"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "Password_hereEn"

# Connect to vCenter
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

# Initialize results array
$logResults = @()

# Define target services
$targetServices = @("TSM-SSH", "TSM")

# Loop over each host
Get-VMHost | ForEach-Object {
    $vmhost = $_
    $services = Get-VMHostService -VMHost $vmhost | Where-Object { $targetServices -contains $_.Key }

    foreach ($svc in $services) {
        $result = [pscustomobject]@{
            Host     = $vmhost.Name
            Service  = $svc.Key
            Status   = ""
            Time     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }

        try {
            # Enable the service
            Set-VMHostService -HostService $svc -Policy On -Confirm:$false

            if ($svc.Running -eq $false) {
                Start-VMHostService -HostService $svc -Confirm:$false
                $result.Status = "Started"
            } else {
                $result.Status = "Already Running"
            }
        } catch {
            $result.Status = "Failed: $($_.Exception.Message)"
        }

        $logResults += $result
    }
}

# Export log to CSV
$logResults | Export-Csv -Path "SSH-Shell-Enable-Results2.csv" -NoTypeInformation
