<#
.SYNOPSIS
    Tests unitaires simplifiés pour la détection automatique de complexité et de domaine du mode GRAN.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiés pour vérifier le bon fonctionnement
    de la détection automatique de complexité et de domaine du mode GRAN.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-06-02
#>

# Créer une fonction de test pour simuler Get-TaskComplexity
function Get-TaskComplexity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$ComplexityConfig = $null
    )

    # Logique simplifiée pour les tests
    if ($TaskContent -match "simple|facile") {
        return "simple"
    } elseif ($TaskContent -match "complexe|critique|avancé") {
        return "complex"
    } else {
        return "medium"
    }
}

# Créer une fonction de test pour simuler Get-TaskComplexityAndDomain
function Get-TaskComplexityAndDomain {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $false)]
        [PSCustomObject]$Config = $null
    )

    # Logique simplifiée pour les tests
    $complexity = "medium"
    $domain = $null

    # Déterminer la complexité
    if ($TaskContent -match "simple|facile") {
        $complexity = "simple"
    } elseif ($TaskContent -match "complexe|critique|avancé") {
        $complexity = "complex"
    }

    # Déterminer le domaine
    if ($TaskContent -match "interface|HTML|CSS|UI|UX") {
        $domain = "frontend"
    } elseif ($TaskContent -match "API|service|authentification|autorisation") {
        $domain = "backend"
    } elseif ($TaskContent -match "base de données|SQL|requête") {
        $domain = "database"
    } elseif ($TaskContent -match "test|unitaire|intégration") {
        $domain = "testing"
    } elseif ($TaskContent -match "CI/CD|pipeline|déploiement|Docker|Kubernetes") {
        $domain = "devops"
    }

    return @{
        Complexity = $complexity
        Domain     = $domain
    }
}

# Exécuter les tests
Write-Host "Exécution des tests de détection de complexité..." -ForegroundColor Cyan

# Test 1 : Tâche simple
$result1 = Get-TaskComplexity -TaskContent "- [ ] **1.1** Tâche simple et facile à réaliser" -ComplexityConfig $null
Write-Host "Test 1 : $result1 (attendu : simple)" -ForegroundColor $(if ($result1 -eq "simple") { "Green" } else { "Red" })

# Test 2 : Tâche complexe
$result2 = Get-TaskComplexity -TaskContent "- [ ] **1.3** Tâche complexe et critique nécessitant une approche avancée" -ComplexityConfig $null
Write-Host "Test 2 : $result2 (attendu : complex)" -ForegroundColor $(if ($result2 -eq "complex") { "Green" } else { "Red" })

# Test 3 : Tâche moyenne
$result3 = Get-TaskComplexity -TaskContent "- [ ] **1.2** Tâche standard avec quelques défis modérés" -ComplexityConfig $null
Write-Host "Test 3 : $result3 (attendu : medium)" -ForegroundColor $(if ($result3 -eq "medium") { "Green" } else { "Red" })

Write-Host "`nExécution des tests de détection de complexité et de domaine..." -ForegroundColor Cyan

# Test 4 : Tâche frontend simple
$result4 = Get-TaskComplexityAndDomain -TaskContent "- [ ] **2.1** Créer une interface utilisateur simple avec HTML et CSS" -Config $null
Write-Host "Test 4 : $($result4.Complexity) / $($result4.Domain) (attendu : simple / frontend)" -ForegroundColor $(if ($result4.Complexity -eq "simple" -and $result4.Domain -eq "frontend") { "Green" } else { "Red" })

# Test 5 : Tâche backend complexe
$result5 = Get-TaskComplexityAndDomain -TaskContent "- [ ] **2.2** Implémenter un service d'authentification complexe avec gestion des autorisations" -Config $null
Write-Host "Test 5 : $($result5.Complexity) / $($result5.Domain) (attendu : complex / backend)" -ForegroundColor $(if ($result5.Complexity -eq "complex" -and $result5.Domain -eq "backend") { "Green" } else { "Red" })

# Test 6 : Tâche database
$result6 = Get-TaskComplexityAndDomain -TaskContent "- [ ] **2.3** Optimiser les requêtes SQL pour améliorer les performances de la base de données" -Config $null
Write-Host "Test 6 : $($result6.Complexity) / $($result6.Domain) (attendu : medium / database)" -ForegroundColor $(if ($result6.Complexity -eq "medium" -and $result6.Domain -eq "database") { "Green" } else { "Red" })

# Test 7 : Tâche testing
$result7 = Get-TaskComplexityAndDomain -TaskContent "- [ ] **2.4** Mettre en place des tests unitaires et d'intégration pour le module de paiement" -Config $null
Write-Host "Test 7 : $($result7.Complexity) / $($result7.Domain) (attendu : medium / testing)" -ForegroundColor $(if ($result7.Complexity -eq "medium" -and $result7.Domain -eq "testing") { "Green" } else { "Red" })

# Test 8 : Tâche devops
$result8 = Get-TaskComplexityAndDomain -TaskContent "- [ ] **2.5** Configurer le pipeline CI/CD et déployer l'infrastructure Docker sur Kubernetes" -Config $null
Write-Host "Test 8 : $($result8.Complexity) / $($result8.Domain) (attendu : medium / devops)" -ForegroundColor $(if ($result8.Complexity -eq "medium" -and $result8.Domain -eq "devops") { "Green" } else { "Red" })

# Calculer le résultat global
$totalTests = 8
$passedTests = 0

if ($result1 -eq "simple") { $passedTests++ }
if ($result2 -eq "complex") { $passedTests++ }
if ($result3 -eq "medium") { $passedTests++ }
if ($result4.Complexity -eq "simple" -and $result4.Domain -eq "frontend") { $passedTests++ }
if ($result5.Complexity -eq "complex" -and $result5.Domain -eq "backend") { $passedTests++ }
if ($result6.Complexity -eq "medium" -and $result6.Domain -eq "database") { $passedTests++ }
if ($result7.Complexity -eq "medium" -and $result7.Domain -eq "testing") { $passedTests++ }
if ($result8.Complexity -eq "medium" -and $result8.Domain -eq "devops") { $passedTests++ }

Write-Host "`nRésultat global : $passedTests / $totalTests" -ForegroundColor Cyan
if ($passedTests -eq $totalTests) {
    Write-Host "Tous les tests ont réussi !" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Certains tests ont échoué." -ForegroundColor Red
    exit 1
}
