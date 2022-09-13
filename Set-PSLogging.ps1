$msg = "Note: Logging changes only affect new PowerShell Sessions."
function Set-PSScriptBlockLogging {

    param ([switch]$disable)

    $basePath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"

    if ($disable) {
        Remove-ItemProperty -Path $basePath -Name EnableScriptBlockLogging -Force -ErrorAction Ignore
    }
    else {
        if (-not (Test-Path $basePath)) {
            $null = New-Item $basePath -Force
        }
        Set-ItemProperty $basePath -Name EnableScriptBlockLogging -Value 1
    }
    Get-ItemProperty $basePath
	Write-Host -Fore Red $msg
}

function Set-PSScriptBlockInvocationLogging {

    param ([switch]$disable)

    $basePath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"

    if ($disable) {
        Remove-ItemProperty -Path $basePath -Name EnableScriptBlockInvocationLogging -Force -ErrorAction Ignore
    }
    else {
        if (-not (Test-Path $basePath)) { $null = New-Item $basePath -Force }
        Set-ItemProperty $basePath -Name EnableScriptBlockInvocationLogging -Value 1
    }

    Get-ItemProperty $basePath
	Write-Host -Fore Red $msg
}

function Set-PSModuleLogging {

    param ([switch]$disable)

    $basePath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging"
    $basePath2 = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ModuleLogging\ModuleNames"    

    if ($disable) {
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
    
        Set-ItemProperty $basePath2 -Name EnableModuleLogging -Value 1
        Set-ItemProperty $basePath2 -Name "*" -Value "*"
    }
    Get-ItemProperty $basePath
	Write-Host -Fore Red $msg

}

function Set-PSTranscriptionLogging {
    param ([switch]$disable)

    $basePath = "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\Transcription"
    $transcriptPath = "C:\ProgramData\WindowsPowerShell\Transcripts"

    if ($disable) {
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

        $transcriptPath = "C:\ProgramData\WindowsPowerShell\Transcripts"
        Set-ItemProperty $basePath -Name OutputDirectory -Value $transcriptPath  
    }

    Get-ItemProperty $basePath
	Write-Host -Fore Red $msg
}

function Enable-AllReasonableLogging{
 Set-PSScriptBlockLogging
 Set-PSModuleLogging
 Set-PSTranscriptionLogging
}

function Disable-AllLogging {
 Set-PSScriptBlockLogging -disable
 Set-PSModuleLogging -disable
 Set-PSTranscriptionLogging -disable
 Set-PSScriptBlockInvocationLogging -disable
}

function Enable-AllLogging {
	Enable-AllReasonableLogging
 Set-PSScriptBlockInvocationLogging
} 
