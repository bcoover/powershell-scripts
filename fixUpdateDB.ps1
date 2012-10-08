cd\
cls

#load exchange2010 mgmt snapins
Add-PSSnapin Microsoft.Exchange.Management.Powershell.Support
Add-PSSnapin  Microsoft.Exchange.Management.PowerShell.E2010

#input global variables and declarations
$startstring="Start script run at:  "
$startendtime=date
$startannounce=$startstring+$startendtime
#end input global variables

#begin functions

#function to write event to Windows if DB is moved
function writeEvent1131([string]$eventChangeMade)
{
$evt=new-object System.Diagnostics.EventLog("Application")
$evt.Source="Exchange attempt to update DB copy"
$infoevent=[System.Diagnostics.EventLogEntryType]::Warning
$1stpart="Exchange attempt to fix DB with Update: "
$2ndpart=" , see log for more details at C:\Program Files\Microsoft\Exchange Server\V14\Logging\Failback_logs"
$eventStringfull=$1stpart+$eventChangeMade+$2ndpart
$evt.WriteEntry($eventStringfull,$infoevent,1131)
}

#exit the program cleanly, announcing the change that was made (function called only if a change was made)
function exitClean([string]$changeMade)
{
$text1 = "The Database Copy: "
$text2 = " was attempted to be updated and re-mounted "
$finalConcat = $text1+$changeMade+$text2
Write-Output $finalConcat
writeEvent1131 $finalConcat
}

#attempt to update the failed database
function updateDBnow([string]$passedID)
{
Update-MailboxDatabaseCopy -Force -Identity $passedID
}
#attempt to update the failed database
function updateDBnowDeleteFiles([string]$passedID)
{
Update-MailboxDatabaseCopy -Force -Identity $passedID -DeleteExistingFiles
}

#end functions

Start-Transcript -Append -Force -Path 'C:\Program Files\Microsoft\Exchange Server\V14\Logging\Failback_logs\DNSfollowsExchDB.log'
$startannounce
" "
#begin main program
#identify any database copies in the failed state and pass their identity to the updateDBnow function
Get-MailboxDatabase | Sort Name | FOREACH{$db=$_.Name; Get-MailboxDatabaseCopyStatus -Identity $db | FOREACH{If($_.Status -eq "FailedAndSuspended"){$PassID = $_.Identity;updateDBnow $PassID;exitClean $PassID}ELSE{write-host "Database: " $_.Name " is: " $_.Status "  Mounted on: " $_.MailBoxServer}}}

Get-MailboxDatabase | Sort Name | FOREACH{$db=$_.Name; Get-MailboxDatabaseCopyStatus -Identity $db | FOREACH{If($_.Status -eq "FailedAndSuspended"){$PassID = $_.Identity;updateDBnowDeleteFiles $PassID;exitClean $PassID}ELSE{write-host "Database: " $_.Name " is: " $_.Status "  Mounted on: " $_.MailBoxServer}}}

#end main program
" "
stop-transcript

#exit default if no changes made
exit
