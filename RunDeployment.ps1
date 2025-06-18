# Final UiPath Deployment Script - Using Jenkins Credential IDs Exactly
# Filename: RunDeployment.ps1

param (
    [string]$OrchestratorUrl     = $env.'orch-url',
    [string]$AccountLogicalName  = $env.'account-logical-name',
    [string]$TenantLogicalName   = $env.'tenant-logical-name',
    [string]$FolderName          = $env.'folder-name',
    [string]$AppId               = $env.'app-id',
    [string]$AppSecret           = $env.'app-secret',
    [string]$PackagePath         = "./project.json"
)

Write-Host "Authenticating with UiPath Orchestrator..."

# Step 1: Get access token
$body = @{
    grant_type    = "client_credentials"
    client_id     = $AppId
    client_secret = $AppSecret
    scope         = "OR.Jobs OR.Folders OR.Machines OR.Robots OR.Execution OR.Assets"
}

$tokenResponse = Invoke-RestMethod -Uri "$OrchestratorUrl/identity_/connect/token" `
                                   -Method Post `
                                   -Body $body `
                                   -ContentType "application/x-www-form-urlencoded"

$token = $tokenResponse.access_token

if (-not $token) {
    Write-Error "Authentication failed. Please check credentials."
    exit 1
}

Write-Host "Token retrieved successfully."

# Step 2: Prepare headers
$headers = @{
    Authorization                 = "Bearer $token"
    "X-UIPATH-TenantName"         = $TenantLogicalName
    "X-UIPATH-OrganizationUnitId" = $FolderName
}

# Step 3: Pack project into .nupkg
Write-Host "Packing project..."

& "C:\Program Files\UiPath\Studio\UiRobot.exe" pack $PackagePath -o "$(pwd)\Output"

# Step 4: Extract project name and version
$projectData = Get-Content $PackagePath | ConvertFrom-Json
$packageName = $projectData.name
$version     = $projectData.projectVersion

$packageFilePath = "$(pwd)\Output\$packageName.$version.nupkg"

if (-not (Test-Path $packageFilePath)) {
    Write-Error "Package not found: $packageFilePath"
    exit 1
}

# Step 5: Upload the package
Write-Host "Uploading package..."

$uploadUri = "$OrchestratorUrl/odata/Processes/UiPath.Server.Configuration.OData.UploadPackage"

$form = @{
    file       = Get-Item $packageFilePath
    folderPath = "/"
}

$response = Invoke-RestMethod -Uri $uploadUri `
                              -Headers $headers `
                              -Method Post `
                              -Form $form

if ($response -ne $null) {
    Write-Host "Package uploaded successfully."
} else {
    Write-Error "Package upload failed."
    exit 1
}
