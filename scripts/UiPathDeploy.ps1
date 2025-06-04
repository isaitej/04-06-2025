<#
.SYNOPSIS 
    Deploy NuGet package files to UiPath Orchestrator (Cloud or On-Prem)

.DESCRIPTION 
    This script uses UiPath CLI to deploy .nupkg packages to Orchestrator.

.PARAMETER packages_path 
     Required. Path to the package file or folder.

.PARAMETER orchestrator_url 
    Required. Orchestrator base URL.

.PARAMETER orchestrator_tenant 
    Required. Tenant name.

.PARAMETER orchestrator_user
    Orchestrator username (for basic auth).

.PARAMETER orchestrator_pass
    Orchestrator password (for basic auth).

.PARAMETER UserKey
    OAuth refresh token (for Cloud authentication).

.PARAMETER account_name
    Cloud account name (for Cloud authentication).

.PARAMETER folder_organization_unit
    Optional. The Orchestrator folder name.

.PARAMETER environment_list
    Optional. Comma-separated list of environments to deploy to.

.PARAMETER language
    Optional. Language of Orchestrator session.

.PARAMETER disableTelemetry
    Optional. Disable telemetry reporting.

#>

param (
    [Parameter(Mandatory = $true)]
    [string]$packages_path,

    [Parameter(Mandatory = $true)]
    [string]$orchestrator_url,

    [Parameter(Mandatory = $true)]
    [string]$orchestrator_tenant,

    [Parameter(Mandatory = $true)]
    [string]$UserKey,

    [Parameter(Mandatory = $true)]
    [string]$account_name
)

function Write-Log {
    param ([string]$Message)
    Write-Host "$(Get-Date -Format "G") `t $Message"
}

Write-Log "Starting UiPath deployment process..."
Write-Log "Validating parameters..."

if (-not (Test-Path $packages_path)) {
    Write-Log "ERROR: Package path '$packages_path' does not exist."
    exit 1
}

# Create CLI folder if not already present
$cliFolder = Join-Path $PSScriptRoot "uipathcli"
if (-not (Test-Path $cliFolder)) {
    Write-Log "UiPath CLI does not exist. Downloading..."
    $cliUrl = "https://uipathcli.blob.core.windows.net/public/uipathcli.zip"
    $zipPath = Join-Path $PSScriptRoot "uipathcli.zip"
    Invoke-WebRequest -Uri $cliUrl -OutFile $zipPath
    Expand-Archive -Path $zipPath -DestinationPath $cliFolder
    Remove-Item $zipPath
    Write-Log "UiPath CLI downloaded to: $cliFolder"
}

# Find CLI executable
$cliExe = Join-Path $cliFolder "lib/net461/uipcli.exe"
if (-not (Test-Path $cliExe)) {
    Write-Log "ERROR: UiPath CLI executable not found at $cliExe"
    exit 1
}

# Authenticate with Orchestrator
Write-Log "Authenticating with Orchestrator..."
& $cliExe config set --url "$orchestrator_url" --account-name "$account_name" --tenant "$orchestrator_tenant"
& $cliExe login --user-key "$UserKey"

if ($LASTEXITCODE -ne 0) {
    Write-Log "ERROR: Failed to authenticate with UiPath Orchestrator"
    exit 1
}

# Deploy all .nupkg files in package path
$nupkgFiles = Get-ChildItem -Path $packages_path -Filter *.nupkg
foreach ($pkg in $nupkgFiles) {
    Write-Log "Publishing package: $($pkg.Name)"
    & $cliExe packages deploy --file-path "$($pkg.FullName)"
    if ($LASTEXITCODE -ne 0) {
        Write-Log "ERROR: Failed to publish $($pkg.Name)"
        exit 1
    }
}

Write-Log "Deployment completed successfully!"
