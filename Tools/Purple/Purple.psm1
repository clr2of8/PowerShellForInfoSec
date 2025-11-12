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
        IEX (IWR "https://raw.githubusercontent.com/clr2of8/PowerShellForInfoSec/refs/heads/on_demand/Tools/windows-vm-setup.ps1" -UseBasicParsing)
    }
    elseif ($hostEntryType -eq "remote") {
        Write-Host "Running remote-vm-setup." -ForegroundColor Yellow
        IEX (IWR "https://raw.githubusercontent.com/clr2of8/PowerShellForInfoSec/refs/heads/on_demand/Tools/remote-vm-setup.ps1" -UseBasicParsing)

        # Define the desired hostname
        $desiredHostname = "REMOTE"
        
        # Get the current hostname
        $currentHostname = $env:COMPUTERNAME
        
        # Check if hostname needs to be changed
        if ($currentHostname -ne $desiredHostname) {
            Write-Host "Current hostname: $currentHostname"
            Write-Host "Changing hostname to: $desiredHostname"
            Rename-Computer -NewName $desiredHostname -Restart
        } else {
            Write-Host "Hostname is already set to: $desiredHostname"
            Write-Host "No changes needed."
        }
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

function Purple-InstallCursorAI {
    <#
    .SYNOPSIS
        Installs Cursor AI (Cursor Editor) on Windows.

    .DESCRIPTION
        Downloads and installs the latest Cursor AI (Cursor Editor) for Windows.

    .EXAMPLE
        Purple-InstallCursorAI
    #>
    Write-Host "Installing Cursor AI (Cursor Editor)..." -ForegroundColor Cyan

    # Define the download URL for the latest Cursor AI Windows installer (as of 2025-08)
    $cursorUrl = "https://downloads.cursor.com/production/d01860bc5f5a36b62f8a77cd42578126270db343/win32/x64/user-setup/CursorUserSetup-x64-1.4.2.exe"
    $installerPath = "$env:TEMP\CursorSetup.exe"

    try {
        $originalPreference = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        Write-Host "Downloading Cursor AI installer..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $cursorUrl -OutFile $installerPath -UseBasicParsing
        $ProgressPreference = $originalPreference

        Write-Host "Running Cursor AI installer silently..." -ForegroundColor Cyan
        Start-Process -FilePath $installerPath -ArgumentList "/S" -Wait

        Write-Host "Cursor AI installation complete." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to install Cursor AI: $_" -ForegroundColor Red
    }
    finally {
        if (Test-Path $installerPath) {
            Remove-Item $installerPath -Force
        }
    }
}

function Purple-GetRemoteVMIP {
    Write-Host "Determining Remote VM IP address..." -ForegroundColor Cyan
    
    try {
        $dnsResult = [System.Net.Dns]::GetHostAddresses("remote")
        $ipv4Address = $dnsresult.IPAddressToSTring
        return $ipv4Address
    }
    catch {
        Write-Error "Failed to determine VM IP address: $($_.Exception.Message)"
        return $null
    }
}

function Purple-AddRemoteVMHostsEntry {
    Write-Host "Adding Remote VM entry to Windows hosts file..." -ForegroundColor Cyan
    
    # Get the Remote VM IP address
    $vmIP = Purple-GetRemoteVMIP
    
    if (-not $vmIP) {
        Write-Error "Could not determine Remote VM IP address"
        return
    }
    
    # Define the hosts file path
    $hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"
    $hostname = "remote.cloudlab.lan"
    
    try {
        # Check if the entry already exists
        $hostsContent = Get-Content $hostsFile -ErrorAction Stop
        $existingEntry = $hostsContent | Where-Object { $_ -match "remote\.cloudlab\.lan" }
        
        if ($existingEntry) {
            Write-Host "Hosts entry already exists: $existingEntry" -ForegroundColor Yellow
            
            # Check if the IP matches
            if ($existingEntry -match $vmIP) {
                Write-Host "IP address is already correct: $vmIP" -ForegroundColor Green
                return
            } else {
                Write-Host "Updating existing entry with new IP: $vmIP" -ForegroundColor Yellow
                # Remove the old entry
                $hostsContent = $hostsContent | Where-Object { $_ -notmatch "remote\.cloudlab\.lan" }
            }
        }
        
        # Add the new entry
        $newEntry = "$vmIP`t$hostname"
        $hostsContent += $newEntry
        
        # Write the updated content back to the hosts file
        $hostsContent | Set-Content $hostsFile -Encoding ASCII
        
        Write-Host "Successfully added hosts entry: $newEntry" -ForegroundColor Green
        Write-Host "You can now use 'remote.cloudlab.lan' to access the VM" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to update hosts file: $($_.Exception.Message)"
        Write-Host "You may need to run PowerShell as Administrator to modify the hosts file" -ForegroundColor Yellow
    }
}

function Purple-ClearPowerShellHistory {
    Write-Host "Clearing PowerShell history..." -ForegroundColor Cyan
    
    try {
        # Get the PowerShell history file path
        $historyPath = (Get-PSReadlineOption).HistorySavePath
        
        if (-not $historyPath) {
            # Fallback to default location if PSReadlineOption doesn't work
            $historyPath = "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
        }
        
        Write-Host "History file location: $historyPath" -ForegroundColor Yellow
        
        if (Test-Path $historyPath) {
            # Get file size before deletion for reporting
            $fileSize = (Get-Item $historyPath).Length
            $fileSizeKB = [math]::Round($fileSize / 1KB, 2)
            
            # Delete the history file
            Remove-Item $historyPath -Force
            
            Write-Host "Successfully deleted PowerShell history file" -ForegroundColor Green
            Write-Host "Deleted file size: $fileSizeKB KB" -ForegroundColor Yellow
            
            # Also clear the current session history
            Clear-History -ErrorAction SilentlyContinue
            Write-Host "Cleared current session history" -ForegroundColor Green
            
        } else {
            Write-Host "PowerShell history file not found at: $historyPath" -ForegroundColor Yellow
            Write-Host "History may not exist or be stored in a different location" -ForegroundColor Gray
        }
        
        # Additional cleanup - clear other potential history locations
        $additionalPaths = @(
            "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt",
            "$env:LOCALAPPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
        )
        
        foreach ($path in $additionalPaths) {
            if (Test-Path $path) {
                Remove-Item $path -Force -ErrorAction SilentlyContinue
                Write-Host "Cleared additional history file: $path" -ForegroundColor Green
            }
        }
        
        Write-Host "PowerShell history cleanup completed!" -ForegroundColor Green
        
    }
    catch {
        Write-Error "Failed to clear PowerShell history: $($_.Exception.Message)"
    }
}
