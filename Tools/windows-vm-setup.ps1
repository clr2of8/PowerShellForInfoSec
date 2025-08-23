# iex (iwr https://raw.githubusercontent.com/clr2of8/PowerShellForInfoSec/refs/heads/main/Tools/windows-vm-setup.ps1 -UseBasicParsing)

# call base-vm-setup script that is common between all lab VMs
iex (iwr https://raw.githubusercontent.com/clr2of8/PowerShellForInfoSec/refs/heads/main/Tools/base-vm-setup.ps1 -UseBasicParsing)

# check if this is a cloud lab VM or not. Local VMs will be treated a little differently.
$uuid = (Get-WmiObject -Query "select uuid from Win32_ComputerSystemProduct").UUID
if ($uuid -like "EC2*") { } else {
    # local VM
    # add local domain to hosts file for remote.cloudlab.lan
    $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
    $entry = "192.168.195.136`tremote.cloudlab.lan"
    $hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue
    if ($hostsContent -notmatch "remote\.cloudlab\.lan") {
        Add-Content -Path $hostsPath -Value $entry
        Write-Host "Added remote.cloudlab.lan to hosts file." -ForegroundColor Cyan
    } else {
        Write-Host "Entry for remote.cloudlab.lan already exists in hosts file." -ForegroundColor Yellow
    }
}
