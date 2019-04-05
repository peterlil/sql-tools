function Get-CPUs {
	param ($server, $username)
	if ($username)
	{
		$processors = get-wmiobject -computername $server -credential $username win32_processor
	}
	else
	{
		$processors = get-wmiobject -computername $server win32_processor
	}
	if (@($processors)[0].NumberOfCores)
	{
		$cores = @($processors).count * @($processors)[0].NumberOfCores
	}
	else
	{
		$cores = @($processors).count
	}
	$sockets = @(@($processors) | % {$_.SocketDesignation} | select-object -unique).count;
	
	"Cores: $cores, Sockets: $sockets";
 }
 
Function Get-SQLServerConfiguration {
	param([Microsoft.SqlServer.Management.Smo.Server] $s)
	
	$Recommended = $TRUE
	
	"{0,-30}{1,20}{2,20}" -f "Configuration", "ConfigValue", "RunValue"
	"{0,-30}{1,20}{2,20}" -f "-------------", "-----------", "--------"
	
	Foreach($cp in $s.Configuration.Properties){
		switch($cp.DisplayName) {
			"recovery interval (min)" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"allow updates" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"user connections" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"locks" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"open objects" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"fill factor (%)" { If(($cp.ConfigValue -eq 0) -or ($cp.ConfigValue -eq 100)) {$Recommended = $FALSE} }
			"disallow results from triggers" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"nested triggers" { If($cp.ConfigValue -ne 1) {$Recommended = $FALSE} }
			"server trigger recursion" { If($cp.ConfigValue -ne 1) {$Recommended = $FALSE} }
			"remote access" { If($cp.ConfigValue -ne 1) {$Recommended = $FALSE} }
			"default language" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"cross db ownership chaining" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"max worker threads" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"network packet size (B)" { If($cp.ConfigValue -le 4095) {$Recommended = $FALSE} }
			"show advanced options" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"remote proc trans" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"c2 audit mode" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"default full-text language" { If($cp.ConfigValue -ne 1033) {$Recommended = $FALSE} }
			"two digit year cutoff" { If($cp.ConfigValue -ne 2049) {$Recommended = $FALSE} }
			"index create memory (KB)" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"priority boost" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"remote login timeout (s)" { If($cp.ConfigValue -ne 20) {$Recommended = $FALSE} }
			"remote query timeout (s)" { If($cp.ConfigValue -ne 600) {$Recommended = $FALSE} }
			"cursor threshold" { If($cp.ConfigValue -ne -1) {$Recommended = $FALSE} }
			"set working set size" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"user options" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"affinity mask" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"max text repl size (B)" { If($cp.ConfigValue -ne 65536) {$Recommended = $FALSE} }
			"media retention" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"cost threshold for parallelism" { If($cp.ConfigValue -ne 5) {$Recommended = $FALSE} }
			"max degree of parallelism" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"min memory per query (KB)" { If($cp.ConfigValue -ne 1024) {$Recommended = $FALSE} }
			"query wait (s)" { If($cp.ConfigValue -ne -1) {$Recommended = $FALSE} }
			"min server memory (MB)" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"max server memory (MB)" { If($cp.ConfigValue -ne 2147483647) {$Recommended = $FALSE} }
			"query governor cost limit" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"lightweight pooling" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"scan for startup procs" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"awe enabled" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"affinity64 mask" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"affinity I/O mask" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"affinity64 I/O mask" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"transform noise words" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"precompute rank" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"PH timeout (s)" { If($cp.ConfigValue -ne 60) {$Recommended = $FALSE} }
			"clr enabled" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"max full-text crawl range" { If($cp.ConfigValue -ne 4) {$Recommended = $FALSE} }
			"ft notify bandwidth (min)" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"ft notify bandwidth (max)" { If($cp.ConfigValue -ne 100) {$Recommended = $FALSE} }
			"ft crawl bandwidth (min)" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"ft crawl bandwidth (max)" { If($cp.ConfigValue -ne 100) {$Recommended = $FALSE} }
			"default trace enabled" { If($cp.ConfigValue -ne 1) {$Recommended = $FALSE} }
			"blocked process threshold (s)" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"in-doubt xact resolution" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"remote admin connections" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"common criteria compliance enabled" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"EKM provider enabled" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"backup compression default" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"filestream access level" { If($cp.ConfigValue -ne 2) {$Recommended = $FALSE} }
			"optimize for ad hoc workloads" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"access check cache bucket count" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"access check cache quota" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"Agent XPs" { If($cp.ConfigValue -ne 1) {$Recommended = $FALSE} }
			"SQL Mail XPs" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"Database Mail XPs" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"SMO and DMO XPs" { If($cp.ConfigValue -ne 1) {$Recommended = $FALSE} }
			"Ole Automation Procedures" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"xp_cmdshell" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"Ad Hoc Distributed Queries" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
			"Replication XPs" { If($cp.ConfigValue -ne 0) {$Recommended = $FALSE} }
		default {"Unknown property {0}" -f $cp.DisplayName}
		}
		if ( $Recommended -eq $FALSE ) {
			$ui = (Get-Host).UI.RawUI 
			#$OriginalBgC = $ui.BackgroundColor
			$OriginalFgC = $ui.ForegroundColor
			#$ui.BackgroundColor = "green"
			$ui.ForegroundColor = "red"
		}
	
		"{0,-30}{1,20}{2,20}" -f $cp.DisplayName, $cp.ConfigValue, $cp.RunValue
		
		if ( $Recommended -eq $FALSE ) {
			$ui.ForegroundColor = $OriginalFgC
			$Recommended = $TRUE
		}
	}
}

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
"Affinity Cpu Count:	{0}" -f $Server.AffinityInfo.Cpu.Count
Foreach ($cpu in $server.AffinityInfo.Cpus)
{
	"   CPU ID {0}" -f $cpu.ID.ToString()
	"      CPU{0} Group ID      {1}" -f $cpu.ID.ToString(), $cpu.GroupID.ToString()
	"      CPU{0} AffinityMask  {1}" -f $cpu.ID.ToString(), $cpu.AffinityMask.ToString()
	"      CPU{0} Numa Node ID  {1}" -f $cpu.ID.ToString(), $cpu.NumaNodeID.ToString()
}
"Numa node count:       {0}" -f $Server.AffinityInfo.NumaNodes.Count
""
"Collation:  		{0}" -f $Server.Collation

""
#"Configuration"
#"--------------"
Get-SQLServerConfiguration $server
""
"Physical CPUs"
"============="
Get-CPUs "127.0.0.1"
""
"Physical RAM"
"============="
$mem = Get-WmiObject -Class Win32_ComputerSystem  
  
# Display memory  
"{0} MB" -f $($mem.TotalPhysicalMemory/1mb) 
""




# Display Database/Table info
"Databases and Table"
"-------------------"
foreach ($database in $server.Databases) {
"{0} (contains {1} tables)" -f $Database.name, $Database.Tables.Count
}



# Error logs

# Backup settings
