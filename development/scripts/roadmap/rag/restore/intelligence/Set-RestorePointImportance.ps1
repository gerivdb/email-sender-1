# Set-RestorePointImportance.ps1
# Script pour classifier les points de restauration par importance
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RestorePointId,
    
    [Parameter(Mandatory = $false)]
    [string]$RestorePointPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Critical", "High", "Medium", "Low", "Auto")]
    [string]$Importance = "Auto",
    
    [Parameter(Mandatory = $false)]
    [string]$Reason,
    
    [Parameter(Mandatory = $false)]
    [switch]$Recalculate,
    
    [Parameter(Mandatory = $false)]
    [switch]$RecalculateAll,
    
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

# Fonction pour obtenir le chemin du répertoire des points de restauration
function Get-RestorePointsPath {
    [CmdletBinding()]
    param()
    
    $pointsPath = Join-Path -Path $rootPath -ChildPath "points"
    
    if (-not (Test-Path -Path $pointsPath)) {
        New-Item -Path $pointsPath -ItemType Directory -Force | Out-Null
    }
    
    return $pointsPath
}

# Fonction pour charger un point de restauration
function Get-RestorePoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RestorePointId,
        
        [Parameter(Mandatory = $false)]
        [string]$RestorePointPath
    )
    
    # Déterminer le chemin du point de restauration
    if ([string]::IsNullOrEmpty($RestorePointPath)) {
        if ([string]::IsNullOrEmpty($RestorePointId)) {
            Write-Log "Either RestorePointId or RestorePointPath must be provided" -Level "Error"
            return $null
        }
        
        $pointsPath = Get-RestorePointsPath
        $RestorePointPath = Join-Path -Path $pointsPath -ChildPath "$RestorePointId.json"
    }
    
    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $RestorePointPath)) {
        Write-Log "Restore point file not found: $RestorePointPath" -Level "Error"
        return $null
    }
    
    # Charger le point de restauration
    try {
        $restorePoint = Get-Content -Path $RestorePointPath -Raw | ConvertFrom-Json
        return $restorePoint
    } catch {
        Write-Log "Error loading restore point: $_" -Level "Error"
        return $null
    }
}

# Fonction pour sauvegarder un point de restauration
function Save-RestorePoint {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$RestorePoint,
        
        [Parameter(Mandatory = $false)]
        [string]$RestorePointPath
    )
    
    # Déterminer le chemin du point de restauration
    if ([string]::IsNullOrEmpty($RestorePointPath)) {
        $pointsPath = Get-RestorePointsPath
        $RestorePointPath = Join-Path -Path $pointsPath -ChildPath "$($RestorePoint.metadata.id).json"
    }
    
    # Sauvegarder le point de restauration
    try {
        $RestorePoint | ConvertTo-Json -Depth 10 | Out-File -FilePath $RestorePointPath -Encoding UTF8
        Write-Log "Restore point saved to: $RestorePointPath" -Level "Debug"
        return $true
    } catch {
        Write-Log "Error saving restore point: $_" -Level "Error"
        return $false
    }
}

# Fonction pour calculer l'importance automatique d'un point de restauration
function Get-AutoImportance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$RestorePoint
    )
    
    # Initialiser le score d'importance
    $importanceScore = 0
    $reasons = @()
    
    # Facteurs d'importance basés sur les métadonnées
    
    # 1. Type de point de restauration
    switch ($RestorePoint.metadata.type) {
        "manual" {
            # Les points manuels sont généralement plus importants
            $importanceScore += 20
            $reasons += "Manual restore point"
        }
        "pre-update" {
            # Les points pré-mise à jour sont critiques
            $importanceScore += 30
            $reasons += "Pre-update restore point"
        }
        "pre-migration" {
            # Les points pré-migration sont critiques
            $importanceScore += 30
            $reasons += "Pre-migration restore point"
        }
        "git-commit" {
            # Les points liés aux commits Git sont moyennement importants
            $importanceScore += 15
            $reasons += "Git commit restore point"
        }
        "scheduled" {
            # Les points planifiés sont moins importants
            $importanceScore += 10
            $reasons += "Scheduled restore point"
        }
        "automatic" {
            # Les points automatiques sont moins importants
            $importanceScore += 5
            $reasons += "Automatic restore point"
        }
    }
    
    # 2. Tags
    if ($null -ne $RestorePoint.metadata.tags) {
        foreach ($tag in $RestorePoint.metadata.tags) {
            switch ($tag) {
                "critical" {
                    $importanceScore += 30
                    $reasons += "Critical tag"
                }
                "important" {
                    $importanceScore += 20
                    $reasons += "Important tag"
                }
                "milestone" {
                    $importanceScore += 25
                    $reasons += "Milestone tag"
                }
                "release" {
                    $importanceScore += 25
                    $reasons += "Release tag"
                }
                "stable" {
                    $importanceScore += 15
                    $reasons += "Stable tag"
                }
                "test" {
                    $importanceScore -= 10
                    $reasons += "Test tag (negative impact)"
                }
                "temporary" {
                    $importanceScore -= 15
                    $reasons += "Temporary tag (negative impact)"
                }
            }
        }
    }
    
    # 3. Âge du point de restauration
    if ($RestorePoint.metadata.PSObject.Properties.Name.Contains("created_at")) {
        $createdAt = [DateTime]::Parse($RestorePoint.metadata.created_at)
        $ageInDays = (New-TimeSpan -Start $createdAt -End (Get-Date)).TotalDays
        
        if ($ageInDays < 1) {
            # Points très récents (moins d'un jour)
            $importanceScore += 15
            $reasons += "Very recent restore point (less than 1 day)"
        } elseif ($ageInDays < 7) {
            # Points récents (moins d'une semaine)
            $importanceScore += 10
            $reasons += "Recent restore point (less than 7 days)"
        } elseif ($ageInDays < 30) {
            # Points moyennement récents (moins d'un mois)
            $importanceScore += 5
            $reasons += "Moderately recent restore point (less than 30 days)"
        } elseif ($ageInDays > 90) {
            # Points anciens (plus de 3 mois)
            $importanceScore -= 10
            $reasons += "Old restore point (more than 90 days)"
        }
    }
    
    # 4. Nombre de configurations
    if ($null -ne $RestorePoint.content.configurations) {
        $configCount = $RestorePoint.content.configurations.Count
        
        if ($configCount > 10) {
            $importanceScore += 20
            $reasons += "Large number of configurations ($configCount)"
        } elseif ($configCount > 5) {
            $importanceScore += 10
            $reasons += "Multiple configurations ($configCount)"
        } elseif ($configCount > 0) {
            $importanceScore += 5
            $reasons += "Few configurations ($configCount)"
        }
    }
    
    # 5. Informations Git
    if ($RestorePoint.metadata.PSObject.Properties.Name.Contains("git_info")) {
        $gitInfo = $RestorePoint.metadata.git_info
        
        if ($gitInfo.PSObject.Properties.Name.Contains("branch")) {
            switch ($gitInfo.branch) {
                "main" {
                    $importanceScore += 20
                    $reasons += "Main branch commit"
                }
                "master" {
                    $importanceScore += 20
                    $reasons += "Master branch commit"
                }
                "develop" {
                    $importanceScore += 15
                    $reasons += "Develop branch commit"
                }
                "release" {
                    $importanceScore += 25
                    $reasons += "Release branch commit"
                }
                default {
                    if ($gitInfo.branch -match "^release") {
                        $importanceScore += 25
                        $reasons += "Release branch commit"
                    } elseif ($gitInfo.branch -match "^hotfix") {
                        $importanceScore += 30
                        $reasons += "Hotfix branch commit"
                    } elseif ($gitInfo.branch -match "^feature") {
                        $importanceScore += 10
                        $reasons += "Feature branch commit"
                    }
                }
            }
        }
        
        if ($gitInfo.PSObject.Properties.Name.Contains("commit_message")) {
            if ($gitInfo.commit_message -match "release|version|v\d+\.\d+|milestone") {
                $importanceScore += 20
                $reasons += "Release-related commit message"
            } elseif ($gitInfo.commit_message -match "fix|bug|issue|problem|error") {
                $importanceScore += 15
                $reasons += "Bug fix commit message"
            } elseif ($gitInfo.commit_message -match "important|critical|urgent") {
                $importanceScore += 25
                $reasons += "Critical commit message"
            }
        }
    }
    
    # 6. Historique de restauration
    if ($RestorePoint.restore_info.PSObject.Properties.Name.Contains("restore_history") -and 
        $RestorePoint.restore_info.restore_history.Count -gt 0) {
        $importanceScore += 15
        $reasons += "Previously restored point"
    }
    
    # Déterminer l'importance en fonction du score
    $importance = "Low"
    
    if ($importanceScore >= 70) {
        $importance = "Critical"
    } elseif ($importanceScore >= 40) {
        $importance = "High"
    } elseif ($importanceScore >= 20) {
        $importance = "Medium"
    }
    
    return @{
        importance = $importance
        score = $importanceScore
        reasons = $reasons
    }
}

# Fonction pour définir l'importance d'un point de restauration
function Set-RestorePointImportance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RestorePointId,
        
        [Parameter(Mandatory = $false)]
        [string]$RestorePointPath,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Critical", "High", "Medium", "Low", "Auto")]
        [string]$Importance = "Auto",
        
        [Parameter(Mandatory = $false)]
        [string]$Reason,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Charger le point de restauration
    $restorePoint = Get-RestorePoint -RestorePointId $RestorePointId -RestorePointPath $RestorePointPath
    
    if ($null -eq $restorePoint) {
        return $false
    }
    
    # Vérifier si le point de restauration a déjà une importance définie
    $hasImportance = $restorePoint.metadata.PSObject.Properties.Name.Contains("importance")
    
    if ($hasImportance -and -not $Force) {
        Write-Log "Restore point already has importance: $($restorePoint.metadata.importance.level). Use -Force to overwrite." -Level "Warning"
        return $false
    }
    
    # Déterminer l'importance
    $importanceInfo = $null
    
    if ($Importance -eq "Auto") {
        # Calculer l'importance automatiquement
        $autoImportance = Get-AutoImportance -RestorePoint $restorePoint
        
        $importanceInfo = @{
            level = $autoImportance.importance
            score = $autoImportance.score
            reasons = $autoImportance.reasons
            auto_calculated = $true
            last_updated = (Get-Date).ToString("o")
        }
    } else {
        # Utiliser l'importance spécifiée
        $importanceInfo = @{
            level = $Importance
            auto_calculated = $false
            last_updated = (Get-Date).ToString("o")
        }
        
        if (-not [string]::IsNullOrEmpty($Reason)) {
            $importanceInfo.reason = $Reason
        }
    }
    
    # Mettre à jour le point de restauration
    if (-not $restorePoint.metadata.PSObject.Properties.Name.Contains("importance")) {
        $restorePoint.metadata | Add-Member -MemberType NoteProperty -Name "importance" -Value $importanceInfo
    } else {
        $restorePoint.metadata.importance = $importanceInfo
    }
    
    # Sauvegarder le point de restauration
    $result = Save-RestorePoint -RestorePoint $restorePoint -RestorePointPath $RestorePointPath
    
    if ($result) {
        Write-Log "Importance set to $($importanceInfo.level) for restore point $($restorePoint.metadata.id)" -Level "Info"
        
        if ($importanceInfo.auto_calculated) {
            Write-Log "Auto-calculated importance with score $($importanceInfo.score)" -Level "Info"
            foreach ($reason in $importanceInfo.reasons) {
                Write-Log "  - $reason" -Level "Debug"
            }
        }
        
        return $importanceInfo
    } else {
        Write-Log "Failed to set importance for restore point $($restorePoint.metadata.id)" -Level "Error"
        return $false
    }
}

# Fonction pour recalculer l'importance de tous les points de restauration
function Update-AllRestorePointsImportance {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Obtenir tous les points de restauration
    $pointsPath = Get-RestorePointsPath
    $restorePointFiles = Get-ChildItem -Path $pointsPath -Filter "*.json"
    
    if ($restorePointFiles.Count -eq 0) {
        Write-Log "No restore points found" -Level "Warning"
        return $false
    }
    
    Write-Log "Recalculating importance for $($restorePointFiles.Count) restore points" -Level "Info"
    
    $updatedCount = 0
    $skippedCount = 0
    
    foreach ($file in $restorePointFiles) {
        $result = Set-RestorePointImportance -RestorePointPath $file.FullName -Importance "Auto" -Force:$Force
        
        if ($result -ne $false) {
            $updatedCount++
        } else {
            $skippedCount++
        }
    }
    
    Write-Log "Importance recalculation completed: $updatedCount updated, $skippedCount skipped" -Level "Info"
    
    return @{
        updated_count = $updatedCount
        skipped_count = $skippedCount
        total_count = $restorePointFiles.Count
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    if ($RecalculateAll) {
        Update-AllRestorePointsImportance -Force:$Force
    } elseif ($Recalculate) {
        Set-RestorePointImportance -RestorePointId $RestorePointId -RestorePointPath $RestorePointPath -Importance "Auto" -Force:$Force
    } else {
        Set-RestorePointImportance -RestorePointId $RestorePointId -RestorePointPath $RestorePointPath -Importance $Importance -Reason $Reason -Force:$Force
    }
}

