# Show-GitHistory.ps1
# Script pour afficher l'historique Git dans une interface utilisateur
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RepositoryPath,
    
    [Parameter(Mandatory = $false)]
    [string]$BranchName,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxCommits = 50,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeAllBranches,
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowGraph,
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowDiff,
    
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

# Fonction pour obtenir l'historique Git
function Get-GitHistoryData {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxCommits = 50,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllBranches
    )
    
    try {
        Push-Location -Path $RepositoryPath
        
        # Construire la commande Git
        $command = "git log"
        
        if (-not $IncludeAllBranches) {
            if ([string]::IsNullOrEmpty($BranchName)) {
                $BranchName = git rev-parse --abbrev-ref HEAD
            }
            
            $command += " $BranchName"
        } else {
            $command += " --all"
        }
        
        $command += " --pretty=format:'%H|%h|%an|%ae|%ad|%s|%d' --date=format:'%Y-%m-%d %H:%M:%S' -n $MaxCommits"
        
        # Exécuter la commande
        $output = Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to get Git history" -Level "Error"
            return $null
        }
        
        # Analyser les résultats
        $commits = @()
        
        foreach ($line in $output) {
            if (-not [string]::IsNullOrEmpty($line)) {
                $parts = $line.Trim("'").Split("|")
                
                if ($parts.Count -ge 6) {
                    $commit = @{
                        Hash = $parts[0]
                        ShortHash = $parts[1]
                        Author = $parts[2]
                        Email = $parts[3]
                        Date = $parts[4]
                        Subject = $parts[5]
                        Refs = if ($parts.Count -gt 6) { $parts[6].Trim() } else { "" }
                    }
                    
                    $commits += $commit
                }
            }
        }
        
        return $commits
    } catch {
        Write-Log "Error getting Git history: $_" -Level "Error"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour obtenir le graphe Git
function Get-GitGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxCommits = 50,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllBranches
    )
    
    try {
        Push-Location -Path $RepositoryPath
        
        # Construire la commande Git
        $command = "git log"
        
        if (-not $IncludeAllBranches) {
            if ([string]::IsNullOrEmpty($BranchName)) {
                $BranchName = git rev-parse --abbrev-ref HEAD
            }
            
            $command += " $BranchName"
        } else {
            $command += " --all"
        }
        
        $command += " --graph --pretty=format:'%C(auto)%h%d %s %C(bold blue)<%an>%Creset %C(green)(%cr)%Creset' -n $MaxCommits"
        
        # Exécuter la commande
        $output = Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to get Git graph" -Level "Error"
            return $null
        }
        
        return $output
    } catch {
        Write-Log "Error getting Git graph: $_" -Level "Error"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour obtenir les différences d'un commit
function Get-GitCommitDiff {
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
        $diff = git show --color=always $CommitHash
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to get Git commit diff" -Level "Error"
            return $null
        }
        
        return $diff
    } catch {
        Write-Log "Error getting Git commit diff: $_" -Level "Error"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour créer une interface utilisateur en console
function Show-ConsoleUI {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object[]]$Commits,
        
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowDiff
    )
    
    # Définir les couleurs
    $headerColor = "Cyan"
    $selectedColor = "Green"
    $normalColor = "White"
    $refColor = "Yellow"
    
    # Variables pour la navigation
    $currentIndex = 0
    $pageSize = [Math]::Min($Host.UI.RawUI.WindowSize.Height - 5, 20)
    $startIndex = 0
    $endIndex = [Math]::Min($startIndex + $pageSize - 1, $Commits.Count - 1)
    $showingDiff = $false
    $diffCommit = $null
    
    # Fonction pour afficher l'en-tête
    function Show-Header {
        Clear-Host
        Write-Host "Git History Viewer" -ForegroundColor $headerColor
        Write-Host "Repository: $RepositoryPath" -ForegroundColor $headerColor
        Write-Host "Use arrow keys to navigate, Enter to view details, D to toggle diff, Q to quit" -ForegroundColor $headerColor
        Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
    }
    
    # Fonction pour afficher la liste des commits
    function Show-CommitList {
        for ($i = $startIndex; $i -le $endIndex; $i++) {
            $commit = $Commits[$i]
            $color = if ($i -eq $currentIndex) { $selectedColor } else { $normalColor }
            
            $line = "{0} {1} {2}" -f $commit.ShortHash, $commit.Date, $commit.Subject
            
            if (-not [string]::IsNullOrEmpty($commit.Refs)) {
                $line += " " + $commit.Refs
            }
            
            if ($i -eq $currentIndex) {
                Write-Host "> $line" -ForegroundColor $color
            } else {
                Write-Host "  $line" -ForegroundColor $color
            }
        }
        
        Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
        Write-Host "Showing commits $($startIndex + 1) to $($endIndex + 1) of $($Commits.Count)" -ForegroundColor $headerColor
    }
    
    # Fonction pour afficher les détails d'un commit
    function Show-CommitDetails {
        param (
            [Parameter(Mandatory = $true)]
            [object]$Commit
        )
        
        Clear-Host
        Write-Host "Commit Details" -ForegroundColor $headerColor
        Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
        Write-Host "Hash:    $($Commit.Hash)" -ForegroundColor $normalColor
        Write-Host "Author:  $($Commit.Author) <$($Commit.Email)>" -ForegroundColor $normalColor
        Write-Host "Date:    $($Commit.Date)" -ForegroundColor $normalColor
        Write-Host "Subject: $($Commit.Subject)" -ForegroundColor $normalColor
        
        if (-not [string]::IsNullOrEmpty($Commit.Refs)) {
            Write-Host "Refs:    $($Commit.Refs)" -ForegroundColor $refColor
        }
        
        Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
        
        if ($ShowDiff) {
            Write-Host "Diff:" -ForegroundColor $headerColor
            $diff = Get-GitCommitDiff -RepositoryPath $RepositoryPath -CommitHash $Commit.Hash
            
            if ($null -ne $diff) {
                foreach ($line in $diff) {
                    if ($line -match "^diff --git") {
                        Write-Host $line -ForegroundColor "Magenta"
                    } elseif ($line -match "^index") {
                        Write-Host $line -ForegroundColor "DarkGray"
                    } elseif ($line -match "^---") {
                        Write-Host $line -ForegroundColor "Red"
                    } elseif ($line -match "^\+\+\+") {
                        Write-Host $line -ForegroundColor "Green"
                    } elseif ($line -match "^-") {
                        Write-Host $line -ForegroundColor "Red"
                    } elseif ($line -match "^\+") {
                        Write-Host $line -ForegroundColor "Green"
                    } elseif ($line -match "^@@") {
                        Write-Host $line -ForegroundColor "Cyan"
                    } else {
                        Write-Host $line
                    }
                }
            } else {
                Write-Host "Failed to get diff" -ForegroundColor "Red"
            }
        }
        
        Write-Host "----------------------------------------------------------------------" -ForegroundColor $headerColor
        Write-Host "Press any key to return to the commit list..." -ForegroundColor $headerColor
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    # Boucle principale
    while ($true) {
        if ($showingDiff) {
            Show-CommitDetails -Commit $diffCommit
            $showingDiff = $false
        } else {
            Show-Header
            Show-CommitList
        }
        
        # Lire la touche
        $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        # Traiter la touche
        switch ($key.VirtualKeyCode) {
            38 { # Flèche haut
                if ($currentIndex -gt 0) {
                    $currentIndex--
                    
                    if ($currentIndex -lt $startIndex) {
                        $startIndex = [Math]::Max(0, $startIndex - $pageSize)
                        $endIndex = [Math]::Min($startIndex + $pageSize - 1, $Commits.Count - 1)
                    }
                }
            }
            40 { # Flèche bas
                if ($currentIndex -lt $Commits.Count - 1) {
                    $currentIndex++
                    
                    if ($currentIndex -gt $endIndex) {
                        $startIndex = [Math]::Min($startIndex + $pageSize, $Commits.Count - $pageSize)
                        $endIndex = [Math]::Min($startIndex + $pageSize - 1, $Commits.Count - 1)
                    }
                }
            }
            33 { # Page Up
                $startIndex = [Math]::Max(0, $startIndex - $pageSize)
                $endIndex = [Math]::Min($startIndex + $pageSize - 1, $Commits.Count - 1)
                $currentIndex = $startIndex
            }
            34 { # Page Down
                $startIndex = [Math]::Min($startIndex + $pageSize, $Commits.Count - $pageSize)
                $endIndex = [Math]::Min($startIndex + $pageSize - 1, $Commits.Count - 1)
                $currentIndex = $startIndex
            }
            36 { # Home
                $startIndex = 0
                $endIndex = [Math]::Min($startIndex + $pageSize - 1, $Commits.Count - 1)
                $currentIndex = 0
            }
            35 { # End
                $startIndex = [Math]::Max(0, $Commits.Count - $pageSize)
                $endIndex = $Commits.Count - 1
                $currentIndex = $Commits.Count - 1
            }
            13 { # Enter
                $showingDiff = $true
                $diffCommit = $Commits[$currentIndex]
            }
            68 { # D
                $ShowDiff = -not $ShowDiff
            }
            81 { # Q
                return
            }
        }
    }
}

# Fonction pour afficher l'historique Git
function Show-GitHistory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxCommits = 50,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeAllBranches,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowGraph,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowDiff
    )
    
    # Vérifier si Git est installé
    if (-not (Test-GitInstalled)) {
        Write-Log "Git must be installed to show history" -Level "Error"
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
    
    # Obtenir l'historique Git
    if ($ShowGraph) {
        $graph = Get-GitGraph -RepositoryPath $RepositoryPath -BranchName $BranchName -MaxCommits $MaxCommits -IncludeAllBranches:$IncludeAllBranches
        
        if ($null -eq $graph) {
            Write-Log "Failed to get Git graph" -Level "Error"
            return
        }
        
        # Afficher le graphe
        Clear-Host
        Write-Host "Git History Graph" -ForegroundColor "Cyan"
        Write-Host "Repository: $RepositoryPath" -ForegroundColor "Cyan"
        Write-Host "----------------------------------------------------------------------" -ForegroundColor "Cyan"
        
        foreach ($line in $graph) {
            Write-Host $line
        }
        
        Write-Host "----------------------------------------------------------------------" -ForegroundColor "Cyan"
        Write-Host "Press any key to exit..." -ForegroundColor "Cyan"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        $commits = Get-GitHistoryData -RepositoryPath $RepositoryPath -BranchName $BranchName -MaxCommits $MaxCommits -IncludeAllBranches:$IncludeAllBranches
        
        if ($null -eq $commits -or $commits.Count -eq 0) {
            Write-Log "No commits found" -Level "Warning"
            return
        }
        
        # Afficher l'interface utilisateur
        Show-ConsoleUI -Commits $commits -RepositoryPath $RepositoryPath -ShowDiff:$ShowDiff
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Show-GitHistory -RepositoryPath $RepositoryPath -BranchName $BranchName -MaxCommits $MaxCommits -IncludeAllBranches:$IncludeAllBranches -ShowGraph:$ShowGraph -ShowDiff:$ShowDiff
}
