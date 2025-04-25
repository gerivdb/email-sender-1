# Script pour vÃ©rifier la structure du dÃ©pÃ´t GitHub
# Ce script vÃ©rifie que la structure du dÃ©pÃ´t est conforme aux conventions GitHub

Write-Host "VÃ©rification de la structure du dÃ©pÃ´t GitHub..." -ForegroundColor Cyan

# Liste des fichiers essentiels
$essentialFiles = @(
    ".gitignore",
    ".gitattributes",
    "LICENSE",
    "README.md",
    "CONTRIBUTING.md",
    "CHANGELOG.md",
    "CODE_OF_CONDUCT.md",
    "package.json"
)

# Liste des rÃ©pertoires essentiels
$essentialDirs = @(
    ".github",
    "workflows",
    "config",
    "docs",
    "scripts"
)

# VÃ©rification des fichiers essentiels
Write-Host "`nVÃ©rification des fichiers essentiels:" -ForegroundColor Yellow
$missingFiles = @()
foreach ($file in $essentialFiles) {
    if (Test-Path -Path $file) {
        Write-Host "âœ“ $file existe" -ForegroundColor Green
    } else {
        Write-Host "âœ— $file est manquant" -ForegroundColor Red
        $missingFiles += $file
    }
}

# VÃ©rification des rÃ©pertoires essentiels
Write-Host "`nVÃ©rification des rÃ©pertoires essentiels:" -ForegroundColor Yellow
$missingDirs = @()
foreach ($dir in $essentialDirs) {
    if (Test-Path -Path $dir -PathType Container) {
        Write-Host "âœ“ $dir existe" -ForegroundColor Green
    } else {
        Write-Host "âœ— $dir est manquant" -ForegroundColor Red
        $missingDirs += $dir
    }
}

# VÃ©rification de la structure GitHub
Write-Host "`nVÃ©rification de la structure GitHub:" -ForegroundColor Yellow
if (Test-Path -Path ".github\workflows") {
    Write-Host "âœ“ .github\workflows existe" -ForegroundColor Green
    
    # VÃ©rifier s'il y a des fichiers de workflow
    $workflowFiles = Get-ChildItem -Path ".github\workflows" -Filter "*.yml" -File
    if ($workflowFiles.Count -gt 0) {
        Write-Host "âœ“ Des fichiers de workflow GitHub Actions sont prÃ©sents" -ForegroundColor Green
    } else {
        Write-Host "âœ— Aucun fichier de workflow GitHub Actions trouvÃ©" -ForegroundColor Red
    }
} else {
    Write-Host "âœ— .github\workflows est manquant" -ForegroundColor Red
}

if (Test-Path -Path ".github\ISSUE_TEMPLATE") {
    Write-Host "âœ“ .github\ISSUE_TEMPLATE existe" -ForegroundColor Green
} else {
    Write-Host "âœ— .github\ISSUE_TEMPLATE est manquant" -ForegroundColor Red
}

# VÃ©rification du package.json
if (Test-Path -Path "package.json") {
    Write-Host "`nVÃ©rification du package.json:" -ForegroundColor Yellow
    $packageJson = Get-Content -Path "package.json" -Raw | ConvertFrom-Json
    
    $requiredFields = @("name", "version", "description", "scripts", "license", "repository")
    foreach ($field in $requiredFields) {
        if ($packageJson.PSObject.Properties.Name -contains $field) {
            Write-Host "âœ“ Le champ '$field' existe dans package.json" -ForegroundColor Green
        } else {
            Write-Host "âœ— Le champ '$field' est manquant dans package.json" -ForegroundColor Red
        }
    }
}

# RÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de la vÃ©rification:" -ForegroundColor Cyan
if ($missingFiles.Count -eq 0 -and $missingDirs.Count -eq 0) {
    Write-Host "âœ“ La structure du dÃ©pÃ´t est conforme aux conventions GitHub!" -ForegroundColor Green
} else {
    Write-Host "âœ— La structure du dÃ©pÃ´t n'est pas entiÃ¨rement conforme aux conventions GitHub." -ForegroundColor Red
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "`nFichiers manquants:" -ForegroundColor Yellow
        foreach ($file in $missingFiles) {
            Write-Host "  - $file" -ForegroundColor Red
        }
    }
    
    if ($missingDirs.Count -gt 0) {
        Write-Host "`nRÃ©pertoires manquants:" -ForegroundColor Yellow
        foreach ($dir in $missingDirs) {
            Write-Host "  - $dir" -ForegroundColor Red
        }
    }
    
    Write-Host "`nConsidÃ©rez d'ajouter ces Ã©lÃ©ments pour amÃ©liorer la conformitÃ© de votre dÃ©pÃ´t." -ForegroundColor Yellow
}
