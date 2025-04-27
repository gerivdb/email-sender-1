<#
.SYNOPSIS
    Tests unitaires pour la fonction Update-ActiveDocumentCheckboxes-Enhanced.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Update-ActiveDocumentCheckboxes-Enhanced
    qui met à jour les cases à cocher dans un document actif tout en préservant l'encodage UTF-8 avec BOM.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-05-01
#>

# Importer la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$functionPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Functions\Public\Update-ActiveDocumentCheckboxes-Enhanced.ps1"

if (-not (Test-Path -Path $functionPath)) {
    Write-Warning "La fonction Update-ActiveDocumentCheckboxes-Enhanced est introuvable à l'emplacement : $functionPath"

    # Essayer de trouver la fonction dans d'autres emplacements
    $alternativePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "roadmap-parser\module\Functions\Public\Update-ActiveDocumentCheckboxes-Enhanced.ps1"

    if (Test-Path -Path $alternativePath) {
        Write-Host "Fonction trouvée à l'emplacement alternatif : $alternativePath" -ForegroundColor Yellow
        $functionPath = $alternativePath
    } else {
        # Utiliser la fonction standard si la version améliorée n'est pas disponible
        $standardPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Functions\Public\Update-ActiveDocumentCheckboxes.ps1"

        if (Test-Path -Path $standardPath) {
            Write-Host "Utilisation de la fonction standard : $standardPath" -ForegroundColor Yellow
            $functionPath = $standardPath
        } else {
            Write-Error "Aucune fonction de mise à jour des cases à cocher n'a été trouvée."
            exit 1
        }
    }
}

Write-Host "Chargement de la fonction depuis : $functionPath" -ForegroundColor Cyan
. $functionPath

# Créer un fichier temporaire pour les tests
$tempFile = [System.IO.Path]::GetTempFileName() + ".md"

# Créer un contenu de test avec des caractères accentués
$testContent = @"
# Test Document avec caractères accentués

## Tâches

- [ ] **1.1** Tâche 1.1 avec des caractères spéciaux (é, è, à, ç)
- [ ] **1.2** Tâche 1.2 sans caractères spéciaux
- [ ] 1.3 Tâche 1.3 avec des caractères spéciaux (é, è, à, ç)
- [ ] Tâche 1.4 sans identifiant
- [x] **1.5** Tâche déjà cochée avec des caractères spéciaux (é, è, à, ç)
"@

# Écrire le contenu dans le fichier temporaire avec UTF-8 sans BOM
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($tempFile, $testContent, $utf8NoBom)

# Fonction pour vérifier si un fichier a un BOM UTF-8
function Test-HasUtf8Bom {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $bytes = [System.IO.File]::ReadAllBytes($FilePath)
    return $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
}

# Vérifier l'encodage initial
$hasBOM = Test-HasUtf8Bom -FilePath $tempFile

Write-Host "Encodage initial du fichier de test : " -NoNewline
if ($hasBOM) {
    Write-Host "UTF-8 avec BOM" -ForegroundColor Green
} else {
    Write-Host "UTF-8 sans BOM" -ForegroundColor Yellow
}

# Créer des résultats de test
$implementationResults = @{
    "1.1" = @{
        ImplementationComplete = $true
        TaskTitle = "Tâche 1.1 avec des caractères spéciaux (é, è, à, ç)"
    }
    "1.2" = @{
        ImplementationComplete = $false
        TaskTitle = "Tâche 1.2 sans caractères spéciaux"
    }
    "1.3" = @{
        ImplementationComplete = $true
        TaskTitle = "Tâche 1.3 avec des caractères spéciaux (é, è, à, ç)"
    }
}

$testResults = @{
    "1.1" = @{
        TestsComplete = $true
        TestsSuccessful = $true
    }
    "1.2" = @{
        TestsComplete = $true
        TestsSuccessful = $false
    }
    "1.3" = @{
        TestsComplete = $true
        TestsSuccessful = $true
    }
}

# Exécuter la fonction à tester
$result = Update-ActiveDocumentCheckboxes -DocumentPath $tempFile -ImplementationResults $implementationResults -TestResults $testResults

# Vérifier les résultats
$updatedContent = Get-Content -Path $tempFile -Encoding UTF8

# Vérifier l'encodage après mise à jour
$hasBOM = Test-HasUtf8Bom -FilePath $tempFile

Write-Host "Encodage après mise à jour : " -NoNewline
if ($hasBOM) {
    Write-Host "UTF-8 avec BOM" -ForegroundColor Green
} else {
    Write-Host "UTF-8 sans BOM" -ForegroundColor Red
    Write-Host "ERREUR: L'encodage n'a pas été correctement mis à jour!" -ForegroundColor Red
}

# Afficher les résultats
Write-Host "Résultat de la mise à jour : $result cases à cocher mises à jour" -ForegroundColor Cyan
Write-Host "Contenu mis à jour :" -ForegroundColor Cyan
$updatedContent | ForEach-Object { Write-Host $_ }

# Vérifier que les cases à cocher ont été mises à jour correctement
$expectedContent = @"
# Test Document avec caractères accentués

## Tâches

- [x] **1.1** Tâche 1.1 avec des caractères spéciaux (é, è, à, ç)
- [ ] **1.2** Tâche 1.2 sans caractères spéciaux
- [x] 1.3 Tâche 1.3 avec des caractères spéciaux (é, è, à, ç)
- [ ] Tâche 1.4 sans identifiant
- [x] **1.5** Tâche déjà cochée avec des caractères spéciaux (é, è, à, ç)
"@

# Comparer le contenu mis à jour avec le contenu attendu
$contentMatches = $true
$expectedLines = $expectedContent -split "`n"
for ($i = 0; $i -lt [Math]::Min($updatedContent.Count, $expectedLines.Count); $i++) {
    if ($updatedContent[$i] -ne $expectedLines[$i]) {
        Write-Host "Différence à la ligne $($i+1):" -ForegroundColor Red
        Write-Host "  Attendu: '$($expectedLines[$i])'" -ForegroundColor Yellow
        Write-Host "  Obtenu : '$($updatedContent[$i])'" -ForegroundColor Red
        $contentMatches = $false
    }
}

if ($contentMatches) {
    Write-Host "Le contenu mis à jour correspond au contenu attendu." -ForegroundColor Green
} else {
    Write-Host "Le contenu mis à jour ne correspond pas au contenu attendu!" -ForegroundColor Red
}

# Nettoyer le fichier temporaire
Remove-Item -Path $tempFile -Force

Write-Host "Test terminé." -ForegroundColor Cyan
