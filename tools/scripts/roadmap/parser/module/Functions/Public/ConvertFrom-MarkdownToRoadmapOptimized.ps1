<#
.SYNOPSIS
    Convertit un fichier markdown en structure d'objet PowerShell reprÃ©sentant une roadmap avec performance optimisÃ©e.

.DESCRIPTION
    La fonction ConvertFrom-MarkdownToRoadmapOptimized lit un fichier markdown et le convertit en une structure d'objet PowerShell.
    Elle est optimisÃ©e pour traiter efficacement les fichiers volumineux en utilisant des techniques de lecture par blocs
    et des structures de donnÃ©es optimisÃ©es.

.PARAMETER FilePath
    Chemin du fichier markdown Ã  convertir.

.PARAMETER IncludeMetadata
    Indique si les mÃ©tadonnÃ©es supplÃ©mentaires doivent Ãªtre extraites et incluses dans les objets.

.PARAMETER CustomStatusMarkers
    Hashtable dÃ©finissant des marqueurs de statut personnalisÃ©s et leur correspondance avec les statuts standard.

.PARAMETER DetectDependencies
    Indique si les dÃ©pendances entre tÃ¢ches doivent Ãªtre dÃ©tectÃ©es et incluses dans les objets.

.PARAMETER ValidateStructure
    Indique si la structure de la roadmap doit Ãªtre validÃ©e.

.PARAMETER BlockSize
    Taille des blocs de lecture en lignes. Par dÃ©faut, 1000 lignes.

.EXAMPLE
    ConvertFrom-MarkdownToRoadmapOptimized -FilePath ".\roadmap.md"
    Convertit le fichier roadmap.md en structure d'objet PowerShell.

.EXAMPLE
    ConvertFrom-MarkdownToRoadmapOptimized -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies -BlockSize 500
    Convertit le fichier roadmap.md en structure d'objet PowerShell avec extraction des mÃ©tadonnÃ©es et dÃ©tection des dÃ©pendances,
    en utilisant des blocs de 500 lignes.

.OUTPUTS
    [PSCustomObject] ReprÃ©sentant la structure de la roadmap.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
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

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Mesurer le temps d'exÃ©cution
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    # CrÃ©er l'objet roadmap
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

    # DÃ©finir les marqueurs de statut standard
    $statusMarkers = [System.Collections.Generic.Dictionary[string, string]]::new([StringComparer]::OrdinalIgnoreCase)
    $statusMarkers["x"] = "Complete"
    $statusMarkers["X"] = "Complete"
    $statusMarkers["~"] = "InProgress"
    $statusMarkers["!"] = "Blocked"
    $statusMarkers[" "] = "Incomplete"
    $statusMarkers[""] = "Incomplete"

    # Fusionner avec les marqueurs personnalisÃ©s si fournis
    if ($null -ne $CustomStatusMarkers) {
        foreach ($key in $CustomStatusMarkers.Keys) {
            $statusMarkers[$key] = $CustomStatusMarkers[$key]
        }
    }

    # CrÃ©er des expressions rÃ©guliÃ¨res compilÃ©es pour amÃ©liorer les performances
    $sectionRegex = [regex]::new('^##\s+(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $taskRegex = [regex]::new('^(\s*)[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $titleRegex = [regex]::new('^#\s+(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    
    # Expressions rÃ©guliÃ¨res pour les mÃ©tadonnÃ©es
    $assigneeRegex = [regex]::new('@([a-zA-Z0-9_-]+)(?:\s|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $tagRegex = [regex]::new('#([a-zA-Z0-9_-]+)(?:\s|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $priorityRegex = [regex]::new('\b(P[0-9])\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $dateRegex = [regex]::new('@date:(\d{4}-\d{2}-\d{2})', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $dependsOnRegex = [regex]::new('@depends:([^@\s]+)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $estimateRegex = [regex]::new('@estimate:(\d+[hdjmw])', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $startDateRegex = [regex]::new('@start:(\d{4}-\d{2}-\d{2})', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $endDateRegex = [regex]::new('@end:(\d{4}-\d{2}-\d{2})', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $refRegex = [regex]::new('\bref:([a-zA-Z0-9_.-]+)\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)

    # Variables pour suivre l'Ã©tat du parsing
    $currentSection = $null
    $taskStack = [System.Collections.Generic.Stack[object]]::new()
    $currentLevel = 0
    $lineNumber = 0
    $inDescription = $false
    $descriptionLines = [System.Collections.ArrayList]::new()
    $titleFound = $false

    # Ouvrir le fichier en mode streaming pour Ã©conomiser la mÃ©moire
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
            
            # Extraire le titre (premiÃ¨re ligne commenÃ§ant par #)
            if (-not $titleFound -and $titleRegex.IsMatch($line)) {
                $match = $titleRegex.Match($line)
                $roadmap.Title = $match.Groups[1].Value
                $titleFound = $true
                $inDescription = $true
                continue
            }
            
            # Collecter les lignes de description
            if ($inDescription) {
                # Si on trouve une section, on arrÃªte la description
                if ($sectionRegex.IsMatch($line)) {
                    $inDescription = $false
                    # Ne pas continuer, traiter la section ci-dessous
                }
                else {
                    # Ignorer les lignes vides au dÃ©but de la description
                    if ($descriptionLines.Count -eq 0 -and [string]::IsNullOrWhiteSpace($line)) {
                        continue
                    }
                    
                    $descriptionLines.Add($line) | Out-Null
                    continue
                }
            }
            
            # DÃ©tecter les sections (lignes commenÃ§ant par ##)
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
            
            # DÃ©tecter les tÃ¢ches (lignes commenÃ§ant par -, *, + avec ou sans case Ã  cocher)
            if ($null -ne $currentSection -and $taskRegex.IsMatch($line)) {
                $match = $taskRegex.Match($line)
                $indent = $match.Groups[1].Value.Length
                $statusMarker = $match.Groups[2].Value
                $id = $match.Groups[3].Value
                $title = $match.Groups[4].Value
                
                # DÃ©terminer le statut
                $status = if ($statusMarkers.ContainsKey($statusMarker)) {
                    $statusMarkers[$statusMarker]
                } else {
                    "Incomplete"
                }
                
                # Extraire les mÃ©tadonnÃ©es
                $metadata = [System.Collections.Generic.Dictionary[string, object]]::new()
                
                # Extraire les mÃ©tadonnÃ©es avancÃ©es si demandÃ©
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
                    
                    # Extraire les prioritÃ©s (P1, P2, etc.)
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
                    
                    # Extraire les dÃ©pendances (format: @depends:ID1,ID2,...)
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
                    
                    # Extraire les dates de dÃ©but (format: @start:YYYY-MM-DD)
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
                    
                    # Extraire les rÃ©fÃ©rences (format: ref:ID)
                    $refMatch = $refRegex.Match($title)
                    if ($refMatch.Success) {
                        $metadata["References"] = $refMatch.Groups[1].Value
                        # Nettoyer le titre
                        $title = $refRegex.Replace($title, '')
                    }
                }
                
                # Nettoyer le titre (supprimer les espaces en trop)
                $title = $title.Trim()
                
                # CrÃ©er l'objet tÃ¢che
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
                
                # Ajouter la tÃ¢che au dictionnaire global
                if (-not [string]::IsNullOrEmpty($id)) {
                    if ($roadmap.AllTasks.ContainsKey($id)) {
                        if ($ValidateStructure) {
                            $roadmap.ValidationIssues.Add("Duplicate task ID: $id at line $lineNumber") | Out-Null
                        }
                    } else {
                        $roadmap.AllTasks[$id] = $task
                    }
                }
                
                # DÃ©terminer le parent en fonction de l'indentation
                if ($indent -eq 0) {
                    # TÃ¢che de premier niveau
                    $currentSection.Tasks.Add($task) | Out-Null
                    $taskStack.Clear()
                    $taskStack.Push($task)
                    $currentLevel = 0
                }
                elseif ($indent -gt $currentLevel) {
                    # Sous-tÃ¢che
                    if ($taskStack.Count -gt 0) {
                        $parent = $taskStack.Peek()
                        $parent.SubTasks.Add($task) | Out-Null
                        $taskStack.Push($task)
                        $currentLevel = $indent
                    }
                }
                elseif ($indent -eq $currentLevel) {
                    # MÃªme niveau que la tÃ¢che prÃ©cÃ©dente
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
                    # Remonter dans la hiÃ©rarchie
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
        
        # DÃ©finir la description
        if ($descriptionLines.Count -gt 0) {
            # Supprimer les lignes vides Ã  la fin
            while ($descriptionLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($descriptionLines[$descriptionLines.Count - 1])) {
                $descriptionLines.RemoveAt($descriptionLines.Count - 1)
            }
            $roadmap.Description = [string]::Join("`n", $descriptionLines)
        }
        
        # DÃ©tecter les dÃ©pendances entre tÃ¢ches si demandÃ©
        if ($DetectDependencies) {
            # Traiter les dÃ©pendances explicites (via mÃ©tadonnÃ©es)
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
                
                # DÃ©tecter les dÃ©pendances implicites (basÃ©es sur les rÃ©fÃ©rences dans le titre)
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
        
        # Valider la structure de la roadmap si demandÃ©
        if ($ValidateStructure) {
            # VÃ©rifier les IDs manquants
            foreach ($section in $roadmap.Sections) {
                foreach ($task in $section.Tasks) {
                    if ([string]::IsNullOrEmpty($task.Id)) {
                        $roadmap.ValidationIssues.Add("Missing task ID at line $($task.LineNumber)") | Out-Null
                    }
                    
                    # VÃ©rifier rÃ©cursivement les sous-tÃ¢ches
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
            
            # VÃ©rifier les dÃ©pendances circulaires
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
