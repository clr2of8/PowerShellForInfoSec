# a script to build an example history to demo Ctrl+R and Ctrl+S
rm (Get-PSReadLineOption).HistorySavePath
Get-Content (Get-PSReadLineOption).HistorySavePath
ssh -i .ssh\mykey.priv 10.18.270.15
iex(iwr https://gist.githubusercontent.com/clr2of8/a1d6a3a50f6bd8e080e4cf45084c1325/raw/e281e5c595f6a63d8bfb5027c1a9196b43f6960e/asciiart2.ps1 -UseBasicParsing)
cd C:\Users\IEUser\PowerShellForInfoSec\Samples
ssh -i .ssh\mykey.priv 10.18.270.16
ssh -i .ssh\mykey.priv 10.18.270.17
ssh -i .ssh\mykey.priv 10.18.270.18
iex(iwr https://gist.githubusercontent.com/clr2of8/c5b3f563f3fffab1286fde4197da0894/raw/2e0896dbabcfbf8c5fba77bf86497281a51eb45c/asciiart.ps1 -UseBasicParsing)
mkdir Samples
