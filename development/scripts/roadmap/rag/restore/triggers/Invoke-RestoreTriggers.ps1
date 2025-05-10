# Invoke-RestoreTriggers.ps1
# Script pour invoquer les déclencheurs de points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("ConfigChange", "GitCommit", "SystemUpdate", "DataMigration", "BulkOperation", "Custom")]
    [string]$EventType,
    
    [Parameter(Mandatory = $true)]
    [hashtable]$EventData,
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
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

# Fonction pour obtenir le chemin du fichier de configuration des déclencheurs
function Get-TriggersConfigPath {
    [CmdletBinding()]
    param()
    
    $configPath = Join-Path -Path $parentPath -ChildPath "config"
    $triggersPath = Join-Path -Path $configPath -ChildPath "triggers"
    return Join-Path -Path $triggersPath -ChildPath "triggers.json"
}

# Fonction pour charger les déclencheurs existants
function Get-Triggers {
    [CmdletBinding()]
    param()
    
    $triggersPath = Get-TriggersConfigPath
    
    if (Test-Path -Path $triggersPath) {
        try {
            $triggers = Get-Content -Path $triggersPath -Raw | ConvertFrom-Json
            return $triggers
        } catch {
            Write-Log "Error loading triggers: $_" -Level "Error"
            return @()
        }
    } else {
        return @()
    }
}

# Fonction pour exécuter un scriptblock à partir d'une chaîne
function Invoke-ScriptBlock {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptString,
        
        [Parameter(Mandatory = $true)]
        [object]$EventData
    )
    
    try {
        $scriptBlock = [scriptblock]::Create($ScriptString)
        return & $scriptBlock $EventData
    } catch {
        Write-Log "Error executing script: $_" -Level "Error"
        return $false
    }
}

# Fonction pour journaliser l'exécution d'un déclencheur
function Write-TriggerLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TriggerName,
        
        [Parameter(Mandatory = $true)]
        [string]$EventType,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$EventData,
        
        [Parameter(Mandatory = $false)]
        [bool]$Success = $true,
        
        [Parameter(Mandatory = $false)]
        [string]$ErrorMessage = ""
    )
    
    # Créer le répertoire de journalisation s'il n'existe pas
    $logPath = Join-Path -Path $parentPath -ChildPath "logs"
    
    if (-not (Test-Path -Path $logPath)) {
        New-Item -Path $logPath -ItemType Directory -Force | Out-Null
    }
    
    # Générer le nom du fichier de journal
    $logFileName = "trigger_log_$(Get-Date -Format 'yyyyMMdd').json"
    $logFilePath = Join-Path -Path $logPath -ChildPath $logFileName
    
    # Créer l'entrée de journal
    $logEntry = @{
        timestamp = (Get-Date).ToString("o")
        trigger_name = $TriggerName
        event_type = $EventType
        event_data = $EventData
        success = $Success
        error_message = $ErrorMessage
    }
    
    # Charger le journal existant ou créer un nouveau
    if (Test-Path -Path $logFilePath) {
        try {
            $log = Get-Content -Path $logFilePath -Raw | ConvertFrom-Json
        } catch {
            $log = @()
        }
    } else {
        $log = @()
    }
    
    # Ajouter l'entrée au journal
    $log += $logEntry
    
    # Sauvegarder le journal
    try {
        $log | ConvertTo-Json -Depth 10 | Out-File -FilePath $logFilePath -Encoding UTF8
    } catch {
        Write-Log "Error writing trigger log: $_" -Level "Error"
    }
}

# Fonction pour invoquer les déclencheurs
function Invoke-RestoreTriggers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("ConfigChange", "GitCommit", "SystemUpdate", "DataMigration", "BulkOperation", "Custom")]
        [string]$EventType,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$EventData,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Ajouter le type d'événement aux données d'événement
    $EventData["EventType"] = $EventType
    
    # Charger les déclencheurs
    $triggers = Get-Triggers
    
    # Filtrer les déclencheurs par type d'événement et état activé
    $filteredTriggers = $triggers | Where-Object { $_.type -eq $EventType -and $_.enabled -eq $true }
    
    if ($null -eq $filteredTriggers -or $filteredTriggers.Count -eq 0) {
        Write-Log "No triggers found for event type: $EventType" -Level "Info"
        return $false
    }
    
    Write-Log "Found $($filteredTriggers.Count) triggers for event type: $EventType" -Level "Info"
    
    # Initialiser le compteur de déclencheurs exécutés
    $triggersExecuted = 0
    
    # Traiter chaque déclencheur
    foreach ($trigger in $filteredTriggers) {
        Write-Log "Processing trigger: $($trigger.name)" -Level "Debug"
        
        # Vérifier si le déclencheur a une condition
        if (-not [string]::IsNullOrEmpty($trigger.condition)) {
            # Exécuter la condition
            $conditionResult = Invoke-ScriptBlock -ScriptString $trigger.condition -EventData $EventData
            
            if (-not $conditionResult) {
                Write-Log "Trigger condition not met: $($trigger.name)" -Level "Debug"
                continue
            }
        }
        
        # Vérifier si le déclencheur a une action
        if (-not [string]::IsNullOrEmpty($trigger.action)) {
            # Exécuter l'action
            Write-Log "Executing action for trigger: $($trigger.name)" -Level "Info"
            
            try {
                $actionResult = Invoke-ScriptBlock -ScriptString $trigger.action -EventData $EventData
                
                if ($actionResult) {
                    Write-Log "Action executed successfully for trigger: $($trigger.name)" -Level "Info"
                    $triggersExecuted++
                    
                    # Journaliser l'exécution réussie
                    Write-TriggerLog -TriggerName $trigger.name -EventType $EventType -EventData $EventData -Success $true
                } else {
                    Write-Log "Action failed for trigger: $($trigger.name)" -Level "Warning"
                    
                    # Journaliser l'échec
                    Write-TriggerLog -TriggerName $trigger.name -EventType $EventType -EventData $EventData -Success $false -ErrorMessage "Action returned false"
                }
            } catch {
                Write-Log "Error executing action for trigger: $($trigger.name): $_" -Level "Error"
                
                # Journaliser l'erreur
                Write-TriggerLog -TriggerName $trigger.name -EventType $EventType -EventData $EventData -Success $false -ErrorMessage $_.ToString()
            }
        } else {
            Write-Log "No action defined for trigger: $($trigger.name)" -Level "Warning"
        }
    }
    
    Write-Log "Executed $triggersExecuted out of $($filteredTriggers.Count) triggers for event type: $EventType" -Level "Info"
    
    return $triggersExecuted -gt 0
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-RestoreTriggers -EventType $EventType -EventData $EventData -Force:$Force
}
