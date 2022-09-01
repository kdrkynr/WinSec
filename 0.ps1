$wsh = New-Object -ComObject Wscript.Shell

$time = (Get-Date).AddMinutes(-75)

$LFResults = get-winevent -FilterHashtable @{Logname="Security";ID=4625;StartTime=$time}
$LSResults = get-winevent -FilterHashtable @{Logname="Security";ID=4624;StartTime=$time}


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
$TLFR = $LFResults.Count
$a = 1
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
$wsh.Popup("$a\$TLFR LOGON FAILURE >> User: $D\$U, Type: $T, IP: $IP($H), $EventTime")
$a = $a + 1
}



Write-Host "Logon Success" -ForegroundColor darkred -BackgroundColor white
$TLSR = $LSResults.Count
$a = 1
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
$wsh.Popup("$a\$TLSR LOGON SUCCESS >> User: $D\$U, Type: $T, IP: $IP($H), $EventTime")
$a = $a + 1
}
}


Write-Host "Task Schedule" -ForegroundColor darkred -BackgroundColor white
$ST = Get-ScheduledTask
foreach ($a in $ST){
$Date = $a.Date
$compare = $Time
if ($Compare-le $Date){
$Name = $a.TaskName
$Path = $a.TaskPath
$Author = $a.Author
$Date = $a.Date
$wsh.Popup("New Schedule Task >>> Author: $Author Task Name: $Name Path: $Path Date: $Date ")
}
}


Write-Host "SMB SHARE" -ForegroundColor darkred -BackgroundColor white
$Sharelist = Get-SmbShare 
$DefaultShare = "ADMIN$", "C$", "D$", "IPC$"
foreach($a in $Sharelist){
$b = $a.Name
$x = $DefaultShare -contains $b
if ($x -ne "False"){
$Desc = $a.Description
$Path = $a.Path
echo $Path
$wsh.Popup("NEW or UNDEFAULT SMB Share $b for $Path ($Desc)")
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
