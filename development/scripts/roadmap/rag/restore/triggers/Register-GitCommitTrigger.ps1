# Register-GitCommitTrigger.ps1
# Script pour enregistrer des déclencheurs de commits Git
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RepositoryPath,
    
    [Parameter(Mandatory = $false)]
    [string]$Branch = "main",
    
    [Parameter(Mandatory = $false)]
    [string]$FilePattern = "*",
    
    [Parameter(Mandatory = $false)]
    [string]$CommitMessagePattern = "",
    
    [Parameter(Mandatory = $false)]
    [string]$TriggerName,
    
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

# Fonction pour générer un nom de déclencheur par défaut
function Get-DefaultTriggerName {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Branch,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePattern
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $branchShort = $Branch -replace "[^a-zA-Z0-9]", ""
    $patternShort = $FilePattern -replace "[^a-zA-Z0-9]", ""
    
    if ($patternShort.Length -gt 10) {
        $patternShort = $patternShort.Substring(0, 10)
    }
    
    return "GitTrigger-$branchShort-$patternShort-$timestamp"
}

# Fonction pour créer une action de création de point de restauration
function New-RestorePointAction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $true)]
        [string]$Branch
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
`$repositoryPath = `$EventData.RepositoryPath
`$branch = `$EventData.Branch
`$commitHash = `$EventData.CommitHash
`$commitMessage = `$EventData.CommitMessage
`$author = `$EventData.Author
`$changedFiles = `$EventData.ChangedFiles

# Générer un nom pour le point de restauration
`$shortHash = `$commitHash.Substring(0, 7)
`$restorePointName = "Git-`$branch-`$shortHash-`$(Get-Date -Format 'yyyyMMdd_HHmmss')"

# Créer le point de restauration
`$result = New-RestorePoint -Name `$restorePointName -Type "git_commit" -Tags @("git", `$branch) -Description `$commitMessage -GitInfo @{
    commit_hash = `$commitHash
    branch = `$branch
    commit_message = `$commitMessage
    author = `$author
    changed_files = `$changedFiles
}

return `$result
"@
    
    return [scriptblock]::Create($actionScript)
}

# Fonction pour créer une condition de vérification
function New-VerificationCondition {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Branch,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePattern,
        
        [Parameter(Mandatory = $false)]
        [string]$CommitMessagePattern = ""
    )
    
    $conditionScript = @"
# Condition de vérification
param(`$EventData)

# Vérifier si les données de l'événement sont valides
if (`$null -eq `$EventData) {
    return `$false
}

# Vérifier la branche
if ('$Branch' -ne '*' -and `$EventData.Branch -ne '$Branch') {
    return `$false
}

# Vérifier les fichiers modifiés
`$matchesFilePattern = `$false
foreach (`$file in `$EventData.ChangedFiles) {
    if (`$file -like '$FilePattern') {
        `$matchesFilePattern = `$true
        break
    }
}

if (-not `$matchesFilePattern) {
    return `$false
}

# Vérifier le message de commit si un pattern est spécifié
if ('$CommitMessagePattern' -ne '') {
    if (`$EventData.CommitMessage -notmatch '$CommitMessagePattern') {
        return `$false
    }
}

return `$true
"@
    
    return [scriptblock]::Create($conditionScript)
}

# Fonction pour enregistrer un déclencheur de commit Git
function Register-GitCommitTrigger {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Branch = "main",
        
        [Parameter(Mandatory = $false)]
        [string]$FilePattern = "*",
        
        [Parameter(Mandatory = $false)]
        [string]$CommitMessagePattern = "",
        
        [Parameter(Mandatory = $false)]
        [string]$TriggerName,
        
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
    
    # Vérifier si un chemin de dépôt est fourni
    if ([string]::IsNullOrEmpty($RepositoryPath)) {
        $RepositoryPath = Get-Location
    }
    
    # Vérifier si le répertoire existe
    if (-not (Test-Path -Path $RepositoryPath)) {
        Write-Log "Repository path does not exist: $RepositoryPath" -Level "Error"
        return $false
    }
    
    # Vérifier si le répertoire est un dépôt Git
    $gitDir = Join-Path -Path $RepositoryPath -ChildPath ".git"
    if (-not (Test-Path -Path $gitDir)) {
        Write-Log "Directory is not a Git repository: $RepositoryPath" -Level "Error"
        return $false
    }
    
    # Générer un nom de déclencheur par défaut si non fourni
    if ([string]::IsNullOrEmpty($TriggerName)) {
        $TriggerName = Get-DefaultTriggerName -Branch $Branch -FilePattern $FilePattern
    }
    
    # Générer une description par défaut si non fournie
    if ([string]::IsNullOrEmpty($Description)) {
        $Description = "Git commit trigger for branch '$Branch' and files matching '$FilePattern'"
        
        if (-not [string]::IsNullOrEmpty($CommitMessagePattern)) {
            $Description += " with commit messages matching '$CommitMessagePattern'"
        }
    }
    
    # Créer une condition par défaut si non fournie
    if ($null -eq $Condition) {
        $Condition = New-VerificationCondition -Branch $Branch -FilePattern $FilePattern -CommitMessagePattern $CommitMessagePattern
    }
    
    # Créer une action par défaut si non fournie et si CreateRestorePoint est activé
    if ($null -eq $Action -and $CreateRestorePoint) {
        $Action = New-RestorePointAction -RepositoryPath $RepositoryPath -Branch $Branch
    }
    
    # Créer les paramètres du déclencheur
    $parameters = @{
        "RepositoryPath" = $RepositoryPath
        "Branch" = $Branch
        "FilePattern" = $FilePattern
    }
    
    if (-not [string]::IsNullOrEmpty($CommitMessagePattern)) {
        $parameters["CommitMessagePattern"] = $CommitMessagePattern
    }
    
    # Enregistrer le déclencheur
    $result = Register-RestoreTrigger -TriggerType "GitCommit" -TriggerName $TriggerName -Description $Description -Parameters $parameters -Condition $Condition -Action $Action -Enabled:$Enabled -Force:$Force
    
    if ($result) {
        Write-Log "Git commit trigger registered successfully: $TriggerName" -Level "Info"
        
        # Créer le hook Git post-commit si nécessaire
        $hookPath = Join-Path -Path $gitDir -ChildPath "hooks\post-commit"
        $hookExists = Test-Path -Path $hookPath
        
        if (-not $hookExists -or $Force) {
            $hookContent = @"
#!/bin/sh
# Post-commit hook for restore point creation
# Generated by Register-GitCommitTrigger.ps1

# Get commit information
COMMIT_HASH=`$(git rev-parse HEAD)
COMMIT_MSG=`$(git log -1 --pretty=%B)
BRANCH=`$(git rev-parse --abbrev-ref HEAD)
AUTHOR=`$(git log -1 --pretty=%an)
CHANGED_FILES=`$(git diff-tree --no-commit-id --name-only -r HEAD)

# Call PowerShell script to process the commit
powershell.exe -ExecutionPolicy Bypass -File "$scriptPath\Process-GitCommit.ps1" -RepositoryPath "$RepositoryPath" -CommitHash "`$COMMIT_HASH" -CommitMessage "`$COMMIT_MSG" -Branch "`$BRANCH" -Author "`$AUTHOR" -ChangedFiles "`$CHANGED_FILES"

exit 0
"@
            
            # Sauvegarder le hook
            $hookContent | Out-File -FilePath $hookPath -Encoding UTF8
            
            # Rendre le hook exécutable sur les systèmes Unix
            if (-not $IsWindows) {
                chmod +x $hookPath
            }
            
            Write-Log "Git post-commit hook created: $hookPath" -Level "Info"
        }
        
        return $true
    } else {
        Write-Log "Failed to register Git commit trigger: $TriggerName" -Level "Error"
        return $false
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Register-GitCommitTrigger -RepositoryPath $RepositoryPath -Branch $Branch -FilePattern $FilePattern -CommitMessagePattern $CommitMessagePattern -TriggerName $TriggerName -Description $Description -Condition $Condition -Action $Action -CreateRestorePoint:$CreateRestorePoint -Enabled:$Enabled -Force:$Force
}
