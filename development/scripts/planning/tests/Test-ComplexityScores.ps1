<#
.SYNOPSIS
    Tests unitaires pour vérifier le rapport des scores de complexité technique.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que le rapport des scores
    de complexité technique a été correctement créé et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le rapport des scores de complexité technique.

.EXAMPLE
    .\Test-ComplexityScores.ps1 -DocumentPath "..\..\data\planning\complexity-scores.md"
    Exécute les tests unitaires pour le rapport des scores de complexité technique.

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
            return ($documentContent -match "# Attribution des Scores de Complexité Technique des Améliorations")
        }
    },
    @{
        Name = "Test de la présence de la table des matières"
        Test = {
            return ($documentContent -match "## Table des Matières")
        }
    },
    @{
        Name = "Test de la présence de la méthodologie"
        Test = {
            return ($documentContent -match "## Méthodologie")
        }
    },
    @{
        Name = "Test de la présence des niveaux de complexité technique"
        Test = {
            return ($documentContent -match "### Niveaux de Complexité Technique")
        }
    },
    @{
        Name = "Test de la présence du tableau des niveaux de complexité"
        Test = {
            return ($documentContent -match "\| Niveau \| Score \| Description \|")
        }
    },
    @{
        Name = "Test de la présence du score de complexité technique"
        Test = {
            return ($documentContent -match "#### Score de Complexité Technique")
        }
    },
    @{
        Name = "Test de la présence des facteurs de complexité"
        Test = {
            return ($documentContent -match "\*\*Facteurs de complexité :\*\*")
        }
    },
    @{
        Name = "Test de la présence du tableau des facteurs"
        Test = {
            return ($documentContent -match "\| Facteur \| Poids \| Score \| Score pondéré \|")
        }
    },
    @{
        Name = "Test de la présence de la justification"
        Test = {
            return ($documentContent -match "#### Justification")
        }
    },
    @{
        Name = "Test de la présence de la justification pour le type d'amélioration"
        Test = {
            return ($documentContent -match "\*\*Type d'amélioration \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la présence de la justification pour l'effort requis"
        Test = {
            return ($documentContent -match "\*\*Effort requis \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la présence de la justification pour la difficulté d'implémentation"
        Test = {
            return ($documentContent -match "\*\*Difficulté d'implémentation \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la présence de la justification pour les risques techniques"
        Test = {
            return ($documentContent -match "\*\*Risques techniques \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la présence du résumé"
        Test = {
            return ($documentContent -match "## Résumé")
        }
    },
    @{
        Name = "Test de la présence de la répartition par niveau de complexité technique"
        Test = {
            return ($documentContent -match "### Répartition par Niveau de Complexité Technique")
        }
    },
    @{
        Name = "Test de la présence du tableau de répartition"
        Test = {
            return ($documentContent -match "\| Niveau \| Nombre \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la présence des recommandations"
        Test = {
            return ($documentContent -match "### Recommandations")
        }
    },
    @{
        Name = "Test de la présence du Process Manager"
        Test = {
            return ($documentContent -match "## <a name='process-manager'></a>Process Manager")
        }
    },
    @{
        Name = "Test de la présence du Mode Manager"
        Test = {
            return ($documentContent -match "## <a name='mode-manager'></a>Mode Manager")
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
