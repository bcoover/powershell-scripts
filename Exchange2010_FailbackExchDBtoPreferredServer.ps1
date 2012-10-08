# Script to preempt or always failover the active database copy to the "preferred" server (based on preference number)
# This can be run interactively from the exchange powershell
# this script should be run from the preferred server, which implies it is functional
#   first subroutine to get and display status of each DB; if db is activated on the preferred server, the metric is in Exchange activation preference
#   second subroutine to move each DB to the preferred server, the metric is in Exchange activation preference

## INCREASE WINDOW WIDTH #####################################################

#prepare evenlog but only use if db is moved

function WidenWindow([int]$preferredWidth)
{
  [int]$maxAllowedWindowWidth = $host.ui.rawui.MaxPhysicalWindowSize.Width
  if ($preferredWidth -lt $maxAllowedWindowWidth)
  {
    # first, buffer size has to be set to windowsize or more
    # this operation does not usually fail
    $current=$host.ui.rawui.BufferSize
    $bufferWidth = $current.width
    if ($bufferWidth -lt $preferredWidth)
    {
      $current.width=$preferredWidth
      $host.ui.rawui.BufferSize=$current
    }
    # else not setting BufferSize as it is already larger
    
    # setting window size. As we are well within max limit, it won't throw exception.
    $current=$host.ui.rawui.WindowSize
    if ($current.width -lt $preferredWidth)
    {
      $current.width=$preferredWidth
      $host.ui.rawui.WindowSize=$current
    }
    #else not setting WindowSize as it is already larger
  }
}

WidenWindow(120)

function exitClean([string]$DBmoved)#should always exit program here
{
$text1 = "The DB: "
$text2 = " was moved from server: "
$text3 = " to server: "
$finalConcat = $text1+$DBmoved+$text2+$xNow+$text3+$dbown.key.name
Write-Output $finalConcat
writeEvent4614 $finalConcat
}

#function to write event to Windows if DB is moved
function writeEvent4614([string]$eventChangeMade)
{
$evt=new-object System.Diagnostics.EventLog("Application")
$evt.Source="Exchange DB Failback"
$infoevent=[System.Diagnostics.EventLogEntryType]::Warning
$1stpart="DB Failback Event for Exchange DB, "
$2ndpart=" , see log for more details at C:\Program Files\Microsoft\Exchange Server\V14\Logging\Failback_logs"
$eventStringfull=$1stpart+$eventChangeMade+$2ndpart
$evt.WriteEntry($eventStringfull,$infoevent,4614)
}

$startstring="Start script run at:  "
$startendtime=date
$startannounce=$startstring+$startendtime

#start Exchange Powershell snapins
cd\
Add-PSSnapin Microsoft.Exchange.Management.Powershell.Support
Add-PSSnapin  Microsoft.Exchange.Management.PowerShell.E2010


#start FailbackExchDBtoPreferredServer

Start-Transcript -Append -Force -Path 'C:\Program Files\Microsoft\Exchange Server\V14\Logging\Failback_logs\failback.log'
$startannounce
" "
"Status"
Get-MailboxDatabase | Sort Name | FOREACH {$db=$_.Name; $xNow=$_.Server.Name ;$dbown=$_.ActivationPreference| Where {$_.Value -eq 1};$quoteon=" on ";$quotesb=" Should be on ";If ( $xNow -ne $dbOwn.Key.Name){$stat=" WRONG"; }ELSE{$stat=" OK" };  $OutP=$db+$quoton+$xNow+$quotesb+$dbOwn.Key.Name+$stat; write-output $OutP}
" "
"Moves (if any)"
Get-MailboxDatabase | Sort Name | FOREACH {$db=$_.Name; $xNow=$_.Server.Name ;$dbown=$_.ActivationPreference| Where {$_.Value -eq 1};$quoteon=" on ";$quotesb=" Should be on ";If ( $xNow -ne $dbOwn.Key.Name){$stat=" MOVING..."; }ELSE{$stat=" OK" };  $OutP=$db+$quoton+$xNow+$quotesb+$dbOwn.Key.Name+$stat; write-output $OutP; If ( $xNow -ne $dbOwn.Key){Move-ActiveMailboxDatabase $db -ActivateOnServer $dbown.key.name -Confirm:$False; exitClean $db }}
" "

stop-transcript

#end FailbackExchDBtoPreferredServer

exit
