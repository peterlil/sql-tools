param(
	[string] $LogDirectory = "",
	[switch] $IncludeNoDriveLetter,
	[switch] $PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ScriptDirectory {
	$invocation = (Get-Variable MyInvocation -Scope 1).Value
	Split-Path -Path $invocation.MyCommand.Path
}

if ([string]::IsNullOrWhiteSpace($LogDirectory)) {
	$LogDirectory = Get-ScriptDirectory
}

if (-not (Test-Path -LiteralPath $LogDirectory)) {
	New-Item -Path $LogDirectory -ItemType Directory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$computerName = $env:COMPUTERNAME

$csvLogPath = Join-Path -Path $LogDirectory -ChildPath "drive-allocation-unit-log.csv"
$textLogPath = Join-Path -Path $LogDirectory -ChildPath "drive-allocation-unit-log.txt"

# Win32_Volume.BlockSize is the file system allocation unit (cluster size) in bytes.
$volumes = Get-CimInstance -ClassName Win32_Volume |
	Where-Object {
		($IncludeNoDriveLetter -or -not [string]::IsNullOrWhiteSpace($_.DriveLetter)) -and
		-not [string]::IsNullOrWhiteSpace($_.FileSystem)
	} |
	Sort-Object -Property DriveLetter

$rows = foreach ($volume in $volumes) {
	$clusterSizeBytes = [int64]$volume.BlockSize

	[pscustomobject]@{
		Timestamp        = $timestamp
		ComputerName     = $computerName
		DriveLetter      = $volume.DriveLetter
		Label            = $volume.Label
		FileSystem       = $volume.FileSystem
		CapacityGB       = if ($volume.Capacity) { [math]::Round(($volume.Capacity / 1GB), 2) } else { $null }
		FreeSpaceGB      = if ($volume.FreeSpace) { [math]::Round(($volume.FreeSpace / 1GB), 2) } else { $null }
		ClusterSizeBytes = $clusterSizeBytes
		ClusterSizeKB    = if ($clusterSizeBytes -gt 0) { [math]::Round(($clusterSizeBytes / 1KB), 2) } else { $null }
	}
}

if ($rows.Count -gt 0) {
	if (-not (Test-Path -LiteralPath $csvLogPath)) {
		$rows | Export-Csv -Path $csvLogPath -NoTypeInformation
	}
	else {
		$rows | Export-Csv -Path $csvLogPath -NoTypeInformation -Append
	}

	Add-Content -Path $textLogPath -Value "[$timestamp] Logged $($rows.Count) volumes on $computerName."
}
else {
	Add-Content -Path $textLogPath -Value "[$timestamp] No eligible volumes found on $computerName."
}

Write-Host "Cluster size logging completed." -ForegroundColor Green
Write-Host "CSV log:  $csvLogPath"
Write-Host "Text log: $textLogPath"

if ($PassThru) {
	$rows
}
