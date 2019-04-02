SCHTASKS /CREATE /TN "SQL Server Performance Analyzer Monitor" /XML "SQL Server Performance Analyzer Monitor - Scheduled Task.xml" /F
SCHTASKS /CREATE /TN "SQL Server Performance Analyzer Monitor Restart" /XML "SQL Server Performance Analyzer Monitor Restart - Scheduled Task.xml" /F
SCHTASKS /CREATE /TN "Zip Perfmon Logs" /XML "Zip Perfmon Logs - Scheduled Task.xml" /F
SCHTASKS /CREATE /TN "Remove old logs" /XML "Remove old logs - Scheduled Task.xml" /F

logman start "SQL Server Performance Analyzer Monitor"


