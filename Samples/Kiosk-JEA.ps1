#Requires -RunAsAdministrator

$modulePath = Join-Path $env:ProgramFiles "WindowsPowerShell\Modules\Unrestricted"
$null = New-Item -ItemType Directory -Path $modulePath
New-ModuleManifest -Path (Join-Path $modulePath Unrestricted.psd1)

## Create an initialization script for the Unrestricted role that
## re-enables Full Language mode from Lee Holmes PowerShell CookBook
Set-Content -Path (Join-Path $modulePath init.ps1) -Value @"
`$null = [PowerShell]::Create().AddScript(@'
    param(`$rs)
    while(`$rs.RunspaceAvailability -ne `"Available`") {
        Start-Sleep -Milliseconds 500 }
    `$rs.LanguageMode = `"FullLanguage`"
'@).AddArgument([Runspace]::DefaultRunspace).BeginInvoke()
"@

############################################################################################
### Create the RoleCapabilities file (psrc) inside of a <module>\RoleCapabilities folder ###
############################################################################################

$roleCapabilitiesPath = "C:\Program Files\WindowsPowerShell\Modules\Kiosk\RoleCapabilities"
New-Item -ItemType Directory $roleCapabilitiesPath -ErrorAction Ignore
$VisibleCmdlets = 'Restart-Computer'
New-PSRoleCapabilityFile -Path "$roleCapabilitiesPath\Kiosk.psrc" -VisibleCmdlets $visibleCmdlets

$roleCapabilitiesPath = "C:\Program Files\WindowsPowerShell\Modules\Unrestricted\RoleCapabilities"
New-Item -ItemType Directory $roleCapabilitiesPath -ErrorAction Ignore
New-PSRoleCapabilityFile -Path "$roleCapabilitiesPath\Unrestricted.psrc" -VisibleAliases * `
-VisibleCmdlets * -VisibleFunctions * -VisibleExternalCommands * `
-VisibleProviders * -ScriptsToProcess (Join-Path $modulePath init.ps1)

#############################################################################
### Create the Session Configuration file (pssc) in a temporary directory ###
#############################################################################

$argsSC = @{
 Path = "$env:Temp\Kiosk.pssc"
 RoleDefinitions = @{ 
    'KioskUsers' = @{RoleCapabilities = "Kiosk" }
    'Administrators' = @{RoleCapabilities = "Unrestricted" }}
 SessionType = "RestrictedRemoteServer"
 RunAsVirtualAccount = $true
}
New-PSSessionConfigurationFile @argsSC

###############################################################
#### Register the endpoint that the session will connect to ###
###############################################################
 
Register-PSSessionConfiguration -Name "KioskEndpoint" -Path $env:Temp\Kiosk.pssc -Force
