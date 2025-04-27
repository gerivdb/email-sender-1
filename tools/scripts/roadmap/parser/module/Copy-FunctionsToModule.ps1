#
# Copy-FunctionsToModule.ps1
#
# Script to copy existing functions to the module structure
#

# Get the script path
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Get the functions path
$functionsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "functions"

# Get the module functions path
$moduleFunctionsPath = Join-Path -Path $scriptPath -ChildPath "Functions"
$modulePublicPath = Join-Path -Path $moduleFunctionsPath -ChildPath "Public"
$modulePrivatePath = Join-Path -Path $moduleFunctionsPath -ChildPath "Private"
$moduleExceptionsPath = Join-Path -Path $moduleFunctionsPath -ChildPath "Exceptions"

# Create the module functions directories if they don't exist
if (-not (Test-Path -Path $moduleFunctionsPath)) {
    New-Item -Path $moduleFunctionsPath -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -Path $modulePublicPath)) {
    New-Item -Path $modulePublicPath -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -Path $modulePrivatePath)) {
    New-Item -Path $modulePrivatePath -ItemType Directory -Force | Out-Null
}
if (-not (Test-Path -Path $moduleExceptionsPath)) {
    New-Item -Path $moduleExceptionsPath -ItemType Directory -Force | Out-Null
}

# Copy the exceptions
$exceptionsPath = Join-Path -Path $functionsPath -ChildPath "exceptions"
if (Test-Path -Path $exceptionsPath) {
    $exceptionFiles = Get-ChildItem -Path $exceptionsPath -Filter "*.ps1" -File
    foreach ($file in $exceptionFiles) {
        $destinationPath = Join-Path -Path $moduleExceptionsPath -ChildPath $file.Name
        Copy-Item -Path $file.FullName -Destination $destinationPath -Force
        Write-Host "Copied exception file: $($file.Name)" -ForegroundColor Green
    }
}

# Define public functions
$publicFunctions = @(
    "ConvertFrom-MarkdownToRoadmap.ps1",
    "ConvertFrom-MarkdownToRoadmapExtended.ps1",
    "ConvertFrom-MarkdownToRoadmapOptimized.ps1",
    "ConvertFrom-MarkdownToRoadmapWithDependencies.ps1",
    "Test-MarkdownFormat.ps1",
    "Edit-RoadmapTask.ps1",
    "Find-DependencyCycle.ps1",
    "Get-TaskDependencies.ps1",
    "Export-RoadmapToJson.ps1",
    "Import-RoadmapFromJson.ps1",
    "Select-RoadmapTask.ps1",
    "Test-RoadmapParameter.ps1",
    "Get-RoadmapParameterDefault.ps1",
    "Initialize-RoadmapParameters.ps1",
    "Test-RoadmapReturnType.ps1",
    "Write-RoadmapLog.ps1",
    "Invoke-RoadmapErrorHandler.ps1"
)

# Copy public functions
foreach ($function in $publicFunctions) {
    $sourcePath = Join-Path -Path $functionsPath -ChildPath $function
    if (Test-Path -Path $sourcePath) {
        $destinationPath = Join-Path -Path $modulePublicPath -ChildPath $function
        Copy-Item -Path $sourcePath -Destination $destinationPath -Force
        Write-Host "Copied public function: $function" -ForegroundColor Green
    } else {
        Write-Warning "Public function not found: $function"
    }
}

# Copy all other functions as private
$allFunctions = Get-ChildItem -Path $functionsPath -Filter "*.ps1" -File
foreach ($function in $allFunctions) {
    if ($publicFunctions -notcontains $function.Name) {
        $destinationPath = Join-Path -Path $modulePrivatePath -ChildPath $function.Name
        Copy-Item -Path $function.FullName -Destination $destinationPath -Force
        Write-Host "Copied private function: $($function.Name)" -ForegroundColor Green
    }
}

Write-Host "All functions copied to module structure" -ForegroundColor Green
