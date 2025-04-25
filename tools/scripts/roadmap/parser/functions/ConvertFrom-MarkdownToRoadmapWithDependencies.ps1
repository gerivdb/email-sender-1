<#
.SYNOPSIS
    Convertit un fichier markdown en structure d'objet PowerShell représentant une roadmap avec dépendances.

.DESCRIPTION
    La fonction ConvertFrom-MarkdownToRoadmapWithDependencies lit un fichier markdown et le convertit en une structure d'objet PowerShell.
    Elle est spécialement conçue pour traiter les roadmaps au format markdown avec des tâches, des statuts, des identifiants,
    et des dépendances entre les tâches.

.PARAMETER FilePath
    Chemin du fichier markdown à convertir.

.PARAMETER IncludeMetadata
    Indique si les métadonnées supplémentaires doivent être extraites et incluses dans les objets.

.PARAMETER DetectDependencies
    Indique si les dépendances entre tâches doivent être détectées et incluses dans les objets.

.PARAMETER ValidateStructure
    Indique si la structure de la roadmap doit être validée.

.EXAMPLE
    ConvertFrom-MarkdownToRoadmapWithDependencies -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
    Convertit le fichier roadmap.md en structure d'objet PowerShell avec extraction des métadonnées et détection des dépendances.

.OUTPUTS
    [PSCustomObject] Représentant la structure de la roadmap.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function ConvertFrom-MarkdownToRoadmapWithDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [switch]$DetectDependencies,

        [Parameter(Mandatory = $false)]
        [switch]$ValidateStructure
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw
    $lines = $content -split "`r?`n"

    # Créer l'objet roadmap
    $roadmap = [PSCustomObject]@{
        Title            = "Roadmap"
        Description      = ""
        Sections         = [System.Collections.ArrayList]::new()
        AllTasks         = [System.Collections.Generic.Dictionary[string, object]]::new([StringComparer]::OrdinalIgnoreCase)
        ValidationIssues = [System.Collections.ArrayList]::new()
    }

    # Extraire le titre et la description
    $inDescription = $false
    $descriptionLines = [System.Collections.ArrayList]::new()

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        # Extraire le titre (première ligne commençant par #)
        if ($line -match '^#\s+(.+)$' -and -not $inDescription) {
            $roadmap.Title = $matches[1]
            $inDescription = $true
            continue
        }

        # Collecter les lignes de description
        if ($inDescription) {
            # Si on trouve une section, on arrête la description
            if ($line -match '^##\s+') {
                $inDescription = $false
                $i-- # Reculer d'une ligne pour traiter la section au prochain tour
                continue
            }

            # Ignorer les lignes vides au début de la description
            if ($descriptionLines.Count -eq 0 -and [string]::IsNullOrWhiteSpace($line)) {
                continue
            }

            $descriptionLines.Add($line) | Out-Null
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

    # Définir les marqueurs de statut standard
    $statusMarkers = [System.Collections.Generic.Dictionary[string, string]]::new([StringComparer]::OrdinalIgnoreCase)
    $statusMarkers["x"] = "Complete"
    $statusMarkers["X"] = "Complete"
    $statusMarkers["~"] = "InProgress"
    $statusMarkers["!"] = "Blocked"
    $statusMarkers[" "] = "Incomplete"
    $statusMarkers[""] = "Incomplete"

    # Première passe : extraire les sections et les tâches
    $currentSection = $null
    $taskStack = [System.Collections.Generic.Stack[object]]::new()
    $currentLevel = 0
    $lineNumber = 0

    foreach ($line in $lines) {
        $lineNumber++

        # Détecter les sections (lignes commençant par ##)
        if ($line -match '^##\s+(.+)$') {
            $sectionTitle = $matches[1]
            $currentSection = [PSCustomObject]@{
                Title      = $sectionTitle
                Tasks      = [System.Collections.ArrayList]::new()
                LineNumber = $lineNumber
            }
            $roadmap.Sections.Add($currentSection) | Out-Null
            $taskStack.Clear()
            $currentLevel = 0
            continue
        }

        # Détecter les tâches (lignes commençant par -, *, + avec ou sans case à cocher)
        if ($null -ne $currentSection -and $line -match '^(\s*)[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$') {
            $indent = $matches[1].Length
            $statusMarker = $matches[2]
            $id = $matches[3]
            $title = $matches[4]

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
                if ($title -match '@([a-zA-Z0-9_-]+)') {
                    $metadata["Assignee"] = $matches[1]
                    # Nettoyer le titre
                    $title = $title -replace '@[a-zA-Z0-9_-]+', ''
                }

                # Extraire les tags (#tag)
                $tags = [System.Collections.ArrayList]::new()
                $tagMatches = [regex]::Matches($title, '#([a-zA-Z0-9_-]+)')
                foreach ($match in $tagMatches) {
                    $tags.Add($match.Groups[1].Value) | Out-Null
                }
                if ($tags.Count -gt 0) {
                    $metadata["Tags"] = $tags
                    # Nettoyer le titre
                    $title = $title -replace '#[a-zA-Z0-9_-]+', ''
                }

                # Extraire les priorités (P1, P2, etc.)
                if ($title -match '\b(P[0-9])\b') {
                    $metadata["Priority"] = $matches[1]
                    # Nettoyer le titre
                    $title = $title -replace '\bP[0-9]\b', ''
                }

                # Extraire les dates (format: @date:YYYY-MM-DD)
                if ($title -match '@date:(\d{4}-\d{2}-\d{2})') {
                    $metadata["Date"] = $matches[1]
                    # Nettoyer le titre
                    $title = $title -replace '@date:\d{4}-\d{2}-\d{2}', ''
                }

                # Extraire les dépendances (format: @depends:ID1,ID2,...)
                if ($title -match '@depends:([\w\.-]+)') {
                    $dependsOn = $matches[1] -split ','
                    $metadata["DependsOn"] = $dependsOn
                    # Nettoyer le titre
                    $title = $title -replace '@depends:[\w\.-]+', ''
                }

                # Extraire les estimations (format: @estimate:2h, @estimate:3d, etc.)
                if ($title -match '@estimate:(\d+[hdjmw])') {
                    $metadata["Estimate"] = $matches[1]
                    # Nettoyer le titre
                    $title = $title -replace '@estimate:\d+[hdjmw]', ''
                }

                # Extraire les dates de début (format: @start:YYYY-MM-DD)
                if ($title -match '@start:(\d{4}-\d{2}-\d{2})') {
                    $metadata["StartDate"] = $matches[1]
                    # Nettoyer le titre
                    $title = $title -replace '@start:\d{4}-\d{2}-\d{2}', ''
                }

                # Extraire les dates de fin (format: @end:YYYY-MM-DD)
                if ($title -match '@end:(\d{4}-\d{2}-\d{2})') {
                    $metadata["EndDate"] = $matches[1]
                    # Nettoyer le titre
                    $title = $title -replace '@end:\d{4}-\d{2}-\d{2}', ''
                }
            }

            # Nettoyer le titre (supprimer les espaces en trop)
            $title = $title.Trim()

            # Créer l'objet tâche
            $task = [PSCustomObject]@{
                Id             = $id
                Title          = $title
                Status         = $status
                Level          = [int]($indent / 2)  # Supposer 2 espaces par niveau
                SubTasks       = [System.Collections.ArrayList]::new()
                Dependencies   = [System.Collections.ArrayList]::new()
                DependentTasks = [System.Collections.ArrayList]::new()
                Metadata       = $metadata
                LineNumber     = $lineNumber
                OriginalText   = $line
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
            } elseif ($indent -gt $currentLevel) {
                # Sous-tâche
                if ($taskStack.Count -gt 0) {
                    $parent = $taskStack.Peek()
                    $parent.SubTasks.Add($task) | Out-Null
                    $taskStack.Push($task)
                    $currentLevel = $indent
                }
            } elseif ($indent -eq $currentLevel) {
                # Même niveau que la tâche précédente
                if ($taskStack.Count -gt 1) {
                    $taskStack.Pop() | Out-Null
                    $parent = $taskStack.Peek()
                    $parent.SubTasks.Add($task) | Out-Null
                    $taskStack.Push($task)
                } else {
                    $taskStack.Clear()
                    $currentSection.Tasks.Add($task) | Out-Null
                    $taskStack.Push($task)
                }
            } elseif ($indent -lt $currentLevel) {
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
                } else {
                    $currentSection.Tasks.Add($task) | Out-Null
                }

                $taskStack.Push($task)
                $currentLevel = $indent
            }
        }
    }

    # Deuxième passe : traiter les dépendances
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
                    } elseif ($ValidateStructure) {
                        $roadmap.ValidationIssues.Add("Task $id depends on non-existent task $dependencyId") | Out-Null
                    }
                }
            }
        }

        # Détecter les dépendances implicites (basées sur les références dans le titre)
        $refRegex = [regex]::new('\bref:([\w\.-]+)\b', [System.Text.RegularExpressions.RegexOptions]::Compiled)

        foreach ($id in $roadmap.AllTasks.Keys) {
            $task = $roadmap.AllTasks[$id]

            # Chercher les références dans le titre
            $titleMatches = $refRegex.Matches($task.Title)
            foreach ($match in $titleMatches) {
                $refId = $match.Groups[1].Value
                if ($roadmap.AllTasks.ContainsKey($refId) -and $refId -ne $id) {
                    $dependency = $roadmap.AllTasks[$refId]
                    if (-not $task.Dependencies.Contains($dependency)) {
                        $task.Dependencies.Add($dependency) | Out-Null
                        $dependency.DependentTasks.Add($task) | Out-Null
                    }
                } elseif ($ValidateStructure -and $refId -ne $id) {
                    $roadmap.ValidationIssues.Add("Task $id references non-existent task $refId") | Out-Null
                }
            }

            # Détecter les dépendances basées sur les identifiants hiérarchiques
            if ($id -match '^(.+)\.\d+$') {
                $parentId = $matches[1]
                if ($roadmap.AllTasks.ContainsKey($parentId) -and $parentId -ne $id) {
                    $dependency = $roadmap.AllTasks[$parentId]
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

    return $roadmap
}
