# Path: Disable-SSH-Shell.ps1

$vcServer = "aus-vmprod310.company.pvt"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "Alkebulan1129"

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
            if ($svc.Running -eq $true) {
                Stop-VMHostService -HostService $svc -Confirm:$false
                $result.Status = "Stopped"
            } else {
                $result.Status = "Already Stopped"
            }

            Set-VMHostService -HostService $svc -Policy Off -Confirm:$false
        } catch {
            $result.Status = "Failed: $($_.Exception.Message)"
        }

        $logResults += $result
    }
}

# Export log to CSV
$logResults | Export-Csv -Path "SSH-Shell-Disable-Results.csv" -NoTypeInformation
