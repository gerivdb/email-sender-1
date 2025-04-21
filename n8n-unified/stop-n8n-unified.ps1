<#
.SYNOPSIS
    Script pour arrêter n8n et toutes les intégrations.

.DESCRIPTION
    Ce script arrête n8n et toutes les intégrations configurées, notamment
    l'intégration IDE et l'intégration MCP.

.PARAMETER McpPath
    Chemin vers le dossier MCP.

.PARAMETER Force
    Force l'arrêt de n8n et des intégrations.

.EXAMPLE
    .\stop-n8n-unified.ps1
#>

#Requires -Version 5.1

# Paramètres
param (
    [string]$McpPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp",
    [switch]$Force
)

# Variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path -Path $ScriptPath -ChildPath "logs\n8n-unified.log"
$ConfigFile = Join-Path -Path $ScriptPath -ChildPath "config\n8n-unified-config.json"
$McpIntegrationPath = Join-Path -Path $ScriptPath -ChildPath "integrations\mcp\McpN8nIntegration.ps1"

# Fonction pour écrire dans le journal
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "[$Timestamp] [$Level] $Message"
    
    Add-Content -Path $LogFile -Value $LogMessage -Encoding UTF8
    
    switch ($Level) {
        "INFO" { Write-Host $LogMessage -ForegroundColor White }
        "WARNING" { Write-Host $LogMessage -ForegroundColor Yellow }
        "ERROR" { Write-Host $LogMessage -ForegroundColor Red }
        "DEBUG" { Write-Host $LogMessage -ForegroundColor Gray }
    }
}

# Fonction pour charger la configuration
function Get-N8nUnifiedConfig {
    try {
        if (Test-Path -Path $ConfigFile) {
            $Config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
            Write-Log -Message "Configuration chargée avec succès" -Level DEBUG
            return $Config
        }
        else {
            Write-Log -Message "Le fichier de configuration n'existe pas" -Level WARNING
            return $null
        }
    }
    catch {
        Write-Log -Message "Erreur lors du chargement de la configuration : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour arrêter l'intégration MCP
function Stop-McpIntegration {
    param (
        [string]$McpPath
    )
    
    try {
        if (-not (Test-Path -Path $McpIntegrationPath)) {
            Write-Log -Message "Le fichier d'intégration MCP $McpIntegrationPath n'existe pas" -Level ERROR
            return $false
        }
        
        Write-Log -Message "Arrêt de l'intégration MCP..." -Level INFO
        
        # Importer le module
        Import-Module $McpIntegrationPath -Force
        
        # Arrêter l'intégration MCP
        $Result = Start-McpN8nIntegration -Action Stop -McpPath $McpPath
        
        if ($Result) {
            Write-Log -Message "Intégration MCP arrêtée avec succès" -Level INFO
            return $true
        }
        else {
            Write-Log -Message "Erreur lors de l'arrêt de l'intégration MCP" -Level ERROR
            return $false
        }
    }
    catch {
        Write-Log -Message "Erreur lors de l'arrêt de l'intégration MCP : $_" -Level ERROR
        return $false
    }
}

# Fonction pour arrêter n8n
function Stop-N8n {
    param (
        [switch]$Force
    )
    
    try {
        Write-Log -Message "Arrêt de n8n..." -Level INFO
        
        # Récupérer les processus n8n
        $N8nProcesses = Get-Process -Name "node" | Where-Object { $_.CommandLine -like "*n8n start*" }
        
        if ($N8nProcesses.Count -eq 0) {
            Write-Log -Message "Aucun processus n8n trouvé" -Level WARNING
            return $true
        }
        
        # Arrêter les processus n8n
        foreach ($Process in $N8nProcesses) {
            if ($Force) {
                Stop-Process -Id $Process.Id -Force
            }
            else {
                Stop-Process -Id $Process.Id
            }
        }
        
        # Vérifier que les processus sont arrêtés
        $Timeout = 30
        $StartTime = Get-Date
        $Stopped = $false
        
        while (-not $Stopped -and ((Get-Date) - $StartTime).TotalSeconds -lt $Timeout) {
            $N8nProcesses = Get-Process -Name "node" | Where-Object { $_.CommandLine -like "*n8n start*" }
            if ($N8nProcesses.Count -eq 0) {
                $Stopped = $true
            }
            else {
                Start-Sleep -Seconds 1
            }
        }
        
        if ($Stopped) {
            Write-Log -Message "n8n arrêté avec succès" -Level INFO
            return $true
        }
        else {
            Write-Log -Message "Timeout lors de l'arrêt de n8n" -Level ERROR
            return $false
        }
    }
    catch {
        Write-Log -Message "Erreur lors de l'arrêt de n8n : $_" -Level ERROR
        return $false
    }
}

# Fonction principale
function Stop-N8nUnified {
    param (
        [string]$McpPath,
        [switch]$Force
    )
    
    try {
        Write-Log -Message "Arrêt de n8n unifié..." -Level INFO
        
        # Charger la configuration
        $Config = Get-N8nUnifiedConfig
        
        # Utiliser le chemin MCP de la configuration si disponible
        if ($Config -and $Config.McpPath -and -not $PSBoundParameters.ContainsKey('McpPath')) {
            $McpPath = $Config.McpPath
        }
        
        # Arrêter l'intégration MCP si activée
        if ($Config -and $Config.EnableMcp) {
            $McpResult = Stop-McpIntegration -McpPath $McpPath
            if (-not $McpResult) {
                Write-Log -Message "Impossible d'arrêter l'intégration MCP" -Level WARNING
            }
        }
        
        # Arrêter n8n
        $N8nResult = Stop-N8n -Force:$Force
        if (-not $N8nResult) {
            Write-Log -Message "Impossible d'arrêter n8n" -Level ERROR
            return $false
        }
        
        Write-Log -Message "n8n unifié arrêté avec succès" -Level INFO
        return $true
    }
    catch {
        Write-Log -Message "Erreur lors de l'arrêt de n8n unifié : $_" -Level ERROR
        return $false
    }
}

# Arrêter n8n unifié
$Result = Stop-N8nUnified -McpPath $McpPath -Force:$Force

if ($Result) {
    Write-Host "n8n unifié arrêté avec succès." -ForegroundColor Green
}
else {
    Write-Host "Erreur lors de l'arrêt de n8n unifié." -ForegroundColor Red
}
