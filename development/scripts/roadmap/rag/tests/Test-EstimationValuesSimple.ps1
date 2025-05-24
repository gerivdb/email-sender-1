# Test-EstimationValuesSimple.ps1
# Script de test simplifié pour l'extraction des valeurs d'estimation
# Version: 1.0
# Date: 2025-05-15

# Importer la fonction à tester
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$metadataDir = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath "metadata"
$scriptPath = Join-Path -Path $metadataDir -ChildPath "Extract-EstimationValues.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script à tester n'existe pas: $scriptPath"
    exit 1
}

# Charger le script
. $scriptPath

# Créer des exemples de textes contenant des expressions d'estimation avec des valeurs
$testCases = @(
    @{
        Name = "Valeurs simples"
        Text = "Cette tâche est estimée à 3 jours de travail."
    },
    @{
        Name = "Valeurs avec décimales"
        Text = "Cette tâche prendra environ 3,5 jours."
    },
    @{
        Name = "Valeurs avec plage"
        Text = "Cette tâche prendra entre 3 et 5 jours."
    },
    @{
        Name = "Valeurs avec minimum"
        Text = "Cette tâche prendra au moins 3 jours."
    },
    @{
        Name = "Valeurs avec maximum"
        Text = "Cette tâche prendra au plus 5 jours."
    },
    @{
        Name = "Valeurs avec différentes unités"
        Text = "Cette tâche est estimée à 2 semaines."
    },
    @{
        Name = "Valeurs avec abréviations"
        Text = "Cette tâche est estimée à 4h."
    }
)

# Fonction pour exécuter les tests
function Start-Tests {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$TestCases
    )
    
    $totalValues = 0
    $passedTests = 0
    $failedTests = 0
    
    foreach ($testCase in $TestCases) {
        Write-Host "Test: $($testCase.Name)" -ForegroundColor Cyan
        
        # Exécuter la fonction avec le texte de test
        $results = Get-EstimationValues -Text $testCase.Text
        
        # Vérifier si des valeurs ont été trouvées
        if ($results -and $results.Count -gt 0) {
            Write-Host "  Résultat: $($results.Count) valeurs trouvées" -ForegroundColor Green
            $passedTests++
            $totalValues += $results.Count
            
            # Afficher les résultats
            foreach ($result in $results) {
                Write-Host "    Valeur: $($result.Value) $($result.Unit) (= $($result.HoursValue) heures)" -ForegroundColor Gray
                Write-Host "    Catégorie: $($result.Category)" -ForegroundColor Gray
                Write-Host "    Contexte: $($result.Context)" -ForegroundColor Gray
                Write-Host ""
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
Start-Tests -TestCases $testCases

