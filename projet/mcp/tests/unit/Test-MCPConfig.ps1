#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la configuration MCP.
.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier la validité de la configuration MCP.
.EXAMPLE
    .\Test-MCPConfig.ps1
    Exécute les tests unitaires pour la configuration MCP.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-01
#>
[CmdletBinding()]
param ()

# Initialisation
$ErrorActionPreference = "Stop"
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$testsRoot = (Get-Item $scriptPath).Parent.FullName
$mcpRoot = (Get-Item $testsRoot).Parent.FullName
$configPath = Join-Path -Path $mcpRoot -ChildPath "config\mcp-config.json"

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

# Tests
function Test-ConfigFileExists {
    $TestName = "Test-ConfigFileExists"
    
    if (Test-Path $configPath) {
        Write-TestResult -TestName $TestName -Success $true
        return $true
    }
    else {
        Write-TestResult -TestName $TestName -Success $false -Message "Le fichier de configuration n'existe pas: $configPath"
        return $false
    }
}

function Test-ConfigFileIsValidJson {
    $TestName = "Test-ConfigFileIsValidJson"
    
    if (-not (Test-Path $configPath)) {
        Write-TestResult -TestName $TestName -Success $false -Message "Le fichier de configuration n'existe pas: $configPath"
        return $false
    }
    
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        Write-TestResult -TestName $TestName -Success $true
        return $true
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Le fichier de configuration n'est pas un JSON valide: $_"
        return $false
    }
}

function Test-ConfigHasMcpServersSection {
    $TestName = "Test-ConfigHasMcpServersSection"
    
    if (-not (Test-Path $configPath)) {
        Write-TestResult -TestName $TestName -Success $false -Message "Le fichier de configuration n'existe pas: $configPath"
        return $false
    }
    
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        
        if ($config.mcpServers) {
            Write-TestResult -TestName $TestName -Success $true
            return $true
        }
        else {
            Write-TestResult -TestName $TestName -Success $false -Message "La section 'mcpServers' est manquante dans la configuration"
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors de la lecture de la configuration: $_"
        return $false
    }
}

function Test-ConfigHasGlobalSection {
    $TestName = "Test-ConfigHasGlobalSection"
    
    if (-not (Test-Path $configPath)) {
        Write-TestResult -TestName $TestName -Success $false -Message "Le fichier de configuration n'existe pas: $configPath"
        return $false
    }
    
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        
        if ($config.global) {
            Write-TestResult -TestName $TestName -Success $true
            return $true
        }
        else {
            Write-TestResult -TestName $TestName -Success $false -Message "La section 'global' est manquante dans la configuration"
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors de la lecture de la configuration: $_"
        return $false
    }
}

function Test-ConfigHasAtLeastOneServer {
    $TestName = "Test-ConfigHasAtLeastOneServer"
    
    if (-not (Test-Path $configPath)) {
        Write-TestResult -TestName $TestName -Success $false -Message "Le fichier de configuration n'existe pas: $configPath"
        return $false
    }
    
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        
        if ($config.mcpServers -and $config.mcpServers.PSObject.Properties.Count -gt 0) {
            Write-TestResult -TestName $TestName -Success $true
            return $true
        }
        else {
            Write-TestResult -TestName $TestName -Success $false -Message "Aucun serveur MCP n'est configuré"
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors de la lecture de la configuration: $_"
        return $false
    }
}

function Test-ServerConfigsAreValid {
    $TestName = "Test-ServerConfigsAreValid"
    
    if (-not (Test-Path $configPath)) {
        Write-TestResult -TestName $TestName -Success $false -Message "Le fichier de configuration n'existe pas: $configPath"
        return $false
    }
    
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        $invalidServers = @()
        
        foreach ($serverName in $config.mcpServers.PSObject.Properties.Name) {
            $serverConfig = $config.mcpServers.$serverName
            
            # Vérifier que le serveur a une propriété 'enabled'
            if ($null -eq $serverConfig.enabled) {
                $invalidServers += "$serverName (propriété 'enabled' manquante)"
                continue
            }
            
            # Vérifier que le serveur a une URL ou une commande
            if (-not $serverConfig.url -and -not $serverConfig.command) {
                $invalidServers += "$serverName (ni URL ni commande spécifiée)"
                continue
            }
            
            # Si le serveur a une commande, vérifier qu'il a des arguments
            if ($serverConfig.command -and $null -eq $serverConfig.args) {
                $invalidServers += "$serverName (commande spécifiée mais pas d'arguments)"
                continue
            }
        }
        
        if ($invalidServers.Count -eq 0) {
            Write-TestResult -TestName $TestName -Success $true
            return $true
        }
        else {
            $message = "Les serveurs suivants ont une configuration invalide: $($invalidServers -join ', ')"
            Write-TestResult -TestName $TestName -Success $false -Message $message
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors de la lecture de la configuration: $_"
        return $false
    }
}

# Exécution des tests
$tests = @(
    "Test-ConfigFileExists",
    "Test-ConfigFileIsValidJson",
    "Test-ConfigHasMcpServersSection",
    "Test-ConfigHasGlobalSection",
    "Test-ConfigHasAtLeastOneServer",
    "Test-ServerConfigsAreValid"
)

$results = @{
    Total = $tests.Count
    Passed = 0
    Failed = 0
}

Write-Host "Exécution des tests unitaires pour la configuration MCP..." -ForegroundColor Cyan

foreach ($test in $tests) {
    $success = & $test
    
    if ($success) {
        $results.Passed++
    }
    else {
        $results.Failed++
    }
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
