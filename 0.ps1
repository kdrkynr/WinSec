$wsh = New-Object -ComObject Wscript.Shell


Write-Host "Host File" -ForegroundColor darkred -BackgroundColor white

$x = (Get-Item C:\Windows\System32\drivers\etc\hosts).LastWriteTime
$Compare = (Get-Date).AddHours(-12)
if ($Compare-le $x){
$wsh.Popup("Host File Change in $x")
}
