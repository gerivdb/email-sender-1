# Script pour organiser les fichiers dans le dépôt
# Date: 4 juin 2025

# Configuration
$rootPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$scriptsPath = Join-Path $rootPath "standalone-scripts-archive"
$developmentPath = Join-Path $rootPath "development"
$testPath = Join-Path $rootPath "tests"

# Création des répertoires nécessaires s'ils n'existent pas
@($scriptsPath, $developmentPath, $testPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Host "📁 Créé le répertoire: $_" -ForegroundColor Green
    }
}

# Fonction pour déplacer les fichiers en toute sécurité
function Move-FileSafely {
    param(
        [string]$source,
        [string]$destination,
        [switch]$createBackup = $true
    )

    if (-not (Test-Path $source)) {
        Write-Host "⚠️ Source non trouvée: $source" -ForegroundColor Yellow
        return
    }

    # Créer le répertoire de destination si nécessaire
    $destDir = Split-Path -Parent $destination
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    # Créer une sauvegarde si demandé
    if ($createBackup -and (Test-Path $source)) {
        $backupPath = "$source.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        Copy-Item $source $backupPath
        Write-Host "💾 Sauvegarde créée: $backupPath" -ForegroundColor Blue
    }

    # Déplacer le fichier
    try {
        Move-Item -Path $source -Destination $destination -Force
        Write-Host "✅ Déplacé: $source -> $destination" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Erreur lors du déplacement de $source : $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Déplacer les fichiers de test vers le répertoire de tests
Get-ChildItem -Path $rootPath -Filter "*_test.go" | ForEach-Object {
    $destPath = Join-Path $testPath $_.Name
    Move-FileSafely -source $_.FullName -destination $destPath
}

# Déplacer les scripts autonomes vers le répertoire scripts
Get-ChildItem -Path $rootPath -Include "*.ps1", "*.py", "*.sh" -File | Where-Object {
    $_.Directory.FullName -eq $rootPath
} | ForEach-Object {
    $destPath = Join-Path $scriptsPath $_.Name
    Move-FileSafely -source $_.FullName -destination $destPath
}

# Organiser les fichiers de développement
Get-ChildItem -Path $rootPath -Include "*.go" -File -Exclude "*_test.go" | Where-Object {
    $_.Directory.FullName -eq $rootPath
} | ForEach-Object {
    $destPath = Join-Path $developmentPath $_.Name
    Move-FileSafely -source $_.FullName -destination $destPath
}

Write-Host "`n📋 Organisation des fichiers terminée" -ForegroundColor Green
Write-Host "📊 Statistiques:"
@{
    "Scripts déplacés" = (Get-ChildItem $scriptsPath -File).Count
    "Fichiers de développement" = (Get-ChildItem $developmentPath -File).Count
    "Tests" = (Get-ChildItem $testPath -File).Count
} | Format-Table -AutoSize
