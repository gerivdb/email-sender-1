<#
.SYNOPSIS
    Tests unitaires pour vérifier le document des facteurs de complexité.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que le document des facteurs
    de complexité a été correctement créé et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le document des facteurs de complexité.

.EXAMPLE
    .\Test-ComplexityFactors.ps1 -DocumentPath "..\..\data\planning\complexity-factors.md"
    Exécute les tests unitaires pour le document des facteurs de complexité.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de création: 2025-05-07
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$DocumentPath
)

# Vérifier que le document existe
if (-not (Test-Path -Path $DocumentPath)) {
    Write-Error "Le document est introuvable : $DocumentPath"
    exit 1
}

# Fonction pour exécuter un test
function Test-Function {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [scriptblock]$Test
    )

    Write-Host "`nTest : $Name" -ForegroundColor Cyan
    
    try {
        $result = & $Test
        
        if ($result -eq $true) {
            Write-Host "  Résultat : Succès" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Résultat : Échec" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Erreur : $_" -ForegroundColor Red
        return $false
    }
}

# Charger le contenu du document
$documentContent = Get-Content -Path $DocumentPath -Raw

# Tests unitaires
$tests = @(
    @{
        Name = "Test de l'existence du document"
        Test = {
            return (Test-Path -Path $DocumentPath -PathType Leaf)
        }
    },
    @{
        Name = "Test de la présence du titre principal"
        Test = {
            return ($documentContent -match "# Facteurs Influençant la Complexité des Améliorations")
        }
    },
    @{
        Name = "Test de la présence de la table des matières"
        Test = {
            return ($documentContent -match "## Table des Matières")
        }
    },
    @{
        Name = "Test de la présence des facteurs de complexité technique"
        Test = {
            return ($documentContent -match "## <a name='technicalcomplexity'></a>Facteurs liés à la complexité technique de l'amélioration")
        }
    },
    @{
        Name = "Test de la présence des facteurs de complexité fonctionnelle"
        Test = {
            return ($documentContent -match "## <a name='functionalcomplexity'></a>Facteurs liés à la complexité fonctionnelle de l'amélioration")
        }
    },
    @{
        Name = "Test de la présence des facteurs de complexité du projet"
        Test = {
            return ($documentContent -match "## <a name='projectcomplexity'></a>Facteurs liés à la complexité du projet")
        }
    },
    @{
        Name = "Test de la présence des facteurs de complexité de qualité"
        Test = {
            return ($documentContent -match "## <a name='qualitycomplexity'></a>Facteurs liés aux exigences de qualité")
        }
    },
    @{
        Name = "Test de la présence de la matrice d'évaluation"
        Test = {
            return ($documentContent -match "## Matrice d'Évaluation")
        }
    },
    @{
        Name = "Test de la présence des poids pour les facteurs"
        Test = {
            return ($documentContent -match "\(Poids: \d+\.\d+\)")
        }
    },
    @{
        Name = "Test de la présence d'exemples pour les facteurs"
        Test = {
            return ($documentContent -match "\*\*Exemples :\*\*")
        }
    }
)

# Exécuter les tests
$totalTests = $tests.Count
$passedTests = 0

foreach ($test in $tests) {
    $result = Test-Function -Name $test.Name -Test $test.Test
    
    if ($result) {
        $passedTests++
    }
}

# Afficher le résumé
Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "  Tests exécutés : $totalTests" -ForegroundColor Cyan
Write-Host "  Tests réussis : $passedTests" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
Write-Host "  Tests échoués : $($totalTests - $passedTests)" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Red" })

# Retourner le résultat
if ($passedTests -eq $totalTests) {
    Write-Host "`nTous les tests ont réussi." -ForegroundColor Green
    exit 0
} else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
