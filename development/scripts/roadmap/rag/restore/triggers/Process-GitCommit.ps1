# Invoke-GitCommit.ps1
# Script pour traiter les commits Git et déclencher les actions appropriées
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$RepositoryPath,
    
    [Parameter(Mandatory = $true)]
    [string]$CommitHash,
    
    [Parameter(Mandatory = $true)]
    [string]$CommitMessage,
    
    [Parameter(Mandatory = $true)]
    [string]$Branch,
    
    [Parameter(Mandatory = $true)]
    [string]$Author,
    
    [Parameter(Mandatory = $true)]
    [string]$ChangedFiles,
    
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

# Fonction pour traiter un commit Git
function Invoke-GitCommit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CommitHash,
        
        [Parameter(Mandatory = $true)]
        [string]$CommitMessage,
        
        [Parameter(Mandatory = $true)]
        [string]$Branch,
        
        [Parameter(Mandatory = $true)]
        [string]$Author,
        
        [Parameter(Mandatory = $true)]
        [string]$ChangedFiles
    )
    
    # Convertir la chaîne de fichiers modifiés en tableau
    $changedFilesArray = $ChangedFiles -split "\s+"
    
    # Créer l'objet d'événement
    $eventData = @{
        RepositoryPath = $RepositoryPath
        CommitHash = $CommitHash
        CommitMessage = $CommitMessage
        Branch = $Branch
        Author = $Author
        ChangedFiles = $changedFilesArray
        Timestamp = (Get-Date).ToString("o")
    }
    
    # Charger les déclencheurs
    $triggers = Get-Triggers
    
    # Filtrer les déclencheurs de type GitCommit qui sont activés
    $gitTriggers = $triggers | Where-Object { $_.type -eq "GitCommit" -and $_.enabled -eq $true }
    
    if ($null -eq $gitTriggers -or $gitTriggers.Count -eq 0) {
        Write-Log "No Git commit triggers found" -Level "Info"
        return $false
    }
    
    Write-Log "Found $($gitTriggers.Count) Git commit triggers" -Level "Info"
    
    # Initialiser le compteur de déclencheurs exécutés
    $triggersExecuted = 0
    
    # Traiter chaque déclencheur
    foreach ($trigger in $gitTriggers) {
        Write-Log "Processing trigger: $($trigger.name)" -Level "Debug"
        
        # Vérifier si le déclencheur a une condition
        if (-not [string]::IsNullOrEmpty($trigger.condition)) {
            # Exécuter la condition
            $conditionResult = Invoke-ScriptBlock -ScriptString $trigger.condition -EventData $eventData
            
            if (-not $conditionResult) {
                Write-Log "Trigger condition not met: $($trigger.name)" -Level "Debug"
                continue
            }
        }
        
        # Vérifier si le déclencheur a une action
        if (-not [string]::IsNullOrEmpty($trigger.action)) {
            # Exécuter l'action
            Write-Log "Executing action for trigger: $($trigger.name)" -Level "Info"
            $actionResult = Invoke-ScriptBlock -ScriptString $trigger.action -EventData $eventData
            
            if ($actionResult) {
                Write-Log "Action executed successfully for trigger: $($trigger.name)" -Level "Info"
                $triggersExecuted++
            } else {
                Write-Log "Action failed for trigger: $($trigger.name)" -Level "Warning"
            }
        } else {
            Write-Log "No action defined for trigger: $($trigger.name)" -Level "Warning"
        }
    }
    
    Write-Log "Executed $triggersExecuted out of $($gitTriggers.Count) Git commit triggers" -Level "Info"
    
    return $triggersExecuted -gt 0
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-GitCommit -RepositoryPath $RepositoryPath -CommitHash $CommitHash -CommitMessage $CommitMessage -Branch $Branch -Author $Author -ChangedFiles $ChangedFiles
}

