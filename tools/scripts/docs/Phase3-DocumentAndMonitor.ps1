<#
.SYNOPSIS
    Phase 3 du Script Manager - Documentation et surveillance
.DESCRIPTION
    Ce script exÃ©cute la Phase 3 du Script Manager, qui comprend la gÃ©nÃ©ration
    de documentation automatique et la mise en place d'un systÃ¨me de surveillance
    des scripts.
.PARAMETER InventoryPath
    Chemin vers le fichier d'inventaire (par dÃ©faut : ..\D)
.PARAMETER AnalysisPath
    Chemin vers le fichier d'analyse (par dÃ©faut : scripts\manager\data\analysis_advanced.json)
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer la documentation et les donnÃ©es de surveillance (par dÃ©faut : scripts\manager\docs)
.PARAMETER MonitoringInterval
    Intervalle de surveillance en minutes (par dÃ©faut : 60)
.PARAMETER EnableAlerts
    Active le systÃ¨me d'alertes
.PARAMETER IncludeExamples
    Inclut des exemples d'utilisation dans la documentation
.EXAMPLE
    .\Phase3-DocumentAndMonitor.ps1
    ExÃ©cute la Phase 3 avec les paramÃ¨tres par dÃ©faut
.EXAMPLE
    .\Phase3-DocumentAndMonitor.ps1 -EnableAlerts -IncludeExamples
    ExÃ©cute la Phase 3 avec les alertes activÃ©es et des exemples inclus
#>

param (
    [string]$InventoryPath = "..\D",
    [string]$AnalysisPath = "scripts\manager\data\analysis_advanced.json",
    [string]$OutputPath = "scripts\manager\docs",
    [int]$MonitoringInterval = 60,
    [switch]$EnableAlerts,
    [switch]$IncludeExamples
)

# VÃ©rifier si l'inventaire et l'analyse existent
if (-not (Test-Path -Path $InventoryPath)) {
    Write-Host "Inventaire non trouvÃ©. Veuillez d'abord exÃ©cuter la Phase 1 (Inventory-Scripts.ps1)." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path $AnalysisPath)) {
    Write-Host "Analyse non trouvÃ©e. Veuillez d'abord exÃ©cuter la Phase 2 (Phase2-AnalyzeAndOrganize.ps1)." -ForegroundColor Red
    exit 1
}

# DÃ©finir les chemins des modules
$ModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$DocumentationModulePath = Join-Path -Path $ModulesPath -ChildPath "Documentation\DocumentationModule.psm1"
$MonitoringModulePath = Join-Path -Path $ModulesPath -ChildPath "Monitoring\MonitoringModule.psm1"

# VÃ©rifier si les modules existent
if (-not (Test-Path -Path $DocumentationModulePath)) {
    Write-Host "Module de documentation non trouvÃ©: $DocumentationModulePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path $MonitoringModulePath)) {
    Write-Host "Module de surveillance non trouvÃ©: $MonitoringModulePath" -ForegroundColor Red
    exit 1
}

# Importer les modules
Import-Module $DocumentationModulePath -Force
Import-Module $MonitoringModulePath -Force

# DÃ©finir les chemins de sortie
$DocsPath = Join-Path -Path $OutputPath -ChildPath "documentation"
$MonitoringPath = Join-Path -Path $OutputPath -ChildPath "monitoring"

# CrÃ©er les dossiers de sortie s'ils n'existent pas
if (-not (Test-Path -Path $DocsPath)) {
    New-Item -ItemType Directory -Path $DocsPath -Force | Out-Null
}

if (-not (Test-Path -Path $MonitoringPath)) {
    New-Item -ItemType Directory -Path $MonitoringPath -Force | Out-Null
}

# Afficher la banniÃ¨re
Write-Host "=== Phase 3: Documentation et surveillance ===" -ForegroundColor Cyan
Write-Host "Inventaire: $InventoryPath" -ForegroundColor Yellow
Write-Host "Analyse: $AnalysisPath" -ForegroundColor Yellow
Write-Host "Documentation: $DocsPath" -ForegroundColor Yellow
Write-Host "Surveillance: $MonitoringPath" -ForegroundColor Yellow
Write-Host "Intervalle de surveillance: $MonitoringInterval minutes" -ForegroundColor Yellow
Write-Host "Alertes: $(if ($EnableAlerts) { 'ActivÃ©es' } else { 'DÃ©sactivÃ©es' })" -ForegroundColor Yellow
Write-Host "Exemples: $(if ($IncludeExamples) { 'Inclus' } else { 'Non inclus' })" -ForegroundColor Yellow
Write-Host ""

# Charger l'inventaire et l'analyse
try {
    $Inventory = Get-Content -Path $InventoryPath -Raw | ConvertFrom-Json
    $Analysis = Get-Content -Path $AnalysisPath -Raw | ConvertFrom-Json
} catch {
    Write-Host "Erreur lors du chargement des fichiers: $_" -ForegroundColor Red
    exit 1
}

# Ã‰tape 1: GÃ©nÃ©ration de la documentation
Write-Host "Ã‰tape 1: GÃ©nÃ©ration de la documentation" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host ""

$Documentation = Invoke-ScriptDocumentation -AnalysisPath $AnalysisPath -OutputPath $DocsPath -IncludeExamples:$IncludeExamples

if ($null -eq $Documentation) {
    Write-Host "Erreur lors de la gÃ©nÃ©ration de la documentation." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Documentation gÃ©nÃ©rÃ©e. RÃ©sultats enregistrÃ©s dans: $DocsPath" -ForegroundColor Green
Write-Host "Nombre de scripts documentÃ©s: $($Documentation.TotalScripts)" -ForegroundColor Cyan
Write-Host "README gÃ©nÃ©rÃ©s pour $($Documentation.FolderReadmes.Count) dossiers" -ForegroundColor Cyan
Write-Host "Documentation gÃ©nÃ©rÃ©e pour $($Documentation.ScriptDocs.Count) scripts" -ForegroundColor Cyan
Write-Host ""

# Ã‰tape 2: Configuration de la surveillance
Write-Host "Ã‰tape 2: Configuration de la surveillance" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host ""

$Monitoring = Start-ScriptMonitoring -InventoryPath $InventoryPath -OutputPath $MonitoringPath -MonitoringInterval $MonitoringInterval -EnableAlerts:$EnableAlerts

if ($null -eq $Monitoring) {
    Write-Host "Erreur lors de la configuration de la surveillance." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Surveillance configurÃ©e. RÃ©sultats enregistrÃ©s dans: $MonitoringPath" -ForegroundColor Green
Write-Host "Nombre de scripts surveillÃ©s: $($Monitoring.TotalScripts)" -ForegroundColor Cyan
Write-Host "Intervalle de surveillance: $($Monitoring.MonitoringInterval) minutes" -ForegroundColor Cyan
Write-Host "Alertes: $(if ($Monitoring.EnableAlerts) { 'ActivÃ©es' } else { 'DÃ©sactivÃ©es' })" -ForegroundColor Cyan
Write-Host ""

# CrÃ©er le script de mise Ã  jour de la surveillance
$UpdateScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Update-Monitoring.ps1"
$UpdateScriptContent = @"
<#
.SYNOPSIS
    Met Ã  jour la surveillance des scripts
.DESCRIPTION
    Met Ã  jour le tableau de bord de santÃ© et vÃ©rifie les modifications des scripts
.PARAMETER InventoryPath
    Chemin vers le fichier d'inventaire
.PARAMETER OutputPath
    Chemin oÃ¹ sont enregistrÃ©es les donnÃ©es de surveillance
.PARAMETER EnableAlerts
    Active le systÃ¨me d'alertes
.EXAMPLE
    .\Update-Monitoring.ps1 -InventoryPath "..\D" -OutputPath "scripts\manager\docs\monitoring" -EnableAlerts
#>

param (
    [string]`$InventoryPath = "..\D",
    [string]`$OutputPath = "scripts\manager\docs\monitoring",
    [switch]`$EnableAlerts
)

# VÃ©rifier si l'inventaire existe
if (-not (Test-Path -Path `$InventoryPath)) {
    Write-Error "Inventaire non trouvÃ©: `$InventoryPath"
    exit 1
}

# DÃ©finir les chemins des modules
`$ModulesPath = Join-Path -Path `$PSScriptRoot -ChildPath "modules"
`$MonitoringModulePath = Join-Path -Path `$ModulesPath -ChildPath "Monitoring\MonitoringModule.psm1"

# VÃ©rifier si le module existe
if (-not (Test-Path -Path `$MonitoringModulePath)) {
    Write-Error "Module de surveillance non trouvÃ©: `$MonitoringModulePath"
    exit 1
}

# Importer le module
Import-Module `$MonitoringModulePath -Force

# Charger l'inventaire
try {
    `$Inventory = Get-Content -Path `$InventoryPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement de l'inventaire: `$_"
    exit 1
}

# Mettre Ã  jour le tableau de bord
`$DashboardPath = Join-Path -Path `$OutputPath -ChildPath "dashboard"
`$DashboardDataPath = Join-Path -Path `$DashboardPath -ChildPath "dashboard_data.json"
`$UpdateScriptPath = Join-Path -Path `$DashboardPath -ChildPath "Update-Dashboard.ps1"

if (Test-Path -Path `$UpdateScriptPath) {
    Write-Host "Mise Ã  jour du tableau de bord..." -ForegroundColor Cyan
    & `$UpdateScriptPath -InventoryPath `$InventoryPath -DashboardDataPath `$DashboardDataPath
}

# VÃ©rifier les modifications
`$ChangesPath = Join-Path -Path `$OutputPath -ChildPath "changes"
`$SnapshotPath = Join-Path -Path `$ChangesPath -ChildPath "initial_snapshot.json"
`$HistoryPath = Join-Path -Path `$ChangesPath -ChildPath "changes_history.json"

if (Test-Path -Path `$SnapshotPath -and Test-Path -Path `$HistoryPath) {
    Write-Host "VÃ©rification des modifications..." -ForegroundColor Cyan
    
    # CrÃ©er un nouvel instantanÃ©
    `$TempSnapshotPath = Join-Path -Path `$ChangesPath -ChildPath "temp_snapshot.json"
    `$Snapshot = @()
    
    foreach (`$Script in `$Inventory.Scripts) {
        # Calculer le hash du fichier
        `$FileHash = Get-FileHash -Path `$Script.Path -Algorithm SHA256 -ErrorAction SilentlyContinue
        
        if (`$FileHash) {
            `$Snapshot += [PSCustomObject]@{
                Path = `$Script.Path
                Name = `$Script.Name
                Type = `$Script.Type
                Hash = `$FileHash.Hash
                LastWriteTime = (Get-Item -Path `$Script.Path).LastWriteTime
                Size = (Get-Item -Path `$Script.Path).Length
                SnapshotTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
        }
    }
    
    # Enregistrer l'instantanÃ© temporaire
    `$Snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path `$TempSnapshotPath
    
    # Comparer les instantanÃ©s
    `$Comparison = Compare-ScriptSnapshots -SnapshotPath1 `$SnapshotPath -SnapshotPath2 `$TempSnapshotPath
    
    # Mettre Ã  jour l'historique des modifications
    if (`$Comparison.Modified.Count -gt 0 -or `$Comparison.Added.Count -gt 0 -or `$Comparison.Removed.Count -gt 0) {
        Write-Host "Modifications dÃ©tectÃ©es:" -ForegroundColor Yellow
        Write-Host "  Scripts modifiÃ©s: `$(`$Comparison.Modified.Count)" -ForegroundColor Yellow
        Write-Host "  Scripts ajoutÃ©s: `$(`$Comparison.Added.Count)" -ForegroundColor Yellow
        Write-Host "  Scripts supprimÃ©s: `$(`$Comparison.Removed.Count)" -ForegroundColor Yellow
        
        # Charger l'historique
        try {
            `$History = Get-Content -Path `$HistoryPath -Raw | ConvertFrom-Json
        } catch {
            Write-Error "Erreur lors du chargement de l'historique: `$_"
            exit 1
        }
        
        # Ajouter les modifications Ã  l'historique
        foreach (`$Script in `$Comparison.Modified) {
            `$Change = [PSCustomObject]@{
                Path = `$Script.Path
                Name = `$Script.Name
                Type = `$Script.Type
                ChangeType = "Modified"
                Details = "Hash changed from `$(`$Script.OldHash) to `$(`$Script.NewHash)"
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            
            `$History.Changes += `$Change
            
            # Envoyer une alerte si activÃ©
            if (`$EnableAlerts) {
                `$AlertsPath = Join-Path -Path `$OutputPath -ChildPath "alerts"
                `$AlertScriptPath = Join-Path -Path `$AlertsPath -ChildPath "Send-Alert.ps1"
                `$AlertConfigPath = Join-Path -Path `$AlertsPath -ChildPath "alert_config.json"
                `$AlertHistoryPath = Join-Path -Path `$AlertsPath -ChildPath "alert_history.json"
                
                if (Test-Path -Path `$AlertScriptPath) {
                    & `$AlertScriptPath -AlertName "Script modifiÃ©" -Level "Info" -Message "Le script a Ã©tÃ© modifiÃ©" -ScriptPath `$Script.Path -ConfigPath `$AlertConfigPath -HistoryPath `$AlertHistoryPath
                }
            }
        }
        
        foreach (`$Script in `$Comparison.Added) {
            `$Change = [PSCustomObject]@{
                Path = `$Script.Path
                Name = `$Script.Name
                Type = `$Script.Type
                ChangeType = "Added"
                Details = "Script added"
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            
            `$History.Changes += `$Change
            
            # Envoyer une alerte si activÃ©
            if (`$EnableAlerts) {
                `$AlertsPath = Join-Path -Path `$OutputPath -ChildPath "alerts"
                `$AlertScriptPath = Join-Path -Path `$AlertsPath -ChildPath "Send-Alert.ps1"
                `$AlertConfigPath = Join-Path -Path `$AlertsPath -ChildPath "alert_config.json"
                `$AlertHistoryPath = Join-Path -Path `$AlertsPath -ChildPath "alert_history.json"
                
                if (Test-Path -Path `$AlertScriptPath) {
                    & `$AlertScriptPath -AlertName "Script ajoutÃ©" -Level "Info" -Message "Un nouveau script a Ã©tÃ© ajoutÃ©" -ScriptPath `$Script.Path -ConfigPath `$AlertConfigPath -HistoryPath `$AlertHistoryPath
                }
            }
        }
        
        foreach (`$Script in `$Comparison.Removed) {
            `$Change = [PSCustomObject]@{
                Path = `$Script.Path
                Name = `$Script.Name
                Type = `$Script.Type
                ChangeType = "Removed"
                Details = "Script removed"
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            }
            
            `$History.Changes += `$Change
            
            # Envoyer une alerte si activÃ©
            if (`$EnableAlerts) {
                `$AlertsPath = Join-Path -Path `$OutputPath -ChildPath "alerts"
                `$AlertScriptPath = Join-Path -Path `$AlertsPath -ChildPath "Send-Alert.ps1"
                `$AlertConfigPath = Join-Path -Path `$AlertsPath -ChildPath "alert_config.json"
                `$AlertHistoryPath = Join-Path -Path `$AlertsPath -ChildPath "alert_history.json"
                
                if (Test-Path -Path `$AlertScriptPath) {
                    & `$AlertScriptPath -AlertName "Script supprimÃ©" -Level "Error" -Message "Le script a Ã©tÃ© supprimÃ©" -ScriptPath `$Script.Path -ConfigPath `$AlertConfigPath -HistoryPath `$AlertHistoryPath
                }
            }
        }
        
        # Mettre Ã  jour la date de derniÃ¨re mise Ã  jour
        `$History.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Enregistrer l'historique mis Ã  jour
        `$History | ConvertTo-Json -Depth 10 | Set-Content -Path `$HistoryPath
        
        # Remplacer l'instantanÃ© initial par le nouvel instantanÃ©
        Copy-Item -Path `$TempSnapshotPath -Destination `$SnapshotPath -Force
    } else {
        Write-Host "Aucune modification dÃ©tectÃ©e" -ForegroundColor Green
    }
    
    # Supprimer l'instantanÃ© temporaire
    Remove-Item -Path `$TempSnapshotPath -Force
}

Write-Host "Surveillance mise Ã  jour avec succÃ¨s!" -ForegroundColor Green
"@

Set-Content -Path $UpdateScriptPath -Value $UpdateScriptContent

Write-Host "Script de mise Ã  jour de la surveillance crÃ©Ã©: $UpdateScriptPath" -ForegroundColor Green
Write-Host ""

# RÃ©sumÃ©
Write-Host "=== RÃ©sumÃ© de la Phase 3 ===" -ForegroundColor Cyan
Write-Host "Documentation: $($Documentation.TotalScripts) scripts documentÃ©s" -ForegroundColor Cyan
Write-Host "Surveillance: $($Monitoring.TotalScripts) scripts surveillÃ©s" -ForegroundColor Cyan
Write-Host ""

Write-Host "Pour mettre Ã  jour la surveillance manuellement, exÃ©cutez la commande suivante:" -ForegroundColor Yellow
Write-Host ".\Update-Monitoring.ps1 -InventoryPath `"$InventoryPath`" -OutputPath `"$MonitoringPath`" -EnableAlerts:`$$EnableAlerts" -ForegroundColor Cyan
Write-Host ""

Write-Host "Pour ouvrir le tableau de bord de santÃ©, ouvrez le fichier suivant dans votre navigateur:" -ForegroundColor Yellow
Write-Host "$($Monitoring.HealthDashboard.DashboardHtmlPath)" -ForegroundColor Cyan
Write-Host ""

Write-Host "Phase 3 terminÃ©e avec succÃ¨s!" -ForegroundColor Green

