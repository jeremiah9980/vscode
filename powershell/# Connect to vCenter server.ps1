# Connect to vCenter server
$vcServer = "aus-vmprod310.company.pvt"
$vcUsername = "administrator@vsphere.local"
$vcPassword = "Alkebulan1129"

# Connect to vCenter server
Connect-VIServer -Server $vcServer -User $vcUsername -Password $vcPassword

Get-VMHost | Get-VMHostService | Where-Object {$_.Key -eq "TSM-SSH"} | Set-VMHostService -Policy Off -Confirm:$false -Running:$false

Get-VMHost | Get-VMHostService | Where-Object {$_.Key -eq "TSM"} | Set-VMHostService -Policy Off -Confirm:$false
Get-VMHost | Get-VMHostService | Where-Object {$_.Key -eq "TSM"} | Stop-VMHostService -Confirm:$false



$esxi = Get-VMHost -Name "aus-vmprod310.company.pvt"

# Enable and Start SSH
Get-VMHostService -VMHost $esxi | Where-Object {$_.Key -eq "TSM-SSH"} | Set-VMHostService -Policy On -Confirm:$false
Get-VMHostService -VMHost $esxi | Where-Object {$_.Key -eq "TSM-SSH"} | Start-VMHostService -Confirm:$false

# Enable and Start ESXi Shell
Get-VMHostService -VMHost $esxi | Where-Object {$_.Key -eq "TSM"} | Set-VMHostService -Policy On -Confirm:$false
Get-VMHostService -VMHost $esxi | Where-Object {$_.Key -eq "TSM"} | Start-VMHostService -Confirm:$false
