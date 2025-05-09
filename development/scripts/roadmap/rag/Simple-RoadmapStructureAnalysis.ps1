# Simple-RoadmapStructureAnalysis.ps1
# Script simplifié pour analyser la structure des fichiers de roadmap
# Version: 1.0
# Date: 2025-05-15

# Paramètres
$inputPath = "projet/roadmaps/analysis/test_output.json"
$outputPath = "projet/roadmaps/analysis/structure_analysis.json"
$testDirectory = "projet/roadmaps/analysis/test/files"

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

# Fonction pour analyser la structure d'un fichier markdown
function Get-MarkdownStructure {
    param (
        [string]$FilePath
    )
    
    $structure = @{
        Path = $FilePath
        Title = ""
        Format = @{
            IndentationType = "Unknown" # Spaces, Tabs, Mixed
            IndentationSize = 0
            NumberingStyle = "Unknown" # Numeric (1.2.3), Bullet (-, *, +), Mixed
            CheckboxStyle = "Unknown" # Standard ([]), Custom, None
            HeaderStyle = "Unknown" # ATX (#), Setext (===), Mixed
        }
        Content = @{
            SectionCount = 0
            TaskCount = 0
            CompletedTaskCount = 0
            MaxIndentationLevel = 0
            MaxTaskDepth = 0
        }
        Metadata = @{
            HasFrontMatter = $false
            HasInlineMetadata = $false
            MetadataFields = @()
        }
    }
    
    try {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Raw
        $lines = $content -split "`n"
        
        # Extraire le titre (première ligne commençant par #)
        if ($content -match "^#\s+(.+)$") {
            $structure.Title = $Matches[1].Trim()
        }
        
        # Vérifier la présence de front matter YAML
        if ($content -match "^---\s*\n([\s\S]*?)\n---") {
            $structure.Metadata.HasFrontMatter = $true
            $frontMatter = $Matches[1]
            $frontMatterLines = $frontMatter -split "`n"
            
            foreach ($line in $frontMatterLines) {
                if ($line -match "^([^:]+):\s*(.*)$") {
                    $structure.Metadata.MetadataFields += $Matches[1].Trim()
                }
            }
        }
        
        # Analyser le style d'indentation
        $indentSpaces = 0
        $indentTabs = 0
        $indentSizes = @{}
        
        # Analyser le style de numérotation
        $bulletCount = 0
        $numericCount = 0
        $checkboxCount = 0
        $standardCheckboxCount = 0
        
        # Compter les sections
        $sectionCount = 0
        $atxHeaderCount = 0
        $setextHeaderCount = 0
        
        # Analyser les tâches et l'indentation
        $maxIndentLevel = 0
        $maxTaskDepth = 0
        $taskCount = 0
        $completedTaskCount = 0
        
        # Vérifier les métadonnées inline
        $inlineMetadataCount = 0
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            
            # Analyser les en-têtes
            if ($line -match "^(#{1,6})\s+") {
                $sectionCount++
                $atxHeaderCount++
            }
            elseif ($i -lt $lines.Count - 1 -and $line -match "^[^\s]" -and $lines[$i + 1] -match "^[=]+$") {
                $sectionCount++
                $setextHeaderCount++
            }
            
            # Analyser l'indentation
            if ($line -match "^(\s+)") {
                $indent = $Matches[1]
                $indentLevel = $indent.Length
                
                if ($indentLevel -gt $maxIndentLevel) {
                    $maxIndentLevel = $indentLevel
                }
                
                if ($indent -match "^\t+$") {
                    $indentTabs++
                }
                elseif ($indent -match "^ +$") {
                    $indentSpaces++
                    $indentSize = $indent.Length
                    
                    if (-not $indentSizes.ContainsKey($indentSize)) {
                        $indentSizes[$indentSize] = 0
                    }
                    
                    $indentSizes[$indentSize]++
                }
            }
            
            # Analyser les listes
            if ($line -match "^\s*[-*+]\s") {
                $bulletCount++
            }
            elseif ($line -match "^\s*\d+\.\s") {
                $numericCount++
            }
            
            # Analyser les cases à cocher
            if ($line -match "\s*[-*+]\s*\[([ xX])\]") {
                $checkboxCount++
                $standardCheckboxCount++
                $taskCount++
                
                # Calculer la profondeur de la tâche
                if ($line -match "^(\s*)") {
                    $taskIndent = $Matches[1].Length
                    $taskDepth = [math]::Ceiling($taskIndent / 2)
                    
                    if ($taskDepth -gt $maxTaskDepth) {
                        $maxTaskDepth = $taskDepth
                    }
                }
                
                # Compter les tâches terminées
                if ($line -match "\s*[-*+]\s*\[[xX]\]") {
                    $completedTaskCount++
                }
            }
            
            # Vérifier les métadonnées inline
            if ($line -match "\s*[-*+]\s*\[[ xX]\]\s*.*\(([^)]+)\)") {
                $inlineMetadataCount++
                $structure.Metadata.HasInlineMetadata = $true
            }
        }
        
        # Déterminer le type d'indentation
        if ($indentSpaces > 0 -and $indentTabs > 0) {
            $structure.Format.IndentationType = "Mixed"
        }
        elseif ($indentSpaces > 0) {
            $structure.Format.IndentationType = "Spaces"
        }
        elseif ($indentTabs > 0) {
            $structure.Format.IndentationType = "Tabs"
        }
        
        # Déterminer la taille d'indentation la plus courante
        if ($indentSizes.Count -gt 0) {
            $structure.Format.IndentationSize = $indentSizes.GetEnumerator() | 
                Sort-Object -Property Value -Descending | 
                Select-Object -First 1 -ExpandProperty Key
        }
        
        # Déterminer le style de numérotation
        if ($bulletCount > 0 -and $numericCount > 0) {
            $structure.Format.NumberingStyle = "Mixed"
        }
        elseif ($bulletCount > 0) {
            $structure.Format.NumberingStyle = "Bullet"
        }
        elseif ($numericCount > 0) {
            $structure.Format.NumberingStyle = "Numeric"
        }
        
        # Déterminer le style de case à cocher
        if ($checkboxCount > 0) {
            if ($standardCheckboxCount -eq $checkboxCount) {
                $structure.Format.CheckboxStyle = "Standard"
            }
            else {
                $structure.Format.CheckboxStyle = "Mixed"
            }
        }
        else {
            $structure.Format.CheckboxStyle = "None"
        }
        
        # Déterminer le style d'en-tête
        if ($atxHeaderCount > 0 -and $setextHeaderCount > 0) {
            $structure.Format.HeaderStyle = "Mixed"
        }
        elseif ($atxHeaderCount > 0) {
            $structure.Format.HeaderStyle = "ATX"
        }
        elseif ($setextHeaderCount > 0) {
            $structure.Format.HeaderStyle = "Setext"
        }
        
        # Mettre à jour les statistiques de contenu
        $structure.Content.SectionCount = $sectionCount
        $structure.Content.TaskCount = $taskCount
        $structure.Content.CompletedTaskCount = $completedTaskCount
        $structure.Content.MaxIndentationLevel = $maxIndentLevel
        $structure.Content.MaxTaskDepth = $maxTaskDepth
    }
    catch {
        Write-Log "Erreur lors de l'analyse de la structure de $FilePath : $_" -Level "Error"
    }
    
    return $structure
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
        },
        @{
            Name = "roadmap_duplicate.md"
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
            Name = "plan-implementation.md"
            Content = @"
# Plan d'implémentation

## Fonctionnalité A
- [ ] **1.1** Conception
  - [ ] **1.1.1** Analyse des besoins
  - [ ] **1.1.2** Conception de l'architecture
- [ ] **1.2** Développement
  - [ ] **1.2.1** Implémentation du backend
  - [ ] **1.2.2** Implémentation du frontend

## Fonctionnalité B
- [ ] **2.1** Conception
- [ ] **2.2** Développement
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

# Exécution principale
try {
    Write-Log "Démarrage de l'analyse de la structure des fichiers de roadmap..." -Level "Info"
    
    # Créer le dossier de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $outputPath -Parent
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Créer des fichiers de test
    $testFiles = New-TestRoadmapFiles -TestDirectory $testDirectory
    
    # Analyser la structure des fichiers
    $results = @()
    
    foreach ($file in $testFiles) {
        Write-Log "Analyse de la structure de $file..." -Level "Info"
        $structure = Get-MarkdownStructure -FilePath $file
        $results += $structure
    }
    
    Write-Log "Analyse terminée. $($results.Count) fichiers analysés." -Level "Success"
    
    # Exporter les résultats
    $results | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8
    Write-Log "Résultats exportés dans $outputPath" -Level "Success"
    
    # Afficher un résumé des résultats
    Write-Log "Résumé des résultats :" -Level "Info"
    foreach ($result in $results) {
        Write-Log "  - $($result.Path) : $($result.Content.TaskCount) tâches, $($result.Content.CompletedTaskCount) terminées" -Level "Info"
    }
}
catch {
    Write-Log "Erreur lors de l'analyse des fichiers : $_" -Level "Error"
}
