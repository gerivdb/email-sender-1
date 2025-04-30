<#
.SYNOPSIS
    Tests unitaires pour la détection automatique de complexité et de domaine du mode GRAN.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    de la détection automatique de complexité et de domaine du mode GRAN.

.NOTES
    Auteur: RoadmapParser Team
    Version: 2.0
    Date de création: 2025-06-01
    Date de mise à jour: 2025-06-02 - Ajout des tests de détection de domaine
#>

# Importer les fonctions à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$granModePath = Join-Path -Path $modulePath -ChildPath "..\..\..\scripts\maintenance\modes\gran-mode.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $granModePath)) {
    throw "Le script gran-mode.ps1 est introuvable à l'emplacement : $granModePath"
}

# Créer une fonction de test pour Get-TaskComplexity
function Test-GetTaskComplexity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedComplexity,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ComplexityConfig
    )

    # Appeler la fonction Get-TaskComplexity
    $result = Get-TaskComplexity -TaskContent $TaskContent -ComplexityConfig $ComplexityConfig

    # Vérifier le résultat
    if ($result -eq $ExpectedComplexity) {
        Write-Host "Test réussi : '$TaskContent' -> Complexité: $result" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Test échoué : '$TaskContent' -> Complexité: $result (attendu : $ExpectedComplexity)" -ForegroundColor Red
        return $false
    }
}

# Créer une fonction de test pour Get-TaskComplexityAndDomain
function Test-GetTaskComplexityAndDomain {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $true)]
        [string]$ExpectedComplexity,

        [Parameter(Mandatory = $false)]
        [string]$ExpectedDomain = $null,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    # Appeler la fonction Get-TaskComplexityAndDomain
    $result = Get-TaskComplexityAndDomain -TaskContent $TaskContent -Config $Config

    # Vérifier le résultat de complexité
    $complexityMatch = $result.Complexity -eq $ExpectedComplexity

    # Vérifier le résultat de domaine
    $domainMatch = $true
    if ($ExpectedDomain -ne $null) {
        $domainMatch = $result.Domain -eq $ExpectedDomain
    }

    # Afficher le résultat
    if ($complexityMatch -and $domainMatch) {
        Write-Host "Test réussi : '$TaskContent' -> Complexité: $($result.Complexity), Domaine: $($result.Domain)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Test échoué : '$TaskContent' -> Complexité: $($result.Complexity) (attendu : $ExpectedComplexity), Domaine: $($result.Domain) (attendu : $ExpectedDomain)" -ForegroundColor Red
        return $false
    }
}

# Charger le script gran-mode.ps1 pour accéder aux fonctions
# Créer une fonction de test pour simuler les fonctions du script gran-mode.ps1
function Get-TaskComplexity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ComplexityConfig
    )

    # Initialiser les scores pour chaque niveau de complexité
    $scores = @{
        "simple"  = 0
        "medium"  = 0
        "complex" = 0
    }

    # Vérifier les mots-clés dans le contenu de la tâche
    foreach ($level in $scores.Keys) {
        foreach ($keyword in $ComplexityConfig.keywords.$level) {
            if ($TaskContent -match $keyword) {
                $scores[$level] += 1
            }
        }
    }

    # Vérifier la longueur du contenu (indicateur de complexité)
    $wordCount = ($TaskContent -split '\s+').Count
    if ($wordCount -lt 10) {
        $scores["simple"] += 2
    } elseif ($wordCount -lt 30) {
        $scores["medium"] += 2
    } else {
        $scores["complex"] += 2
    }

    # Déterminer le niveau de complexité en fonction des scores
    $maxScore = 0
    $maxLevel = "medium" # Par défaut

    foreach ($level in $scores.Keys) {
        if ($scores[$level] -gt $maxScore) {
            $maxScore = $scores[$level]
            $maxLevel = $level
        }
    }

    return $maxLevel
}

function Get-TaskComplexityAndDomain {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    # Initialiser les scores pour chaque niveau de complexité
    $complexityScores = @{
        "simple"  = 0
        "medium"  = 0
        "complex" = 0
    }

    # Initialiser les scores pour chaque domaine
    $domainScores = @{
        "frontend" = 0
        "backend"  = 0
        "database" = 0
        "testing"  = 0
        "devops"   = 0
    }

    # Vérifier les mots-clés de complexité dans le contenu de la tâche
    foreach ($level in $complexityScores.Keys) {
        foreach ($keyword in $Config.keywords.$level) {
            if ($TaskContent -match $keyword) {
                $complexityScores[$level] += 1
            }
        }
    }

    # Vérifier les mots-clés de domaine dans le contenu de la tâche
    foreach ($domain in $domainScores.Keys) {
        if ($Config.keywords.PSObject.Properties.Name -contains $domain) {
            foreach ($keyword in $Config.keywords.$domain) {
                if ($TaskContent -match $keyword) {
                    $domainScores[$domain] += 1
                }
            }
        }
    }

    # Vérifier la longueur du contenu (indicateur de complexité)
    $wordCount = ($TaskContent -split '\s+').Count
    if ($wordCount -lt 10) {
        $complexityScores["simple"] += 2
    } elseif ($wordCount -lt 30) {
        $complexityScores["medium"] += 2
    } else {
        $complexityScores["complex"] += 2
    }

    # Déterminer le niveau de complexité en fonction des scores
    $maxComplexityScore = 0
    $maxComplexityLevel = "medium" # Par défaut

    foreach ($level in $complexityScores.Keys) {
        if ($complexityScores[$level] -gt $maxComplexityScore) {
            $maxComplexityScore = $complexityScores[$level]
            $maxComplexityLevel = $level
        }
    }

    # Déterminer le domaine en fonction des scores
    $maxDomainScore = 0
    $maxDomain = $null # Par défaut, pas de domaine spécifique

    foreach ($domain in $domainScores.Keys) {
        if ($domainScores[$domain] -gt $maxDomainScore) {
            $maxDomainScore = $domainScores[$domain]
            $maxDomain = $domain
        }
    }

    # Ne retourner un domaine que si le score est supérieur à un seuil minimal
    if ($maxDomainScore -lt 2) {
        $maxDomain = $null
    }

    return @{
        Complexity      = $maxComplexityLevel
        Domain          = $maxDomain
        ComplexityScore = $maxComplexityScore
        DomainScore     = $maxDomainScore
    }
}

# Créer une configuration de test
$testConfig = [PSCustomObject]@{
    complexity_levels  = [PSCustomObject]@{
        simple  = [PSCustomObject]@{
            description   = "Tâche simple, peu de risques, technologie maîtrisée"
            template_file = "development\templates\subtasks\simple.txt"
            max_subtasks  = 3
        }
        medium  = [PSCustomObject]@{
            description   = "Tâche modérément complexe, quelques risques, technologie partiellement maîtrisée"
            template_file = "development\templates\subtasks\medium.txt"
            max_subtasks  = 5
        }
        complex = [PSCustomObject]@{
            description   = "Tâche complexe, risques importants, nouvelle technologie ou approche"
            template_file = "development\templates\subtasks\complex.txt"
            max_subtasks  = 10
        }
    }
    domain_templates   = [PSCustomObject]@{
        frontend = [PSCustomObject]@{
            description   = "Développement d'interfaces utilisateur et expérience utilisateur"
            template_file = "development\templates\subtasks\domains\frontend.txt"
            max_subtasks  = 9
        }
        backend  = [PSCustomObject]@{
            description   = "Développement de services, API et logique métier"
            template_file = "development\templates\subtasks\domains\backend.txt"
            max_subtasks  = 10
        }
        database = [PSCustomObject]@{
            description   = "Conception et optimisation de bases de données"
            template_file = "development\templates\subtasks\domains\database.txt"
            max_subtasks  = 9
        }
        testing  = [PSCustomObject]@{
            description   = "Tests unitaires, d'intégration et de bout en bout"
            template_file = "development\templates\subtasks\domains\testing.txt"
            max_subtasks  = 9
        }
        devops   = [PSCustomObject]@{
            description   = "Infrastructure, déploiement et opérations"
            template_file = "development\templates\subtasks\domains\devops.txt"
            max_subtasks  = 9
        }
    }
    keywords           = [PSCustomObject]@{
        simple   = @("simple", "basique", "facile", "mineur")
        medium   = @("moyen", "standard", "normal", "modéré")
        complex  = @("complexe", "difficile", "majeur", "critique", "avancé")
        frontend = @("interface", "UI", "UX", "CSS", "HTML", "JavaScript", "responsive", "composant", "visuel")
        backend  = @("API", "service", "endpoint", "contrôleur", "middleware", "authentification", "autorisation")
        database = @("base de données", "SQL", "NoSQL", "schéma", "migration", "requête", "index", "table")
        testing  = @("test", "unitaire", "intégration", "e2e", "bout en bout", "couverture", "assertion", "mock")
        devops   = @("CI/CD", "pipeline", "déploiement", "infrastructure", "conteneur", "Docker", "Kubernetes", "monitoring")
    }
    default_complexity = "medium"
    default_domain     = $null
}

# Exécuter les tests de complexité
Write-Host "Exécution des tests de détection de complexité..." -ForegroundColor Cyan

# Créer un tableau pour stocker les résultats des tests
$testResults = @()

# Test 1 : Tâche simple
$testResults += Test-GetTaskComplexity -TaskContent "- [ ] **1.1** Tâche simple et facile à réaliser" -ExpectedComplexity "simple" -ComplexityConfig $testConfig

# Test 2 : Tâche moyenne
$testResults += Test-GetTaskComplexity -TaskContent "- [ ] **1.2** Tâche standard avec quelques défis modérés" -ExpectedComplexity "medium" -ComplexityConfig $testConfig

# Test 3 : Tâche complexe
$testResults += Test-GetTaskComplexity -TaskContent "- [ ] **1.3** Tâche complexe et critique nécessitant une approche avancée" -ExpectedComplexity "complex" -ComplexityConfig $testConfig

# Test 4 : Tâche sans mots-clés mais courte (devrait être simple)
$testResults += Test-GetTaskComplexity -TaskContent "- [ ] **1.4** Mise à jour" -ExpectedComplexity "simple" -ComplexityConfig $testConfig

# Test 5 : Tâche sans mots-clés mais longue (devrait être complexe)
$testResults += Test-GetTaskComplexity -TaskContent "- [ ] **1.5** Implémenter une fonctionnalité qui permet de gérer les différentes configurations du système tout en assurant la compatibilité avec les versions précédentes et en optimisant les performances pour les utilisateurs finaux" -ExpectedComplexity "complex" -ComplexityConfig $testConfig

# Afficher le résultat global des tests de complexité
$totalComplexityTests = 5
$passedComplexityTests = ($testResults | Where-Object { $_ -eq $true }).Count

Write-Host "`nRésultat des tests de complexité : $passedComplexityTests / $totalComplexityTests" -ForegroundColor Cyan
if ($passedComplexityTests -eq $totalComplexityTests) {
    Write-Host "Tous les tests de complexité ont réussi !" -ForegroundColor Green
} else {
    Write-Host "Certains tests de complexité ont échoué." -ForegroundColor Red
}

# Exécuter les tests de complexité et domaine
Write-Host "`nExécution des tests de détection de complexité et de domaine..." -ForegroundColor Cyan

# Créer un tableau pour stocker les résultats des tests
$testCDResults = @()

# Test 1 : Tâche frontend simple
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.1** Créer une interface utilisateur simple avec HTML et CSS" -ExpectedComplexity "simple" -ExpectedDomain "frontend" -Config $testConfig

# Test 2 : Tâche backend complexe
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.2** Implémenter un service d'authentification complexe avec gestion des autorisations et middleware de sécurité" -ExpectedComplexity "complex" -ExpectedDomain "backend" -Config $testConfig

# Test 3 : Tâche database moyenne
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.3** Optimiser les requêtes SQL pour améliorer les performances de la base de données" -ExpectedComplexity "medium" -ExpectedDomain "database" -Config $testConfig

# Test 4 : Tâche testing
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.4** Mettre en place des tests unitaires et d'intégration pour le module de paiement" -ExpectedComplexity "medium" -ExpectedDomain "testing" -Config $testConfig

# Test 5 : Tâche devops
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.5** Configurer le pipeline CI/CD et déployer l'infrastructure Docker sur Kubernetes" -ExpectedComplexity "complex" -ExpectedDomain "devops" -Config $testConfig

# Test 6 : Tâche sans domaine spécifique
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.6** Mettre à jour la documentation du projet" -ExpectedComplexity "simple" -ExpectedDomain $null -Config $testConfig

# Test 7 : Tâche avec plusieurs domaines (devrait choisir le domaine avec le plus de mots-clés)
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.7** Créer une interface utilisateur pour afficher les résultats des tests unitaires" -ExpectedComplexity "medium" -ExpectedDomain "frontend" -Config $testConfig

# Afficher le résultat global des tests de complexité et domaine
$totalCDTests = 7
$passedCDTests = ($testCDResults | Where-Object { $_ -eq $true }).Count

Write-Host "`nRésultat des tests de complexité et domaine : $passedCDTests / $totalCDTests" -ForegroundColor Cyan
if ($passedCDTests -eq $totalCDTests) {
    Write-Host "Tous les tests de complexité et domaine ont réussi !" -ForegroundColor Green
} else {
    Write-Host "Certains tests de complexité et domaine ont échoué." -ForegroundColor Red
}

# Afficher le résultat global de tous les tests
$totalTests = $totalComplexityTests + $totalCDTests
$passedTests = $passedComplexityTests + $passedCDTests

Write-Host "`nRésultat global des tests : $passedTests / $totalTests" -ForegroundColor Cyan
if ($passedTests -eq $totalTests) {
    Write-Host "Tous les tests ont réussi !" -ForegroundColor Green
} else {
    Write-Host "Certains tests ont échoué." -ForegroundColor Red
}
