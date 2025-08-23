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
    }
    else {
        Write-Host "Entry for remote.cloudlab.lan already exists in hosts file." -ForegroundColor Yellow
    }

    # Set the wallpaper to all black
    Add-Type @"
using System.Runtime.InteropServices;
public class Wallpaper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

    $blackBmpPath = "$env:TEMP\allblack.bmp"
    # Create a 1x1 black BMP file
    [byte[]]$bmp = 0x42, 0x4D, 0x3E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x3E, 0x00, 0x00, 0x00, 0x28, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x00, 0x18, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x13, 0x0B, 0x00, 0x00, 0x13, 0x0B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    Set-Content -Path $blackBmpPath -Value $bmp -Encoding Byte

    # Set as wallpaper
    [Wallpaper]::SystemParametersInfo(20, 0, $blackBmpPath, 3) | Out-Null
}
