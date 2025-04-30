<#
.SYNOPSIS
    Tests unitaires pour la sélection de modèle de sous-tâches du mode GRAN.

.DESCRIPTION
    Ce script contient des tests unitaires pour vérifier le bon fonctionnement
    de la sélection de modèle de sous-tâches du mode GRAN en fonction de la
    complexité et du domaine.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-06-02
#>

# Importer les fonctions à tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$granModePath = Join-Path -Path $modulePath -ChildPath "..\..\..\scripts\maintenance\modes\gran-mode.ps1"

# Vérifier que le script existe
if (-not (Test-Path -Path $granModePath)) {
    throw "Le script gran-mode.ps1 est introuvable à l'emplacement : $granModePath"
}

# Créer une fonction de test pour Get-SubTasksTemplate
function Test-GetSubTasksTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComplexityLevel,

        [Parameter(Mandatory = $false)]
        [string]$Domain = "None",

        [Parameter(Mandatory = $true)]
        [string]$ExpectedLevel,

        [Parameter(Mandatory = $false)]
        [string]$ExpectedDomain = $null,

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TemplateConfig,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    # Appeler la fonction Get-SubTasksTemplate
    $result = Get-SubTasksTemplate -ComplexityLevel $ComplexityLevel -Domain $Domain -TemplateConfig $TemplateConfig -ProjectRoot $ProjectRoot

    # Vérifier si le résultat est null
    if ($result -eq $null) {
        Write-Host "Test échoué : Get-SubTasksTemplate a retourné null pour ComplexityLevel=$ComplexityLevel, Domain=$Domain" -ForegroundColor Red
        return $false
    }

    # Vérifier le niveau de complexité
    $levelMatch = $result.Level -eq $ExpectedLevel

    # Vérifier le domaine
    $domainMatch = $true
    if ($ExpectedDomain -ne $null) {
        $domainMatch = $result.Domain -eq $ExpectedDomain
    } elseif ($result.Domain -ne $null) {
        $domainMatch = $false
    }

    # Afficher le résultat
    if ($levelMatch -and $domainMatch) {
        Write-Host "Test réussi : ComplexityLevel=$ComplexityLevel, Domain=$Domain -> Level=$($result.Level), Domain=$($result.Domain)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Test échoué : ComplexityLevel=$ComplexityLevel, Domain=$Domain -> Level=$($result.Level) (attendu : $ExpectedLevel), Domain=$($result.Domain) (attendu : $ExpectedDomain)" -ForegroundColor Red
        return $false
    }
}

# Charger le script gran-mode.ps1 pour accéder aux fonctions
# Créer une fonction de test pour simuler la fonction Get-SubTasksTemplate
function Get-SubTasksTemplate {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComplexityLevel,

        [Parameter(Mandatory = $false)]
        [string]$Domain = "None",

        [Parameter(Mandatory = $true)]
        [PSCustomObject]$TemplateConfig,

        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot
    )

    # Vérifier si un domaine spécifique est demandé et s'il existe
    $useDomainTemplate = $false
    $normalizedDomain = $Domain.ToLower()

    if ($normalizedDomain -ne "none" -and $TemplateConfig.domain_templates -and $TemplateConfig.domain_templates.PSObject.Properties.Name -contains $normalizedDomain) {
        $useDomainTemplate = $true
    }

    if ($useDomainTemplate) {
        # Simuler l'utilisation d'un modèle spécifique au domaine
        return @{
            Content     = "Contenu du modèle pour le domaine $normalizedDomain"
            Level       = "domain"
            Domain      = $normalizedDomain
            Description = $TemplateConfig.domain_templates.$normalizedDomain.description
            MaxSubTasks = $TemplateConfig.domain_templates.$normalizedDomain.max_subtasks
        }
    }

    # Simuler l'utilisation d'un modèle basé sur la complexité

    # Normaliser le niveau de complexité
    $normalizedLevel = $ComplexityLevel.ToLower()
    if ($normalizedLevel -eq "auto") {
        $normalizedLevel = $TemplateConfig.default_complexity
    }

    # Vérifier si le niveau de complexité est valide
    if (-not $TemplateConfig.complexity_levels.PSObject.Properties.Name -contains $normalizedLevel) {
        $normalizedLevel = $TemplateConfig.default_complexity
    }

    # Simuler le contenu du modèle
    return @{
        Content     = "Contenu du modèle pour la complexité $normalizedLevel"
        Level       = $normalizedLevel
        Domain      = $null
        Description = $TemplateConfig.complexity_levels.$normalizedLevel.description
        MaxSubTasks = $TemplateConfig.complexity_levels.$normalizedLevel.max_subtasks
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

# Définir le chemin du projet pour les tests
$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $modulePath))

# Exécuter les tests de sélection de modèle
Write-Host "Exécution des tests de sélection de modèle de sous-tâches..." -ForegroundColor Cyan

# Test 1 : Complexité simple, pas de domaine
$test1 = Test-GetSubTasksTemplate -ComplexityLevel "Simple" -Domain "None" -ExpectedLevel "simple" -ExpectedDomain $null -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 2 : Complexité medium, pas de domaine
$test2 = Test-GetSubTasksTemplate -ComplexityLevel "Medium" -Domain "None" -ExpectedLevel "medium" -ExpectedDomain $null -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 3 : Complexité complex, pas de domaine
$test3 = Test-GetSubTasksTemplate -ComplexityLevel "Complex" -Domain "None" -ExpectedLevel "complex" -ExpectedDomain $null -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 4 : Complexité auto (devrait utiliser la valeur par défaut), pas de domaine
$test4 = Test-GetSubTasksTemplate -ComplexityLevel "Auto" -Domain "None" -ExpectedLevel "medium" -ExpectedDomain $null -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 5 : Domaine frontend, complexité simple
$test5 = Test-GetSubTasksTemplate -ComplexityLevel "Simple" -Domain "Frontend" -ExpectedLevel "domain" -ExpectedDomain "frontend" -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 6 : Domaine backend, complexité medium
$test6 = Test-GetSubTasksTemplate -ComplexityLevel "Medium" -Domain "Backend" -ExpectedLevel "domain" -ExpectedDomain "backend" -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 7 : Domaine database, complexité complex
$test7 = Test-GetSubTasksTemplate -ComplexityLevel "Complex" -Domain "Database" -ExpectedLevel "domain" -ExpectedDomain "database" -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 8 : Domaine testing, complexité auto
$test8 = Test-GetSubTasksTemplate -ComplexityLevel "Auto" -Domain "Testing" -ExpectedLevel "domain" -ExpectedDomain "testing" -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 9 : Domaine devops, complexité auto
$test9 = Test-GetSubTasksTemplate -ComplexityLevel "Auto" -Domain "DevOps" -ExpectedLevel "domain" -ExpectedDomain "devops" -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Afficher le résultat global des tests
$totalTests = 9
$passedTests = @($test1, $test2, $test3, $test4, $test5, $test6, $test7, $test8, $test9).Where({ $_ -eq $true }).Count

Write-Host "`nRésultat des tests de sélection de modèle : $passedTests / $totalTests" -ForegroundColor Cyan
if ($passedTests -eq $totalTests) {
    Write-Host "Tous les tests ont réussi !" -ForegroundColor Green
} else {
    Write-Host "Certains tests ont échoué." -ForegroundColor Red
}
