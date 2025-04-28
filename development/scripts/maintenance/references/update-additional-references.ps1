# Script to update additional path references
Write-Host "Updating additional path references..." -ForegroundColor Green

# Define path mappings
$pathMappings = @(
    @{ Old = "_templates"; New = "development/templates" },
    @{ Old = "_templates/"; New = "development/templates/" },
    @{ Old = "_templates\\"; New = "development\\templates\\" },
    @{ Old = "config/"; New = "projet/config/" },
    @{ Old = "config\\"; New = "projet\\config\\" },
    @{ Old = "./config/"; New = "./projet/config/" },
    @{ Old = ".\\config\\"; New = ".\\projet\\config\\" },
    @{ Old = ".\config\"; New = ".\projet\config\" }
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
