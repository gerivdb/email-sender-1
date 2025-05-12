# Test-GetEstimationValues.ps1
# Script de test pour l'extraction des valeurs d'estimation
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
$scriptPath = Join-Path -Path $metadataDir -ChildPath "Get-EstimationValues.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script à tester n'existe pas: $scriptPath"
    exit 1
}

# Créer des exemples de textes contenant des expressions d'estimation avec des valeurs
$testCases = @(
    @{
        Name = "Valeurs simples"
        Text = @"
Cette tâche est estimée à 3 jours de travail.
Le temps prévu pour cette fonctionnalité est de 2 semaines.
La durée estimée est de 4 heures.
Cette tâche devrait prendre environ 5 jours.
Le développement est évalué à 10 jours-homme.
"@
    },
    @{
        Name = "Valeurs avec décimales"
        Text = @"
Cette tâche prendra environ 3,5 jours.
Le développement durera à peu près 2.5 semaines.
La mise en place devrait prendre plus ou moins 5,5 heures.
Cette fonctionnalité nécessitera autour de 10.25 jours de travail.
Le temps de développement est estimé à 4,75 jours.
"@
    },
    @{
        Name = "Valeurs avec plage"
        Text = @"
Cette tâche prendra entre 3 et 5 jours.
Le développement durera de 2 à 3 semaines.
La mise en place devrait prendre de 4 à 6 heures.
Cette fonctionnalité nécessitera entre 8 et 12 jours de travail.
Le temps de développement est estimé à 3-5 jours.
"@
    },
    @{
        Name = "Valeurs avec minimum/maximum"
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
        Name = "Valeurs avec différentes unités"
        Text = @"
Cette tâche est estimée à 3 jours de travail.
Le temps prévu pour cette fonctionnalité est de 2 semaines.
La durée estimée est de 4 heures.
Cette tâche devrait prendre environ 1 mois.
Le développement est évalué à 2 trimestres.
La maintenance est estimée à 1 an.
"@
    },
    @{
        Name = "Valeurs avec abréviations"
        Text = @"
Cette tâche est estimée à 3j.
Le temps prévu pour cette fonctionnalité est de 2s.
La durée estimée est de 4h.
Cette tâche devrait prendre environ 1m.
Le développement est évalué à 2a.
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
    
    $totalValues = 0
    $passedTests = 0
    $failedTests = 0
    
    foreach ($testCase in $TestCases) {
        Write-Host "Test: $($testCase.Name)" -ForegroundColor Cyan
        
        # Exécuter le script avec le texte de test
        $result = & $scriptPath -InputText $testCase.Text -OutputFormat $OutputFormat
        
        # Vérifier si des valeurs ont été trouvées
        if ($result -and $result -notmatch "Aucune valeur d'estimation trouvée") {
            Write-Host "  Résultat: Valeurs trouvées" -ForegroundColor Green
            $passedTests++
            
            # Compter le nombre de valeurs trouvées
            if ($OutputFormat -eq "Text") {
                $valuesCount = ([regex]::Matches($result, "Valeur:")).Count
                $totalValues += $valuesCount
                Write-Host "  Nombre de valeurs trouvées: $valuesCount" -ForegroundColor Green
            }
            
            # Afficher les résultats
            if ($OutputFormat -eq "Text") {
                Write-Host $result -ForegroundColor Gray
            } else {
                Write-Host "  Résultat au format $OutputFormat généré" -ForegroundColor Gray
            }
        } else {
            Write-Host "  Résultat: Aucune valeur trouvée" -ForegroundColor Red
            $failedTests++
        }
        
        Write-Host ""
    }
    
    # Afficher le résumé des tests
    Write-Host "Résumé des tests:" -ForegroundColor Cyan
    Write-Host "  Tests réussis: $passedTests" -ForegroundColor Green
    Write-Host "  Tests échoués: $failedTests" -ForegroundColor Red
    Write-Host "  Total des valeurs trouvées: $totalValues" -ForegroundColor Cyan
}

# Exécuter les tests
Run-Tests -TestCases $testCases -OutputFormat $OutputFormat
