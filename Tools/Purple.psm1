function Purple-Redeploy {
    IEX (IWR "https://raw.githubusercontent.com/clr2of8/PurpleTeaming/refs/heads/main/Tools/windows-vm-setup.ps1" -UseBasicParsing)
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


