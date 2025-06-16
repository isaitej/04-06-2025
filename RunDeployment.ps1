Write-Output "===== Starting UiPath deployment ====="

# Define paths
$projectJsonPath = "$PSScriptRoot\project.json"
$outputPath = "$PSScriptRoot\output"
$uipcliExe = "$PSScriptRoot\tools\uipcli.exe"
$packageName = "UiPath.Github.Action"

# Step 1: Pack the project
Write-Output "Packing UiPath project..."
& $uipcliExe package pack "$projectJsonPath" -o "$outputPath" --autoVersion

# Step 2: Get the .nupkg file
$nupkg = Get-ChildItem -Path $outputPath -Filter "$packageName*.nupkg" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if (-not $nupkg) {
    Write-Error "No .nupkg file found after packing!"
    exit 1
}
Write-Output "Package created: $($nupkg.FullName)"

# Step 3: Deploy to Orchestrator
Write-Output "Deploying to Orchestrator..."
& $uipcliExe package deploy `
    "$($nupkg.FullName)" `
    "$env:ORCH_URL" `
    "$env:TENANT_LOGICAL_NAME" `
    -a "$env:ACCOUNT_LOGICAL_NAME" `
    -I "$env:APP_ID" `
    -S "$env:APP_SECRET" `
    --applicationScope "OR.Folders OR.Execution OR.Assets OR.Robots OR.Jobs" `
    -o "$env:FOLDER_NAME" `
    --traceLevel Information `
    --entryPointsPath "Main.xaml"

Write-Output "===== Deployment Completed ====="
