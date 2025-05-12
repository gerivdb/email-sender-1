# Test-DecimalEstimationValues.ps1
# Script de test pour l'extraction des valeurs d'estimation décimales
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
$scriptPath = Join-Path -Path $metadataDir -ChildPath "Get-DecimalEstimationValues.ps1"

# Vérifier si le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script à tester n'existe pas: $scriptPath"
    exit 1
}

# Créer des exemples de textes contenant des expressions d'estimation avec des valeurs décimales
$testCases = @(
    @{
        Name = "Valeurs avec virgule"
        Text = @"
Cette tâche prendra environ 3,5 jours.
La mise en place devrait prendre plus ou moins 5,5 heures.
Le temps de développement est estimé à 4,75 jours.
"@
    },
    @{
        Name = "Valeurs avec point"
        Text = @"
Le développement durera à peu près 2.5 semaines.
Cette fonctionnalité nécessitera autour de 10.25 jours de travail.
"@
    },
    @{
        Name = "Valeurs mixtes"
        Text = @"
Cette tâche prendra environ 3,5 jours et le développement durera à peu près 2.5 semaines.
La mise en place devrait prendre plus ou moins 5,5 heures et cette fonctionnalité nécessitera autour de 10.25 jours de travail.
Le temps de développement est estimé à 4,75 jours.
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
        if ($result -and $result -notmatch "Aucune valeur d'estimation") {
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
