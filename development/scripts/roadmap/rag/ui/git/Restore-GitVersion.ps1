# Restore-GitVersion.ps1
# Script pour restaurer des versions antérieures dans Git
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RepositoryPath,
    
    [Parameter(Mandatory = $false)]
    [string]$CommitHash,
    
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateBranch,
    
    [Parameter(Mandatory = $false)]
    [string]$BranchName,
    
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
$configPath = Join-Path -Path $rootPath -ChildPath "config"
$gitPath = Join-Path -Path $configPath -ChildPath "git"
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
$gitOperationPath = Join-Path -Path $gitPath -ChildPath "Invoke-GitOperation.ps1"

if (Test-Path -Path $gitOperationPath) {
    . $gitOperationPath
} else {
    Write-Log "Required script not found: $gitOperationPath" -Level "Error"
    exit 1
}

# Fonction pour obtenir les commits récents
function Get-RecentCommits {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [int]$Count = 20
    )
    
    try {
        Push-Location -Path $RepositoryPath
        
        # Exécuter la commande
        $command = "git log --pretty=format:'%H|%h|%an|%ad|%s' --date=format:'%Y-%m-%d %H:%M:%S' -n $Count"
        $output = Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to get recent commits" -Level "Error"
            return $null
        }
        
        # Analyser les résultats
        $commits = @()
        
        foreach ($line in $output) {
            if (-not [string]::IsNullOrEmpty($line)) {
                $parts = $line.Trim("'").Split("|")
                
                if ($parts.Count -ge 5) {
                    $commit = @{
                        Hash = $parts[0]
                        ShortHash = $parts[1]
                        Author = $parts[2]
                        Date = $parts[3]
                        Subject = $parts[4]
                    }
                    
                    $commits += $commit
                }
            }
        }
        
        return $commits
    } catch {
        Write-Log "Error getting recent commits: $_" -Level "Error"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour obtenir les fichiers d'un commit
function Get-CommitFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CommitHash
    )
    
    try {
        Push-Location -Path $RepositoryPath
        
        # Exécuter la commande
        $command = "git show --name-only --pretty=format:'' $CommitHash"
        $output = Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to get commit files" -Level "Error"
            return $null
        }
        
        # Filtrer les lignes vides
        $files = $output | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        
        return $files
    } catch {
        Write-Log "Error getting commit files: $_" -Level "Error"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour restaurer un fichier à une version antérieure
function Restore-GitFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CommitHash,
        
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        Push-Location -Path $RepositoryPath
        
        # Vérifier si le fichier existe dans le commit
        $fileExists = git show "$CommitHash:$FilePath" 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "File does not exist in commit: $FilePath" -Level "Error"
            return $false
        }
        
        # Restaurer le fichier
        $command = "git checkout $CommitHash -- `"$FilePath`""
        Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to restore file: $FilePath" -Level "Error"
            return $false
        }
        
        Write-Log "File restored successfully: $FilePath" -Level "Info"
        return $true
    } catch {
        Write-Log "Error restoring file: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour restaurer un commit complet
function Restore-GitCommit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CommitHash,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBranch,
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        Push-Location -Path $RepositoryPath
        
        # Vérifier si le commit existe
        $commitExists = git cat-file -t $CommitHash 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Commit does not exist: $CommitHash" -Level "Error"
            return $false
        }
        
        # Créer une branche si demandé
        if ($CreateBranch) {
            if ([string]::IsNullOrEmpty($BranchName)) {
                $BranchName = "restore-$($CommitHash.Substring(0, 7))"
            }
            
            $branchExists = git show-ref --verify --quiet refs/heads/$BranchName
            
            if ($LASTEXITCODE -eq 0 -and -not $Force) {
                Write-Log "Branch already exists: $BranchName. Use -Force to overwrite." -Level "Error"
                return $false
            }
            
            $command = "git checkout -B $BranchName $CommitHash"
            Invoke-Expression $command
            
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Failed to create branch: $BranchName" -Level "Error"
                return $false
            }
            
            Write-Log "Branch created successfully: $BranchName" -Level "Info"
            return $true
        } else {
            # Restaurer le commit sans créer de branche (hard reset)
            $command = "git reset --hard $CommitHash"
            Invoke-Expression $command
            
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Failed to restore commit: $CommitHash" -Level "Error"
                return $false
            }
            
            Write-Log "Commit restored successfully: $CommitHash" -Level "Info"
            return $true
        }
    } catch {
        Write-Log "Error restoring commit: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour sélectionner un commit
function Select-GitCommit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "Select a commit to restore"
    )
    
    # Obtenir les commits récents
    $commits = Get-RecentCommits -RepositoryPath $RepositoryPath
    
    if ($null -eq $commits -or $commits.Count -eq 0) {
        Write-Log "No commits found" -Level "Warning"
        return $null
    }
    
    # Afficher la liste des commits
    Clear-Host
    Write-Host $Title -ForegroundColor "Cyan"
    Write-Host "----------------------------------------------------------------------" -ForegroundColor "Cyan"
    
    for ($i = 0; $i -lt $commits.Count; $i++) {
        $commit = $commits[$i]
        Write-Host "$($i + 1). $($commit.ShortHash) - $($commit.Date) - $($commit.Subject)" -ForegroundColor "White"
    }
    
    Write-Host "----------------------------------------------------------------------" -ForegroundColor "Cyan"
    
    # Demander à l'utilisateur de sélectionner un commit
    $selection = 0
    
    do {
        Write-Host "Enter the number of the commit (1-$($commits.Count)) or 'q' to quit: " -ForegroundColor "Yellow" -NoNewline
        $input = Read-Host
        
        if ($input -eq "q") {
            return $null
        }
        
        if ([int]::TryParse($input, [ref]$selection) -and $selection -ge 1 -and $selection -le $commits.Count) {
            return $commits[$selection - 1].Hash
        } else {
            Write-Host "Invalid selection. Please try again." -ForegroundColor "Red"
        }
    } while ($true)
}

# Fonction pour sélectionner un fichier
function Select-GitFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CommitHash
    )
    
    # Obtenir les fichiers du commit
    $files = Get-CommitFiles -RepositoryPath $RepositoryPath -CommitHash $CommitHash
    
    if ($null -eq $files -or $files.Count -eq 0) {
        Write-Log "No files found in commit" -Level "Warning"
        return $null
    }
    
    # Afficher la liste des fichiers
    Clear-Host
    Write-Host "Select a file to restore" -ForegroundColor "Cyan"
    Write-Host "----------------------------------------------------------------------" -ForegroundColor "Cyan"
    
    for ($i = 0; $i -lt $files.Count; $i++) {
        Write-Host "$($i + 1). $($files[$i])" -ForegroundColor "White"
    }
    
    Write-Host "----------------------------------------------------------------------" -ForegroundColor "Cyan"
    
    # Demander à l'utilisateur de sélectionner un fichier
    $selection = 0
    
    do {
        Write-Host "Enter the number of the file (1-$($files.Count)) or 'q' to quit: " -ForegroundColor "Yellow" -NoNewline
        $input = Read-Host
        
        if ($input -eq "q") {
            return $null
        }
        
        if ([int]::TryParse($input, [ref]$selection) -and $selection -ge 1 -and $selection -le $files.Count) {
            return $files[$selection - 1]
        } else {
            Write-Host "Invalid selection. Please try again." -ForegroundColor "Red"
        }
    } while ($true)
}

# Fonction pour confirmer une action
function Confirm-Action {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    if ($Force) {
        return $true
    }
    
    Write-Host "$Message (y/n): " -ForegroundColor "Yellow" -NoNewline
    $response = Read-Host
    
    return $response -eq "y" -or $response -eq "Y"
}

# Fonction principale
function Restore-GitVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$CommitHash,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBranch,
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si Git est installé
    if (-not (Test-GitInstalled)) {
        Write-Log "Git must be installed to restore versions" -Level "Error"
        return
    }
    
    # Vérifier si un chemin de dépôt est fourni
    if ([string]::IsNullOrEmpty($RepositoryPath)) {
        $RepositoryPath = Get-Location
    }
    
    # Vérifier si le répertoire existe
    if (-not (Test-Path -Path $RepositoryPath)) {
        Write-Log "Repository path does not exist: $RepositoryPath" -Level "Error"
        return
    }
    
    # Vérifier si le répertoire est un dépôt Git
    if (-not (Test-GitRepository -Path $RepositoryPath)) {
        Write-Log "Directory is not a Git repository: $RepositoryPath" -Level "Error"
        return
    }
    
    # Vérifier si le dépôt a des modifications non validées
    $status = Invoke-GitOperation -Operation "Status" -RepositoryPath $RepositoryPath
    
    if (-not $status.is_clean -and -not $Force) {
        $confirmed = Confirm-Action -Message "Repository has uncommitted changes. Continue anyway?" -Force:$Force
        
        if (-not $confirmed) {
            Write-Log "Operation cancelled" -Level "Warning"
            return
        }
    }
    
    # Sélectionner un commit si non fourni
    if ([string]::IsNullOrEmpty($CommitHash)) {
        $CommitHash = Select-GitCommit -RepositoryPath $RepositoryPath
        
        if ($null -eq $CommitHash) {
            Write-Log "No commit selected" -Level "Warning"
            return
        }
    }
    
    # Restaurer un fichier spécifique ou le commit entier
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        # Restaurer un fichier spécifique
        $result = Restore-GitFile -RepositoryPath $RepositoryPath -CommitHash $CommitHash -FilePath $FilePath
        
        if ($result) {
            Write-Host "File restored successfully: $FilePath" -ForegroundColor "Green"
            
            # Demander si l'utilisateur veut valider les modifications
            $confirmed = Confirm-Action -Message "Do you want to commit the restored file?" -Force:$Force
            
            if ($confirmed) {
                $message = "Restore file '$FilePath' from commit $($CommitHash.Substring(0, 7))"
                $commitResult = Invoke-GitOperation -Operation "Commit" -RepositoryPath $RepositoryPath -Message $message
                
                if ($commitResult) {
                    Write-Host "Changes committed successfully" -ForegroundColor "Green"
                } else {
                    Write-Host "Failed to commit changes" -ForegroundColor "Red"
                }
            }
        }
    } else {
        # Sélectionner un fichier ou restaurer le commit entier
        $confirmed = Confirm-Action -Message "Do you want to restore a specific file? (No will restore the entire commit)" -Force:$Force
        
        if ($confirmed) {
            $FilePath = Select-GitFile -RepositoryPath $RepositoryPath -CommitHash $CommitHash
            
            if ($null -eq $FilePath) {
                Write-Log "No file selected" -Level "Warning"
                return
            }
            
            $result = Restore-GitFile -RepositoryPath $RepositoryPath -CommitHash $CommitHash -FilePath $FilePath
            
            if ($result) {
                Write-Host "File restored successfully: $FilePath" -ForegroundColor "Green"
                
                # Demander si l'utilisateur veut valider les modifications
                $confirmed = Confirm-Action -Message "Do you want to commit the restored file?" -Force:$Force
                
                if ($confirmed) {
                    $message = "Restore file '$FilePath' from commit $($CommitHash.Substring(0, 7))"
                    $commitResult = Invoke-GitOperation -Operation "Commit" -RepositoryPath $RepositoryPath -Message $message
                    
                    if ($commitResult) {
                        Write-Host "Changes committed successfully" -ForegroundColor "Green"
                    } else {
                        Write-Host "Failed to commit changes" -ForegroundColor "Red"
                    }
                }
            }
        } else {
            # Restaurer le commit entier
            $warning = "This will reset your working directory to the state of commit $($CommitHash.Substring(0, 7))."
            
            if ($CreateBranch) {
                if ([string]::IsNullOrEmpty($BranchName)) {
                    $BranchName = "restore-$($CommitHash.Substring(0, 7))"
                }
                
                $warning += " A new branch '$BranchName' will be created."
            } else {
                $warning += " All uncommitted changes will be lost."
            }
            
            $confirmed = Confirm-Action -Message "$warning Continue?" -Force:$Force
            
            if ($confirmed) {
                $result = Restore-GitCommit -RepositoryPath $RepositoryPath -CommitHash $CommitHash -CreateBranch:$CreateBranch -BranchName $BranchName -Force:$Force
                
                if ($result) {
                    if ($CreateBranch) {
                        Write-Host "Branch created successfully: $BranchName" -ForegroundColor "Green"
                    } else {
                        Write-Host "Repository reset to commit: $($CommitHash.Substring(0, 7))" -ForegroundColor "Green"
                    }
                }
            } else {
                Write-Log "Operation cancelled" -Level "Warning"
            }
        }
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Restore-GitVersion -RepositoryPath $RepositoryPath -CommitHash $CommitHash -FilePath $FilePath -CreateBranch:$CreateBranch -BranchName $BranchName -Force:$Force
}
