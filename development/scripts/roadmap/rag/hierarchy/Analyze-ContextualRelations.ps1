# Analyze-ContextualRelations.ps1
# Script pour analyser les relations contextuelles entre les tâches dans les fichiers markdown de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$Content,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetectImplicitRelations,
    
    [Parameter(Mandatory = $false)]
    [switch]$AnalyzeSectionTitles,
    
    [Parameter(Mandatory = $false)]
    [switch]$DetectThematicGroups,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "GraphViz")]
    [string]$OutputFormat = "JSON"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$utilsPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
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
            "Debug" { "Gray" }
        }
        
        Write-Host "[$Level] $Message" -ForegroundColor $color
    }
}

# Fonction pour extraire les tâches et leurs relations
function Get-TasksAndRelations {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $false)]
        [switch]$DetectImplicitRelations,
        
        [Parameter(Mandatory = $false)]
        [switch]$AnalyzeSectionTitles,
        
        [Parameter(Mandatory = $false)]
        [switch]$DetectThematicGroups
    )
    
    Write-Log "Extraction des tâches et de leurs relations..." -Level "Debug"
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $analysis = @{
        Tasks = @{}
        ExplicitRelations = @{}
        ImplicitRelations = @{}
        Sections = @{}
        ThematicGroups = @{}
        Stats = @{
            TotalTasks = 0
            CompletedTasks = 0
            ExplicitRelations = 0
            ImplicitRelations = 0
            Sections = 0
            ThematicGroups = 0
        }
    }
    
    # Patterns pour détecter les tâches et les relations
    $patterns = @{
        Task = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
        TaskWithoutId = '^\s*[-*+]\s*\[([ xX])\]\s*(.*)'
        ExplicitRelation = '@(?:depends|blocks|related):([A-Za-z0-9\.\-_,]+)'
        SectionHeader = '^(#{1,6})\s+(.*)'
    }
    
    # Variables pour suivre le contexte
    $currentSection = ""
    $currentSectionLevel = 0
    $currentSectionId = ""
    $sectionHierarchy = @()
    $taskHierarchy = @()
    $lineNumber = 0
    $lastTaskId = ""
    $lastTaskIndent = 0
    $tasksByIndent = @{}
    
    foreach ($line in $lines) {
        $lineNumber++
        
        # Détecter les sections (titres)
        if ($line -match $patterns.SectionHeader) {
            $headerLevel = $matches[1].Length
            $headerTitle = $matches[2].Trim()
            
            # Mettre à jour la hiérarchie des sections
            if ($headerLevel -le $sectionHierarchy.Count) {
                $sectionHierarchy = $sectionHierarchy[0..($headerLevel - 1)]
            }
            
            while ($sectionHierarchy.Count -lt $headerLevel) {
                $sectionHierarchy += ""
            }
            
            $sectionHierarchy[$headerLevel - 1] = $headerTitle
            
            # Créer un ID pour cette section
            $currentSectionId = "section_" + ($lineNumber)
            $currentSection = $headerTitle
            $currentSectionLevel = $headerLevel
            
            # Enregistrer la section
            $analysis.Sections[$currentSectionId] = @{
                Title = $headerTitle
                Level = $headerLevel
                LineNumber = $lineNumber
                Path = $sectionHierarchy[0..($headerLevel - 1)] -join " > "
                Tasks = @()
            }
            
            $analysis.Stats.Sections++
            
            # Si l'analyse des titres de section est activée, extraire des informations supplémentaires
            if ($AnalyzeSectionTitles) {
                # Détecter les mots-clés thématiques dans le titre
                $keywords = @("configuration", "installation", "setup", "api", "interface", "database", "security", "authentication", "authorization", "testing", "deployment", "monitoring", "logging", "performance", "optimization", "documentation", "maintenance")
                
                foreach ($keyword in $keywords) {
                    if ($headerTitle -match $keyword) {
                        if (-not $analysis.Sections[$currentSectionId].ContainsKey("Keywords")) {
                            $analysis.Sections[$currentSectionId].Keywords = @()
                        }
                        
                        $analysis.Sections[$currentSectionId].Keywords += $keyword
                    }
                }
            }
            
            continue
        }
        
        # Détecter les tâches avec identifiants
        if ($line -match $patterns.Task) {
            $status = $matches[1]
            $taskId = $matches[2]
            $taskTitle = $matches[3].Trim()
            
            # Calculer l'indentation
            if ($line -match '^(\s*)') {
                $indent = $matches[1].Length
            } else {
                $indent = 0
            }
            
            # Mettre à jour la hiérarchie des tâches
            if ($indent -lt $lastTaskIndent) {
                # Remonter dans la hiérarchie
                $levelsToRemove = [Math]::Ceiling(($lastTaskIndent - $indent) / 2)
                if ($taskHierarchy.Count -gt $levelsToRemove) {
                    $taskHierarchy = $taskHierarchy[0..($taskHierarchy.Count - $levelsToRemove - 1)]
                } else {
                    $taskHierarchy = @()
                }
            } elseif ($indent -gt $lastTaskIndent) {
                # Descendre dans la hiérarchie
                $taskHierarchy += $lastTaskId
            } else {
                # Même niveau, remplacer le dernier élément
                if ($taskHierarchy.Count -gt 0) {
                    $taskHierarchy[-1] = $lastTaskId
                }
            }
            
            # Enregistrer la tâche
            $analysis.Tasks[$taskId] = @{
                Id = $taskId
                Title = $taskTitle
                Status = if ($status -match '[xX]') { "Completed" } else { "Pending" }
                LineNumber = $lineNumber
                Indent = $indent
                Section = $currentSectionId
                Parents = @($taskHierarchy)
                Children = @()
                ExplicitDependencies = @()
                ImplicitDependencies = @()
                Line = $line
            }
            
            # Mettre à jour les statistiques
            $analysis.Stats.TotalTasks++
            if ($status -match '[xX]') {
                $analysis.Stats.CompletedTasks++
            }
            
            # Ajouter cette tâche à la section courante
            if (-not [string]::IsNullOrEmpty($currentSectionId)) {
                $analysis.Sections[$currentSectionId].Tasks += $taskId
            }
            
            # Enregistrer cette tâche par niveau d'indentation
            if (-not $tasksByIndent.ContainsKey($indent)) {
                $tasksByIndent[$indent] = @()
            }
            $tasksByIndent[$indent] += $taskId
            
            # Mettre à jour les relations parent-enfant
            foreach ($parentId in $taskHierarchy) {
                if ($analysis.Tasks.ContainsKey($parentId)) {
                    if (-not $analysis.Tasks[$parentId].Children.Contains($taskId)) {
                        $analysis.Tasks[$parentId].Children += $taskId
                    }
                }
            }
            
            # Détecter les relations explicites
            $explicitRelations = [regex]::Matches($taskTitle, $patterns.ExplicitRelation)
            foreach ($relation in $explicitRelations) {
                $relatedIds = $relation.Groups[1].Value -split ','
                
                foreach ($relatedId in $relatedIds) {
                    $relatedId = $relatedId.Trim()
                    
                    if (-not $analysis.ExplicitRelations.ContainsKey($taskId)) {
                        $analysis.ExplicitRelations[$taskId] = @()
                    }
                    
                    if (-not $analysis.ExplicitRelations[$taskId].Contains($relatedId)) {
                        $analysis.ExplicitRelations[$taskId] += $relatedId
                        $analysis.Stats.ExplicitRelations++
                    }
                    
                    # Ajouter la dépendance à la tâche
                    if (-not $analysis.Tasks[$taskId].ExplicitDependencies.Contains($relatedId)) {
                        $analysis.Tasks[$taskId].ExplicitDependencies += $relatedId
                    }
                }
            }
            
            # Mettre à jour les variables pour la prochaine itération
            $lastTaskId = $taskId
            $lastTaskIndent = $indent
        } elseif ($line -match $patterns.TaskWithoutId) {
            # Tâche sans identifiant, mais qui pourrait avoir des relations implicites
            $status = $matches[1]
            $taskTitle = $matches[2].Trim()
            
            # Générer un ID temporaire pour cette tâche
            $tempTaskId = "task_" + $lineNumber
            
            # Calculer l'indentation
            if ($line -match '^(\s*)') {
                $indent = $matches[1].Length
            } else {
                $indent = 0
            }
            
            # Enregistrer la tâche
            $analysis.Tasks[$tempTaskId] = @{
                Id = $tempTaskId
                Title = $taskTitle
                Status = if ($status -match '[xX]') { "Completed" } else { "Pending" }
                LineNumber = $lineNumber
                Indent = $indent
                Section = $currentSectionId
                Parents = @()
                Children = @()
                ExplicitDependencies = @()
                ImplicitDependencies = @()
                Line = $line
                IsTemporary = $true
            }
            
            # Mettre à jour les statistiques
            $analysis.Stats.TotalTasks++
            if ($status -match '[xX]') {
                $analysis.Stats.CompletedTasks++
            }
            
            # Ajouter cette tâche à la section courante
            if (-not [string]::IsNullOrEmpty($currentSectionId)) {
                $analysis.Sections[$currentSectionId].Tasks += $tempTaskId
            }
        }
    }
    
    # Détecter les relations implicites si demandé
    if ($DetectImplicitRelations) {
        Write-Log "Détection des relations implicites..." -Level "Debug"
        
        # Parcourir toutes les tâches pour détecter les relations implicites
        foreach ($taskId in $analysis.Tasks.Keys) {
            $task = $analysis.Tasks[$taskId]
            
            # Relation implicite 1: Tâches consécutives dans la même section avec même indentation
            $sectionTasks = if ($task.Section -and $analysis.Sections.ContainsKey($task.Section)) {
                $analysis.Sections[$task.Section].Tasks
            } else { @() }
            
            $taskIndex = [array]::IndexOf($sectionTasks, $taskId)
            
            if ($taskIndex -ge 0 -and $taskIndex -lt ($sectionTasks.Count - 1)) {
                $nextTaskId = $sectionTasks[$taskIndex + 1]
                $nextTask = $analysis.Tasks[$nextTaskId]
                
                if ($nextTask.Indent -eq $task.Indent) {
                    if (-not $analysis.ImplicitRelations.ContainsKey($nextTaskId)) {
                        $analysis.ImplicitRelations[$nextTaskId] = @()
                    }
                    
                    if (-not $analysis.ImplicitRelations[$nextTaskId].Contains($taskId)) {
                        $analysis.ImplicitRelations[$nextTaskId] += $taskId
                        $analysis.Stats.ImplicitRelations++
                    }
                    
                    # Ajouter la dépendance implicite à la tâche
                    if (-not $analysis.Tasks[$nextTaskId].ImplicitDependencies.Contains($taskId)) {
                        $analysis.Tasks[$nextTaskId].ImplicitDependencies += $taskId
                    }
                }
            }
            
            # Relation implicite 2: Tâches avec des mots-clés similaires
            $taskWords = $task.Title -split '\W+' | Where-Object { $_.Length -gt 3 } | ForEach-Object { $_.ToLower() }
            
            foreach ($otherTaskId in $analysis.Tasks.Keys) {
                if ($otherTaskId -eq $taskId) { continue }
                
                $otherTask = $analysis.Tasks[$otherTaskId]
                $otherWords = $otherTask.Title -split '\W+' | Where-Object { $_.Length -gt 3 } | ForEach-Object { $_.ToLower() }
                
                $commonWords = $taskWords | Where-Object { $otherWords -contains $_ }
                
                if ($commonWords.Count -ge 3) {  # Au moins 3 mots significatifs en commun
                    if (-not $analysis.ImplicitRelations.ContainsKey($taskId)) {
                        $analysis.ImplicitRelations[$taskId] = @()
                    }
                    
                    if (-not $analysis.ImplicitRelations[$taskId].Contains($otherTaskId)) {
                        $analysis.ImplicitRelations[$taskId] += $otherTaskId
                        $analysis.Stats.ImplicitRelations++
                    }
                    
                    # Ajouter la relation thématique
                    if (-not $analysis.Tasks[$taskId].ImplicitDependencies.Contains($otherTaskId)) {
                        $analysis.Tasks[$taskId].ImplicitDependencies += $otherTaskId
                        $analysis.Tasks[$taskId].ThematicRelation = $true
                    }
                }
            }
        }
    }
    
    # Détecter les groupes thématiques si demandé
    if ($DetectThematicGroups) {
        Write-Log "Détection des groupes thématiques..." -Level "Debug"
        
        # Extraire les mots-clés significatifs de chaque tâche
        $taskKeywords = @{}
        
        foreach ($taskId in $analysis.Tasks.Keys) {
            $task = $analysis.Tasks[$taskId]
            $keywords = $task.Title -split '\W+' | 
                Where-Object { $_.Length -gt 3 -and $_ -notmatch '^\d+$' } | 
                ForEach-Object { $_.ToLower() }
            
            $taskKeywords[$taskId] = $keywords
        }
        
        # Regrouper les tâches par mots-clés communs
        $keywordGroups = @{}
        
        foreach ($taskId in $taskKeywords.Keys) {
            $keywords = $taskKeywords[$taskId]
            
            foreach ($keyword in $keywords) {
                if (-not $keywordGroups.ContainsKey($keyword)) {
                    $keywordGroups[$keyword] = @()
                }
                
                $keywordGroups[$keyword] += $taskId
            }
        }
        
        # Filtrer les groupes significatifs (au moins 3 tâches)
        $significantGroups = $keywordGroups.GetEnumerator() | 
            Where-Object { $_.Value.Count -ge 3 } | 
            Sort-Object -Property { $_.Value.Count } -Descending
        
        # Créer les groupes thématiques
        $groupId = 1
        
        foreach ($group in $significantGroups) {
            $keyword = $group.Key
            $tasks = $group.Value
            
            $analysis.ThematicGroups["group_$groupId"] = @{
                Keyword = $keyword
                Tasks = $tasks
                Count = $tasks.Count
            }
            
            $groupId++
            $analysis.Stats.ThematicGroups++
        }
    }
    
    return $analysis
}

# Fonction pour générer la sortie au format demandé
function Format-AnalysisOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "Markdown", "GraphViz")]
        [string]$Format = "JSON"
    )
    
    Write-Log "Génération de la sortie au format $Format..." -Level "Debug"
    
    switch ($Format) {
        "JSON" {
            return $Analysis | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $markdown = "# Analyse des relations contextuelles`n`n"
            
            # Statistiques générales
            $markdown += "## Statistiques`n`n"
            $markdown += "- Tâches totales : $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches terminées : $($Analysis.Stats.CompletedTasks)`n"
            $markdown += "- Relations explicites : $($Analysis.Stats.ExplicitRelations)`n"
            $markdown += "- Relations implicites : $($Analysis.Stats.ImplicitRelations)`n"
            $markdown += "- Sections : $($Analysis.Stats.Sections)`n"
            $markdown += "- Groupes thématiques : $($Analysis.Stats.ThematicGroups)`n`n"
            
            # Sections
            $markdown += "## Sections`n`n"
            foreach ($sectionId in $Analysis.Sections.Keys) {
                $section = $Analysis.Sections[$sectionId]
                $markdown += "### $($section.Title) (Niveau $($section.Level))`n`n"
                $markdown += "- Ligne : $($section.LineNumber)`n"
                $markdown += "- Chemin : $($section.Path)`n"
                $markdown += "- Tâches : $($section.Tasks.Count)`n"
                
                if ($section.ContainsKey("Keywords") -and $section.Keywords.Count -gt 0) {
                    $markdown += "- Mots-clés : $($section.Keywords -join ", ")`n"
                }
                
                $markdown += "`n"
            }
            
            # Tâches avec relations
            $markdown += "## Tâches avec relations`n`n"
            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                
                # Ne pas inclure les tâches temporaires
                if ($task.ContainsKey("IsTemporary") -and $task.IsTemporary) { continue }
                
                $markdown += "### $taskId : $($task.Title)`n`n"
                $markdown += "- Statut : $($task.Status)`n"
                $markdown += "- Ligne : $($task.LineNumber)`n"
                
                if ($task.Parents.Count -gt 0) {
                    $markdown += "- Parents : $($task.Parents -join ", ")`n"
                }
                
                if ($task.Children.Count -gt 0) {
                    $markdown += "- Enfants : $($task.Children -join ", ")`n"
                }
                
                if ($task.ExplicitDependencies.Count -gt 0) {
                    $markdown += "- Dépendances explicites : $($task.ExplicitDependencies -join ", ")`n"
                }
                
                if ($task.ImplicitDependencies.Count -gt 0) {
                    $markdown += "- Dépendances implicites : $($task.ImplicitDependencies -join ", ")`n"
                }
                
                $markdown += "`n"
            }
            
            # Groupes thématiques
            if ($Analysis.ThematicGroups.Count -gt 0) {
                $markdown += "## Groupes thématiques`n`n"
                foreach ($groupId in $Analysis.ThematicGroups.Keys) {
                    $group = $Analysis.ThematicGroups[$groupId]
                    $markdown += "### Groupe : $($group.Keyword)`n`n"
                    $markdown += "- Nombre de tâches : $($group.Count)`n"
                    $markdown += "- Tâches : $($group.Tasks -join ", ")`n`n"
                }
            }
            
            return $markdown
        }
        "GraphViz" {
            $dot = "digraph RoadmapRelations {`n"
            $dot += "  rankdir=LR;`n"
            $dot += "  node [shape=box, style=filled, fillcolor=lightblue];`n`n"
            
            # Nœuds pour les tâches
            foreach ($taskId in $Analysis.Tasks.Keys) {
                $task = $Analysis.Tasks[$taskId]
                
                # Ne pas inclure les tâches temporaires
                if ($task.ContainsKey("IsTemporary") -and $task.IsTemporary) { continue }
                
                $color = if ($task.Status -eq "Completed") { "lightgreen" } else { "lightblue" }
                $dot += "  \"$taskId\" [label=\"$taskId: $($task.Title)\", fillcolor=$color];`n"
            }
            
            $dot += "`n"
            
            # Arêtes pour les relations explicites
            foreach ($taskId in $Analysis.ExplicitRelations.Keys) {
                foreach ($relatedId in $Analysis.ExplicitRelations[$taskId]) {
                    $dot += "  \"$relatedId\" -> \"$taskId\" [color=red, label=\"explicit\"];`n"
                }
            }
            
            # Arêtes pour les relations implicites
            foreach ($taskId in $Analysis.ImplicitRelations.Keys) {
                foreach ($relatedId in $Analysis.ImplicitRelations[$taskId]) {
                    $dot += "  \"$relatedId\" -> \"$taskId\" [color=blue, style=dashed, label=\"implicit\"];`n"
                }
            }
            
            # Arêtes pour les relations parent-enfant
            foreach ($taskId in $Analysis.Tasks.Keys) {
                $task = $Analysis.Tasks[$taskId]
                
                # Ne pas inclure les tâches temporaires
                if ($task.ContainsKey("IsTemporary") -and $task.IsTemporary) { continue }
                
                foreach ($childId in $task.Children) {
                    $dot += "  \"$taskId\" -> \"$childId\" [color=green];`n"
                }
            }
            
            $dot += "}`n"
            
            return $dot
        }
    }
}

# Fonction principale
function Analyze-ContextualRelations {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [switch]$DetectImplicitRelations,
        [switch]$AnalyzeSectionTitles,
        [switch]$DetectThematicGroups,
        [string]$OutputPath,
        [string]$OutputFormat
    )
    
    # Vérifier les paramètres
    if ([string]::IsNullOrEmpty($Content) -and [string]::IsNullOrEmpty($FilePath)) {
        Write-Log "Vous devez spécifier soit un chemin de fichier, soit un contenu à analyser." -Level "Error"
        return $null
    }
    
    # Lire le contenu du fichier si nécessaire
    if ([string]::IsNullOrEmpty($Content) -and -not [string]::IsNullOrEmpty($FilePath)) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Log "Le fichier spécifié n'existe pas : $FilePath" -Level "Error"
            return $null
        }
        
        try {
            $Content = Get-Content -Path $FilePath -Raw
        } catch {
            Write-Log "Erreur lors de la lecture du fichier : $_" -Level "Error"
            return $null
        }
    }
    
    # Analyser les tâches et leurs relations
    $analysis = Get-TasksAndRelations -Content $Content -DetectImplicitRelations:$DetectImplicitRelations -AnalyzeSectionTitles:$AnalyzeSectionTitles -DetectThematicGroups:$DetectThematicGroups
    
    # Afficher les résultats de l'analyse
    Write-Log "Analyse des relations contextuelles terminée :" -Level "Info"
    Write-Log "  - Tâches totales : $($analysis.Stats.TotalTasks)" -Level "Info"
    Write-Log "  - Tâches terminées : $($analysis.Stats.CompletedTasks)" -Level "Info"
    Write-Log "  - Relations explicites : $($analysis.Stats.ExplicitRelations)" -Level "Info"
    Write-Log "  - Relations implicites : $($analysis.Stats.ImplicitRelations)" -Level "Info"
    Write-Log "  - Sections : $($analysis.Stats.Sections)" -Level "Info"
    Write-Log "  - Groupes thématiques : $($analysis.Stats.ThematicGroups)" -Level "Info"
    
    # Générer la sortie au format demandé
    $output = Format-AnalysisOutput -Analysis $analysis -Format $OutputFormat
    
    # Enregistrer la sortie si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        try {
            $output | Set-Content -Path $OutputPath -Encoding UTF8
            Write-Log "Sortie enregistrée dans : $OutputPath" -Level "Success"
        } catch {
            Write-Log "Erreur lors de l'enregistrement de la sortie : $_" -Level "Error"
        }
    }
    
    return @{
        Analysis = $analysis
        Output = $output
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Analyze-ContextualRelations -FilePath $FilePath -Content $Content -DetectImplicitRelations:$DetectImplicitRelations -AnalyzeSectionTitles:$AnalyzeSectionTitles -DetectThematicGroups:$DetectThematicGroups -OutputPath $OutputPath -OutputFormat $OutputFormat
}
