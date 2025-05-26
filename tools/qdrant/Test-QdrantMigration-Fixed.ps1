# Test-QdrantMigration-Fixed.ps1
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

# Fonction pour ecrire des logs
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

# Test 1: Verifier la connectivite QDrant
function Test-QdrantConnectivity {
    Write-Log "=== Test de connectivite QDrant ===" -Level Info
    
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/" -Method Get -TimeoutSec 5
        Write-Log "QDrant version: $($response.version)" -Level Success
        Write-Log "QDrant title: $($response.title)" -Level Success
        return $true
    } catch {
        Write-Log "Erreur de connexion a QDrant: $_" -Level Error
        return $false
    }
}

# Test 2: Lister les collections QDrant
function Get-QdrantCollections {
    Write-Log "=== Test des collections QDrant ===" -Level Info
    
    try {
        $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get -TimeoutSec 5
        
        if ($response.result.collections) {
            Write-Log "Collections trouvees: $($response.result.collections.Count)" -Level Success
            
            foreach ($collection in $response.result.collections) {
                Write-Log "  - $($collection.name)" -Level Info
                if ($VerboseOutput) {
                    Write-Log "    Points: $($collection.points_count)" -Level Info
                }
            }
        } else {
            Write-Log "Aucune collection trouvee" -Level Warning
        }
        
        return $response.result.collections
    } catch {
        Write-Log "Erreur lors de la recuperation des collections: $_" -Level Error
        return @()
    }
}

# Test 3: Trouver les plans de developpement
function Find-DevelopmentPlans {
    Write-Log "=== Recherche des plans de developpement ===" -Level Info
    
    $planFiles = @()
    
    # Patterns de recherche pour les plans de dev
    $searchPatterns = @(
        "*plan*.md",
        "*roadmap*.md",
        "*mcp*.md",
        "*development*.md",
        "*specs*.md"
    )
    
    foreach ($pattern in $searchPatterns) {
        $files = Get-ChildItem -Path $ProjectRoot -Recurse -Filter $pattern -ErrorAction SilentlyContinue
        $planFiles += $files
    }
    
    # Recherche specifique pour les versions MCP Manager
    $mcpFiles = Get-ChildItem -Path $ProjectRoot -Recurse -Filter "*.md" | Where-Object {
        $_.Name -like "*mcp*" -and ($_.Name -like "*v16*" -or $_.Name -like "*v33*")
    }
    
    $planFiles += $mcpFiles
    
    # Supprimer les doublons
    $planFiles = $planFiles | Sort-Object FullName | Get-Unique -AsString
    
    Write-Log "Plans trouves: $($planFiles.Count)" -Level Success
    
    foreach ($file in $planFiles) {
        $relativePath = $file.FullName.Replace($ProjectRoot, "").TrimStart('\')
        Write-Log "  - $relativePath" -Level Info
        
        if ($VerboseOutput) {
            $size = [math]::Round($file.Length / 1KB, 2)
            $modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            Write-Log "    Taille: ${size}KB, Modifie: $modified" -Level Info
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
    
    foreach ($group in $groups.GetEnumerator()) {
        if ($group.Value.Count -gt 1) {
            Write-Log "Doublons potentiels pour '$($group.Key)':" -Level Warning
            $sortedFiles = $group.Value | Sort-Object LastWriteTime -Descending
            
            foreach ($file in $sortedFiles) {
                $relativePath = $file.FullName.Replace($ProjectRoot, "").TrimStart('\')
                $size = [math]::Round($file.Length / 1KB, 2)
                $modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
                
                if ($file -eq $sortedFiles[0]) {
                    Write-Log "  ✓ $relativePath (${size}KB, $modified) [LE PLUS RECENT]" -Level Success
                } else {
                    Write-Log "  ⚠ $relativePath (${size}KB, $modified)" -Level Warning
                }
            }
            
            $duplicates += @{
                GroupName = $group.Key
                Files = $group.Value
                RecommendedFile = $sortedFiles[0]
                OldFiles = $sortedFiles[1..($sortedFiles.Count-1)]
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
        Write-Log "Aucun doublon detecte - Projet bien organise!" -Level Success
        return
    }
    
    $totalOldFiles = 0
    $totalSizeToSave = 0
    
    foreach ($duplicate in $Duplicates) {
        $oldFiles = $duplicate.OldFiles
        $totalOldFiles += $oldFiles.Count
        
        foreach ($oldFile in $oldFiles) {
            $totalSizeToSave += $oldFile.Length
        }
    }
    
    $sizeMB = [math]::Round($totalSizeToSave / 1MB, 2)
    
    Write-Log "Fichiers obsoletes detectes: $totalOldFiles" -Level Warning
    Write-Log "Espace disque a liberer: ${sizeMB}MB" -Level Warning
    
    Write-Log "Actions recommandees:" -Level Info
    Write-Log "1. Conserver les fichiers les plus recents marques [LE PLUS RECENT]" -Level Info
    Write-Log "2. Archiver les anciennes versions dans un dossier 'archive/'" -Level Info
    Write-Log "3. Ou supprimer directement si le contenu est vraiment obsolete" -Level Info
}

# Fonction principale
function Main {
    Write-Log "=== Test de migration QDrant Standalone ===" -Level Info
    Write-Log "Projet: EMAIL_SENDER_1" -Level Info
    Write-Log "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level Info
    
    # Test 1: Connectivite
    if (-not (Test-QdrantConnectivity)) {
        Write-Log "Echec du test de connectivite. Arret des tests." -Level Error
        return $false
    }
    
    # Test 2: Collections
    $collections = Get-QdrantCollections
    
    # Test 3: Plans de developpement
    $plans = Find-DevelopmentPlans
    
    # Test 4: Doublons
    $duplicates = Find-PotentialDuplicates -Files $plans
    
    # Test 5: Recommandations
    Get-CleanupRecommendations -Duplicates $duplicates
    
    # Resume
    Write-Log "=== Resume des tests ===" -Level Success
    Write-Log "✓ QDrant standalone operationnel" -Level Success
    Write-Log "✓ Collections QDrant: $($collections.Count)" -Level Success
    Write-Log "✓ Plans de developpement trouves: $($plans.Count)" -Level Success
    Write-Log "⚠ Groupes de doublons: $($duplicates.Count)" -Level Warning
    
    if ($duplicates.Count -gt 0) {
        Write-Log "" -Level Info
        Write-Log "Actions recommandees:" -Level Info
        Write-Log "1. Examiner les doublons identifies ci-dessus" -Level Info
        Write-Log "2. Conserver les fichiers les plus recents" -Level Info
        Write-Log "3. Archiver ou supprimer les anciennes versions" -Level Info
        Write-Log "4. Utiliser QDrant pour vectoriser les plans consolides" -Level Info
    }
    
    return $true
}

# Executer les tests
if ($MyInvocation.InvocationName -ne '.') {
    Main
}
