<#
.SYNOPSIS
    Prepare the scheduled task template by replacing server name and instance name accordingly and creating the final XML file with standardized name.

.DESCRIPTION
	This script customizes a Scheduled Task XML template by replacing placeholders with the actual instance name.
	It creates a new XML file with the instance name appended to the base filename.
    
.PARAMETER ServerName
    The name of the server where SQL Server is running.

.PARAMETER InstanceName
	The name of the SQL Server instance to collect performance data for. Leave empty for the default instance.

.PARAMETER Template
	The path to the XML template file to prepare.

.OUTPUTS
	The path to the newly created Scheduled Task template file.

.EXAMPLE
    $FileName = .\Prepare-ScheduledTaskTemplate.ps1 -ServerName "MyServer" -InstanceName "MyInstance" -Template ".\ScheduledTaskTemplate.xml"
#>

[CmdletBinding()]
param (
	[Parameter(Position = 0, Mandatory = $false, HelpMessage = "Specify the name of the server where SQL Server is running. Leave empty to use the local computer name.")]
	[string] $ServerName,
	[Parameter(Position = 1, Mandatory = $false, HelpMessage = "Specify the SQL Server instance name. Leave empty for default instance.")]
	[string] $InstanceName,
	[Parameter(Position = 2, Mandatory = $true, HelpMessage = "Specify the path to the XML template file. Paths relative to the script location are supported.")]
	[string] $Template
)

# Prepare the Perfmon template
if ([string]::IsNullOrEmpty($ServerName))
{
	$ServerName = $env:computername
}
if ([string]::IsNullOrEmpty($InstanceName))
{
	$InstanceName = ""
}

# Get the filename from the template path
$Filename = [System.IO.Path]::GetFileName($Template)

# Prepare the templates for the Scheduled Tasks
$strarr = Get-Content $Template

if($InstanceName.Length -ne 0)
{
	$ReplaceString = " $InstanceName";
}
else {
	$ReplaceString = "";
}

for ( $i = 0; $i -lt $strarr.Length; $i++ )
{ 
	$strarr[$i] = ($strarr[$i] -replace "#InstanceName", $ReplaceString).TrimEnd(); 
}

# add the instance name to the file name if it is supplied
if($InstanceName.Length -ne 0 -and $InstanceName.ToLower() -ne "default") 
{ 
	$FilePrefix = "${Servername}_${InstanceName}-"
}
else {
	$FilePrefix = "$Servername-"
}

Set-Content -Path "${FilePrefix}${Filename}" -Value $strarr
Write-Host "Prepared Scheduled Task template: ${FilePrefix}${Filename} from $Template"

return "${FilePrefix}${Filename}"

# Prepare-File -Filename "SQL Server Performance Analyzer Monitor - Scheduled Task.xml" -InstanceName $InstanceName
# Prepare-File -Filename "SQL Server Performance Analyzer Monitor Restart - Scheduled Task.xml" -InstanceName $InstanceName
# Prepare-File -Filename "Remove old logs - Scheduled Task.xml" -InstanceName $InstanceName
# Prepare-File -Filename "Zip Perfmon Logs - Scheduled Task.xml" -InstanceName $InstanceName
