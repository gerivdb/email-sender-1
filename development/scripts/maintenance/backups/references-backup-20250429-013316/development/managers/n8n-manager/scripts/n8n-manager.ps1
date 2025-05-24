<#
.SYNOPSIS
    Script d'orchestration principal pour la gestion de n8n.

.DESCRIPTION
    Ce script fournit une interface unifiÃ©e pour toutes les fonctionnalitÃ©s de gestion de n8n,
    incluant le dÃ©marrage, l'arrÃªt, la surveillance, l'importation de workflows et les diagnostics.

.PARAMETER Action
    Action Ã  exÃ©cuter directement sans afficher le menu (optionnel).
    Valeurs possibles: start, stop, restart, status, import, verify, test, dashboard, maintenance.

.PARAMETER ConfigFile
    Fichier de configuration Ã  utiliser (par dÃ©faut: n8n/config/n8n-manager-config.json).

.PARAMETER NoInteractive
    ExÃ©cute le script en mode non interactif (sans menu).

.EXAMPLE
    .\n8n-manager.ps1
    Affiche le menu interactif.

.EXAMPLE
    .\n8n-manager.ps1 -Action start
    DÃ©marre n8n sans afficher le menu.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  23/04/2025
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [ValidateSet("start", "stop", "restart", "status", "import", "verify", "test", "dashboard", "maintenance")]
    [string]$Action = "",
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile = "n8n/config/n8n-manager-config.json",
    
    [Parameter(Mandatory=$false)]
    [switch]$NoInteractive
)

#region Configuration et initialisation

# DÃ©finir les chemins des scripts
$scriptPaths = @{
    Start = "deployment/start-n8n.ps1"
    Stop = "deployment/stop-n8n.ps1"
    Restart = "deployment/restart-n8n.ps1"
    Status = "monitoring/check-n8n-status-main.ps1"
    Import = "deployment/import-workflows-auto-main.ps1"
    ImportBulk = "deployment/import-workflows-bulk.ps1"
    Verify = "monitoring/Confirm-Workflows.ps1"
    Test = "diagnostics/test-structure.ps1"
    Dashboard = "dashboard/n8n-dashboard.ps1"
    Maintenance = "maintenance/maintenance.ps1"
}

# Fonction pour obtenir le chemin complet d'un script
function Get-ScriptPath {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ScriptKey
    )
    
    if ($scriptPaths.ContainsKey($ScriptKey)) {
        return Join-Path -Path $PSScriptRoot -ChildPath $scriptPaths[$ScriptKey]
    }
    
    return $null
}

# Fonction pour charger la configuration
function Import-Configuration {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigFile
    )
    
    if (Test-Path -Path $ConfigFile) {
        try {
            $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Warning "Erreur lors du chargement de la configuration: $_"
        }
    } else {
        Write-Warning "Fichier de configuration non trouvÃ©: $ConfigFile"
        
        # CrÃ©er une configuration par dÃ©faut
        $defaultConfig = @{
            N8nRootFolder = "n8n"
            WorkflowFolder = "n8n/data/.n8n/workflows"
            ReferenceFolder = "n8n/core/workflows/local"
            LogFolder = "n8n/logs"
            DefaultPort = 5678
            DefaultProtocol = "http"
            DefaultHostname = "localhost"
            AutoRestart = $false
            NotificationEnabled = $true
        }
        
        # CrÃ©er le dossier parent s'il n'existe pas
        $configFolder = Split-Path -Path $ConfigFile -Parent
        if (-not (Test-Path -Path $configFolder)) {
            New-Item -Path $configFolder -ItemType Directory -Force | Out-Null
        }
        
        # Enregistrer la configuration par dÃ©faut
        $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFile -Encoding UTF8
        
        return $defaultConfig
    }
}

# Charger la configuration
$config = Import-Configuration -ConfigFile $ConfigFile

#endregion

#region Fonctions d'interface utilisateur

# Fonction pour afficher le menu principal
function Show-MainMenu {
    Clear-Host
    Write-Host "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Cyan
    Write-Host "â•‘           n8n Manager v1.0           â•‘" -ForegroundColor Cyan
    Write-Host "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Gestion du cycle de vie:" -ForegroundColor Yellow
    Write-Host "  1. DÃ©marrer n8n"
    Write-Host "  2. ArrÃªter n8n"
    Write-Host "  3. RedÃ©marrer n8n"
    Write-Host ""
    Write-Host "Surveillance et diagnostics:" -ForegroundColor Yellow
    Write-Host "  4. VÃ©rifier l'Ã©tat de n8n"
    Write-Host "  5. Afficher le tableau de bord"
    Write-Host "  6. Tester la structure"
    Write-Host ""
    Write-Host "Gestion des workflows:" -ForegroundColor Yellow
    Write-Host "  7. Importer des workflows"
    Write-Host "  8. Importer des workflows en masse"
    Write-Host "  9. VÃ©rifier la prÃ©sence des workflows"
    Write-Host ""
    Write-Host "Maintenance:" -ForegroundColor Yellow
    Write-Host "  M. ExÃ©cuter la maintenance"
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Yellow
    Write-Host "  C. Configurer n8n Manager"
    Write-Host ""
    Write-Host "  0. Quitter"
    Write-Host ""
    Write-Host "Statut actuel:" -ForegroundColor Magenta
    
    # VÃ©rifier si n8n est en cours d'exÃ©cution
    $pidFile = Join-Path -Path $config.N8nRootFolder -ChildPath "data/n8n.pid"
    if (Test-Path -Path $pidFile) {
        $pid = Get-Content -Path $pidFile
        $process = Get-Process -Id $pid -ErrorAction SilentlyContinue
        
        if ($null -ne $process) {
            Write-Host "  n8n est en cours d'exÃ©cution (PID: $pid)" -ForegroundColor Green
        } else {
            Write-Host "  n8n n'est pas en cours d'exÃ©cution (PID invalide: $pid)" -ForegroundColor Red
        }
    } else {
        Write-Host "  n8n n'est pas en cours d'exÃ©cution" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Fonction pour afficher le menu de configuration
function Show-ConfigMenu {
    Clear-Host
    Write-Host "â•”â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•—" -ForegroundColor Cyan
    Write-Host "â•‘       Configuration n8n Manager      â•‘" -ForegroundColor Cyan
    Write-Host "â•šâ•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Configuration actuelle:" -ForegroundColor Yellow
    Write-Host "  1. Dossier racine n8n: $($config.N8nRootFolder)"
    Write-Host "  2. Dossier des workflows: $($config.WorkflowFolder)"
    Write-Host "  3. Dossier de rÃ©fÃ©rence: $($config.ReferenceFolder)"
    Write-Host "  4. Dossier des logs: $($config.LogFolder)"
    Write-Host "  5. Port par dÃ©faut: $($config.DefaultPort)"
    Write-Host "  6. Protocole par dÃ©faut: $($config.DefaultProtocol)"
    Write-Host "  7. HÃ´te par dÃ©faut: $($config.DefaultHostname)"
    Write-Host "  8. RedÃ©marrage automatique: $($config.AutoRestart)"
    Write-Host "  9. Notifications activÃ©es: $($config.NotificationEnabled)"
    Write-Host ""
    Write-Host "  S. Sauvegarder la configuration"
    Write-Host "  R. RÃ©initialiser la configuration"
    Write-Host ""
    Write-Host "  0. Retour au menu principal"
    Write-Host ""
}

# Fonction pour mettre Ã  jour la configuration
function Update-Configuration {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Key,
        
        [Parameter(Mandatory=$true)]
        [object]$Value
    )
    
    $config.$Key = $Value
}

# Fonction pour sauvegarder la configuration
function Save-Configuration {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ConfigFile,
        
        [Parameter(Mandatory=$true)]
        [object]$Config
    )
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFile -Encoding UTF8
        Write-Host "Configuration sauvegardÃ©e avec succÃ¨s." -ForegroundColor Green
        Start-Sleep -Seconds 2
        return $true
    } catch {
        Write-Host "Erreur lors de la sauvegarde de la configuration: $_" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return $false
    }
}

#endregion

#region Fonctions d'exÃ©cution des actions

# Fonction pour exÃ©cuter une action
function Invoke-Action {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Action,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Parameters = @{}
    )
    
    $scriptPath = Get-ScriptPath -ScriptKey $Action
    
    if ($null -eq $scriptPath) {
        Write-Host "Action non reconnue: $Action" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    if (-not (Test-Path -Path $scriptPath)) {
        Write-Host "Script non trouvÃ©: $scriptPath" -ForegroundColor Red
        Start-Sleep -Seconds 2
        return
    }
    
    Write-Host "ExÃ©cution de l'action: $Action" -ForegroundColor Cyan
    Write-Host "Script: $scriptPath" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Construire la commande avec les paramÃ¨tres
        $command = "& `"$scriptPath`""
        
        foreach ($key in $Parameters.Keys) {
            $value = $Parameters[$key]
            
            # GÃ©rer les diffÃ©rents types de valeurs
            if ($value -is [bool]) {
                $command += " -$key `$$value"
            } elseif ($value -is [int] -or $value -is [double]) {
                $command += " -$key $value"
            } else {
                $command += " -$key `"$value`""
            }
        }
        
        # ExÃ©cuter la commande
        Invoke-Expression -Command $command
        
        Write-Host ""
        Write-Host "Action terminÃ©e: $Action" -ForegroundColor Green
        
        if (-not $NoInteractive) {
            Write-Host ""
            Write-Host "Appuyez sur une touche pour continuer..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    } catch {
        Write-Host "Erreur lors de l'exÃ©cution de l'action: $_" -ForegroundColor Red
        
        if (-not $NoInteractive) {
            Write-Host ""
            Write-Host "Appuyez sur une touche pour continuer..."
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
}

# Fonction pour dÃ©marrer n8n
function Start-N8n {
    Invoke-Action -Action "Start"
}

# Fonction pour arrÃªter n8n
function Stop-N8n {
    Invoke-Action -Action "Stop"
}

# Fonction pour redÃ©marrer n8n
function Restart-N8n {
    Invoke-Action -Action "Restart"
}

# Fonction pour vÃ©rifier l'Ã©tat de n8n
function Test-N8nStatus {
    $parameters = @{
        Hostname = $config.DefaultHostname
        Port = $config.DefaultPort
        Protocol = $config.DefaultProtocol
        AutoRestart = $config.AutoRestart
    }
    
    Invoke-Action -Action "Status" -Parameters $parameters
}

# Fonction pour importer des workflows
function Import-Workflows {
    $parameters = @{
        SourceFolder = $config.ReferenceFolder
        TargetFolder = $config.WorkflowFolder
    }
    
    Invoke-Action -Action "Import" -Parameters $parameters
}

# Fonction pour importer des workflows en masse
function Import-WorkflowsBulk {
    $parameters = @{
        SourceFolder = $config.ReferenceFolder
        TargetFolder = $config.WorkflowFolder
        MaxConcurrent = 5
        BatchSize = 10
    }
    
    Invoke-Action -Action "ImportBulk" -Parameters $parameters
}

# Fonction pour vÃ©rifier la prÃ©sence des workflows
function Confirm-Workflows {
    $parameters = @{
        WorkflowFolder = $config.WorkflowFolder
        ReferenceFolder = $config.ReferenceFolder
    }
    
    Invoke-Action -Action "Verify" -Parameters $parameters
}

# Fonction pour tester la structure
function Test-Structure {
    $parameters = @{
        N8nRootFolder = $config.N8nRootFolder
        WorkflowFolder = $config.WorkflowFolder
        LogFolder = $config.LogFolder
    }
    
    Invoke-Action -Action "Test" -Parameters $parameters
}

# Fonction pour afficher le tableau de bord
function Show-Dashboard {
    $parameters = @{
        OpenBrowser = $true
    }
    
    # VÃ©rifier si le script de tableau de bord existe
    $scriptPath = Get-ScriptPath -ScriptKey "Dashboard"
    
    if ($null -eq $scriptPath -or -not (Test-Path -Path $scriptPath)) {
        Write-Host "Le script de tableau de bord n'est pas encore implÃ©mentÃ©." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }
    
    Invoke-Action -Action "Dashboard" -Parameters $parameters
}

# Fonction pour exÃ©cuter la maintenance
function Invoke-Maintenance {
    # VÃ©rifier si le script de maintenance existe
    $scriptPath = Get-ScriptPath -ScriptKey "Maintenance"
    
    if ($null -eq $scriptPath -or -not (Test-Path -Path $scriptPath)) {
        Write-Host "Le script de maintenance n'est pas encore implÃ©mentÃ©." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
        return
    }
    
    Invoke-Action -Action "Maintenance"
}

#endregion

#region Boucle principale

# ExÃ©cuter une action directement si spÃ©cifiÃ©e
if (-not [string]::IsNullOrEmpty($Action)) {
    switch ($Action.ToLower()) {
        "start" { Start-N8n }
        "stop" { Stop-N8n }
        "restart" { Restart-N8n }
        "status" { Test-N8nStatus }
        "import" { Import-Workflows }
        "verify" { Confirm-Workflows }
        "test" { Test-Structure }
        "dashboard" { Show-Dashboard }
        "maintenance" { Invoke-Maintenance }
        default { Write-Host "Action non reconnue: $Action" -ForegroundColor Red }
    }
    
    exit
}

# Quitter si mode non interactif
if ($NoInteractive) {
    exit
}

# Boucle principale du menu
$continue = $true
$inConfigMenu = $false

while ($continue) {
    if ($inConfigMenu) {
        Show-ConfigMenu
        $choice = Read-Host "Entrez votre choix"
        
        switch ($choice) {
            "1" {
                $newValue = Read-Host "Entrez le nouveau dossier racine n8n"
                Update-Configuration -Key "N8nRootFolder" -Value $newValue
            }
            "2" {
                $newValue = Read-Host "Entrez le nouveau dossier des workflows"
                Update-Configuration -Key "WorkflowFolder" -Value $newValue
            }
            "3" {
                $newValue = Read-Host "Entrez le nouveau dossier de rÃ©fÃ©rence"
                Update-Configuration -Key "ReferenceFolder" -Value $newValue
            }
            "4" {
                $newValue = Read-Host "Entrez le nouveau dossier des logs"
                Update-Configuration -Key "LogFolder" -Value $newValue
            }
            "5" {
                $newValue = Read-Host "Entrez le nouveau port par dÃ©faut"
                if ($newValue -match '^\d+$') {
                    Update-Configuration -Key "DefaultPort" -Value ([int]$newValue)
                } else {
                    Write-Host "Valeur invalide. Le port doit Ãªtre un nombre." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
            }
            "6" {
                $newValue = Read-Host "Entrez le nouveau protocole par dÃ©faut (http ou https)"
                if ($newValue -eq "http" -or $newValue -eq "https") {
                    Update-Configuration -Key "DefaultProtocol" -Value $newValue
                } else {
                    Write-Host "Valeur invalide. Le protocole doit Ãªtre http ou https." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
            }
            "7" {
                $newValue = Read-Host "Entrez le nouvel hÃ´te par dÃ©faut"
                Update-Configuration -Key "DefaultHostname" -Value $newValue
            }
            "8" {
                $newValue = Read-Host "Activer le redÃ©marrage automatique? (true ou false)"
                if ($newValue -eq "true" -or $newValue -eq "false") {
                    Update-Configuration -Key "AutoRestart" -Value ($newValue -eq "true")
                } else {
                    Write-Host "Valeur invalide. Utilisez true ou false." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
            }
            "9" {
                $newValue = Read-Host "Activer les notifications? (true ou false)"
                if ($newValue -eq "true" -or $newValue -eq "false") {
                    Update-Configuration -Key "NotificationEnabled" -Value ($newValue -eq "true")
                } else {
                    Write-Host "Valeur invalide. Utilisez true ou false." -ForegroundColor Red
                    Start-Sleep -Seconds 2
                }
            }
            "s" {
                Save-Configuration -ConfigFile $ConfigFile -Config $config
            }
            "r" {
                $config = Import-Configuration -ConfigFile $ConfigFile
                Write-Host "Configuration rÃ©initialisÃ©e." -ForegroundColor Green
                Start-Sleep -Seconds 2
            }
            "0" {
                $inConfigMenu = $false
            }
            default {
                Write-Host "Option invalide" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } else {
        Show-MainMenu
        $choice = Read-Host "Entrez votre choix"
        
        switch ($choice) {
            "1" { Start-N8n }
            "2" { Stop-N8n }
            "3" { Restart-N8n }
            "4" { Test-N8nStatus }
            "5" { Show-Dashboard }
            "6" { Test-Structure }
            "7" { Import-Workflows }
            "8" { Import-WorkflowsBulk }
            "9" { Confirm-Workflows }
            "m" { Invoke-Maintenance }
            "c" { $inConfigMenu = $true }
            "0" { $continue = $false }
            default {
                Write-Host "Option invalide" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

#endregion

