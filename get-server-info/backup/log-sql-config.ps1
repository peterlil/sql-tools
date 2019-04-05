# Load the SMO Assembly
$null = [system.Reflection.Assembly]::LoadWithPartialName("Microsoft.SQLServer.Smo")
$server = New-Object Microsoft.SqlServer.Management.Smo.Server $args[0]
# Display key properties 
"Server Details"
"--------------"
$Server.Information.Properties | Select-Object Name, Value | Format-Table -auto
"Server Name:      		{0}" -f $server.netname
"Product:          		{0}" -f $Server.Product
"Edition:          		{0}" -f $Server.Edition
"Type:             		{0}" -f $Server.ServerType
"Version:          		{0}" -f $Server.Version
"Version String:   		{0}" -f $Server.Versionstring
"Service Account:  		{0}" -f $Server.ServiceAccount
""
"Affinity Type:    		{0}" -f $Server.AffinityInfo.AffinityType
"Affinity Cpu Count:	{0}" + $Server.AffinityInfo.Cpu.Count
Foreach ($cpu in $server.AffinityInfo.Cpus)
{
	Write-Host "   " -f $cpu.ID
}
""
# Display Database/Table info
"Databases and Table"
"-------------------"
foreach ($database in $server.Databases) {
"{0} (contains {1} tables)" -f $Database.name, $Database.Tables.Count
}