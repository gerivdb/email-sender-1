<#
.SYNOPSIS
    Convertit un fichier markdown en structure d'objet PowerShell représentant une roadmap avec performance optimisée.

.DESCRIPTION
    La fonction ConvertFrom-MarkdownToRoadmapOptimized lit un fichier markdown et le convertit en une structure d'objet PowerShell.
    Elle est optimisée pour traiter efficacement les fichiers volumineux en utilisant des techniques de lecture par blocs
    et des structures de données optimisées.

.PARAMETER FilePath
    Chemin du fichier markdown à convertir.

.PARAMETER IncludeMetadata
    Indique si les métadonnées supplémentaires doivent être extraites et incluses dans les objets.

.PARAMETER CustomStatusMarkers
    Hashtable définissant des marqueurs de statut personnalisés et leur correspondance avec les statuts standard.

.PARAMETER DetectDependencies
    Indique si les dépendances entre tâches doivent être détectées et incluses dans les objets.

.PARAMETER ValidateStructure
    Indique si la structure de la roadmap doit être validée.

.PARAMETER BlockSize
    Taille des blocs de lecture en lignes. Par défaut, 1000 lignes.

.EXAMPLE
    ConvertFrom-MarkdownToRoadmapOptimized -FilePath ".\roadmap.md"
    Convertit le fichier roadmap.md en structure d'objet PowerShell.

.EXAMPLE
    ConvertFrom-MarkdownToRoadmapOptimized -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies -BlockSize 500
    Convertit le fichier roadmap.md en structure d'objet PowerShell avec extraction des métadonnées et détection des dépendances,
    en utilisant des blocs de 500 lignes.

.OUTPUTS
    [PSCustomObject] Représentant la structure de la roadmap.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function ConvertFrom-MarkdownToRoadmapOptimized {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [hashtable]$CustomStatusMarkers,

        [Parameter(Mandatory = $false)]
        [switch]$DetectDependencies,

        [Parameter(Mandatory = $false)]
        [switch]$ValidateStructure,
        
        [Parameter(Mandatory = $false)]
        [int]$BlockSize = 1000
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Mesurer le temps d'exécution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # Créer l'objet roadmap
    $roadmap = [PSCustomObject]@{
        Title = "Roadmap"
        Description = ""
        Sections = [System.Collections.ArrayList]::new()
        AllTasks = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::OrdinalIgnoreCase)
        ValidationIssues = [System.Collections.ArrayList]::new()
        Statistics = [PSCustomObject]@{
            TotalLines = 0
            ProcessingTime = 0
            MemoryUsage = 0
        }
    }

    # Définir les marqueurs de statut standard
    $statusMarkers = [System.Collections.Generic.Dictionary[string, string]]::new([StringComparer]::OrdinalIgnoreCase)
    $statusMarkers["x"] = "Complete"
    $statusMarkers["X"] = "Complete"
    $statusMarkers["~"] = "InProgress"
    $statusMarkers["!"] = "Blocked"
    $statusMarkers[" "] = "Incomplete"
    $statusMarkers[""] = "Incomplete"

    # Fusionner avec les marqueurs personnalisés si fournis
    if ($null -ne $CustomStatusMarkers) {
        foreach ($key in $CustomStatusMarkers.Keys) {
            $statusMarkers[$key] = $CustomStatusMarkers[$key]
        }
    }

    # Créer des expressions régulières compilées pour améliorer les performances
    $sectionRegex = [regex]::new('^##\s+(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $taskRegex = [regex]::new('^(\s*)[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $titleRegex = [regex]::new('^#\s+(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    
    # Expressions régulières pour les métadonnées
    $assigneeRegex = [regex]::new('@([a-zA-Z0-9_-]+)(?:\s|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $tagRegex = [regex]::new('#([a-zA-Z0-9_-]+)(?:\s|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $priorityRegex = [regex]::new('\b(P[0-9])\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $dateRegex = [regex]::new('@date:(\d{4}-\d{2}-\d{2})', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $dependsOnRegex = [regex]::new('@depends:([^@\s]+)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $estimateRegex = [regex]::new('@estimate:(\d+[hdjmw])', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $startDateRegex = [regex]::new('@start:(\d{4}-\d{2}-\d{2})', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $endDateRegex = [regex]::new('@end:(\d{4}-\d{2}-\d{2})', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $refRegex = [regex]::new('\bref:([a-zA-Z0-9_.-]+)\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)

    # Variables pour suivre l'état du parsing
    $currentSection = $null
    $taskStack = [System.Collections.Generic.Stack[object]]::new()
    $currentLevel = 0
    $lineNumber = 0
    $inDescription = $false
    $descriptionLines = [System.Collections.ArrayList]::new()
    $titleFound = $false

    # Ouvrir le fichier en mode streaming pour économiser la mémoire
    $reader = [System.IO.StreamReader]::new($FilePath, [System.Text.Encoding]::UTF8)
    
    try {
        # Lire le fichier par blocs
        $buffer = New-Object char[] $BlockSize
        $line = ""
        $linesProcessed = 0
        
        while (($read = $reader.ReadLine()) -ne $null) {
            $lineNumber++
            $linesProcessed++
            $line = $read
            
            # Extraire le titre (première ligne commençant par #)
            if (-not $titleFound -and $titleRegex.IsMatch($line)) {
                $match = $titleRegex.Match($line)
                $roadmap.Title = $match.Groups[1].Value
                $titleFound = $true
                $inDescription = $true
                continue
            }
            
            # Collecter les lignes de description
            if ($inDescription) {
                # Si on trouve une section, on arrête la description
                if ($sectionRegex.IsMatch($line)) {
                    $inDescription = $false
                    # Ne pas continuer, traiter la section ci-dessous
                }
                else {
                    # Ignorer les lignes vides au début de la description
                    if ($descriptionLines.Count -eq 0 -and [string]::IsNullOrWhiteSpace($line)) {
                        continue
                    }
                    
                    $descriptionLines.Add($line) | Out-Null
                    continue
                }
            }
            
            # Détecter les sections (lignes commençant par ##)
            if ($sectionRegex.IsMatch($line)) {
                $match = $sectionRegex.Match($line)
                $sectionTitle = $match.Groups[1].Value
                $currentSection = [PSCustomObject]@{
                    Title = $sectionTitle
                    Tasks = [System.Collections.ArrayList]::new()
                    LineNumber = $lineNumber
                }
                $roadmap.Sections.Add($currentSection) | Out-Null
                $taskStack.Clear()
                $currentLevel = 0
                continue
            }
            
            # Détecter les tâches (lignes commençant par -, *, + avec ou sans case à cocher)
            if ($null -ne $currentSection -and $taskRegex.IsMatch($line)) {
                $match = $taskRegex.Match($line)
                $indent = $match.Groups[1].Value.Length
                $statusMarker = $match.Groups[2].Value
                $id = $match.Groups[3].Value
                $title = $match.Groups[4].Value
                
                # Déterminer le statut
                $status = if ($statusMarkers.ContainsKey($statusMarker)) {
                    $statusMarkers[$statusMarker]
                } else {
                    "Incomplete"
                }
                
                # Extraire les métadonnées
                $metadata = [System.Collections.Generic.Dictionary[string, object]]::new()
                
                # Extraire les métadonnées avancées si demandé
                if ($IncludeMetadata) {
                    # Extraire les assignations (@personne)
                    $assigneeMatch = $assigneeRegex.Match($title)
                    if ($assigneeMatch.Success) {
                        $metadata["Assignee"] = $assigneeMatch.Groups[1].Value
                        # Nettoyer le titre
                        $title = $assigneeRegex.Replace($title, '')
                    }
                    
                    # Extraire les tags (#tag)
                    $tags = [System.Collections.ArrayList]::new()
                    $tagMatches = $tagRegex.Matches($title)
                    foreach ($tagMatch in $tagMatches) {
                        $tags.Add($tagMatch.Groups[1].Value) | Out-Null
                    }
                    if ($tags.Count -gt 0) {
                        $metadata["Tags"] = $tags
                        # Nettoyer le titre
                        $title = $tagRegex.Replace($title, '')
                    }
                    
                    # Extraire les priorités (P1, P2, etc.)
                    $priorityMatch = $priorityRegex.Match($title)
                    if ($priorityMatch.Success) {
                        $metadata["Priority"] = $priorityMatch.Groups[1].Value
                        # Nettoyer le titre
                        $title = $priorityRegex.Replace($title, '')
                    }
                    
                    # Extraire les dates (format: @date:YYYY-MM-DD)
                    $dateMatch = $dateRegex.Match($title)
                    if ($dateMatch.Success) {
                        $metadata["Date"] = $dateMatch.Groups[1].Value
                        # Nettoyer le titre
                        $title = $dateRegex.Replace($title, '')
                    }
                    
                    # Extraire les dépendances (format: @depends:ID1,ID2,...)
                    $dependsOnMatch = $dependsOnRegex.Match($title)
                    if ($dependsOnMatch.Success) {
                        $dependsOn = $dependsOnMatch.Groups[1].Value -split ','
                        $metadata["DependsOn"] = $dependsOn
                        # Nettoyer le titre
                        $title = $dependsOnRegex.Replace($title, '')
                    }
                    
                    # Extraire les estimations (format: @estimate:2h, @estimate:3d, etc.)
                    $estimateMatch = $estimateRegex.Match($title)
                    if ($estimateMatch.Success) {
                        $metadata["Estimate"] = $estimateMatch.Groups[1].Value
                        # Nettoyer le titre
                        $title = $estimateRegex.Replace($title, '')
                    }
                    
                    # Extraire les dates de début (format: @start:YYYY-MM-DD)
                    $startDateMatch = $startDateRegex.Match($title)
                    if ($startDateMatch.Success) {
                        $metadata["StartDate"] = $startDateMatch.Groups[1].Value
                        # Nettoyer le titre
                        $title = $startDateRegex.Replace($title, '')
                    }
                    
                    # Extraire les dates de fin (format: @end:YYYY-MM-DD)
                    $endDateMatch = $endDateRegex.Match($title)
                    if ($endDateMatch.Success) {
                        $metadata["EndDate"] = $endDateMatch.Groups[1].Value
                        # Nettoyer le titre
                        $title = $endDateRegex.Replace($title, '')
                    }
                    
                    # Extraire les références (format: ref:ID)
                    $refMatch = $refRegex.Match($title)
                    if ($refMatch.Success) {
                        $metadata["References"] = $refMatch.Groups[1].Value
                        # Nettoyer le titre
                        $title = $refRegex.Replace($title, '')
                    }
                }
                
                # Nettoyer le titre (supprimer les espaces en trop)
                $title = $title.Trim()
                
                # Créer l'objet tâche
                $task = [PSCustomObject]@{
                    Id = $id
                    Title = $title
                    Status = $status
                    Level = [int]($indent / 2)  # Supposer 2 espaces par niveau
                    SubTasks = [System.Collections.ArrayList]::new()
                    Dependencies = [System.Collections.ArrayList]::new()
                    DependentTasks = [System.Collections.ArrayList]::new()
                    Metadata = $metadata
                    LineNumber = $lineNumber
                    OriginalText = $line
                }
                
                # Ajouter la tâche au dictionnaire global
                if (-not [string]::IsNullOrEmpty($id)) {
                    if ($roadmap.AllTasks.ContainsKey($id)) {
                        if ($ValidateStructure) {
                            $roadmap.ValidationIssues.Add("Duplicate task ID: $id at line $lineNumber") | Out-Null
                        }
                    } else {
                        $roadmap.AllTasks[$id] = $task
                    }
                }
                
                # Déterminer le parent en fonction de l'indentation
                if ($indent -eq 0) {
                    # Tâche de premier niveau
                    $currentSection.Tasks.Add($task) | Out-Null
                    $taskStack.Clear()
                    $taskStack.Push($task)
                    $currentLevel = 0
                }
                elseif ($indent -gt $currentLevel) {
                    # Sous-tâche
                    if ($taskStack.Count -gt 0) {
                        $parent = $taskStack.Peek()
                        $parent.SubTasks.Add($task) | Out-Null
                        $taskStack.Push($task)
                        $currentLevel = $indent
                    }
                }
                elseif ($indent -eq $currentLevel) {
                    # Même niveau que la tâche précédente
                    if ($taskStack.Count -gt 1) {
                        $taskStack.Pop() | Out-Null
                        $parent = $taskStack.Peek()
                        $parent.SubTasks.Add($task) | Out-Null
                        $taskStack.Push($task)
                    }
                    else {
                        $taskStack.Clear()
                        $currentSection.Tasks.Add($task) | Out-Null
                        $taskStack.Push($task)
                    }
                }
                elseif ($indent -lt $currentLevel) {
                    # Remonter dans la hiérarchie
                    $levelDiff = [int](($currentLevel - $indent) / 2)
                    for ($i = 0; $i -lt $levelDiff + 1; $i++) {
                        if ($taskStack.Count -gt 0) {
                            $taskStack.Pop() | Out-Null
                        }
                    }
                    
                    if ($taskStack.Count -gt 0) {
                        $parent = $taskStack.Peek()
                        $parent.SubTasks.Add($task) | Out-Null
                    }
                    else {
                        $currentSection.Tasks.Add($task) | Out-Null
                    }
                    
                    $taskStack.Push($task)
                    $currentLevel = $indent
                }
                
                continue
            }
        }
        
        # Définir la description
        if ($descriptionLines.Count -gt 0) {
            # Supprimer les lignes vides à la fin
            while ($descriptionLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($descriptionLines[$descriptionLines.Count - 1])) {
                $descriptionLines.RemoveAt($descriptionLines.Count - 1)
            }
            $roadmap.Description = [string]::Join("`n", $descriptionLines)
        }
        
        # Détecter les dépendances entre tâches si demandé
        if ($DetectDependencies) {
            # Traiter les dépendances explicites (via métadonnées)
            foreach ($id in $roadmap.AllTasks.Keys) {
                $task = $roadmap.AllTasks[$id]
                if ($task.Metadata.ContainsKey("DependsOn")) {
                    foreach ($dependencyId in $task.Metadata["DependsOn"]) {
                        if ($roadmap.AllTasks.ContainsKey($dependencyId)) {
                            $dependency = $roadmap.AllTasks[$dependencyId]
                            $task.Dependencies.Add($dependency) | Out-Null
                            $dependency.DependentTasks.Add($task) | Out-Null
                        }
                        elseif ($ValidateStructure) {
                            $roadmap.ValidationIssues.Add("Task $id depends on non-existent task $dependencyId") | Out-Null
                        }
                    }
                }
                
                # Détecter les dépendances implicites (basées sur les références dans le titre)
                if ($task.Metadata.ContainsKey("References")) {
                    $refId = $task.Metadata["References"]
                    if ($roadmap.AllTasks.ContainsKey($refId) -and $refId -ne $id) {
                        $dependency = $roadmap.AllTasks[$refId]
                        if (-not $task.Dependencies.Contains($dependency)) {
                            $task.Dependencies.Add($dependency) | Out-Null
                            $dependency.DependentTasks.Add($task) | Out-Null
                        }
                    }
                }
            }
        }
        
        # Valider la structure de la roadmap si demandé
        if ($ValidateStructure) {
            # Vérifier les IDs manquants
            foreach ($section in $roadmap.Sections) {
                foreach ($task in $section.Tasks) {
                    if ([string]::IsNullOrEmpty($task.Id)) {
                        $roadmap.ValidationIssues.Add("Missing task ID at line $($task.LineNumber)") | Out-Null
                    }
                    
                    # Vérifier récursivement les sous-tâches
                    function Test-SubTasks {
                        param (
                            [PSCustomObject]$Task
                        )
                        
                        foreach ($subTask in $Task.SubTasks) {
                            if ([string]::IsNullOrEmpty($subTask.Id)) {
                                $roadmap.ValidationIssues.Add("Missing subtask ID at line $($subTask.LineNumber)") | Out-Null
                            }
                            Test-SubTasks -Task $subTask
                        }
                    }
                    
                    Test-SubTasks -Task $task
                }
            }
            
            # Vérifier les dépendances circulaires
            function Test-CircularDependencies {
                param (
                    [PSCustomObject]$Task,
                    [System.Collections.Generic.HashSet[string]]$VisitedTasks = (New-Object System.Collections.Generic.HashSet[string])
                )
                
                if ($VisitedTasks.Contains($Task.Id)) {
                    $roadmap.ValidationIssues.Add("Circular dependency detected involving task $($Task.Id)") | Out-Null
                    return $true
                }
                
                $VisitedTasks.Add($Task.Id) | Out-Null
                
                foreach ($dependency in $Task.Dependencies) {
                    $result = Test-CircularDependencies -Task $dependency -VisitedTasks $VisitedTasks
                    if ($result) {
                        return $true
                    }
                }
                
                $VisitedTasks.Remove($Task.Id) | Out-Null
                return $false
            }
            
            foreach ($id in $roadmap.AllTasks.Keys) {
                $task = $roadmap.AllTasks[$id]
                Test-CircularDependencies -Task $task
            }
        }
        
        # Calculer les statistiques
        $stopwatch.Stop()
        $roadmap.Statistics.TotalLines = $linesProcessed
        $roadmap.Statistics.ProcessingTime = $stopwatch.ElapsedMilliseconds
        $roadmap.Statistics.MemoryUsage = [System.GC]::GetTotalMemory($true)
        
        return $roadmap
    }
    finally {
        # Fermer le fichier
        $reader.Close()
        $reader.Dispose()
    }
}
