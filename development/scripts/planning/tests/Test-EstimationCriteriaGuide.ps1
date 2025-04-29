<#
.SYNOPSIS
    Tests unitaires pour vérifier le guide des critères d'estimation.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que le guide des critères
    d'estimation a été correctement créé et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le guide des critères d'estimation.

.EXAMPLE
    .\Test-EstimationCriteriaGuide.ps1 -DocumentPath "..\..\data\planning\estimation-criteria-guide.md"
    Exécute les tests unitaires pour le guide des critères d'estimation.

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
            return ($documentContent -match "# Guide des Critères d'Estimation")
        }
    },
    @{
        Name = "Test de la présence de l'objectif du guide"
        Test = {
            return ($documentContent -match "## Objectif du Guide")
        }
    },
    @{
        Name = "Test de la présence des documents de référence"
        Test = {
            return ($documentContent -match "## Documents de Référence")
        }
    },
    @{
        Name = "Test de la présence du processus d'estimation complet"
        Test = {
            return ($documentContent -match "## Processus d'Estimation Complet")
        }
    },
    @{
        Name = "Test de la présence de l'analyse préliminaire"
        Test = {
            return ($documentContent -match "### 1\. Analyse Préliminaire")
        }
    },
    @{
        Name = "Test de la présence de l'évaluation de la complexité"
        Test = {
            return ($documentContent -match "### 2\. Évaluation de la Complexité")
        }
    },
    @{
        Name = "Test de la présence de l'estimation des ressources"
        Test = {
            return ($documentContent -match "### 3\. Estimation des Ressources")
        }
    },
    @{
        Name = "Test de la présence du calcul de l'effort"
        Test = {
            return ($documentContent -match "### 4\. Calcul de l'Effort")
        }
    },
    @{
        Name = "Test de la présence de la validation et documentation"
        Test = {
            return ($documentContent -match "### 5\. Validation et Documentation")
        }
    },
    @{
        Name = "Test de la présence des critères d'estimation détaillés"
        Test = {
            return ($documentContent -match "## Critères d'Estimation Détaillés")
        }
    },
    @{
        Name = "Test de la présence des critères de complexité technique"
        Test = {
            return ($documentContent -match "### Critères de Complexité Technique")
        }
    },
    @{
        Name = "Test de la présence des critères de ressources humaines"
        Test = {
            return ($documentContent -match "### Critères de Ressources Humaines")
        }
    },
    @{
        Name = "Test de la présence des critères de durée"
        Test = {
            return ($documentContent -match "### Critères de Durée")
        }
    },
    @{
        Name = "Test de la présence des critères d'ajustement"
        Test = {
            return ($documentContent -match "### Critères d'Ajustement")
        }
    },
    @{
        Name = "Test de la présence du formulaire d'estimation"
        Test = {
            return ($documentContent -match "## Formulaire d'Estimation")
        }
    },
    @{
        Name = "Test de la présence des bonnes pratiques"
        Test = {
            return ($documentContent -match "## Bonnes Pratiques")
        }
    },
    @{
        Name = "Test de la présence des conseils pour des estimations précises"
        Test = {
            return ($documentContent -match "### Conseils pour des Estimations Précises")
        }
    },
    @{
        Name = "Test de la présence des pièges à éviter"
        Test = {
            return ($documentContent -match "### Pièges à Éviter")
        }
    },
    @{
        Name = "Test de la présence du processus d'amélioration continue"
        Test = {
            return ($documentContent -match "## Processus d'Amélioration Continue")
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
