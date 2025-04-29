<#
.SYNOPSIS
    Tests unitaires pour vérifier le document des métriques pour l'estimation des ressources.

.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier que le document des métriques
    pour l'estimation des ressources a été correctement créé et contient toutes les informations nécessaires.

.PARAMETER DocumentPath
    Chemin vers le document des métriques pour l'estimation des ressources.

.EXAMPLE
    .\Test-ResourceMetrics.ps1 -DocumentPath "..\..\data\planning\resource-metrics.md"
    Exécute les tests unitaires pour le document des métriques pour l'estimation des ressources.

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
            return ($documentContent -match "# Métriques pour l'Estimation des Ressources")
        }
    },
    @{
        Name = "Test de la présence des catégories de ressources"
        Test = {
            return ($documentContent -match "## Catégories de Ressources")
        }
    },
    @{
        Name = "Test de la présence des métriques des ressources humaines"
        Test = {
            return ($documentContent -match "## Métriques des Ressources Humaines")
        }
    },
    @{
        Name = "Test de la présence de la taille de l'équipe"
        Test = {
            return ($documentContent -match "### Taille de l'Équipe")
        }
    },
    @{
        Name = "Test de la présence des rôles nécessaires"
        Test = {
            return ($documentContent -match "### Rôles Nécessaires")
        }
    },
    @{
        Name = "Test de la présence des métriques des compétences techniques"
        Test = {
            return ($documentContent -match "## Métriques des Compétences Techniques")
        }
    },
    @{
        Name = "Test de la présence du niveau d'expertise requis"
        Test = {
            return ($documentContent -match "### Niveau d'Expertise Requis")
        }
    },
    @{
        Name = "Test de la présence des domaines de compétence"
        Test = {
            return ($documentContent -match "### Domaines de Compétence")
        }
    },
    @{
        Name = "Test de la présence des métriques des ressources matérielles"
        Test = {
            return ($documentContent -match "## Métriques des Ressources Matérielles")
        }
    },
    @{
        Name = "Test de la présence de l'infrastructure requise"
        Test = {
            return ($documentContent -match "### Infrastructure Requise")
        }
    },
    @{
        Name = "Test de la présence des environnements nécessaires"
        Test = {
            return ($documentContent -match "### Environnements Nécessaires")
        }
    },
    @{
        Name = "Test de la présence des métriques des ressources temporelles"
        Test = {
            return ($documentContent -match "## Métriques des Ressources Temporelles")
        }
    },
    @{
        Name = "Test de la présence de la durée d'implémentation"
        Test = {
            return ($documentContent -match "### Durée d'Implémentation")
        }
    },
    @{
        Name = "Test de la présence des phases du projet"
        Test = {
            return ($documentContent -match "### Phases du Projet")
        }
    },
    @{
        Name = "Test de la présence des métriques des ressources financières"
        Test = {
            return ($documentContent -match "## Métriques des Ressources Financières")
        }
    },
    @{
        Name = "Test de la présence des coûts directs"
        Test = {
            return ($documentContent -match "### Coûts Directs")
        }
    },
    @{
        Name = "Test de la présence du modèle de calcul des coûts"
        Test = {
            return ($documentContent -match "### Modèle de Calcul des Coûts")
        }
    },
    @{
        Name = "Test de la présence de l'application des métriques"
        Test = {
            return ($documentContent -match "## Application des Métriques")
        }
    },
    @{
        Name = "Test de la présence du processus d'estimation"
        Test = {
            return ($documentContent -match "### Processus d'Estimation")
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
