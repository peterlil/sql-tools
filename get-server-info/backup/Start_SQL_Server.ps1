#This script should work for WS2003, WS2008, WS2008R2 and SQL2005, SQL2008, SQL2008R2

# Common machine config
# =====================
# * Server information
Get-WmiObject Win32_ComputerSystem

Get-WmiObject Win32_OperatingSystem | format-list Caption, BuildNumber, BuildType, CodeSet, CountryCode, 
	CurrentTimeZone, Description, ForegroundApplicationBoost, FreePhysicalMemory, FreeSpaceInPagingFile, 
	FreeVirtualMemory, Name, OperatingSystemSKU, Organization, OSArchitecture, OSLanguage, OSType, 
	RegisteredUser, SerialNumber, ServicePackMajorVersion, ServicePackMinorVersion,
	@{Name=”Installation Date”; Expression={$_.ConvertToDateTime($_.InstallDate)}}, 
	@{Name=”Last Bootup time”; Expression={$_.ConvertToDateTime($_.LastBootUpTime)}}, 
	@{Name=”Local Date Time”; Expression={$_.ConvertToDateTime($_.LocalDateTime)}}


Get-WmiObject HWINV_OperatingSystemEx | format-list Name, BuildLabEx, CSDBuildNumber, CSDReleaseType, CSDVersion
# * CPU information
Get-WmiObject Win32_Processor | format-list Caption, AddressWidth, L2CacheSize, MaxClockSpeed, NumberOfCores, NumberOfLogicalProcessors
# * Amount of memory
# * Hyperthreading on/off
# * OS Version
# * OS Edition
# * OS Build
# * OS Architecture
# * OS Service Pack level
# * OS Patch Level


# Start SQL Server if it's not started.
$SqlEngineService = Get-Service MSSQLSERVER
if( $SqlEngineService.Status -eq "Stopped" )
{
	"The service is stopped. Tryng to start the service."
	start-service MSSQLSERVER
	$SqlEngineService = Get-Service MSSQLSERVER
	if( $SqlEngineService.Status -eq "Stopped" )
	{
		throw "SQL Server Engine failed to start."
	}
}
else
{
	"The service is running"
}

# Running processes
# =================
# * List of running processes

# Memory Pressure

# Storage subsystem

# Load SQL Server PowerShell cmdlets.

#
