# iex (iwr https://raw.githubusercontent.com/clr2of8/PowerShellForInfoSec/refs/heads/main/Tools/windows-vm-setup.ps1 -UseBasicParsing)

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

Function Add-TestUsers {
    # Add test users and groups
    New-LocalGroup PrinterAdmins -ErrorAction Ignore
    $pswd = ConvertTo-SecureString "Passw0rd!" -AsPlainText -Force
    New-LocalUser -Name bob -Password $pswd -PasswordNeverExpires -ErrorAction Ignore
    Add-LocalGroupMember -Group PrinterAdmins -Member bob -ErrorAction Ignore
    New-LocalUser -Name RemoteMgmtUser -Password $pswd -PasswordNeverExpires -ErrorAction Ignore
    Add-LocalGroupMember -Group "Remote Management Users" -Member RemoteMgmtUser -ErrorAction Ignore
}
    
# install Chrome (must be admin)
$property = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\chrome.exe' -ErrorAction Ignore
if ( -not ($property -and $property.'(Default)')) {
    Write-Host "Installing Chrome" -ForegroundColor Cyan
    $flags = '/silent', '/install'
    Install-Application 'http://dl.google.com/chrome/install/375.126/chrome_installer.exe' $flags
}

Remove-Item "$env:USERPROFILE\Desktop\Microsoft Edge.lnk" -ErrorAction Ignore
# Add Class Timer module
new-item -Type Directory "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Timer" -ErrorAction ignore | out-null
Invoke-WebRequest https://raw.githubusercontent.com/clr2of8/PowerShellForInfoSec/refs/heads/main/Tools/Timer.psm1 -OutFile "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\Timer\Timer.psm1" -ErrorAction ignore | out-null

# Installing Chrome Bookmarks
Write-Host "Installing Chrome Bookmarks" -ForegroundColor Cyan
$bookmarksFile = "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
if(-not (test-path $bookmarksFile)){
  start-process chrome; sleep 3 # must start chrome before bookmarks file exists
}
Invoke-WebRequest "https://raw.githubusercontent.com/clr2of8/PowerShellForInfoSec/main/Tools/Shortcuts/Bookmarks" -OutFile "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\Default\Bookmarks"
Stop-Process -Name "chrome" -Force -ErrorAction Ignore

# install Notepad++
if (-not (Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*  | where-Object DisplayName -like 'NotePad++*')) {
    Write-Host "Installing Notepad++" -ForegroundColor Cyan
    Install-Application 'https://github.com/notepad-plus-plus/notepad-plus-plus/releases/download/v8.5/npp.8.5.Installer.x64.exe' '/S'
}

Write-Host "Writing class files to $env:USERPROFILE\PowerShellForInfoSec" -ForegroundColor Cyan
Get-ClassFiles
# compile log watcher tool and put on the desktop
Stop-Process -Name TailPSopLog -ErrorAction Ignore
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /out:C:\Users\art\Desktop\TailPSopLog.exe C:\Users\art\PowerShellForInfoSec\Tools\TailPSopLog.cs | Out-Null

# add Desktop shortcuts
Write-Host "Creating Desktop Shortcuts" -ForegroundColor Cyan
Copy-Item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Windows PowerShell\Windows PowerShell.lnk" "$env:USERPROFILE\Desktop\PowerShell.lnk"
Copy-Item "$env:USERPROFILE\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\System Tools\Command Prompt.lnk" "$env:USERPROFILE\Desktop\Command Prompt.lnk"
Copy-Item 'C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Notepad++.lnk' "$env:USERPROFILE\Desktop\Notepad++.lnk"
$TargetFile = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
$ShortcutFile = "$env:USERPROFILE\PowerShellForInfoSec\LogMenu.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$shortcut.Arguments = "-file $env:USERPROFILE\PowerShellForInfoSec\Tools\LogMenu.ps1"
$Shortcut.Save()
$TargetFile = "$env:USERPROFILE\PowerShellForInfoSec"
$ShortcutFile = "$env:USERPROFILE\Desktop\PowerShell For InfoSec.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()
$TargetFile = "C:\Program Files\Microsoft VS Code\Code.exe"
$ShortcutFile = "$env:USERPROFILE\Desktop\Visual Studio Code.lnk"
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Save()
$TargetFile = "$env:USERPROFILE\Desktop\TailPSopLog.exe"
$ShortcutFile = "$env:USERPROFILE\Desktop\PWSH (Core) log tail.lnk"
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetFile
$Shortcut.Arguments = "core"
$Shortcut.Save()

# Turn off Automatic Sample Submission in Windows Defender
Write-Host "Turning off Automatic Sample Submission" -ForegroundColor Cyan
PowerShell Set-MpPreference -SubmitSamplesConsent 2

# Turn off screensaver and screen lock features for convenience
Powercfg /Change -monitor-timeout-ac 0
Powercfg /Change -standby-timeout-ac 0
