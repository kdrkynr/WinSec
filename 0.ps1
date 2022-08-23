$wsh = New-Object -ComObject Wscript.Shell

$LFResults = get-winevent -FilterHashtable @{Logname="Security";ID=4625} | where Timecreated -GE (Get-Date).AddMinutes(-75)
$LSResults = get-winevent -FilterHashtable @{Logname="Security";ID=4624} | where Timecreated -GE (Get-Date).AddMinutes(-75) 


Write-Host "Host File" -ForegroundColor darkred -BackgroundColor white

$x = (Get-Item C:\Windows\System32\drivers\etc\hosts).LastWriteTime
$Compare = (Get-Date).AddHours(-12)
if ($Compare-le $x){
$wsh.Popup("Host File Change in $x")
}



Write-Host "Local Users" -ForegroundColor darkred -BackgroundColor white
$Users = Get-LocalUser
$Default = "kadir"
foreach ($a in $Users){
$x = $a.Enabled
if ($x -eq "True"){
$Name = $a.Name
$Result = $Default -contains $Name
if ($Result -ne "False"){
$wsh.Popup("New User --> $Name")
}
}
}



Write-Host "Logon Failures" -ForegroundColor darkred -BackgroundColor white
foreach ($r in $LFResults){
$EventTime = $r.TimeCreated
[xml]$evt = $r.ToXml()
$evt.Event.EventData.Data | foreach-object -Begin {$h = @{}} -Process {
$h.add($_.name,$_.'#text')
} -end { $obj = New-Object -TypeName PSObject -Property $h }
$U = $obj.TargetUserName
$D = $obj.TargetDomainName
$T = $obj.LogonType
$IP = $obj.IpAddress
$H = $obj.WorkstationName
$wsh.Popup("LOGON FAILURE >> User: $D\$U, Type: $T, IP: $IP($H), $EventTime")
}



Write-Host "Logon Success" -ForegroundColor darkred -BackgroundColor white
foreach ($r in $LSResults){
$EventTime = $r.TimeCreated
[xml]$evt = $r.ToXml()
$evt.Event.EventData.Data | foreach-object -Begin {$h = @{}} -Process {
$h.add($_.name,$_.'#text')
} -end { $obj = New-Object -TypeName PSObject -Property $h }
# $SID = $obj.SubjectUserSid
$DefaultProfiles = "SYSTEM"
$U = $obj.TargetUserName
$x = $DefaultProfiles -contains $U
if ($x -ne "False"){
$D = $obj.TargetDomainName
$T = $obj.LogonType
$IP = $obj.IpAddress
$H = $obj.WorkstationName
$wsh.Popup("LOGON SUCCESS >> User: $D\$U, Type: $T, IP: $IP($H), $EventTime")
}
}


Write-Host "TCP Connections" -ForegroundColor darkred -BackgroundColor white
$IPs = Get-NetIPAddress
$PrivateIPs = @()
foreach ($a in $IPs){
$b = $a.IPAddress
$PrivateIPs += $b
}
$Est = Get-NetTCPConnection -State Established
foreach ($A in $Est){
$RP = $a.RemotePort
$Web = "80", "443"
$x = $Web -contains $RP
if ($x -ne "True"){
$RIP = $a.RemoteAddress
$y = $PrivateIPs -contains $RIP
if ($y -ne "True"){
$ID = $a.OwningProcess
$CT = $a.CreationTime
$PN = (Get-Process -Id $ID).ProcessName
$wsh.Popup("$PN has TCP a connection to $RIP : $RP since $CT")
}
}
}


Write-Host "TCP Listenings" -ForegroundColor darkred -BackgroundColor white
$Lis = Get-NetTCPConnection -State Listen | sort LocalPort
foreach ($A in $Lis){
$WhiteProcessList = "lsass", "wininit", "svchost", "spoolsv", "system", "services", "vmware-authd", "vmware-hostd"
$LP = $a.LocalPort
$ID = $a.OwningProcess
$PN = (Get-Process -Id $ID).ProcessName
$x = $WhiteProcessList -contains $PN
if ($x -ne "True"){
$wsh.Popup("TCP $LP is listening for $PN process and PID is $ID")
}
}
