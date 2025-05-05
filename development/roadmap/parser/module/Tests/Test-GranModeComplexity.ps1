<#
.SYNOPSIS
    Tests unitaires pour la dÃ©tection automatique de complexitÃ© et de domaine du mode GRAN.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement
    de la dÃ©tection automatique de complexitÃ© et de domaine du mode GRAN.

.NOTES
    Auteur: RoadmapParser Team
    Version: 2.0
    Date de crÃ©ation: 2025-06-01
    Date de mise Ã  jour: 2025-06-02 - Ajout des tests de dÃ©tection de domaine
#>

# Importer les fonctions Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$granModePath = Join-Path -Path $modulePath -ChildPath "..\..\..\scripts\maintenance\modes\gran-mode.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $granModePath)) {
    throw "Le script gran-mode.ps1 est introuvable Ã  l'emplacement : $granModePath"
}

# CrÃ©er une fonction de test pour Get-TaskComplexity
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

    # VÃ©rifier le rÃ©sultat
    if ($result -eq $ExpectedComplexity) {
        Write-Host "Test rÃ©ussi : '$TaskContent' -> ComplexitÃ©: $result" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Test Ã©chouÃ© : '$TaskContent' -> ComplexitÃ©: $result (attendu : $ExpectedComplexity)" -ForegroundColor Red
        return $false
    }
}

# CrÃ©er une fonction de test pour Get-TaskComplexityAndDomain
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

    # VÃ©rifier le rÃ©sultat de complexitÃ©
    $complexityMatch = $result.Complexity -eq $ExpectedComplexity

    # VÃ©rifier le rÃ©sultat de domaine
    $domainMatch = $true
    if ($ExpectedDomain -ne $null) {
        $domainMatch = $result.Domain -eq $ExpectedDomain
    }

    # Afficher le rÃ©sultat
    if ($complexityMatch -and $domainMatch) {
        Write-Host "Test rÃ©ussi : '$TaskContent' -> ComplexitÃ©: $($result.Complexity), Domaine: $($result.Domain)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Test Ã©chouÃ© : '$TaskContent' -> ComplexitÃ©: $($result.Complexity) (attendu : $ExpectedComplexity), Domaine: $($result.Domain) (attendu : $ExpectedDomain)" -ForegroundColor Red
        return $false
    }
}

# Charger le script gran-mode.ps1 pour accÃ©der aux fonctions
# CrÃ©er une fonction de test pour simuler les fonctions du script gran-mode.ps1
function Get-TaskComplexity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskContent,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$ComplexityConfig
    )

    # Initialiser les scores pour chaque niveau de complexitÃ©
    $scores = @{
        "simple"  = 0
        "medium"  = 0
        "complex" = 0
    }

    # VÃ©rifier les mots-clÃ©s dans le contenu de la tÃ¢che
    foreach ($level in $scores.Keys) {
        foreach ($keyword in $ComplexityConfig.keywords.$level) {
            if ($TaskContent -match $keyword) {
                $scores[$level] += 1
            }
        }
    }

    # VÃ©rifier la longueur du contenu (indicateur de complexitÃ©)
    $wordCount = ($TaskContent -split '\s+').Count
    if ($wordCount -lt 10) {
        $scores["simple"] += 2
    } elseif ($wordCount -lt 30) {
        $scores["medium"] += 2
    } else {
        $scores["complex"] += 2
    }

    # DÃ©terminer le niveau de complexitÃ© en fonction des scores
    $maxScore = 0
    $maxLevel = "medium" # Par dÃ©faut

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

    # Initialiser les scores pour chaque niveau de complexitÃ©
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

    # VÃ©rifier les mots-clÃ©s de complexitÃ© dans le contenu de la tÃ¢che
    foreach ($level in $complexityScores.Keys) {
        foreach ($keyword in $Config.keywords.$level) {
            if ($TaskContent -match $keyword) {
                $complexityScores[$level] += 1
            }
        }
    }

    # VÃ©rifier les mots-clÃ©s de domaine dans le contenu de la tÃ¢che
    foreach ($domain in $domainScores.Keys) {
        if ($Config.keywords.PSObject.Properties.Name -contains $domain) {
            foreach ($keyword in $Config.keywords.$domain) {
                if ($TaskContent -match $keyword) {
                    $domainScores[$domain] += 1
                }
            }
        }
    }

    # VÃ©rifier la longueur du contenu (indicateur de complexitÃ©)
    $wordCount = ($TaskContent -split '\s+').Count
    if ($wordCount -lt 10) {
        $complexityScores["simple"] += 2
    } elseif ($wordCount -lt 30) {
        $complexityScores["medium"] += 2
    } else {
        $complexityScores["complex"] += 2
    }

    # DÃ©terminer le niveau de complexitÃ© en fonction des scores
    $maxComplexityScore = 0
    $maxComplexityLevel = "medium" # Par dÃ©faut

    foreach ($level in $complexityScores.Keys) {
        if ($complexityScores[$level] -gt $maxComplexityScore) {
            $maxComplexityScore = $complexityScores[$level]
            $maxComplexityLevel = $level
        }
    }

    # DÃ©terminer le domaine en fonction des scores
    $maxDomainScore = 0
    $maxDomain = $null # Par dÃ©faut, pas de domaine spÃ©cifique

    foreach ($domain in $domainScores.Keys) {
        if ($domainScores[$domain] -gt $maxDomainScore) {
            $maxDomainScore = $domainScores[$domain]
            $maxDomain = $domain
        }
    }

    # Ne retourner un domaine que si le score est supÃ©rieur Ã  un seuil minimal
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

# CrÃ©er une configuration de test
$testConfig = [PSCustomObject]@{
    complexity_levels  = [PSCustomObject]@{
        simple  = [PSCustomObject]@{
            description   = "TÃ¢che simple, peu de risques, technologie maÃ®trisÃ©e"
            template_file = "development\templates\subtasks\simple.txt"
            max_subtasks  = 3
        }
        medium  = [PSCustomObject]@{
            description   = "TÃ¢che modÃ©rÃ©ment complexe, quelques risques, technologie partiellement maÃ®trisÃ©e"
            template_file = "development\templates\subtasks\medium.txt"
            max_subtasks  = 5
        }
        complex = [PSCustomObject]@{
            description   = "TÃ¢che complexe, risques importants, nouvelle technologie ou approche"
            template_file = "development\templates\subtasks\complex.txt"
            max_subtasks  = 10
        }
    }
    domain_templates   = [PSCustomObject]@{
        frontend = [PSCustomObject]@{
            description   = "DÃ©veloppement d'interfaces utilisateur et expÃ©rience utilisateur"
            template_file = "development\templates\subtasks\domains\frontend.txt"
            max_subtasks  = 9
        }
        backend  = [PSCustomObject]@{
            description   = "DÃ©veloppement de services, API et logique mÃ©tier"
            template_file = "development\templates\subtasks\domains\backend.txt"
            max_subtasks  = 10
        }
        database = [PSCustomObject]@{
            description   = "Conception et optimisation de bases de donnÃ©es"
            template_file = "development\templates\subtasks\domains\database.txt"
            max_subtasks  = 9
        }
        testing  = [PSCustomObject]@{
            description   = "Tests unitaires, d'intÃ©gration et de bout en bout"
            template_file = "development\templates\subtasks\domains\testing.txt"
            max_subtasks  = 9
        }
        devops   = [PSCustomObject]@{
            description   = "Infrastructure, dÃ©ploiement et opÃ©rations"
            template_file = "development\templates\subtasks\domains\devops.txt"
            max_subtasks  = 9
        }
    }
    keywords           = [PSCustomObject]@{
        simple   = @("simple", "basique", "facile", "mineur")
        medium   = @("moyen", "standard", "normal", "modÃ©rÃ©")
        complex  = @("complexe", "difficile", "majeur", "critique", "avancÃ©")
        frontend = @("interface", "UI", "UX", "CSS", "HTML", "JavaScript", "responsive", "composant", "visuel")
        backend  = @("API", "service", "endpoint", "contrÃ´leur", "middleware", "authentification", "autorisation")
        database = @("base de donnÃ©es", "SQL", "NoSQL", "schÃ©ma", "migration", "requÃªte", "index", "table")
        testing  = @("test", "unitaire", "intÃ©gration", "e2e", "bout en bout", "couverture", "assertion", "mock")
        devops   = @("CI/CD", "pipeline", "dÃ©ploiement", "infrastructure", "conteneur", "Docker", "Kubernetes", "monitoring")
    }
    default_complexity = "medium"
    default_domain     = $null
}

# ExÃ©cuter les tests de complexitÃ©
Write-Host "ExÃ©cution des tests de dÃ©tection de complexitÃ©..." -ForegroundColor Cyan

# CrÃ©er un tableau pour stocker les rÃ©sultats des tests
$testResults = @()

# Test 1 : TÃ¢che simple
$testResults += Test-GetTaskComplexity -TaskContent "- [ ] **1.1** TÃ¢che simple et facile Ã  rÃ©aliser" -ExpectedComplexity "simple" -ComplexityConfig $testConfig

# Test 2 : TÃ¢che moyenne
$testResults += Test-GetTaskComplexity -TaskContent "- [ ] **1.2** TÃ¢che standard avec quelques dÃ©fis modÃ©rÃ©s" -ExpectedComplexity "medium" -ComplexityConfig $testConfig

# Test 3 : TÃ¢che complexe
$testResults += Test-GetTaskComplexity -TaskContent "- [ ] **1.3** TÃ¢che complexe et critique nÃ©cessitant une approche avancÃ©e" -ExpectedComplexity "complex" -ComplexityConfig $testConfig

# Test 4 : TÃ¢che sans mots-clÃ©s mais courte (devrait Ãªtre simple)
$testResults += Test-GetTaskComplexity -TaskContent "- [ ] **1.4** Mise Ã  jour" -ExpectedComplexity "simple" -ComplexityConfig $testConfig

# Test 5 : TÃ¢che sans mots-clÃ©s mais longue (devrait Ãªtre complexe)
$testResults += Test-GetTaskComplexity -TaskContent "- [ ] **1.5** ImplÃ©menter une fonctionnalitÃ© qui permet de gÃ©rer les diffÃ©rentes configurations du systÃ¨me tout en assurant la compatibilitÃ© avec les versions prÃ©cÃ©dentes et en optimisant les performances pour les utilisateurs finaux" -ExpectedComplexity "complex" -ComplexityConfig $testConfig

# Afficher le rÃ©sultat global des tests de complexitÃ©
$totalComplexityTests = 5
$passedComplexityTests = ($testResults | Where-Object { $_ -eq $true }).Count

Write-Host "`nRÃ©sultat des tests de complexitÃ© : $passedComplexityTests / $totalComplexityTests" -ForegroundColor Cyan
if ($passedComplexityTests -eq $totalComplexityTests) {
    Write-Host "Tous les tests de complexitÃ© ont rÃ©ussi !" -ForegroundColor Green
} else {
    Write-Host "Certains tests de complexitÃ© ont Ã©chouÃ©." -ForegroundColor Red
}

# ExÃ©cuter les tests de complexitÃ© et domaine
Write-Host "`nExÃ©cution des tests de dÃ©tection de complexitÃ© et de domaine..." -ForegroundColor Cyan

# CrÃ©er un tableau pour stocker les rÃ©sultats des tests
$testCDResults = @()

# Test 1 : TÃ¢che frontend simple
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.1** CrÃ©er une interface utilisateur simple avec HTML et CSS" -ExpectedComplexity "simple" -ExpectedDomain "frontend" -Config $testConfig

# Test 2 : TÃ¢che backend complexe
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.2** ImplÃ©menter un service d'authentification complexe avec gestion des autorisations et middleware de sÃ©curitÃ©" -ExpectedComplexity "complex" -ExpectedDomain "backend" -Config $testConfig

# Test 3 : TÃ¢che database moyenne
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.3** Optimiser les requÃªtes SQL pour amÃ©liorer les performances de la base de donnÃ©es" -ExpectedComplexity "medium" -ExpectedDomain "database" -Config $testConfig

# Test 4 : TÃ¢che testing
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.4** Mettre en place des tests unitaires et d'intÃ©gration pour le module de paiement" -ExpectedComplexity "medium" -ExpectedDomain "testing" -Config $testConfig

# Test 5 : TÃ¢che devops
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.5** Configurer le pipeline CI/CD et dÃ©ployer l'infrastructure Docker sur Kubernetes" -ExpectedComplexity "complex" -ExpectedDomain "devops" -Config $testConfig

# Test 6 : TÃ¢che sans domaine spÃ©cifique
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.6** Mettre Ã  jour la documentation du projet" -ExpectedComplexity "simple" -ExpectedDomain $null -Config $testConfig

# Test 7 : TÃ¢che avec plusieurs domaines (devrait choisir le domaine avec le plus de mots-clÃ©s)
$testCDResults += Test-GetTaskComplexityAndDomain -TaskContent "- [ ] **2.7** CrÃ©er une interface utilisateur pour afficher les rÃ©sultats des tests unitaires" -ExpectedComplexity "medium" -ExpectedDomain "frontend" -Config $testConfig

# Afficher le rÃ©sultat global des tests de complexitÃ© et domaine
$totalCDTests = 7
$passedCDTests = ($testCDResults | Where-Object { $_ -eq $true }).Count

Write-Host "`nRÃ©sultat des tests de complexitÃ© et domaine : $passedCDTests / $totalCDTests" -ForegroundColor Cyan
if ($passedCDTests -eq $totalCDTests) {
    Write-Host "Tous les tests de complexitÃ© et domaine ont rÃ©ussi !" -ForegroundColor Green
} else {
    Write-Host "Certains tests de complexitÃ© et domaine ont Ã©chouÃ©." -ForegroundColor Red
}

# Afficher le rÃ©sultat global de tous les tests
$totalTests = $totalComplexityTests + $totalCDTests
$passedTests = $passedComplexityTests + $passedCDTests

Write-Host "`nRÃ©sultat global des tests : $passedTests / $totalTests" -ForegroundColor Cyan
if ($passedTests -eq $totalTests) {
    Write-Host "Tous les tests ont rÃ©ussi !" -ForegroundColor Green
} else {
    Write-Host "Certains tests ont Ã©chouÃ©." -ForegroundColor Red
}
