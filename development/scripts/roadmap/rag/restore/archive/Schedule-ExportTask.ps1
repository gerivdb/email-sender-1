# Schedule-ExportTask.ps1
# Script pour planifier des tâches d'exportation d'archives vers un stockage externe
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Create", "Update", "Remove", "List", "Run")]
    [string]$Action = "List",
    
    [Parameter(Mandatory = $false)]
    [string]$TaskName = "",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Daily", "Weekly", "Monthly", "Once")]
    [string]$Schedule = "Daily",
    
    [Parameter(Mandatory = $false)]
    [string]$Time = "03:00",
    
    [Parameter(Mandatory = $false)]
    [int]$DayOfWeek = 1,
    
    [Parameter(Mandatory = $false)]
    [int]$DayOfMonth = 1,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Local", "Network", "Azure", "AWS", "GCP", "FTP", "SFTP")]
    [string]$StorageType = "Local",
    
    [Parameter(Mandatory = $false)]
    [string]$DestinationPath = "",
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigName = "",
    
    [Parameter(Mandatory = $false)]
    [hashtable]$ConnectionParams = @{},
    
    [Parameter(Mandatory = $false)]
    [switch]$RemoveOriginals,
    
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Importer le script d'exportation
$exportScriptPath = Join-Path -Path $scriptPath -ChildPath "Export-ToExternalStorage.ps1"

if (-not (Test-Path -Path $exportScriptPath)) {
    Write-Log "Required script not found: Export-ToExternalStorage.ps1" -Level "Error"
    exit 1
}

# Fonction pour obtenir le chemin du répertoire des tâches planifiées
function Get-ScheduledTasksPath {
    [CmdletBinding()]
    param()
    
    $tasksPath = Join-Path -Path $parentPath -ChildPath "config\tasks"
    
    if (-not (Test-Path -Path $tasksPath)) {
        New-Item -Path $tasksPath -ItemType Directory -Force | Out-Null
    }
    
    return $tasksPath
}

# Fonction pour obtenir le chemin du fichier de configuration d'une tâche planifiée
function Get-TaskConfigPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )
    
    $tasksPath = Get-ScheduledTasksPath
    return Join-Path -Path $tasksPath -ChildPath "$TaskName.json"
}

# Fonction pour charger la configuration d'une tâche planifiée
function Get-TaskConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )
    
    $configPath = Get-TaskConfigPath -TaskName $TaskName
    
    if (Test-Path -Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "Error loading task configuration: $_" -Level "Error"
            return $null
        }
    } else {
        return $null
    }
}

# Fonction pour sauvegarder la configuration d'une tâche planifiée
function Save-TaskConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Config,
        
        [Parameter(Mandatory = $true)]
        [string]$TaskName
    )
    
    $configPath = Get-TaskConfigPath -TaskName $TaskName
    
    try {
        $Config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding UTF8
        Write-Log "Task configuration saved to: $configPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving task configuration: $_" -Level "Error"
        return $false
    }
}

# Fonction pour créer une tâche planifiée Windows
function New-WindowsScheduledTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $true)]
        [string]$Schedule,
        
        [Parameter(Mandatory = $true)]
        [string]$Time,
        
        [Parameter(Mandatory = $false)]
        [int]$DayOfWeek = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$DayOfMonth = 1,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Vérifier si la tâche existe déjà
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($null -ne $existingTask) {
        Write-Log "Task already exists: $TaskName" -Level "Warning"
        return $false
    }
    
    # Construire le chemin du script PowerShell à exécuter
    $scriptToRun = Join-Path -Path $scriptPath -ChildPath "Schedule-ExportTask.ps1"
    
    # Construire la commande PowerShell
    $action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptToRun`" -Action Run -TaskName `"$TaskName`" -LogLevel Info"
    
    # Créer le déclencheur en fonction du type de planification
    $trigger = $null
    
    switch ($Schedule) {
        "Daily" {
            $trigger = New-ScheduledTaskTrigger -Daily -At $Time
        }
        "Weekly" {
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $Time
        }
        "Monthly" {
            $trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth $DayOfMonth -At $Time
        }
        "Once" {
            $trigger = New-ScheduledTaskTrigger -Once -At $Time
        }
        default {
            Write-Log "Invalid schedule type: $Schedule" -Level "Error"
            return $false
        }
    }
    
    # Créer les paramètres de la tâche
    $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
    
    # Créer la tâche planifiée
    if (-not $WhatIf) {
        try {
            $principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType S4U -RunLevel Highest
            Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal
            
            Write-Log "Scheduled task created: $TaskName" -Level "Info"
            return $true
        } catch {
            Write-Log "Error creating scheduled task: $($_.Exception.Message)" -Level "Error"
            return $false
        }
    } else {
        Write-Log "WhatIf: Would create scheduled task: $TaskName" -Level "Info"
        Write-Log "  Schedule: $Schedule at $Time" -Level "Info"
        Write-Log "  Command: powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$scriptToRun`" -Action Run -TaskName `"$TaskName`" -LogLevel Info" -Level "Info"
        return $true
    }
}

# Fonction pour mettre à jour une tâche planifiée Windows
function Update-WindowsScheduledTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $true)]
        [string]$Schedule,
        
        [Parameter(Mandatory = $true)]
        [string]$Time,
        
        [Parameter(Mandatory = $false)]
        [int]$DayOfWeek = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$DayOfMonth = 1,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Vérifier si la tâche existe
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($null -eq $existingTask) {
        Write-Log "Task does not exist: $TaskName" -Level "Warning"
        return $false
    }
    
    # Créer le déclencheur en fonction du type de planification
    $trigger = $null
    
    switch ($Schedule) {
        "Daily" {
            $trigger = New-ScheduledTaskTrigger -Daily -At $Time
        }
        "Weekly" {
            $trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $DayOfWeek -At $Time
        }
        "Monthly" {
            $trigger = New-ScheduledTaskTrigger -Monthly -DaysOfMonth $DayOfMonth -At $Time
        }
        "Once" {
            $trigger = New-ScheduledTaskTrigger -Once -At $Time
        }
        default {
            Write-Log "Invalid schedule type: $Schedule" -Level "Error"
            return $false
        }
    }
    
    # Mettre à jour la tâche planifiée
    if (-not $WhatIf) {
        try {
            Set-ScheduledTask -TaskName $TaskName -Trigger $trigger
            
            Write-Log "Scheduled task updated: $TaskName" -Level "Info"
            return $true
        } catch {
            Write-Log "Error updating scheduled task: $($_.Exception.Message)" -Level "Error"
            return $false
        }
    } else {
        Write-Log "WhatIf: Would update scheduled task: $TaskName" -Level "Info"
        Write-Log "  New schedule: $Schedule at $Time" -Level "Info"
        return $true
    }
}

# Fonction pour supprimer une tâche planifiée Windows
function Remove-WindowsScheduledTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Vérifier si la tâche existe
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($null -eq $existingTask) {
        Write-Log "Task does not exist: $TaskName" -Level "Warning"
        return $false
    }
    
    # Supprimer la tâche planifiée
    if (-not $WhatIf) {
        try {
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
            
            # Supprimer également le fichier de configuration
            $configPath = Get-TaskConfigPath -TaskName $TaskName
            
            if (Test-Path -Path $configPath) {
                Remove-Item -Path $configPath -Force
            }
            
            Write-Log "Scheduled task removed: $TaskName" -Level "Info"
            return $true
        } catch {
            Write-Log "Error removing scheduled task: $($_.Exception.Message)" -Level "Error"
            return $false
        }
    } else {
        Write-Log "WhatIf: Would remove scheduled task: $TaskName" -Level "Info"
        return $true
    }
}

# Fonction pour lister les tâches planifiées
function Get-ExportTasks {
    [CmdletBinding()]
    param()
    
    $tasksPath = Get-ScheduledTasksPath
    $taskFiles = Get-ChildItem -Path $tasksPath -Filter "*.json"
    $tasks = @()
    
    foreach ($file in $taskFiles) {
        try {
            $taskConfig = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            $taskName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name)
            
            # Vérifier si la tâche Windows existe
            $windowsTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            $status = if ($null -ne $windowsTask) { $windowsTask.State } else { "Not registered" }
            
            $tasks += [PSCustomObject]@{
                Name = $taskName
                Schedule = $taskConfig.schedule.type
                Time = $taskConfig.schedule.time
                StorageType = $taskConfig.export.storage_type
                DestinationPath = $taskConfig.export.destination_path
                Status = $status
                LastRun = $taskConfig.last_run
            }
        } catch {
            Write-Log "Error processing task file $($file.Name): $($_.Exception.Message)" -Level "Warning"
        }
    }
    
    return $tasks
}

# Fonction pour exécuter une tâche d'exportation
function Invoke-ExportTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TaskName,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # Charger la configuration de la tâche
    $taskConfig = Get-TaskConfig -TaskName $TaskName
    
    if ($null -eq $taskConfig) {
        Write-Log "Task configuration not found: $TaskName" -Level "Error"
        return $false
    }
    
    # Importer le script d'exportation
    . $exportScriptPath
    
    # Obtenir les archives à exporter
    $archivesPath = Join-Path -Path $rootPath -ChildPath "archives"
    $archiveFiles = Get-ChildItem -Path $archivesPath -Filter "*.*" -Recurse | Where-Object { $_.Extension -in @(".zip", ".7z", ".tar", ".gz") }
    
    if ($archiveFiles.Count -eq 0) {
        Write-Log "No archives found to export" -Level "Warning"
        return $true
    }
    
    # Filtrer les archives selon les critères de la tâche
    $archivesToExport = @()
    
    if ($taskConfig.PSObject.Properties.Name.Contains("filter")) {
        $filter = $taskConfig.filter
        
        # Filtrer par âge
        if ($filter.PSObject.Properties.Name.Contains("min_age_days") -and $filter.min_age_days -gt 0) {
            $cutoffDate = (Get-Date).AddDays(-$filter.min_age_days)
            $archiveFiles = $archiveFiles | Where-Object { $_.CreationTime -lt $cutoffDate }
        }
        
        # Filtrer par type
        if ($filter.PSObject.Properties.Name.Contains("types") -and $filter.types.Count -gt 0) {
            $archiveFiles = $archiveFiles | Where-Object { $filter.types -contains $_.Extension.TrimStart(".") }
        }
        
        # Filtrer par motif de nom
        if ($filter.PSObject.Properties.Name.Contains("name_patterns") -and $filter.name_patterns.Count -gt 0) {
            $filteredFiles = @()
            
            foreach ($pattern in $filter.name_patterns) {
                $filteredFiles += $archiveFiles | Where-Object { $_.Name -like $pattern }
            }
            
            $archiveFiles = $filteredFiles | Sort-Object -Property FullName -Unique
        }
    }
    
    $archivesToExport = $archiveFiles.FullName
    
    if ($archivesToExport.Count -eq 0) {
        Write-Log "No archives match the filter criteria" -Level "Warning"
        return $true
    }
    
    Write-Log "Found $($archivesToExport.Count) archives to export" -Level "Info"
    
    # Préparer les paramètres d'exportation
    $exportParams = @{
        ArchivePaths = $archivesToExport
        StorageType = $taskConfig.export.storage_type
        DestinationPath = $taskConfig.export.destination_path
        RemoveOriginals = $taskConfig.export.remove_originals
        CreateLogFile = $true
        WhatIf = $WhatIf
    }
    
    # Ajouter les paramètres de connexion
    if ($taskConfig.export.PSObject.Properties.Name.Contains("connection_params")) {
        $connectionParams = @{}
        
        foreach ($prop in $taskConfig.export.connection_params.PSObject.Properties) {
            $connectionParams[$prop.Name] = $prop.Value
        }
        
        $exportParams.ConnectionParams = $connectionParams
    }
    
    # Exécuter l'exportation
    $result = Export-ToExternalStorage @exportParams
    
    # Mettre à jour la date de dernière exécution
    if (-not $WhatIf) {
        $taskConfig.last_run = (Get-Date).ToString("o")
        Save-TaskConfig -Config $taskConfig -TaskName $TaskName
    }
    
    return $result
}

# Fonction principale pour gérer les tâches d'exportation planifiées
function Schedule-ExportTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Create", "Update", "Remove", "List", "Run")]
        [string]$Action = "List",
        
        [Parameter(Mandatory = $false)]
        [string]$TaskName = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Daily", "Weekly", "Monthly", "Once")]
        [string]$Schedule = "Daily",
        
        [Parameter(Mandatory = $false)]
        [string]$Time = "03:00",
        
        [Parameter(Mandatory = $false)]
        [int]$DayOfWeek = 1,
        
        [Parameter(Mandatory = $false)]
        [int]$DayOfMonth = 1,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Local", "Network", "Azure", "AWS", "GCP", "FTP", "SFTP")]
        [string]$StorageType = "Local",
        
        [Parameter(Mandatory = $false)]
        [string]$DestinationPath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ConnectionParams = @{},
        
        [Parameter(Mandatory = $false)]
        [switch]$RemoveOriginals,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    switch ($Action) {
        "Create" {
            # Valider les paramètres
            if ([string]::IsNullOrEmpty($TaskName)) {
                Write-Log "Task name is required" -Level "Error"
                return $false
            }
            
            if ([string]::IsNullOrEmpty($DestinationPath)) {
                Write-Log "Destination path is required" -Level "Error"
                return $false
            }
            
            # Créer la configuration de la tâche
            $taskConfig = @{
                name = $TaskName
                created_at = (Get-Date).ToString("o")
                last_modified = (Get-Date).ToString("o")
                last_run = $null
                schedule = @{
                    type = $Schedule
                    time = $Time
                    day_of_week = $DayOfWeek
                    day_of_month = $DayOfMonth
                }
                export = @{
                    storage_type = $StorageType
                    destination_path = $DestinationPath
                    remove_originals = $RemoveOriginals.IsPresent
                }
                filter = @{
                    min_age_days = 0
                    types = @()
                    name_patterns = @()
                }
            }
            
            # Ajouter les paramètres de connexion
            if ($ConnectionParams.Count -gt 0) {
                $taskConfig.export.connection_params = $ConnectionParams
            } elseif (-not [string]::IsNullOrEmpty($ConfigName)) {
                # Charger les paramètres de connexion depuis la configuration
                $exportScriptPath = Join-Path -Path $scriptPath -ChildPath "Export-ToExternalStorage.ps1"
                . $exportScriptPath
                
                $exportConfig = Get-ExportConfig -ConfigName $ConfigName
                
                if ($null -ne $exportConfig -and $exportConfig.PSObject.Properties.Name.Contains("connection_params")) {
                    $taskConfig.export.connection_params = @{}
                    
                    foreach ($prop in $exportConfig.connection_params.PSObject.Properties) {
                        $taskConfig.export.connection_params[$prop.Name] = $prop.Value
                    }
                }
            }
            
            # Sauvegarder la configuration de la tâche
            $configSaved = Save-TaskConfig -Config $taskConfig -TaskName $TaskName
            
            if (-not $configSaved) {
                return $false
            }
            
            # Créer la tâche planifiée Windows
            return New-WindowsScheduledTask -TaskName $TaskName -Schedule $Schedule -Time $Time -DayOfWeek $DayOfWeek -DayOfMonth $DayOfMonth -WhatIf:$WhatIf
        }
        "Update" {
            # Valider les paramètres
            if ([string]::IsNullOrEmpty($TaskName)) {
                Write-Log "Task name is required" -Level "Error"
                return $false
            }
            
            # Charger la configuration de la tâche
            $taskConfig = Get-TaskConfig -TaskName $TaskName
            
            if ($null -eq $taskConfig) {
                Write-Log "Task configuration not found: $TaskName" -Level "Error"
                return $false
            }
            
            # Mettre à jour la configuration de la tâche
            $taskConfig.last_modified = (Get-Date).ToString("o")
            
            if (-not [string]::IsNullOrEmpty($Schedule)) {
                $taskConfig.schedule.type = $Schedule
            }
            
            if (-not [string]::IsNullOrEmpty($Time)) {
                $taskConfig.schedule.time = $Time
            }
            
            if ($PSBoundParameters.ContainsKey("DayOfWeek")) {
                $taskConfig.schedule.day_of_week = $DayOfWeek
            }
            
            if ($PSBoundParameters.ContainsKey("DayOfMonth")) {
                $taskConfig.schedule.day_of_month = $DayOfMonth
            }
            
            if (-not [string]::IsNullOrEmpty($StorageType)) {
                $taskConfig.export.storage_type = $StorageType
            }
            
            if (-not [string]::IsNullOrEmpty($DestinationPath)) {
                $taskConfig.export.destination_path = $DestinationPath
            }
            
            if ($PSBoundParameters.ContainsKey("RemoveOriginals")) {
                $taskConfig.export.remove_originals = $RemoveOriginals.IsPresent
            }
            
            # Mettre à jour les paramètres de connexion
            if ($ConnectionParams.Count -gt 0) {
                $taskConfig.export.connection_params = $ConnectionParams
            } elseif (-not [string]::IsNullOrEmpty($ConfigName)) {
                # Charger les paramètres de connexion depuis la configuration
                $exportScriptPath = Join-Path -Path $scriptPath -ChildPath "Export-ToExternalStorage.ps1"
                . $exportScriptPath
                
                $exportConfig = Get-ExportConfig -ConfigName $ConfigName
                
                if ($null -ne $exportConfig -and $exportConfig.PSObject.Properties.Name.Contains("connection_params")) {
                    $taskConfig.export.connection_params = @{}
                    
                    foreach ($prop in $exportConfig.connection_params.PSObject.Properties) {
                        $taskConfig.export.connection_params[$prop.Name] = $prop.Value
                    }
                }
            }
            
            # Sauvegarder la configuration de la tâche
            $configSaved = Save-TaskConfig -Config $taskConfig -TaskName $TaskName
            
            if (-not $configSaved) {
                return $false
            }
            
            # Mettre à jour la tâche planifiée Windows
            return Update-WindowsScheduledTask -TaskName $TaskName -Schedule $taskConfig.schedule.type -Time $taskConfig.schedule.time -DayOfWeek $taskConfig.schedule.day_of_week -DayOfMonth $taskConfig.schedule.day_of_month -WhatIf:$WhatIf
        }
        "Remove" {
            # Valider les paramètres
            if ([string]::IsNullOrEmpty($TaskName)) {
                Write-Log "Task name is required" -Level "Error"
                return $false
            }
            
            # Supprimer la tâche planifiée Windows
            return Remove-WindowsScheduledTask -TaskName $TaskName -WhatIf:$WhatIf
        }
        "List" {
            # Lister les tâches planifiées
            $tasks = Get-ExportTasks
            
            if ($tasks.Count -eq 0) {
                Write-Log "No export tasks found" -Level "Info"
            } else {
                Write-Log "Export tasks:" -Level "Info"
                
                foreach ($task in $tasks) {
                    Write-Log "  - $($task.Name) ($($task.Schedule) at $($task.Time)): $($task.StorageType) -> $($task.DestinationPath) [$($task.Status)]" -Level "Info"
                }
            }
            
            return $tasks
        }
        "Run" {
            # Valider les paramètres
            if ([string]::IsNullOrEmpty($TaskName)) {
                Write-Log "Task name is required" -Level "Error"
                return $false
            }
            
            # Exécuter la tâche d'exportation
            return Invoke-ExportTask -TaskName $TaskName -WhatIf:$WhatIf
        }
        default {
            Write-Log "Invalid action: $Action" -Level "Error"
            return $false
        }
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Schedule-ExportTask -Action $Action -TaskName $TaskName -Schedule $Schedule -Time $Time -DayOfWeek $DayOfWeek -DayOfMonth $DayOfMonth -StorageType $StorageType -DestinationPath $DestinationPath -ConfigName $ConfigName -ConnectionParams $ConnectionParams -RemoveOriginals:$RemoveOriginals -WhatIf:$WhatIf
}
