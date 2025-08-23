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
        Write-Host "Detected windows.cloudlab.lan in hosts file. Running windows-vm-setup." -ForegroundColor Cyan
        IEX (IWR "https://raw.githubusercontent.com/clr2of8/PowerShellForInfoSec/refs/heads/main/Tools/windows-vm-setup.ps1" -UseBasicParsing)
    }
    elseif ($hostEntryType -eq "remote") {
        Write-Host "Detected remote.cloudlab.lan in hosts file. Running remote-vm-setup." -ForegroundColor Cyan
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

function Purple-PatchCaldera {
    Install-Module -Name Posh-SSH -Force -ErrorAction Ignore
    $password = ConvertTo-SecureString "metarange" -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ("ubuntu", $password)
    Get-SSHSession | Remove-SSHSession
    $sess = New-SSHSession -ComputerName linux.cloudlab.lan -Credential $cred -Force
    $commands = @(
        "sudo kill -9 `$(sudo lsof -t -i :8888)",
        "sed -i -r ""s/app.frontend.api_base_url: .*$/app.frontend.api_base_url: http:\/\/linux.cloudlab.lan:8888/g"" ~/caldera/conf/local.yml",
        "sed -i -r ""s/app.contact.http: .*$/app.contact.http: http:\/\/linux.cloudlab.lan:8888/g"" ~/caldera/conf/local.yml",
        "cd ~/caldera; .venv//bin//python3 server.py --build",
        "sudo kill -9 `$(sudo lsof -t -i :8888)"
    )
    foreach ($command in $commands) {
        invoke-sshcommand -SSHSession $sess -Command $command -ShowStandardOutputStream -ShowErrorOutputStream -TimeOut 300
    }
    $sess | Remove-SSHSession
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


