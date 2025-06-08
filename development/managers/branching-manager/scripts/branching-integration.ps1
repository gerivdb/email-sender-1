#!/usr/bin/env pwsh
# Script d'intégration du Framework de Branchement 8-Niveaux
# Généré automatiquement par la migration du 2025-06-08 22:33:00

param(
    [Parameter(Mandatory = $false)]
    [string]$Mode = "development",
    
    [Parameter(Mandatory = $false)]
    [int]$Port = 8090
)

$ErrorActionPreference = "Stop"

# Configuration du framework intégré
$FrameworkConfig = @{
    Mode        = $Mode
    Port        = $Port
    ManagerPath = $PSScriptRoot
    ExecutionId = "integration-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
}

function Write-IntegrationLog {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] [BRANCHING-INTEGRATION] $Message"
    Write-Host $logMessage
}

function Start-BranchingFramework {
    Write-IntegrationLog "🌿 Démarrage du Framework de Branchement 8-Niveaux"
    Write-IntegrationLog "Mode: $($FrameworkConfig.Mode)"
    Write-IntegrationLog "Port: $($FrameworkConfig.Port)"
    
    # 1. Vérifier les services essentiels
    Test-EssentialServices    # 2. Démarrer le serveur web si disponible
    $webScript = Join-Path $FrameworkConfig.ManagerPath "start-branching-web.ps1"
    if (Test-Path $webScript) {
        Write-IntegrationLog "🚀 Démarrage du serveur web..."
        Start-Process -FilePath "pwsh.exe" -ArgumentList "-File", $webScript, "-Port", $FrameworkConfig.Port, "-Mode", $FrameworkConfig.Mode -WindowStyle Hidden
        Start-Sleep -Seconds 5  # Attendre que le serveur démarre
        
        # Vérifier si le serveur est maintenant accessible
        try {
            $serverTest = Test-NetConnection -ComputerName "localhost" -Port $FrameworkConfig.Port -InformationLevel Quiet
            if ($serverTest) {
                Write-IntegrationLog "✅ Serveur web démarré sur le port $($FrameworkConfig.Port)"
                Write-IntegrationLog "🌐 URL: http://localhost:$($FrameworkConfig.Port)/"
            }
            else {
                Write-IntegrationLog "⚠️  Serveur web non accessible" "WARNING"
            }
        }
        catch {
            Write-IntegrationLog "⚠️  Test de connectivité échoué" "WARNING"
        }
    }
    else {
        Write-IntegrationLog "⚠️  Script du serveur web non trouvé: $webScript" "WARNING"
    }
    
    # 3. Initialiser l'orchestrateur si disponible
    $orchestratorScript = Join-Path $FrameworkConfig.ManagerPath "orchestration\*orchestrat*.ps1"
    $orchestratorFiles = Get-ChildItem -Path $orchestratorScript -ErrorAction SilentlyContinue
    if ($orchestratorFiles) {
        Write-IntegrationLog "🎯 Initialisation de l'orchestrateur..."
        & $orchestratorFiles[0].FullName
    }
    
    Write-IntegrationLog "✅ Framework de branchement initialisé avec succès"
}

function Test-EssentialServices {
    Write-IntegrationLog "🔍 Vérification des services essentiels..."
    
    # Test Redis
    try {
        $redisTest = Test-NetConnection -ComputerName "localhost" -Port 6379 -InformationLevel Quiet
        if ($redisTest) {
            Write-IntegrationLog "✅ Redis: Disponible"
        }
        else {
            Write-IntegrationLog "⚠️  Redis: Non disponible" "WARNING"
        }
    }
    catch {
        Write-IntegrationLog "⚠️  Redis: Test échoué" "WARNING"
    }
    
    # Test QDrant
    try {
        $qdrantTest = Test-NetConnection -ComputerName "localhost" -Port 6333 -InformationLevel Quiet
        if ($qdrantTest) {
            Write-IntegrationLog "✅ QDrant: Disponible"
        }
        else {
            Write-IntegrationLog "⚠️  QDrant: Non disponible" "WARNING"
        }
    }
    catch {
        Write-IntegrationLog "⚠️  QDrant: Test échoué" "WARNING"
    }
}

# Point d'entrée principal
try {
    Start-BranchingFramework
}
catch {
    Write-IntegrationLog "❌ Erreur fatale: $($_.Exception.Message)" "ERROR"
    exit 1
}
