<#
.SYNOPSIS
    Tests unitaires pour vérifier le rapport des compétences requises.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que le rapport des compétences
    requises a été correctement créé et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le rapport des compétences requises.

.EXAMPLE
    .\Test-RequiredSkills.ps1 -DocumentPath "..\..\data\planning\required-skills.md"
    Exécute les tests unitaires pour le rapport des compétences requises.

.NOTES
    Auteur: Planning Team
    Version: 1.0
    Date de création: 2025-05-09
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
            return ($documentContent -match "# Identification des Compétences Requises pour les Améliorations")
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
        Name = "Test de la présence des niveaux de compétence"
        Test = {
            return ($documentContent -match "### Niveaux de Compétence")
        }
    },
    @{
        Name = "Test de la présence du tableau des niveaux de compétence"
        Test = {
            return ($documentContent -match "\| Niveau \| Description \|")
        }
    },
    @{
        Name = "Test de la présence des compétences requises"
        Test = {
            return ($documentContent -match "#### Compétences Requises")
        }
    },
    @{
        Name = "Test de la présence du tableau des compétences"
        Test = {
            return ($documentContent -match "\| Catégorie \| Compétence \| Niveau \| Justification \|")
        }
    },
    @{
        Name = "Test de la présence du résumé"
        Test = {
            return ($documentContent -match "## Résumé")
        }
    },
    @{
        Name = "Test de la présence de la répartition par catégorie"
        Test = {
            return ($documentContent -match "### Répartition par Catégorie")
        }
    },
    @{
        Name = "Test de la présence du tableau de répartition par catégorie"
        Test = {
            return ($documentContent -match "\| Catégorie \| Nombre de Compétences \|")
        }
    },
    @{
        Name = "Test de la présence de la répartition par niveau"
        Test = {
            return ($documentContent -match "### Répartition par Niveau")
        }
    },
    @{
        Name = "Test de la présence du tableau de répartition par niveau"
        Test = {
            return ($documentContent -match "\| Niveau \| Nombre \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la présence des compétences les plus demandées"
        Test = {
            return ($documentContent -match "### Compétences les Plus Demandées")
        }
    },
    @{
        Name = "Test de la présence du tableau des compétences les plus demandées"
        Test = {
            return ($documentContent -match "\| Catégorie \| Compétence \| Nombre d'Améliorations \|")
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
