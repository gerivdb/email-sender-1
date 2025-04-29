<#
.SYNOPSIS
    Tests unitaires pour vérifier le document des niveaux de complexité technique.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que le document des niveaux
    de complexité technique a été correctement créé et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le document des niveaux de complexité technique.

.EXAMPLE
    .\Test-ComplexityLevels.ps1 -DocumentPath "..\..\data\planning\complexity-levels.md"
    Exécute les tests unitaires pour le document des niveaux de complexité technique.

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
            return ($documentContent -match "# Niveaux de Complexité Technique")
        }
    },
    @{
        Name = "Test de la présence de l'échelle de complexité"
        Test = {
            return ($documentContent -match "## Échelle de Complexité")
        }
    },
    @{
        Name = "Test de la présence du tableau des niveaux"
        Test = {
            return ($documentContent -match "\| Niveau \| Score \| Description \|")
        }
    },
    @{
        Name = "Test de la présence des critères d'évaluation"
        Test = {
            return ($documentContent -match "## Critères d'Évaluation par Niveau")
        }
    },
    @{
        Name = "Test de la présence du niveau 1"
        Test = {
            return ($documentContent -match "### Niveau 1 : Très faible")
        }
    },
    @{
        Name = "Test de la présence du niveau 2"
        Test = {
            return ($documentContent -match "### Niveau 2 : Faible")
        }
    },
    @{
        Name = "Test de la présence du niveau 3"
        Test = {
            return ($documentContent -match "### Niveau 3 : Moyen")
        }
    },
    @{
        Name = "Test de la présence du niveau 4"
        Test = {
            return ($documentContent -match "### Niveau 4 : Élevé")
        }
    },
    @{
        Name = "Test de la présence du niveau 5"
        Test = {
            return ($documentContent -match "### Niveau 5 : Très élevé")
        }
    },
    @{
        Name = "Test de la présence des caractéristiques"
        Test = {
            return ($documentContent -match "\*\*Caractéristiques :\*\*")
        }
    },
    @{
        Name = "Test de la présence des exemples"
        Test = {
            return ($documentContent -match "\*\*Exemples :\*\*")
        }
    },
    @{
        Name = "Test de la présence de l'effort typique"
        Test = {
            return ($documentContent -match "\*\*Effort typique :\*\*")
        }
    },
    @{
        Name = "Test de la présence de l'application aux facteurs"
        Test = {
            return ($documentContent -match "## Application aux Facteurs de Complexité")
        }
    },
    @{
        Name = "Test de la présence de l'exemple d'évaluation"
        Test = {
            return ($documentContent -match "### Exemple d'Évaluation")
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
