# Save-ConfigurationToGit.ps1
# Script principal pour sauvegarder les configurations dans Git
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
    [string]$ConfigType,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory = $false)]
    [object]$Configuration,
    
    [Parameter(Mandatory = $false)]
    [string]$RepositoryPath,
    
    [Parameter(Mandatory = $false)]
    [string]$CommitMessage,
    
    [Parameter(Mandatory = $false)]
    [string]$BranchName,
    
    [Parameter(Mandatory = $false)]
    [switch]$Push,
    
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
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $rootPath)) -ChildPath "utils"
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

# Importer les scripts nécessaires
$gitOperationPath = Join-Path -Path $scriptPath -ChildPath "Invoke-GitOperation.ps1"
$gitStructurePath = Join-Path -Path $scriptPath -ChildPath "Get-GitRepositoryStructure.ps1"
$gitInitPath = Join-Path -Path $scriptPath -ChildPath "Initialize-GitRepository.ps1"

# Vérifier que tous les scripts nécessaires existent
$requiredScripts = @($gitOperationPath, $gitStructurePath, $gitInitPath)
foreach ($script in $requiredScripts) {
    if (-not (Test-Path -Path $script)) {
        Write-Log "Required script not found: $script" -Level "Error"
        exit 1
    }
}

# Importer les scripts
. $gitOperationPath
. $gitStructurePath
. $gitInitPath

# Fonction pour obtenir le chemin de destination dans le dépôt Git
function Get-GitDestinationPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $true)]
        [object]$Configuration
    )
    
    # Obtenir la structure du dépôt
    $structure = Get-GitRepositoryStructure
    
    # Déterminer le répertoire de destination
    $destinationDir = switch ($ConfigType) {
        "Template" { Join-Path -Path $RepositoryPath -ChildPath $structure.directories.templates.path }
        "Visualization" { Join-Path -Path $RepositoryPath -ChildPath $structure.directories.visualizations.path }
        "DataMapping" { Join-Path -Path $RepositoryPath -ChildPath $structure.directories.data_mappings.path }
        "Chart" { Join-Path -Path $RepositoryPath -ChildPath $structure.directories.charts.path }
        "Export" { Join-Path -Path $RepositoryPath -ChildPath $structure.directories.exports.path }
        "Search" { Join-Path -Path $RepositoryPath -ChildPath $structure.directories.searches.path }
        default { Join-Path -Path $RepositoryPath -ChildPath "configurations" }
    }
    
    # Créer le répertoire s'il n'existe pas
    if (-not (Test-Path -Path $destinationDir)) {
        New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
    }
    
    # Déterminer le nom de fichier
    $fileNamePattern = $structure.file_naming.$($ConfigType.ToLower())
    
    if ([string]::IsNullOrEmpty($fileNamePattern)) {
        $fileNamePattern = "{name}_v{version}.json"
    }
    
    $fileName = $fileNamePattern -replace "{name}", $Configuration.name -replace "{version}", $Configuration.version
    
    # Construire le chemin complet
    $destinationPath = Join-Path -Path $destinationDir -ChildPath $fileName
    
    return $destinationPath
}

# Fonction pour générer un message de commit
function Get-CommitMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $true)]
        [object]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [string]$CustomMessage
    )
    
    if (-not [string]::IsNullOrEmpty($CustomMessage)) {
        return $CustomMessage
    }
    
    $scope = switch ($ConfigType) {
        "Template" { "templates" }
        "Visualization" { "visualizations" }
        "DataMapping" { "data-mappings" }
        "Chart" { "charts" }
        "Export" { "exports" }
        "Search" { "searches" }
        default { "configs" }
    }
    
    $action = "add"
    
    if ($Configuration.PSObject.Properties.Name.Contains("updated_at") -or $Configuration.PSObject.Properties.Name.Contains("modified_date")) {
        $action = "update"
    }
    
    $message = "feat($scope): $action $($Configuration.name) configuration"
    
    if ($Configuration.PSObject.Properties.Name.Contains("description")) {
        $message += "`n`n$($Configuration.description)"
    }
    
    return $message
}

# Fonction pour vérifier si une configuration existe déjà dans le dépôt
function Test-ConfigurationExists {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    return Test-Path -Path $FilePath
}

# Fonction pour sauvegarder une configuration dans le dépôt Git
function Save-ConfigurationToGit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Template", "Visualization", "DataMapping", "Chart", "Export", "Search")]
        [string]$ConfigType,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [object]$Configuration,
        
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$CommitMessage,
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Push,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si un chemin de configuration ou une configuration est fourni
    if ([string]::IsNullOrEmpty($ConfigPath) -and $null -eq $Configuration) {
        Write-Log "Either ConfigPath or Configuration must be provided" -Level "Error"
        return $false
    }
    
    # Charger la configuration à partir du fichier si nécessaire
    if (-not [string]::IsNullOrEmpty($ConfigPath)) {
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-Log "Configuration file not found: $ConfigPath" -Level "Error"
            return $false
        }
        
        try {
            $Configuration = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        } catch {
            Write-Log "Error loading configuration from file: $_" -Level "Error"
            return $false
        }
    }
    
    # Déterminer le type de configuration si non spécifié
    if ([string]::IsNullOrEmpty($ConfigType)) {
        if ($Configuration.PSObject.Properties.Name.Contains("content") -and $Configuration.PSObject.Properties.Name.Contains("type")) {
            $ConfigType = "Template"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("chart_configuration") -and $Configuration.PSObject.Properties.Name.Contains("data_mapping")) {
            $ConfigType = "Visualization"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("mappings") -and $Configuration.PSObject.Properties.Name.Contains("version")) {
            $ConfigType = "DataMapping"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("chart_type") -and $Configuration.PSObject.Properties.Name.Contains("data_field")) {
            $ConfigType = "Chart"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("export_type")) {
            $ConfigType = "Export"
        } elseif ($Configuration.PSObject.Properties.Name.Contains("search_type") -and $Configuration.PSObject.Properties.Name.Contains("query")) {
            $ConfigType = "Search"
        } else {
            Write-Log "Could not determine configuration type" -Level "Error"
            return $false
        }
        
        Write-Log "Determined configuration type: $ConfigType" -Level "Info"
    }
    
    # Vérifier si un chemin de dépôt est fourni
    if ([string]::IsNullOrEmpty($RepositoryPath)) {
        $RepositoryPath = Join-Path -Path $rootPath -ChildPath "git_repository"
    }
    
    # Vérifier si le dépôt existe, sinon l'initialiser
    if (-not (Test-Path -Path $RepositoryPath)) {
        Write-Log "Repository path does not exist, creating it: $RepositoryPath" -Level "Info"
        New-Item -Path $RepositoryPath -ItemType Directory -Force | Out-Null
    }
    
    if (-not (Test-GitRepository -Path $RepositoryPath)) {
        Write-Log "Initializing Git repository at: $RepositoryPath" -Level "Info"
        $initResult = Initialize-GitRepository -RepositoryPath $RepositoryPath -Force:$Force
        
        if (-not $initResult) {
            Write-Log "Failed to initialize Git repository" -Level "Error"
            return $false
        }
    }
    
    # Déterminer le chemin de destination dans le dépôt
    $destinationPath = Get-GitDestinationPath -ConfigType $ConfigType -RepositoryPath $RepositoryPath -Configuration $Configuration
    
    # Vérifier si la configuration existe déjà
    $configExists = Test-ConfigurationExists -FilePath $destinationPath
    
    if ($configExists -and -not $Force) {
        Write-Log "Configuration already exists: $destinationPath. Use -Force to overwrite." -Level "Warning"
        return $false
    }
    
    # Sauvegarder la configuration
    try {
        $Configuration | ConvertTo-Json -Depth 10 | Out-File -FilePath $destinationPath -Encoding UTF8
        Write-Log "Configuration saved to: $destinationPath" -Level "Info"
    } catch {
        Write-Log "Error saving configuration: $_" -Level "Error"
        return $false
    }
    
    # Créer une branche si demandé
    if (-not [string]::IsNullOrEmpty($BranchName)) {
        $branchResult = Invoke-GitOperation -Operation "Branch" -RepositoryPath $RepositoryPath -BranchName $BranchName
        
        if (-not $branchResult) {
            Write-Log "Failed to create branch: $BranchName" -Level "Error"
            return $false
        }
    }
    
    # Ajouter la configuration à l'index
    $addResult = Invoke-GitOperation -Operation "Add" -RepositoryPath $RepositoryPath -FilePath $destinationPath
    
    if (-not $addResult) {
        Write-Log "Failed to add configuration to Git index" -Level "Error"
        return $false
    }
    
    # Générer un message de commit
    $message = Get-CommitMessage -ConfigType $ConfigType -Configuration $Configuration -CustomMessage $CommitMessage
    
    # Créer un commit
    $commitResult = Invoke-GitOperation -Operation "Commit" -RepositoryPath $RepositoryPath -Message $message
    
    if (-not $commitResult) {
        Write-Log "Failed to create Git commit" -Level "Error"
        return $false
    }
    
    # Pousser les modifications si demandé
    if ($Push) {
        $pushResult = Invoke-GitOperation -Operation "Push" -RepositoryPath $RepositoryPath -BranchName $BranchName -Force:$Force
        
        if (-not $pushResult) {
            Write-Log "Failed to push Git changes" -Level "Warning"
            # Ne pas échouer complètement si le push échoue
        } else {
            Write-Log "Git changes pushed successfully" -Level "Info"
        }
    }
    
    Write-Log "Configuration saved to Git repository successfully" -Level "Info"
    return $true
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Save-ConfigurationToGit -ConfigType $ConfigType -ConfigPath $ConfigPath -Configuration $Configuration -RepositoryPath $RepositoryPath -CommitMessage $CommitMessage -BranchName $BranchName -Push:$Push -Force:$Force
}
