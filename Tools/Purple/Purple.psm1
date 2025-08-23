function Purple-Redeploy {
    function Get-CloudLabHostRole {
        # First, try to determine by hosts file
        $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
        $hostsContent = @()
        if (Test-Path $hostsPath) {
            $hostsContent = Get-Content $hostsPath -ErrorAction SilentlyContinue
            if ($hostsContent -match "windows\.cloudlab\.lan") {
                return "remote"
            } elseif ($hostsContent -match "remote\.cloudlab\.lan") {
                return "windows"
            }
        }

        # If not found, try to match the current VM's IP to the DNS resolution of the cloudlab hostnames
        try {
            # Get all IPv4 addresses of this machine (excluding loopback and APIPA)
            $myIPs = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
                $_.IPAddress -notlike "169.254.*" -and $_.IPAddress -ne "127.0.0.1"
            } | Select-Object -ExpandProperty IPAddress

            # nslookup windows.cloudlab.lan
            $winLookup = nslookup windows.cloudlab.lan 2>$null | Select-String -Pattern "Address:\s*([\d\.]+)" | ForEach-Object {
                $_.Matches[0].Groups[1].Value
            }
            # nslookup remote.cloudlab.lan
            $remoteLookup = nslookup remote.cloudlab.lan 2>$null | Select-String -Pattern "Address:\s*([\d\.]+)" | ForEach-Object {
                $_.Matches[0].Groups[1].Value
            }

            if ($myIPs -and $winLookup -and ($myIPs | Where-Object { $winLookup -contains $_ })) {
                return "windows"
            } elseif ($myIPs -and $remoteLookup -and ($myIPs | Where-Object { $remoteLookup -contains $_ })) {
                return "remote"
            }
        } catch {
            Write-Host "Could not determine by nslookup." -ForegroundColor Yellow
        }

        # If all checks fail
        return $null
    }

    $hostEntryType = Get-CloudLabHostRole

    if ($hostEntryType -eq "windows") {
        Write-Host "Running windows-vm-setup." -ForegroundColor Cyan
        IEX (IWR "https://raw.githubusercontent.com/clr2of8/PowerShellForInfoSec/refs/heads/main/Tools/windows-vm-setup.ps1" -UseBasicParsing)
    }
    elseif ($hostEntryType -eq "remote") {
        Write-Host "Running remote-vm-setup." -ForegroundColor Yellow
        IEX (IWR "https://raw.githubusercontent.com/clr2of8/PowerShellForInfoSec/refs/heads/main/Tools/remote-vm-setup.ps1" -UseBasicParsing)
    }
    else {
        Write-Host "No cloudlab hosts entry found. Please ensure your hosts file contains either windows.cloudlab.lan or remote.cloudlab.lan." -ForegroundColor Yellow
    }
}

function Purple-InstallVSCode {
    Write-Host "Installing VSCode" -ForegroundColor Cyan
    Install-PackageProvider -Name NuGet -Force
    Install-Script -Name Install-VSCode -Force
    Install-VSCode
}



function Purple-InstallAtomicRedTeam {
    Add-MpPreference -ExclusionPath C:\AtomicRedTeam\
    IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1' -UseBasicParsing);
    Install-AtomicRedTeam -getAtomics
    add-content $profile "Import-Module C:\AtomicRedTeam\invoke-atomicredteam\Invoke-AtomicRedTeam.psd1 -Force"
}

function Purple-InstallMACAT {
    Set-MpPreference -DisableRealtimeMonitoring $true
    Add-MpPreference -ExclusionPath "C:\MACAT\"
    $msi = "$env:USERPROFILE\Downloads\MACAT_0.1.9_x64_en-US.msi"
    if (-not (test-path $msi)) {
        Invoke-WebRequest 'https://www.macat.io/download/files/MACAT_0.1.9_x64_en-US.msi' -OutFile $msi
    }
}


