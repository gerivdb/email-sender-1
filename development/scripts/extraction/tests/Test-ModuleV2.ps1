# Test-ModuleV2.ps1
# Simple test script for the ExtractedInfoModuleV2

Write-Output "Testing ExtractedInfoModuleV2..."

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

# Test creating a base extracted info
Write-Output "Creating base extracted info..."
try {
    $info = New-ExtractedInfo -Source "TestSource" -ExtractorName "TestExtractor"
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

# Test creating a text extracted info
Write-Output "Creating text extracted info..."
try {
    $textInfo = New-TextExtractedInfo -Source "TextSource" -ExtractorName "TextExtractor" -Text "This is a test text" -Language "en"
    Write-Output "Text info created successfully: $($textInfo.Id)"
    Write-Output "Text info character count: $($textInfo.CharacterCount)"
    Write-Output "Text info word count: $($textInfo.WordCount)"
} catch {
    Write-Output "Error creating text info: $_"
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
    $collection = Add-ExtractedInfoToCollection -Collection $collection -Info $textInfo
    if ($collection.Items.Count -eq 2) {
        Write-Output "Info added to collection successfully!"
    } else {
        Write-Output "Error: Collection item count ($($collection.Items.Count)) does not match expected count (2)"
        exit 1
    }
} catch {
    Write-Output "Error adding info to collection: $_"
    exit 1
}

# Test retrieving info from collection
Write-Output "Retrieving info from collection..."
try {
    Write-Output "Collection item count: $($collection.Items.Count)"
    Write-Output "First item ID: $($collection.Items[0].Id)"
    Write-Output "Looking for ID: $($info.Id)"

    $retrievedInfo = Get-ExtractedInfoFromCollection -Collection $collection -Id $info.Id
    Write-Output "Retrieved info count: $($retrievedInfo.Count)"

    if ($retrievedInfo.Count -gt 0) {
        Write-Output "Retrieved info ID: $($retrievedInfo[0].Id)"
    }

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

# Test validation
Write-Output "Testing validation..."
try {
    $validationResult = Test-ExtractedInfo -Info $info -UpdateObject
    if ($validationResult -and $info.IsValid) {
        Write-Output "Validation successful!"
    } else {
        Write-Output "Error: Validation failed"
        $errors = Get-ValidationErrors -Info $info
        foreach ($error in $errors) {
            Write-Output "Validation error: $error"
        }
        exit 1
    }
} catch {
    Write-Output "Error with validation: $_"
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
        $loadedInfo = Import-ExtractedInfoFromFile -FilePath $tempFile
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

Write-Output "All tests completed successfully!"
exit 0
