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
        DÃ©marre la surveillance des scripts
    .DESCRIPTION
        Configure et dÃ©marre la surveillance des scripts, incluant le suivi des modifications,
        le tableau de bord de santÃ© et le systÃ¨me d'alertes
    .PARAMETER InventoryPath
        Chemin vers le fichier d'inventaire JSON
    .PARAMETER OutputPath
        Chemin oÃ¹ enregistrer les rÃ©sultats de la surveillance
    .PARAMETER MonitoringInterval
        Intervalle de surveillance en minutes
    .PARAMETER EnableAlerts
        Active le systÃ¨me d'alertes
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
    
    # VÃ©rifier si le fichier d'inventaire existe
    if (-not (Test-Path -Path $InventoryPath)) {
        Write-Error "Fichier d'inventaire non trouvÃ©: $InventoryPath"
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
    Write-Host "Nombre de scripts Ã  surveiller: $($Inventory.TotalScripts)" -ForegroundColor Cyan
    Write-Host "Intervalle de surveillance: $MonitoringInterval minutes" -ForegroundColor Cyan
    Write-Host "Alertes: $(if ($EnableAlerts) { 'ActivÃ©es' } else { 'DÃ©sactivÃ©es' })" -ForegroundColor Cyan
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    if (-not (Test-Path -Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
    }
    
    # Initialiser le suivi des modifications
    $ChangeTracker = Initialize-ChangeTracker -Inventory $Inventory -OutputPath $OutputPath
    
    # Initialiser le tableau de bord de santÃ©
    $HealthDashboard = Initialize-HealthDashboard -Inventory $Inventory -OutputPath $OutputPath
    
    # Initialiser le systÃ¨me d'alertes si activÃ©
    $AlertSystem = $null
    if ($EnableAlerts) {
        $AlertSystem = Initialize-AlertSystem -Inventory $Inventory -OutputPath $OutputPath
    }
    
    # Initialiser le suivi d'utilisation
    $UsageTracker = Initialize-UsageTracker -Inventory $Inventory -OutputPath $OutputPath
    
    # CrÃ©er un objet avec les informations de surveillance
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
    
    Write-Host "Surveillance configurÃ©e. Informations enregistrÃ©es dans: $MonitoringPath" -ForegroundColor Green
    
    # CrÃ©er une tÃ¢che planifiÃ©e pour la surveillance continue
    if ($MonitoringInterval -gt 0) {
        $TaskName = "ScriptManager_Monitoring"
        $TaskPath = "\Script Manager\"
        $ScriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\Update-Monitoring.ps1"
        
        # VÃ©rifier si la tÃ¢che existe dÃ©jÃ 
        $TaskExists = Get-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -ErrorAction SilentlyContinue
        
        if ($TaskExists) {
            # Mettre Ã  jour la tÃ¢che existante
            $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -InventoryPath `"$InventoryPath`" -OutputPath `"$OutputPath`" -EnableAlerts:`$$EnableAlerts"
            $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $MonitoringInterval)
            Set-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $Action -Trigger $Trigger
            Write-Host "TÃ¢che planifiÃ©e mise Ã  jour: $TaskPath$TaskName" -ForegroundColor Green
        } else {
            # CrÃ©er une nouvelle tÃ¢che
            try {
                $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`" -InventoryPath `"$InventoryPath`" -OutputPath `"$OutputPath`" -EnableAlerts:`$$EnableAlerts"
                $Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes $MonitoringInterval)
                $Settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries
                
                # CrÃ©er le dossier de tÃ¢ches s'il n'existe pas
                if (-not (Get-ScheduledTaskFolder -TaskPath $TaskPath -ErrorAction SilentlyContinue)) {
                    Register-ScheduledTaskFolder -TaskPath $TaskPath
                }
                
                Register-ScheduledTask -TaskName $TaskName -TaskPath $TaskPath -Action $Action -Trigger $Trigger -Settings $Settings -Description "Surveillance des scripts par le Script Manager"
                Write-Host "TÃ¢che planifiÃ©e crÃ©Ã©e: $TaskPath$TaskName" -ForegroundColor Green
            } catch {
                Write-Warning "Erreur lors de la crÃ©ation de la tÃ¢che planifiÃ©e: $_"
                Write-Host "Vous devrez exÃ©cuter manuellement le script de surveillance: $ScriptPath" -ForegroundColor Yellow
            }
        }
    }
    
    return $Monitoring
}

function Get-ScheduledTaskFolder {
    <#
    .SYNOPSIS
        VÃ©rifie si un dossier de tÃ¢ches planifiÃ©es existe
    .DESCRIPTION
        VÃ©rifie si un dossier de tÃ¢ches planifiÃ©es existe dans le planificateur de tÃ¢ches
    .PARAMETER TaskPath
        Chemin du dossier de tÃ¢ches
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
        
        # Supprimer les barres obliques au dÃ©but et Ã  la fin
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
        CrÃ©e un dossier de tÃ¢ches planifiÃ©es
    .DESCRIPTION
        CrÃ©e un dossier de tÃ¢ches planifiÃ©es dans le planificateur de tÃ¢ches
    .PARAMETER TaskPath
        Chemin du dossier de tÃ¢ches Ã  crÃ©er
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
        
        # Supprimer les barres obliques au dÃ©but et Ã  la fin
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
                    # Le dossier n'existe pas, le crÃ©er
                    $CurrentFolder.CreateFolder($Segment)
                    $CurrentFolder = $CurrentFolder.GetFolder($Segment)
                }
            }
        }
        
        return $CurrentFolder
    } catch {
        Write-Warning "Erreur lors de la crÃ©ation du dossier de tÃ¢ches: $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Start-ScriptMonitoring, Get-ScheduledTaskFolder, Register-ScheduledTaskFolder
