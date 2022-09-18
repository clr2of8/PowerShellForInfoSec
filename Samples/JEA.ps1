$capabilityName = 'SpoolerRestart'

############################################################################################
### Create the RoleCapabilities file (psrc) inside of a <module>\RoleCapabilities folder ###
############################################################################################

$roleCapabilitiesPath = "C:\Program Files\WindowsPowerShell\Modules\$capabilityName\RoleCapabilities"
New-Item -ItemType Directory $roleCapabilitiesPath -ErrorAction Ignore

$VisibleCmdlets = 'Get-Service',
                  @{ Name = 'Restart-Service'; Parameters = @{ Name = 'Name'; ValidateSet = 'Spooler' }},
                  @{ Name = 'Stop-Service'; Parameters = @{ Name = 'Name'; ValidateSet = 'Spooler' }}

New-PSRoleCapabilityFile -Path "$roleCapabilitiesPath\$capabilityName.psrc" -VisibleCmdlets $visibleCmdlets

###############################################################
#### Register the endpoint that the session will connect to ###
###############################################################

$sessionEndPointName = "$capabilityName`Endpoint"

$roleDefinitions = @{ 'PrinterAdmins' = @{RoleCapabilities = $capabilityName }}

New-PSSessionConfigurationFile -Path $env:Temp\$capabilityName.pssc -RoleDefinitions $roleDefinitions -SessionType RestrictedRemoteServer -RunAsVirtualAccount 
Register-PSSessionConfiguration -Name $sessionEndPointName -Path $env:Temp\$capabilityName.pssc -Force
