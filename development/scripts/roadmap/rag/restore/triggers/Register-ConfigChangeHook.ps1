# Register-ConfigChangeHook.ps1
# Script pour enregistrer des hooks de modification de configuration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
    [string]$ConfigType = "All",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Create", "Update", "Delete", "All")]
    [string]$ChangeType = "All",
    
    [Parameter(Mandatory = $false)]
    [string]$HookName,
    
    [Parameter(Mandatory = $false)]
    [string]$Description,
    
    [Parameter(Mandatory = $false)]
    [scriptblock]$Condition,
    
    [Parameter(Mandatory = $false)]
    [scriptblock]$Action,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateRestorePoint = $true,
    
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

# Importer le script d'enregistrement de déclencheur
$registerTriggerPath = Join-Path -Path $scriptPath -ChildPath "Register-RestoreTrigger.ps1"

if (Test-Path -Path $registerTriggerPath) {
    . $registerTriggerPath
} else {
    Write-Log "Required script not found: $registerTriggerPath" -Level "Error"
    exit 1
}

# Fonction pour générer un nom de hook par défaut
function Get-DefaultHookName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$ChangeType
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    return "ConfigHook-$ConfigType-$ChangeType-$timestamp"
}

# Fonction pour créer une action de création de point de restauration
function New-RestorePointAction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$ChangeType
    )
    
    $actionScript = @"
# Action de création de point de restauration
param(`$EventData)

# Importer le script de création de point de restauration
`$scriptPath = Split-Path -Parent `$MyInvocation.MyCommand.Path
`$createRestorePointPath = Join-Path -Path `$scriptPath -ChildPath "..\..\New-RestorePoint.ps1"

if (Test-Path -Path `$createRestorePointPath) {
    . `$createRestorePointPath
} else {
    Write-Host "Required script not found: `$createRestorePointPath" -ForegroundColor Red
    return `$false
}

# Extraire les données de l'événement
`$configType = `$EventData.ConfigType
`$changeType = `$EventData.ChangeType
`$configId = `$EventData.ConfigId
`$configuration = `$EventData.Configuration

# Générer un nom pour le point de restauration
`$restorePointName = "Auto-`$changeType-`$configType-`$configId-`$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Créer le point de restauration
`$result = New-RestorePoint -Name `$restorePointName -Type "automatic" -ConfigType `$configType -ConfigId `$configId -Configuration `$configuration -Tags @("auto", `$changeType.ToLower(), `$configType.ToLower())

return `$result
"@
    
    return [scriptblock]::Create($actionScript)
}

# Fonction pour créer une condition de vérification
function New-VerificationCondition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$ChangeType
    )
    
    $conditionScript = @"
# Condition de vérification
param(`$EventData)

# Vérifier si les données de l'événement sont valides
if (`$null -eq `$EventData) {
    return `$false
}

# Vérifier le type de configuration
if ('$ConfigType' -ne 'All' -and `$EventData.ConfigType -ne '$ConfigType') {
    return `$false
}

# Vérifier le type de changement
if ('$ChangeType' -ne 'All' -and `$EventData.ChangeType -ne '$ChangeType') {
    return `$false
}

# Vérifier si la configuration est valide
if (`$null -eq `$EventData.Configuration) {
    return `$false
}

return `$true
"@
    
    return [scriptblock]::Create($conditionScript)
}

# Fonction pour enregistrer un hook de modification de configuration
function Register-ConfigChangeHook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search", "All")]
        [string]$ConfigType = "All",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Create", "Update", "Delete", "All")]
        [string]$ChangeType = "All",
        
        [Parameter(Mandatory = $false)]
        [string]$HookName,
        
        [Parameter(Mandatory = $false)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$Condition,
        
        [Parameter(Mandatory = $false)]
        [scriptblock]$Action,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateRestorePoint = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$Enabled = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Générer un nom de hook par défaut si non fourni
    if ([string]::IsNullOrEmpty($HookName)) {
        $HookName = Get-DefaultHookName -ConfigType $ConfigType -ChangeType $ChangeType
    }
    
    # Générer une description par défaut si non fournie
    if ([string]::IsNullOrEmpty($Description)) {
        $Description = "Hook for $ChangeType operations on $ConfigType configurations"
    }
    
    # Créer une condition par défaut si non fournie
    if ($null -eq $Condition) {
        $Condition = New-VerificationCondition -ConfigType $ConfigType -ChangeType $ChangeType
    }
    
    # Créer une action par défaut si non fournie et si CreateRestorePoint est activé
    if ($null -eq $Action -and $CreateRestorePoint) {
        $Action = New-RestorePointAction -ConfigType $ConfigType -ChangeType $ChangeType
    }
    
    # Créer les paramètres du déclencheur
    $parameters = @{
        "ConfigType" = $ConfigType
        "ChangeType" = $ChangeType
    }
    
    # Enregistrer le déclencheur
    $result = Register-RestoreTrigger -TriggerType "ConfigChange" -TriggerName $HookName -Description $Description -Parameters $parameters -Condition $Condition -Action $Action -Enabled:$Enabled -Force:$Force
    
    if ($result) {
        Write-Log "Config change hook registered successfully: $HookName" -Level "Info"
        return $true
    } else {
        Write-Log "Failed to register config change hook: $HookName" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Register-ConfigChangeHook -ConfigType $ConfigType -ChangeType $ChangeType -HookName $HookName -Description $Description -Condition $Condition -Action $Action -CreateRestorePoint:$CreateRestorePoint -Enabled:$Enabled -Force:$Force
}
