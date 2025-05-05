# Script to update all references to the old docs/ path
Write-Host "Updating all references to the old docs/ path..." -ForegroundColor Green

# Define path mappings
$pathMappings = @(
    # Project documentation
    @{ Old = "docs/architecture"; New = "projet/architecture" },
    @{ Old = "docs\\architecture"; New = "projet\\architecture" },
    @{ Old = "docs/tutorials"; New = "projet/tutorials" },
    @{ Old = "docs\\tutorials"; New = "projet\\tutorials" },
    @{ Old = "docs/guides"; New = "projet/guides" },
    @{ Old = "docs\\guides"; New = "projet\\guides" },
    @{ Old = "docs/development/roadmap"; New = "projet/roadmaps" },
    @{ Old = "docs\\development\\roadmap"; New = "projet\\roadmaps" },
    @{ Old = "docs/plans"; New = "projet/roadmaps/plans" },
    @{ Old = "docs\\plans"; New = "projet\\roadmaps\\plans" },
    @{ Old = "docs/readme"; New = "projet/documentation" },
    @{ Old = "docs\\readme"; New = "projet\\documentation" },
    @{ Old = "docs/assets"; New = "projet/assets" },
    @{ Old = "docs\\assets"; New = "projet\\assets" },
    @{ Old = "docs/journal_de_bord"; New = "projet/roadmaps/journal" },
    @{ Old = "docs\\journal_de_bord"; New = "projet\\roadmaps\\journal" },
    
    # Development documentation
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
    @{ Old = "docs\\guides\\methodologies"; New = "development\\methodologies" },
    @{ Old = "docs/reporting"; New = "development/reporting" },
    @{ Old = "docs\\reporting"; New = "development\\reporting" },
    
    # Individual files
    @{ Old = "docs/CacheManager.md"; New = "development/docs/CacheManager.md" },
    @{ Old = "docs\\CacheManager.md"; New = "development\\docs\\CacheManager.md" },
    @{ Old = "docs/CSV_YAML_Support.md"; New = "development/docs/CSV_YAML_Support.md" },
    @{ Old = "docs\\CSV_YAML_Support.md"; New = "development\\docs\\CSV_YAML_Support.md" },
    @{ Old = "docs/EncryptionUtils.md"; New = "development/docs/EncryptionUtils.md" },
    @{ Old = "docs\\EncryptionUtils.md"; New = "development\\docs\\EncryptionUtils.md" },
    @{ Old = "docs/FileSecurityUtils.md"; New = "development/docs/FileSecurityUtils.md" },
    @{ Old = "docs\\FileSecurityUtils.md"; New = "development\\docs\\FileSecurityUtils.md" },
    @{ Old = "docs/ParallelProcessing.md"; New = "development/docs/ParallelProcessing.md" },
    @{ Old = "docs\\ParallelProcessing.md"; New = "development\\docs\\ParallelProcessing.md" },
    @{ Old = "docs/OPTIMIZATIONS.md"; New = "development/docs/OPTIMIZATIONS.md" },
    @{ Old = "docs\\OPTIMIZATIONS.md"; New = "development\\docs\\OPTIMIZATIONS.md" },
    @{ Old = "docs/CODE_OF_CONDUCT.md"; New = "projet/documentation/CODE_OF_CONDUCT.md" },
    @{ Old = "docs\\CODE_OF_CONDUCT.md"; New = "projet\\documentation\\CODE_OF_CONDUCT.md" },
    @{ Old = "docs/CONTRIBUTING.md"; New = "projet/documentation/CONTRIBUTING.md" },
    @{ Old = "docs\\CONTRIBUTING.md"; New = "projet\\documentation\\CONTRIBUTING.md" },
    @{ Old = "docs/README.md"; New = "projet/documentation/README.md" },
    @{ Old = "docs\\README.md"; New = "projet\\documentation\\README.md" },
    @{ Old = "docs/README_MCP_USE.md"; New = "projet/documentation/README_MCP_USE.md" },
    @{ Old = "docs\\README_MCP_USE.md"; New = "projet\\documentation\\README_MCP_USE.md" },
    @{ Old = "docs/conf.py"; New = "projet/documentation/projet/config/conf.py" },
    @{ Old = "docs\\conf.py"; New = "projet\\documentation\\projet\\config\\conf.py" },
    @{ Old = "docs/index.rst"; New = "projet/documentation/projet/config/index.rst" },
    @{ Old = "docs\\index.rst"; New = "projet\\documentation\\projet\\config\\index.rst" },
    
    # Generic paths
    @{ Old = "docs/"; New = "projet/documentation/" },
    @{ Old = "docs\\"; New = "projet\\documentation\\" },
    @{ Old = "docs"; New = "projet/documentation" },
    @{ Old = "docs"; New = "projet\\documentation" }
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

