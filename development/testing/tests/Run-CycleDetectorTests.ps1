#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute les tests unitaires pour le module CycleDetector.
.DESCRIPTION
    Ce script exÃ©cute les tests unitaires pour le module CycleDetector et gÃ©nÃ¨re un rapport d'exÃ©cution.
.PARAMETER OutputPath
    Chemin oÃ¹ le rapport de test sera gÃ©nÃ©rÃ©. Par dÃ©faut, il est crÃ©Ã© dans le dossier docs/test_reports.
.PARAMETER ShowDetailedResults
    Affiche les rÃ©sultats dÃ©taillÃ©s des tests dans la console.
.EXAMPLE
    .\Run-CycleDetectorTests.ps1
    ExÃ©cute les tests et gÃ©nÃ¨re un rapport dans le dossier par dÃ©faut.
.EXAMPLE
    .\Run-CycleDetectorTests.ps1 -OutputPath "C:\Reports" -ShowDetailedResults
    ExÃ©cute les tests, affiche les rÃ©sultats dÃ©taillÃ©s et gÃ©nÃ¨re un rapport dans le dossier spÃ©cifiÃ©.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de crÃ©ation: 2025-06-01
#>
[CmdletBinding()]
param (
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "..\docs\test_reports"),
    [switch]$ShowDetailedResults
)

# VÃ©rifier si Pester est installÃ©
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Error "Le module Pester n'est pas installÃ©. Veuillez l'installer avec la commande : Install-Module -Name Pester -Force"
    return
}

# CrÃ©er le dossier de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    Write-Host "Dossier de sortie crÃ©Ã©: $OutputPath" -ForegroundColor Green
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

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests unitaires pour le module CycleDetector..." -ForegroundColor Cyan
$results = Invoke-Pester -Configuration $pesterConfig

# GÃ©nÃ©rer le rapport Markdown
$reportContent = @"
# Rapport d'exÃ©cution des tests - Module CycleDetector

## RÃ©sumÃ©

- **Date d'exÃ©cution**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- **Nombre total de tests**: $($results.TotalCount)
- **Tests rÃ©ussis**: $($results.PassedCount)
- **Tests Ã©chouÃ©s**: $($results.FailedCount)
- **Tests ignorÃ©s**: $($results.SkippedCount)
- **DurÃ©e totale**: $([math]::Round($results.Duration.TotalSeconds, 2)) secondes

## DÃ©tails des tests

### Tests fonctionnels

Les tests fonctionnels vÃ©rifient que le module CycleDetector dÃ©tecte correctement les cycles dans diffÃ©rents types de graphes :

- DÃ©tection de cycles dans des graphes simples
- DÃ©tection de cycles dans des graphes complexes
- Gestion des cas limites (graphes vides, noeuds isolÃ©s, rÃ©fÃ©rences nulles)
- Suppression de cycles
- DÃ©tection de cycles dans les dÃ©pendances de scripts
- DÃ©tection de cycles dans les workflows n8n

$(if ($results.FailedCount -eq 0) { "Tous les tests fonctionnels ont rÃ©ussi, confirmant que le module fonctionne correctement." } else { "Certains tests fonctionnels ont Ã©chouÃ©. Voir les dÃ©tails ci-dessous." })

### Tests de performance

Les tests de performance vÃ©rifient que le module CycleDetector est efficace mÃªme avec de grands graphes :

- Traitement de petits graphes (10 noeuds) : < 1 seconde
- Traitement de graphes moyens (50 noeuds) : < 2 secondes
- Traitement de grands graphes (100 noeuds) : < 3 secondes
- Traitement de trÃ¨s grands graphes (1000 noeuds) : < 5 secondes

$(if ($results.FailedCount -eq 0) { "Tous les tests de performance ont rÃ©ussi, confirmant que le module est suffisamment performant pour les cas d'utilisation prÃ©vus." } else { "Certains tests de performance ont Ã©chouÃ©. Voir les dÃ©tails ci-dessous." })

$(if ($results.FailedCount -gt 0) {
@"
## Tests Ã©chouÃ©s

$(foreach ($test in $results.Failed) {
"### $($test.Name)`n`n- **Description**: $($test.ExpandedName)`n- **Message**: $($test.ErrorRecord.Exception.Message)`n- **Emplacement**: $($test.ErrorRecord.ScriptStackTrace)`n"
})
"@
})

## Recommandations

1. **AmÃ©lioration de la gestion des erreurs**: Bien que le module gÃ¨re correctement les erreurs, il serait utile d'ajouter plus de messages d'erreur descriptifs pour aider les utilisateurs Ã  comprendre les problÃ¨mes.

2. **Documentation des tests**: Ajouter des commentaires plus dÃ©taillÃ©s dans les tests pour expliquer le but de chaque test et les rÃ©sultats attendus.

3. **Tests d'intÃ©gration**: DÃ©velopper des tests d'intÃ©gration pour vÃ©rifier que le module fonctionne correctement avec d'autres modules et dans des scÃ©narios rÃ©els.

## Conclusion

$(if ($results.FailedCount -eq 0) { "Le module CycleDetector a passÃ© tous les tests avec succÃ¨s, dÃ©montrant sa fiabilitÃ© et ses performances." } else { "Le module CycleDetector prÃ©sente des problÃ¨mes qui doivent Ãªtre corrigÃ©s avant de pouvoir Ãªtre utilisÃ© en production." })
"@

# Enregistrer le rapport
$reportContent | Out-File -FilePath $reportPath -Encoding utf8

# Afficher le rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© des tests:" -ForegroundColor Cyan
Write-Host "  Tests totaux: $($results.TotalCount)" -ForegroundColor White
Write-Host "  Tests rÃ©ussis: $($results.PassedCount)" -ForegroundColor Green
Write-Host "  Tests Ã©chouÃ©s: $($results.FailedCount)" -ForegroundColor $(if ($results.FailedCount -gt 0) { "Red" } else { "Green" })
Write-Host "  Tests ignorÃ©s: $($results.SkippedCount)" -ForegroundColor Yellow
Write-Host "  DurÃ©e totale: $([math]::Round($results.Duration.TotalSeconds, 2)) secondes" -ForegroundColor White

Write-Host "`nRapport gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Green
Write-Host "Rapport XML gÃ©nÃ©rÃ©: $xmlReportPath" -ForegroundColor Green

# Retourner le code de sortie
exit $results.FailedCount
