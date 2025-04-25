# Module de surveillance pour le Script Manager
# Ce module coordonne la surveillance des scripts
# Author: Script Manager
# Version: 1.0
# Tags: monitoring, scripts, manager

# Importer les sous-modules
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$SubModules = @(
    "ChangeTracker.psm1",
    "HealthDashboard.psm1",
    "AlertSystem.psm1",
    "UsageTracker.psm1"
)

foreach ($Module in $SubModules) {
    $ModulePath = Join-Path -Path $ScriptPath -ChildPath $Module
    if (Test-Path $ModulePath) {
        Import-Module $ModulePath -Force
    } else {
        Write-Warning "Module $Module not found at $ModulePath"
    }
}

function Start-ScriptMonitoring {
    <#
    .SYNOPSIS
        Démarre la surveillance des scripts
    .DESCRIPTION
        Configure et démarre la surveillance des scripts, incluant le suivi des modifications,
        le tableau de bord de santé et le système d'alertes
    .PARAMETER InventoryPath
        Chemin vers le fichier d'inventaire JSON
    .PARAMETER OutputPath
        Chemin où enregistrer les résultats de la surveillance
    .PARAMETER MonitoringInterval
        Intervalle de surveillance en minutes
    .PARAMETER EnableAlerts
        Active le système d'alertes
    .EXAMPLE
        Start-ScriptMonitoring -InventoryPath "data\inventory.json" -OutputPath "monitoring" -MonitoringInterval 60
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$InventoryPath,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath,
        
        [int]$MonitoringInterval = 60,
        
        [switch]$EnableAlerts
    )
    
    # Vérifier si le fichier d'inventaire existe
    if (-not (Test-Path -Path $InventoryPath)) {
        Write-Error "Fichier d'inventaire non trouvé: $InventoryPath"
        return $null
    }
    
    # Charger l'inventaire
    try {
        $Inventory = Get-Content -Path $InventoryPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "Erreur lors du chargement de l'inventaire: $_"
        return $null
    }
    
    Write-Host "Configuration de la surveillance des scripts..." -ForegroundColor Cyan
    Write-Host "Nombre de scripts à surveiller: $($Inventory.TotalScripts)" -ForegroundColor Cyan
    Write-Host "Intervalle de surveillance: $MonitoringInterval minutes" -ForegroundColor Cyan
    Write-Host "Alertes: $(if ($EnableAlerts) { 'Activées' } else { 'Désactivées' })" -ForegroundColor Cyan
    
    # Créer le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Initialiser le suivi des modifications
    $ChangeTracker = Initialize-ChangeTracker -Inventory $Inventory -OutputPath $OutputPath
    
    # Initialiser le tableau de bord de santé
    $HealthDashboard = Initialize-HealthDashboard -Inventory $Inventory -OutputPath $OutputPath
    
    # Initialiser le système d'alertes si activé
    $AlertSystem = $null
    if ($EnableAlerts) {
        $AlertSystem = Initialize-AlertSystem -Inventory $Inventory -OutputPath $OutputPath
    }
    
    # Initialiser le suivi d'utilisation
    $UsageTracker = Initialize-UsageTracker -Inventory $Inventory -OutputPath $OutputPath
    
    # Créer un objet avec les informations de surveillance
    $Monitoring = [PSCustomObject]@{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalScripts = $Inventory.TotalScripts
        MonitoringInterval = $MonitoringInterval
        EnableAlerts = $EnableAlerts
        ChangeTracker = $ChangeTracker
        HealthDashboard = $HealthDashboard
        AlertSystem = $AlertSystem
        UsageTracker = $UsageTracker
    }
    
    # Convertir l'objet en JSON et l'enregistrer dans un fichier
    $MonitoringPath = Join-Path -Path $OutputPath -ChildPath "monitoring.json"
    $Monitoring | ConvertTo-Json -Depth 10 | Set-Content -Path $MonitoringPath
    
    Write-Host "Surveillance configurée. Informations enregistrées dans: $MonitoringPath" -ForegroundColor Green
    
    # Créer une tâche planifiée pour la surveillance continue
    if ($MonitoringInterval -gt 0) {
        $TaskName = "ScriptManager_Monitoring"
        $TaskPath = "\Script Manager\"
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Update-Monitoring.ps1"
        
        # Vérifier si la tâche existe déjà
        $TaskExists = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
        
        if ($TaskExists) {
            # Mettre à jour la tâche existante
            $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -InventoryPath `"$InventoryPath`" -OutputPath `"$OutputPath`" -EnableAlerts:`$$EnableAlerts"
            $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $MonitoringInterval)
            Set-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $Action -Trigger $Trigger
            Write-Host "Tâche planifiée mise à jour: $TaskPath$TaskName" -ForegroundColor Green
        } else {
            # Créer une nouvelle tâche
            try {
                $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -InventoryPath `"$InventoryPath`" -OutputPath `"$OutputPath`" -EnableAlerts:`$$EnableAlerts"
                $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $MonitoringInterval)
                $Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
                
                # Créer le dossier de tâches s'il n'existe pas
                if (-not (Get-ScheduledTaskFolder -TaskPath $TaskPath -ErrorAction SilentlyContinue)) {
                    Register-ScheduledTaskFolder -TaskPath $TaskPath
                }
                
                Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $Action -Trigger $Trigger -Settings $Settings -Description "Surveillance des scripts par le Script Manager"
                Write-Host "Tâche planifiée créée: $TaskPath$TaskName" -ForegroundColor Green
            } catch {
                Write-Warning "Erreur lors de la création de la tâche planifiée: $_"
                Write-Host "Vous devrez exécuter manuellement le script de surveillance: $ScriptPath" -ForegroundColor Yellow
            }
        }
    }
    
    return $Monitoring
}

function Get-ScheduledTaskFolder {
    <#
    .SYNOPSIS
        Vérifie si un dossier de tâches planifiées existe
    .DESCRIPTION
        Vérifie si un dossier de tâches planifiées existe dans le planificateur de tâches
    .PARAMETER TaskPath
        Chemin du dossier de tâches
    .EXAMPLE
        Get-ScheduledTaskFolder -TaskPath "\Script Manager\"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TaskPath
    )
    
    try {
        $Schedule = New-Object -ComObject Schedule.Service
        $Schedule.Connect()
        $Root = $Schedule.GetFolder("\")
        
        # Supprimer les barres obliques au début et à la fin
        $FolderPath = $TaskPath.Trim("\")
        
        # Si le chemin est vide, c'est le dossier racine
        if ([string]::IsNullOrEmpty($FolderPath)) {
            return $Root
        }
        
        # Diviser le chemin en segments
        $Segments = $FolderPath -split "\\"
        $CurrentFolder = $Root
        
        foreach ($Segment in $Segments) {
            if (-not [string]::IsNullOrEmpty($Segment)) {
                try {
                    $CurrentFolder = $CurrentFolder.GetFolder($Segment)
                } catch {
                    return $null
                }
            }
        }
        
        return $CurrentFolder
    } catch {
        return $null
    }
}

function Register-ScheduledTaskFolder {
    <#
    .SYNOPSIS
        Crée un dossier de tâches planifiées
    .DESCRIPTION
        Crée un dossier de tâches planifiées dans le planificateur de tâches
    .PARAMETER TaskPath
        Chemin du dossier de tâches à créer
    .EXAMPLE
        Register-ScheduledTaskFolder -TaskPath "\Script Manager\"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$TaskPath
    )
    
    try {
        $Schedule = New-Object -ComObject Schedule.Service
        $Schedule.Connect()
        $Root = $Schedule.GetFolder("\")
        
        # Supprimer les barres obliques au début et à la fin
        $FolderPath = $TaskPath.Trim("\")
        
        # Si le chemin est vide, c'est le dossier racine
        if ([string]::IsNullOrEmpty($FolderPath)) {
            return $Root
        }
        
        # Diviser le chemin en segments
        $Segments = $FolderPath -split "\\"
        $CurrentPath = "\"
        $CurrentFolder = $Root
        
        foreach ($Segment in $Segments) {
            if (-not [string]::IsNullOrEmpty($Segment)) {
                $CurrentPath += "$Segment\"
                
                try {
                    $CurrentFolder = $CurrentFolder.GetFolder($Segment)
                } catch {
                    # Le dossier n'existe pas, le créer
                    $CurrentFolder.CreateFolder($Segment)
                    $CurrentFolder = $CurrentFolder.GetFolder($Segment)
                }
            }
        }
        
        return $CurrentFolder
    } catch {
        Write-Warning "Erreur lors de la création du dossier de tâches: $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Start-ScriptMonitoring, Get-ScheduledTaskFolder, Register-ScheduledTaskFolder
