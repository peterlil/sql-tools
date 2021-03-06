param(
	[string] $serverName = "",
	[string] $sqlServerName = ".",
    [string] $dbName = "tempdb",
	[boolean] $skipEventLogDumps = $false,
	[boolean] $skipDatabaseQueries = $false
)

[string] $currentDateTime = ""

cls

#This script should work for WS2003, WS2008, WS2008R2 and SQL2005, SQL2008, SQL2008R2, SQL2012


# *****************************************************************************
# *** Get-ScriptDirectory
# *** Returns the directory of the script.
# *****************************************************************************
function Get-ScriptDirectory
{
    $Invocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $Invocation.MyCommand.Path
}


# *****************************************************************************
# *** Check and prepare variables
# *****************************************************************************

if ($serverName.Length -eq 0) {
    $tmp = Get-WmiObject Win32_ComputerSystem
    $serverName = $tmp.Name + "." + $tmp.Domain
}
$scriptStartDateTime = [System.DateTime]::Now.ToString("yyyyMMdd-HHmm")

$baseOutputFilename = Get-ScriptDirectory
$baseOutputFilename += "\" + $serverName + "_" + $scriptStartDateTime
$outputFilename = $baseOutputFilename + "_server-info.txt"


Write-Host "Get Server Info Version 3" -ForegroundColor Green; 
"Get Server Info Version 3" | Out-File -FilePath $outputFilename
"=========================" | Out-File -FilePath $outputFilename
"" | Out-File -FilePath $outputFilename

$OneQuarterBack = (Get-Date).AddMonths(-3)


# *****************************************************************************
# *****************************************************************************
# *** Windows Server information and configuration
# *****************************************************************************
# *****************************************************************************

Write-Host "Quering object Win32_ComputerSystem." -ForegroundColor Green;
"Computer System Information" | Out-File -FilePath $outputFilename -Append
$wmi = Get-WmiObject Win32_ComputerSystem -ComputerName $serverName;
$wmi | format-table Domain, Manufacturer, Model, `
	Name, PrimaryOwnerName, TotalPhysicalMemory, `
	@{Label="Total Physical Memory (GB)"; Expression={$_.TotalPhysicalMemory/(1024*1024*1024)}} `
	-AutoSize | Out-String -Width 4096 | Out-File -FilePath $outputFilename -Append
$totalPhysicalMemory = $wmi.TotalPhysicalMemory;
	
Write-Host "Quering object Win32_OperatingSystem." -ForegroundColor Green;
$computerSystem = Get-WmiObject Win32_OperatingSystem -ComputerName $serverName 
$computerSystem | format-table Caption, BuildNumber, BuildType, CodeSet, CountryCode, 
	CurrentTimeZone, Description, ForegroundApplicationBoost, FreePhysicalMemory, FreeSpaceInPagingFile, 
	FreeVirtualMemory, Name, OperatingSystemSKU, Organization, OSArchitecture, OSLanguage, OSType, 
	RegisteredUser, SerialNumber, ServicePackMajorVersion, ServicePackMinorVersion,
	@{Name=�Installation Date�; Expression={$_.ConvertToDateTime($_.InstallDate)}}, 
	@{Name=�Last Bootup time�; Expression={$_.ConvertToDateTime($_.LastBootUpTime)}}, 
	@{Name=�Local Date Time�; Expression={$_.ConvertToDateTime($_.LocalDateTime)}} -AutoSize | Out-String -Width 4096 | Out-File -FilePath $outputFilename -Append

if($computerSystem.ForeGroundApplicationBoost -ne 0)
{
	"Warning: Processor scheduling is not optimized for background tasks."  | Out-File -FilePath $outputFilename -Append
	""  | Out-File -FilePath $outputFilename -Append
}

Write-Host "Quering object Win32_WindowsProductActivation." -ForegroundColor Green;
"Windows Product Activation Information" | Out-File -FilePath $outputFilename -Append
Get-WmiObject Win32_WindowsProductActivation -ComputerName $serverName -erroraction silentlycontinue `
	| format-list *
	
if($? -eq $false)
{
    "Class Win32_WindowsProductActivation is not available on this system." | Out-File -FilePath $outputFilename -Append
    "" | Out-File -FilePath $outputFilename -Append
}

# BIOS is not giving the review interesting info. Needs more investigation
#"Win32_BIOS Information" | Out-File -FilePath $outputFilename -Append
#Get-WmiObject Win32_BIOS -ComputerName $serverName | format-list PSComputerName,Status,Name,Caption,SMBIOSPresent,
#    BiosCharacteristics,BIOSVersion,BuildNumber,CodeSet,CurrentLanguage,Description,
#    IdentificationCode,InstallableLanguages,InstallDate,LanguageEdition,ListOfLanguages,
#    Manufacturer,OtherTargetOS,PrimaryBIOS,ReleaseDate,SerialNumber,SMBIOSBIOSVersion,
#    SMBIOSMajorVersion,SMBIOSMinorVersion,SoftwareElementID, SoftwareElementState,
#    TargetOperatingSystem,Version | Out-File -FilePath $outputFilename -Append

# Win32_SystemBIOS did not have any complementary information
# Get-WmiObject Win32_SystemBIOS | format-list * | Out-File -FilePath $outputFilename -Append

# Boot configuration
Write-Host "Quering object Win32_BootConfiguration." -ForegroundColor Green;
Get-WmiObject Win32_BootConfiguration -ComputerName $serverName | format-table Name, BootDirectory | Out-File -FilePath $outputFilename -Append

$dtype = DATA {
ConvertFrom-StringData -StringData @� 
0 = Unknown 
1 = No Root Directory 
2 = Removable Disk 
3 = Local Disk 
4 = Network Drive 
5 = Compact Disk 
6 = RAM Disk 
�@
}
 
$media = DATA {
ConvertFrom-StringData -StringData @� 
11 = Removable media other than floppy 
12 = Fixed hard disk media 
�@
}

$admPwdStatus = DATA {
ConvertFrom-StringData -StringData @� 
1 = Disabled
2 = Enabled
3 = Not Implemented
4 = Unknown
�@
}

$domainRole = DATA {
ConvertFrom-StringData -StringData @� 
0 = Standalone Workstation
1 = Member Workstation
2 = Standalone Server
3 = Member Server
4 = Backup Domain Controller
5 = Primary Domain Controller
�@
}

Write-Host "Quering object Win32_ComputerSystem." -ForegroundColor Green;
# Win32_ComputerSystem
Get-WmiObject Win32_ComputerSystem -ComputerName $serverName `
	| format-table `
		@{Name="AdminPasswordStatus"; Expression={$admPwdStatus["$($_.AdminPasswordStatus)"]}}, `
		BootupState, DaylightInEffect, Domain, `
		@{Name="DomainRole"; Expression={$domainRole["$($_.DomainRole)"]}}, `
		EnableDaylightSavingsTime, HypervisorPresent, NetworkServerModeEnabled, `
		NumberOfLogicalProcessors, NumberOfProcessors, PartOfDomain, Roles, `
		SystemType, UserName -AutoSize `
	| Out-String -Width 4096 `
	| Out-File -FilePath $outputFilename -Append

# Win32_ComputerSystemProduct
Write-Host "Quering object Win32_ComputerSystemProduct." -ForegroundColor Green;
Get-WmiObject Win32_ComputerSystemProduct -ComputerName $serverName | format-list PSComputerName, Caption,
    IdentifyingNumber, SKUNumber, UUID | format-table * -AutoSize | Out-String -Width 4096 | Out-File -FilePath $outputFilename -Append


# Win32_SystemSlot
Write-Host "Quering object Win32_SystemSlot." -ForegroundColor Green;
Get-WmiObject Win32_SystemSlot -ComputerName $serverName | format-table Status, SlotDesignation,
    Caption, ConnectorPinout, ConnectorType, CurrentUsage, Description, InstallDate, 
    Manufacturer, MaxDataWidth, Model, Name, Number, OtherIdentifyingInfo,
    PartNumber, PMESignal, PoweredOn, PurposeDescription, SerialNumber, Shared, 
    SKU, SpecialPurpose, SupportsHotPlug, Tag, ThermalRating, Version, -AutoSize `
	| Out-String -Width 4096 | Out-File -FilePath $outputFilename -Append

# Server features
Write-Host "Quering for server features" -ForegroundColor Green;
get-wmiobject Win32_ServerFeature | format-table Name, ID, ParentID -AutoSize | Out-String -Width 4096 | Out-File -FilePath $outputFilename -Append

# Defrag analysis
Write-Host "Quering object Win32_DefragAnalysis." -ForegroundColor Green;
Get-WmiObject Win32_DefragAnalysis -ComputerName $serverName | format-table PSComputerName, Status, Name,
    Caption, Description, InstallDate, UserName, VariableValue, Scope, Path,
    Options, ClassPath, Properties, SystemProperties, Qualifiers, Site,
    ContainerSystemVariable -AutoSize | Out-String -Width 4096 | Out-File -FilePath $outputFilename -Append

# Environment
Write-Host "Quering object Win32_Environment." -ForegroundColor Green;
Get-WmiObject Win32_Environment -ComputerName $serverName `
	| format-table Status, Name, SystemVariable, Caption, Description, InstallDate, `
		UserName, VariableValue -AutoSize `
	| Out-String -Width 4096 `
	| Out-File -FilePath $outputFilename -Append

# Win32_TimeZone
Write-Host "Quering object Win32_TimeZone." -ForegroundColor Green;
Get-WmiObject Win32_TimeZone -ComputerName $serverName `
	| format-table Caption, DaylightName, StandardName -AutoSize `
	| Out-String -Width 4096 `
	| Out-File -FilePath $outputFilename -Append

# Persisted routes
Write-Host "Quering object Win32_IP4PersistedRouteTable." -ForegroundColor Green;
"Persisted routes" | Out-File -FilePath $outputFilename -Append
Get-WmiObject Win32_IP4PersistedRouteTable -ComputerName $serverName `
	| format-table Caption, Description, Destination, Mask, Metric1, Name, `
		NextHop, Status, InstallDate -AutoSize `
	| Out-String -Width 4096 `
	| Out-File -FilePath $outputFilename -Append

# All routes
Write-Host "Quering object Win32_IP4RouteTable." -ForegroundColor Green;
"All routes" | Out-File -FilePath $outputFilename -Append
Get-WmiObject Win32_IP4RouteTable -ComputerName $serverName `
	| format-table Caption, Age, Description, Destination, Information, `
		InterfaceIndex, Mask, Metric1, Metric2, Metric3, Metric4, Metric5, `
		Name, NextHop, Protocol, Status, Type, InstallDate -AutoSize `
	| Out-String -Width 4096 `
	| Out-File -FilePath $outputFilename -Append

# Logical memory configuration
#Get-WmiObject Win32_LogicalMemoryConfiguration | format-list *

# Page file
Write-Host "Quering object Win32_PageFile." -ForegroundColor Green;
"Page file" | Out-File -FilePath $outputFilename -Append
Get-WmiObject Win32_PageFile -ComputerName $serverName `
	| format-table AccessWork, Archive, Caption, Compressed, CompressionMethod, `
		CreationDate, Drive, Encrypted, EncryptionMethod, FileSize, `
		MaximumSize, Status -AutoSize `
	| Out-String -Width 4096 `
	| Out-File -FilePath $outputFilename -Append
Write-Host "Quering object Win32_PageFileSetting." -ForegroundColor Green;
Get-WmiObject Win32_PageFileSetting -ComputerName $serverName `
	| format-table Caption, Description, InitialSize, MaximumSize -AutoSize `
	| Out-String -Width 4096 `
	| Out-File -FilePath $outputFilename -Append
Write-Host "Quering object Win32_PageFileUsage." -ForegroundColor Green;
Get-WmiObject Win32_PageFileUsage -ComputerName $serverName `
	| format-table Name, CurrentUsage, AllocationBaseSize, PeakUsage, TempPageFile, Caption -AutoSize `
	| Out-String -Width 4096 `
	| Out-File -FilePath $outputFilename -Append

Write-Host "Quering for installed software." -ForegroundColor Green;
$Software = Get-WmiObject -class Win32_Product -ComputerName $serverName;

Write-Host "Filtering out Microsoft software." -ForegroundColor Green;
$MS_Software = $Software | Where { $_.Vendor -eq 'Microsoft Corporation'} `
	| Sort-Object  Name `
	| ft __Server, Name, Version -AutoSize `
	| Out-String

Write-Host "Filtering out 3rd party software." -ForegroundColor Green;
$NonMS_Software = $Software | Where { $_.Vendor -ne 'Microsoft Corporation'} `
	| Sort-Object  Name  `
	| ft __Server, Name, Version -AutoSize `
	| Out-String

$MS_SoftwareCount = ($MS_Software| ForEach-Object {$_}).count | Out-String
$NonMS_SoftwareCount = ($NonMS_Software | Where { $_.Vendor -ne 'Microsoft Corporation'}| ForEach-Object {$_}).count | Out-String

"Microsoft software inventory" | Out-File -FilePath $outputFilename -Append
$MS_Software 		| Out-File -FilePath $outputFilename -Append
$MS_SoftwareCount	| Out-File -FilePath $outputFilename -Append
"3rd party software inventory" | Out-File -FilePath $outputFilename -Append
$NonMS_Software		 | Out-File -FilePath $outputFilename -Append
$NonMS_SoftwareCount | Out-File -FilePath $outputFilename -Append

# patch
Write-Host "Quering for hotfixes." -ForegroundColor Green;
Get-HotFix -ComputerName $serverName `
	| Select-Object -Property @{Name="Server"; Expression={$_.psBase.Properties["CSName"].Value}}, `
		HotFixID, @{Name="InstalledOn"; Expression={$_.psBase.Properties["InstalledOn"].Value}} , Description `
	| Where {($_.HotFixID -NE 'File 1')} `
	| Sort-Object -Property HotFixID  | Out-File -FilePath $outputFilename -Append

# drivers
Write-Host "Quering for drivers." -ForegroundColor Green;
"Driver inventory" | Out-File -FilePath $outputFilename -Append
Get-WmiObject win32_pnpSignedDriver -Authentication 6 -ComputerName $serverName `
	| where {$_.DriverVersion -ne $null} `
	| Sort-Object DeviceName `
	| ft -auto __Server, DeviceName, driverversion `
	| Out-File -FilePath $outputFilename -Append


# * CPU information
Write-Host "Quering object Win32_Processor." -ForegroundColor Green;
$wmi = Get-WmiObject Win32_Processor -ComputerName $serverName;
if($wmi.NumberOfLogicalProcessors -eq ($wmi.NumberOfCores*2))
{
	Write-Host "HyperThreading is enabled." -BackgroundColor Gray -ForegroundColor White;
	"HyperThreading is enabled" | Out-File -FilePath $outputFilename -Append;
}
else
{
	Write-Host "HyperThreading is not enabled." -BackgroundColor Gray -ForegroundColor White;
	"HyperThreading is not enabled" | Out-File -FilePath $outputFilename -Append;
}
Write-Host "Ratio of Memory (GB)/core: " -NoNewline -BackgroundColor Gray -ForegroundColor White;
Write-Host (($totalPhysicalMemory / (1024 * 1024 * 1024)) /  $wmi.NumberOfLogicalPRocessors) -BackgroundColor Gray -ForegroundColor White;
("Ratio of Memory (GB)/core: " + (($totalPhysicalMemory / (1024 * 1024 * 1024)) /  $wmi.NumberOfLogicalPRocessors).ToString()) | Out-File -FilePath $outputFilename -Append;
$wmi | format-table Caption, AddressWidth, L2CacheSize, MaxClockSpeed, `
		NumberOfCores, NumberOfLogicalProcessors -AutoSize `
	| Out-String -Width 4096 `
	| Out-File -FilePath $outputFilename -Append;
	
# * Amount of memory
# * Hyperthreading on/off
# * OS Version
# * OS Edition
# * OS Build
# * OS Architecture
# * OS Service Pack level
# * OS Patch Level

# Storage subsystem
# get-wmiobject -list | where {$_.name -match "Disk"}
# get-wmiobject Win32_DiskDrive | get-member


Write-Host "Quering volumes and mount points." -ForegroundColor Green;

$volumeSummary = @()

"Volumes and volume mount points" | Out-File -FilePath $outputFilename -Append
Get-WmiObject -Class Win32_MountPoint -ComputerName $serverName | foreach `
{
	$vol = $_.Volume

    $vol2 = Get-WmiObject -Class Win32_Volume -ComputerName $serverName | where {$_.__RELPATH -eq $vol -and $_.DriveType -eq 3}

	if($vol2 -ne $null) 
	{
		$volRecord = new-Object -typename System.Object
		$volRecord | add-Member -memberType noteProperty -name Folder -Value $vol2.Caption
		$volRecord | add-Member -memberType noteProperty -name "Drive Letter" -Value $vol2.DriveLetter
		$volRecord | add-Member -memberType noteProperty -name "Drive Type" -Value $dtype["$($vol2.DriveType)"]
		$volRecord | add-Member -memberType noteProperty -name Label -Value $vol2.Label
		$volRecord | add-Member -memberType noteProperty -name "File System" -Value $vol2.FileSystem
		$volRecord | add-Member -memberType noteProperty -name "Block Size" -Value $vol2.BlockSize
		$volRecord | add-Member -memberType noteProperty -name "Size (GB)" -Value ([System.Math]::Round(($vol2.Capacity / 1GB), 2))
		$volRecord | add-Member -memberType noteProperty -name "Free (GB)" -Value ([System.Math]::Round(($vol2.FreeSpace / 1GB), 2))
		$volRecord | add-Member -memberType noteProperty -name "% Free" -Value ([System.Math]::Round((($vol2.FreeSpace/$vol2.Capacity)*100), 0))
		$volRecord | add-Member -memberType noteProperty -name "Boot Volume" -Value $vol2.BootVolume
		$volRecord | add-Member -memberType noteProperty -name "Indexing Enabled" -Value $vol2.IndexingEnabled
		$volRecord | add-Member -memberType noteProperty -name "Page File Present" -Value $vol2.PageFilePresent
		
		$volumeSummary += $volRecord
	}
}
$volumeSummary | Sort-Object -Property Folder | format-table Folder, "Drive Letter", "Drive Type", `
	Label, "File System", "Block Size", "Size (GB)", `
	"Free (GB)", `
	"% Free", "Boot Volume", "Indexing Enabled", "Page File Present" -AutoSize `
	| Out-String -Width 4096 `
	| Sort-Object -Property Folder, DriveType `
	| Out-File -FilePath $outputFilename -Append

# Prepare the table and record structure
$diskSummary = @()

Write-Host "Quering object Win32_DiskDrive." -ForegroundColor Green;
"foreach Win32_DiskDrive" | Out-File -FilePath $outputFilename -Append
Get-WmiObject -Class Win32_DiskDrive -ComputerName $serverName | Sort-Object -Property Name | foreach {

    $diskDrive = $_
 
    $query = "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='" + $_.DeviceID + "'} WHERE ResultClass=Win32_DiskPartition"
     
    Get-WmiObject -Query $query -ComputerName $serverName | foreach {
		
        $diskPartition = $_
		
		$query2 = "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='" + $_.DeviceID + "'} WHERE ResultClass=Win32_LogicalDisk"
		
        $logicalDisk = Get-WmiObject -Query $query2 -ComputerName $serverName
                
        $diskRecord = new-Object -typename System.Object
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_Name -Value $diskDrive.Name
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_Caption -Value $diskDrive.Caption
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_Description -Value $diskDrive.Description
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_DeviceID -Value $diskDrive.DeviceID
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_Index -Value $diskDrive.Index
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_InterfaceType -Value $diskDrive.InterfaceType
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_Manufacturer -Value $diskDrive.Manufacturer
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_Partitions -Value $diskDrive.Partitions
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_SCSIBus -Value $diskDrive.SCSIBus
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_SCSILogicalUnit -Value $diskDrive.SCSILogicalUnit
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_SCSITargetId -Value $diskDrive.SCSITargetId
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_Size -Value $diskDrive.Size
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_SizeGB -Value ($diskDrive.Size/1GB)
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_Status -Value $diskDrive.Status
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskDrive_StatusInfo -Value $diskDrive.StatusInfo
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskPartition_Name -Value $diskPartition.Name
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskPartition_Caption -Value $diskPartition.Caption
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskPartition_Description -Value $diskPartition.Description
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskPartition_DeviceID -Value $diskPartition.DeviceID
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskPartition_DiskIndex -Value $diskPartition.DiskIndex
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskPartition_Index -Value $diskPartition.Index
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskPartition_PrimaryPartition -Value $diskPartition.PrimaryPartition
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskPartition_Size -Value $diskPartition.Size
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskPartition_SizeGB -Value ($diskPartition.Size/1GB)
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskPartition_StartingOffset -Value $diskPartition.StartingOffset
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskPartition_Status -Value $diskPartition.Status
        $diskRecord | add-Member -memberType noteProperty -name Win32_DiskPartition_StatusInfo -Value $diskPartition.StatusInfo
        $diskRecord | add-Member -memberType noteProperty -name Win32_LogicalDisk_DeviceID -Value $logicalDisk.DeviceID
        $diskRecord | add-Member -memberType noteProperty -name Win32_LogicalDisk_FileSystem -Value $logicalDisk.FileSystem
        $diskRecord | add-Member -memberType noteProperty -name Win32_LogicalDisk_Size -Value $logicalDisk.Size
        $diskRecord | add-Member -memberType noteProperty -name Win32_LogicalDisk_SizeGB -Value ($logicalDisk.Size/1GB)
        $diskRecord | add-Member -memberType noteProperty -name Win32_LogicalDisk_DiskSizeGB -Value ($logicalDisk.Size/1GB)
        $diskRecord | add-Member -memberType noteProperty -name Win32_LogicalDisk_VolumeName -Value $logicalDisk.VolumeName
        $diskRecord | add-Member -memberType noteProperty -name Win32_LogicalDisk_DriveType -Value $dtype["$($logicalDisk.DriveType)"]
        $diskRecord | add-Member -memberType noteProperty -name Win32_LogicalDisk_MediaType -Value $media["$($logicalDisk.MediaType)"]
        $diskRecord | add-Member -memberType noteProperty -name Win32_LogicalDisk_FreeSpaceGB -Value ($logicalDisk.FreeSpace/1GB)

        $diskSummary += $diskRecord

    }
} 

$diskSummary | format-table * -AutoSize | Out-String -Width 4096 | Sort-Object -Property Win32_DiskDrive_Name | Out-File -FilePath $outputFilename -Append
	
# Network
Write-Host "Quering object Win32_NetworkAdapter." -ForegroundColor Green;
get-wmiobject Win32_NetworkAdapter -ComputerName $serverName `
	| Sort-Object -Property PhysicalAdapter, Name `    | format-table Name, PhysicalAdapter, Caption, Speed, `
	    MACAddress, Manufacturer, MaxSpeed, NetworkAddresses, PermanentAddress, `
	    ProductName,  Description, ServiceName -AutoSize `
    | Out-String -Width 4096 | Out-File -FilePath $outputFilename -Append

# Network adapter config
Write-Host "Quering object Win32_NetworkAdapterConfiguration." -ForegroundColor Green;
get-wmiobject Win32_NetworkAdapterConfiguration -ComputerName $serverName `
	| format-table Description, Index, InterfaceIndex, IPAddress, `
		DefaultIPGateway, IPSubnet, MACAddress, IPEnabled, `
		IPConnectionMetric, DHCPEnabled, ServiceName, DHCPServer, `
		DNSDomain, DNSHostName, DomainDNSRegistrationEnabled, `
		FullDNSRegistrationEnabled, DNSSuffixSearchOrder, DHCPLeaseExpires `
		-AutoSize `
	| Out-String -Width 4096 `
	| Out-File -FilePath $outputFilename -Append

# Protocol binding
Write-Host "Quering object Win32_ProtocolBinding." -ForegroundColor Green;
get-wmiobject Win32_ProtocolBinding -ComputerName $serverName `
	| format-table Antecedent, Dependent, Device -AutoSize | Out-String -Width 4096 | Out-File -FilePath $outputFilename -Append

Write-Host "Quering the config of TCP Chimney Offload" -ForegroundColor Green;
netsh int tcp show global > ($serverName + "_" + $scriptStartDateTime + "_tcp_chimney_os_settings.txt")
	
# Proxy settings
#get-wmiobject Win32_Proxy | format-table * -AutoSize | Out-String -Width 4096




Write-Host "Dumping Event Logs." -ForegroundColor Green;
if ($skipEventLogDumps -eq $false) {
	# *****************************************************************************
	# *** Event Log dumps
	# *** Get only the logs for the last quarter
	# *****************************************************************************
	Get-EventLog -ComputerName $serverName -LogName application -EntryType Error -Newest 200 -after $OneQuarterBack | format-list -property * > ($serverName + "_" + $scriptStartDateTime + "_event-log-application-error.txt")
	Get-EventLog -ComputerName $serverName -LogName application -EntryType Warning -Newest 200 -after $OneQuarterBack | format-list -property * > ($serverName + "_" + $scriptStartDateTime + "_event-log-application-warnings.txt")
	Get-EventLog -ComputerName $serverName -LogName system -EntryType Error -Newest 200 -after $OneQuarterBack | format-list -property * > ($serverName + "_" + $scriptStartDateTime + "_event-log-system-error.txt")
	Get-EventLog -ComputerName $serverName -LogName system -EntryType Warning -Newest 200 -after $OneQuarterBack | format-list -property * > ($serverName + "_" + $scriptStartDateTime + "_event-log-system-warnings.txt")
}

# TODO: List firewall exceptions
Write-Host "TODO: Query firewall exceptions." -ForegroundColor Yellow;

# Check if SQL Server is started or not
$SqlEngineService = Get-Service MSSQLSERVER -ComputerName $serverName -erroraction silentlycontinue
if($SqlEngineService -ne $null)
{
	if( $SqlEngineService.Status -eq "Stopped" )
	{
		"The MSSQLSERVER service is stopped." | Out-File -FilePath $outputFilename -Append
	}
	else
	{
		"The MSSQLSERVER service is running" | Out-File -FilePath $outputFilename -Append
	}
}
else
{
	"There is no MSSQLSERVER service in the server" | Out-File -FilePath $outputFilename -Append
}
# Running processes
# =================
# * List of running processes

# Memory Pressure

# <<<<<----------------------------------------------------------->>>>>
# <<<<< Perform some extra checks if cluster feature is installed >>>>>
# <<<<<----------------------------------------------------------->>>>>
Write-Host "Checking if the cluster feature is installed." -ForegroundColor Green;
Import-Module FailoverClusters -ErrorAction "SilentlyContinue";
$foc = Get-Module FailoverClusters;
if($foc -ne $null)
{
   	Write-Host "Quering the cluster nodes." -ForegroundColor Green;
	Get-ClusterNode | Sort-Object -Property Name | ft Name, State, NodeWeight | Out-File -FilePath $outputFilename -Append;
}

if($sqlServerName.Length -eq 0) {
    exit;
}
if($dbName.Length -eq 0) {
    exit
}

# *****************************************************************************
# *****************************************************************************
# *** SQL Server Checks
# *****************************************************************************
# *****************************************************************************

$sqlServerVersion = 'unknown';

Write-Host "Quering for version path" -ForegroundColor Green;
$version = invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query "SELECT @@VERSION AS Version"
if ( $version.version.Contains( "Microsoft SQL Server 2008" ) ) {
    $sqlServerVersion='100'
} elseif ( $version.version.Contains( "Microsoft SQL Server 2012" ) ) {
    $sqlServerVersion='110'
} elseif ( $version.version.Contains( "Microsoft SQL Server 2014" ) ) {
    $sqlServerVersion='120'
} elseif ( $version.version.Contains( "Microsoft SQL Server 2016" ) ) {
    $sqlServerVersion='130'
} elseif ( $version.version.Contains( "Microsoft SQL Server 2017" ) ) {
    $sqlServerVersion='140'
} elseif ( $version.version.Contains( "Microsoft SQL Server 2019" ) ) {
    $sqlServerVersion='150'
}


if($skipDatabaseQueries -eq $false) {
	$snapIns = Get-PSSnapin -Name *SQL* -ErrorAction "SilentlyContinue"
	if($snapIns.Length -lt 2) {
		#
		# Add the SQL Server Provider.
		#

		$ErrorActionPreference = "Stop"

		# SQL Server 2012
		$sqlpsreg="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps110"
		if (Get-ChildItem $sqlpsreg -ErrorAction "SilentlyContinue")
		{
			# "SQL Server 2012 Provider for Windows PowerShell is not installed."
			# Check SQL Server 2008 & 2008R2
			$sqlpsreg="HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.SqlServer.Management.PowerShell.sqlps"
			if (Get-ChildItem $sqlpsreg -ErrorAction "SilentlyContinue")
			{
				throw "SQL Server Provider for Windows PowerShell is not installed."
			}
			else
			{
				$item = Get-ItemProperty $sqlpsreg
				$sqlpsPath = [System.IO.Path]::GetDirectoryName($item.Path)
				#
				# Set mandatory variables for the SQL Server provider
				#
				Set-Variable -scope Global -name SqlServerMaximumChildItems -Value 0
				Set-Variable -scope Global -name SqlServerConnectionTimeout -Value 30
				Set-Variable -scope Global -name SqlServerIncludeSystemObjects -Value $false
				Set-Variable -scope Global -name SqlServerMaximumTabCompletion -Value 1000

				#
				# Load the snapins, type data, format data
				#
				Push-Location
				cd $sqlpsPath
				Add-PSSnapin SqlServerCmdletSnapin100
				Add-PSSnapin SqlServerProviderSnapin100
				Update-TypeData -PrependPath SQLProvider.Types.ps1xml 
				update-FormatData -prependpath SQLProvider.Format.ps1xml 
				Pop-Location
			}
		}
		else
		{
			import-module sqlps -DisableNameChecking
			C:
		}

	}

# *****************************************************************************
# * Collect the configuration.ini files
# * Look into 'C:\Program Files\Microsoft SQL Server\<version>\Setup Bootstrap\Log'
# * for folders named 00000000_000000.
# *****************************************************************************
	$sqlServerSetupLogPath = "C:\Program Files\Microsoft SQL Server\" + $sqlServerVersion `
		+ "\Setup Bootstrap\Log";
	$folderSearchTerm = $sqlServerSetupLogPath + "\????????_??????";
	
	$folderlist = Get-ChildItem $folderSearchTerm
    foreach ($folder in $folderlist) `
	{
        if((Test-Path ($folder.PSPath + '\ConfigurationFile.ini')) -eq $true)
        {
			$tmpFilename = $baseOutputFilename + "_ConfigurationFile_" + $folder.Name + ".ini";
            Write-Host ("Copy: '" + ($folder.PSPath + '\ConfigurationFile.ini') + "' -> '" + ('C:\temp\ConfigurationFile_' + $folder.Name + '.ini') + "'...") -NoNewline -ForegroundColor Green;
            Copy-Item ($folder.PSPath + '\ConfigurationFile.ini') $tmpFilename;
            Write-Host "OK" -ForegroundColor Green;
        }
	}

	Write-Host "Quering for SQL Server services states and users" -ForegroundColor Green;
	get-wmiobject Win32_Service `
		-Filter "DisplayName like '%SQL%'" `
		| Sort-Object DisplayName `
		| ft DisplayName, State, StartName, StartMode  | Out-File -FilePath $outputFilename -Append;

	Write-Host "Quering for authentication schemes used" -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_auth-scheme.txt"
	"List authentication schemes that are used. " | Out-File -FilePath $tmpFilename -Append
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query "SELECT session_id, client_net_address, auth_scheme FROM sys.dm_exec_connections" `		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Quering for the instance collection." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_instance-collation.txt"
	"Get the instance collation. " | Out-File -FilePath $tmpFilename -Append
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query "SELECT SERVERPROPERTY('Collation') AS [COLLATION]" `
		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Quering for authentication configuration." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_integrated-security-only.txt"
	"Authentication configuration. " | Out-File -FilePath $tmpFilename -Append
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query "SELECT SERVERPROPERTY('IsIntegratedSecurityOnly') AS [IsIntegratedSecurityOnly]" `
		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append
	
	
	Write-Host "Quering for node names." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_instance-names.txt"
	"Node name(s). " | Out-File -FilePath $tmpFilename -Append
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query "SELECT SERVERPROPERTY('ComputerNamePhysicalNetBIOS') AS [ComputerNamePhysicalNetBIOS], SERVERPROPERTY('InstanceName') AS [InstanceName], SERVERPROPERTY('MachineName') AS [MachineName]" `
		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

#	$tmpFilename = $baseOutputFilename + "_index-fragmentation.txt"
#	"Index fragmentation. " | Out-File -FilePath $tmpFilename -Append
#	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query "SELECT * FROM sys.dm_db_index_physical_stats(null, null, null, null, 'LIMITED');" `
#		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append
	
	Write-Host "Quering for recovery model." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_recovery-model.txt"
	"Recovery model. " | Out-File -FilePath $tmpFilename -Append
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query "SELECT name AS [Database Name], recovery_model_desc AS [Recovery Model] FROM sys.databases ORDER BY recovery_model_desc, name;" `
		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Quering for standby databases" -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_standby-databases.txt"
	"List of databases in standby" | Out-File -FilePath $tmpFilename -Append
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query "SELECT name AS [Database Name],	is_in_standby AS [IsInStandby] FROM sys.databases WHERE is_in_standby = 1 ORDER BY name;" `
		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append
	
	
	$scriptDir = Get-ScriptDirectory

	Write-Host "Sending query database-file-report.sql." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_database-file-report.txt"
	if( $sqlServerVersion -eq "110") `
	{
		$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "Database-file-report_110.sql"));
	}
	else `
	{
		$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "Database-file-report.sql"));
	}
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query $tmpQuery `		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Sending query transaction-log-fragment-report-alternative.sql." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_vlf-report.txt"
	
    if( $sqlServerVersion -eq "100") {
		$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "Transaction-log-fragment-report-altenative.sql"));
    } else {
		$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "Transaction-log-fragment-report-altenative_110.sql"));
	}
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query $tmpQuery `		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Sending query traceflags.sql." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_traceflags.txt"
	$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "check running traceflags.sql"));
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query $tmpQuery `		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Sending query database-sizes.sql." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_database-sizes.txt"
	$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "database sizes.sql"));
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query $tmpQuery `		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Sending query db-info.sql." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_db-info.txt"
	$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "db-info.sql"));
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query $tmpQuery `		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Sending query sa-owned-jobs.sql." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_sa-owned-jobs.txt"
	$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "sa-owned-jobs.sql"));
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query $tmpQuery `		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Sending query version-check.sql." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_version-check.txt"
	$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "version-check.sql"));
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query $tmpQuery `		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append
	 
	Write-Host "Sending query sys-configuration.sql." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_sys-configuration.txt"
	$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "sys-configuration.sql"));
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query $tmpQuery `		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Sending query dbfile-placementdataorlog-files-in-folders.sql." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_dbfile-placementdataorlog-folderbased.txt"
	$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "dbfile-placementdataorlog-files-in-folders.sql"));
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query $tmpQuery `		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Sending query dbfile-placementsdataorlog-files-in-drives.sql." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_dbfile-placementdataorlog-driveletterbased.txt"
	$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "dbfile-placementdataorlog-files-in-drives.sql"));
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query $tmpQuery `		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Sending query autogrowth.sql." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_autogrowth.txt"
	$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "autogrowth.sql"));
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query $tmpQuery `		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append

	Write-Host "Sending query dbcc-checkdb.sql." -ForegroundColor Green;
	$tmpFilename = $baseOutputFilename + "_dbcc-checkdb.txt"
	$tmpQuery = [System.IO.File]::ReadAllText((join-Path $scriptDir "dbcc-checkdb.sql"));
	invoke-sqlcmd -ServerInstance $sqlServerName -Database $dbName �Query $tmpQuery `
		| Format-Table -AutoSize | Out-String -Width 4096 | Out-File -FilePath $tmpFilename -Append
}
