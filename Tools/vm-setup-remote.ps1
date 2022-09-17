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

# Turn off Automatic Sample Submission in Windows Defender
Write-Host "Turning off Automatic Sample Submission" -ForegroundColor Cyan
PowerShell Set-MpPreference -SubmitSamplesConsent 2

# Turn off screensaver and screen lock features for convenience
Powercfg /Change -monitor-timeout-ac 0
Powercfg /Change -standby-timeout-ac 0

Write-Host "Creating Desktop Shortcuts" -ForegroundColor Cyan
Copy-Item 'C:\Users\IEUser\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk' "C:\Users\IEUser\Desktop\PowerShell.lnk"

Write-Host "Writing class files to $env:USERPROFILE\PowerShellForInfoSec" -ForegroundColor Cyan
Get-ClassFiles 

Write-Host "Renaming the computer to PS4I" -ForegroundColor Cyan
Rename-Computer -NewName "PS4I-Remote" -Force -Restart
