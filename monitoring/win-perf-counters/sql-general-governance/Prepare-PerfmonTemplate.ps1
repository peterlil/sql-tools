<#
.SYNOPSIS
    Prepare the Perfmon template for a specific server and instance.

.DESCRIPTION
    This script customizes a Performance Monitor XML template by replacing placeholders with the actual server name and instance name.

.PARAMETER ServerName
    The name of the server where SQL Server is running.

.PARAMETER InstanceName
	The name of the SQL Server instance to collect performance data for. Leave empty for the default instance.

.PARAMETER Template
	The path to the XML template file to use for the Perfmon configuration.

.OUTPUTS
	The path to the newly created Perfmon template file.

.EXAMPLE
    $FileName = .\Prepare-PerfmonTemplate.ps1 -ServerName "MyServer" -InstanceName "MyInstance" -Template ".\PerformanceMonitorTemplate_SQL2019.xml"
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

$strarr = Get-Content $Template

for ( $i = 0; $i -lt $strarr.Length; $i++ )
{ 
	$strarr[$i] = ($strarr[$i] -replace "#SERVER#", $ServerName); 
	if($InstanceName.Length -ne 0 -and $InstanceName.ToLower() -ne "default") 
	{ 
		if($strarr[$i].Contains("SQLServer:SSIS") -eq $false)
		{
			$strarr[$i] = ($strarr[$i] -replace "SQLServer:", ([string]::Format('MSSQL${0}:', $InstanceName))); 
		}
	}
	if($InstanceName.Length -ne 0)
	{
		$strarr[$i] = ($strarr[$i] -replace "#InstanceName", " $InstanceName").TrimEnd();
	}
	else {
		$strarr[$i] = ($strarr[$i] -replace "#InstanceName", "").TrimEnd();
	}
}
# add the instance name to the file name if it is supplied
if($InstanceName.Length -ne 0 -and $InstanceName.ToLower() -ne "default") 
{ 
	$FilePrefix = "${Servername}_${InstanceName}"
}
else {
	$FilePrefix = $Servername
}
$NewTemplateFileName = "$FilePrefix-PerfmonTemplate.xml"
Set-Content -Path $NewTemplateFileName -Value $strarr
Write-Host "Prepared Perfmon template: $NewTemplateFileName from $Template"

return $NewTemplateFileName
