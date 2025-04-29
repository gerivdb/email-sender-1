<#
.SYNOPSIS
    Tests unitaires pour vérifier le rapport des risques techniques.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que le rapport des risques
    techniques a été correctement créé et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le rapport des risques techniques.

.EXAMPLE
    .\Test-TechnicalRisks.ps1 -DocumentPath "..\..\data\planning\technical-risks.md"
    Exécute les tests unitaires pour le rapport des risques techniques.

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
            return ($documentContent -match "# Identification des Risques Techniques des Améliorations")
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
        Name = "Test de la présence de l'évaluation de la criticité des risques"
        Test = {
            return ($documentContent -match "### Évaluation de la Criticité des Risques")
        }
    },
    @{
        Name = "Test de la présence du tableau de criticité"
        Test = {
            return ($documentContent -match "\| Impact \| Probabilité \| Criticité \|")
        }
    },
    @{
        Name = "Test de la présence des risques identifiés"
        Test = {
            return ($documentContent -match "#### Risques Identifiés")
        }
    },
    @{
        Name = "Test de la présence du tableau des risques"
        Test = {
            return ($documentContent -match "\| Catégorie \| Description \| Impact \| Probabilité \| Criticité \| Mitigation \|")
        }
    },
    @{
        Name = "Test de la présence du résumé"
        Test = {
            return ($documentContent -match "## Résumé")
        }
    },
    @{
        Name = "Test de la présence de la répartition par niveau de criticité"
        Test = {
            return ($documentContent -match "### Répartition par Niveau de Criticité")
        }
    },
    @{
        Name = "Test de la présence du tableau de répartition"
        Test = {
            return ($documentContent -match "\| Niveau \| Nombre \| Pourcentage \|")
        }
    },
    @{
        Name = "Test de la présence des recommandations générales"
        Test = {
            return ($documentContent -match "### Recommandations Générales")
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
