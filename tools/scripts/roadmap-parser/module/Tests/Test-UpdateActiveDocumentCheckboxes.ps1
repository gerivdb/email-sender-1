<#
.SYNOPSIS
    Tests unitaires pour la fonction Update-ActiveDocumentCheckboxes.

.DESCRIPTION
    Ce script contient des tests unitaires pour la fonction Update-ActiveDocumentCheckboxes
    qui met à jour les cases à cocher dans un document actif.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-09-15
#>

# Importer la fonction à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$functionPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "Functions\Public\Update-ActiveDocumentCheckboxes-Enhanced.ps1"
. $functionPath

# Créer un fichier temporaire pour les tests
$tempFile = [System.IO.Path]::GetTempFileName() + ".md"

# Créer un contenu de test
$testContent = @"
# Test Document

## Tâches

- [ ] **1.1** Tâche 1.1
- [ ] **1.2** Tâche 1.2
- [ ] 1.3 Tâche 1.3
- [ ] Tâche 1.4
- [x] **1.5** Tâche déjà cochée
"@

# Écrire le contenu dans le fichier temporaire
$testContent | Set-Content -Path $tempFile -Encoding UTF8

# Créer des résultats de test
$implementationResults = @{
    "1.1" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Tâche 1.1"
    }
    "1.2" = @{
        ImplementationComplete = $false
        ImplementationPercentage = 50
        TaskTitle = "Tâche 1.2"
    }
    "1.3" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Tâche 1.3"
    }
    "1.4" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Tâche 1.4"
    }
}

$testResults = @{
    "1.1" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Tâche 1.1"
    }
    "1.2" = @{
        TestsComplete = $false
        TestsSuccessful = $false
        TaskTitle = "Tâche 1.2"
    }
    "1.3" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Tâche 1.3"
    }
    "1.4" = @{
        TestsComplete = $false
        TestsSuccessful = $false
        TaskTitle = "Tâche 1.4"
    }
}

# Exécuter la fonction à tester
$result = Update-ActiveDocumentCheckboxes -DocumentPath $tempFile -ImplementationResults $implementationResults -TestResults $testResults

# Vérifier les résultats
$updatedContent = Get-Content -Path $tempFile -Encoding UTF8

# Afficher les résultats
Write-Host "Résultat de la mise à jour : $result cases à cocher mises à jour" -ForegroundColor Cyan
Write-Host "Contenu mis à jour :" -ForegroundColor Cyan
$updatedContent | ForEach-Object { Write-Host $_ }

# Vérifier que les cases à cocher ont été mises à jour correctement
$expectedContent = @"
# Test Document

## Tâches

- [x] **1.1** Tâche 1.1
- [ ] **1.2** Tâche 1.2
- [x] 1.3 Tâche 1.3
- [ ] Tâche 1.4
- [x] **1.5** Tâche déjà cochée
"@

$expectedLines = $expectedContent -split "`n"
$updatedLines = $updatedContent -join "`n" -split "`n"

$success = $true
for ($i = 0; $i -lt $expectedLines.Count; $i++) {
    if ($i -lt $updatedLines.Count) {
        if ($expectedLines[$i] -ne $updatedLines[$i]) {
            Write-Host "Différence à la ligne $($i+1):" -ForegroundColor Red
            Write-Host "  Attendu : $($expectedLines[$i])" -ForegroundColor Red
            Write-Host "  Obtenu  : $($updatedLines[$i])" -ForegroundColor Red
            $success = $false
        }
    } else {
        Write-Host "Ligne manquante à la position $($i+1) : $($expectedLines[$i])" -ForegroundColor Red
        $success = $false
    }
}

if ($updatedLines.Count -gt $expectedLines.Count) {
    for ($i = $expectedLines.Count; $i -lt $updatedLines.Count; $i++) {
        Write-Host "Ligne supplémentaire à la position $($i+1) : $($updatedLines[$i])" -ForegroundColor Red
        $success = $false
    }
}

# Nettoyer
Remove-Item -Path $tempFile -Force

# Afficher le résultat final
if ($success) {
    Write-Host "Test réussi : Les cases à cocher ont été mises à jour correctement." -ForegroundColor Green
} else {
    Write-Host "Test échoué : Les cases à cocher n'ont pas été mises à jour correctement." -ForegroundColor Red
}
