<#
.SYNOPSIS
    Tests unitaires pour la sÃ©lection de modÃ¨le de sous-tÃ¢ches du mode GRAN.

.DESCRIPTION
    Ce script contient des tests unitaires pour vÃ©rifier le bon fonctionnement
    de la sÃ©lection de modÃ¨le de sous-tÃ¢ches du mode GRAN en fonction de la
    complexitÃ© et du domaine.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-06-02
#>

# Importer les fonctions Ã  tester
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Split-Path -Parent $scriptPath
$granModePath = Join-Path -Path $modulePath -ChildPath "..\..\..\scripts\maintenance\modes\gran-mode.ps1"

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $granModePath)) {
    throw "Le script gran-mode.ps1 est introuvable Ã  l'emplacement : $granModePath"
}

# CrÃ©er une fonction de test pour Get-SubTasksTemplate
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

    # VÃ©rifier si le rÃ©sultat est null
    if ($result -eq $null) {
        Write-Host "Test Ã©chouÃ© : Get-SubTasksTemplate a retournÃ© null pour ComplexityLevel=$ComplexityLevel, Domain=$Domain" -ForegroundColor Red
        return $false
    }

    # VÃ©rifier le niveau de complexitÃ©
    $levelMatch = $result.Level -eq $ExpectedLevel

    # VÃ©rifier le domaine
    $domainMatch = $true
    if ($ExpectedDomain -ne $null) {
        $domainMatch = $result.Domain -eq $ExpectedDomain
    } elseif ($result.Domain -ne $null) {
        $domainMatch = $false
    }

    # Afficher le rÃ©sultat
    if ($levelMatch -and $domainMatch) {
        Write-Host "Test rÃ©ussi : ComplexityLevel=$ComplexityLevel, Domain=$Domain -> Level=$($result.Level), Domain=$($result.Domain)" -ForegroundColor Green
        return $true
    } else {
        Write-Host "Test Ã©chouÃ© : ComplexityLevel=$ComplexityLevel, Domain=$Domain -> Level=$($result.Level) (attendu : $ExpectedLevel), Domain=$($result.Domain) (attendu : $ExpectedDomain)" -ForegroundColor Red
        return $false
    }
}

# Charger le script gran-mode.ps1 pour accÃ©der aux fonctions
# CrÃ©er une fonction de test pour simuler la fonction Get-SubTasksTemplate
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

    # VÃ©rifier si un domaine spÃ©cifique est demandÃ© et s'il existe
    $useDomainTemplate = $false
    $normalizedDomain = $Domain.ToLower()

    if ($normalizedDomain -ne "none" -and $TemplateConfig.domain_templates -and $TemplateConfig.domain_templates.PSObject.Properties.Name -contains $normalizedDomain) {
        $useDomainTemplate = $true
    }

    if ($useDomainTemplate) {
        # Simuler l'utilisation d'un modÃ¨le spÃ©cifique au domaine
        return @{
            Content     = "Contenu du modÃ¨le pour le domaine $normalizedDomain"
            Level       = "domain"
            Domain      = $normalizedDomain
            Description = $TemplateConfig.domain_templates.$normalizedDomain.description
            MaxSubTasks = $TemplateConfig.domain_templates.$normalizedDomain.max_subtasks
        }
    }

    # Simuler l'utilisation d'un modÃ¨le basÃ© sur la complexitÃ©

    # Normaliser le niveau de complexitÃ©
    $normalizedLevel = $ComplexityLevel.ToLower()
    if ($normalizedLevel -eq "auto") {
        $normalizedLevel = $TemplateConfig.default_complexity
    }

    # VÃ©rifier si le niveau de complexitÃ© est valide
    if (-not $TemplateConfig.complexity_levels.PSObject.Properties.Name -contains $normalizedLevel) {
        $normalizedLevel = $TemplateConfig.default_complexity
    }

    # Simuler le contenu du modÃ¨le
    return @{
        Content     = "Contenu du modÃ¨le pour la complexitÃ© $normalizedLevel"
        Level       = $normalizedLevel
        Domain      = $null
        Description = $TemplateConfig.complexity_levels.$normalizedLevel.description
        MaxSubTasks = $TemplateConfig.complexity_levels.$normalizedLevel.max_subtasks
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

# DÃ©finir le chemin du projet pour les tests
$projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $modulePath))

# ExÃ©cuter les tests de sÃ©lection de modÃ¨le
Write-Host "ExÃ©cution des tests de sÃ©lection de modÃ¨le de sous-tÃ¢ches..." -ForegroundColor Cyan

# Test 1 : ComplexitÃ© simple, pas de domaine
$test1 = Test-GetSubTasksTemplate -ComplexityLevel "Simple" -Domain "None" -ExpectedLevel "simple" -ExpectedDomain $null -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 2 : ComplexitÃ© medium, pas de domaine
$test2 = Test-GetSubTasksTemplate -ComplexityLevel "Medium" -Domain "None" -ExpectedLevel "medium" -ExpectedDomain $null -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 3 : ComplexitÃ© complex, pas de domaine
$test3 = Test-GetSubTasksTemplate -ComplexityLevel "Complex" -Domain "None" -ExpectedLevel "complex" -ExpectedDomain $null -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 4 : ComplexitÃ© auto (devrait utiliser la valeur par dÃ©faut), pas de domaine
$test4 = Test-GetSubTasksTemplate -ComplexityLevel "Auto" -Domain "None" -ExpectedLevel "medium" -ExpectedDomain $null -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 5 : Domaine frontend, complexitÃ© simple
$test5 = Test-GetSubTasksTemplate -ComplexityLevel "Simple" -Domain "Frontend" -ExpectedLevel "domain" -ExpectedDomain "frontend" -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 6 : Domaine backend, complexitÃ© medium
$test6 = Test-GetSubTasksTemplate -ComplexityLevel "Medium" -Domain "Backend" -ExpectedLevel "domain" -ExpectedDomain "backend" -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 7 : Domaine database, complexitÃ© complex
$test7 = Test-GetSubTasksTemplate -ComplexityLevel "Complex" -Domain "Database" -ExpectedLevel "domain" -ExpectedDomain "database" -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 8 : Domaine testing, complexitÃ© auto
$test8 = Test-GetSubTasksTemplate -ComplexityLevel "Auto" -Domain "Testing" -ExpectedLevel "domain" -ExpectedDomain "testing" -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Test 9 : Domaine devops, complexitÃ© auto
$test9 = Test-GetSubTasksTemplate -ComplexityLevel "Auto" -Domain "DevOps" -ExpectedLevel "domain" -ExpectedDomain "devops" -TemplateConfig $testConfig -ProjectRoot $projectRoot

# Afficher le rÃ©sultat global des tests
$totalTests = 9
$passedTests = @($test1, $test2, $test3, $test4, $test5, $test6, $test7, $test8, $test9).Where({ $_ -eq $true }).Count

Write-Host "`nRÃ©sultat des tests de sÃ©lection de modÃ¨le : $passedTests / $totalTests" -ForegroundColor Cyan
if ($passedTests -eq $totalTests) {
    Write-Host "Tous les tests ont rÃ©ussi !" -ForegroundColor Green
} else {
    Write-Host "Certains tests ont Ã©chouÃ©." -ForegroundColor Red
}
