#         (mm)
#        w/ o w
#       /oo__/ \
#         /     \
#   qqqqqQ/      \Qqqqqq
# qqQ(   MM  |  Ss   )Qqq
#   qQ(  Mm  |  sS  )Qq
# qqqQ(------|------)Qqqq 
#    qQ( RR  |  D  )Qq
#      A(    |    )A
#	  AAAAAAAAA
#          bbbbb
#Bully by Ji Min Sha
#Version: 2.0.2
#Updated: 19 Jun. 2022
#
#Legal: 
#All responsibilities regarding the usage of this script remains with the user with no exception.
#Any incomplete limitation of legal liability prohibits all usages of users under such jurisdiction.
#
#Notes:
#Bully is a powershell script designed to block/unblock specific countries using ISO 3166-1 alpha-2 code (2 digit country code).
#
#
#
#
#

param ($InputFile, $CountryCode, $ProfileType = "any", $InterfaceType = "any")

$CountryCode = Read-Host "Enter 2 digit country code: " #asks country code.
if ($CountryCode.Length -gt 2){				  #checks formatting.
	Write-Host "ONLY ISO 3166-1 alpha-2 is accepted!" #if length invalid, quit.
	return
}

$InputFile = $CountryCode + ".zone" #concatenates country code with extension.

if(!(Test-Path .\$InputFile))		#if file doesn't exist, quit
{
    Write-Host "The zone file does not exist! Are you sure you the country is real?"
    return
}
else
{
continue
}

# Create array of IP ranges; any line that doesn't start like an IPv4/IPv6 address is ignored.
$ranges = get-content $InputFile | Where-Object {($_.trim().length -ne 0) -and ($_ -match '^[0-9a-f]{1,4}[\.\:]')} 
if (-not $?) { "`nCould not parse $InputFile, quitting...`n" ; exit } 
$linecount = $ranges.count
if ($linecount -eq 0) { "`nNo IP addresses to block!`n" ; exit } 


function Undo-Block-Country
{
# Any existing firewall rules which match the name are deleted every time the script runs.
$currentrules = netsh.exe advfirewall firewall show rule name=all | select-string '^[Rule Name|Regelname]+:\s+(.+$)' | ForEach-Object { $_.matches[0].groups[1].value } 
if ($currentrules.count -lt 3) {"`nProblem getting a list of current firewall rules, quitting...`n" ; exit } 
# Note: If you are getting the above error, try editing the regex pattern two lines above to include the 'Rule Name' in your local language.
$currentrules | ForEach-Object { if ($_ -like "$rulename-#*"){ netsh.exe advfirewall firewall delete rule name="$_" | out-null } } 

Write-Host "Done!"
return
}

function Block-Country
{
$MaxRangesPerRule = 100

$i = 1                     # Rule number counter, when more than one rule must be created, e.g., us-#1.
$start = 1                 # For array slicing out of IP $ranges.
$end = $maxrangesperrule   # For array slicing out of IP $ranges.
do {
    $icount = $i.tostring().padleft(3,"0")  # Used in name of rule, e.g., us-#1.
    
    if ($end -gt $linecount) { $end = $linecount } 
    $textranges = [System.String]::Join(",",$($ranges[$($start - 1)..$($end - 1)])) 

    "`nCreating an  inbound firewall rule named '$CountryCode-#$icount' for IP ranges $start - $end" 
    netsh.exe advfirewall firewall add rule name="$CountryCode-#$icount" dir=in action=block localip=any remoteip="$textranges" description="$description" profile="$profiletype" interfacetype="$interfacetype"
    if (-not $?) { "`nFailed to create '$rulename-#$icount' inbound rule for some reason, continuing anyway..."}
    
    "`nCreating an outbound firewall rule named '$CountryCode-#$icount' for IP ranges $start - $end" 
    netsh.exe advfirewall firewall add rule name="$CountryCode-#$icount" dir=out action=block localip=any remoteip="$textranges" description="$description" profile="$profiletype" interfacetype="$interfacetype"
    if (-not $?) { "`nFailed to create '$rulename-#$icount' outbound rule for some reason, continuing anyway..."}
    
    $i++
    $start += $maxrangesperrule
    $end += $maxrangesperrule
} while ($start -le $linecount)

Write-Host "Done!"
return
}

function Show-Menu
{
     Clear-Host
     Write-Host "Here's your option:"
    
     Write-Host “a: Block”
    
     Write-Host “b: Unblock”
}

Show-Menu
$Selection = Read-Host “Whacha gonna do boi?: ”

switch ($Selection)
{
	'a'{
		Block-Country
	}'b'{
		Undo-Block-Country
	}
}
return

