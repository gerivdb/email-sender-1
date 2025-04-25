# Script pour mettre à jour les chemins dans les scripts de la Phase 6
# Ce script remplace les anciens chemins par les nouveaux chemins dans les scripts de la Phase 6

Write-Host "=== Mise à jour des chemins dans les scripts de la Phase 6 ===" -ForegroundColor Cyan

# Ancien chemin (avec et sans espaces)
$oldPathVariants = @(
    # Variante avec espaces et underscores
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",

    # Variante sans espaces
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1",
    "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"
)

# Nouveau chemin
$newPath = "D:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1"

# Répertoire des scripts de la Phase 6
$phase6Dir = $PSScriptRoot

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
            $encodingParam = "UTF8"

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

# Rechercher tous les scripts PowerShell dans le répertoire de la Phase 6
$scripts = Get-ChildItem -Path $phase6Dir -File -Filter "*.ps1"
Write-Host "Nombre de scripts à vérifier: $($scripts.Count)" -ForegroundColor Yellow

# Mettre à jour les scripts
$updatedFiles = 0
$errorFiles = 0

foreach ($script in $scripts) {
    $result = Update-File -filePath $script.FullName
    if ($result) {
        $updatedFiles++
    }
}

# Mettre à jour les fichiers batch
$batchFiles = Get-ChildItem -Path $phase6Dir -File -Filter "*.bat"
Write-Host "Nombre de fichiers batch à vérifier: $($batchFiles.Count)" -ForegroundColor Yellow

foreach ($batchFile in $batchFiles) {
    $result = Update-File -filePath $batchFile.FullName
    if ($result) {
        $updatedFiles++
    }
}

# Afficher les résultats
Write-Host "`n=== Résultats ===" -ForegroundColor Cyan
Write-Host "Scripts vérifiés: $($scripts.Count)" -ForegroundColor White
Write-Host "Fichiers batch vérifiés: $($batchFiles.Count)" -ForegroundColor White
Write-Host "Fichiers mis à jour: $updatedFiles" -ForegroundColor Green
Write-Host "Fichiers en erreur: $errorFiles" -ForegroundColor Red

if ($errorFiles -gt 0) {
    Write-Host "`nCertains fichiers n'ont pas pu être mis à jour. Vérifiez les erreurs ci-dessus." -ForegroundColor Yellow
}

Write-Host "`n=== Terminé ===" -ForegroundColor Cyan
