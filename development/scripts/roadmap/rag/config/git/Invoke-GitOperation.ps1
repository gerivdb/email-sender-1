# Invoke-GitOperation.ps1
# Script pour gérer les opérations Git de base
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet("Status", "Add", "Commit", "Push", "Pull", "Checkout", "Branch", "Merge", "Tag", "Log", "Reset", "Stash", "Clone")]
    [string]$Operation = "Status",
    
    [Parameter(Mandatory = $false)]
    [string]$RepositoryPath,
    
    [Parameter(Mandatory = $false)]
    [string]$Message,
    
    [Parameter(Mandatory = $false)]
    [string]$BranchName,
    
    [Parameter(Mandatory = $false)]
    [string]$TagName,
    
    [Parameter(Mandatory = $false)]
    [string]$Remote = "origin",
    
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
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

# Fonction pour vérifier si un répertoire est un dépôt Git
function Test-GitRepository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    $gitDir = Join-Path -Path $Path -ChildPath ".git"
    
    if (Test-Path -Path $gitDir -PathType Container) {
        Write-Log "Directory is a Git repository: $Path" -Level "Debug"
        return $true
    } else {
        Write-Log "Directory is not a Git repository: $Path" -Level "Warning"
        return $false
    }
}

# Fonction pour obtenir le statut du dépôt
function Get-GitStatus {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        Push-Location -Path $Path
        
        $status = git status --porcelain=v2
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to get Git status" -Level "Error"
            return $null
        }
        
        # Analyser le statut
        $result = @{
            branch = git rev-parse --abbrev-ref HEAD
            changes = @{
                staged = 0
                modified = 0
                untracked = 0
                deleted = 0
                renamed = 0
            }
            is_clean = $status.Count -eq 0
        }
        
        foreach ($line in $status) {
            if ($line -match "^1 .M") {
                $result.changes.modified++
            } elseif ($line -match "^1 A.") {
                $result.changes.staged++
            } elseif ($line -match "^1 .A") {
                $result.changes.untracked++
            } elseif ($line -match "^1 .D") {
                $result.changes.deleted++
            } elseif ($line -match "^1 .R") {
                $result.changes.renamed++
            } elseif ($line -match "^1 M.") {
                $result.changes.staged++
            } elseif ($line -match "^1 D.") {
                $result.changes.staged++
            } elseif ($line -match "^1 R.") {
                $result.changes.staged++
            } elseif ($line -match "^\? ") {
                $result.changes.untracked++
            }
        }
        
        Write-Log "Git status retrieved successfully" -Level "Info"
        return $result
    } catch {
        Write-Log "Error getting Git status: $_" -Level "Error"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour ajouter des fichiers à l'index
function Add-GitFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath
    )
    
    try {
        Push-Location -Path $Path
        
        if ([string]::IsNullOrEmpty($FilePath)) {
            # Ajouter tous les fichiers
            git add .
        } else {
            # Ajouter un fichier spécifique
            git add $FilePath
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to add files to Git index" -Level "Error"
            return $false
        }
        
        Write-Log "Files added to Git index successfully" -Level "Info"
        return $true
    } catch {
        Write-Log "Error adding files to Git index: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour créer un commit
function New-GitCommit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$Message
    )
    
    try {
        Push-Location -Path $Path
        
        git commit -m $Message
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to create Git commit" -Level "Error"
            return $false
        }
        
        Write-Log "Git commit created successfully" -Level "Info"
        return $true
    } catch {
        Write-Log "Error creating Git commit: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour pousser les modifications
function Push-GitChanges {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Remote = "origin",
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    try {
        Push-Location -Path $Path
        
        # Obtenir la branche actuelle si non spécifiée
        if ([string]::IsNullOrEmpty($BranchName)) {
            $BranchName = git rev-parse --abbrev-ref HEAD
        }
        
        # Construire la commande
        $command = "git push $Remote $BranchName"
        
        if ($Force) {
            $command += " --force"
        }
        
        # Exécuter la commande
        Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to push Git changes" -Level "Error"
            return $false
        }
        
        Write-Log "Git changes pushed successfully" -Level "Info"
        return $true
    } catch {
        Write-Log "Error pushing Git changes: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour tirer les modifications
function Get-GitChanges {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Remote = "origin",
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName
    )
    
    try {
        Push-Location -Path $Path
        
        # Obtenir la branche actuelle si non spécifiée
        if ([string]::IsNullOrEmpty($BranchName)) {
            $BranchName = git rev-parse --abbrev-ref HEAD
        }
        
        git pull $Remote $BranchName
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to pull Git changes" -Level "Error"
            return $false
        }
        
        Write-Log "Git changes pulled successfully" -Level "Info"
        return $true
    } catch {
        Write-Log "Error pulling Git changes: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour changer de branche
function Switch-GitBranch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Create
    )
    
    try {
        Push-Location -Path $Path
        
        # Construire la commande
        $command = "git checkout"
        
        if ($Create) {
            $command += " -b"
        }
        
        $command += " $BranchName"
        
        # Exécuter la commande
        Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to switch Git branch" -Level "Error"
            return $false
        }
        
        Write-Log "Git branch switched successfully to: $BranchName" -Level "Info"
        return $true
    } catch {
        Write-Log "Error switching Git branch: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour créer une branche
function New-GitBranch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [string]$BaseBranch
    )
    
    try {
        Push-Location -Path $Path
        
        # Changer de branche de base si spécifiée
        if (-not [string]::IsNullOrEmpty($BaseBranch)) {
            git checkout $BaseBranch
            
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Failed to checkout base branch: $BaseBranch" -Level "Error"
                return $false
            }
        }
        
        # Créer la nouvelle branche
        git checkout -b $BranchName
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to create Git branch: $BranchName" -Level "Error"
            return $false
        }
        
        Write-Log "Git branch created successfully: $BranchName" -Level "Info"
        return $true
    } catch {
        Write-Log "Error creating Git branch: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour fusionner des branches
function Merge-GitBranch {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [switch]$NoFastForward
    )
    
    try {
        Push-Location -Path $Path
        
        # Construire la commande
        $command = "git merge"
        
        if ($NoFastForward) {
            $command += " --no-ff"
        }
        
        $command += " $BranchName"
        
        # Exécuter la commande
        Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to merge Git branch: $BranchName" -Level "Error"
            return $false
        }
        
        Write-Log "Git branch merged successfully: $BranchName" -Level "Info"
        return $true
    } catch {
        Write-Log "Error merging Git branch: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour créer un tag
function New-GitTag {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $true)]
        [string]$TagName,
        
        [Parameter(Mandatory = $false)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [switch]$Push
    )
    
    try {
        Push-Location -Path $Path
        
        # Construire la commande
        if ([string]::IsNullOrEmpty($Message)) {
            # Tag léger
            git tag $TagName
        } else {
            # Tag annoté
            git tag -a $TagName -m $Message
        }
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to create Git tag: $TagName" -Level "Error"
            return $false
        }
        
        # Pousser le tag si demandé
        if ($Push) {
            git push origin $TagName
            
            if ($LASTEXITCODE -ne 0) {
                Write-Log "Failed to push Git tag: $TagName" -Level "Error"
                return $false
            }
        }
        
        Write-Log "Git tag created successfully: $TagName" -Level "Info"
        return $true
    } catch {
        Write-Log "Error creating Git tag: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour afficher l'historique
function Get-GitLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [int]$Count = 10,
        
        [Parameter(Mandatory = $false)]
        [string]$Format = "oneline"
    )
    
    try {
        Push-Location -Path $Path
        
        # Construire la commande
        $command = "git log -n $Count"
        
        if ($Format -eq "oneline") {
            $command += " --oneline"
        } elseif ($Format -eq "full") {
            $command += " --pretty=full"
        } elseif ($Format -eq "graph") {
            $command += " --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"
        }
        
        # Exécuter la commande
        $log = Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to get Git log" -Level "Error"
            return $null
        }
        
        Write-Log "Git log retrieved successfully" -Level "Info"
        return $log
    } catch {
        Write-Log "Error getting Git log: $_" -Level "Error"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour réinitialiser les modifications
function Reset-GitChanges {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Soft", "Mixed", "Hard")]
        [string]$Mode = "Mixed",
        
        [Parameter(Mandatory = $false)]
        [string]$Commit = "HEAD"
    )
    
    try {
        Push-Location -Path $Path
        
        # Construire la commande
        $command = "git reset"
        
        if ($Mode -eq "Soft") {
            $command += " --soft"
        } elseif ($Mode -eq "Hard") {
            $command += " --hard"
        }
        
        $command += " $Commit"
        
        # Exécuter la commande
        Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to reset Git changes" -Level "Error"
            return $false
        }
        
        Write-Log "Git changes reset successfully (Mode: $Mode)" -Level "Info"
        return $true
    } catch {
        Write-Log "Error resetting Git changes: $_" -Level "Error"
        return $false
    } finally {
        Pop-Location
    }
}

# Fonction pour gérer les stash
function Invoke-GitStash {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Save", "Pop", "Apply", "List", "Drop")]
        [string]$Action = "Save",
        
        [Parameter(Mandatory = $false)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [int]$Index = 0
    )
    
    try {
        Push-Location -Path $Path
        
        # Construire la commande
        $command = "git stash"
        
        if ($Action -eq "Save") {
            if (-not [string]::IsNullOrEmpty($Message)) {
                $command += " push -m `"$Message`""
            } else {
                $command += " push"
            }
        } elseif ($Action -eq "Pop") {
            if ($Index -gt 0) {
                $command += " pop stash@{$Index}"
            } else {
                $command += " pop"
            }
        } elseif ($Action -eq "Apply") {
            if ($Index -gt 0) {
                $command += " apply stash@{$Index}"
            } else {
                $command += " apply"
            }
        } elseif ($Action -eq "List") {
            $command += " list"
        } elseif ($Action -eq "Drop") {
            if ($Index -gt 0) {
                $command += " drop stash@{$Index}"
            } else {
                $command += " drop"
            }
        }
        
        # Exécuter la commande
        $result = Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to perform Git stash operation: $Action" -Level "Error"
            return $null
        }
        
        Write-Log "Git stash operation performed successfully: $Action" -Level "Info"
        return $result
    } catch {
        Write-Log "Error performing Git stash operation: $_" -Level "Error"
        return $null
    } finally {
        Pop-Location
    }
}

# Fonction pour cloner un dépôt
function Copy-GitRepository {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,
        
        [Parameter(Mandatory = $false)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Branch
    )
    
    try {
        # Construire la commande
        $command = "git clone"
        
        if (-not [string]::IsNullOrEmpty($Branch)) {
            $command += " -b $Branch"
        }
        
        $command += " $Url"
        
        if (-not [string]::IsNullOrEmpty($Path)) {
            $command += " `"$Path`""
        }
        
        # Exécuter la commande
        Invoke-Expression $command
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "Failed to clone Git repository: $Url" -Level "Error"
            return $false
        }
        
        Write-Log "Git repository cloned successfully: $Url" -Level "Info"
        return $true
    } catch {
        Write-Log "Error cloning Git repository: $_" -Level "Error"
        return $false
    }
}

# Fonction principale
function Invoke-GitOperation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Status", "Add", "Commit", "Push", "Pull", "Checkout", "Branch", "Merge", "Tag", "Log", "Reset", "Stash", "Clone")]
        [string]$Operation = "Status",
        
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$BranchName,
        
        [Parameter(Mandatory = $false)]
        [string]$TagName,
        
        [Parameter(Mandatory = $false)]
        [string]$Remote = "origin",
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si Git est installé
    if (-not (Test-GitInstalled)) {
        Write-Log "Git must be installed to perform operations" -Level "Error"
        return $null
    }
    
    # Vérifier si un chemin de dépôt est fourni
    if ([string]::IsNullOrEmpty($RepositoryPath)) {
        $RepositoryPath = Get-Location
    }
    
    # Vérifier si le répertoire existe
    if (-not (Test-Path -Path $RepositoryPath)) {
        Write-Log "Repository path does not exist: $RepositoryPath" -Level "Error"
        return $null
    }
    
    # Vérifier si le répertoire est un dépôt Git (sauf pour l'opération Clone)
    if ($Operation -ne "Clone" -and -not (Test-GitRepository -Path $RepositoryPath)) {
        Write-Log "Directory is not a Git repository: $RepositoryPath" -Level "Error"
        return $null
    }
    
    # Exécuter l'opération demandée
    $result = $null
    
    switch ($Operation) {
        "Status" {
            $result = Get-GitStatus -Path $RepositoryPath
        }
        "Add" {
            $result = Add-GitFiles -Path $RepositoryPath -FilePath $FilePath
        }
        "Commit" {
            if ([string]::IsNullOrEmpty($Message)) {
                Write-Log "Message is required for Commit operation" -Level "Error"
                return $null
            }
            
            $result = New-GitCommit -Path $RepositoryPath -Message $Message
        }
        "Push" {
            $result = Push-GitChanges -Path $RepositoryPath -Remote $Remote -BranchName $BranchName -Force:$Force
        }
        "Pull" {
            $result = Get-GitChanges -Path $RepositoryPath -Remote $Remote -BranchName $BranchName
        }
        "Checkout" {
            if ([string]::IsNullOrEmpty($BranchName)) {
                Write-Log "BranchName is required for Checkout operation" -Level "Error"
                return $null
            }
            
            $result = Switch-GitBranch -Path $RepositoryPath -BranchName $BranchName
        }
        "Branch" {
            if ([string]::IsNullOrEmpty($BranchName)) {
                Write-Log "BranchName is required for Branch operation" -Level "Error"
                return $null
            }
            
            $result = New-GitBranch -Path $RepositoryPath -BranchName $BranchName -BaseBranch $FilePath
        }
        "Merge" {
            if ([string]::IsNullOrEmpty($BranchName)) {
                Write-Log "BranchName is required for Merge operation" -Level "Error"
                return $null
            }
            
            $result = Merge-GitBranch -Path $RepositoryPath -BranchName $BranchName -NoFastForward:$Force
        }
        "Tag" {
            if ([string]::IsNullOrEmpty($TagName)) {
                Write-Log "TagName is required for Tag operation" -Level "Error"
                return $null
            }
            
            $result = New-GitTag -Path $RepositoryPath -TagName $TagName -Message $Message -Push:$Force
        }
        "Log" {
            $result = Get-GitLog -Path $RepositoryPath -Count 10 -Format "graph"
        }
        "Reset" {
            $mode = "Mixed"
            if (-not [string]::IsNullOrEmpty($Message)) {
                $mode = $Message
            }
            
            $commit = "HEAD"
            if (-not [string]::IsNullOrEmpty($BranchName)) {
                $commit = $BranchName
            }
            
            $result = Reset-GitChanges -Path $RepositoryPath -Mode $mode -Commit $commit
        }
        "Stash" {
            $action = "Save"
            if (-not [string]::IsNullOrEmpty($BranchName)) {
                $action = $BranchName
            }
            
            $result = Invoke-GitStash -Path $RepositoryPath -Action $action -Message $Message
        }
        "Clone" {
            if ([string]::IsNullOrEmpty($Remote)) {
                Write-Log "Remote (URL) is required for Clone operation" -Level "Error"
                return $null
            }
            
            $result = Copy-GitRepository -Url $Remote -Path $RepositoryPath -Branch $BranchName
        }
    }
    
    return $result
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-GitOperation -Operation $Operation -RepositoryPath $RepositoryPath -Message $Message -BranchName $BranchName -TagName $TagName -Remote $Remote -FilePath $FilePath -Force:$Force
}

