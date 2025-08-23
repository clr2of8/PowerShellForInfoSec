#Requires -RunAsAdministrator

Write-Host -ForegroundColor Yellow "Disabling AV"
Set-MpPreference -DisableRealtimeMonitoring $true

Write-Host -ForegroundColor Yellow "Downloading and Extracting Invoke-Obfuscation"
Invoke-WebRequest 'https://github.com/danielbohannon/Invoke-Obfuscation/archive/refs/heads/master.zip' -OutFile "$env:USERPROFILE\PowerShellForInfoSec\Tools\Invoke-Obfuscation.zip"
Expand-Archive  "$env:USERPROFILE\PowerShellForInfoSec\Tools\Invoke-Obfuscation.zip" -Force -DestinationPath "$env:USERPROFILE\PowerShellForInfoSec\Tools\"

Write-Host -ForegroundColor Yellow "Importing Invoke-Obfuscation"
Import-Module "$env:USERPROFILE\PowerShellForInfoSec\Tools\Invoke-Obfuscation-master\Invoke-Obfuscation.psd1" -Force

Write-Host -ForegroundColor Green "Done! Use 'Invoke-Obfuscation' from this session to run the tool"
