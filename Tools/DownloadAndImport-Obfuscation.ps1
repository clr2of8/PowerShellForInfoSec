#Requires -RunAsAdministrator

Write-Host -ForegroundColor Yellow "Disabling AV"
Set-MpPreference -DisableRealtimeMonitoring $true

Write-Host -ForegroundColor Yellow "Downloading and Extracting Invoke-Obfuscation"
Invoke-WebRequest 'https://github.com/danielbohannon/Invoke-Obfuscation/archive/refs/heads/master.zip' -OutFile 'C:\Users\IEUser\PowerShellForInfoSec\Tools\Invoke-Obfuscation.zip'
Expand-Archive  'C:\Users\IEUser\PowerShellForInfoSec\Tools\Invoke-Obfuscation.zip' -Force -DestinationPath 'C:\Users\IEUser\PowerShellForInfoSec\Tools\'

Write-Host -ForegroundColor Yellow "Importing Invoke-Obfuscation"
Import-Module 'C:\Users\IEUser\PowerShellForInfoSec\Tools\Invoke-Obfuscation-master\Invoke-Obfuscation.psd1' -Force

Write-Host -ForegroundColor Greem "Done! Use Invoke-Obfuscation from this session to run the tool"
