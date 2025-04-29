<#
.SYNOPSIS
    Tests unitaires pour vérifier le rapport d'évaluation de la difficulté d'implémentation.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que le rapport d'évaluation
    de la difficulté d'implémentation a été correctement créé et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le rapport d'évaluation de la difficulté d'implémentation.

.EXAMPLE
    .\Test-ImplementationDifficulty.ps1 -DocumentPath "..\..\data\planning\implementation-difficulty.md"
    Exécute les tests unitaires pour le rapport d'évaluation de la difficulté d'implémentation.

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
            return ($documentContent -match "# Évaluation de la Difficulté d'Implémentation des Améliorations")
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
        Name = "Test de la présence des niveaux de difficulté"
        Test = {
            return ($documentContent -match "### Niveaux de Difficulté")
        }
    },
    @{
        Name = "Test de la présence du tableau des niveaux de difficulté"
        Test = {
            return ($documentContent -match "\| Niveau \| Score \| Description \|")
        }
    },
    @{
        Name = "Test de la présence de l'évaluation de la difficulté"
        Test = {
            return ($documentContent -match "#### Évaluation de la Difficulté")
        }
    },
    @{
        Name = "Test de la présence des facteurs de difficulté"
        Test = {
            return ($documentContent -match "\*\*Facteurs de difficulté :\*\*")
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
        Name = "Test de la présence de la justification pour la complexité technique"
        Test = {
            return ($documentContent -match "\*\*Complexité technique \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la présence de la justification pour l'expertise requise"
        Test = {
            return ($documentContent -match "\*\*Expertise requise \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la présence de la justification pour les contraintes de temps"
        Test = {
            return ($documentContent -match "\*\*Contraintes de temps \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la présence de la justification pour les dépendances"
        Test = {
            return ($documentContent -match "\*\*Dépendances \(Score : \d+\) :\*\*")
        }
    },
    @{
        Name = "Test de la présence du résumé"
        Test = {
            return ($documentContent -match "## Résumé")
        }
    },
    @{
        Name = "Test de la présence de la répartition par niveau de difficulté"
        Test = {
            return ($documentContent -match "### Répartition par Niveau de Difficulté")
        }
    },
    @{
        Name = "Test de la présence du tableau de répartition"
        Test = {
            return ($documentContent -match "\| Niveau \| Nombre \| Pourcentage \|")
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
    },
    @{
        Name = "Test de la présence du Roadmap Manager"
        Test = {
            return ($documentContent -match "## <a name='roadmap-manager'></a>Roadmap Manager")
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
