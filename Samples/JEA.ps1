#Requires -RunAsAdministrator

############################################################################################
### Create the RoleCapabilities file (psrc) inside of a <module>\RoleCapabilities folder ###
############################################################################################

$roleCapabilitiesPath = "C:\Program Files\WindowsPowerShell\Modules\SpoolerRestart\RoleCapabilities"
New-Item -ItemType Directory $roleCapabilitiesPath -ErrorAction Ignore

$VisibleCmdlets = 'Get-Service',
                  @{ Name = 'Restart-Service'; Parameters = @{ Name = 'Name'; ValidateSet = 'Spooler' }},
                  @{ Name = 'Stop-Service'; Parameters = @{ Name = 'Name'; ValidateSet = 'Spooler' }}


New-PSRoleCapabilityFile -Path "$roleCapabilitiesPath\SpoolerRestart.psrc" -VisibleCmdlets $visibleCmdlets

#############################################################################
### Create the Session Configuration file (pssc) in a temporary directory ###
#############################################################################

$args = @{
 Path = "$env:Temp\SpoolerRestart.pssc"
 RoleDefinitions = @{ 'PrinterAdmins' = @{RoleCapabilities = "SpoolerRestart" }}
 SessionType = "RestrictedRemoteServer"
 RunAsVirtualAccount = $true
}
New-PSSessionConfigurationFile @args

###############################################################
#### Register the endpoint that the session will connect to ###
###############################################################
 
Register-PSSessionConfiguration -Name "SpoolerRestartEndpoint" -Path $env:Temp\SpoolerRestart.pssc -Force
