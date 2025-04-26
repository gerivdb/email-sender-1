# Script pour mettre à jour les cases à cocher dans le document actif

# Importer la fonction Update-ActiveDocumentCheckboxes
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$updateCheckboxesPath = Join-Path -Path $scriptPath -ChildPath "tools\scripts\roadmap-parser\module\Functions\Public\Update-ActiveDocumentCheckboxes.ps1"

if (Test-Path -Path $updateCheckboxesPath) {
    . $updateCheckboxesPath
    Write-Host "Fonction Update-ActiveDocumentCheckboxes importée." -ForegroundColor Green
} else {
    Write-Error "La fonction Update-ActiveDocumentCheckboxes est introuvable à l'emplacement : $updateCheckboxesPath"
    exit 1
}

# Chemin vers le document actif
$documentPath = Join-Path -Path $scriptPath -ChildPath "test-document-actif.md"

# Créer des résultats de test simulés
$implementationResults = @{
    "1.1" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Implémentation de la mise à jour des cases à cocher dans le document actif"
    }
    "1.2" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Détection automatique du document actif"
    }
    "1.3" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Mode simulation et mode force"
    }
    "1.4" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Documentation des nouvelles fonctionnalités"
    }
}

$testResults = @{
    "1.1" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Implémentation de la mise à jour des cases à cocher dans le document actif"
    }
    "1.2" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Détection automatique du document actif"
    }
    "1.3" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Mode simulation et mode force"
    }
    "1.4" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Documentation des nouvelles fonctionnalités"
    }
}

# Afficher le contenu du document avant la mise à jour
Write-Host "`nContenu du document avant la mise à jour :" -ForegroundColor Cyan
Get-Content -Path $documentPath | ForEach-Object { Write-Host $_ }

# Exécuter la fonction pour mettre à jour les cases à cocher
Write-Host "`nMise à jour des cases à cocher..." -ForegroundColor Cyan
$updateResult = Update-ActiveDocumentCheckboxes -DocumentPath $documentPath -ImplementationResults $implementationResults -TestResults $testResults

# Afficher le contenu du document après la mise à jour
Write-Host "`nContenu du document après la mise à jour :" -ForegroundColor Cyan
Get-Content -Path $documentPath | ForEach-Object { Write-Host $_ }

Write-Host "`nMise à jour terminée. $updateResult cases à cocher ont été mises à jour." -ForegroundColor Green
