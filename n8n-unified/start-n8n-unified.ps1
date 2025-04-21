<#
.SYNOPSIS
    Script maître pour démarrer n8n avec toutes les intégrations.

.DESCRIPTION
    Ce script démarre n8n avec toutes les intégrations configurées, notamment
    l'intégration IDE et l'intégration MCP.

.PARAMETER N8nUrl
    URL de l'instance n8n.

.PARAMETER ApiKey
    Clé API pour l'authentification à n8n.

.PARAMETER McpPath
    Chemin vers le dossier MCP.

.PARAMETER EnableIde
    Active l'intégration IDE.

.PARAMETER EnableMcp
    Active l'intégration MCP.

.PARAMETER EnableDebug
    Active le mode débogage.

.EXAMPLE
    .\start-n8n-unified.ps1 -EnableIde -EnableMcp
#>

#Requires -Version 5.1

# Paramètres
param (
    [string]$N8nUrl = "http://localhost:5678",
    [string]$ApiKey = "",
    [string]$McpPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\mcp",
    [switch]$EnableIde,
    [switch]$EnableMcp,
    [switch]$EnableDebug
)

# Variables
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$LogFile = Join-Path -Path $ScriptPath -ChildPath "logs\n8n-unified.log"
$ConfigFile = Join-Path -Path $ScriptPath -ChildPath "config\n8n-unified-config.json"
$IdeIntegrationPath = Join-Path -Path $ScriptPath -ChildPath "integrations\ide\IdeN8nIntegration.ps1"
$McpIntegrationPath = Join-Path -Path $ScriptPath -ChildPath "integrations\mcp\McpN8nIntegration.ps1"

# Création des dossiers nécessaires
$Dirs = @(
    (Split-Path -Path $LogFile -Parent),
    (Split-Path -Path $ConfigFile -Parent)
)

foreach ($Dir in $Dirs) {
    if (-not (Test-Path -Path $Dir)) {
        New-Item -Path $Dir -ItemType Directory -Force | Out-Null
    }
}

# Fonction pour écrire dans le journal
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO"
    )
    
    if ($Level -eq "DEBUG" -and -not $EnableDebug) { return }
    
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
            $Config = @{
                N8nUrl = $N8nUrl
                ApiKey = $ApiKey
                McpPath = $McpPath
                EnableIde = $EnableIde.IsPresent
                EnableMcp = $EnableMcp.IsPresent
                LastStart = $null
            }
            
            $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFile -Encoding UTF8
            Write-Log -Message "Configuration par défaut créée" -Level INFO
            return $Config
        }
    }
    catch {
        Write-Log -Message "Erreur lors du chargement de la configuration : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour sauvegarder la configuration
function Save-N8nUnifiedConfig {
    param (
        [PSCustomObject]$Config
    )
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFile -Encoding UTF8
        Write-Log -Message "Configuration sauvegardée avec succès" -Level DEBUG
    }
    catch {
        Write-Log -Message "Erreur lors de la sauvegarde de la configuration : $_" -Level ERROR
        throw $_
    }
}

# Fonction pour démarrer n8n
function Start-N8n {
    try {
        Write-Log -Message "Démarrage de n8n..." -Level INFO
        
        # Démarrer n8n
        $N8nProcess = Start-Process -FilePath "npx" -ArgumentList "n8n start" -NoNewWindow -PassThru
        
        # Attendre que n8n soit prêt
        $Timeout = 60
        $StartTime = Get-Date
        $Ready = $false
        
        while (-not $Ready -and ((Get-Date) - $StartTime).TotalSeconds -lt $Timeout) {
            try {
                $Response = Invoke-RestMethod -Uri "$N8nUrl/healthz" -Method Get -TimeoutSec 1
                if ($Response.status -eq "ok") {
                    $Ready = $true
                }
            }
            catch {
                # Ignorer les erreurs et continuer à attendre
                Start-Sleep -Seconds 1
            }
        }
        
        if ($Ready) {
            Write-Log -Message "n8n démarré avec succès (PID: $($N8nProcess.Id))" -Level INFO
            return $N8nProcess
        }
        else {
            Write-Log -Message "Timeout lors du démarrage de n8n" -Level ERROR
            return $null
        }
    }
    catch {
        Write-Log -Message "Erreur lors du démarrage de n8n : $_" -Level ERROR
        return $null
    }
}

# Fonction pour démarrer l'intégration IDE
function Start-IdeIntegration {
    try {
        if (-not (Test-Path -Path $IdeIntegrationPath)) {
            Write-Log -Message "Le fichier d'intégration IDE $IdeIntegrationPath n'existe pas" -Level ERROR
            return $false
        }
        
        Write-Log -Message "Démarrage de l'intégration IDE..." -Level INFO
        
        # Importer le module
        Import-Module $IdeIntegrationPath -Force
        
        # Démarrer l'intégration IDE
        $Result = Start-IdeN8nIntegration -Action Test
        
        if ($Result) {
            Write-Log -Message "Intégration IDE démarrée avec succès" -Level INFO
            return $true
        }
        else {
            Write-Log -Message "Erreur lors du démarrage de l'intégration IDE" -Level ERROR
            return $false
        }
    }
    catch {
        Write-Log -Message "Erreur lors du démarrage de l'intégration IDE : $_" -Level ERROR
        return $false
    }
}

# Fonction pour démarrer l'intégration MCP
function Start-McpIntegration {
    param (
        [string]$McpPath
    )
    
    try {
        if (-not (Test-Path -Path $McpIntegrationPath)) {
            Write-Log -Message "Le fichier d'intégration MCP $McpIntegrationPath n'existe pas" -Level ERROR
            return $false
        }
        
        Write-Log -Message "Démarrage de l'intégration MCP..." -Level INFO
        
        # Importer le module
        Import-Module $McpIntegrationPath -Force
        
        # Démarrer l'intégration MCP
        $Result = Start-McpN8nIntegration -Action Start -McpPath $McpPath
        
        if ($Result) {
            Write-Log -Message "Intégration MCP démarrée avec succès" -Level INFO
            return $true
        }
        else {
            Write-Log -Message "Erreur lors du démarrage de l'intégration MCP" -Level ERROR
            return $false
        }
    }
    catch {
        Write-Log -Message "Erreur lors du démarrage de l'intégration MCP : $_" -Level ERROR
        return $false
    }
}

# Fonction principale
function Start-N8nUnified {
    try {
        Write-Log -Message "Démarrage de n8n unifié..." -Level INFO
        
        # Charger la configuration
        $Config = Get-N8nUnifiedConfig
        
        # Démarrer n8n
        $N8nProcess = Start-N8n
        
        if (-not $N8nProcess) {
            Write-Log -Message "Impossible de démarrer n8n" -Level ERROR
            return $false
        }
        
        # Démarrer l'intégration IDE si activée
        if ($Config.EnableIde) {
            $IdeResult = Start-IdeIntegration
            if (-not $IdeResult) {
                Write-Log -Message "Impossible de démarrer l'intégration IDE" -Level WARNING
            }
        }
        
        # Démarrer l'intégration MCP si activée
        if ($Config.EnableMcp) {
            $McpResult = Start-McpIntegration -McpPath $Config.McpPath
            if (-not $McpResult) {
                Write-Log -Message "Impossible de démarrer l'intégration MCP" -Level WARNING
            }
        }
        
        # Mettre à jour la configuration
        $Config.LastStart = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Save-N8nUnifiedConfig -Config $Config
        
        Write-Log -Message "n8n unifié démarré avec succès" -Level INFO
        return $true
    }
    catch {
        Write-Log -Message "Erreur lors du démarrage de n8n unifié : $_" -Level ERROR
        return $false
    }
}

# Démarrer n8n unifié
$Result = Start-N8nUnified

if ($Result) {
    Write-Host "n8n unifié démarré avec succès." -ForegroundColor Green
    Write-Host "Accédez à n8n à l'adresse $N8nUrl" -ForegroundColor Green
    Write-Host "Appuyez sur Ctrl+C pour arrêter n8n." -ForegroundColor Yellow
    
    try {
        # Garder le script en cours d'exécution
        while ($true) {
            Start-Sleep -Seconds 1
        }
    }
    catch {
        # Arrêter n8n
        Write-Host "Arrêt de n8n..." -ForegroundColor Yellow
        
        # Arrêter l'intégration MCP si activée
        if ($EnableMcp) {
            try {
                Import-Module $McpIntegrationPath -Force
                Start-McpN8nIntegration -Action Stop -McpPath $McpPath
            }
            catch {
                Write-Host "Erreur lors de l'arrêt de l'intégration MCP : $_" -ForegroundColor Red
            }
        }
        
        # Arrêter n8n
        try {
            $N8nProcesses = Get-Process -Name "node" | Where-Object { $_.CommandLine -like "*n8n start*" }
            foreach ($Process in $N8nProcesses) {
                Stop-Process -Id $Process.Id -Force
            }
        }
        catch {
            Write-Host "Erreur lors de l'arrêt de n8n : $_" -ForegroundColor Red
        }
        
        Write-Host "n8n arrêté." -ForegroundColor Green
    }
}
else {
    Write-Host "Erreur lors du démarrage de n8n unifié." -ForegroundColor Red
}
