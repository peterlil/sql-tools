$destPath = Join-Path -Path (Get-ChildItem env:SystemDrive).Value -ChildPath "PerfLogs\zip-logs.ps1"
Copy-Item zip-logs.ps1 $destPath

$destPath = Join-Path -Path (Get-ChildItem env:SystemDrive).Value -ChildPath "PerfLogs\remove-old-logs.ps1"
Copy-Item remove-old-logs.ps1 C:\PerfLogs\remove-old-logs.ps1