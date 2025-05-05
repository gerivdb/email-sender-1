# Script to update references in files after migration
# This script searches and replaces paths from the old structure to the new one

# Path mappings definition
$pathMappings = @(
    @{ Old = "docs/architecture"; New = "projet/architecture" },
    @{ Old = "docs\\architecture"; New = "projet\\architecture" },
    @{ Old = "docs/tutorials"; New = "projet/tutorials" },
    @{ Old = "docs\\tutorials"; New = "projet\\tutorials" },
    @{ Old = "docs/guides"; New = "projet/guides" },
    @{ Old = "docs\\guides"; New = "projet\\guides" },
    @{ Old = "docs/development/roadmap"; New = "projet/roadmaps" },
    @{ Old = "docs\\development\\roadmap"; New = "projet\\roadmaps" },
    @{ Old = "docs/api"; New = "development/api" },
    @{ Old = "docs\\api"; New = "development\\api" },
    @{ Old = "docs/development/communications"; New = "development/communications" },
    @{ Old = "docs\\development\\communications"; New = "development\\communications" },
    @{ Old = "docs/development/n8n-internals"; New = "development/n8n-internals" },
    @{ Old = "docs\\development\\n8n-internals"; New = "development\\n8n-internals" },
    @{ Old = "docs/development/testing"; New = "development/testing" },
    @{ Old = "docs\\development\\testing"; New = "development\\testing" },
    @{ Old = "docs/development/testing/tests"; New = "development/testing/tests" },
    @{ Old = "docs\\development\\testing\\tests"; New = "development\\testing\\tests" },
    @{ Old = "docs/development/workflows"; New = "development/workflows" },
    @{ Old = "docs\\development\\workflows"; New = "development\\workflows" },
    @{ Old = "docs/guides/methodologies"; New = "development/methodologies" },
    @{ Old = "docs\\guides\\methodologies"; New = "development\\methodologies" }
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

    $content = Get-Content -Path $filePath -Raw
    $modified = $false

    foreach ($mapping in $mappings) {
        if ($content -match [regex]::Escape($mapping.Old)) {
            $content = $content -replace [regex]::Escape($mapping.Old), $mapping.New
            $modified = $true
        }
    }

    if ($modified) {
        Set-Content -Path $filePath -Value $content -NoNewline
        Write-Host "Updated references in: $filePath" -ForegroundColor Green
    }
}

# Find all markdown and text files in the project
$files = Get-ChildItem -Path . -Recurse -Include *.md, *.txt, *.ps1, *.py, *.js, *.html, *.css, *.json, *.yaml, *.yml -File

# Update references in each file
foreach ($file in $files) {
    Update-References -filePath $file.FullName -mappings $pathMappings
}

Write-Host "References updated successfully!" -ForegroundColor Green

