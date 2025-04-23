# Path: Set-ESXiLockdown.ps1
# === SET CREDENTIALS ===
$esxiRootUser = "root"
$esxiRootPassword = "Alkebulan1129!!"

$hosts = @(
    "corp-vrtx1-001.company.pvt",
    "corp-vrtx1-002.company.pvt"
)

$sshUser = "root"
$user = "vlockdownuser"
$pass = "Alkebulan1129!!$$"
$desc = "Local Lockdown Admin User"

# Initialize results array
$results = @()

foreach ($esxiHost in $hosts) {
    Write-Host "Connecting to $esxiHost..."

    $cmd = @"
esxcli system account add --id=$user --password='$pass' --password-confirmation='$pass' --description='$desc'
esxcli system permission set --id=$user --role=Admin
"@

    try {
        ssh "$sshUser@$esxiHost" $cmd
        Write-Host "Success on $esxiHost" -ForegroundColor Green
        $results += [pscustomobject]@{
            Host     = $esxiHost
            Status   = "Success"
            Time     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    } catch {
        Write-Host ("Failed on {0}: {1}" -f $esxiHost, $_) -ForegroundColor Red
        $results += [pscustomobject]@{
            Host     = $esxiHost
            Status   = "Failed: $($_.Exception.Message)"
            Time     = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
    }
}

# Export results to CSV
$results | Export-Csv -Path "SetLockdownResults.csv" -NoTypeInformation