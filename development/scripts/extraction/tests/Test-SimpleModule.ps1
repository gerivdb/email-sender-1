# Simple test script for the SimpleExtractedInfoModule
# Using ASCII characters only to avoid encoding issues

Write-Output "Testing SimpleExtractedInfoModule..."

# Import the module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "SimpleExtractedInfoModule.psm1"
Write-Output "Module path: $modulePath"

try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Output "Module imported successfully!"
} catch {
    Write-Output "Error importing module: $_"
    exit 1
}

# Test creating a base extracted info
Write-Output "Creating base extracted info..."
try {
    $info = New-BaseExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
    Write-Output "Base info created successfully: $($info.Id)"
} catch {
    Write-Output "Error creating base info: $_"
    exit 1
}

# Test adding metadata
Write-Output "Adding metadata..."
try {
    $info = Add-ExtractedInfoMetadata -Info $info -Key "TestKey" -Value "TestValue"
    $value = Get-ExtractedInfoMetadata -Info $info -Key "TestKey"
    if ($value -eq "TestValue") {
        Write-Output "Metadata added and retrieved successfully!"
    } else {
        Write-Output "Error: Retrieved value ($value) does not match expected value (TestValue)"
        exit 1
    }
} catch {
    Write-Output "Error with metadata: $_"
    exit 1
}

# Test getting summary
Write-Output "Getting summary..."
try {
    $summary = Get-ExtractedInfoSummary -Info $info
    Write-Output "Summary: $summary"
} catch {
    Write-Output "Error getting summary: $_"
    exit 1
}

# Test creating a collection
Write-Output "Creating collection..."
try {
    $collection = New-ExtractedInfoCollection -Name "TestCollection"
    Write-Output "Collection created successfully: $($collection.Name)"
} catch {
    Write-Output "Error creating collection: $_"
    exit 1
}

# Test adding info to collection
Write-Output "Adding info to collection..."
try {
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $info
    if ($collection.Items.Count -eq 1) {
        Write-Output "Info added to collection successfully!"
    } else {
        Write-Output "Error: Collection item count ($($collection.Items.Count)) does not match expected count (1)"
        exit 1
    }
} catch {
    Write-Output "Error adding info to collection: $_"
    exit 1
}

# Test retrieving info from collection
Write-Output "Retrieving info from collection..."
try {
    $retrievedInfo = Get-ExtractedInfoFromCollection -Collection $collection -Id $info.Id
    if ($retrievedInfo.Count -eq 1 -and $retrievedInfo[0].Id -eq $info.Id) {
        Write-Output "Info retrieved from collection successfully!"
    } else {
        Write-Output "Error retrieving info from collection"
        exit 1
    }
} catch {
    Write-Output "Error retrieving info from collection: $_"
    exit 1
}

# Test serialization
Write-Output "Testing serialization..."
try {
    $json = ConvertTo-ExtractedInfoJson -InputObject $info
    Write-Output "JSON serialization successful!"
    
    $tempFile = Join-Path -Path $env:TEMP -ChildPath "test_info.json"
    $saveResult = Save-ExtractedInfoToFile -Info $info -FilePath $tempFile
    if ($saveResult) {
        Write-Output "Info saved to file successfully: $tempFile"
    } else {
        Write-Output "Error saving info to file"
        exit 1
    }
    
    if (Test-Path $tempFile) {
        $loadedInfo = Load-ExtractedInfoFromFile -FilePath $tempFile
        if ($loadedInfo -and $loadedInfo.Id -eq $info.Id) {
            Write-Output "Info loaded from file successfully!"
        } else {
            Write-Output "Error loading info from file"
            exit 1
        }
    } else {
        Write-Output "Error: File not created"
        exit 1
    }
} catch {
    Write-Output "Error with serialization: $_"
    exit 1
}

# Test validation
Write-Output "Testing validation..."
try {
    $validationResult = Test-ExtractedInfo -Info $info
    if ($validationResult -and $info.IsValid) {
        Write-Output "Validation successful!"
    } else {
        Write-Output "Error: Validation failed"
        exit 1
    }
} catch {
    Write-Output "Error with validation: $_"
    exit 1
}

Write-Output "All tests completed successfully!"
exit 0
