#Requires -Version 5.1
<#
.SYNOPSIS
    Tests d'intégration pour les serveurs MCP.
.DESCRIPTION
    Ce script exécute des tests d'intégration pour vérifier le bon fonctionnement des serveurs MCP.
.PARAMETER Server
    Nom du serveur MCP à tester. Si non spécifié, tous les serveurs seront testés.
.EXAMPLE
    .\Test-MCPServerIntegration.ps1 -Server filesystem
    Exécute les tests d'intégration pour le serveur MCP filesystem.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$Server
)

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testsRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $testsRoot).Parent.FullName
$modulePath = Join-Path -Path $mcpRoot -ChildPath "modules\MCPManager"

# Fonctions d'aide
function Write-TestResult {
    param (
        [string]$TestName,
        [bool]$Success,
        [string]$Message = ""
    )
    
    $color = if ($Success) { "Green" } else { "Red" }
    $status = if ($Success) { "PASS" } else { "FAIL" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    
    if (-not [string]::IsNullOrEmpty($Message)) {
        Write-Host "       $Message" -ForegroundColor $color
    }
}

# Importer le module MCPManager
try {
    Import-Module $modulePath -Force -ErrorAction Stop
}
catch {
    Write-Host "Erreur lors de l'importation du module MCPManager: $_" -ForegroundColor Red
    exit 1
}

# Tests
function Test-ServerCanBeStarted {
    param (
        [string]$ServerName
    )
    
    $TestName = "Test-ServerCanBeStarted-$ServerName"
    
    try {
        # Vérifier si le serveur est déjà en cours d'exécution
        $status = Get-MCPServerStatus -ServerName $ServerName
        
        if ($status.Status -eq "Running") {
            Write-TestResult -TestName $TestName -Success $true -Message "Le serveur est déjà en cours d'exécution"
            return $true
        }
        
        # Démarrer le serveur
        $result = Start-MCPServer -ServerName $ServerName -Force
        
        if ($result) {
            # Vérifier que le serveur est bien démarré
            $status = Get-MCPServerStatus -ServerName $ServerName
            
            if ($status.Status -eq "Running") {
                Write-TestResult -TestName $TestName -Success $true
                return $true
            }
            else {
                Write-TestResult -TestName $TestName -Success $false -Message "Le serveur n'est pas en cours d'exécution après le démarrage"
                return $false
            }
        }
        else {
            Write-TestResult -TestName $TestName -Success $false -Message "Échec du démarrage du serveur"
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors du démarrage du serveur: $_"
        return $false
    }
}

function Test-ServerCanBeStopped {
    param (
        [string]$ServerName
    )
    
    $TestName = "Test-ServerCanBeStopped-$ServerName"
    
    try {
        # Vérifier si le serveur est en cours d'exécution
        $status = Get-MCPServerStatus -ServerName $ServerName
        
        if ($status.Status -ne "Running") {
            Write-TestResult -TestName $TestName -Success $false -Message "Le serveur n'est pas en cours d'exécution"
            return $false
        }
        
        # Arrêter le serveur
        $result = Stop-MCPServer -ServerName $ServerName -Force
        
        if ($result) {
            # Vérifier que le serveur est bien arrêté
            $status = Get-MCPServerStatus -ServerName $ServerName
            
            if ($status.Status -ne "Running") {
                Write-TestResult -TestName $TestName -Success $true
                return $true
            }
            else {
                Write-TestResult -TestName $TestName -Success $false -Message "Le serveur est toujours en cours d'exécution après l'arrêt"
                return $false
            }
        }
        else {
            Write-TestResult -TestName $TestName -Success $false -Message "Échec de l'arrêt du serveur"
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors de l'arrêt du serveur: $_"
        return $false
    }
}

function Test-ServerCanBeRestarted {
    param (
        [string]$ServerName
    )
    
    $TestName = "Test-ServerCanBeRestarted-$ServerName"
    
    try {
        # Démarrer le serveur s'il n'est pas déjà en cours d'exécution
        $status = Get-MCPServerStatus -ServerName $ServerName
        
        if ($status.Status -ne "Running") {
            Start-MCPServer -ServerName $ServerName -Force | Out-Null
        }
        
        # Redémarrer le serveur
        $result = Restart-MCPServer -ServerName $ServerName -Force
        
        if ($result) {
            # Vérifier que le serveur est bien redémarré
            $status = Get-MCPServerStatus -ServerName $ServerName
            
            if ($status.Status -eq "Running") {
                Write-TestResult -TestName $TestName -Success $true
                return $true
            }
            else {
                Write-TestResult -TestName $TestName -Success $false -Message "Le serveur n'est pas en cours d'exécution après le redémarrage"
                return $false
            }
        }
        else {
            Write-TestResult -TestName $TestName -Success $false -Message "Échec du redémarrage du serveur"
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors du redémarrage du serveur: $_"
        return $false
    }
}

function Test-ServerCanBeDisabledAndEnabled {
    param (
        [string]$ServerName
    )
    
    $TestName = "Test-ServerCanBeDisabledAndEnabled-$ServerName"
    
    try {
        # Désactiver le serveur
        $disableResult = Disable-MCPServer -ServerName $ServerName
        
        if (-not $disableResult) {
            Write-TestResult -TestName $TestName -Success $false -Message "Échec de la désactivation du serveur"
            return $false
        }
        
        # Vérifier que le serveur est bien désactivé
        $servers = Get-MCPServers
        $server = $servers | Where-Object { $_.Name -eq $ServerName }
        
        if ($server.Enabled -eq $false) {
            # Réactiver le serveur
            $enableResult = Enable-MCPServer -ServerName $ServerName
            
            if (-not $enableResult) {
                Write-TestResult -TestName $TestName -Success $false -Message "Échec de la réactivation du serveur"
                return $false
            }
            
            # Vérifier que le serveur est bien réactivé
            $servers = Get-MCPServers
            $server = $servers | Where-Object { $_.Name -eq $ServerName }
            
            if ($server.Enabled -eq $true) {
                Write-TestResult -TestName $TestName -Success $true
                return $true
            }
            else {
                Write-TestResult -TestName $TestName -Success $false -Message "Le serveur n'est pas activé après la réactivation"
                return $false
            }
        }
        else {
            Write-TestResult -TestName $TestName -Success $false -Message "Le serveur n'est pas désactivé après la désactivation"
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors de la désactivation/réactivation du serveur: $_"
        return $false
    }
}

# Exécution des tests
$servers = if ($Server) { @($Server) } else { (Get-MCPServers).Name }

$results = @{
    Total = $servers.Count * 4 # 4 tests par serveur
    Passed = 0
    Failed = 0
}

Write-Host "Exécution des tests d'intégration pour les serveurs MCP..." -ForegroundColor Cyan

foreach ($serverName in $servers) {
    Write-Host "`nTests pour le serveur $serverName:" -ForegroundColor Cyan
    
    # Test 1: Démarrage du serveur
    $startSuccess = Test-ServerCanBeStarted -ServerName $serverName
    if ($startSuccess) { $results.Passed++ } else { $results.Failed++ }
    
    # Test 2: Arrêt du serveur
    $stopSuccess = Test-ServerCanBeStopped -ServerName $serverName
    if ($stopSuccess) { $results.Passed++ } else { $results.Failed++ }
    
    # Test 3: Redémarrage du serveur
    $restartSuccess = Test-ServerCanBeRestarted -ServerName $serverName
    if ($restartSuccess) { $results.Passed++ } else { $results.Failed++ }
    
    # Test 4: Désactivation et réactivation du serveur
    $disableEnableSuccess = Test-ServerCanBeDisabledAndEnabled -ServerName $serverName
    if ($disableEnableSuccess) { $results.Passed++ } else { $results.Failed++ }
    
    # Arrêter le serveur à la fin des tests
    Stop-MCPServer -ServerName $serverName -Force | Out-Null
}

# Résumé
Write-Host "`nRésumé des tests:" -ForegroundColor Cyan
Write-Host "Total: $($results.Total)" -ForegroundColor White
Write-Host "Réussis: $($results.Passed)" -ForegroundColor Green
Write-Host "Échoués: $($results.Failed)" -ForegroundColor Red

# Retourner un code de sortie
if ($results.Failed -eq 0) {
    Write-Host "`nTous les tests ont réussi!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`nCertains tests ont échoué." -ForegroundColor Red
    exit 1
}
