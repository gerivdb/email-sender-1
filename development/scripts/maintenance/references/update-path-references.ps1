# Script to update path references after reorganization
Write-Host "Updating path references after reorganization..." -ForegroundColor Green

# Define path mappings
$pathMappings = @(
    @{ Old = ".\scripts"; New = ".\development\scripts" },
    @{ Old = ".\tools"; New = ".\development\tools" },
    @{ Old = ".\tests"; New = ".\development\testing\tests" },
    @{ Old = ".\test-reports"; New = ".\development\testing\reports" },
    @{ Old = ".\assets"; New = ".\projet\assets" },
    @{ Old = "./scripts"; New = "./development/scripts" },
    @{ Old = "./tools"; New = "./development/tools" },
    @{ Old = "./tests"; New = "./development/testing/tests" },
    @{ Old = "./test-reports"; New = "./development/testing/reports" },
    @{ Old = "./assets"; New = "./projet/assets" },
    @{ Old = "scripts/"; New = "development/scripts/" },
    @{ Old = "tools/"; New = "development/tools/" },
    @{ Old = "tests/"; New = "development/testing/tests/" },
    @{ Old = "test-reports/"; New = "development/testing/reports/" },
    @{ Old = "assets/"; New = "projet/assets/" }
)

# Function to update references in a file
function Update-References {
    param (
        [string]$filePath,
        [array]$mappings
    )

    if (-not (Test-Path -Path $filePath)) {
        Write-Warning "File does not exist: $filePath"
        return
    }

    try {
        $content = Get-Content -Path $filePath -Raw -Encoding UTF8
        $originalContent = $content
        $modified = $false

        foreach ($mapping in $mappings) {
            if ($content -match [regex]::Escape($mapping.Old)) {
                $content = $content -replace [regex]::Escape($mapping.Old), $mapping.New
                $modified = $true
            }
        }

        if ($modified) {
            Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline
            Write-Host "Updated references in: $filePath" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Error updating references in $filePath : $_"
    }
}

# Find all relevant files in the project
$files = Get-ChildItem -Path . -Recurse -Include *.md, *.txt, *.ps1, *.py, *.js, *.html, *.css, *.json, *.yaml, *.yml, *.rst -File

# Update references in each file
$updatedCount = 0
foreach ($file in $files) {
    $oldContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    Update-References -filePath $file.FullName -mappings $pathMappings
    $newContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8
    
    if ($oldContent -ne $newContent) {
        $updatedCount++
    }
}

Write-Host "References updated in $updatedCount files." -ForegroundColor Green
