# Test-Collection.ps1
# Simple test script for the collection functions

Write-Output "Testing collection functions..."

# Import the module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "ExtractedInfoModuleV2.psm1"
Write-Output "Module path: $modulePath"

try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Output "Module imported successfully!"
} catch {
    Write-Output "Error importing module: $_"
    exit 1
}

# Create a collection
$collection = New-ExtractedInfoCollection -Name "TestCollection"
Write-Output "Collection created: $($collection.Name)"

# Create an info object
$info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
Write-Output "Info created: $($info.Id)"

# Add the info to the collection
$collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
Write-Output "Info added to collection"
Write-Output "Collection item count: $($collection.Items.Count)"
Write-Output "Collection first item ID: $($collection.Items[0].Id)"

# Get the info from the collection
Write-Output "Getting info from collection by ID: $($info.Id)"
$retrievedInfo = Get-ExtractedInfoFromCollection -Collection $collection -Id $info.Id
Write-Output "Retrieved info count: $($retrievedInfo.Count)"

if ($retrievedInfo.Count -gt 0) {
    Write-Output "Retrieved info ID: $($retrievedInfo[0].Id)"
} else {
    Write-Output "No info retrieved"
}

# Get all info from the collection
Write-Output "Getting all info from collection"
$allInfo = Get-ExtractedInfoFromCollection -Collection $collection
Write-Output "All info count: $($allInfo.Count)"

if ($allInfo.Count -gt 0) {
    Write-Output "All info first item ID: $($allInfo[0].Id)"
} else {
    Write-Output "No info retrieved"
}

exit 0
