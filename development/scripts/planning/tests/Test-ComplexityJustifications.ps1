<#
.SYNOPSIS
    Tests unitaires pour vérifier le document des justifications des évaluations de complexité technique.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que le document des justifications
    des évaluations de complexité technique a été correctement créé et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le document des justifications des évaluations de complexité technique.

.EXAMPLE
    .\Test-ComplexityJustifications.ps1 -DocumentPath "..\..\data\planning\complexity-evaluation-justifications.md"
    Exécute les tests unitaires pour le document des justifications des évaluations de complexité technique.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de création: 2025-05-08
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
            return ($documentContent -match "# Justifications des Évaluations de Complexité Technique")
        }
    },
    @{
        Name = "Test de la présence de l'objectif"
        Test = {
            return ($documentContent -match "## Objectif")
        }
    },
    @{
        Name = "Test de la présence de la méthodologie d'évaluation"
        Test = {
            return ($documentContent -match "## Méthodologie d'Évaluation")
        }
    },
    @{
        Name = "Test de la présence des critères d'évaluation détaillés"
        Test = {
            return ($documentContent -match "## Critères d'Évaluation Détaillés")
        }
    },
    @{
        Name = "Test de la présence du type d'amélioration"
        Test = {
            return ($documentContent -match "### Type d'Amélioration")
        }
    },
    @{
        Name = "Test de la présence du tableau du type d'amélioration"
        Test = {
            return ($documentContent -match "\| Type \| Score \| Justification \|")
        }
    },
    @{
        Name = "Test de la présence de l'effort requis"
        Test = {
            return ($documentContent -match "### Effort Requis")
        }
    },
    @{
        Name = "Test de la présence du tableau de l'effort requis"
        Test = {
            return ($documentContent -match "\| Niveau \| Score \| Justification \|")
        }
    },
    @{
        Name = "Test de la présence de la difficulté d'implémentation"
        Test = {
            return ($documentContent -match "### Difficulté d'Implémentation")
        }
    },
    @{
        Name = "Test de la présence des risques techniques"
        Test = {
            return ($documentContent -match "### Risques Techniques")
        }
    },
    @{
        Name = "Test de la présence des justifications par gestionnaire"
        Test = {
            return ($documentContent -match "## Justifications par Gestionnaire")
        }
    },
    @{
        Name = "Test de la présence du Process Manager"
        Test = {
            return ($documentContent -match "### Process Manager")
        }
    },
    @{
        Name = "Test de la présence du Mode Manager"
        Test = {
            return ($documentContent -match "### Mode Manager")
        }
    },
    @{
        Name = "Test de la présence des justifications détaillées"
        Test = {
            return ($documentContent -match "\*\*Justification détaillée :\*\*")
        }
    },
    @{
        Name = "Test de la présence des recommandations"
        Test = {
            return ($documentContent -match "## Recommandations pour l'Utilisation des Évaluations")
        }
    },
    @{
        Name = "Test de la présence du processus de mise à jour"
        Test = {
            return ($documentContent -match "## Processus de Mise à Jour")
        }
    },
    @{
        Name = "Test de la présence de la conclusion"
        Test = {
            return ($documentContent -match "## Conclusion")
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
