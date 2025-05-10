# Initialize-GitRepository.ps1
# Script pour initialiser et configurer un dépôt Git pour les configurations
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RepositoryPath,
    
    [Parameter(Mandatory = $false)]
    [string]$UserName,
    
    [Parameter(Mandatory = $false)]
    [string]$UserEmail,
    
    [Parameter(Mandatory = $false)]
    [switch]$SetupHooks,
    
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
$structurePath = Join-Path -Path $scriptPath -ChildPath "Get-GitRepositoryStructure.ps1"
$branchingPath = Join-Path -Path $scriptPath -ChildPath "Get-GitBranchingConventions.ps1"
$commitPath = Join-Path -Path $scriptPath -ChildPath "Get-GitCommitConventions.ps1"

# Vérifier que tous les scripts nécessaires existent
$requiredScripts = @($structurePath, $branchingPath, $commitPath)
foreach ($script in $requiredScripts) {
    if (-not (Test-Path -Path $script)) {
        Write-Log "Required script not found: $script" -Level "Error"
        exit 1
    }
}

# Importer les scripts
. $structurePath
. $branchingPath
. $commitPath

# Fonction pour vérifier si Git est installé
function Test-GitInstalled {
    [CmdletBinding()]
    param()
    
    try {
        $gitVersion = git --version
        Write-Log "Git is installed: $gitVersion" -Level "Debug"
        return $true
    } catch {
        Write-Log "Git is not installed or not in PATH" -Level "Error"
        return $false
    }
}

# Fonction pour vérifier si un répertoire est déjà un dépôt Git
function Test-GitRepository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    $gitDir = Join-Path -Path $Path -ChildPath ".git"
    
    if (Test-Path -Path $gitDir -PathType Container) {
        Write-Log "Directory is already a Git repository: $Path" -Level "Info"
        return $true
    } else {
        Write-Log "Directory is not a Git repository: $Path" -Level "Debug"
        return $false
    }
}

# Fonction pour initialiser un dépôt Git
function Initialize-Git {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        Push-Location -Path $Path
        
        git init
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to initialize Git repository" -Level "Error"
            return $false
        }
        
        Write-Log "Git repository initialized successfully" -Level "Info"
        return $true
    } catch {
        Write-Log "Error initializing Git repository: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour configurer l'utilisateur Git
function Set-GitUser {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$UserName,
        
        [Parameter(Mandatory = $true)]
        [string]$UserEmail
    )
    
    try {
        Push-Location -Path $Path
        
        git config user.name $UserName
        git config user.email $UserEmail
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to configure Git user" -Level "Error"
            return $false
        }
        
        Write-Log "Git user configured successfully: $UserName <$UserEmail>" -Level "Info"
        return $true
    } catch {
        Write-Log "Error configuring Git user: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour créer la structure de répertoires
function New-RepositoryStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [object]$Structure
    )
    
    try {
        # Créer les répertoires
        foreach ($dir in $Structure.directories.Keys) {
            $dirInfo = $Structure.directories[$dir]
            $dirPath = Join-Path -Path $Path -ChildPath $dirInfo.path
            
            if (-not (Test-Path -Path $dirPath)) {
                New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
                Write-Log "Created directory: $dirPath" -Level "Debug"
            }
            
            # Créer les sous-répertoires
            if ($dirInfo.PSObject.Properties.Name.Contains("subdirectories")) {
                foreach ($subdir in $dirInfo.subdirectories.Keys) {
                    $subdirInfo = $dirInfo.subdirectories[$subdir]
                    $subdirPath = Join-Path -Path $dirPath -ChildPath $subdirInfo.path
                    
                    if (-not (Test-Path -Path $subdirPath)) {
                        New-Item -Path $subdirPath -ItemType Directory -Force | Out-Null
                        Write-Log "Created subdirectory: $subdirPath" -Level "Debug"
                    }
                }
            }
        }
        
        Write-Log "Repository structure created successfully" -Level "Info"
        return $true
    } catch {
        Write-Log "Error creating repository structure: $_" -Level "Error"
        return $false
    }
}

# Fonction pour créer les fichiers de base
function New-BaseFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [object]$Structure
    )
    
    try {
        # Créer le fichier .gitignore
        $gitignoreContent = Get-GitignoreContent -Structure $Structure
        $gitignorePath = Join-Path -Path $Path -ChildPath ".gitignore"
        $gitignoreContent | Out-File -FilePath $gitignorePath -Encoding UTF8
        Write-Log "Created .gitignore file" -Level "Debug"
        
        # Créer le fichier README.md
        $readmeContent = Get-ReadmeContent -Structure $Structure
        $readmePath = Join-Path -Path $Path -ChildPath "README.md"
        $readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
        Write-Log "Created README.md file" -Level "Debug"
        
        # Créer les fichiers de documentation sur les conventions
        $branchingConventions = Get-GitBranchingConventionsFiles -AsObject
        $branchingPath = Join-Path -Path $Path -ChildPath "BRANCHING.md"
        $branchingConventions.documentation | Out-File -FilePath $branchingPath -Encoding UTF8
        Write-Log "Created BRANCHING.md file" -Level "Debug"
        
        $commitConventions = Get-GitCommitConventionsFiles -AsObject
        $commitPath = Join-Path -Path $Path -ChildPath "COMMIT_CONVENTION.md"
        $commitConventions.documentation | Out-File -FilePath $commitPath -Encoding UTF8
        Write-Log "Created COMMIT_CONVENTION.md file" -Level "Debug"
        
        Write-Log "Base files created successfully" -Level "Info"
        return $true
    } catch {
        Write-Log "Error creating base files: $_" -Level "Error"
        return $false
    }
}

# Fonction pour configurer les hooks Git
function Set-GitHooks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        # Créer le répertoire des hooks
        $hooksDir = Join-Path -Path $Path -ChildPath ".git\hooks"
        if (-not (Test-Path -Path $hooksDir)) {
            New-Item -Path $hooksDir -ItemType Directory -Force | Out-Null
        }
        
        # Créer le répertoire des scripts de hooks
        $scriptsDir = Join-Path -Path $Path -ChildPath "scripts\hooks"
        if (-not (Test-Path -Path $scriptsDir)) {
            New-Item -Path $scriptsDir -ItemType Directory -Force | Out-Null
        }
        
        # Obtenir les scripts de validation
        $branchingConventions = Get-GitBranchingConventionsFiles -AsObject
        $commitConventions = Get-GitCommitConventionsFiles -AsObject
        
        # Sauvegarder les scripts de validation
        $branchingConventions.validation_script | Out-File -FilePath (Join-Path -Path $scriptsDir -ChildPath "validate-branch-name.ps1") -Encoding UTF8
        $commitConventions.validation_script | Out-File -FilePath (Join-Path -Path $scriptsDir -ChildPath "validate-commit-message.ps1") -Encoding UTF8
        
        # Créer le hook pre-push
        $prePushHook = @"
#!/bin/sh
# pre-push hook
# Validates branch names according to conventions

# Run PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "$(Join-Path -Path $Path -ChildPath "scripts\hooks\validate-branch-name.ps1")"
exit_code=`$?

if [ `$exit_code -ne 0 ]; then
    exit 1
fi

exit 0
"@
        
        $prePushHook | Out-File -FilePath (Join-Path -Path $hooksDir -ChildPath "pre-push") -Encoding ASCII
        
        # Créer le hook commit-msg
        $commitMsgHook = @"
#!/bin/sh
# commit-msg hook
# Validates commit messages according to conventions

# Run PowerShell script
powershell.exe -ExecutionPolicy Bypass -File "$(Join-Path -Path $Path -ChildPath "scripts\hooks\validate-commit-message.ps1")" "`$1"
exit_code=`$?

if [ `$exit_code -ne 0 ]; then
    exit 1
fi

exit 0
"@
        
        $commitMsgHook | Out-File -FilePath (Join-Path -Path $hooksDir -ChildPath "commit-msg") -Encoding ASCII
        
        Write-Log "Git hooks configured successfully" -Level "Info"
        return $true
    } catch {
        Write-Log "Error configuring Git hooks: $_" -Level "Error"
        return $false
    }
}

# Fonction pour effectuer le premier commit
function New-InitialCommit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        Push-Location -Path $Path
        
        git add .
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to stage files for initial commit" -Level "Error"
            return $false
        }
        
        git commit -m "chore: initial commit"
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to create initial commit" -Level "Error"
            return $false
        }
        
        Write-Log "Initial commit created successfully" -Level "Info"
        return $true
    } catch {
        Write-Log "Error creating initial commit: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour créer les branches principales
function New-MainBranches {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [object]$BranchingConventions
    )
    
    try {
        Push-Location -Path $Path
        
        # Créer la branche development
        git checkout -b development
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to create development branch" -Level "Error"
            return $false
        }
        
        # Revenir à la branche main
        git checkout main
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to switch back to main branch" -Level "Error"
            return $false
        }
        
        Write-Log "Main branches created successfully" -Level "Info"
        return $true
    } catch {
        Write-Log "Error creating main branches: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction principale
function Initialize-GitRepository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$UserName,
        
        [Parameter(Mandatory = $false)]
        [string]$UserEmail,
        
        [Parameter(Mandatory = $false)]
        [switch]$SetupHooks,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si Git est installé
    if (-not (Test-GitInstalled)) {
        Write-Log "Git must be installed to initialize a repository" -Level "Error"
        return $false
    }
    
    # Vérifier si un chemin de dépôt est fourni
    if ([string]::IsNullOrEmpty($RepositoryPath)) {
        $RepositoryPath = Get-Location
    }
    
    # Vérifier si le répertoire existe
    if (-not (Test-Path -Path $RepositoryPath)) {
        Write-Log "Repository path does not exist: $RepositoryPath" -Level "Error"
        return $false
    }
    
    # Vérifier si le répertoire est déjà un dépôt Git
    if (Test-GitRepository -Path $RepositoryPath) {
        if (-not $Force) {
            Write-Log "Directory is already a Git repository. Use -Force to reinitialize." -Level "Warning"
            return $false
        } else {
            Write-Log "Reinitializing existing Git repository" -Level "Warning"
        }
    }
    
    # Obtenir les structures et conventions
    $structure = Get-GitRepositoryStructure
    $branchingConventions = Get-GitBranchingConventions
    
    # Initialiser le dépôt Git
    if (-not (Initialize-Git -Path $RepositoryPath)) {
        return $false
    }
    
    # Configurer l'utilisateur Git si fourni
    if (-not [string]::IsNullOrEmpty($UserName) -and -not [string]::IsNullOrEmpty($UserEmail)) {
        if (-not (Set-GitUser -Path $RepositoryPath -UserName $UserName -UserEmail $UserEmail)) {
            return $false
        }
    } else {
        Write-Log "Skipping Git user configuration (no user name or email provided)" -Level "Info"
    }
    
    # Créer la structure de répertoires
    if (-not (New-RepositoryStructure -Path $RepositoryPath -Structure $structure)) {
        return $false
    }
    
    # Créer les fichiers de base
    if (-not (New-BaseFiles -Path $RepositoryPath -Structure $structure)) {
        return $false
    }
    
    # Configurer les hooks Git si demandé
    if ($SetupHooks) {
        if (-not (Set-GitHooks -Path $RepositoryPath)) {
            return $false
        }
    } else {
        Write-Log "Skipping Git hooks setup (not requested)" -Level "Info"
    }
    
    # Effectuer le premier commit
    if (-not (New-InitialCommit -Path $RepositoryPath)) {
        return $false
    }
    
    # Créer les branches principales
    if (-not (New-MainBranches -Path $RepositoryPath -BranchingConventions $branchingConventions)) {
        return $false
    }
    
    Write-Log "Git repository initialized successfully at: $RepositoryPath" -Level "Info"
    return $true
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Initialize-GitRepository -RepositoryPath $RepositoryPath -UserName $UserName -UserEmail $UserEmail -SetupHooks:$SetupHooks -Force:$Force
}
