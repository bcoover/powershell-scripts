# Sometimes Windows services crash and Microsoft's built-in restart capabilities are weak
# this script restarts stopped services that are of startup mode "automatic"
# this is meant to be run on a regular basis by task manager
# future improvement would be to make this either explicit for certain services, 
# or opt-out for certain services that are meant to be left in automatic mode, 
# but not be running all the time (like MSSQL agent)

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

 