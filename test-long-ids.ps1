# Script pour tester la mise à jour des cases à cocher avec des identifiants longs

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

# Chemin vers le document de test
$documentPath = Join-Path -Path $scriptPath -ChildPath "test-long-ids.md"

# Créer des résultats de test simulés avec des identifiants longs
$implementationResults = @{
    "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.1" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Implémenter l'analyse des permissions de registre"
    }
    "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.2" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Implémenter la détection des héritages de permissions de registre"
    }
    "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.3" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Implémenter l'analyse des propriétaires de clés de registre"
    }
    "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.4" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Implémenter la détection des anomalies de permissions de registre"
    }
    "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.5" = @{
        ImplementationComplete = $true
        ImplementationPercentage = 100
        TaskTitle = "Implémenter la génération de rapports de permissions de registre"
    }
}

$testResults = @{
    "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.1" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Implémenter l'analyse des permissions de registre"
    }
    "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.2" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Implémenter la détection des héritages de permissions de registre"
    }
    "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.3" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Implémenter l'analyse des propriétaires de clés de registre"
    }
    "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.4" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Implémenter la détection des anomalies de permissions de registre"
    }
    "1.3.1.2.2.1.2.1.1.1.1.1.3.2.5.6.2.6.2.5" = @{
        TestsComplete = $true
        TestsSuccessful = $true
        TaskTitle = "Implémenter la génération de rapports de permissions de registre"
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
