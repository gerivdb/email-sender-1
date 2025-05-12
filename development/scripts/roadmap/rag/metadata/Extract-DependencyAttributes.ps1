# Extract-DependencyAttributes.ps1
# Script pour extraire les attributs de dépendances et relations des tâches dans les fichiers markdown de roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$Content,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath,

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "CSV")]
    [string]$OutputFormat = "JSON"
)

# Script pour extraire les attributs de dépendances et relations des tâches dans les fichiers markdown de roadmap

# Fonction pour extraire les références directes entre tâches
function Get-DirectReferences {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    Write-Host "Extraction des références directes entre tâches..." -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $tasks = @{}
    $references = @{}

    # Patterns pour détecter les tâches et les références
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    $referencePattern = '\b([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)\b'

    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }

            $tasks[$taskId] = @{
                Id         = $taskId
                Title      = $taskTitle
                Status     = $taskStatus
                LineNumber = $lineNumber
                References = @()
            }
        }
    }

    # Deuxième passe : identifier les références entre tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]

            # Chercher les références à d'autres tâches dans le titre
            $potentialReferences = [regex]::Matches($taskTitle, $referencePattern) | ForEach-Object { $_.Groups[1].Value }

            foreach ($ref in $potentialReferences) {
                # Vérifier si la référence correspond à une tâche existante
                if ($tasks.ContainsKey($ref) -and $ref -ne $taskId) {
                    $tasks[$taskId].References += $ref

                    if (-not $references.ContainsKey($taskId)) {
                        $references[$taskId] = @()
                    }

                    if (-not $references[$taskId].Contains($ref)) {
                        $references[$taskId] += $ref
                    }
                }
            }
        }
    }

    return @{
        Tasks      = $tasks
        References = $references
    }
}

# Fonction pour extraire les dépendances de type "bloqué par"
function Get-BlockedByDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    Write-Host "Extraction des dépendances de type 'bloqué par'..." -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $tasks = @{}
    $blockedByDependencies = @{}

    # Patterns pour détecter les tâches et les dépendances
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    $blockedByPatterns = @(
        '(?:bloqué par|blocked by):\s*([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)',
        '#blockedBy:([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)',
        '#blocked_by:([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)'
    )

    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }

            $tasks[$taskId] = @{
                Id         = $taskId
                Title      = $taskTitle
                Status     = $taskStatus
                LineNumber = $lineNumber
                BlockedBy  = @()
            }
        }
    }

    # Deuxième passe : identifier les dépendances "bloqué par"
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match $taskPattern) {
            $taskId = $matches[2]

            foreach ($pattern in $blockedByPatterns) {
                if ($line -match $pattern) {
                    $blockedByIds = $matches[1] -split '\s*,\s*'

                    foreach ($blockedById in $blockedByIds) {
                        # Vérifier si la référence correspond à une tâche existante
                        if ($tasks.ContainsKey($blockedById) -and $blockedById -ne $taskId) {
                            $tasks[$taskId].BlockedBy += $blockedById

                            if (-not $blockedByDependencies.ContainsKey($taskId)) {
                                $blockedByDependencies[$taskId] = @()
                            }

                            if (-not $blockedByDependencies[$taskId].Contains($blockedById)) {
                                $blockedByDependencies[$taskId] += $blockedById
                            }
                        }
                    }
                }
            }
        }
    }

    return @{
        Tasks                 = $tasks
        BlockedByDependencies = $blockedByDependencies
    }
}

# Fonction pour extraire les dépendances de type "dépend de"
function Get-DependsOnDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    Write-Host "Extraction des dépendances de type 'dépend de'..." -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $tasks = @{}
    $dependsOnDependencies = @{}

    # Patterns pour détecter les tâches et les dépendances
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    $dependsOnPatterns = @(
        '(?:dépend de|depends on):\s*([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)',
        '#dependsOn:([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)',
        '#depends_on:([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)'
    )

    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }

            $tasks[$taskId] = @{
                Id         = $taskId
                Title      = $taskTitle
                Status     = $taskStatus
                LineNumber = $lineNumber
                DependsOn  = @()
            }
        }
    }

    # Deuxième passe : identifier les dépendances "dépend de"
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match $taskPattern) {
            $taskId = $matches[2]

            foreach ($pattern in $dependsOnPatterns) {
                if ($line -match $pattern) {
                    $dependsOnIds = $matches[1] -split '\s*,\s*'

                    foreach ($dependsOnId in $dependsOnIds) {
                        # Vérifier si la référence correspond à une tâche existante
                        if ($tasks.ContainsKey($dependsOnId) -and $dependsOnId -ne $taskId) {
                            $tasks[$taskId].DependsOn += $dependsOnId

                            if (-not $dependsOnDependencies.ContainsKey($taskId)) {
                                $dependsOnDependencies[$taskId] = @()
                            }

                            if (-not $dependsOnDependencies[$taskId].Contains($dependsOnId)) {
                                $dependsOnDependencies[$taskId] += $dependsOnId
                            }
                        }
                    }
                }
            }
        }
    }

    return @{
        Tasks                 = $tasks
        DependsOnDependencies = $dependsOnDependencies
    }
}

# Fonction pour extraire les dépendances de type "requis pour"
function Get-RequiredForDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    Write-Host "Extraction des dépendances de type 'requis pour'..." -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $tasks = @{}
    $requiredForDependencies = @{}

    # Patterns pour détecter les tâches et les dépendances
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    $requiredForPatterns = @(
        '(?:requis pour|required for):\s*([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)',
        '#requiredFor:([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)',
        '#required_for:([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)'
    )

    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }

            $tasks[$taskId] = @{
                Id          = $taskId
                Title       = $taskTitle
                Status      = $taskStatus
                LineNumber  = $lineNumber
                RequiredFor = @()
            }
        }
    }

    # Deuxième passe : identifier les dépendances "requis pour"
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match $taskPattern) {
            $taskId = $matches[2]

            foreach ($pattern in $requiredForPatterns) {
                if ($line -match $pattern) {
                    $requiredForIds = $matches[1] -split '\s*,\s*'

                    foreach ($requiredForId in $requiredForIds) {
                        # Vérifier si la référence correspond à une tâche existante
                        if ($tasks.ContainsKey($requiredForId) -and $requiredForId -ne $taskId) {
                            $tasks[$taskId].RequiredFor += $requiredForId

                            if (-not $requiredForDependencies.ContainsKey($taskId)) {
                                $requiredForDependencies[$taskId] = @()
                            }

                            if (-not $requiredForDependencies[$taskId].Contains($requiredForId)) {
                                $requiredForDependencies[$taskId] += $requiredForId
                            }
                        }
                    }
                }
            }
        }
    }

    return @{
        Tasks                   = $tasks
        RequiredForDependencies = $requiredForDependencies
    }
}

# Fonction pour analyser les tags de dépendance personnalisés
function Get-CustomDependencyTags {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    Write-Host "Analyse des tags de dépendance personnalisés..." -ForegroundColor Cyan

    # Diviser le contenu en lignes
    $lines = $Content -split "`r?`n"

    # Initialiser les variables d'analyse
    $tasks = @{}
    $customDependencies = @{}

    # Patterns pour détecter les tâches et les tags personnalisés
    $taskPattern = '^\s*[-*+]\s*\[([ xX])\]\s*(?:\*\*)?([A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)(?:\*\*)?\s(.*)'
    $customTagPattern = '#([a-zA-Z][a-zA-Z0-9_]*):((?:[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*(?:\s*,\s*[A-Za-z0-9]+(?:\.[A-Za-z0-9]+)*)*)|(?:[^#\s]+))'

    # Première passe : identifier toutes les tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match $taskPattern) {
            $taskId = $matches[2]
            $taskTitle = $matches[3]
            $taskStatus = if ($matches[1] -match '[xX]') { "Completed" } else { "Pending" }

            $tasks[$taskId] = @{
                Id         = $taskId
                Title      = $taskTitle
                Status     = $taskStatus
                LineNumber = $lineNumber
                CustomTags = @{}
            }
        }
    }

    # Deuxième passe : identifier les tags personnalisés
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        if ($line -match $taskPattern) {
            $taskId = $matches[2]

            $customTags = [regex]::Matches($line, $customTagPattern)

            foreach ($tag in $customTags) {
                $tagName = $tag.Groups[1].Value
                $tagValue = $tag.Groups[2].Value

                # Ignorer les tags déjà traités par d'autres fonctions
                $ignoredTags = @("blockedBy", "blocked_by", "dependsOn", "depends_on", "requiredFor", "required_for")

                if (-not $ignoredTags.Contains($tagName)) {
                    # Vérifier si la valeur contient des références à des tâches
                    $potentialTaskIds = $tagValue -split '\s*,\s*'
                    $validTaskIds = @()

                    foreach ($potentialId in $potentialTaskIds) {
                        if ($tasks.ContainsKey($potentialId) -and $potentialId -ne $taskId) {
                            $validTaskIds += $potentialId
                        }
                    }

                    if ($validTaskIds.Count -gt 0) {
                        $tasks[$taskId].CustomTags[$tagName] = $validTaskIds

                        if (-not $customDependencies.ContainsKey($taskId)) {
                            $customDependencies[$taskId] = @{}
                        }

                        $customDependencies[$taskId][$tagName] = $validTaskIds
                    }
                }
            }
        }
    }

    return @{
        Tasks              = $tasks
        CustomDependencies = $customDependencies
    }
}

# Fonction principale pour extraire les attributs de dépendances
function Get-DependencyAttributes {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$Content,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "Markdown", "CSV")]
        [string]$OutputFormat = "JSON"
    )

    # Vérifier les paramètres
    if ([string]::IsNullOrEmpty($Content) -and [string]::IsNullOrEmpty($FilePath)) {
        Write-Host "Vous devez spécifier soit un chemin de fichier, soit un contenu à analyser." -ForegroundColor Red
        return $null
    }

    # Vérifier si le contenu est vide après avoir été passé
    if (-not [string]::IsNullOrEmpty($Content) -and $Content.Trim().Length -eq 0) {
        Write-Host "Le contenu fourni est vide." -ForegroundColor Red
        return $null
    }

    # Afficher des informations de débogage sur le contenu
    Write-Host "Longueur du contenu: $($Content.Length) caractères" -ForegroundColor Cyan
    Write-Host "Début du contenu: $($Content.Substring(0, [Math]::Min(50, $Content.Length)))" -ForegroundColor Cyan

    # Charger le contenu si un chemin de fichier est spécifié
    if (-not [string]::IsNullOrEmpty($FilePath)) {
        if (-not (Test-Path -Path $FilePath)) {
            Write-Host "Le fichier spécifié n'existe pas: $FilePath" -ForegroundColor Red
            return $null
        }

        $Content = Get-Content -Path $FilePath -Raw
    }

    # Extraire les différents types de dépendances
    $directReferences = Get-DirectReferences -Content $Content
    $blockedByDependencies = Get-BlockedByDependencies -Content $Content
    $dependsOnDependencies = Get-DependsOnDependencies -Content $Content
    $requiredForDependencies = Get-RequiredForDependencies -Content $Content
    $customDependencyTags = Get-CustomDependencyTags -Content $Content

    # Combiner les résultats
    $analysis = @{
        DirectReferences        = $directReferences.References
        BlockedByDependencies   = $blockedByDependencies.BlockedByDependencies
        DependsOnDependencies   = $dependsOnDependencies.DependsOnDependencies
        RequiredForDependencies = $requiredForDependencies.RequiredForDependencies
        CustomDependencyTags    = $customDependencyTags.CustomDependencies
        Tasks                   = @{}
        Stats                   = @{
            TotalTasks                       = 0
            TasksWithDirectReferences        = 0
            TasksWithBlockedByDependencies   = 0
            TasksWithDependsOnDependencies   = 0
            TasksWithRequiredForDependencies = 0
            TasksWithCustomDependencyTags    = 0
            UniqueCustomTags                 = @()
        }
    }

    # Fusionner les informations des tâches
    $allTaskIds = @($directReferences.Tasks.Keys) + @($blockedByDependencies.Tasks.Keys) +
    @($dependsOnDependencies.Tasks.Keys) + @($requiredForDependencies.Tasks.Keys) +
    @($customDependencyTags.Tasks.Keys) | Select-Object -Unique

    foreach ($taskId in $allTaskIds) {
        $task = @{
            Id           = $taskId
            Title        = ""
            Status       = ""
            LineNumber   = 0
            Dependencies = @{
                DirectReferences = @()
                BlockedBy        = @()
                DependsOn        = @()
                RequiredFor      = @()
                CustomTags       = @{}
            }
        }

        if ($directReferences.Tasks.ContainsKey($taskId)) {
            $task.Title = $directReferences.Tasks[$taskId].Title
            $task.Status = $directReferences.Tasks[$taskId].Status
            $task.LineNumber = $directReferences.Tasks[$taskId].LineNumber
            $task.Dependencies.DirectReferences = $directReferences.Tasks[$taskId].References
        }

        if ($blockedByDependencies.Tasks.ContainsKey($taskId)) {
            if ([string]::IsNullOrEmpty($task.Title)) {
                $task.Title = $blockedByDependencies.Tasks[$taskId].Title
                $task.Status = $blockedByDependencies.Tasks[$taskId].Status
                $task.LineNumber = $blockedByDependencies.Tasks[$taskId].LineNumber
            }

            $task.Dependencies.BlockedBy = $blockedByDependencies.Tasks[$taskId].BlockedBy
        }

        if ($dependsOnDependencies.Tasks.ContainsKey($taskId)) {
            if ([string]::IsNullOrEmpty($task.Title)) {
                $task.Title = $dependsOnDependencies.Tasks[$taskId].Title
                $task.Status = $dependsOnDependencies.Tasks[$taskId].Status
                $task.LineNumber = $dependsOnDependencies.Tasks[$taskId].LineNumber
            }

            $task.Dependencies.DependsOn = $dependsOnDependencies.Tasks[$taskId].DependsOn
        }

        if ($requiredForDependencies.Tasks.ContainsKey($taskId)) {
            if ([string]::IsNullOrEmpty($task.Title)) {
                $task.Title = $requiredForDependencies.Tasks[$taskId].Title
                $task.Status = $requiredForDependencies.Tasks[$taskId].Status
                $task.LineNumber = $requiredForDependencies.Tasks[$taskId].LineNumber
            }

            $task.Dependencies.RequiredFor = $requiredForDependencies.Tasks[$taskId].RequiredFor
        }

        if ($customDependencyTags.Tasks.ContainsKey($taskId)) {
            if ([string]::IsNullOrEmpty($task.Title)) {
                $task.Title = $customDependencyTags.Tasks[$taskId].Title
                $task.Status = $customDependencyTags.Tasks[$taskId].Status
                $task.LineNumber = $customDependencyTags.Tasks[$taskId].LineNumber
            }

            $task.Dependencies.CustomTags = $customDependencyTags.Tasks[$taskId].CustomTags
        }

        $analysis.Tasks[$taskId] = $task
    }

    # Calculer les statistiques
    $analysis.Stats.TotalTasks = $allTaskIds.Count
    $analysis.Stats.TasksWithDirectReferences = ($analysis.Tasks.Values | Where-Object { $_.Dependencies.DirectReferences.Count -gt 0 }).Count
    $analysis.Stats.TasksWithBlockedByDependencies = ($analysis.Tasks.Values | Where-Object { $_.Dependencies.BlockedBy.Count -gt 0 }).Count
    $analysis.Stats.TasksWithDependsOnDependencies = ($analysis.Tasks.Values | Where-Object { $_.Dependencies.DependsOn.Count -gt 0 }).Count
    $analysis.Stats.TasksWithRequiredForDependencies = ($analysis.Tasks.Values | Where-Object { $_.Dependencies.RequiredFor.Count -gt 0 }).Count
    $analysis.Stats.TasksWithCustomDependencyTags = ($analysis.Tasks.Values | Where-Object { $_.Dependencies.CustomTags.Count -gt 0 }).Count

    # Collecter les tags personnalisés uniques
    $uniqueTags = @()
    foreach ($task in $analysis.Tasks.Values) {
        foreach ($tagName in $task.Dependencies.CustomTags.Keys) {
            if (-not $uniqueTags.Contains($tagName)) {
                $uniqueTags += $tagName
            }
        }
    }
    $analysis.Stats.UniqueCustomTags = $uniqueTags

    # Formater les résultats selon le format demandé
    $output = Format-DependencyAttributesOutput -Analysis $analysis -Format $OutputFormat

    # Enregistrer les résultats si un chemin de sortie est spécifié
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $outputDirectory = Split-Path -Path $OutputPath -Parent

        if (-not [string]::IsNullOrEmpty($outputDirectory) -and -not (Test-Path -Path $outputDirectory)) {
            New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
        }

        Set-Content -Path $OutputPath -Value $output
        Write-Host "Résultats enregistrés dans $OutputPath" -ForegroundColor Green
    }

    return $output
}

# Fonction pour formater les résultats
function Format-DependencyAttributesOutput {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Analysis,

        [Parameter(Mandatory = $true)]
        [ValidateSet("JSON", "Markdown", "CSV")]
        [string]$Format
    )

    Write-Host "Formatage des résultats en $Format..." -ForegroundColor Cyan

    switch ($Format) {
        "JSON" {
            return $Analysis | ConvertTo-Json -Depth 10
        }
        "Markdown" {
            $markdown = "# Analyse des attributs de dépendances et relations`n`n"

            $markdown += "## Statistiques`n`n"
            $markdown += "- Nombre total de tâches: $($Analysis.Stats.TotalTasks)`n"
            $markdown += "- Tâches avec références directes: $($Analysis.Stats.TasksWithDirectReferences)`n"
            $markdown += "- Tâches avec dépendances 'bloqué par': $($Analysis.Stats.TasksWithBlockedByDependencies)`n"
            $markdown += "- Tâches avec dépendances 'dépend de': $($Analysis.Stats.TasksWithDependsOnDependencies)`n"
            $markdown += "- Tâches avec dépendances 'requis pour': $($Analysis.Stats.TasksWithRequiredForDependencies)`n"
            $markdown += "- Tâches avec tags de dépendance personnalisés: $($Analysis.Stats.TasksWithCustomDependencyTags)`n`n"

            if ($Analysis.Stats.UniqueCustomTags.Count -gt 0) {
                $markdown += "## Tags personnalisés uniques`n`n"
                foreach ($tag in $Analysis.Stats.UniqueCustomTags | Sort-Object) {
                    $markdown += "- $tag`n"
                }
                $markdown += "`n"
            }

            $markdown += "## Tâches avec dépendances`n`n"

            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]
                $hasDependencies = $task.Dependencies.DirectReferences.Count -gt 0 -or
                $task.Dependencies.BlockedBy.Count -gt 0 -or
                $task.Dependencies.DependsOn.Count -gt 0 -or
                $task.Dependencies.RequiredFor.Count -gt 0 -or
                $task.Dependencies.CustomTags.Count -gt 0

                if ($hasDependencies) {
                    $markdown += "### $($task.Id): $($task.Title)`n`n"

                    if ($task.Dependencies.DirectReferences.Count -gt 0) {
                        $markdown += "- Références directes: $($task.Dependencies.DirectReferences -join ', ')`n"
                    }

                    if ($task.Dependencies.BlockedBy.Count -gt 0) {
                        $markdown += "- Bloqué par: $($task.Dependencies.BlockedBy -join ', ')`n"
                    }

                    if ($task.Dependencies.DependsOn.Count -gt 0) {
                        $markdown += "- Dépend de: $($task.Dependencies.DependsOn -join ', ')`n"
                    }

                    if ($task.Dependencies.RequiredFor.Count -gt 0) {
                        $markdown += "- Requis pour: $($task.Dependencies.RequiredFor -join ', ')`n"
                    }

                    if ($task.Dependencies.CustomTags.Count -gt 0) {
                        $markdown += "- Tags personnalisés:`n"
                        foreach ($tagName in $task.Dependencies.CustomTags.Keys | Sort-Object) {
                            $tagValues = $task.Dependencies.CustomTags[$tagName] -join ', '
                            $markdown += "  - ${tagName}: $tagValues`n"
                        }
                    }

                    $markdown += "`n"
                }
            }

            return $markdown
        }
        "CSV" {
            $csv = "TaskId,Title,Status,DirectReferences,BlockedBy,DependsOn,RequiredFor,CustomTags`n"

            foreach ($taskId in $Analysis.Tasks.Keys | Sort-Object) {
                $task = $Analysis.Tasks[$taskId]

                $directReferences = $task.Dependencies.DirectReferences -join ';'
                $blockedBy = $task.Dependencies.BlockedBy -join ';'
                $dependsOn = $task.Dependencies.DependsOn -join ';'
                $requiredFor = $task.Dependencies.RequiredFor -join ';'

                # Formater les tags personnalisés
                $customTags = ""
                if ($task.Dependencies.CustomTags.Count -gt 0) {
                    $tagPairs = @()
                    foreach ($tagName in $task.Dependencies.CustomTags.Keys | Sort-Object) {
                        $tagValues = $task.Dependencies.CustomTags[$tagName] -join ','
                        $tagPairs += "${tagName}:$tagValues"
                    }
                    $customTags = $tagPairs -join ';'
                }

                # Échapper les guillemets dans le titre
                $escapedTitle = $task.Title -replace '"', '""'

                $csv += "$taskId,`"$escapedTitle`",$($task.Status),`"$directReferences`",`"$blockedBy`",`"$dependsOn`",`"$requiredFor`",`"$customTags`"`n"
            }

            return $csv
        }
    }
}

# Exécuter la fonction principale avec les paramètres fournis
Get-DependencyAttributes -FilePath $FilePath -Content $Content -OutputPath $OutputPath -OutputFormat $OutputFormat
