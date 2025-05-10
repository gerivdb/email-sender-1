# Compare-GitVersions.ps1
# Script pour comparer des versions Git dans une interface utilisateur
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RepositoryPath,
    
    [Parameter(Mandatory = $false)]
    [string]$OldCommit,
    
    [Parameter(Mandatory = $false)]
    [string]$NewCommit,
    
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [switch]$ShowStats,
    
    [Parameter(Mandatory = $false)]
    [switch]$IgnoreWhitespace,
    
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
        [int]$Count = 10
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

# Fonction pour obtenir les fichiers modifiés entre deux commits
function Get-ChangedFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OldCommit,
        
        [Parameter(Mandatory = $true)]
        [string]$NewCommit
    )
    
    try {
        Push-Location -Path $RepositoryPath
        
        # Exécuter la commande
        $command = "git diff --name-status $OldCommit $NewCommit"
        $output = Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to get changed files" -Level "Error"
            return $null
        }
        
        # Analyser les résultats
        $files = @()
        
        foreach ($line in $output) {
            if (-not [string]::IsNullOrEmpty($line)) {
                $status = $line.Substring(0, 1)
                $path = $line.Substring(1).Trim()
                
                $file = @{
                    Status = switch ($status) {
                        "A" { "Added" }
                        "M" { "Modified" }
                        "D" { "Deleted" }
                        "R" { "Renamed" }
                        "C" { "Copied" }
                        default { $status }
                    }
                    Path = $path
                }
                
                $files += $file
            }
        }
        
        return $files
    } catch {
        Write-Log "Error getting changed files: $_" -Level "Error"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour obtenir les statistiques de diff
function Get-DiffStats {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OldCommit,
        
        [Parameter(Mandatory = $true)]
        [string]$NewCommit
    )
    
    try {
        Push-Location -Path $RepositoryPath
        
        # Exécuter la commande
        $command = "git diff --stat $OldCommit $NewCommit"
        $output = Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to get diff stats" -Level "Error"
            return $null
        }
        
        return $output
    } catch {
        Write-Log "Error getting diff stats: $_" -Level "Error"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour obtenir le diff entre deux commits
function Get-CommitDiff {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OldCommit,
        
        [Parameter(Mandatory = $true)]
        [string]$NewCommit,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreWhitespace
    )
    
    try {
        Push-Location -Path $RepositoryPath
        
        # Construire la commande
        $command = "git diff"
        
        if ($IgnoreWhitespace) {
            $command += " --ignore-all-space"
        }
        
        $command += " $OldCommit $NewCommit"
        
        if (-not [string]::IsNullOrEmpty($FilePath)) {
            $command += " -- `"$FilePath`""
        }
        
        # Exécuter la commande
        $output = Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to get commit diff" -Level "Error"
            return $null
        }
        
        return $output
    } catch {
        Write-Log "Error getting commit diff: $_" -Level "Error"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour afficher le diff coloré
function Show-ColoredDiff {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$Diff
    )
    
    foreach ($line in $Diff) {
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
}

# Fonction pour sélectionner un commit
function Select-GitCommit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Title = "Select a commit"
    )
    
    # Obtenir les commits récents
    $commits = Get-RecentCommits -RepositoryPath $RepositoryPath -Count 20
    
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
        [string]$OldCommit,
        
        [Parameter(Mandatory = $true)]
        [string]$NewCommit
    )
    
    # Obtenir les fichiers modifiés
    $files = Get-ChangedFiles -RepositoryPath $RepositoryPath -OldCommit $OldCommit -NewCommit $NewCommit
    
    if ($null -eq $files -or $files.Count -eq 0) {
        Write-Log "No changed files found" -Level "Warning"
        return $null
    }
    
    # Afficher la liste des fichiers
    Clear-Host
    Write-Host "Select a file to compare" -ForegroundColor "Cyan"
    Write-Host "----------------------------------------------------------------------" -ForegroundColor "Cyan"
    
    for ($i = 0; $i -lt $files.Count; $i++) {
        $file = $files[$i]
        $color = switch ($file.Status) {
            "Added" { "Green" }
            "Modified" { "Yellow" }
            "Deleted" { "Red" }
            "Renamed" { "Magenta" }
            "Copied" { "Cyan" }
            default { "White" }
        }
        
        Write-Host "$($i + 1). [$($file.Status)] $($file.Path)" -ForegroundColor $color
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
            return $files[$selection - 1].Path
        } else {
            Write-Host "Invalid selection. Please try again." -ForegroundColor "Red"
        }
    } while ($true)
}

# Fonction principale
function Compare-GitVersions {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OldCommit,
        
        [Parameter(Mandatory = $false)]
        [string]$NewCommit,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$ShowStats,
        
        [Parameter(Mandatory = $false)]
        [switch]$IgnoreWhitespace
    )
    
    # Vérifier si Git est installé
    if (-not (Test-GitInstalled)) {
        Write-Log "Git must be installed to compare versions" -Level "Error"
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
    
    # Sélectionner les commits si non fournis
    if ([string]::IsNullOrEmpty($OldCommit)) {
        $OldCommit = Select-GitCommit -RepositoryPath $RepositoryPath -Title "Select the OLD commit"
        
        if ($null -eq $OldCommit) {
            Write-Log "No old commit selected" -Level "Warning"
            return
        }
    }
    
    if ([string]::IsNullOrEmpty($NewCommit)) {
        $NewCommit = Select-GitCommit -RepositoryPath $RepositoryPath -Title "Select the NEW commit"
        
        if ($null -eq $NewCommit) {
            Write-Log "No new commit selected" -Level "Warning"
            return
        }
    }
    
    # Sélectionner un fichier si non fourni
    if ([string]::IsNullOrEmpty($FilePath)) {
        $FilePath = Select-GitFile -RepositoryPath $RepositoryPath -OldCommit $OldCommit -NewCommit $NewCommit
    }
    
    # Afficher les statistiques si demandé
    if ($ShowStats) {
        $stats = Get-DiffStats -RepositoryPath $RepositoryPath -OldCommit $OldCommit -NewCommit $NewCommit
        
        if ($null -ne $stats) {
            Clear-Host
            Write-Host "Diff Statistics" -ForegroundColor "Cyan"
            Write-Host "----------------------------------------------------------------------" -ForegroundColor "Cyan"
            
            foreach ($line in $stats) {
                Write-Host $line
            }
            
            Write-Host "----------------------------------------------------------------------" -ForegroundColor "Cyan"
            Write-Host "Press any key to continue..." -ForegroundColor "Cyan"
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        }
    }
    
    # Obtenir et afficher le diff
    $diff = Get-CommitDiff -RepositoryPath $RepositoryPath -OldCommit $OldCommit -NewCommit $NewCommit -FilePath $FilePath -IgnoreWhitespace:$IgnoreWhitespace
    
    if ($null -ne $diff) {
        Clear-Host
        Write-Host "Comparing commits" -ForegroundColor "Cyan"
        Write-Host "Old: $OldCommit" -ForegroundColor "Red"
        Write-Host "New: $NewCommit" -ForegroundColor "Green"
        
        if (-not [string]::IsNullOrEmpty($FilePath)) {
            Write-Host "File: $FilePath" -ForegroundColor "Yellow"
        }
        
        Write-Host "----------------------------------------------------------------------" -ForegroundColor "Cyan"
        
        Show-ColoredDiff -Diff $diff
        
        Write-Host "----------------------------------------------------------------------" -ForegroundColor "Cyan"
        Write-Host "Press any key to exit..." -ForegroundColor "Cyan"
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } else {
        Write-Log "Failed to get diff" -Level "Error"
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Compare-GitVersions -RepositoryPath $RepositoryPath -OldCommit $OldCommit -NewCommit $NewCommit -FilePath $FilePath -ShowStats:$ShowStats -IgnoreWhitespace:$IgnoreWhitespace
}
