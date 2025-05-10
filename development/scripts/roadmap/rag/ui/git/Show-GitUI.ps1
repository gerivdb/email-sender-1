# Show-GitUI.ps1
# Script principal pour l'interface utilisateur Git
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RepositoryPath,
    
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
$historyPath = Join-Path -Path $scriptPath -ChildPath "Show-GitHistory.ps1"
$comparePath = Join-Path -Path $scriptPath -ChildPath "Compare-GitVersions.ps1"
$restorePath = Join-Path -Path $scriptPath -ChildPath "Restore-GitVersion.ps1"

# Vérifier que tous les scripts nécessaires existent
$requiredScripts = @($gitOperationPath, $historyPath, $comparePath, $restorePath)
foreach ($script in $requiredScripts) {
    if (-not (Test-Path -Path $script)) {
        Write-Log "Required script not found: $script" -Level "Error"
        exit 1
    }
}

# Importer les scripts
. $gitOperationPath
. $historyPath
. $comparePath
. $restorePath

# Fonction pour obtenir le statut du dépôt
function Get-RepositoryStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath
    )
    
    try {
        Push-Location -Path $RepositoryPath
        
        # Obtenir la branche actuelle
        $branch = git rev-parse --abbrev-ref HEAD
        
        # Obtenir le dernier commit
        $lastCommit = git log -1 --pretty=format:"%h - %an, %ar : %s"
        
        # Obtenir le statut
        $status = Invoke-GitOperation -Operation "Status" -RepositoryPath $RepositoryPath
        
        # Construire le résultat
        $result = @{
            Branch = $branch
            LastCommit = $lastCommit
            IsClean = $status.is_clean
            Changes = $status.changes
        }
        
        return $result
    } catch {
        Write-Log "Error getting repository status: $_" -Level "Error"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour afficher le menu principal
function Show-MainMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $true)]
        [object]$Status
    )
    
    # Définir les couleurs
    $headerColor = "Cyan"
    $branchColor = "Green"
    $warningColor = "Yellow"
    $errorColor = "Red"
    $menuColor = "White"
    
    # Afficher l'en-tête
    Clear-Host
    Write-Host "Git UI - Main Menu" -ForegroundColor $headerColor
    Write-Host "Repository: $RepositoryPath" -ForegroundColor $headerColor
    Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
    
    # Afficher le statut
    Write-Host "Current branch: " -ForegroundColor $menuColor -NoNewline
    Write-Host $Status.Branch -ForegroundColor $branchColor
    
    Write-Host "Last commit: $($Status.LastCommit)" -ForegroundColor $menuColor
    
    if ($Status.IsClean) {
        Write-Host "Working directory is clean" -ForegroundColor $branchColor
    } else {
        Write-Host "Working directory has changes:" -ForegroundColor $warningColor
        
        if ($Status.Changes.staged -gt 0) {
            Write-Host "  - Staged changes: $($Status.Changes.staged)" -ForegroundColor $menuColor
        }
        
        if ($Status.Changes.modified -gt 0) {
            Write-Host "  - Modified files: $($Status.Changes.modified)" -ForegroundColor $menuColor
        }
        
        if ($Status.Changes.untracked -gt 0) {
            Write-Host "  - Untracked files: $($Status.Changes.untracked)" -ForegroundColor $menuColor
        }
        
        if ($Status.Changes.deleted -gt 0) {
            Write-Host "  - Deleted files: $($Status.Changes.deleted)" -ForegroundColor $menuColor
        }
    }
    
    Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
    
    # Afficher le menu
    Write-Host "1. View commit history" -ForegroundColor $menuColor
    Write-Host "2. Compare versions" -ForegroundColor $menuColor
    Write-Host "3. Restore previous version" -ForegroundColor $menuColor
    Write-Host "4. Manage branches" -ForegroundColor $menuColor
    Write-Host "5. Manage stashes" -ForegroundColor $menuColor
    Write-Host "6. Refresh status" -ForegroundColor $menuColor
    Write-Host "0. Exit" -ForegroundColor $menuColor
    
    Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
    
    # Demander à l'utilisateur de sélectionner une option
    Write-Host "Enter your choice (0-6): " -ForegroundColor $headerColor -NoNewline
    $choice = Read-Host
    
    return $choice
}

# Fonction pour gérer les branches
function Show-BranchMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath
    )
    
    # Définir les couleurs
    $headerColor = "Cyan"
    $branchColor = "Green"
    $currentBranchColor = "Yellow"
    $menuColor = "White"
    
    # Obtenir les branches
    try {
        Push-Location -Path $RepositoryPath
        
        # Obtenir la branche actuelle
        $currentBranch = git rev-parse --abbrev-ref HEAD
        
        # Obtenir toutes les branches
        $localBranches = git branch --list --format="%(refname:short)"
        $remoteBranches = git branch -r --format="%(refname:short)"
        
        # Afficher le menu
        Clear-Host
        Write-Host "Git UI - Branch Management" -ForegroundColor $headerColor
        Write-Host "Repository: $RepositoryPath" -ForegroundColor $headerColor
        Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
        
        Write-Host "Local branches:" -ForegroundColor $branchColor
        foreach ($branch in $localBranches) {
            if ($branch -eq $currentBranch) {
                Write-Host "* $branch (current)" -ForegroundColor $currentBranchColor
            } else {
                Write-Host "  $branch" -ForegroundColor $menuColor
            }
        }
        
        Write-Host "`nRemote branches:" -ForegroundColor $branchColor
        foreach ($branch in $remoteBranches) {
            Write-Host "  $branch" -ForegroundColor $menuColor
        }
        
        Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
        Write-Host "1. Create new branch" -ForegroundColor $menuColor
        Write-Host "2. Switch to branch" -ForegroundColor $menuColor
        Write-Host "3. Merge branch" -ForegroundColor $menuColor
        Write-Host "4. Delete branch" -ForegroundColor $menuColor
        Write-Host "0. Back to main menu" -ForegroundColor $menuColor
        Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
        
        # Demander à l'utilisateur de sélectionner une option
        Write-Host "Enter your choice (0-4): " -ForegroundColor $headerColor -NoNewline
        $choice = Read-Host
        
        switch ($choice) {
            "1" {
                # Créer une nouvelle branche
                Write-Host "Enter new branch name: " -ForegroundColor $headerColor -NoNewline
                $branchName = Read-Host
                
                if (-not [string]::IsNullOrEmpty($branchName)) {
                    Write-Host "Enter base branch (leave empty for current branch): " -ForegroundColor $headerColor -NoNewline
                    $baseBranch = Read-Host
                    
                    $result = Invoke-GitOperation -Operation "Branch" -RepositoryPath $RepositoryPath -BranchName $branchName -FilePath $baseBranch
                    
                    if ($result) {
                        Write-Host "Branch created successfully: $branchName" -ForegroundColor "Green"
                    } else {
                        Write-Host "Failed to create branch" -ForegroundColor "Red"
                    }
                    
                    Read-Host "Press Enter to continue"
                }
            }
            "2" {
                # Changer de branche
                Write-Host "Enter branch name to switch to: " -ForegroundColor $headerColor -NoNewline
                $branchName = Read-Host
                
                if (-not [string]::IsNullOrEmpty($branchName)) {
                    $result = Invoke-GitOperation -Operation "Checkout" -RepositoryPath $RepositoryPath -BranchName $branchName
                    
                    if ($result) {
                        Write-Host "Switched to branch: $branchName" -ForegroundColor "Green"
                    } else {
                        Write-Host "Failed to switch branch" -ForegroundColor "Red"
                    }
                    
                    Read-Host "Press Enter to continue"
                }
            }
            "3" {
                # Fusionner une branche
                Write-Host "Enter branch name to merge into current branch: " -ForegroundColor $headerColor -NoNewline
                $branchName = Read-Host
                
                if (-not [string]::IsNullOrEmpty($branchName)) {
                    $result = Invoke-GitOperation -Operation "Merge" -RepositoryPath $RepositoryPath -BranchName $branchName
                    
                    if ($result) {
                        Write-Host "Branch merged successfully: $branchName" -ForegroundColor "Green"
                    } else {
                        Write-Host "Failed to merge branch" -ForegroundColor "Red"
                    }
                    
                    Read-Host "Press Enter to continue"
                }
            }
            "4" {
                # Supprimer une branche
                Write-Host "Enter branch name to delete: " -ForegroundColor $headerColor -NoNewline
                $branchName = Read-Host
                
                if (-not [string]::IsNullOrEmpty($branchName)) {
                    if ($branchName -eq $currentBranch) {
                        Write-Host "Cannot delete the current branch" -ForegroundColor "Red"
                    } else {
                        $command = "git branch -d $branchName"
                        $output = Invoke-Expression $command
                        
                        if ($LASTEXITCODE -eq 0) {
                            Write-Host "Branch deleted successfully: $branchName" -ForegroundColor "Green"
                        } else {
                            Write-Host "Failed to delete branch. Use -D to force delete." -ForegroundColor "Red"
                        }
                    }
                    
                    Read-Host "Press Enter to continue"
                }
            }
        }
    } catch {
        Write-Log "Error managing branches: $_" -Level "Error"
    } finally {
        Pop-Location
    }
}

# Fonction pour gérer les stashes
function Show-StashMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath
    )
    
    # Définir les couleurs
    $headerColor = "Cyan"
    $stashColor = "Green"
    $menuColor = "White"
    
    # Obtenir les stashes
    try {
        Push-Location -Path $RepositoryPath
        
        # Obtenir la liste des stashes
        $stashes = Invoke-GitOperation -Operation "Stash" -RepositoryPath $RepositoryPath -BranchName "List"
        
        # Afficher le menu
        Clear-Host
        Write-Host "Git UI - Stash Management" -ForegroundColor $headerColor
        Write-Host "Repository: $RepositoryPath" -ForegroundColor $headerColor
        Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
        
        Write-Host "Stashes:" -ForegroundColor $stashColor
        if ($null -eq $stashes -or $stashes.Count -eq 0) {
            Write-Host "  No stashes found" -ForegroundColor $menuColor
        } else {
            foreach ($stash in $stashes) {
                Write-Host "  $stash" -ForegroundColor $menuColor
            }
        }
        
        Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
        Write-Host "1. Create new stash" -ForegroundColor $menuColor
        Write-Host "2. Apply stash" -ForegroundColor $menuColor
        Write-Host "3. Pop stash" -ForegroundColor $menuColor
        Write-Host "4. Drop stash" -ForegroundColor $menuColor
        Write-Host "0. Back to main menu" -ForegroundColor $menuColor
        Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
        
        # Demander à l'utilisateur de sélectionner une option
        Write-Host "Enter your choice (0-4): " -ForegroundColor $headerColor -NoNewline
        $choice = Read-Host
        
        switch ($choice) {
            "1" {
                # Créer un nouveau stash
                Write-Host "Enter stash message (optional): " -ForegroundColor $headerColor -NoNewline
                $message = Read-Host
                
                $result = Invoke-GitOperation -Operation "Stash" -RepositoryPath $RepositoryPath -BranchName "Save" -Message $message
                
                if ($null -ne $result) {
                    Write-Host "Stash created successfully" -ForegroundColor "Green"
                } else {
                    Write-Host "Failed to create stash" -ForegroundColor "Red"
                }
                
                Read-Host "Press Enter to continue"
            }
            "2" {
                # Appliquer un stash
                if ($null -ne $stashes -and $stashes.Count -gt 0) {
                    Write-Host "Enter stash index (0 for most recent): " -ForegroundColor $headerColor -NoNewline
                    $index = Read-Host
                    
                    $result = Invoke-GitOperation -Operation "Stash" -RepositoryPath $RepositoryPath -BranchName "Apply" -Message $index
                    
                    if ($null -ne $result) {
                        Write-Host "Stash applied successfully" -ForegroundColor "Green"
                    } else {
                        Write-Host "Failed to apply stash" -ForegroundColor "Red"
                    }
                } else {
                    Write-Host "No stashes to apply" -ForegroundColor "Red"
                }
                
                Read-Host "Press Enter to continue"
            }
            "3" {
                # Pop un stash
                if ($null -ne $stashes -and $stashes.Count -gt 0) {
                    Write-Host "Enter stash index (0 for most recent): " -ForegroundColor $headerColor -NoNewline
                    $index = Read-Host
                    
                    $result = Invoke-GitOperation -Operation "Stash" -RepositoryPath $RepositoryPath -BranchName "Pop" -Message $index
                    
                    if ($null -ne $result) {
                        Write-Host "Stash popped successfully" -ForegroundColor "Green"
                    } else {
                        Write-Host "Failed to pop stash" -ForegroundColor "Red"
                    }
                } else {
                    Write-Host "No stashes to pop" -ForegroundColor "Red"
                }
                
                Read-Host "Press Enter to continue"
            }
            "4" {
                # Supprimer un stash
                if ($null -ne $stashes -and $stashes.Count -gt 0) {
                    Write-Host "Enter stash index (0 for most recent): " -ForegroundColor $headerColor -NoNewline
                    $index = Read-Host
                    
                    $result = Invoke-GitOperation -Operation "Stash" -RepositoryPath $RepositoryPath -BranchName "Drop" -Message $index
                    
                    if ($null -ne $result) {
                        Write-Host "Stash dropped successfully" -ForegroundColor "Green"
                    } else {
                        Write-Host "Failed to drop stash" -ForegroundColor "Red"
                    }
                } else {
                    Write-Host "No stashes to drop" -ForegroundColor "Red"
                }
                
                Read-Host "Press Enter to continue"
            }
        }
    } catch {
        Write-Log "Error managing stashes: $_" -Level "Error"
    } finally {
        Pop-Location
    }
}

# Fonction principale
function Show-GitUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath
    )
    
    # Vérifier si Git est installé
    if (-not (Test-GitInstalled)) {
        Write-Log "Git must be installed to use the UI" -Level "Error"
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
    
    # Boucle principale
    $exit = $false
    
    while (-not $exit) {
        # Obtenir le statut du dépôt
        $status = Get-RepositoryStatus -RepositoryPath $RepositoryPath
        
        if ($null -eq $status) {
            Write-Log "Failed to get repository status" -Level "Error"
            return
        }
        
        # Afficher le menu principal
        $choice = Show-MainMenu -RepositoryPath $RepositoryPath -Status $status
        
        # Traiter le choix de l'utilisateur
        switch ($choice) {
            "0" {
                $exit = $true
            }
            "1" {
                # Afficher l'historique des commits
                Show-GitHistory -RepositoryPath $RepositoryPath
            }
            "2" {
                # Comparer des versions
                Compare-GitVersions -RepositoryPath $RepositoryPath
            }
            "3" {
                # Restaurer une version antérieure
                Restore-GitVersion -RepositoryPath $RepositoryPath
            }
            "4" {
                # Gérer les branches
                Show-BranchMenu -RepositoryPath $RepositoryPath
            }
            "5" {
                # Gérer les stashes
                Show-StashMenu -RepositoryPath $RepositoryPath
            }
            "6" {
                # Rafraîchir le statut (ne rien faire, la boucle s'en charge)
            }
            default {
                Write-Host "Invalid choice. Please try again." -ForegroundColor "Red"
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Show-GitUI -RepositoryPath $RepositoryPath
}
