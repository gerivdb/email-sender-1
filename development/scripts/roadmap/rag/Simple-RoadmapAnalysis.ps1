# Simple-RoadmapAnalysis.ps1
# Script principal simplifié pour analyser les roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [ValidateSet(
        "Inventory", "Analyze", "FindDuplicates",
        "All"
    )]
    [string]$Action = "All",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputDirectory = "projet/roadmaps/analysis",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

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

# Fonction pour créer le dossier de sortie
function Initialize-OutputDirectory {
    param (
        [string]$Directory,
        [switch]$Force
    )
    
    if (-not (Test-Path -Path $Directory)) {
        Write-Log "Création du dossier de sortie $Directory..." -Level "Info"
        New-Item -Path $Directory -ItemType Directory -Force | Out-Null
    }
    elseif ($Force) {
        Write-Log "Le dossier de sortie $Directory existe déjà. Les fichiers existants seront écrasés." -Level "Warning"
    }
    else {
        Write-Log "Le dossier de sortie $Directory existe déjà." -Level "Info"
    }
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

# Fonction pour inventorier les fichiers de roadmap
function Invoke-RoadmapInventory {
    param (
        [string]$OutputDirectory,
        [switch]$Force
    )
    
    Write-Log "Démarrage de l'inventaire des fichiers de roadmap..." -Level "Info"
    
    # Créer un dossier pour les fichiers de test
    $testDirectory = Join-Path -Path $OutputDirectory -ChildPath "test/files"
    
    # Créer des fichiers de test
    $testFiles = New-TestRoadmapFiles -TestDirectory $testDirectory
    
    # Inventorier les fichiers
    $inventory = @()
    
    foreach ($file in $testFiles) {
        $fileInfo = Get-Item -Path $file
        
        $fileData = [PSCustomObject]@{
            Path = $file
            Name = $fileInfo.Name
            Directory = $fileInfo.DirectoryName
            Size = $fileInfo.Length
            CreationTime = $fileInfo.CreationTime
            LastWriteTime = $fileInfo.LastWriteTime
            Content = Get-Content -Path $file -Raw
        }
        
        $inventory += $fileData
    }
    
    # Exporter les résultats
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "inventory.json"
    $inventory | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8
    
    Write-Log "Inventaire terminé. $($inventory.Count) fichiers trouvés." -Level "Success"
    Write-Log "Résultats exportés dans $outputPath" -Level "Success"
    
    return $outputPath
}

# Fonction pour analyser la structure des fichiers
function Invoke-RoadmapStructureAnalysis {
    param (
        [string]$InventoryPath,
        [string]$OutputDirectory
    )
    
    Write-Log "Démarrage de l'analyse de la structure des fichiers..." -Level "Info"
    
    # Charger l'inventaire
    $inventory = Get-Content -Path $InventoryPath -Raw | ConvertFrom-Json
    
    # Analyser la structure des fichiers
    $results = @()
    
    foreach ($file in $inventory) {
        Write-Log "Analyse de la structure de $($file.Path)..." -Level "Info"
        
        $analysis = [PSCustomObject]@{
            Path = $file.Path
            Title = ""
            SectionCount = 0
            TaskCount = 0
            CompletedTaskCount = 0
            CompletionRate = 0
        }
        
        # Extraire le titre (première ligne commençant par #)
        if ($file.Content -match "^#\s+(.+)$") {
            $analysis.Title = $Matches[1].Trim()
        }
        
        # Compter les sections (lignes commençant par ##)
        $analysis.SectionCount = ([regex]::Matches($file.Content, "^##\s+")).Count
        
        # Compter les tâches (lignes avec cases à cocher)
        $analysis.TaskCount = ([regex]::Matches($file.Content, "\s*[-*+]\s*\[([ xX])\]")).Count
        
        # Compter les tâches terminées (cases cochées)
        $analysis.CompletedTaskCount = ([regex]::Matches($file.Content, "\s*[-*+]\s*\[[xX]\]")).Count
        
        # Calculer le taux de complétion
        if ($analysis.TaskCount -gt 0) {
            $analysis.CompletionRate = [math]::Round(($analysis.CompletedTaskCount / $analysis.TaskCount) * 100, 2)
        }
        
        $results += $analysis
    }
    
    # Exporter les résultats
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "structure_analysis.json"
    $results | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8
    
    Write-Log "Analyse terminée. $($results.Count) fichiers analysés." -Level "Success"
    Write-Log "Résultats exportés dans $outputPath" -Level "Success"
    
    return $outputPath
}

# Fonction pour identifier les doublons et versions obsolètes
function Invoke-RoadmapDuplicateSearch {
    param (
        [string]$InventoryPath,
        [string]$OutputDirectory
    )
    
    Write-Log "Démarrage de la recherche de doublons et versions obsolètes..." -Level "Info"
    
    # Charger l'inventaire
    $inventory = Get-Content -Path $InventoryPath -Raw | ConvertFrom-Json
    
    # Regrouper les fichiers par nom similaire
    $fileGroups = @{}
    
    foreach ($file in $inventory) {
        $fileName = Split-Path -Path $file.Path -Leaf
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        
        # Extraire la version si présente (ex: roadmap-v2.md -> roadmap)
        $baseNameWithoutVersion = $baseName -replace '-v\d+$', ''
        $baseNameWithoutVersion = $baseNameWithoutVersion -replace '_v\d+$', ''
        
        if (-not $fileGroups.ContainsKey($baseNameWithoutVersion)) {
            $fileGroups[$baseNameWithoutVersion] = @()
        }
        
        $fileGroups[$baseNameWithoutVersion] += $file
    }
    
    # Analyser chaque groupe de fichiers
    $results = @{
        Duplicates = @()
        Obsolete = @()
        VersionedFiles = @()
    }
    
    foreach ($groupName in $fileGroups.Keys) {
        $group = $fileGroups[$groupName]
        
        # Si le groupe contient plus d'un fichier, analyser les similarités
        if ($group.Count -gt 1) {
            Write-Log "Analyse du groupe '$groupName' ($($group.Count) fichiers)..." -Level "Info"
            
            # Trier les fichiers par date de modification (du plus récent au plus ancien)
            $sortedFiles = $group | Sort-Object -Property LastWriteTime -Descending
            
            # Le fichier le plus récent est considéré comme la version actuelle
            $currentFile = $sortedFiles[0]
            
            # Vérifier les autres fichiers pour les doublons et versions obsolètes
            for ($i = 1; $i -lt $sortedFiles.Count; $i++) {
                $olderFile = $sortedFiles[$i]
                
                # Calculer la similarité entre le fichier actuel et le fichier plus ancien
                $similarity = 0
                
                if ($currentFile.Content -eq $olderFile.Content) {
                    $similarity = 1
                }
                else {
                    # Méthode simplifiée : comparer les longueurs et les caractères communs
                    $length1 = $currentFile.Content.Length
                    $length2 = $olderFile.Content.Length
                    
                    # Calculer le nombre de caractères communs
                    $commonChars = 0
                    $minLength = [Math]::Min($length1, $length2)
                    
                    for ($j = 0; $j -lt $minLength; $j++) {
                        if ($currentFile.Content[$j] -eq $olderFile.Content[$j]) {
                            $commonChars++
                        }
                    }
                    
                    # Calculer la similarité
                    $similarity = $commonChars / [Math]::Max($length1, $length2)
                }
                
                # Déterminer si c'est un doublon ou une version obsolète
                if ($similarity -ge 0.8) {
                    # Si les fichiers sont très similaires, considérer comme un doublon
                    $results.Duplicates += [PSCustomObject]@{
                        CurrentFile = $currentFile.Path
                        DuplicateFile = $olderFile.Path
                        Similarity = $similarity
                        Group = $groupName
                    }
                }
                else {
                    # Si les fichiers sont différents mais ont un nom similaire, considérer comme une version obsolète
                    $results.Obsolete += [PSCustomObject]@{
                        CurrentFile = $currentFile.Path
                        ObsoleteFile = $olderFile.Path
                        Similarity = $similarity
                        Group = $groupName
                    }
                }
            }
            
            # Ajouter le groupe aux fichiers versionnés
            $results.VersionedFiles += [PSCustomObject]@{
                Group = $groupName
                Files = $sortedFiles.Path
                CurrentVersion = $currentFile.Path
                OlderVersions = $sortedFiles | Select-Object -Skip 1 | ForEach-Object { $_.Path }
            }
        }
    }
    
    # Exporter les résultats
    $outputPath = Join-Path -Path $OutputDirectory -ChildPath "duplicates.json"
    $results | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8
    
    Write-Log "Recherche terminée." -Level "Success"
    Write-Log "  - Doublons trouvés: $($results.Duplicates.Count)" -Level "Info"
    Write-Log "  - Versions obsolètes trouvées: $($results.Obsolete.Count)" -Level "Info"
    Write-Log "  - Groupes de fichiers versionnés: $($results.VersionedFiles.Count)" -Level "Info"
    Write-Log "Résultats exportés dans $outputPath" -Level "Success"
    
    return $outputPath
}

# Fonction principale
function Invoke-SimpleRoadmapAnalysis {
    param (
        [string]$Action,
        [string]$OutputDirectory,
        [switch]$Force
    )
    
    # Initialiser le dossier de sortie
    Initialize-OutputDirectory -Directory $OutputDirectory -Force:$Force
    
    # Exécuter l'action demandée
    switch ($Action) {
        "Inventory" {
            return Invoke-RoadmapInventory -OutputDirectory $OutputDirectory -Force:$Force
        }
        "Analyze" {
            $inventoryPath = Join-Path -Path $OutputDirectory -ChildPath "inventory.json"
            if (-not (Test-Path -Path $inventoryPath)) {
                Write-Log "Le fichier d'inventaire $inventoryPath n'existe pas. Exécution de l'inventaire..." -Level "Warning"
                $inventoryPath = Invoke-RoadmapInventory -OutputDirectory $OutputDirectory -Force:$Force
            }
            
            return Invoke-RoadmapStructureAnalysis -InventoryPath $inventoryPath -OutputDirectory $OutputDirectory
        }
        "FindDuplicates" {
            $inventoryPath = Join-Path -Path $OutputDirectory -ChildPath "inventory.json"
            if (-not (Test-Path -Path $inventoryPath)) {
                Write-Log "Le fichier d'inventaire $inventoryPath n'existe pas. Exécution de l'inventaire..." -Level "Warning"
                $inventoryPath = Invoke-RoadmapInventory -OutputDirectory $OutputDirectory -Force:$Force
            }
            
            return Invoke-RoadmapDuplicateSearch -InventoryPath $inventoryPath -OutputDirectory $OutputDirectory
        }
        "All" {
            Write-Log "Exécution de toutes les actions..." -Level "Info"
            
            # Exécuter l'inventaire
            $inventoryPath = Invoke-RoadmapInventory -OutputDirectory $OutputDirectory -Force:$Force
            
            # Exécuter l'analyse de structure
            $structurePath = Invoke-RoadmapStructureAnalysis -InventoryPath $inventoryPath -OutputDirectory $OutputDirectory
            
            # Exécuter la recherche de doublons
            $duplicatesPath = Invoke-RoadmapDuplicateSearch -InventoryPath $inventoryPath -OutputDirectory $OutputDirectory
            
            # Créer un rapport de synthèse
            $summaryPath = Join-Path -Path $OutputDirectory -ChildPath "summary.json"
            
            $summary = @{
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                InventoryPath = $inventoryPath
                StructureAnalysisPath = $structurePath
                DuplicatesPath = $duplicatesPath
                Statistics = @{
                    TotalFiles = 0
                    DuplicateFiles = 0
                    ObsoleteFiles = 0
                    VersionedGroups = 0
                }
            }
            
            # Ajouter des statistiques si disponibles
            if (Test-Path -Path $inventoryPath) {
                $inventoryData = Get-Content -Path $inventoryPath -Raw | ConvertFrom-Json
                $summary.Statistics.TotalFiles = $inventoryData.Count
            }
            
            if (Test-Path -Path $duplicatesPath) {
                $duplicatesData = Get-Content -Path $duplicatesPath -Raw | ConvertFrom-Json
                $summary.Statistics.DuplicateFiles = $duplicatesData.Duplicates.Count
                $summary.Statistics.ObsoleteFiles = $duplicatesData.Obsolete.Count
                $summary.Statistics.VersionedGroups = $duplicatesData.VersionedFiles.Count
            }
            
            # Enregistrer le rapport de synthèse
            $summary | ConvertTo-Json -Depth 10 | Set-Content -Path $summaryPath -Encoding UTF8
            
            Write-Log "Toutes les actions terminées. Rapport de synthèse enregistré dans $summaryPath" -Level "Success"
            
            return $summaryPath
        }
        default {
            Write-Log "Action non reconnue : $Action" -Level "Error"
            return $null
        }
    }
}

# Exécution principale
try {
    $result = Invoke-SimpleRoadmapAnalysis -Action $Action -OutputDirectory $OutputDirectory -Force:$Force
    
    # Retourner le résultat
    return $result
}
catch {
    Write-Log "Erreur lors de l'exécution de l'action $Action : $_" -Level "Error"
    throw $_
}
