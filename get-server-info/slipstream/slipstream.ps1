# RTMPath           - Path to RTM build
# SlipstreamPath    - Path to slipstream destination Ex: C:\sqladmin\media\slipstreams\SQLServer2008R2_x64_SP1_CU5
# SPPath            - Path to SP build. Ex: C:\sqladmin\media\SQLServer2008R2_x64_SP1\SQLServer2008SP1-KB968369-x64-ENU.exe
# CUPath            - Path to CU build. Ex: C:\sqladmin\media\SQLServer2008R2_x64_SP1_CU5\SQLServer2008R2-KB2659694-x64.exe
# DeleteDestination - True to delete destination if exists. False if destination folder remains RTM build. 
# EX 1: .\slipstream.ps1 "g:\sw\ms\srv\sql\SQL Server 2008 R2" "C:\Temp\2" "c:\Temp\1\SQLServer2008R2SP1-KB2528583-x64-ENU.exe" "c:\Temp\1\SQLServer2008R2-KB2659694-x64.exe" false
# EX 1: .\slipstream.ps1 "g:\sw\ms\srv\sql\SQL Server 2008 R2" "C:\Temp\2" "c:\Temp\1\SQLServer2008R2SP1-KB2528583-x64-ENU.exe" "c:\Temp\1\SQLServer2008R2-KB2659694-x64.exe" true
param (
    [string] $RTMPath = "",
    [string] $SlipstreamPath = "",
    [string] $SPPath = "",
    [string] $CUPath = "",
    [string] $DeleteDestination = "True"
)

cls



"Start slipstreaming process"

# ***************************************************************************
# *** Clear and create the destination folder
# ***************************************************************************
$SlipstreamFld = New-Object System.IO.DirectoryInfo($SlipstreamPath)
if($DeleteDestination.ToLower() -eq "true") {
    Try {
        if($SlipstreamFld.Exists) {
            "Deleting the destination folder."
            $SlipstreamFld.Delete($true)
            #if($?)
        }
        "Creating the destination folder."
        $SlipstreamFld.Create()
    }
    Catch [System.Exception] {
        "Unexpected error. Terminating."
        $Error
        exit
    }
}

# ***************************************************************************
# *** Copy RTM build to destination folder
# ***************************************************************************
"Copy RTM files"
$args = @()
$args += """$RTMPath"""
$args += """$SlipstreamPath"""
$args += "*.*"
$args += "/E"
$args += "/MT:4"
$args += "/NP"
$args += "/XO"
Start-Process "robocopy.exe" $args -Wait


# ***************************************************************************
# *** Extract service pack
# ***************************************************************************
if([string]::IsNullOrEmpty($SPPath) == $false)
{
	"Extracting Service pack"
	$SPFolder = New-Object System.IO.DirectoryInfo($SlipstreamPath + "\SP")
	if($SPFolder.Exist -eq $false) {
		$SPFolder.Create()
	}

	$args = @()
	$args += "/x:""" + $SPFolder.FullName + """"
	$args += "/Q"
	Start-Process $SPPath $args -Wait
}

# ***************************************************************************
# *** Copying service pack setup files
# ***************************************************************************
"Copying service pack setup files"
$args = @()
$args += """$SPPath"""
$args += """$SlipstreamPath"""
$args += "Setup.exe"
Start-Process "robocopy.exe" $args -Wait

if([string]::IsNullOrEmpty($SPPath) == $false)
{
	$args = @()
	$args += """$SPFolder"""
	$args += """$SlipstreamPath"""
	$args += "Setup.rll"
	Start-Process "robocopy.exe" $args -Wait
	
	$args = @()
	$args += """$SPFolder" + "\x64"""
	$args += """$SlipstreamPath" + "\x64"""
	$args += "/XF"
	$args += "Microsoft.SQL.Chainer.PackageData.dll"
	Start-Process "robocopy.exe" $args -Wait
}

# ***************************************************************************
# *** Extract cumulative update
# ***************************************************************************
"Extracting cumulative update"

$CUFolder = New-Object System.IO.DirectoryInfo($SlipstreamPath + "\CU")
if($CUFolder.Exist -eq $false) {
    $CUFolder.Create()
}

$args = @()
$args += "/x:""" + $CUFolder.FullName + """"
$args += "/Q"
Start-Process $CUPath $args -Wait

# ***************************************************************************
# *** Copying cumulative update setup files
# ***************************************************************************
"Copying cumulative update setup files"
$args = @()
$args += """$CUFolder"""
$args += """$SlipstreamPath"""
$args += "Setup.exe"
Start-Process "robocopy.exe" $args -Wait

$args = @()
$args += """$CUFolder"""
$args += """$SlipstreamPath"""
$args += "Setup.rll"
Start-Process "robocopy.exe" $args -Wait

$args = @()
$args += """$CUFolder" + "\x64"""
$args += """$SlipstreamPath" + "\x64"""
$args += "/XF"
$args += "Microsoft.SQL.Chainer.PackageData.dll"
Start-Process "robocopy.exe" $args -Wait


# ***************************************************************************
# *** Update DefaultSetup.ini
# ***************************************************************************
"Update DefaultSetup.ini"
$args = @()
$args += "PCUSOURCE=""" + $SPFolder + """"
$args += "CUSOURCE=""" + $CUFolder + """"

$DefaultSetupPath = $SlipstreamPath + "\x64\DefaultSetup.ini"

$args | Out-File -FilePath $DefaultSetupPath -Append

"Finished"
