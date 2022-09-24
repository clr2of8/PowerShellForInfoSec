Function Install-Application($Url, $flags) {
    $LocalTempDir = $env:TEMP
    $Installer = "Installer.exe"
    (new-object  System.Net.WebClient).DownloadFile($Url, "$LocalTempDir\$Installer")
    & "$LocalTempDir\$Installer" $flags
    $Process2Monitor = "Installer"
    Do {
        $ProcessesFound = Get-Process | ? { $Process2Monitor -contains $_.Name } | Select-Object -ExpandProperty Name
        If ($ProcessesFound) { Write-Host "." -NoNewline -ForegroundColor Yellow; Start-Sleep -Seconds 2 } 
        else { Write-Host "Done" -ForegroundColor Cyan; rm "$LocalTempDir\$Installer" -ErrorAction SilentlyContinue }
    } 
    Until (!$ProcessesFound)
}

function Get-ClassFiles {
    $PS4InfoSecPath = "$env:USERPROFILE\PowerShellForInfoSec"
    if (Test-Path $PS4InfoSecPath) { Remove-Item -Path $PS4InfoSecPath -Recurse -Force -ErrorAction Stop | Out-Null }
    New-Item -ItemType directory -Path $PS4InfoSecPath | Out-Null
    $url = "https://github.com/clr2of8/PowerShellForInfoSec/archive/refs/heads/main.zip"
    $path = Join-Path $PS4InfoSecPath "$main.zip"
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest $url -OutFile $path
    expand-archive -LiteralPath $path -DestinationPath "$PS4InfoSecPath" -Force:$Force
    $mainFolderUnzipped = Join-Path  $PS4InfoSecPath "PowerShellForInfoSec-main"
    Get-ChildItem -Path $mainFolderUnzipped -Recurse | Move-Item -Destination $PS4InfoSecPath
    Remove-Item $mainFolderUnzipped -Recurse -Force
    Remove-Item $path -Recurse
}

Remove-Item 'C:\Users\IEUser\Desktop\eula.lnk' -ErrorAction Ignore

# install Chrome (must be admin)
$property = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction Ignore
if ( -not ($property -and $property.'(Default)')) {
    Write-Host "Installing Chrome" -ForegroundColor Cyan
    $flags = '/silent', '/install'
    Install-Application 'http://dl.google.com/chrome/install/375.126/chrome_installer.exe' $flags
}

# install Notepad++
if (-not (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*  | where-Object DisplayName -like 'NotePad++*')) {
    Write-Host "Installing Notepad++" -ForegroundColor Cyan
    Install-Application 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.3.3/npp.8.3.3.Installer.x64.exe' '/S'
}

# add Desktop shortcuts
Write-Host "Creating Desktop Shortcuts" -ForegroundColor Cyan
Copy-Item 'C:\Users\IEUser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk' "C:\Users\IEUser\Desktop\PowerShell.lnk"
Copy-Item 'C:\Users\IEUser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\System Tools\Command Prompt.lnk' "C:\Users\IEUser\Desktop\Command Prompt.lnk"
Copy-Item 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Notepad++.lnk' "C:\Users\IEUser\Desktop\Notepad++.lnk"

# Turn off Automatic Sample Submission in Windows Defender
Write-Host "Turning off Automatic Sample Submission" -ForegroundColor Cyan
PowerShell Set-MpPreference -SubmitSamplesConsent 2

# Turn off screensaver and screen lock features for convenience
Powercfg /Change -monitor-timeout-ac 0
Powercfg /Change -standby-timeout-ac 0

if(-not (Test-Path $env:USERPROFILE\Desktop\"Process Explorer.exe")){
  Write-Host "Downloading Process Explorer from Microsoft SysInternals to Desktop" -ForegroundColor Cyan
  Invoke-WebRequest https://live.sysinternals.com/procexp.exe -OutFile $env:USERPROFILE\Desktop\"Process Explorer.exe"
}

Write-Host "Writing class files to $env:USERPROFILE\PowerShellForInfoSec" -ForegroundColor Cyan
Get-ClassFiles 
# compile log watcher tool and put on the desktop
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /out:C:\Users\IEuser\Desktop\TailPSopLog.exe C:\Users\IEUser\PowerShellForInfoSec\Tools\TailPSopLog.cs | Out-Null

$computerName = "PS4I"
if($env:COMPUTERNAME -ne $computerName){
  Write-Host "Renaming the computer to $computerName" -ForegroundColor Cyan
  Start-Sleep 3
  Rename-Computer -NewName $computerName -Force -Restart
}
