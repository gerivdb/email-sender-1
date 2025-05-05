# Main script to execute documentation reorganization
param (
    [switch]$Force,
    [switch]$WhatIf
)

# User confirmation
if (-not $Force -and -not $WhatIf) {
    $confirmation = Read-Host "This operation will reorganize the documentation structure. Do you want to continue? (Y/N)"
    if ($confirmation -ne "Y" -and $confirmation -ne "y") {
        Write-Host "Operation cancelled by user." -ForegroundColor Yellow
        exit
    }
}

# Step 1: Create structure
Write-Host "Step 1: Creating folder structure..." -ForegroundColor Green
if (-not $WhatIf) {
    & .\development\scripts\create-doc-structure.ps1
} else {
    Write-Host "WhatIf: Would create folder structure" -ForegroundColor Cyan
}

# Step 2: Copy files
Write-Host "Step 2: Copying files..." -ForegroundColor Green
if (-not $WhatIf) {
    & .\development\scripts\copy-doc-files.ps1
} else {
    Write-Host "WhatIf: Would copy files" -ForegroundColor Cyan
}

# Step 3: Update references
Write-Host "Step 3: Updating references..." -ForegroundColor Green
if (-not $WhatIf) {
    & .\development\scripts\update-doc-references.ps1
} else {
    Write-Host "WhatIf: Would update references" -ForegroundColor Cyan
}

Write-Host "Documentation reorganization completed successfully!" -ForegroundColor Green

# Display new structure
if (-not $WhatIf) {
    Write-Host "Structure of 'projet' folder:" -ForegroundColor Cyan
    Get-ChildItem -Path ".\projet" -Recurse -Directory | Select-Object FullName | Format-Table -AutoSize

    Write-Host "Structure of 'development' folder:" -ForegroundColor Cyan
    Get-ChildItem -Path ".\development" -Recurse -Directory | Select-Object FullName | Format-Table -AutoSize
} else {
    Write-Host "WhatIf: Would display new structure" -ForegroundColor Cyan
}
