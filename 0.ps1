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
