# Script global pour corriger tous les problÃ¨mes d'encodage dans le projet
# Ce script corrige l'encodage des fichiers PowerShell, CMD, Markdown et autres fichiers texte

Write-Host "=== Correction de tous les problÃ¨mes d'encodage ===" -ForegroundColor Cyan

# 1. Corriger l'encodage des fichiers PowerShell
Write-Host "`n[1] Correction de l'encodage des fichiers PowerShell" -ForegroundColor Yellow
& .\development\scripts\maintenance\fix-encoding-scripts.ps1

# 2. Corriger l'encodage des fichiers CMD
Write-Host "`n[2] Correction de l'encodage des fichiers CMD" -ForegroundColor Yellow
& .\development\scripts\maintenance\fix-encoding-cmd.ps1

# 3. Corriger l'encodage des fichiers Markdown
Write-Host "`n[3] Correction de l'encodage des fichiers Markdown" -ForegroundColor Yellow

# Fonction pour convertir un fichier Markdown en UTF-8 avec BOM
function ConvertTo-UTF8WithBOM {
    param (
        [string]$FilePath
    )
    
    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        [System.IO.File]::WriteAllText($FilePath, $content, [System.Text.Encoding]::UTF8)
        Write-Host "Fichier converti: $FilePath" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur lors de la conversion du fichier $FilePath : $_" -ForegroundColor Red
    }
}

# Rechercher tous les fichiers Markdown dans le projet
$mdFiles = Get-ChildItem -Path . -Filter "*.md" -Recurse

Write-Host "Conversion de $($mdFiles.Count) fichiers Markdown en UTF-8 avec BOM..." -ForegroundColor Yellow

foreach ($file in $mdFiles) {
    ConvertTo-UTF8WithBOM -FilePath $file.FullName
}

# 4. Corriger l'encodage des fichiers JSON
Write-Host "`n[4] Correction de l'encodage des fichiers JSON" -ForegroundColor Yellow

# Rechercher tous les fichiers JSON dans le projet
$jsonFiles = Get-ChildItem -Path . -Filter "*.json" -Recurse

Write-Host "Conversion de $($jsonFiles.Count) fichiers JSON en UTF-8 avec BOM..." -ForegroundColor Yellow

foreach ($file in $jsonFiles) {
    ConvertTo-UTF8WithBOM -FilePath $file.FullName
}

# 5. Ajouter un hook Git pour maintenir l'encodage correct
Write-Host "`n[5] Configuration d'un hook Git pour maintenir l'encodage correct" -ForegroundColor Yellow

$gitHooksDir = ".git\hooks"
if (Test-Path ".git") {
    if (-not (Test-Path $gitHooksDir)) {
        New-Item -ItemType Directory -Path $gitHooksDir -Force | Out-Null
    }

    $preCommitHookPath = "$gitHooksDir\pre-commit"
    $preCommitHookContent = @"
#!/bin/sh
# Pre-commit hook pour corriger l'encodage des fichiers

echo "Correction de l'encodage des fichiers avant commit..."
powershell -ExecutionPolicy Bypass -File "..\..\D"

# Ajouter les fichiers modifiÃ©s au commit
git add -u
"@

    Set-Content -Path $preCommitHookPath -Value $preCommitHookContent -Encoding UTF8
    Write-Host "Hook Git pre-commit configurÃ© pour corriger automatiquement l'encodage" -ForegroundColor Green
} else {
    Write-Host "DÃ©pÃ´t Git non trouvÃ©, impossible de configurer le hook pre-commit" -ForegroundColor Yellow
}

Write-Host "`n=== Correction de tous les problÃ¨mes d'encodage terminÃ©e ===" -ForegroundColor Cyan
Write-Host "Tous les fichiers du projet ont Ã©tÃ© convertis avec l'encodage appropriÃ©." -ForegroundColor Green
Write-Host "Les fichiers PowerShell et Markdown sont en UTF-8 avec BOM." -ForegroundColor Green
Write-Host "Les fichiers CMD sont en ANSI (Windows-1252)." -ForegroundColor Green
Write-Host "Un hook Git a Ã©tÃ© configurÃ© pour maintenir l'encodage correct." -ForegroundColor Green

