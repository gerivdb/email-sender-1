# Script pour verifier la structure du depot GitHub
# Ce script verifie que la structure du depot est conforme aux conventions GitHub

Write-Host "Verification de la structure du depot GitHub..." -ForegroundColor Cyan

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

# Liste des repertoires essentiels
$essentialDirs = @(
    ".github",
    "workflows",
    "config",
    "docs",
    "scripts"
)

# Verification des fichiers essentiels
Write-Host "`nVerification des fichiers essentiels:" -ForegroundColor Yellow
$missingFiles = @()
foreach ($file in $essentialFiles) {
    if (Test-Path -Path $file) {
        Write-Host "OK $file existe" -ForegroundColor Green
    } else {
        Write-Host "X $file est manquant" -ForegroundColor Red
        $missingFiles += $file
    }
}

# Verification des repertoires essentiels
Write-Host "`nVerification des repertoires essentiels:" -ForegroundColor Yellow
$missingDirs = @()
foreach ($dir in $essentialDirs) {
    if (Test-Path -Path $dir -PathType Container) {
        Write-Host "OK $dir existe" -ForegroundColor Green
    } else {
        Write-Host "X $dir est manquant" -ForegroundColor Red
        $missingDirs += $dir
    }
}

# Verification de la structure GitHub
Write-Host "`nVerification de la structure GitHub:" -ForegroundColor Yellow
if (Test-Path -Path ".github\workflows") {
    Write-Host "OK .github\workflows existe" -ForegroundColor Green
    
    # Verifier s'il y a des fichiers de workflow
    $workflowFiles = Get-ChildItem -Path ".github\workflows" -Filter "*.yml" -File
    if ($workflowFiles.Count -gt 0) {
        Write-Host "OK Des fichiers de workflow GitHub Actions sont presents" -ForegroundColor Green
    } else {
        Write-Host "X Aucun fichier de workflow GitHub Actions trouve" -ForegroundColor Red
    }
} else {
    Write-Host "X .github\workflows est manquant" -ForegroundColor Red
}

if (Test-Path -Path ".github\ISSUE_TEMPLATE") {
    Write-Host "OK .github\ISSUE_TEMPLATE existe" -ForegroundColor Green
} else {
    Write-Host "X .github\ISSUE_TEMPLATE est manquant" -ForegroundColor Red
}

# Verification du package.json
if (Test-Path -Path "package.json") {
    Write-Host "`nVerification du package.json:" -ForegroundColor Yellow
    $packageJson = Get-Content -Path "package.json" -Raw | ConvertFrom-Json
    
    $requiredFields = @("name", "version", "description", "scripts", "license", "repository")
    foreach ($field in $requiredFields) {
        if ($packageJson.PSObject.Properties.Name -contains $field) {
            Write-Host "OK Le champ '$field' existe dans package.json" -ForegroundColor Green
        } else {
            Write-Host "X Le champ '$field' est manquant dans package.json" -ForegroundColor Red
        }
    }
}

# Resume
Write-Host "`nResume de la verification:" -ForegroundColor Cyan
if ($missingFiles.Count -eq 0 -and $missingDirs.Count -eq 0) {
    Write-Host "OK La structure du depot est conforme aux conventions GitHub!" -ForegroundColor Green
} else {
    Write-Host "X La structure du depot n'est pas entierement conforme aux conventions GitHub." -ForegroundColor Red
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "`nFichiers manquants:" -ForegroundColor Yellow
        foreach ($file in $missingFiles) {
            Write-Host "  - $file" -ForegroundColor Red
        }
    }
    
    if ($missingDirs.Count -gt 0) {
        Write-Host "`nRepertoires manquants:" -ForegroundColor Yellow
        foreach ($dir in $missingDirs) {
            Write-Host "  - $dir" -ForegroundColor Red
        }
    }
    
    Write-Host "`nConsiderez d'ajouter ces elements pour ameliorer la conformite de votre depot." -ForegroundColor Yellow
}
