# Function to copy files recursively
function Copy-FilesRecursively {
    param (
        [string]$sourcePath,
        [string]$targetPath
    )

    if (-not (Test-Path -Path $sourcePath)) {
        Write-Warning "Source path does not exist: $sourcePath"
        return
    }

    if (-not (Test-Path -Path $targetPath)) {
        New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
    }

    # Copy files
    $files = Get-ChildItem -Path $sourcePath -File
    foreach ($file in $files) {
        $targetFile = Join-Path -Path $targetPath -ChildPath $file.Name
        Copy-Item -Path $file.FullName -Destination $targetPath -Force
        Write-Host "Copied: $($file.FullName) -> $targetPath" -ForegroundColor Green
    }

    # Copy subdirectories
    $directories = Get-ChildItem -Path $sourcePath -Directory
    foreach ($dir in $directories) {
        $targetDir = Join-Path -Path $targetPath -ChildPath $dir.Name
        Copy-FilesRecursively -sourcePath $dir.FullName -targetPath $targetDir
    }
}

# Mappings for copying files
$mappings = @(
    # Project
    @{ Source = ".\docs\architecture"; Target = ".\projet\architecture" },
    @{ Source = ".\docs\tutorials"; Target = ".\projet\tutorials" },
    @{ Source = ".\docs\guides"; Target = ".\projet\guides" },
    @{ Source = ".\docs\development\roadmap"; Target = ".\projet\roadmaps" },
    
    # Development
    @{ Source = ".\docs\api"; Target = ".\development\api" },
    @{ Source = ".\docs\development\communications"; Target = ".\development\communications" },
    @{ Source = ".\docs\development\n8n-internals"; Target = ".\development\n8n-internals" },
    @{ Source = ".\docs\development\testing"; Target = ".\development\testing" },
    @{ Source = ".\docs\development\tests"; Target = ".\development\testing\tests" },
    @{ Source = ".\docs\development\workflows"; Target = ".\development\workflows" },
    @{ Source = ".\docs\guides\methodologies"; Target = ".\development\methodologies" }
)

# Execute mappings
foreach ($mapping in $mappings) {
    Write-Host "Processing: $($mapping.Source) -> $($mapping.Target)" -ForegroundColor Cyan
    Copy-FilesRecursively -sourcePath $mapping.Source -targetPath $mapping.Target
}

Write-Host "Files copied successfully!" -ForegroundColor Green
