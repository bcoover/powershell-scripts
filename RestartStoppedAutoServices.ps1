#this script restarts stopped services that are of startup mode "automatic"

$startstring="Start script run at:  "
$startendtime=date
$startannounce=$startstring+$startendtime

function RestartServices

{

Get-WmiObject Win32_Service | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' } | ft
Get-WmiObject Win32_Service | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' } | start-service
Get-WmiObject Win32_Service | Where-Object { $_.StartMode -eq 'Auto' -and $_.State -ne 'Running' } | ft

}

#start Exchange Powershell snapins
cd\

Start-Transcript -Append -Force -Path 'C:\scripts\RestartStoppedServices.log'
$startannounce

RestartServices
" "

stop-transcript

#end RestartStoppedExchServices

exit

 