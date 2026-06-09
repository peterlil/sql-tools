param(
    [string] $ComputerName = $env:COMPUTERNAME,
    [switch] $PassThru
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Resolve-ToSid {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Identity
    )

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        return $null
    }

    $trimmed = $Identity.Trim()

    # secedit output often prefixes SIDs with '*'
    if ($trimmed.StartsWith("*")) {
        $trimmed = $trimmed.Substring(1)
    }

    try {
        if ($trimmed -match "^S-1-") {
            return [System.Security.Principal.SecurityIdentifier]::new($trimmed)
        }

        $account = [System.Security.Principal.NTAccount]::new($trimmed)
        return $account.Translate([System.Security.Principal.SecurityIdentifier])
    }
    catch {
        return $null
    }
}

function Get-SeManageVolumeAssignments {
    $tempFile = Join-Path -Path $env:TEMP -ChildPath ("secpol_{0}.inf" -f ([System.Guid]::NewGuid().ToString("N")))

    try {
        $null = & secedit /export /cfg $tempFile /areas USER_RIGHTS
        if ($LASTEXITCODE -ne 0) {
            throw "secedit export failed with exit code $LASTEXITCODE"
        }

        $line = Get-Content -Path $tempFile | Where-Object { $_ -match "^SeManageVolumePrivilege\s*=" } | Select-Object -First 1
        if (-not $line) {
            return @()
        }

        $rightValues = ($line -split "=", 2)[1].Trim()
        if ([string]::IsNullOrWhiteSpace($rightValues)) {
            return @()
        }

        return $rightValues.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }
    finally {
        if (Test-Path -LiteralPath $tempFile) {
            Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

try {
    $service = Get-CimInstance -ClassName Win32_Service -ComputerName $ComputerName -Filter "Name='MSSQLSERVER'" -ErrorAction Stop
}
catch {
    Write-Error "Failed to query Win32_Service on '$ComputerName'. $_"
    exit 1
}

if (-not $service) {
    Write-Host "Service MSSQLSERVER was not found on $ComputerName." -ForegroundColor Yellow
    exit 2
}

$serviceAccount = $service.StartName
$serviceAccountSid = Resolve-ToSid -Identity $serviceAccount

try {
    $assignedPrincipals = Get-SeManageVolumeAssignments
}
catch {
    Write-Error "Failed to read local user rights assignments. Run in an elevated PowerShell session. $_"
    exit 3
}

$assignedSids = foreach ($principal in $assignedPrincipals) {
    $sid = Resolve-ToSid -Identity $principal
    if ($sid) {
        $sid.Value
    }
}

$hasPrivilege = $false
if ($serviceAccountSid) {
    $hasPrivilege = $assignedSids -contains $serviceAccountSid.Value
}

$result = [pscustomobject]@{
    ComputerName                 = $ComputerName
    ServiceName                  = $service.Name
    DisplayName                  = $service.DisplayName
    ServiceAccount               = $serviceAccount
    ServiceAccountSid            = if ($serviceAccountSid) { $serviceAccountSid.Value } else { $null }
    SecurityPolicyRight          = "SeManageVolumePrivilege"
    SecurityPolicyRightFriendly  = "Perform volume maintenance tasks"
    AssignedPrincipals           = ($assignedPrincipals -join "; ")
    HasPerformVolumeMaintenance  = $hasPrivilege
}

if ($PassThru) {
    $result
}
else {
    $result | Format-List
}

if ($hasPrivilege) {
    Write-Host "OK: Service account '$serviceAccount' has 'Perform volume maintenance tasks'." -ForegroundColor Green
    exit 0
}

Write-Host "WARNING: Service account '$serviceAccount' does NOT have 'Perform volume maintenance tasks'." -ForegroundColor Yellow
exit 4