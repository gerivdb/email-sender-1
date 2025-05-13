# Script pour analyser le dépôt mem0ai/mem0 avec MCP git-ingest
# Ce script utilise le MCP git-ingest déjà configuré dans Augment

# URL du dépôt à analyser
$repoUrl = "https://github.com/mem0ai/mem0"

# Créer le répertoire de sortie
$outputDir = "output/mem0-analysis"
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

Write-Host "Analyse du dépôt $repoUrl avec MCP git-ingest..." -ForegroundColor Cyan

# Étape 1: Obtenir la structure du dépôt
Write-Host "Étape 1: Récupération de la structure du dépôt..." -ForegroundColor Green

$directoryStructureCommand = @{
    tool = "github_directory_structure"
    params = @{
        repo_url = $repoUrl
    }
} | ConvertTo-Json -Compress

# Exécuter la commande avec npx
$structureResult = npx -y @adhikasp/mcp-git-ingest 2>&1
if ($structureResult -match "command not found") {
    # Essayer avec l'installation globale
    $structureResult = npx -y --package=git+https://github.com/adhikasp/mcp-git-ingest mcp-git-ingest 2>&1
}

# Sauvegarder la structure dans un fichier
$structureResult | Out-File -FilePath "$outputDir/structure.txt" -Encoding utf8
Write-Host "Structure du dépôt sauvegardée dans $outputDir/structure.txt" -ForegroundColor Green

# Étape 2: Lire les fichiers importants
Write-Host "Étape 2: Lecture des fichiers importants..." -ForegroundColor Green

# Liste des fichiers importants à lire
$importantFiles = @(
    "README.md",
    "pyproject.toml",
    "setup.py",
    "mem0/__init__.py",
    "mem0/main.py",
    "mem0/mcp/__init__.py",
    "mem0/mcp/server.py",
    "mem0/mcp/tools.py",
    "mem0/config.py",
    "docs/README.md"
)

# Utiliser le MCP GitHub directement
Write-Host "Utilisation du MCP GitHub pour lire les fichiers..." -ForegroundColor Yellow

# Créer un répertoire pour les fichiers
$filesDir = "$outputDir/files"
New-Item -ItemType Directory -Path $filesDir -Force | Out-Null

# Utiliser git clone pour obtenir le dépôt
$repoDir = "$outputDir/repo"
if (Test-Path $repoDir) {
    Remove-Item -Path $repoDir -Recurse -Force
}

Write-Host "Clonage du dépôt $repoUrl..." -ForegroundColor Yellow
git clone $repoUrl $repoDir

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors du clonage du dépôt. Vérifiez l'URL et votre connexion Internet." -ForegroundColor Red
    exit 1
}

# Lire les fichiers importants
$filesContent = @()
foreach ($file in $importantFiles) {
    $filePath = Join-Path -Path $repoDir -ChildPath $file
    if (Test-Path $filePath) {
        $content = Get-Content -Path $filePath -Raw -Encoding utf8
        $filesContent += [PSCustomObject]@{
            path = $file
            content = $content
        }
        
        # Sauvegarder le fichier individuellement
        $safePath = $file.Replace("/", "_").Replace("\", "_")
        $content | Out-File -FilePath "$filesDir/$safePath" -Encoding utf8
        Write-Host "Fichier $file sauvegardé dans $filesDir/$safePath" -ForegroundColor Green
    } else {
        Write-Host "Fichier $file non trouvé dans le dépôt" -ForegroundColor Yellow
    }
}

# Sauvegarder le contenu des fichiers dans un fichier JSON
$filesContent | ConvertTo-Json -Depth 10 | Out-File -FilePath "$outputDir/files_content.json" -Encoding utf8
Write-Host "Contenu des fichiers sauvegardé dans $outputDir/files_content.json" -ForegroundColor Green

# Étape 3: Générer un rapport d'analyse
Write-Host "Étape 3: Génération du rapport d'analyse..." -ForegroundColor Green

$report = @"
# Analyse du dépôt mem0ai/mem0

## Structure du dépôt

```
$(Get-Content -Path "$outputDir/structure.txt" -Raw)
```

## Fichiers importants

"@

foreach ($file in $filesContent) {
    $report += @"

### $($file.path)

```
$($file.content.Substring(0, [Math]::Min(1000, $file.content.Length)))
$(if ($file.content.Length -gt 1000) { "...\n[contenu tronqué]" })
```

"@
}

# Analyser les fonctionnalités MCP
$report += @"

## Analyse de compatibilité avec Augment

### Fonctionnalités MCP détectées

"@

$mcpFeatures = @{}

# Détecter les fonctionnalités MCP dans les fichiers
foreach ($file in $filesContent) {
    # Détecter les outils MCP
    if ($file.path -like "*mcp/tools.py*" -or $file.path -like "*tools*") {
        if (-not $mcpFeatures.ContainsKey("MCP Tools")) {
            $mcpFeatures["MCP Tools"] = @{
                description = "Outils MCP pour interagir avec le modèle"
                compatible = $true
                files = @($file.path)
            }
        } elseif ($mcpFeatures["MCP Tools"].files -notcontains $file.path) {
            $mcpFeatures["MCP Tools"].files += $file.path
        }
    }
    
    # Détecter le serveur MCP
    if ($file.path -like "*mcp/server.py*" -or $file.path -like "*server*") {
        if (-not $mcpFeatures.ContainsKey("MCP Server")) {
            $mcpFeatures["MCP Server"] = @{
                description = "Serveur MCP pour exposer les outils"
                compatible = $true
                files = @($file.path)
            }
        } elseif ($mcpFeatures["MCP Server"].files -notcontains $file.path) {
            $mcpFeatures["MCP Server"].files += $file.path
        }
    }
    
    # Détecter l'API MCP
    if ($file.path -like "*api*" -and $file.content -like "*mcp*") {
        if (-not $mcpFeatures.ContainsKey("MCP API")) {
            $mcpFeatures["MCP API"] = @{
                description = "API pour interagir avec le serveur MCP"
                compatible = $true
                files = @($file.path)
            }
        } elseif ($mcpFeatures["MCP API"].files -notcontains $file.path) {
            $mcpFeatures["MCP API"].files += $file.path
        }
    }
    
    # Détecter les fonctionnalités de mémoire
    if ($file.path -like "*memory*" -or $file.content -like "*memory*") {
        if (-not $mcpFeatures.ContainsKey("Memory Management")) {
            $mcpFeatures["Memory Management"] = @{
                description = "Gestion de la mémoire pour les modèles"
                compatible = $true
                files = @($file.path)
            }
        } elseif ($mcpFeatures["Memory Management"].files -notcontains $file.path) {
            $mcpFeatures["Memory Management"].files += $file.path
        }
    }
}

foreach ($feature in $mcpFeatures.Keys) {
    $details = $mcpFeatures[$feature]
    $report += @"

#### $feature

$($details.description)

$(if ($details.compatible) { "✅ **Compatible avec Augment**" } else { "❌ **Non compatible avec Augment**" })

*Détecté dans: $($details.files -join ", ")*

"@
}

# Conclusion
$report += @"

## Conclusion

"@

$compatibleFeatures = ($mcpFeatures.Values | Where-Object { $_.compatible }).Count
$totalFeatures = $mcpFeatures.Count

if ($totalFeatures -gt 0) {
    $compatibilityScore = [Math]::Round(($compatibleFeatures / $totalFeatures) * 100)
    $report += @"
Le projet mem0ai/mem0 est **$compatibilityScore%** compatible avec Augment.

"@
    
    if ($compatibilityScore -ge 75) {
        $report += "**Recommandation**: L'intégration de OpenMemory MCP avec Augment est fortement recommandée."
    } elseif ($compatibilityScore -ge 50) {
        $report += "**Recommandation**: L'intégration de OpenMemory MCP avec Augment est possible mais nécessitera quelques adaptations."
    } else {
        $report += "**Recommandation**: L'intégration de OpenMemory MCP avec Augment nécessitera des modifications importantes."
    }
} else {
    $report += "Impossible de déterminer la compatibilité avec Augment."
}

# Sauvegarder le rapport
$report | Out-File -FilePath "$outputDir/report.md" -Encoding utf8
Write-Host "Rapport d'analyse sauvegardé dans $outputDir/report.md" -ForegroundColor Green

# Ouvrir le rapport
Write-Host "Ouverture du rapport..." -ForegroundColor Cyan
Invoke-Item "$outputDir/report.md"

Write-Host "Analyse terminée." -ForegroundColor Cyan
