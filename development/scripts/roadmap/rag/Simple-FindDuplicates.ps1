# Simple-FindDuplicates.ps1
# Script simplifié pour identifier les doublons et versions obsolètes
# Version: 1.0
# Date: 2025-05-15

# Paramètres
$testDirectory = "projet/roadmaps/analysis/test/files"
$outputPath = "projet/roadmaps/analysis/duplicates.json"

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

# Fonction pour calculer la similarité entre deux chaînes de texte
function Get-TextSimilarity {
    param (
        [string]$Text1,
        [string]$Text2
    )
    
    # Si l'un des textes est vide, retourner 0
    if ([string]::IsNullOrEmpty($Text1) -or [string]::IsNullOrEmpty($Text2)) {
        return 0
    }
    
    # Normaliser les textes (supprimer les espaces, mettre en minuscules)
    $normalizedText1 = $Text1.ToLower().Trim()
    $normalizedText2 = $Text2.ToLower().Trim()
    
    # Si les textes sont identiques après normalisation, retourner 1
    if ($normalizedText1 -eq $normalizedText2) {
        return 1
    }
    
    # Méthode simplifiée : comparer les longueurs et les caractères communs
    $length1 = $normalizedText1.Length
    $length2 = $normalizedText2.Length
    
    # Calculer le nombre de caractères communs
    $commonChars = 0
    $minLength = [Math]::Min($length1, $length2)
    
    for ($i = 0; $i -lt $minLength; $i++) {
        if ($normalizedText1[$i] -eq $normalizedText2[$i]) {
            $commonChars++
        }
    }
    
    # Calculer la similarité
    $similarity = $commonChars / [Math]::Max($length1, $length2)
    
    return $similarity
}

# Fonction pour identifier les doublons et versions obsolètes
function Find-DuplicateRoadmaps {
    param (
        [string[]]$FilePaths,
        [double]$SimilarityThreshold = 0.8
    )
    
    $results = @{
        Duplicates = @()
        Obsolete = @()
        VersionedFiles = @()
    }
    
    # Regrouper les fichiers par nom similaire
    $fileGroups = @{}
    
    foreach ($filePath in $FilePaths) {
        $fileName = Split-Path -Path $filePath -Leaf
        $baseName = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
        
        # Extraire la version si présente (ex: roadmap-v2.md -> roadmap)
        $baseNameWithoutVersion = $baseName -replace '-v\d+$', ''
        $baseNameWithoutVersion = $baseNameWithoutVersion -replace '_v\d+$', ''
        
        if (-not $fileGroups.ContainsKey($baseNameWithoutVersion)) {
            $fileGroups[$baseNameWithoutVersion] = @()
        }
        
        $fileGroups[$baseNameWithoutVersion] += $filePath
    }
    
    # Analyser chaque groupe de fichiers
    foreach ($groupName in $fileGroups.Keys) {
        $group = $fileGroups[$groupName]
        
        # Si le groupe contient plus d'un fichier, analyser les similarités
        if ($group.Count -gt 1) {
            Write-Log "Analyse du groupe '$groupName' ($($group.Count) fichiers)..." -Level "Info"
            
            # Trier les fichiers par date de modification (du plus récent au plus ancien)
            $sortedFiles = $group | ForEach-Object {
                $fileInfo = Get-Item -Path $_
                [PSCustomObject]@{
                    Path = $_
                    LastWriteTime = $fileInfo.LastWriteTime
                    Content = Get-Content -Path $_ -Raw
                }
            } | Sort-Object -Property LastWriteTime -Descending
            
            # Le fichier le plus récent est considéré comme la version actuelle
            $currentFile = $sortedFiles[0]
            
            # Vérifier les autres fichiers pour les doublons et versions obsolètes
            for ($i = 1; $i -lt $sortedFiles.Count; $i++) {
                $olderFile = $sortedFiles[$i]
                
                # Calculer la similarité entre le fichier actuel et le fichier plus ancien
                $similarity = Get-TextSimilarity -Text1 $currentFile.Content -Text2 $olderFile.Content
                
                # Déterminer si c'est un doublon ou une version obsolète
                if ($similarity -ge $SimilarityThreshold) {
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
    
    return $results
}

# Exécution principale
try {
    Write-Log "Démarrage de la recherche de doublons et versions obsolètes..." -Level "Info"
    
    # Créer le dossier de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $outputPath -Parent
    if (-not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    
    # Créer des fichiers de test
    $testFiles = New-TestRoadmapFiles -TestDirectory $testDirectory
    
    # Rechercher les doublons et versions obsolètes
    $results = Find-DuplicateRoadmaps -FilePaths $testFiles -SimilarityThreshold 0.8
    
    Write-Log "Recherche terminée." -Level "Success"
    Write-Log "  - Doublons trouvés: $($results.Duplicates.Count)" -Level "Info"
    Write-Log "  - Versions obsolètes trouvées: $($results.Obsolete.Count)" -Level "Info"
    Write-Log "  - Groupes de fichiers versionnés: $($results.VersionedFiles.Count)" -Level "Info"
    
    # Exporter les résultats
    $results | ConvertTo-Json -Depth 10 | Set-Content -Path $outputPath -Encoding UTF8
    Write-Log "Résultats exportés dans $outputPath" -Level "Success"
}
catch {
    Write-Log "Erreur lors de la recherche de doublons : $_" -Level "Error"
}
