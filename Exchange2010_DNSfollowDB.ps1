#this script simply watches what server the active Exchange database is on and sets the external DNS to the appropriate FQDN for that server


#must have the DnsShell module from http://code.msdn.microsoft.com/dnsshell 
Import-Module DnsShell

#load exchange2010 mgmt snapins
Add-PSSnapin Microsoft.Exchange.Management.Powershell.Support
Add-PSSnapin  Microsoft.Exchange.Management.PowerShell.E2010

#input global variables and declarations
$CnameName = "publicFQDNofMailServices.mydomain.com"
$cnames = $CnameName

$DBname1 = "MyDBname1"
$DBname2 = "MyDBname2"
$DBs = $DBname1,$DBname2
$Cname2DBArray = $DBname,$CnameName

$mail1DNS = "publicFQDN.mymailserver1.mydomain.com."
$mail2DNS = "publicFQDN.mymailserver2.mydomain.com."
$Arecords = $mail1DNS,$mail2DNS

$server1 = "ExchangeServername1"
$server2 = "ExchangeServername2"
$servers = $server1,$server2

$EXCHarray = $server1,$mail1DNS,$server2,$mail2DNS

$DnsServerVar = "domain-name"
$startstring="Start script run at:  "
$startendtime=date
$startannounce=$startstring+$startendtime
#end input global variables



#begin functions

#function to write event to Windows if DB is moved
function writeEvent6119([string]$eventChangeMade)
{
$evt=new-object System.Diagnostics.EventLog("Application")
$evt.Source="Exchange DNS follow DB"
$infoevent=[System.Diagnostics.EventLogEntryType]::Warning
$1stpart="DNS follows Exchange DB Event: "
$2ndpart=" , see log for more details at C:\Program Files\Microsoft\Exchange Server\V14\Logging\Failback_logs"
$eventStringfull=$1stpart+$eventChangeMade+$2ndpart
$evt.WriteEntry($eventStringfull,$infoevent,6119)
}


#Gets the current server name with the specified database active
function getCurrentServerName([string]$feedMeDB)
{
$currentServerinfo = Get-MailboxDatabase -identity $feedMeDB
Write-Output "Getting DB server list from Exchange..."
Write-Output $currentServerinfo
Set-Variable -name CurrentServerName -value $currentServerinfo.server.name -scope global
}


#gets the current DNS name associated with the CNAME record (what it's pointing to)
function getCurrentDNS([string]$currentCNAME)
{
Write-Output "Getting DNS records(s) from Domain Controllers..."
$dnsCMD1 = Get-DnsRecord $currentCNAME -Server $DnsServerVar
Set-Variable -name DNSget -value $dnsCMD1 -scope global
Set-Variable -name DNSrecord -value $DNSget.recordData -scope global
Set-Variable -name CnameID -value $DNSget.identity -scope global
}


#Make a change to the CNAME record with the new pointer passed to this function from the if clause below that matches where it should be
function setDNSchange([string]$newHostName)
{
Write-Output "Making DNS change... "
set-dnsrecord -server $DnsServerVar -identity $CnameID -Hostname $newHostName
}


#exit the program cleanly, announcing the change that was made (function called only if a change was made)
function exitClean([string]$changeMade)#should always exit program here
{
$text1 = "The DNS record: "
$text2 = " was changed from: "
$text3 = " to: "
$finalConcat = $text1+$tempCNAME+$text2+$DNSrecord+$text3+$changeMade
Write-Output $finalConcat
writeEvent6119 $finalConcat
}

#end functions



Start-Transcript -Append -Force -Path 'C:\Program Files\Microsoft\Exchange Server\V14\Logging\Failback_logs\DNSfollowsExchDB.log'
$startannounce
" "
#begin main program
#step 1 - call the function to get the active server name and display the results
FOREACH ($db in $DBs)
{
getCurrentServerName $db;
$ServerNamePosition = 0..($EXCHarray.length - 1) | where {$EXCHarray[$_] -eq $CurrentServerName}
$DNSnamePosition = $ServerNamePosition + 1
$correctDNS = $EXCHarray[$DNSnamePosition]

$dbNamePosition = 0..($Cname2DBArray.length - 1) | where {$Cname2DBArray[$_] -eq $db}
$CnamePosition = $dbNamePosition + 1
$tempCNAME = $Cname2DBArray[$CnamePosition]

#step 2 - call the function to get the active DNS record and display the results
getCurrentDNS $tempCNAME
Write-Output "Current DNS Record is: "
Write-Output $DNSget
Write-Output "Current WMI location of this record is: "
Write-Output $CnameID

#step 3 - makes changes as needed
If ($DNSrecord -ne $correctDNS)
{setDNSchange $correctDNS ; exitClean $correctDNS}
else{Write-Output "dns is correct for " $db}
}

#end main program
" "

stop-transcript


#exit default if no changes made
exit
