param ([string] $Servername, [string] $InstanceName = "", [string] $Template)

if ([string]::IsNullOrEmpty($Servername))
{
	$Servername = $env:computername
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
}
Set-Content -Path ($Servername + "-PerfmonTemplate.xml") -Value $strarr