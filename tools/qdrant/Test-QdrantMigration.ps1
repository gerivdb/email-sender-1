# Test-QdrantMigration.ps1
# Script pour tester la migration vers QDrant standalone et identifier les doublons
# Date: 2025-05-25

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [switch]$VerboseOutput
)

# Configuration
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$QdrantUrl = "http://localhost:6333"

# Fonction pour écrire des logs
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Info' { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
}

# Test 1: Vérifier la connectivité QDrant
function Test-QdrantConnectivity {
    Write-Log "=== Test de connectivité QDrant ===" -Level Info
    
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/" -Method Get -TimeoutSec 5
        Write-Log "QDrant version: $($response.version)" -Level Success
        Write-Log "QDrant title: $($response.title)" -Level Success
        return $true
    } catch {
        Write-Log "Erreur de connexion à QDrant: $_" -Level Error
        return $false
    }
}

# Test 2: Lister les collections existantes
function Get-QdrantCollections {
    Write-Log "=== Collections QDrant existantes ===" -Level Info
    
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get
        
        if ($response.result.collections.Count -gt 0) {
            foreach ($collection in $response.result.collections) {
                Write-Log "Collection: $($collection.name)" -Level Info
                if ($VerboseOutput) {
                    Write-Log "  - Points: $($collection.points_count)" -Level Info
                    Write-Log "  - Status: $($collection.status)" -Level Info
                }
            }
        } else {
            Write-Log "Aucune collection trouvée" -Level Warning
        }
        
        return $response.result.collections
    } catch {
        Write-Log "Erreur lors de la récupération des collections: $_" -Level Error
        return @()
    }
}

# Test 3: Rechercher les fichiers de plans de développement
function Find-DevelopmentPlans {
    Write-Log "=== Recherche des plans de développement ===" -Level Info
    
    $planFiles = @()
    $searchPaths = @(
        (Join-Path $ProjectRoot "plan-dev"),
        (Join-Path $ProjectRoot "development"),
        (Join-Path $ProjectRoot "projet"),
        $ProjectRoot
    )
    
    foreach ($path in $searchPaths) {
        if (Test-Path $path) {
            $files = Get-ChildItem -Path $path -Recurse -Filter "*.md" | Where-Object {
                $_.Name -like "*plan*dev*" -or 
                $_.Name -like "*mcp*manager*" -or
                $_.Name -like "*roadmap*" -or
                $_.BaseName -match "v\d+"
            }
            
            $planFiles += $files
        }
    }
    
    # Recherche spécifique pour les versions MCP Manager
    $mcpFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.md" | Where-Object {
        $_.Name -like "*mcp*" -and ($_.Name -like "*v16*" -or $_.Name -like "*v33*")
    }
    
    $planFiles += $mcpFiles
    
    # Supprimer les doublons
    $planFiles = $planFiles | Sort-Object FullName | Get-Unique -AsString
    
    Write-Log "Plans trouvés: $($planFiles.Count)" -Level Success
    
    foreach ($file in $planFiles) {
        $relativePath = $file.FullName.Replace($ProjectRoot, "").TrimStart('\')
        Write-Log "  - $relativePath" -Level Info
        
        if ($VerboseOutput) {
            $size = [math]::Round($file.Length / 1KB, 2)
            $modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            Write-Log "    Taille: ${size}KB, Modifié: $modified" -Level Info
        }
    }
    
    return $planFiles
}

# Test 4: Identifier les doublons potentiels
function Find-PotentialDuplicates {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Files
    )
    
    Write-Log "=== Analyse des doublons potentiels ===" -Level Info
    
    $duplicates = @()
    $groups = @{}
    
    foreach ($file in $Files) {
        $baseName = $file.BaseName -replace "[-_]?v\d+[a-z]?$", ""
        $baseName = $baseName -replace "[-_]?(final|latest|new|old)$", ""
        
        if (-not $groups.ContainsKey($baseName)) {
            $groups[$baseName] = @()
        }
        $groups[$baseName] += $file
    }
    
    foreach ($groupName in $groups.Keys) {
        if ($groups[$groupName].Count -gt 1) {
            Write-Log "Groupe de doublons potentiels: $groupName" -Level Warning
            
            $groupFiles = $groups[$groupName] | Sort-Object LastWriteTime -Descending
            foreach ($file in $groupFiles) {
                $age = (Get-Date) - $file.LastWriteTime
                $status = if ($file -eq $groupFiles[0]) { "[RECENT]" } else { "[ANCIEN]" }
                
                Write-Log "  $status $($file.Name) (modifié il y a $([math]::Round($age.TotalDays, 1)) jours)" -Level Info
            }
            
            $duplicates += [PSCustomObject]@{
                Group = $groupName
                Files = $groupFiles
                RecentFile = $groupFiles[0]
                OldFiles = $groupFiles[1..($groupFiles.Count-1)]
            }
        }
    }
    
    return $duplicates
}

# Test 5: Recommandations de nettoyage
function Get-CleanupRecommendations {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Duplicates
    )
    
    Write-Log "=== Recommandations de nettoyage ===" -Level Info
    
    if ($Duplicates.Count -eq 0) {
        Write-Log "Aucun doublon détecté" -Level Success
        return
    }
    
    foreach ($duplicate in $Duplicates) {
        Write-Log "Groupe: $($duplicate.Group)" -Level Warning
        Write-Log "  Conserver: $($duplicate.RecentFile.Name)" -Level Success
        
        foreach ($oldFile in $duplicate.OldFiles) {
            Write-Log "  Supprimer ou archiver: $($oldFile.Name)" -Level Warning
        }
    }
}

# Fonction principale
function Main {
    Write-Log "=== Test de migration QDrant Standalone ===" -Level Info
    Write-Log "Projet: EMAIL_SENDER_1" -Level Info
    Write-Log "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level Info
    
    # Test 1: Connectivité
    if (-not (Test-QdrantConnectivity)) {
        Write-Log "Échec du test de connectivité. Arrêt des tests." -Level Error
        return $false
    }
    
    # Test 2: Collections
    $collections = Get-QdrantCollections
    
    # Test 3: Plans de développement
    $plans = Find-DevelopmentPlans
    
    # Test 4: Doublons
    $duplicates = Find-PotentialDuplicates -Files $plans
    
    # Test 5: Recommandations
    Get-CleanupRecommendations -Duplicates $duplicates
    
    # Résumé
    Write-Log "=== Résumé des tests ===" -Level Success
    Write-Log "✓ QDrant standalone opérationnel" -Level Success
    Write-Log "✓ Collections QDrant: $($collections.Count)" -Level Success
    Write-Log "✓ Plans de développement trouvés: $($plans.Count)" -Level Success
    Write-Log "⚠ Groupes de doublons: $($duplicates.Count)" -Level Warning
    
    if ($duplicates.Count -gt 0) {
        Write-Log "" -Level Info
        Write-Log "Actions recommandées:" -Level Info
        Write-Log "1. Examiner les doublons identifiés ci-dessus" -Level Info
        Write-Log "2. Conserver les fichiers les plus récents" -Level Info
        Write-Log "3. Archiver ou supprimer les anciennes versions" -Level Info
        Write-Log "4. Utiliser QDrant pour vectoriser les plans consolidés" -Level Info
    }
    
    return $true
}

# Exécuter les tests
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
