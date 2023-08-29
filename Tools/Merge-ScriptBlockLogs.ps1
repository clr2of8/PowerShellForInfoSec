#Requires -RunAsAdministrator

$allScriptLogEvents | Out-Null
function Merge-ScriptBlockLogs {

        [CmdletBinding()]
        param
        (
                [parameter(Mandatory = $false)][String]$keyword = "",
                [parameter(Mandatory = $false)][String]$outputFolder = $($PWD),
                [parameter(Mandatory = $false)][String]$logToSearch = "$env:WINDIR\System32\Winevt\Logs\Microsoft-Windows-PowerShell%4Operational.evtx",
                [parameter(Mandatory = $false)][Switch]$useCachedEvents
        )

        $filter = @{ 
                Path         = $logToSearch;
                ProviderName = "Microsoft-Windows-PowerShell"
                Id           = 4104 
        }

        if (($null -eq $script:allScriptLogEvents) -or (-not $useCachedEvents)) { 
                Write-Host -Fore Yellow "Loading event logs. This can take several minutes. Use the '-useCachedEvents' use events from the last run of this script."
                $script:allScriptLogEvents = Get-WinEvent -FilterHashtable $filter 
        }
        $eventsOfInterest = $allScriptLogEvents  | Where-Object { $_.Message -like "*$keyword*" }

        if ($eventsOfInterest) {
                $scriptBlockIDs = $eventsOfInterest | Group-Object -Property { $_.Properties[3].Value } -noelement | Select-Object Name
                $foundMultiPartEvents = $false
                foreach ($scriptBlockID in $scriptBlockIDs.Name) {
                        $events = $allScriptLogEvents | Where-Object { $_.Properties[3].Value -eq $scriptBlockID } | Sort-Object { $_.Properties[0].Value }
                        $count = $events.properties[1].Value
                        if ($count -gt 1) {
                                $foundMultiPartEvents = $true
                                Write-Host -ForegroundColor Cyan "Found $count message(s) for ScriptBlockID: $scriptBlockID"
                                $outfile = Join-Path $outputFolder "$scriptBlockID.txt"
                                if($events.count -ne $count){$outfile = Join-Path $outputFolder "$scriptBlockID-MISSING-PARTS.txt"}
                                Write-Host -ForegroundColor Cyan "Writing $count part message to $outfile"
                                -join ($events  | ForEach-Object { $_.Properties[2].Value }) | Out-File "$outfile"
                        } 
                }
                if (-not $foundMultiPartEvents) { Write-Host -ForegroundColor Yellow "No multipart events found" }
        }
        else {
                Write-host -ForegroundColor yellow "No events found."
        }
}
#Merge-ScriptBlockLogs -useCachedEvents -Keyword "Inveigh"
