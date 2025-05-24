# Get-TaskMetadata.ps1
# Script pour inférer des métadonnées à partir du contenu des tâches dans les fichiers markdown de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,
    
    [Parameter(Mandatory = $false)]
    [string]$Content,
    
    [Parameter(Mandatory = $false)]
    [switch]$InferPriority,
    
    [Parameter(Mandatory = $false)]
    [switch]$InferComplexity,
    
    [Parameter(Mandatory = $false)]
    [switch]$InferCategory,
    
    [Parameter(Mandatory = $false)]
    [switch]$InferDependencies,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "CSV")]
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

# Fonction pour extraire les tâches
function Get-TasksFromContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )
    
    Write-Log "Extraction des tâches..." -Level "Debug"
    
    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"
    
    # Initialiser les variables d'analyse
    $tasks = @{}
    
    # Pattern pour détecter les tâches
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    
    # Analyser chaque ligne
    $lineNumber = 0
    
    foreach ($line in $lines) {
        $lineNumber++
        
        # Détecter les tâches avec identifiants
        if ($line -match $taskPattern) {
            $status = $matches[1]
            $taskId = $matches[2]
            $taskTitle = $matches[3].Trim()
            
            # Calculer l'indentation
            if ($line -match '^(\s*)') {
                $indent = $matches[1].Length
            } else {
                $indent = 0
            }
            
            # Enregistrer la tâche
            $tasks[$taskId] = @{
                Id = $taskId
                Title = $taskTitle
                Status = if ($status -match '[xX]') { "Completed" } else { "Pending" }
                LineNumber = $lineNumber
                Indent = $indent
                Line = $line
                InferredMetadata = @{}
            }
        }
    }
    
    return $tasks
}

# Fonction pour inférer la priorité des tâches
function Get-TaskPriority {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks
    )
    
    Write-Log "Inférence de la priorité des tâches..." -Level "Debug"
    
    # Mots-clés indiquant une priorité élevée
    $highPriorityKeywords = @(
        "urgent", "critical", "important", "high", "priority", "asap", "immediately",
        "crucial", "vital", "essential", "key", "major", "significant", "primary"
    )
    
    # Mots-clés indiquant une priorité moyenne
    $mediumPriorityKeywords = @(
        "medium", "moderate", "normal", "standard", "regular", "average", "intermediate",
        "secondary", "next", "soon", "later"
    )
    
    # Mots-clés indiquant une priorité faible
    $lowPriorityKeywords = @(
        "low", "minor", "trivial", "optional", "eventually", "when possible", "nice to have",
        "if time permits", "tertiary", "last", "least"
    )
    
    foreach ($taskId in $Tasks.Keys) {
        $task = $Tasks[$taskId]
        $title = $task.Title.ToLower()
        
        # Vérifier les mots-clés de priorité élevée
        $highPriorityScore = 0
        foreach ($keyword in $highPriorityKeywords) {
            if ($title -match $keyword) {
                $highPriorityScore++
            }
        }
        
        # Vérifier les mots-clés de priorité moyenne
        $mediumPriorityScore = 0
        foreach ($keyword in $mediumPriorityKeywords) {
            if ($title -match $keyword) {
                $mediumPriorityScore++
            }
        }
        
        # Vérifier les mots-clés de priorité faible
        $lowPriorityScore = 0
        foreach ($keyword in $lowPriorityKeywords) {
            if ($title -match $keyword) {
                $lowPriorityScore++
            }
        }
        
        # Déterminer la priorité en fonction des scores
        if ($highPriorityScore -gt $mediumPriorityScore -and $highPriorityScore -gt $lowPriorityScore) {
            $priority = "High"
        } elseif ($lowPriorityScore -gt $highPriorityScore -and $lowPriorityScore -gt $mediumPriorityScore) {
            $priority = "Low"
        } elseif ($mediumPriorityScore -gt 0) {
            $priority = "Medium"
        } else {
            # Priorité par défaut basée sur la position dans la hiérarchie
            $parts = $taskId -split '\.'
            
            if ($parts.Count -eq 1) {
                # Tâche de premier niveau
                $priority = "High"
            } elseif ($parts.Count -eq 2) {
                # Tâche de deuxième niveau
                $priority = "Medium"
            } else {
                # Tâche de niveau inférieur
                $priority = "Low"
            }
        }
        
        # Enregistrer la priorité inférée
        $task.InferredMetadata.Priority = $priority
        $task.InferredMetadata.PriorityScores = @{
            High = $highPriorityScore
            Medium = $mediumPriorityScore
            Low = $lowPriorityScore
        }
    }
    
    return $Tasks
}

# Fonction pour inférer la complexité des tâches
function Get-TaskComplexity {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks
    )
    
    Write-Log "Inférence de la complexité des tâches..." -Level "Debug"
    
    # Mots-clés indiquant une complexité élevée
    $highComplexityKeywords = @(
        "complex", "complicated", "difficult", "challenging", "hard", "advanced", "sophisticated",
        "intricate", "elaborate", "comprehensive", "extensive", "detailed", "thorough", "in-depth"
    )
    
    # Mots-clés indiquant une complexité moyenne
    $mediumComplexityKeywords = @(
        "moderate", "intermediate", "standard", "normal", "regular", "average", "typical",
        "common", "usual", "ordinary", "conventional", "traditional", "mainstream"
    )
    
    # Mots-clés indiquant une complexité faible
    $lowComplexityKeywords = @(
        "simple", "easy", "basic", "straightforward", "elementary", "fundamental", "trivial",
        "quick", "fast", "rapid", "swift", "brief", "short", "minimal", "small"
    )
    
    foreach ($taskId in $Tasks.Keys) {
        $task = $Tasks[$taskId]
        $title = $task.Title.ToLower()
        
        # Vérifier les mots-clés de complexité élevée
        $highComplexityScore = 0
        foreach ($keyword in $highComplexityKeywords) {
            if ($title -match $keyword) {
                $highComplexityScore++
            }
        }
        
        # Vérifier les mots-clés de complexité moyenne
        $mediumComplexityScore = 0
        foreach ($keyword in $mediumComplexityKeywords) {
            if ($title -match $keyword) {
                $mediumComplexityScore++
            }
        }
        
        # Vérifier les mots-clés de complexité faible
        $lowComplexityScore = 0
        foreach ($keyword in $lowComplexityKeywords) {
            if ($title -match $keyword) {
                $lowComplexityScore++
            }
        }
        
        # Déterminer la complexité en fonction des scores
        if ($highComplexityScore -gt $mediumComplexityScore -and $highComplexityScore -gt $lowComplexityScore) {
            $complexity = "High"
        } elseif ($lowComplexityScore -gt $highComplexityScore -and $lowComplexityScore -gt $mediumComplexityScore) {
            $complexity = "Low"
        } elseif ($mediumComplexityScore -gt 0) {
            $complexity = "Medium"
        } else {
            # Complexité par défaut basée sur la profondeur dans la hiérarchie
            $parts = $taskId -split '\.'
            
            if ($parts.Count -ge 4) {
                # Tâche de niveau profond
                $complexity = "High"
            } elseif ($parts.Count -eq 3) {
                # Tâche de niveau intermédiaire
                $complexity = "Medium"
            } else {
                # Tâche de niveau supérieur
                $complexity = "Low"
            }
        }
        
        # Enregistrer la complexité inférée
        $task.InferredMetadata.Complexity = $complexity
        $task.InferredMetadata.ComplexityScores = @{
            High = $highComplexityScore
            Medium = $mediumComplexityScore
            Low = $lowComplexityScore
        }
    }
    
    return $Tasks
}

# Fonction pour inférer la catégorie des tâches
function Get-TaskCategory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks
    )
    
    Write-Log "Inférence de la catégorie des tâches..." -Level "Debug"
    
    # Définir les catégories et leurs mots-clés associés
    $categories = @{
        "Development" = @(
            "develop", "code", "implement", "programming", "function", "method", "class", "module",
            "library", "api", "interface", "component", "service", "feature", "algorithm"
        )
        "Design" = @(
            "design", "ui", "ux", "user interface", "user experience", "layout", "wireframe", "prototype",
            "mockup", "sketch", "visual", "graphic", "style", "theme", "color", "typography"
        )
        "Testing" = @(
            "test", "qa", "quality assurance", "unit test", "integration test", "e2e", "end-to-end",
            "validation", "verification", "assert", "check", "review", "inspect", "evaluate"
        )
        "Documentation" = @(
            "document", "doc", "readme", "manual", "guide", "tutorial", "instruction", "specification",
            "requirement", "description", "explanation", "comment", "annotation", "note"
        )
        "Infrastructure" = @(
            "infrastructure", "devops", "ci", "cd", "continuous integration", "continuous deployment",
            "pipeline", "build", "deploy", "server", "cloud", "container", "docker", "kubernetes"
        )
        "Security" = @(
            "security", "secure", "authentication", "authorization", "permission", "access control",
            "encryption", "decrypt", "hash", "salt", "token", "certificate", "vulnerability", "threat"
        )
        "Performance" = @(
            "performance", "optimize", "optimization", "speed", "fast", "efficient", "benchmark",
            "profiling", "memory", "cpu", "resource", "cache", "latency", "throughput", "scalability"
        )
        "Maintenance" = @(
            "maintenance", "maintain", "update", "upgrade", "fix", "repair", "refactor", "clean",
            "improve", "enhance", "revise", "revisit", "review", "monitor", "support"
        )
        "Planning" = @(
            "plan", "planning", "roadmap", "strategy", "schedule", "timeline", "milestone", "goal",
            "objective", "target", "vision", "mission", "scope", "requirement", "specification"
        )
    }
    
    foreach ($taskId in $Tasks.Keys) {
        $task = $Tasks[$taskId]
        $title = $task.Title.ToLower()
        
        # Calculer les scores pour chaque catégorie
        $categoryScores = @{}
        
        foreach ($category in $categories.Keys) {
            $keywords = $categories[$category]
            $score = 0
            
            foreach ($keyword in $keywords) {
                if ($title -match $keyword) {
                    $score++
                }
            }
            
            $categoryScores[$category] = $score
        }
        
        # Déterminer la catégorie avec le score le plus élevé
        $topCategory = ($categoryScores.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1).Key
        $topScore = $categoryScores[$topCategory]
        
        # Si aucune catégorie n'a de score, utiliser une heuristique basée sur l'ID
        if ($topScore -eq 0) {
            $parts = $taskId -split '\.'
            $firstPart = [int]$parts[0]
            
            # Attribuer une catégorie en fonction du premier chiffre de l'ID
            $topCategory = switch ($firstPart) {
                { $_ -le 2 } { "Planning" }
                { $_ -le 4 } { "Design" }
                { $_ -le 6 } { "Development" }
                { $_ -le 8 } { "Testing" }
                default { "Maintenance" }
            }
        }
        
        # Enregistrer la catégorie inférée
        $task.InferredMetadata.Category = $topCategory
        $task.InferredMetadata.CategoryScores = $categoryScores
    }
    
    return $Tasks
}

# Fonction pour inférer les dépendances entre les tâches
function Get-TaskDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks
    )
    
    Write-Log "Inférence des dépendances entre les tâches..." -Level "Debug"
    
    # Créer une structure hiérarchique des tâches
    $taskHierarchy = @{}
    
    foreach ($taskId in $Tasks.Keys) {
        $parts = $taskId -split '\.'
        
        # Construire les IDs des parents potentiels
        $parentIds = @()
        
        for ($i = 1; $i -lt $parts.Count; $i++) {
            $parentId = [string]::Join(".", $parts[0..($parts.Count - $i - 1)])
            if (-not [string]::IsNullOrEmpty($parentId)) {
                $parentIds += $parentId
            }
        }
        
        # Enregistrer la hiérarchie
        $taskHierarchy[$taskId] = @{
            ParentIds = $parentIds
            ChildrenIds = @()
        }
    }
    
    # Compléter la hiérarchie avec les enfants
    foreach ($taskId in $taskHierarchy.Keys) {
        foreach ($parentId in $taskHierarchy[$taskId].ParentIds) {
            if ($taskHierarchy.ContainsKey($parentId)) {
                $taskHierarchy[$parentId].ChildrenIds += $taskId
            }
        }
    }
    
    # Inférer les dépendances
    foreach ($taskId in $Tasks.Keys) {
        $task = $Tasks[$taskId]
        $dependencies = @()
        
        # Dépendance 1: Les tâches dépendent de leurs parents directs
        if ($taskHierarchy[$taskId].ParentIds.Count -gt 0) {
            $directParent = $taskHierarchy[$taskId].ParentIds[0]
            if ($Tasks.ContainsKey($directParent)) {
                $dependencies += $directParent
            }
        }
        
        # Dépendance 2: Les tâches dépendent des tâches précédentes au même niveau
        $parts = $taskId -split '\.'
        if ($parts.Count -gt 0) {
            $lastPart = [int]$parts[-1]
            
            if ($lastPart -gt 1) {
                $previousParts = $parts.Clone()
                $previousParts[-1] = ($lastPart - 1).ToString()
                $previousTaskId = [string]::Join(".", $previousParts)
                
                if ($Tasks.ContainsKey($previousTaskId)) {
                    $dependencies += $previousTaskId
                }
            }
        }
        
        # Dépendance 3: Inférer les dépendances basées sur le contenu
        $title = $task.Title.ToLower()
        
        # Rechercher des références explicites à d'autres tâches
        foreach ($otherTaskId in $Tasks.Keys) {
            if ($otherTaskId -eq $taskId) { continue }
            
            if ($title -match $otherTaskId) {
                $dependencies += $otherTaskId
            }
        }
        
        # Rechercher des mots-clés indiquant des dépendances
        $dependencyKeywords = @(
            "after", "following", "once", "when", "depends", "dependent", "prerequisite",
            "requires", "required", "needed", "necessary", "contingent"
        )
        
        foreach ($keyword in $dependencyKeywords) {
            if ($title -match "$keyword\s+(.{1,30})") {
                $context = $matches[1]
                
                # Chercher des tâches dont le titre correspond au contexte
                foreach ($otherTaskId in $Tasks.Keys) {
                    if ($otherTaskId -eq $taskId) { continue }
                    
                    $otherTitle = $Tasks[$otherTaskId].Title.ToLower()
                    
                    # Calculer la similarité entre le contexte et le titre de l'autre tâche
                    $similarity = 0
                    $contextWords = $context -split '\W+'
                    $otherTitleWords = $otherTitle -split '\W+'
                    
                    foreach ($word in $contextWords) {
                        if ($word.Length -lt 3) { continue }
                        
                        if ($otherTitleWords -contains $word) {
                            $similarity++
                        }
                    }
                    
                    if ($similarity -ge 2) {  # Au moins 2 mots en commun
                        $dependencies += $otherTaskId
                    }
                }
            }
        }
        
        # Supprimer les doublons et enregistrer les dépendances inférées
        $uniqueDependencies = $dependencies | Select-Object -Unique
        $task.InferredMetadata.Dependencies = $uniqueDependencies
    }
    
    return $Tasks
}

# Fonction pour générer la sortie au format demandé
function Format-InferredMetadataOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Tasks,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "Markdown", "CSV")]
        [string]$Format = "JSON"
    )
    
    Write-Log "Génération de la sortie au format $Format..." -Level "Debug"
    
    switch ($Format) {
        "JSON" {
            return $Tasks | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $markdown = "# Métadonnées inférées des tâches`n`n"
            
            # Statistiques générales
            $markdown += "## Statistiques`n`n"
            $markdown += "- Tâches totales : $($Tasks.Count)`n"
            $markdown += "- Tâches avec priorité inférée : $($Tasks.Values | Where-Object { $_.InferredMetadata.ContainsKey('Priority') } | Measure-Object).Count`n"
            $markdown += "- Tâches avec complexité inférée : $($Tasks.Values | Where-Object { $_.InferredMetadata.ContainsKey('Complexity') } | Measure-Object).Count`n"
            $markdown += "- Tâches avec catégorie inférée : $($Tasks.Values | Where-Object { $_.InferredMetadata.ContainsKey('Category') } | Measure-Object).Count`n"
            $markdown += "- Tâches avec dépendances inférées : $($Tasks.Values | Where-Object { $_.InferredMetadata.ContainsKey('Dependencies') -and $_.InferredMetadata.Dependencies.Count -gt 0 } | Measure-Object).Count`n`n"
            
            # Tâches avec métadonnées inférées
            $markdown += "## Tâches avec métadonnées inférées`n`n"
            
            foreach ($taskId in $Tasks.Keys | Sort-Object) {
                $task = $Tasks[$taskId]
                
                $markdown += "### $taskId : $($task.Title)`n`n"
                $markdown += "- Statut : $($task.Status)`n"
                $markdown += "- Ligne : $($task.LineNumber)`n"
                
                if ($task.InferredMetadata.ContainsKey('Priority')) {
                    $markdown += "- Priorité inférée : $($task.InferredMetadata.Priority)`n"
                }
                
                if ($task.InferredMetadata.ContainsKey('Complexity')) {
                    $markdown += "- Complexité inférée : $($task.InferredMetadata.Complexity)`n"
                }
                
                if ($task.InferredMetadata.ContainsKey('Category')) {
                    $markdown += "- Catégorie inférée : $($task.InferredMetadata.Category)`n"
                }
                
                if ($task.InferredMetadata.ContainsKey('Dependencies') -and $task.InferredMetadata.Dependencies.Count -gt 0) {
                    $markdown += "- Dépendances inférées : $($task.InferredMetadata.Dependencies -join ", ")`n"
                }
                
                $markdown += "`n"
            }
            
            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,Priority,Complexity,Category,Dependencies`n"
            
            foreach ($taskId in $Tasks.Keys | Sort-Object) {
                $task = $Tasks[$taskId]
                
                $priority = if ($task.InferredMetadata.ContainsKey('Priority')) { $task.InferredMetadata.Priority } else { "" }
                $complexity = if ($task.InferredMetadata.ContainsKey('Complexity')) { $task.InferredMetadata.Complexity } else { "" }
                $category = if ($task.InferredMetadata.ContainsKey('Category')) { $task.InferredMetadata.Category } else { "" }
                $dependencies = if ($task.InferredMetadata.ContainsKey('Dependencies') -and $task.InferredMetadata.Dependencies.Count -gt 0) {
                    $task.InferredMetadata.Dependencies -join ";"
                } else { "" }
                
                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'
                
                $csv += "$taskId,`"$escapedTitle`",$($task.Status),$priority,$complexity,$category,`"$dependencies`"`n"
            }
            
            return $csv
        }
    }
}

# Fonction principale
function Get-TaskMetadata {
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Content,
        [switch]$InferPriority,
        [switch]$InferComplexity,
        [switch]$InferCategory,
        [switch]$InferDependencies,
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
    
    # Extraire les tâches
    $tasks = Get-TasksFromContent -Content $Content
    
    Write-Log "Extraction des tâches terminée : $($tasks.Count) tâches trouvées." -Level "Info"
    
    # Inférer les métadonnées demandées
    if ($InferPriority) {
        $tasks = Get-TaskPriority -Tasks $tasks
        Write-Log "Inférence de la priorité terminée." -Level "Info"
    }
    
    if ($InferComplexity) {
        $tasks = Get-TaskComplexity -Tasks $tasks
        Write-Log "Inférence de la complexité terminée." -Level "Info"
    }
    
    if ($InferCategory) {
        $tasks = Get-TaskCategory -Tasks $tasks
        Write-Log "Inférence de la catégorie terminée." -Level "Info"
    }
    
    if ($InferDependencies) {
        $tasks = Get-TaskDependencies -Tasks $tasks
        Write-Log "Inférence des dépendances terminée." -Level "Info"
    }
    
    # Générer la sortie au format demandé
    $output = Format-InferredMetadataOutput -Tasks $tasks -Format $OutputFormat
    
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
        Tasks = $tasks
        Output = $output
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Get-TaskMetadata -FilePath $FilePath -Content $Content -InferPriority:$InferPriority -InferComplexity:$InferComplexity -InferCategory:$InferCategory -InferDependencies:$InferDependencies -OutputPath $OutputPath -OutputFormat $OutputFormat
}

