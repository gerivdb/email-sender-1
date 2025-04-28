#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module MCPManager.
.DESCRIPTION
    Ce script exécute des tests unitaires pour vérifier le bon fonctionnement du module MCPManager.
.EXAMPLE
    .\Test-MCPManager.ps1
    Exécute les tests unitaires pour le module MCPManager.
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

# Tests
function Test-ModuleExists {
    $TestName = "Test-ModuleExists"
    
    if (Test-Path $modulePath) {
        Write-TestResult -TestName $TestName -Success $true
        return $true
    }
    else {
        Write-TestResult -TestName $TestName -Success $false -Message "Le module MCPManager n'existe pas: $modulePath"
        return $false
    }
}

function Test-ModuleCanBeImported {
    $TestName = "Test-ModuleCanBeImported"
    
    if (-not (Test-Path $modulePath)) {
        Write-TestResult -TestName $TestName -Success $false -Message "Le module MCPManager n'existe pas: $modulePath"
        return $false
    }
    
    try {
        Import-Module $modulePath -Force -ErrorAction Stop
        Write-TestResult -TestName $TestName -Success $true
        return $true
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors de l'importation du module: $_"
        return $false
    }
}

function Test-GetMCPServersFunction {
    $TestName = "Test-GetMCPServersFunction"
    
    if (-not (Test-Path $modulePath)) {
        Write-TestResult -TestName $TestName -Success $false -Message "Le module MCPManager n'existe pas: $modulePath"
        return $false
    }
    
    try {
        Import-Module $modulePath -Force -ErrorAction Stop
        
        if (Get-Command -Name Get-MCPServers -ErrorAction SilentlyContinue) {
            $servers = Get-MCPServers
            
            if ($null -ne $servers) {
                Write-TestResult -TestName $TestName -Success $true
                return $true
            }
            else {
                Write-TestResult -TestName $TestName -Success $false -Message "La fonction Get-MCPServers n'a retourné aucun résultat"
                return $false
            }
        }
        else {
            Write-TestResult -TestName $TestName -Success $false -Message "La fonction Get-MCPServers n'existe pas"
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors de l'exécution de la fonction Get-MCPServers: $_"
        return $false
    }
}

function Test-GetMCPServerStatusFunction {
    $TestName = "Test-GetMCPServerStatusFunction"
    
    if (-not (Test-Path $modulePath)) {
        Write-TestResult -TestName $TestName -Success $false -Message "Le module MCPManager n'existe pas: $modulePath"
        return $false
    }
    
    try {
        Import-Module $modulePath -Force -ErrorAction Stop
        
        if (Get-Command -Name Get-MCPServerStatus -ErrorAction SilentlyContinue) {
            $status = Get-MCPServerStatus
            
            if ($null -ne $status) {
                Write-TestResult -TestName $TestName -Success $true
                return $true
            }
            else {
                Write-TestResult -TestName $TestName -Success $false -Message "La fonction Get-MCPServerStatus n'a retourné aucun résultat"
                return $false
            }
        }
        else {
            Write-TestResult -TestName $TestName -Success $false -Message "La fonction Get-MCPServerStatus n'existe pas"
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors de l'exécution de la fonction Get-MCPServerStatus: $_"
        return $false
    }
}

function Test-EnableDisableMCPServerFunctions {
    $TestName = "Test-EnableDisableMCPServerFunctions"
    
    if (-not (Test-Path $modulePath)) {
        Write-TestResult -TestName $TestName -Success $false -Message "Le module MCPManager n'existe pas: $modulePath"
        return $false
    }
    
    try {
        Import-Module $modulePath -Force -ErrorAction Stop
        
        $enableExists = Get-Command -Name Enable-MCPServer -ErrorAction SilentlyContinue
        $disableExists = Get-Command -Name Disable-MCPServer -ErrorAction SilentlyContinue
        
        if ($enableExists -and $disableExists) {
            Write-TestResult -TestName $TestName -Success $true
            return $true
        }
        else {
            $missing = @()
            
            if (-not $enableExists) {
                $missing += "Enable-MCPServer"
            }
            
            if (-not $disableExists) {
                $missing += "Disable-MCPServer"
            }
            
            Write-TestResult -TestName $TestName -Success $false -Message "Les fonctions suivantes n'existent pas: $($missing -join ', ')"
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors de la vérification des fonctions Enable/Disable-MCPServer: $_"
        return $false
    }
}

function Test-StartStopRestartMCPServerFunctions {
    $TestName = "Test-StartStopRestartMCPServerFunctions"
    
    if (-not (Test-Path $modulePath)) {
        Write-TestResult -TestName $TestName -Success $false -Message "Le module MCPManager n'existe pas: $modulePath"
        return $false
    }
    
    try {
        Import-Module $modulePath -Force -ErrorAction Stop
        
        $startExists = Get-Command -Name Start-MCPServer -ErrorAction SilentlyContinue
        $stopExists = Get-Command -Name Stop-MCPServer -ErrorAction SilentlyContinue
        $restartExists = Get-Command -Name Restart-MCPServer -ErrorAction SilentlyContinue
        
        if ($startExists -and $stopExists -and $restartExists) {
            Write-TestResult -TestName $TestName -Success $true
            return $true
        }
        else {
            $missing = @()
            
            if (-not $startExists) {
                $missing += "Start-MCPServer"
            }
            
            if (-not $stopExists) {
                $missing += "Stop-MCPServer"
            }
            
            if (-not $restartExists) {
                $missing += "Restart-MCPServer"
            }
            
            Write-TestResult -TestName $TestName -Success $false -Message "Les fonctions suivantes n'existent pas: $($missing -join ', ')"
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors de la vérification des fonctions Start/Stop/Restart-MCPServer: $_"
        return $false
    }
}

function Test-InvokeMCPCommandFunction {
    $TestName = "Test-InvokeMCPCommandFunction"
    
    if (-not (Test-Path $modulePath)) {
        Write-TestResult -TestName $TestName -Success $false -Message "Le module MCPManager n'existe pas: $modulePath"
        return $false
    }
    
    try {
        Import-Module $modulePath -Force -ErrorAction Stop
        
        if (Get-Command -Name Invoke-MCPCommand -ErrorAction SilentlyContinue) {
            Write-TestResult -TestName $TestName -Success $true
            return $true
        }
        else {
            Write-TestResult -TestName $TestName -Success $false -Message "La fonction Invoke-MCPCommand n'existe pas"
            return $false
        }
    }
    catch {
        Write-TestResult -TestName $TestName -Success $false -Message "Erreur lors de la vérification de la fonction Invoke-MCPCommand: $_"
        return $false
    }
}

# Exécution des tests
$tests = @(
    "Test-ModuleExists",
    "Test-ModuleCanBeImported",
    "Test-GetMCPServersFunction",
    "Test-GetMCPServerStatusFunction",
    "Test-EnableDisableMCPServerFunctions",
    "Test-StartStopRestartMCPServerFunctions",
    "Test-InvokeMCPCommandFunction"
)

$results = @{
    Total = $tests.Count
    Passed = 0
    Failed = 0
}

Write-Host "Exécution des tests unitaires pour le module MCPManager..." -ForegroundColor Cyan

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
