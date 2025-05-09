# Very-Simple-Analysis.ps1
# Script très simplifié pour analyser les fichiers de roadmap
# Version: 1.0
# Date: 2025-05-15

# Paramètres
$testDirectory = "projet/roadmaps/analysis/test/files"
$outputPath = "projet/roadmaps/analysis/simple_analysis.json"

# Fonction de journalisation simplifiée
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "Info"
    )
    
    $color = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
    }
    
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message" -ForegroundColor $color
}

# Fonction pour créer des fichiers de test
function New-TestRoadmapFiles {
    param (
        [string]$TestDirectory
    )
    
    # Créer le dossier de test s'il n'existe pas
    if (-not (Test-Path -Path $TestDirectory)) {
        New-Item -Path $TestDirectory -ItemType Directory -Force | Out-Null
    }
    
    # Créer des fichiers de test
    $testFiles = @(
        @{
            Name = "roadmap-v1.md"
            Content = @"
# Roadmap Test v1

## Section 1
- [ ] Tâche 1
- [ ] Tâche 2
  - [ ] Sous-tâche 2.1
  - [ ] Sous-tâche 2.2

## Section 2
- [ ] Tâche 3
- [x] Tâche 4
"@
        },
        @{
            Name = "roadmap-v2.md"
            Content = @"
# Roadmap Test v2

## Section 1
- [ ] Tâche 1
- [ ] Tâche 2
  - [ ] Sous-tâche 2.1
  - [x] Sous-tâche 2.2

## Section 2
- [ ] Tâche 3
- [x] Tâche 4
- [ ] Tâche 5
"@
        }
    )
    
    $createdFiles = @()
    
    foreach ($file in $testFiles) {
        $filePath = Join-Path -Path $TestDirectory -ChildPath $file.Name
        Set-Content -Path $filePath -Value $file.Content -Encoding UTF8
        Write-Log "Fichier de test créé : $filePath" -Level "Info"
        $createdFiles += $filePath
    }
    
    return $createdFiles
}

# Fonction pour analyser un fichier markdown de façon très simple
function Get-SimpleAnalysis {
    param (
        [string]$FilePath
    )
    
    $analysis = @{
        Path = $FilePath
        Title = ""
        SectionCount = 0
        TaskCount = 0
        CompletedTaskCount = 0
    }
    
    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        $lines = $content -split "`n"
        
        # Extraire le titre (première ligne commençant par #)
        foreach ($line in $lines) {
            if ($line -match "^#\s+(.+)$") {
                $analysis.Title = $Matches[1].Trim()
                break
            }
        }
        
        # Compter les sections (lignes commençant par ##)
        $analysis.SectionCount = ($lines | Where-Object { $_ -match "^##\s+" }).Count
        
        # Compter les tâches (lignes avec cases à cocher)
        $analysis.TaskCount = ($lines | Where-Object { $_ -match "\s*[-*+]\s*\[([ xX])\]" }).Count
        
        # Compter les tâches terminées (cases cochées)
        $analysis.CompletedTaskCount = ($lines | Where-Object { $_ -match "\s*[-*+]\s*\[[xX]\]" }).Count
    }
    catch {
        Write-Log "Erreur lors de l'analyse de $FilePath : $_" -Level "Error"
    }
    
    return $analysis
}

# Exécution principale
try {
    Write-Log "Démarrage de l'analyse simplifiée des fichiers de roadmap..." -Level "Info"
    
    # Créer le dossier de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $outputPath -Parent
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Créer des fichiers de test
    $testFiles = New-TestRoadmapFiles -TestDirectory $testDirectory
    
    # Analyser les fichiers
    $results = @()
    
    foreach ($file in $testFiles) {
        Write-Log "Analyse de $file..." -Level "Info"
        $analysis = Get-SimpleAnalysis -FilePath $file
        $results += $analysis
    }
    
    Write-Log "Analyse terminée. $($results.Count) fichiers analysés." -Level "Success"
    
    # Exporter les résultats
    $results | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8
    Write-Log "Résultats exportés dans $outputPath" -Level "Success"
    
    # Afficher un résumé des résultats
    Write-Log "Résumé des résultats :" -Level "Info"
    foreach ($result in $results) {
        Write-Log "  - $($result.Path) : $($result.TaskCount) tâches, $($result.CompletedTaskCount) terminées" -Level "Info"
    }
}
catch {
    Write-Log "Erreur lors de l'analyse des fichiers : $_" -Level "Error"
}
