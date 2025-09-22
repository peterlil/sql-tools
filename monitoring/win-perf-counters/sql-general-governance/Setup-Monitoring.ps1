<#
.SYNOPSIS
    Setup the monitoring for one SQL Server instance. 

.DESCRIPTION
    This script sets up the monitoring environment for a specified SQL Server instance by creating a Performance Monitor trace and scheduling related tasks.
    It uses the server name and instance name to customize the monitoring setup.

.PARAMETER ServerName
    The name of the server where SQL Server is running.

.PARAMETER InstanceName
    The name of the SQL Server instance to append to each scheduled task.

.PARAMETER Template
    The path to the XML template file to use for the Performance Monitor trace.

.EXAMPLE
    .\Setup-Monitoring.ps1 -ServerName "MyServer" -InstanceName "MyInstance"
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false, HelpMessage = "Specify the name of the server where SQL Server is running. Leave empty to use the local computer name.")]
    [string] $ServerName,
    [Parameter(Position = 1, Mandatory = $false, HelpMessage = "Specify the SQL Server instance name. Leave empty for default instance.")]
    [string] $InstanceName,
    [Parameter(Position = 2, Mandatory = $false, HelpMessage = "Specify the path to the XML template file. Paths relative to the script location are supported.")]
    [string] $Template = ".\PerformanceMonitorTemplate_SQL2019.xml"
)

try {

    # Copy the script for compressing the files and removing old files to the right folder on the server
    .\copy-scripts.ps1

    # Prepare the Perfmon template
    $PerfmonTemplateFile = .\Prepare-PerfmonTemplate.ps1 -ServerName $ServerName -InstanceName $InstanceName -Template $Template

    # Prepare the scheduled tasks templates
    $StartTraceTaskFile = .\Prepare-ScheduledTaskTemplate.ps1 -ServerName $ServerName -InstanceName $InstanceName -Template ".\SQL Server Performance Analyzer Monitor - Scheduled Task.xml"
    $RestartTraceTaskFile = .\Prepare-ScheduledTaskTemplate.ps1 -ServerName $ServerName -InstanceName $InstanceName -Template ".\SQL Server Performance Analyzer Monitor Restart - Scheduled Task.xml"
    $RemoveOldLogsTaskFile = .\Prepare-ScheduledTaskTemplate.ps1 -ServerName $ServerName -InstanceName $InstanceName -Template ".\Remove old logs - Scheduled Task.xml"
    $ZipLogsTaskFile = .\Prepare-ScheduledTaskTemplate.ps1 -ServerName $ServerName -InstanceName $InstanceName -Template ".\Zip Perfmon Logs - Scheduled Task.xml"

    $TraceName = "SQL Server Trace $InstanceName".TrimEnd()

    # Create the Perfmon trace
    .\Create-PerfmonTrace.ps1 -Name $TraceName -Template $PerfmonTemplateFile

    # Create the scheduled tasks
    Write-Host "Creating scheduled task: $TraceName using $StartTraceTaskFile"
    SCHTASKS /CREATE /TN "$TraceName" /XML "$StartTraceTaskFile" /F
    Write-Host "Creating scheduled task: $TraceName Restart using $RestartTraceTaskFile"
    SCHTASKS /CREATE /TN "$TraceName Restart" /XML "$RestartTraceTaskFile" /F
    Write-Host "Creating scheduled task: Zip Perfmon Logs $InstanceName using $ZipLogsTaskFile"
    SCHTASKS /CREATE /TN "Zip Perfmon Logs $InstanceName".TrimEnd() /XML "$ZipLogsTaskFile" /F
    Write-Host "Creating scheduled task: Remove old logs $InstanceName using $RemoveOldLogsTaskFile"
    SCHTASKS /CREATE /TN "Remove old logs $InstanceName".TrimEnd() /XML "$RemoveOldLogsTaskFile" /F

    # Start the trace
    Write-Host "Starting the Perfmon trace: $TraceName"
    logman start $TraceName
}
catch {
    {<#Do this if a terminating exception happens#>}
}