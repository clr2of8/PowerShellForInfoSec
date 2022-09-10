$scriptBlockLoggingEventId = 4104
$moduleLoggingEventId = 4103
$scriptBlockExecutionStartEventId = 4105
$scriptBlockExecutionStopEventId = 4106


function Write-ColorCodedLogData ($logs) {
    foreach ($log in $logs) {
        $msg = ($log | Format-List | out-string)
        $color = "White"
        if ($log.Id -eq $scriptBlockLoggingEventId){
            $color = "Yellow"
        }
        elseif ($log.Id -eq $moduleLoggingEventId){
            $color = "Green"
        }
        elseif ($log.Id -eq $scriptBlockExecutionStartEventId){
            $color = "Magenta"
        }
        elseif ($log.Id -eq $scriptBlockExecutionStopEventId){
            $color = "Magenta"
        }

        Write-Host -ForegroundColor  "Magenta" -NoNewline "**************************** RecordId: $($log.RecordId)"
        write-host -ForegroundColor $color "$msg"
    }

}

# Get-WinEventTail function modified from https://stackoverflow.com/questions/15262196/powershell-tail-windows-event-log-is-it-possible
function Get-WinEventTail($LogName, $ShowExisting=2) {
    if ($ShowExisting -gt 0) {
        $data = (Get-WinEvent $LogName -max $ShowExisting | Sort-Object RecordId)
        Write-ColorCodedLogData $data
        $idx = $data[0].RecordId
    }
    else {
        $idx = (Get-WinEvent $LogName -max 1).RecordId
    }

    while ($true)
    {
        start-sleep -Seconds 1
        $idx2  = (Get-WinEvent $LogName -max 1).RecordId
        if ($idx2 -gt $idx) {
            $data = (Get-WinEvent $LogName -max ($idx2 - $idx) | Sort-Object RecordId)
            Write-ColorCodedLogData $data
        }
        $idx = $idx2

        # Any key to terminate; does NOT work in PowerShell ISE!
        # if ($Host.UI.RawUI.KeyAvailable) { return; }
    }
}

Get-WinEventTail 'Microsoft-Windows-PowerShell/Operational'
# $data = (Get-WinEvent 'Microsoft-Windows-PowerShell/Operational' -max 3 | sort RecordId )

# Write-ColorCodedLogData $data


