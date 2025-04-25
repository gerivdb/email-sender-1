﻿# Script pour mettre à jour les chemins du projet
# Ce script remplace les anciens chemins par les nouveaux chemins dans tous les fichiers pertinents

Write-Host "=== Mise à jour des chemins du projet ===" -ForegroundColor Cyan

# Ancien chemin (avec et sans espaces)
$oldPathVariants = @(
    # Variante avec espaces et underscores
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",

    # Variante sans espaces
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",

    # Variante avec espaces et accents
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
)

# Nouveau chemin
$newPath = "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"

# Types de fichiers à mettre à jour
$fileTypes = @("*.json", "*.cmd", "*.ps1", "*.yaml", "*.md", "*.py", "*.txt")

# Fonction pour mettre à jour un fichier
function Update-File {
    param (
        [string]$filePath
    )

    try {
        $content = Get-Content -Path $filePath -Raw -ErrorAction SilentlyContinue -Encoding UTF8
        if (-not $content) {
            return $false
        }

        $modified = $false
        foreach ($variant in $oldPathVariants) {
            # Échapper les caractères spéciaux pour la regex
            $escapedVariant = [regex]::Escape($variant)
            if ($content -match $escapedVariant) {
                $content = $content -replace $escapedVariant, $newPath
                $modified = $true
            }
        }

        if ($modified) {
            # Déterminer l'encodage approprié
            $encodingParam = "utf8"
            if ($filePath -match '\.ps1$') {
                # Pour les fichiers PowerShell, utiliser UTF-8 avec BOM
                $encodingParam = "utf8BOM"
            }

            Set-Content -Path $filePath -Value $content -NoNewline -Encoding $encodingParam
            Write-Host "✅ Fichier mis à jour: $filePath" -ForegroundColor Green
            return $true
        }

        return $false
    }
    catch {
        Write-Host "❌ Erreur lors de la mise à jour du fichier $filePath : $_" -ForegroundColor Red
        return $false
    }
}

# Rechercher tous les fichiers à mettre à jour
$allFiles = @()
foreach ($fileType in $fileTypes) {
    $files = Get-ChildItem -Path . -Recurse -File -Filter $fileType -Exclude "node_modules", ".git"
    $allFiles += $files
}

Write-Host "Nombre de fichiers à vérifier: $($allFiles.Count)" -ForegroundColor Yellow

# Mettre à jour les fichiers
$updatedFiles = 0
$errorFiles = 0

foreach ($file in $allFiles) {
    $result = Update-File -filePath $file.FullName
    if ($result) {
        $updatedFiles++
    }
}

# Afficher les résultats
Write-Host "`n=== Résultats ===" -ForegroundColor Cyan
Write-Host "Fichiers vérifiés: $($allFiles.Count)" -ForegroundColor White
Write-Host "Fichiers mis à jour: $updatedFiles" -ForegroundColor Green
Write-Host "Fichiers en erreur: $errorFiles" -ForegroundColor Red

# Créer un rapport de mise à jour
$reportPath = "logs\path_update_report_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
$reportDir = Split-Path -Parent $reportPath
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$report = @"
Rapport de mise à jour des chemins - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Anciens chemins:
$($oldPathVariants -join "`n")

Nouveau chemin:
$newPath

Fichiers vérifiés: $($allFiles.Count)
Fichiers mis à jour: $updatedFiles
Fichiers en erreur: $errorFiles
"@

Set-Content -Path $reportPath -Value $report -Encoding UTF8
Write-Host "Rapport de mise à jour enregistré dans: $reportPath" -ForegroundColor Cyan

if ($errorFiles -gt 0) {
    Write-Host "`nCertains fichiers n'ont pas pu être mis à jour. Vérifiez les erreurs ci-dessus." -ForegroundColor Yellow
}

Write-Host "`n=== Terminé ===" -ForegroundColor Cyan
