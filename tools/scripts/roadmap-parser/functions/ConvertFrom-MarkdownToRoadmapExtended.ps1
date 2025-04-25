<#
.SYNOPSIS
    Convertit un fichier markdown en structure d'objet PowerShell représentant une roadmap avec fonctionnalités étendues.

.DESCRIPTION
    La fonction ConvertFrom-MarkdownToRoadmapExtended lit un fichier markdown et le convertit en une structure d'objet PowerShell.
    Elle est spécialement conçue pour traiter les roadmaps au format markdown avec des tâches, des statuts, des identifiants,
    des dépendances et des métadonnées avancées.

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

.EXAMPLE
    ConvertFrom-MarkdownToRoadmapExtended -FilePath ".\roadmap.md"
    Convertit le fichier roadmap.md en structure d'objet PowerShell.

.EXAMPLE
    ConvertFrom-MarkdownToRoadmapExtended -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
    Convertit le fichier roadmap.md en structure d'objet PowerShell avec extraction des métadonnées et détection des dépendances.

.OUTPUTS
    [PSCustomObject] Représentant la structure de la roadmap.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function ConvertFrom-MarkdownToRoadmapExtended {
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
        Sections         = @()
        AllTasks         = @{}  # Dictionnaire de toutes les tâches par ID
        ValidationIssues = @()  # Liste des problèmes de validation
    }

    # Extraire le titre et la description
    $inDescription = $false
    $descriptionLines = @()

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

            $descriptionLines += $line
        }
    }

    # Définir la description
    if ($descriptionLines.Count -gt 0) {
        # Supprimer les lignes vides à la fin
        while ($descriptionLines.Count -gt 0 -and [string]::IsNullOrWhiteSpace($descriptionLines[-1])) {
            $descriptionLines = $descriptionLines[0..($descriptionLines.Count - 2)]
        }
        $roadmap.Description = $descriptionLines -join "`n"
    }

    # Définir les marqueurs de statut standard
    $statusMarkers = @{
        "x" = "Complete"
        # "X" = "Complete"  # Traité manuellement ci-dessous
        "~" = "InProgress"
        "!" = "Blocked"
        " " = "Incomplete"
        ""  = "Incomplete"
    }

    # Ajouter manuellement le cas "X" (majuscule)
    $statusMarkers["X"] = "Complete"

    # Fusionner avec les marqueurs personnalisés si fournis
    if ($null -ne $CustomStatusMarkers) {
        foreach ($key in $CustomStatusMarkers.Keys) {
            $statusMarkers[$key] = $CustomStatusMarkers[$key]
        }
    }

    # Extraire les sections et les tâches
    $currentSection = $null
    $taskStack = @()
    $currentLevel = 0
    $lineNumber = 0

    foreach ($line in $lines) {
        $lineNumber++

        # Détecter les sections (lignes commençant par ##)
        if ($line -match '^##\s+(.+)$') {
            $sectionTitle = $matches[1]
            $currentSection = [PSCustomObject]@{
                Title      = $sectionTitle
                Tasks      = @()
                LineNumber = $lineNumber
            }
            $roadmap.Sections += $currentSection
            $taskStack = @()
            $currentLevel = 0
            continue
        }

        # Détecter les tâches (lignes commençant par -, *, + avec ou sans case à cocher)
        if ($line -match '^(\s*)[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$' -and $null -ne $currentSection) {
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
            $metadata = @{}

            # Extraire les métadonnées avancées si demandé
            if ($IncludeMetadata) {
                # Extraire les assignations (@personne)
                if ($title -match '@([a-zA-Z0-9_-]+)') {
                    $metadata["Assignee"] = $matches[1]
                    # Nettoyer le titre
                    $title = $title -replace '@[a-zA-Z0-9_-]+', ''
                }

                # Extraire les tags (#tag)
                $tags = @()
                $tagMatches = [regex]::Matches($title, '#([a-zA-Z0-9_-]+)')
                foreach ($match in $tagMatches) {
                    $tags += $match.Groups[1].Value
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

                    # Ajouter les dépendances explicites
                    foreach ($dependencyId in $dependsOn) {
                        if ($roadmap.AllTasks.ContainsKey($dependencyId)) {
                            $dependency = $roadmap.AllTasks[$dependencyId]
                            $task.Dependencies.Add($dependency) | Out-Null
                            $dependency.DependentTasks.Add($task) | Out-Null
                        }
                    }
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
                SubTasks       = @()
                Dependencies   = @()  # Liste des tâches dont cette tâche dépend
                DependentTasks = @()  # Liste des tâches qui dépendent de cette tâche
                Metadata       = $metadata
                LineNumber     = $lineNumber
                OriginalText   = $line
            }

            # Ajouter la tâche au dictionnaire global
            if (-not [string]::IsNullOrEmpty($id)) {
                if ($roadmap.AllTasks.ContainsKey($id)) {
                    if ($ValidateStructure) {
                        $roadmap.ValidationIssues += "Duplicate task ID: $id at line $lineNumber"
                    }
                } else {
                    $roadmap.AllTasks[$id] = $task
                }
            }

            # Déterminer le parent en fonction de l'indentation
            if ($indent -eq 0) {
                # Tâche de premier niveau
                $currentSection.Tasks += $task
                $taskStack = @($task)
                $currentLevel = 0
            } elseif ($indent -gt $currentLevel) {
                # Sous-tâche
                if ($taskStack.Count -gt 0) {
                    $taskStack[-1].SubTasks += $task
                    $taskStack += $task
                    $currentLevel = $indent
                }
            } elseif ($indent -eq $currentLevel) {
                # Même niveau que la tâche précédente
                if ($taskStack.Count -gt 1) {
                    $taskStack = $taskStack[0..($taskStack.Count - 2)]
                    $taskStack[-1].SubTasks += $task
                    $taskStack += $task
                } else {
                    $currentSection.Tasks += $task
                    $taskStack = @($task)
                }
            } elseif ($indent -lt $currentLevel) {
                # Remonter dans la hiérarchie
                $levelDiff = [int](($currentLevel - $indent) / 2)
                if ($levelDiff -ge $taskStack.Count) {
                    $taskStack = @()
                    $currentSection.Tasks += $task
                    $taskStack += $task
                } else {
                    $taskStack = $taskStack[0..($taskStack.Count - $levelDiff - 1)]
                    $taskStack[-1].SubTasks += $task
                    $taskStack += $task
                }
                $currentLevel = $indent
            }
        }
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
                        $task.Dependencies += $dependency
                        $dependency.DependentTasks += $task
                    } elseif ($ValidateStructure) {
                        $roadmap.ValidationIssues += "Task $id depends on non-existent task $dependencyId"
                    }
                }
            }
        }

        # Détecter les dépendances implicites (basées sur les références dans le titre)
        foreach ($id in $roadmap.AllTasks.Keys) {
            $task = $roadmap.AllTasks[$id]
            if ($task.Title -match '\bref:([a-zA-Z0-9_.-]+)\b') {
                $refId = $matches[1]
                if ($roadmap.AllTasks.ContainsKey($refId) -and $refId -ne $id) {
                    $dependency = $roadmap.AllTasks[$refId]
                    if (-not $task.Dependencies.Contains($dependency)) {
                        $task.Dependencies += $dependency
                        $dependency.DependentTasks += $task
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
                    $roadmap.ValidationIssues += "Missing task ID at line $($task.LineNumber)"
                }

                # Vérifier récursivement les sous-tâches
                function Test-SubTasks {
                    param (
                        [PSCustomObject]$Task
                    )

                    foreach ($subTask in $Task.SubTasks) {
                        if ([string]::IsNullOrEmpty($subTask.Id)) {
                            $roadmap.ValidationIssues += "Missing subtask ID at line $($subTask.LineNumber)"
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
                [System.Collections.ArrayList]$VisitedTasks = (New-Object System.Collections.ArrayList)
            )

            if ($VisitedTasks.Contains($Task.Id)) {
                $roadmap.ValidationIssues += "Circular dependency detected involving task $($Task.Id)"
                return $true
            }

            $VisitedTasks.Add($Task.Id) | Out-Null

            foreach ($dependency in $Task.Dependencies) {
                $result = Test-CircularDependencies -Task $dependency -VisitedTasks $VisitedTasks
                if ($result) {
                    return $true
                }
            }

            $VisitedTasks.RemoveAt($VisitedTasks.Count - 1) | Out-Null
            return $false
        }

        foreach ($id in $roadmap.AllTasks.Keys) {
            $task = $roadmap.AllTasks[$id]
            Test-CircularDependencies -Task $task
        }
    }

    return $roadmap
}
