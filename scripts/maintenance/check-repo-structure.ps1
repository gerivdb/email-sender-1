# Script pour vérifier la structure du dépôt GitHub
# Ce script vérifie que la structure du dépôt est conforme aux conventions GitHub

Write-Host "Vérification de la structure du dépôt GitHub..." -ForegroundColor Cyan

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

# Liste des répertoires essentiels
$essentialDirs = @(
    ".github",
    "workflows",
    "config",
    "docs",
    "scripts"
)

# Vérification des fichiers essentiels
Write-Host "`nVérification des fichiers essentiels:" -ForegroundColor Yellow
$missingFiles = @()
foreach ($file in $essentialFiles) {
    if (Test-Path -Path $file) {
        Write-Host "✓ $file existe" -ForegroundColor Green
    } else {
        Write-Host "✗ $file est manquant" -ForegroundColor Red
        $missingFiles += $file
    }
}

# Vérification des répertoires essentiels
Write-Host "`nVérification des répertoires essentiels:" -ForegroundColor Yellow
$missingDirs = @()
foreach ($dir in $essentialDirs) {
    if (Test-Path -Path $dir -PathType Container) {
        Write-Host "✓ $dir existe" -ForegroundColor Green
    } else {
        Write-Host "✗ $dir est manquant" -ForegroundColor Red
        $missingDirs += $dir
    }
}

# Vérification de la structure GitHub
Write-Host "`nVérification de la structure GitHub:" -ForegroundColor Yellow
if (Test-Path -Path ".github\workflows") {
    Write-Host "✓ .github\workflows existe" -ForegroundColor Green
    
    # Vérifier s'il y a des fichiers de workflow
    $workflowFiles = Get-ChildItem -Path ".github\workflows" -Filter "*.yml" -File
    if ($workflowFiles.Count -gt 0) {
        Write-Host "✓ Des fichiers de workflow GitHub Actions sont présents" -ForegroundColor Green
    } else {
        Write-Host "✗ Aucun fichier de workflow GitHub Actions trouvé" -ForegroundColor Red
    }
} else {
    Write-Host "✗ .github\workflows est manquant" -ForegroundColor Red
}

if (Test-Path -Path ".github\ISSUE_TEMPLATE") {
    Write-Host "✓ .github\ISSUE_TEMPLATE existe" -ForegroundColor Green
} else {
    Write-Host "✗ .github\ISSUE_TEMPLATE est manquant" -ForegroundColor Red
}

# Vérification du package.json
if (Test-Path -Path "package.json") {
    Write-Host "`nVérification du package.json:" -ForegroundColor Yellow
    $packageJson = Get-Content -Path "package.json" -Raw | ConvertFrom-Json
    
    $requiredFields = @("name", "version", "description", "scripts", "license", "repository")
    foreach ($field in $requiredFields) {
        if ($packageJson.PSObject.Properties.Name -contains $field) {
            Write-Host "✓ Le champ '$field' existe dans package.json" -ForegroundColor Green
        } else {
            Write-Host "✗ Le champ '$field' est manquant dans package.json" -ForegroundColor Red
        }
    }
}

# Résumé
Write-Host "`nRésumé de la vérification:" -ForegroundColor Cyan
if ($missingFiles.Count -eq 0 -and $missingDirs.Count -eq 0) {
    Write-Host "✓ La structure du dépôt est conforme aux conventions GitHub!" -ForegroundColor Green
} else {
    Write-Host "✗ La structure du dépôt n'est pas entièrement conforme aux conventions GitHub." -ForegroundColor Red
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "`nFichiers manquants:" -ForegroundColor Yellow
        foreach ($file in $missingFiles) {
            Write-Host "  - $file" -ForegroundColor Red
        }
    }
    
    if ($missingDirs.Count -gt 0) {
        Write-Host "`nRépertoires manquants:" -ForegroundColor Yellow
        foreach ($dir in $missingDirs) {
            Write-Host "  - $dir" -ForegroundColor Red
        }
    }
    
    Write-Host "`nConsidérez d'ajouter ces éléments pour améliorer la conformité de votre dépôt." -ForegroundColor Yellow
}
