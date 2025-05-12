# Test-EstimationExpressions.ps1
# Script de test pour l'analyse des expressions d'estimation
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$OutputFormat = "Text"
)

# Importer le script à tester
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$metadataDir = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath "metadata"
$scriptPath = Join-Path -Path $metadataDir -ChildPath "Analyze-EstimationExpressions.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script à tester n'existe pas: $scriptPath"
    exit 1
}

# Créer des exemples de textes contenant des expressions d'estimation
$testCases = @(
    @{
        Name = "Expressions précises"
        Text = @"
Cette tâche est estimée à 3 jours de travail.
Le temps prévu pour cette fonctionnalité est de 2 semaines.
La durée estimée est de 4 heures.
Cette tâche devrait prendre environ 5 jours.
Le développement est évalué à 10 jours-homme.
"@
    },
    @{
        Name = "Expressions approximatives"
        Text = @"
Cette tâche prendra environ 3 jours.
Le développement durera à peu près 2 semaines.
La mise en place devrait prendre plus ou moins 5 heures.
Cette fonctionnalité nécessitera autour de 10 jours de travail.
Le temps de développement est estimé à ~4 jours.
"@
    },
    @{
        Name = "Expressions avec plage"
        Text = @"
Cette tâche prendra entre 3 et 5 jours.
Le développement durera de 2 à 3 semaines.
La mise en place devrait prendre de 4 à 6 heures.
Cette fonctionnalité nécessitera entre 8 et 12 jours de travail.
Le temps de développement est estimé à 3-5 jours.
"@
    },
    @{
        Name = "Expressions avec minimum/maximum"
        Text = @"
Cette tâche prendra au moins 3 jours.
Le développement durera au maximum 2 semaines.
La mise en place devrait prendre minimum 5 heures.
Cette fonctionnalité nécessitera au plus 10 jours de travail.
Le temps de développement est estimé à min 4 jours.
Le temps de développement est estimé à max 7 jours.
"@
    },
    @{
        Name = "Expressions mixtes"
        Text = @"
Cette tâche est estimée à environ 3 jours de travail.
Le temps prévu pour cette fonctionnalité est d'au moins 2 semaines.
La durée estimée est entre 4 et 6 heures.
Cette tâche devrait prendre au maximum 5 jours.
Le développement est évalué à plus ou moins 10 jours-homme.
"@
    }
)

# Fonction pour exécuter les tests
function Run-Tests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$TestCases,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputFormat = "Text"
    )
    
    $totalExpressions = 0
    $passedTests = 0
    $failedTests = 0
    
    foreach ($testCase in $TestCases) {
        Write-Host "Test: $($testCase.Name)" -ForegroundColor Cyan
        
        # Exécuter le script avec le texte de test
        $result = & $scriptPath -InputText $testCase.Text -OutputFormat $OutputFormat
        
        # Analyser les résultats
        if ($OutputFormat -eq "JSON") {
            $resultObj = $result | ConvertFrom-Json
            $expressionsCount = $resultObj.Count
        } else {
            # Pour les autres formats, compter les occurrences de "Expression:" dans le résultat
            $expressionsCount = ([regex]::Matches($result, "Expression:")).Count
        }
        
        $totalExpressions += $expressionsCount
        
        # Vérifier si des expressions ont été trouvées
        if ($expressionsCount -gt 0) {
            Write-Host "  Résultat: $expressionsCount expressions trouvées" -ForegroundColor Green
            $passedTests++
        } else {
            Write-Host "  Résultat: Aucune expression trouvée" -ForegroundColor Red
            $failedTests++
        }
        
        # Afficher les résultats
        if ($OutputFormat -eq "Text") {
            Write-Host $result -ForegroundColor Gray
        } else {
            Write-Host "  Résultat au format $OutputFormat généré" -ForegroundColor Gray
        }
        
        Write-Host ""
    }
    
    # Afficher le résumé des tests
    Write-Host "Résumé des tests:" -ForegroundColor Cyan
    Write-Host "  Tests réussis: $passedTests" -ForegroundColor Green
    Write-Host "  Tests échoués: $failedTests" -ForegroundColor Red
    Write-Host "  Total des expressions trouvées: $totalExpressions" -ForegroundColor Cyan
}

# Exécuter les tests
Run-Tests -TestCases $testCases -OutputFormat $OutputFormat
