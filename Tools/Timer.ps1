  function Timer{
    param (
     [Parameter(Position = 0)]
      [int]$Minutes = 0,
      [Parameter(Position = 1)]
      [int]$Seconds = 0
    )
    Clear-Host
    $t = New-TimeSpan -Minutes $Minutes -Seconds $Seconds
    $remain = $t
    $d =( get-date) + $t
    $remain = ($d - (get-date))
    while ($remain.TotalSeconds -gt 0){
     $progress = (($t - $remain).TotalSeconds)/$t.TotalSeconds*100
      Write-Progress -Activity "Class Timer" -Status $("Class will resume in {0:d2}m {1:d2}s " -f  $remain.Minutes, $remain.Seconds) -PercentComplete $progress
      Start-Sleep 1
      $remain = ($d - (get-date))
    }
  }
