# Register-RestoreTrigger.ps1
# Script pour enregistrer des déclencheurs de points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("ConfigChange", "GitCommit", "SystemUpdate", "DataMigration", "BulkOperation", "Custom")]
    [string]$TriggerType = "ConfigChange",
    
    [Parameter(Mandatory = $false)]
    [string]$TriggerName,
    
    [Parameter(Mandatory = $false)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [hashtable]$Parameters = @{},
    
    [Parameter(Mandatory = $false)]
    [scriptblock]$Condition,
    
    [Parameter(Mandatory = $false)]
    [scriptblock]$Action,
    
    [Parameter(Mandatory = $false)]
    [switch]$Enabled = $true,
    
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

# Fonction pour générer un nom de déclencheur par défaut
function Get-DefaultTriggerName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TriggerType
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    return "$TriggerType-$timestamp"
}

# Fonction pour valider les paramètres du déclencheur
function Test-TriggerParameters {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TriggerType,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Parameters
    )
    
    $valid = $true
    $requiredParams = @{}
    
    # Définir les paramètres requis pour chaque type de déclencheur
    switch ($TriggerType) {
        "ConfigChange" {
            $requiredParams = @{
                "ConfigType" = @("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")
                "ChangeType" = @("Create", "Update", "Delete", "All")
            }
        }
        "GitCommit" {
            $requiredParams = @{
                "RepositoryPath" = $null
                "Branch" = $null
            }
        }
        "SystemUpdate" {
            $requiredParams = @{
                "UpdateType" = @("Minor", "Major", "Patch", "All")
            }
        }
        "DataMigration" {
            $requiredParams = @{
                "SourceType" = $null
                "TargetType" = $null
            }
        }
        "BulkOperation" {
            $requiredParams = @{
                "OperationType" = @("Import", "Export", "Delete", "Update", "All")
                "ThresholdCount" = $null
            }
        }
        "Custom" {
            # Aucun paramètre requis pour les déclencheurs personnalisés
        }
    }
    
    # Vérifier les paramètres requis
    foreach ($param in $requiredParams.Keys) {
        if (-not $Parameters.ContainsKey($param)) {
            Write-Log "Missing required parameter for $TriggerType trigger: $param" -Level "Error"
            $valid = $false
        } elseif ($null -ne $requiredParams[$param] -and $requiredParams[$param] -is [array]) {
            # Vérifier si la valeur est dans la liste des valeurs autorisées
            if ($Parameters[$param] -ne "All" -and $Parameters[$param] -notin $requiredParams[$param]) {
                Write-Log "Invalid value for parameter $param: $($Parameters[$param]). Allowed values: $($requiredParams[$param] -join ', ') or 'All'" -Level "Error"
                $valid = $false
            }
        }
    }
    
    return $valid
}

# Fonction pour obtenir le chemin du fichier de configuration des déclencheurs
function Get-TriggersConfigPath {
    [CmdletBinding()]
    param()
    
    $configPath = Join-Path -Path $parentPath -ChildPath "config"
    
    if (-not (Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    }
    
    $triggersPath = Join-Path -Path $configPath -ChildPath "triggers"
    
    if (-not (Test-Path -Path $triggersPath)) {
        New-Item -Path $triggersPath -ItemType Directory -Force | Out-Null
    }
    
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

# Fonction pour sauvegarder les déclencheurs
function Save-Triggers {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Triggers
    )
    
    $triggersPath = Get-TriggersConfigPath
    
    try {
        $Triggers | ConvertTo-Json -Depth 10 | Out-File -FilePath $triggersPath -Encoding UTF8
        Write-Log "Triggers saved to: $triggersPath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error saving triggers: $_" -Level "Error"
        return $false
    }
}

# Fonction pour enregistrer un déclencheur
function Register-RestoreTrigger {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("ConfigChange", "GitCommit", "SystemUpdate", "DataMigration", "BulkOperation", "Custom")]
        [string]$TriggerType = "ConfigChange",
        
        [Parameter(Mandatory = $false)]
        [string]$TriggerName,
        
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Parameters = @{},
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$Condition,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$Action,
        
        [Parameter(Mandatory = $false)]
        [switch]$Enabled = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Générer un nom de déclencheur par défaut si non fourni
    if ([string]::IsNullOrEmpty($TriggerName)) {
        $TriggerName = Get-DefaultTriggerName -TriggerType $TriggerType
    }
    
    # Valider les paramètres du déclencheur
    if (-not (Test-TriggerParameters -TriggerType $TriggerType -Parameters $Parameters)) {
        Write-Log "Invalid trigger parameters" -Level "Error"
        return $false
    }
    
    # Charger les déclencheurs existants
    $triggers = Get-Triggers
    
    # Vérifier si le déclencheur existe déjà
    $existingTrigger = $triggers | Where-Object { $_.name -eq $TriggerName }
    
    if ($null -ne $existingTrigger -and -not $Force) {
        Write-Log "Trigger already exists: $TriggerName. Use -Force to overwrite." -Level "Warning"
        return $false
    }
    
    # Convertir les scriptblocks en chaînes
    $conditionString = if ($null -ne $Condition) { $Condition.ToString() } else { $null }
    $actionString = if ($null -ne $Action) { $Action.ToString() } else { $null }
    
    # Créer le nouveau déclencheur
    $newTrigger = @{
        name = $TriggerName
        type = $TriggerType
        description = $Description
        parameters = $Parameters
        condition = $conditionString
        action = $actionString
        enabled = $Enabled
        created_at = (Get-Date).ToString("o")
        last_modified = (Get-Date).ToString("o")
    }
    
    # Mettre à jour ou ajouter le déclencheur
    if ($null -ne $existingTrigger) {
        # Mettre à jour le déclencheur existant
        $triggerIndex = [array]::IndexOf($triggers, $existingTrigger)
        $triggers[$triggerIndex] = $newTrigger
    } else {
        # Ajouter le nouveau déclencheur
        $triggers += $newTrigger
    }
    
    # Sauvegarder les déclencheurs
    $result = Save-Triggers -Triggers $triggers
    
    if ($result) {
        Write-Log "Trigger registered successfully: $TriggerName" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to register trigger: $TriggerName" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Register-RestoreTrigger -TriggerType $TriggerType -TriggerName $TriggerName -Description $Description -Parameters $Parameters -Condition $Condition -Action $Action -Enabled:$Enabled -Force:$Force
}
