#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute les tests unitaires pour le module CycleDetector.
.DESCRIPTION
    Ce script exécute les tests unitaires pour le module CycleDetector et génère un rapport d'exécution.
.PARAMETER OutputPath
    Chemin où le rapport de test sera généré. Par défaut, il est créé dans le dossier docs/test_reports.
.PARAMETER ShowDetailedResults
    Affiche les résultats détaillés des tests dans la console.
.EXAMPLE
    .\Run-CycleDetectorTests.ps1
    Exécute les tests et génère un rapport dans le dossier par défaut.
.EXAMPLE
    .\Run-CycleDetectorTests.ps1 -OutputPath "C:\Reports" -ShowDetailedResults
    Exécute les tests, affiche les résultats détaillés et génère un rapport dans le dossier spécifié.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-01
#>
[CmdletBinding()]
param (
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\docs\test_reports"),
    [switch]$ShowDetailedResults
)

# Vérifier si Pester est installé
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Error "Le module Pester n'est pas installé. Veuillez l'installer avec la commande : Install-Module -Name Pester -Force"
    return
}

# Créer le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de sortie créé: $OutputPath" -ForegroundColor Green
}

# Chemin du fichier de rapport
$reportPath = Join-Path -Path $OutputPath -ChildPath "CycleDetector_TestReport.md"
$xmlReportPath = Join-Path -Path $OutputPath -ChildPath "CycleDetector_TestResults.xml"

# Importer le module Pester
Import-Module Pester -Force

# Configurer Pester
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = Join-Path -Path $PSScriptRoot -ChildPath "unit\CycleDetector.Tests.ps1"
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = if ($ShowDetailedResults) { 'Detailed' } else { 'Normal' }
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = $xmlReportPath
$pesterConfig.TestResult.OutputFormat = 'NUnitXml'

# Exécuter les tests
Write-Host "Exécution des tests unitaires pour le module CycleDetector..." -ForegroundColor Cyan
$results = Invoke-Pester -Configuration $pesterConfig

# Générer le rapport Markdown
$reportContent = @"
# Rapport d'exécution des tests - Module CycleDetector

## Résumé

- **Date d'exécution**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Nombre total de tests**: $($results.TotalCount)
- **Tests réussis**: $($results.PassedCount)
- **Tests échoués**: $($results.FailedCount)
- **Tests ignorés**: $($results.SkippedCount)
- **Durée totale**: $([math]::Round($results.Duration.TotalSeconds, 2)) secondes

## Détails des tests

### Tests fonctionnels

Les tests fonctionnels vérifient que le module CycleDetector détecte correctement les cycles dans différents types de graphes :

- Détection de cycles dans des graphes simples
- Détection de cycles dans des graphes complexes
- Gestion des cas limites (graphes vides, noeuds isolés, références nulles)
- Suppression de cycles
- Détection de cycles dans les dépendances de scripts
- Détection de cycles dans les workflows n8n

$(if ($results.FailedCount -eq 0) { "Tous les tests fonctionnels ont réussi, confirmant que le module fonctionne correctement." } else { "Certains tests fonctionnels ont échoué. Voir les détails ci-dessous." })

### Tests de performance

Les tests de performance vérifient que le module CycleDetector est efficace même avec de grands graphes :

- Traitement de petits graphes (10 noeuds) : < 1 seconde
- Traitement de graphes moyens (50 noeuds) : < 2 secondes
- Traitement de grands graphes (100 noeuds) : < 3 secondes
- Traitement de très grands graphes (1000 noeuds) : < 5 secondes

$(if ($results.FailedCount -eq 0) { "Tous les tests de performance ont réussi, confirmant que le module est suffisamment performant pour les cas d'utilisation prévus." } else { "Certains tests de performance ont échoué. Voir les détails ci-dessous." })

$(if ($results.FailedCount -gt 0) {
@"
## Tests échoués

$(foreach ($test in $results.Failed) {
"### $($test.Name)`n`n- **Description**: $($test.ExpandedName)`n- **Message**: $($test.ErrorRecord.Exception.Message)`n- **Emplacement**: $($test.ErrorRecord.ScriptStackTrace)`n"
})
"@
})

## Recommandations

1. **Amélioration de la gestion des erreurs**: Bien que le module gère correctement les erreurs, il serait utile d'ajouter plus de messages d'erreur descriptifs pour aider les utilisateurs à comprendre les problèmes.

2. **Documentation des tests**: Ajouter des commentaires plus détaillés dans les tests pour expliquer le but de chaque test et les résultats attendus.

3. **Tests d'intégration**: Développer des tests d'intégration pour vérifier que le module fonctionne correctement avec d'autres modules et dans des scénarios réels.

## Conclusion

$(if ($results.FailedCount -eq 0) { "Le module CycleDetector a passé tous les tests avec succès, démontrant sa fiabilité et ses performances." } else { "Le module CycleDetector présente des problèmes qui doivent être corrigés avant de pouvoir être utilisé en production." })
"@

# Enregistrer le rapport
$reportContent | Out-File -FilePath $reportPath -Encoding utf8

# Afficher le résumé
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "  Tests totaux: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests réussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests échoués: $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Tests ignorés: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host "  Durée totale: $([math]::Round($results.Duration.TotalSeconds, 2)) secondes" -ForegroundColor White

Write-Host "`nRapport généré: $reportPath" -ForegroundColor Green
Write-Host "Rapport XML généré: $xmlReportPath" -ForegroundColor Green

# Retourner le code de sortie
exit $results.FailedCount
