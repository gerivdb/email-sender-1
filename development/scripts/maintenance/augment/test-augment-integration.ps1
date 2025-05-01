<#
.SYNOPSIS
    Teste l'intégration avec Augment Code.

.DESCRIPTION
    Ce script teste l'intégration avec Augment Code en vérifiant que tous les
    composants fonctionnent correctement.

.PARAMETER Verbose
    Affiche des informations détaillées sur les tests.

.EXAMPLE
    .\test-augment-integration.ps1
    # Teste l'intégration avec Augment Code

.EXAMPLE
    .\test-augment-integration.ps1 -Verbose
    # Teste l'intégration avec Augment Code avec des informations détaillées

.NOTES
    Version: 1.0
    Date: 2025-06-01
    Auteur: Augment Agent
#>

[CmdletBinding()]
param ()

# Déterminer le chemin du projet
$projectRoot = $PSScriptRoot
while (-not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container) -and
    -not [string]::IsNullOrEmpty($projectRoot)) {
    $projectRoot = Split-Path -Path $projectRoot -Parent
}

if ([string]::IsNullOrEmpty($projectRoot) -or -not (Test-Path -Path (Join-Path -Path $projectRoot -ChildPath ".git") -PathType Container)) {
    $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
    if (-not (Test-Path -Path $projectRoot -PathType Container)) {
        Write-Error "Impossible de déterminer le chemin du projet."
        exit 1
    }
}

# Fonction pour exécuter un test
function Test-Component {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Test
    )
    
    Write-Host "Test de $Name... " -ForegroundColor Cyan -NoNewline
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "OK" -ForegroundColor Green
            return $true
        } else {
            Write-Host "ÉCHEC" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "ERREUR" -ForegroundColor Red
        Write-Verbose "Erreur : $_"
        return $false
    }
}

# Fonction pour tester le module AugmentIntegration
function Test-AugmentIntegrationModule {
    [CmdletBinding()]
    param ()
    
    $modulePath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\AugmentIntegration.psm1"
    if (-not (Test-Path -Path $modulePath)) {
        Write-Verbose "Module AugmentIntegration introuvable : $modulePath"
        return $false
    }
    
    try {
        Import-Module $modulePath -Force -ErrorAction Stop
        $module = Get-Module AugmentIntegration
        if (-not $module) {
            Write-Verbose "Impossible de charger le module AugmentIntegration"
            return $false
        }
        
        $requiredFunctions = @(
            "Invoke-AugmentMode",
            "Start-AugmentMCPServers",
            "Stop-AugmentMCPServers",
            "Update-AugmentMemoriesForMode",
            "Split-AugmentInput",
            "Measure-AugmentInputSize",
            "Get-AugmentModeDescription",
            "Initialize-AugmentIntegration",
            "Analyze-AugmentPerformance"
        )
        
        $missingFunctions = $requiredFunctions | Where-Object { -not (Get-Command -Module AugmentIntegration -Name $_ -ErrorAction SilentlyContinue) }
        if ($missingFunctions) {
            Write-Verbose "Fonctions manquantes : $($missingFunctions -join ', ')"
            return $false
        }
        
        return $true
    } catch {
        Write-Verbose "Erreur lors du test du module AugmentIntegration : $_"
        return $false
    }
}

# Fonction pour tester le serveur MCP pour les Memories
function Test-MemoriesMCPServer {
    [CmdletBinding()]
    param ()
    
    $serverPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\mcp-memories-server.ps1"
    if (-not (Test-Path -Path $serverPath)) {
        Write-Verbose "Serveur MCP pour les Memories introuvable : $serverPath"
        return $false
    }
    
    return $true
}

# Fonction pour tester l'adaptateur MCP pour le gestionnaire de modes
function Test-ModeManagerMCPAdapter {
    [CmdletBinding()]
    param ()
    
    $adapterPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\mcp-mode-manager-adapter.ps1"
    if (-not (Test-Path -Path $adapterPath)) {
        Write-Verbose "Adaptateur MCP pour le gestionnaire de modes introuvable : $adapterPath"
        return $false
    }
    
    return $true
}

# Fonction pour tester le script d'intégration pour le gestionnaire de modes
function Test-ModeManagerIntegration {
    [CmdletBinding()]
    param ()
    
    $integrationPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\mode-manager-augment-integration.ps1"
    if (-not (Test-Path -Path $integrationPath)) {
        Write-Verbose "Script d'intégration pour le gestionnaire de modes introuvable : $integrationPath"
        return $false
    }
    
    return $true
}

# Fonction pour tester le script d'optimisation des Memories
function Test-MemoriesOptimization {
    [CmdletBinding()]
    param ()
    
    $optimizationPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\optimize-augment-memories.ps1"
    if (-not (Test-Path -Path $optimizationPath)) {
        Write-Verbose "Script d'optimisation des Memories introuvable : $optimizationPath"
        return $false
    }
    
    return $true
}

# Fonction pour tester le script de configuration pour l'intégration MCP
function Test-MCPConfiguration {
    [CmdletBinding()]
    param ()
    
    $configurationPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\configure-augment-mcp.ps1"
    if (-not (Test-Path -Path $configurationPath)) {
        Write-Verbose "Script de configuration pour l'intégration MCP introuvable : $configurationPath"
        return $false
    }
    
    return $true
}

# Fonction pour tester le script de démarrage pour les serveurs MCP
function Test-MCPServersStartup {
    [CmdletBinding()]
    param ()
    
    $startupPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\start-mcp-servers.ps1"
    if (-not (Test-Path -Path $startupPath)) {
        Write-Verbose "Script de démarrage pour les serveurs MCP introuvable : $startupPath"
        return $false
    }
    
    return $true
}

# Fonction pour tester le script d'analyse des performances
function Test-PerformanceAnalysis {
    [CmdletBinding()]
    param ()
    
    $analysisPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\analyze-augment-performance.ps1"
    if (-not (Test-Path -Path $analysisPath)) {
        Write-Verbose "Script d'analyse des performances introuvable : $analysisPath"
        return $false
    }
    
    return $true
}

# Fonction pour tester le script de synchronisation des Memories avec n8n
function Test-MemoriesSync {
    [CmdletBinding()]
    param ()
    
    $syncPath = Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\augment\sync-memories-with-n8n.ps1"
    if (-not (Test-Path -Path $syncPath)) {
        Write-Verbose "Script de synchronisation des Memories avec n8n introuvable : $syncPath"
        return $false
    }
    
    return $true
}

# Fonction pour tester la documentation
function Test-Documentation {
    [CmdletBinding()]
    param ()
    
    $docPaths = @(
        "docs\guides\augment\integration_guide.md",
        "docs\guides\augment\memories_optimization.md",
        "docs\guides\augment\limitations.md",
        "docs\guides\augment\advanced_usage.md"
    )
    
    $missingDocs = $docPaths | ForEach-Object {
        $path = Join-Path -Path $projectRoot -ChildPath $_
        if (-not (Test-Path -Path $path)) {
            $_
        }
    }
    
    if ($missingDocs) {
        Write-Verbose "Documentation manquante : $($missingDocs -join ', ')"
        return $false
    }
    
    return $true
}

# Exécuter les tests
$tests = @(
    @{ Name = "Module AugmentIntegration"; Test = { Test-AugmentIntegrationModule } },
    @{ Name = "Serveur MCP pour les Memories"; Test = { Test-MemoriesMCPServer } },
    @{ Name = "Adaptateur MCP pour le gestionnaire de modes"; Test = { Test-ModeManagerMCPAdapter } },
    @{ Name = "Script d'intégration pour le gestionnaire de modes"; Test = { Test-ModeManagerIntegration } },
    @{ Name = "Script d'optimisation des Memories"; Test = { Test-MemoriesOptimization } },
    @{ Name = "Script de configuration pour l'intégration MCP"; Test = { Test-MCPConfiguration } },
    @{ Name = "Script de démarrage pour les serveurs MCP"; Test = { Test-MCPServersStartup } },
    @{ Name = "Script d'analyse des performances"; Test = { Test-PerformanceAnalysis } },
    @{ Name = "Script de synchronisation des Memories avec n8n"; Test = { Test-MemoriesSync } },
    @{ Name = "Documentation"; Test = { Test-Documentation } }
)

$results = @()
foreach ($test in $tests) {
    $success = Test-Component -Name $test.Name -Test $test.Test
    $results += [PSCustomObject]@{
        Name = $test.Name
        Success = $success
    }
}

# Afficher un résumé
$successCount = ($results | Where-Object { $_.Success } | Measure-Object).Count
$totalCount = $results.Count
$successRate = [math]::Round(($successCount / $totalCount) * 100, 2)

Write-Host "`nRésumé des tests :" -ForegroundColor Cyan
Write-Host "Tests réussis : $successCount / $totalCount ($successRate%)" -ForegroundColor $(if ($successRate -eq 100) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })

# Afficher les tests échoués
$failedTests = $results | Where-Object { -not $_.Success }
if ($failedTests) {
    Write-Host "`nTests échoués :" -ForegroundColor Red
    foreach ($test in $failedTests) {
        Write-Host "- $($test.Name)" -ForegroundColor Red
    }
    
    Write-Host "`nConsultez la documentation pour résoudre les problèmes :" -ForegroundColor Yellow
    Write-Host "- docs\guides\augment\integration_guide.md" -ForegroundColor Yellow
}

# Afficher les prochaines étapes
Write-Host "`nProchaines étapes :" -ForegroundColor Cyan
if ($successRate -eq 100) {
    Write-Host "1. Exécutez `Initialize-AugmentIntegration -StartServers` pour démarrer les serveurs MCP" -ForegroundColor Green
    Write-Host "2. Utilisez le module AugmentIntegration pour interagir avec Augment Code" -ForegroundColor Green
    Write-Host "3. Consultez la documentation pour plus d'informations" -ForegroundColor Green
} else {
    Write-Host "1. Corrigez les tests échoués" -ForegroundColor Yellow
    Write-Host "2. Exécutez à nouveau ce script pour vérifier que tout fonctionne correctement" -ForegroundColor Yellow
    Write-Host "3. Consultez la documentation pour plus d'informations" -ForegroundColor Yellow
}
