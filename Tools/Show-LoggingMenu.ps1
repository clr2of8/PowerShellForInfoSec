Import-Module C:\Users\IEUser\PowerShellForInfoSec\Tools\Set-PSLogging.ps1 -Force

$options = New-Object System.Collections.Generic.Dictionary"[Int,String]"
$options.add(1, "Enable-AllREasonableLogging")
$options.add(2, "Disable-AllLogging")
$options.add(3, "Show-AllLogging")
$options.add(4, "Enable-AllLogging")


while ($true) {
    Clear-Host
    Write-Host -ForegroundColor Yellow "**********************************************"
    Write-Host -ForegroundColor Yellow "Select your option:`n"

    foreach ($key in $options.keys) {
        Write-Host -ForegroundColor Yellow "$key) $($options[$key])"
    }

    Write-Host -ForegroundColor Yellow "`n*************************************************"
    Write-Host

    $optionSelected = Read-Host "Select your option (or q to quit) "
    if ($optionSelected -eq "q") { break }
    if($options.keys -contains $optionSelected){
        & $options[$optionSelected]
        Write-Host -NoNewLine "`nPress any key to continue..."
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}
