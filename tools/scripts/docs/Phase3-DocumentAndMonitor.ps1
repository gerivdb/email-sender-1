<#
.SYNOPSIS
    Phase 3 du Script Manager - Documentation et surveillance
.DESCRIPTION
    Ce script exécute la Phase 3 du Script Manager, qui comprend la génération
    de documentation automatique et la mise en place d'un système de surveillance
    des scripts.
.PARAMETER InventoryPath
    Chemin vers le fichier d'inventaire (par défaut : ..\D)
.PARAMETER AnalysisPath
    Chemin vers le fichier d'analyse (par défaut : scripts\manager\data\analysis_advanced.json)
.PARAMETER OutputPath
    Chemin où enregistrer la documentation et les données de surveillance (par défaut : scripts\manager\docs)
.PARAMETER MonitoringInterval
    Intervalle de surveillance en minutes (par défaut : 60)
.PARAMETER EnableAlerts
    Active le système d'alertes
.PARAMETER IncludeExamples
    Inclut des exemples d'utilisation dans la documentation
.EXAMPLE
    .\Phase3-DocumentAndMonitor.ps1
    Exécute la Phase 3 avec les paramètres par défaut
.EXAMPLE
    .\Phase3-DocumentAndMonitor.ps1 -EnableAlerts -IncludeExamples
    Exécute la Phase 3 avec les alertes activées et des exemples inclus
#>

param (
    [string]$InventoryPath = "..\D",
    [string]$AnalysisPath = "scripts\manager\data\analysis_advanced.json",
    [string]$OutputPath = "scripts\manager\docs",
    [int]$MonitoringInterval = 60,
    [switch]$EnableAlerts,
    [switch]$IncludeExamples
)

# Vérifier si l'inventaire et l'analyse existent
if (-not (Test-Path -Path $InventoryPath)) {
    Write-Host "Inventaire non trouvé. Veuillez d'abord exécuter la Phase 1 (Inventory-Scripts.ps1)." -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path $AnalysisPath)) {
    Write-Host "Analyse non trouvée. Veuillez d'abord exécuter la Phase 2 (Phase2-AnalyzeAndOrganize.ps1)." -ForegroundColor Red
    exit 1
}

# Définir les chemins des modules
$ModulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$DocumentationModulePath = Join-Path -Path $ModulesPath -ChildPath "Documentation\DocumentationModule.psm1"
$MonitoringModulePath = Join-Path -Path $ModulesPath -ChildPath "Monitoring\MonitoringModule.psm1"

# Vérifier si les modules existent
if (-not (Test-Path -Path $DocumentationModulePath)) {
    Write-Host "Module de documentation non trouvé: $DocumentationModulePath" -ForegroundColor Red
    exit 1
}

if (-not (Test-Path -Path $MonitoringModulePath)) {
    Write-Host "Module de surveillance non trouvé: $MonitoringModulePath" -ForegroundColor Red
    exit 1
}

# Importer les modules
Import-Module $DocumentationModulePath -Force
Import-Module $MonitoringModulePath -Force

# Définir les chemins de sortie
$DocsPath = Join-Path -Path $OutputPath -ChildPath "documentation"
$MonitoringPath = Join-Path -Path $OutputPath -ChildPath "monitoring"

# Créer les dossiers de sortie s'ils n'existent pas
if (-not (Test-Path -Path $DocsPath)) {
    New-Item -ItemType Directory -Path $DocsPath -Force | Out-Null
}

if (-not (Test-Path -Path $MonitoringPath)) {
    New-Item -ItemType Directory -Path $MonitoringPath -Force | Out-Null
}

# Afficher la bannière
Write-Host "=== Phase 3: Documentation et surveillance ===" -ForegroundColor Cyan
Write-Host "Inventaire: $InventoryPath" -ForegroundColor Yellow
Write-Host "Analyse: $AnalysisPath" -ForegroundColor Yellow
Write-Host "Documentation: $DocsPath" -ForegroundColor Yellow
Write-Host "Surveillance: $MonitoringPath" -ForegroundColor Yellow
Write-Host "Intervalle de surveillance: $MonitoringInterval minutes" -ForegroundColor Yellow
Write-Host "Alertes: $(if ($EnableAlerts) { 'Activées' } else { 'Désactivées' })" -ForegroundColor Yellow
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

# Étape 1: Génération de la documentation
Write-Host "Étape 1: Génération de la documentation" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host ""

$Documentation = Invoke-ScriptDocumentation -AnalysisPath $AnalysisPath -OutputPath $DocsPath -IncludeExamples:$IncludeExamples

if ($null -eq $Documentation) {
    Write-Host "Erreur lors de la génération de la documentation." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Documentation générée. Résultats enregistrés dans: $DocsPath" -ForegroundColor Green
Write-Host "Nombre de scripts documentés: $($Documentation.TotalScripts)" -ForegroundColor Cyan
Write-Host "README générés pour $($Documentation.FolderReadmes.Count) dossiers" -ForegroundColor Cyan
Write-Host "Documentation générée pour $($Documentation.ScriptDocs.Count) scripts" -ForegroundColor Cyan
Write-Host ""

# Étape 2: Configuration de la surveillance
Write-Host "Étape 2: Configuration de la surveillance" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host ""

$Monitoring = Start-ScriptMonitoring -InventoryPath $InventoryPath -OutputPath $MonitoringPath -MonitoringInterval $MonitoringInterval -EnableAlerts:$EnableAlerts

if ($null -eq $Monitoring) {
    Write-Host "Erreur lors de la configuration de la surveillance." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Surveillance configurée. Résultats enregistrés dans: $MonitoringPath" -ForegroundColor Green
Write-Host "Nombre de scripts surveillés: $($Monitoring.TotalScripts)" -ForegroundColor Cyan
Write-Host "Intervalle de surveillance: $($Monitoring.MonitoringInterval) minutes" -ForegroundColor Cyan
Write-Host "Alertes: $(if ($Monitoring.EnableAlerts) { 'Activées' } else { 'Désactivées' })" -ForegroundColor Cyan
Write-Host ""

# Créer le script de mise à jour de la surveillance
$UpdateScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "Update-Monitoring.ps1"
$UpdateScriptContent = @"
<#
.SYNOPSIS
    Met à jour la surveillance des scripts
.DESCRIPTION
    Met à jour le tableau de bord de santé et vérifie les modifications des scripts
.PARAMETER InventoryPath
    Chemin vers le fichier d'inventaire
.PARAMETER OutputPath
    Chemin où sont enregistrées les données de surveillance
.PARAMETER EnableAlerts
    Active le système d'alertes
.EXAMPLE
    .\Update-Monitoring.ps1 -InventoryPath "..\D" -OutputPath "scripts\manager\docs\monitoring" -EnableAlerts
#>

param (
    [string]`$InventoryPath = "..\D",
    [string]`$OutputPath = "scripts\manager\docs\monitoring",
    [switch]`$EnableAlerts
)

# Vérifier si l'inventaire existe
if (-not (Test-Path -Path `$InventoryPath)) {
    Write-Error "Inventaire non trouvé: `$InventoryPath"
    exit 1
}

# Définir les chemins des modules
`$ModulesPath = Join-Path -Path `$PSScriptRoot -ChildPath "modules"
`$MonitoringModulePath = Join-Path -Path `$ModulesPath -ChildPath "Monitoring\MonitoringModule.psm1"

# Vérifier si le module existe
if (-not (Test-Path -Path `$MonitoringModulePath)) {
    Write-Error "Module de surveillance non trouvé: `$MonitoringModulePath"
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

# Mettre à jour le tableau de bord
`$DashboardPath = Join-Path -Path `$OutputPath -ChildPath "dashboard"
`$DashboardDataPath = Join-Path -Path `$DashboardPath -ChildPath "dashboard_data.json"
`$UpdateScriptPath = Join-Path -Path `$DashboardPath -ChildPath "Update-Dashboard.ps1"

if (Test-Path -Path `$UpdateScriptPath) {
    Write-Host "Mise à jour du tableau de bord..." -ForegroundColor Cyan
    & `$UpdateScriptPath -InventoryPath `$InventoryPath -DashboardDataPath `$DashboardDataPath
}

# Vérifier les modifications
`$ChangesPath = Join-Path -Path `$OutputPath -ChildPath "changes"
`$SnapshotPath = Join-Path -Path `$ChangesPath -ChildPath "initial_snapshot.json"
`$HistoryPath = Join-Path -Path `$ChangesPath -ChildPath "changes_history.json"

if (Test-Path -Path `$SnapshotPath -and Test-Path -Path `$HistoryPath) {
    Write-Host "Vérification des modifications..." -ForegroundColor Cyan
    
    # Créer un nouvel instantané
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
    
    # Enregistrer l'instantané temporaire
    `$Snapshot | ConvertTo-Json -Depth 10 | Set-Content -Path `$TempSnapshotPath
    
    # Comparer les instantanés
    `$Comparison = Compare-ScriptSnapshots -SnapshotPath1 `$SnapshotPath -SnapshotPath2 `$TempSnapshotPath
    
    # Mettre à jour l'historique des modifications
    if (`$Comparison.Modified.Count -gt 0 -or `$Comparison.Added.Count -gt 0 -or `$Comparison.Removed.Count -gt 0) {
        Write-Host "Modifications détectées:" -ForegroundColor Yellow
        Write-Host "  Scripts modifiés: `$(`$Comparison.Modified.Count)" -ForegroundColor Yellow
        Write-Host "  Scripts ajoutés: `$(`$Comparison.Added.Count)" -ForegroundColor Yellow
        Write-Host "  Scripts supprimés: `$(`$Comparison.Removed.Count)" -ForegroundColor Yellow
        
        # Charger l'historique
        try {
            `$History = Get-Content -Path `$HistoryPath -Raw | ConvertFrom-Json
        } catch {
            Write-Error "Erreur lors du chargement de l'historique: `$_"
            exit 1
        }
        
        # Ajouter les modifications à l'historique
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
            
            # Envoyer une alerte si activé
            if (`$EnableAlerts) {
                `$AlertsPath = Join-Path -Path `$OutputPath -ChildPath "alerts"
                `$AlertScriptPath = Join-Path -Path `$AlertsPath -ChildPath "Send-Alert.ps1"
                `$AlertConfigPath = Join-Path -Path `$AlertsPath -ChildPath "alert_config.json"
                `$AlertHistoryPath = Join-Path -Path `$AlertsPath -ChildPath "alert_history.json"
                
                if (Test-Path -Path `$AlertScriptPath) {
                    & `$AlertScriptPath -AlertName "Script modifié" -Level "Info" -Message "Le script a été modifié" -ScriptPath `$Script.Path -ConfigPath `$AlertConfigPath -HistoryPath `$AlertHistoryPath
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
            
            # Envoyer une alerte si activé
            if (`$EnableAlerts) {
                `$AlertsPath = Join-Path -Path `$OutputPath -ChildPath "alerts"
                `$AlertScriptPath = Join-Path -Path `$AlertsPath -ChildPath "Send-Alert.ps1"
                `$AlertConfigPath = Join-Path -Path `$AlertsPath -ChildPath "alert_config.json"
                `$AlertHistoryPath = Join-Path -Path `$AlertsPath -ChildPath "alert_history.json"
                
                if (Test-Path -Path `$AlertScriptPath) {
                    & `$AlertScriptPath -AlertName "Script ajouté" -Level "Info" -Message "Un nouveau script a été ajouté" -ScriptPath `$Script.Path -ConfigPath `$AlertConfigPath -HistoryPath `$AlertHistoryPath
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
            
            # Envoyer une alerte si activé
            if (`$EnableAlerts) {
                `$AlertsPath = Join-Path -Path `$OutputPath -ChildPath "alerts"
                `$AlertScriptPath = Join-Path -Path `$AlertsPath -ChildPath "Send-Alert.ps1"
                `$AlertConfigPath = Join-Path -Path `$AlertsPath -ChildPath "alert_config.json"
                `$AlertHistoryPath = Join-Path -Path `$AlertsPath -ChildPath "alert_history.json"
                
                if (Test-Path -Path `$AlertScriptPath) {
                    & `$AlertScriptPath -AlertName "Script supprimé" -Level "Error" -Message "Le script a été supprimé" -ScriptPath `$Script.Path -ConfigPath `$AlertConfigPath -HistoryPath `$AlertHistoryPath
                }
            }
        }
        
        # Mettre à jour la date de dernière mise à jour
        `$History.LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Enregistrer l'historique mis à jour
        `$History | ConvertTo-Json -Depth 10 | Set-Content -Path `$HistoryPath
        
        # Remplacer l'instantané initial par le nouvel instantané
        Copy-Item -Path `$TempSnapshotPath -Destination `$SnapshotPath -Force
    } else {
        Write-Host "Aucune modification détectée" -ForegroundColor Green
    }
    
    # Supprimer l'instantané temporaire
    Remove-Item -Path `$TempSnapshotPath -Force
}

Write-Host "Surveillance mise à jour avec succès!" -ForegroundColor Green
"@

Set-Content -Path $UpdateScriptPath -Value $UpdateScriptContent

Write-Host "Script de mise à jour de la surveillance créé: $UpdateScriptPath" -ForegroundColor Green
Write-Host ""

# Résumé
Write-Host "=== Résumé de la Phase 3 ===" -ForegroundColor Cyan
Write-Host "Documentation: $($Documentation.TotalScripts) scripts documentés" -ForegroundColor Cyan
Write-Host "Surveillance: $($Monitoring.TotalScripts) scripts surveillés" -ForegroundColor Cyan
Write-Host ""

Write-Host "Pour mettre à jour la surveillance manuellement, exécutez la commande suivante:" -ForegroundColor Yellow
Write-Host ".\Update-Monitoring.ps1 -InventoryPath `"$InventoryPath`" -OutputPath `"$MonitoringPath`" -EnableAlerts:`$$EnableAlerts" -ForegroundColor Cyan
Write-Host ""

Write-Host "Pour ouvrir le tableau de bord de santé, ouvrez le fichier suivant dans votre navigateur:" -ForegroundColor Yellow
Write-Host "$($Monitoring.HealthDashboard.DashboardHtmlPath)" -ForegroundColor Cyan
Write-Host ""

Write-Host "Phase 3 terminée avec succès!" -ForegroundColor Green

