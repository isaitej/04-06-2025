<#
.SYNOPSIS 
    Deploy NuGet package files to Orchestrator using External App OAuth

.DESCRIPTION 
    Deploys a .nupkg package to UiPath Orchestrator (Cloud) using External App credentials (client_id/secret).

.PARAMETER packages_path 
    Path to a package file or folder.

.PARAMETER orchestrator_url 
    URL of the Orchestrator instance.

.PARAMETER orchestrator_tenant 
    Tenant name of the Orchestrator instance.

.PARAMETER accountForApp 
    Orchestrator account name (e.g., uipatntvskhu).

.PARAMETER applicationId 
    External App client ID.

.PARAMETER applicationSecret 
    External App client secret.

.PARAMETER applicationScope 
    Scopes to request (e.g., OR.Jobs OR.Folders.Read).

.PARAMETER folder_organization_unit 
    Folder to deploy into.

.EXAMPLE
    .\UiPathDeploy.ps1 "C:\Package" "https://cloud.uipath.com/org/tenant/" "DefaultTenant" `
        -accountForApp "uipatntvskhu" `
        -applicationId "9765da03-dd43-4915-8847-8fe03d64bfa8" `
        -applicationSecret "W#fS4(J!tbTZeZ*v" `
        -applicationScope "OR.Jobs" `
        -folder_organization_unit "Shared"
#>

Param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string] $packages_path,

    [Parameter(Mandatory = $true, Position = 1)]
    [string] $orchestrator_url,

    [Parameter(Mandatory = $true, Position = 2)]
    [string] $orchestrator_tenant,

    [string] $accountForApp,
    [string] $applicationId,
    [string] $applicationSecret,
    [string] $applicationScope,

    [string] $folder_organization_unit = "",
    [string] $environment_list = "",
    [string] $entryPoints = "",
    [string] $language = "",
    [string] $disableTelemetry = "",
    [string] $uipathCliFilePath = "",
    [string] $SpecificCLIVersion = "23.10.8753.32995"
)

# Logging setup
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$debugLog = "$scriptPath\orchestrator-package-deploy.log"

function WriteLog {
    param ($message, [switch] $err)
    $now = Get-Date -Format "G"
    $line = "$now`t$message"
    $line | Add-Content $debugLog -Encoding UTF8
    if ($err) {
        Write-Host $line -ForegroundColor Red
    } else {
        Write-Host $line
    }
}

# Validate required External App params
if (-not ($accountForApp -and $applicationId -and $applicationSecret -and $applicationScope)) {
    WriteLog "❌ Missing required External App credentials (accountForApp, applicationId, applicationSecret, applicationScope)" -err
    exit 1
}

# Ensure CLI is available
if ($uipathCliFilePath -ne "") {
    $uipathCLI = $uipathCliFilePath
    if (-not (Test-Path $uipathCLI -PathType Leaf)) {
        WriteLog "❌ Invalid CLI path provided: $uipathCLI" -err
        exit 1
    }
} else {
    $cliPath = "$scriptPath\uipathcli\$SpecificCLIVersion"
    $uipathCLI = "$cliPath\tools\uipcli.exe"
    if (-not (Test-Path $uipathCLI -PathType Leaf)) {
        WriteLog "Downloading UiPath CLI $SpecificCLIVersion..."
        try {
            New-Item -ItemType Directory -Force -Path $cliPath | Out-Null
            $zipPath = "$cliPath\cli.zip"
            Invoke-WebRequest "https://uipath.pkgs.visualstudio.com/Public.Feeds/_apis/packaging/feeds/1c781268-d43d-45ab-9dfc-0151a1c740b7/nuget/packages/UiPath.CLI.Windows/versions/$SpecificCLIVersion/content" -OutFile $zipPath
            Expand-Archive -Path $zipPath -DestinationPath $cliPath -Force
            Remove-Item $zipPath
        } catch {
            WriteLog "❌ Failed to download or extract UiPath CLI: $_" -err
            exit 1
        }
    }
}

WriteLog "✅ UiPath CLI located: $uipathCLI"

# Build CLI arguments
$cliArgs = @(
    "package", "deploy", "`"$packages_path`"", $orchestrator_url, $orchestrator_tenant,
    "--accountForApp", $accountForApp,
    "--applicationId", $applicationId,
    "--applicationSecret", $applicationSecret,
    "--applicationScope", "`"$applicationScope`""
)

if ($folder_organization_unit) {
    $cliArgs += "--organizationUnit", "`"$folder_organization_unit`""
}
if ($environment_list) {
    $cliArgs += "--environments", "`"$environment_list`""
}
if ($entryPoints) {
    $cliArgs += "--entryPointsPath", "`"$entryPoints`""
}
if ($language) {
    $cliArgs += "--language", $language
}
if ($disableTelemetry) {
    $cliArgs += "--disableTelemetry", $disableTelemetry
}

# Log safe params
$maskedArgs = $cliArgs.Clone()
$maskedArgs[$maskedArgs.IndexOf("--applicationSecret") + 1] = "***************"
WriteLog "▶ Running: $uipathCLI $($maskedArgs -join ' ')"
WriteLog "-----------------------------------------------------"

# Execute CLI
& $uipathCLI @cliArgs

if ($LASTEXITCODE -eq 0) {
    WriteLog "✅ Package deployed successfully."
    exit 0
} else {
    WriteLog "❌ Deployment failed with exit code $LASTEXITCODE" -err
    exit 1
}
