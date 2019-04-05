Clear-Host

schtasks.exe /?

schtasks.exe /Query /?

schtasks.exe /Query /FO TABLE

schtasks.exe /Query /TN "SQL Server Performance Analyzer Monitor" /FO LIST
schtasks.exe /Query /TN "SQL Server Performance Analyzer Monitor Restart" /FO LIST
schtasks.exe /Query /TN "Zip Perfmon Logs" /FO LIST
schtasks.exe /Query /TN "Remove old logs" /FO LIST

schtasks.exe /Query /TN "SQL Server Performance Analyzer Monitor" /XML ONE
schtasks.exe /Query /TN "SQL Server Performance Analyzer Monitor Restart" /XML ONE
schtasks.exe /Query /TN "Zip Perfmon Logs" /XML ONE
schtasks.exe /Query /TN "Remove old logs" /XML ONE
