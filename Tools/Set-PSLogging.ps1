#Requires -RunAsAdministrator

$msg = "Note: Logging changes only affect new PowerShell Sessions."
Write-Host -Fore Red -BackgroundColor White $msg

function Write-Status ($basePath, $key) {
    if (Test-Path $basePath) {
        $value = (Get-ItemProperty $basePath).$key
        if ($value) {
            Write-Host -ForegroundColor Green "Enabled"
        }
        elseif ($null -eq $value) {
            Write-Host -ForegroundColor Gray "Not Configured"
        }
        else {
            Write-Host -ForegroundColor Red "Explicity Disabled"
        }
    }
    else {
        Write-Host -ForegroundColor Gray "Not Configured"
    }
}
function Set-PSScriptBlockLogging {

    param (
        [switch]$disable,
        [switch]$ExplicitDisable,
        [switch]$show
    )

    $basePath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"

    if ($show) {
        Write-Host -ForegroundColor Yellow -NoNewline "Script Block Logging: "
        Write-Status $basePath EnableScriptBlockLogging
        return
    }
   

    if ($ExplicitDisable) {
        if (-not (Test-Path $basePath)) {
            $null = New-Item $basePath -Force
        }
        Set-ItemProperty $basePath -Name EnableScriptBlockLogging -Value 0
    }
    elseif ($disable) {
        Remove-ItemProperty -Path $basePath -Name EnableScriptBlockLogging -Force -ErrorAction Ignore
    }
    else {
        if (-not (Test-Path $basePath)) {
            $null = New-Item $basePath -Force
        }
        Set-ItemProperty $basePath -Name EnableScriptBlockLogging -Value 1
    }
    Set-PSScriptBlockLogging -show
}

function Set-PSScriptBlockInvocationLogging {

    param (
        [switch]$disable,
        [switch]$ExplicitDisable,
        [switch]$show
    )

    $basePath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"

    if ($show) {
        Write-Host -ForegroundColor DarkGray -NoNewline "Script Block Invocation Logging: "
        Write-Status $basePath EnableScriptBlockInvocationLogging
        return
    }
   
    if ($ExplicitDisable) {
        if (-not (Test-Path $basePath)) { $null = New-Item $basePath -Force }
        Set-ItemProperty $basePath -Name EnableScriptBlockInvocationLogging -Value 0
    }
    elseif ($disable) {
        Remove-ItemProperty -Path $basePath -Name EnableScriptBlockInvocationLogging -Force -ErrorAction Ignore
    }
    else {
        if (-not (Test-Path $basePath)) { $null = New-Item $basePath -Force }
        Set-ItemProperty $basePath -Name EnableScriptBlockInvocationLogging -Value 1
    }

    Set-PSScriptBlockInvocationLogging -show
}

function Set-PSModuleLogging {

    param (
        [switch]$disable,
        [switch]$ExplicitDisable,
        [switch]$show
    )

    $basePath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
    $basePath2 = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames"    

    if ($show) {
        Write-Host -ForegroundColor Cyan -NoNewline "Module Logging: "
        Write-Status $basePath EnableModuleLogging
        if (test-path $basePath2) {
            Write-Host "  --> Module Names: $((Get-ItemProperty $basePath2).'*')"
        }
        return
    }

    if ($ExplicitDisable) {
        if (-not (Test-Path $basePath)) {
            $null = New-Item $basePath -Force
        }
        Set-ItemProperty $basePath -Name EnableModuleLogging -Value 0
    }
    elseif ($disable) {
        Remove-ItemProperty -Path $basePath -Name EnableModuleLogging -Force -ErrorAction Ignore
        Remove-ItemProperty $basePath2 -Name EnableModuleLogging  -Force -ErrorAction Ignore
    }
    else {
        if (-not (Test-Path $basePath)) {
            $null = New-Item $basePath -Force
        }
        Set-ItemProperty $basePath -Name EnableModuleLogging -Value 1
    
        if (-not (Test-Path $basePath2)) {
            $null = New-Item $basePath2 -Force
        }
    
        # Set-ItemProperty $basePath2 -Name EnableModuleLogging -Value 1
        Set-ItemProperty $basePath2 -Name "*" -Value "*"
    }
    Set-PSModuleLogging -show
}

function Set-PSTranscriptionLogging {
    param (
        [switch]$disable,
        [switch]$ExplicitDisable,
        [switch]$show
    )

    $basePath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription"
    $transcriptPath = "$env:USERPROFILE\PSTranscripts"

    if ($show) {
        Write-Host -ForegroundColor Magenta -NoNewline "Transcription Logging: "
        Write-Status $basePath EnableTranscripting
        Write-Host -NoNewline "  --> Include Invocation Headers: "; Write-Status $basePath EnableInvocationHeader
        if (test-path $basePath) {
            Write-Host "  --> Transcript Path: $((Get-ItemProperty $basePath).OutputDirectory)"
        }

        return
    }

    if ($ExplicitDisable) {
        if (-not (Test-Path $basePath)) {
            $null = New-Item $basePath -Force
        }
        Set-ItemProperty $basePath -Name EnableTranscripting -Value 0
        Set-ItemProperty $basePath -Name EnableInvocationHeader -Value 0
    }
    elseif ($disable) {
        $Name = "EnableTranscripting"
        Remove-ItemProperty -Path $basePath -Name $name -Force -ErrorAction Ignore
        $Name = "EnableInvocationHeader"
        Remove-ItemProperty -Path $basePath -Name $name -Force -ErrorAction Ignore
    }
    else {
        if (-not (Test-Path $basePath)) {
            $null = New-Item $basePath -Force
        }
        Set-ItemProperty $basePath -Name EnableTranscripting -Value 1
        Set-ItemProperty $basePath -Name EnableInvocationHeader -Value 1

        Set-ItemProperty $basePath -Name OutputDirectory -Value $transcriptPath  
    }

    Set-PSTranscriptionLogging -show
}

function Enable-AllReasonableLogging {
    Set-PSScriptBlockLogging
    Set-PSModuleLogging
    Set-PSTranscriptionLogging
    Set-PSScriptBlockInvocationLogging -disable
}

function Disable-AllLogging {
    param (
        [switch]$ExplicitDisable
    )
    if ($ExplicitDisable) {
        Set-PSScriptBlockLogging -ExplicitDisable
        Set-PSModuleLogging -ExplicitDisable
        Set-PSTranscriptionLogging -ExplicitDisable
        Set-PSScriptBlockInvocationLogging -ExplicitDisable    

    }
    else {
        Set-PSScriptBlockLogging -disable
        Set-PSModuleLogging -disable
        Set-PSTranscriptionLogging -disable
        Set-PSScriptBlockInvocationLogging -disable    
    }
}

function Enable-AllLogging {
    Enable-AllReasonableLogging
    Set-PSScriptBlockInvocationLogging
} 

function Show-AllLogging {
    Set-PSScriptBlockLogging -show
    Set-PSModuleLogging -show
    Set-PSTranscriptionLogging -show
} 
