#Requires -Version 5.1
<#
.SYNOPSIS
    Test minimal pour vérifier les fonctions de base des modules MCP.
.DESCRIPTION
    Ce script effectue des tests minimaux pour vérifier que les fonctions de base des modules MCPManager et MCPClient fonctionnent correctement.
.EXAMPLE
    .\Test-MCPBasicFunctions.ps1
    Exécute les tests minimaux.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-04-20
#>
[CmdletBinding()]
param ()

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console avec couleur
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
}

# Fonction pour tester un module
function Test-Module {
    param (
        [string]$ModulePath,
        [string]$ModuleName
    )
    
    Write-Log "Test du module $ModuleName..." -Level "INFO"
    
    # Vérifier que le module existe
    if (-not (Test-Path $ModulePath)) {
        Write-Log "Module $ModuleName introuvable à $ModulePath" -Level "ERROR"
        return $false
    }
    
    # Essayer d'importer le module
    try {
        Import-Module $ModulePath -Force
        Write-Log "Module $ModuleName importé avec succès" -Level "SUCCESS"
        
        # Vérifier que les fonctions sont exportées
        $exportedFunctions = Get-Command -Module $ModuleName | Select-Object -ExpandProperty Name
        Write-Log "Fonctions exportées par $ModuleName:" -Level "INFO"
        $exportedFunctions | ForEach-Object { Write-Log "- $_" -Level "INFO" }
        
        return $true
    } catch {
        Write-Log "Erreur lors de l'importation du module $ModuleName: $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour tester une fonction spécifique
function Test-Function {
    param (
        [string]$FunctionName,
        [scriptblock]$TestScript
    )
    
    Write-Log "Test de la fonction $FunctionName..." -Level "INFO"
    
    try {
        $result = & $TestScript
        Write-Log "Fonction $FunctionName testée avec succès" -Level "SUCCESS"
        return $true
    } catch {
        Write-Log "Erreur lors du test de la fonction $FunctionName: $_" -Level "ERROR"
        return $false
    }
}

# Chemins des modules
$managerModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\MCPManager.psm1"
$clientModulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\MCPClient.psm1"

# Créer un dossier temporaire pour les tests
$testDrive = Join-Path -Path $env:TEMP -ChildPath "MCPTests_$(Get-Random)"
if (Test-Path $testDrive) {
    Remove-Item $testDrive -Recurse -Force
}
New-Item -Path $testDrive -ItemType Directory -Force | Out-Null

# Tester les modules
$managerSuccess = Test-Module -ModulePath $managerModulePath -ModuleName "MCPManager"
$clientSuccess = Test-Module -ModulePath $clientModulePath -ModuleName "MCPClient"

# Tester les fonctions de base du module MCPManager
if ($managerSuccess) {
    Write-Log "Test des fonctions de base du module MCPManager..." -Level "INFO"
    
    # Tester Write-MCPLog
    $logSuccess = Test-Function -FunctionName "Write-MCPLog" -TestScript {
        Write-MCPLog -Message "Test message" -Level "INFO"
    }
    
    # Tester New-MCPConfiguration
    $configPath = Join-Path -Path $testDrive -ChildPath "mcp-config.json"
    $configSuccess = Test-Function -FunctionName "New-MCPConfiguration" -TestScript {
        New-MCPConfiguration -OutputPath $configPath -Force
    }
    
    # Vérifier que le fichier de configuration a été créé
    if ($configSuccess -and (Test-Path $configPath)) {
        Write-Log "Fichier de configuration créé avec succès" -Level "SUCCESS"
        
        # Vérifier que le contenu est un JSON valide
        $content = Get-Content -Path $configPath -Raw
        try {
            $config = $content | ConvertFrom-Json
            Write-Log "Configuration JSON valide" -Level "SUCCESS"
        } catch {
            Write-Log "Configuration JSON invalide: $_" -Level "ERROR"
        }
    }
}

# Tester les fonctions de base du module MCPClient
if ($clientSuccess) {
    Write-Log "Test des fonctions de base du module MCPClient..." -Level "INFO"
    
    # Tester Initialize-MCPConnection
    $logPath = Join-Path -Path $testDrive -ChildPath "MCPClient.log"
    $initSuccess = Test-Function -FunctionName "Initialize-MCPConnection" -TestScript {
        Initialize-MCPConnection -ServerUrl "http://localhost:8000" -LogPath $logPath
    }
    
    # Tester Get-MCPClientConfiguration
    $configSuccess = Test-Function -FunctionName "Get-MCPClientConfiguration" -TestScript {
        Get-MCPClientConfiguration
    }
    
    # Tester Set-MCPClientConfiguration
    $setConfigSuccess = Test-Function -FunctionName "Set-MCPClientConfiguration" -TestScript {
        Set-MCPClientConfiguration -Timeout 60 -RetryCount 5 -RetryDelay 3 -LogLevel "DEBUG"
    }
    
    # Tester Clear-MCPCache
    $cacheSuccess = Test-Function -FunctionName "Clear-MCPCache" -TestScript {
        Clear-MCPCache -Force
    }
}

# Nettoyer
if (Test-Path $testDrive) {
    Remove-Item $testDrive -Recurse -Force
    Write-Log "Dossier temporaire supprimé" -Level "INFO"
}

# Afficher le résultat
if ($managerSuccess -and $clientSuccess) {
    Write-Log "Tous les modules ont été testés avec succès" -Level "SUCCESS"
} else {
    Write-Log "Certains modules n'ont pas pu être testés correctement" -Level "ERROR"
}
