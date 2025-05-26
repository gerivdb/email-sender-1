# Test-QdrantMigration-Simple.ps1
# Script pour tester la migration vers QDrant standalone et identifier les doublons

param (
    [switch]$VerboseOutput
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$QdrantUrl = "http://localhost:6333"

function Write-TestLog {
    param (
        [string]$Message,
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

# Test 1: Connectivite QDrant
Write-TestLog "=== Test de connectivite QDrant ===" -Level Info

try {
    $response = Invoke-RestMethod -Uri "$QdrantUrl/" -Method Get -TimeoutSec 5
    Write-TestLog "QDrant version: $($response.version)" -Level Success
    Write-TestLog "QDrant title: $($response.title)" -Level Success
    $qdrantOk = $true
} catch {
    Write-TestLog "Erreur de connexion a QDrant: $_" -Level Error
    $qdrantOk = $false
}

if (-not $qdrantOk) {
    Write-TestLog "QDrant n'est pas accessible. Verifiez qu'il est demarre." -Level Error
    exit 1
}

# Test 2: Collections QDrant
Write-TestLog "=== Test des collections QDrant ===" -Level Info

try {
    $response = Invoke-RestMethod -Uri "$QdrantUrl/collections" -Method Get -TimeoutSec 5
    
    if ($response.result.collections) {
        Write-TestLog "Collections trouvees: $($response.result.collections.Count)" -Level Success
        
        foreach ($collection in $response.result.collections) {
            Write-TestLog "  - $($collection.name)" -Level Info
            if ($VerboseOutput) {
                Write-TestLog "    Points: $($collection.points_count)" -Level Info
            }
        }
        $collections = $response.result.collections
    } else {
        Write-TestLog "Aucune collection trouvee" -Level Warning
        $collections = @()
    }
} catch {
    Write-TestLog "Erreur lors de la recuperation des collections: $_" -Level Error
    $collections = @()
}

# Test 3: Recherche des plans de developpement
Write-TestLog "=== Recherche des plans de developpement ===" -Level Info

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

Write-TestLog "Plans trouves: $($planFiles.Count)" -Level Success

foreach ($file in $planFiles) {
    $relativePath = $file.FullName.Replace($ProjectRoot, "").TrimStart('\')
    Write-TestLog "  - $relativePath" -Level Info
    
    if ($VerboseOutput) {
        $size = [math]::Round($file.Length / 1KB, 2)
        $modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
        Write-TestLog "    Taille: ${size}KB, Modifie: $modified" -Level Info
    }
}

# Test 4: Identifier les doublons potentiels
Write-TestLog "=== Analyse des doublons potentiels ===" -Level Info

$duplicates = @()
$groups = @{}

foreach ($file in $planFiles) {
    $baseName = $file.BaseName -replace "[-_]?v\d+[a-z]?$", ""
    $baseName = $baseName -replace "[-_]?(final|latest|new|old)$", ""
    
    if (-not $groups.ContainsKey($baseName)) {
        $groups[$baseName] = @()
    }
    $groups[$baseName] += $file
}

$duplicateCount = 0
foreach ($group in $groups.GetEnumerator()) {
    if ($group.Value.Count -gt 1) {
        $duplicateCount++
        Write-TestLog "Doublons potentiels pour '$($group.Key)':" -Level Warning
        $sortedFiles = $group.Value | Sort-Object LastWriteTime -Descending
        
        foreach ($file in $sortedFiles) {
            $relativePath = $file.FullName.Replace($ProjectRoot, "").TrimStart('\')
            $size = [math]::Round($file.Length / 1KB, 2)
            $modified = $file.LastWriteTime.ToString("yyyy-MM-dd HH:mm")
            
            if ($file -eq $sortedFiles[0]) {
                Write-TestLog "  + $relativePath (${size}KB, $modified) [LE PLUS RECENT]" -Level Success
            } else {
                Write-TestLog "  - $relativePath (${size}KB, $modified)" -Level Warning
            }
        }
        Write-TestLog "" -Level Info
    }
}

# Resume
Write-TestLog "=== Resume des tests ===" -Level Success
Write-TestLog "QDrant standalone operationnel: OUI" -Level Success
Write-TestLog "Collections QDrant: $($collections.Count)" -Level Success
Write-TestLog "Plans de developpement trouves: $($planFiles.Count)" -Level Success
Write-TestLog "Groupes de doublons: $duplicateCount" -Level $(if ($duplicateCount -gt 0) { "Warning" } else { "Success" })

if ($duplicateCount -gt 0) {
    Write-TestLog "" -Level Info
    Write-TestLog "Actions recommandees:" -Level Info
    Write-TestLog "1. Examiner les doublons identifies ci-dessus" -Level Info
    Write-TestLog "2. Conserver les fichiers marques [LE PLUS RECENT]" -Level Info
    Write-TestLog "3. Archiver ou supprimer les anciennes versions" -Level Info
    Write-TestLog "4. Utiliser QDrant pour vectoriser les plans consolides" -Level Info
} else {
    Write-TestLog "Projet bien organise - aucun doublon detecte!" -Level Success
}

Write-TestLog "Test termine avec succes" -Level Success
