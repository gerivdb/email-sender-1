﻿# Generate-RandomTasks.ps1
# Script pour générer des tâches aléatoires pour les tests de performance
# Version: 1.0
# Date: 2025-05-15

# Fonction pour générer une tâche aléatoire
function New-RandomTask {
    <#
    .SYNOPSIS
        Génère une tâche aléatoire pour les tests.

    .DESCRIPTION
        Cette fonction génère une tâche aléatoire avec un ID, une description, un statut et d'autres propriétés.
        Elle peut être utilisée pour créer des jeux de données synthétiques pour les tests de performance.

    .PARAMETER Id
        L'identifiant de la tâche. Si non spécifié, un identifiant aléatoire sera généré.

    .PARAMETER ParentId
        L'identifiant du parent de la tâche. Si non spécifié, la tâche sera considérée comme une tâche de premier niveau.

    .PARAMETER IndentLevel
        Le niveau d'indentation de la tâche. Si non spécifié, il sera calculé en fonction du ParentId.

    .PARAMETER Status
        Le statut de la tâche. Les valeurs possibles sont "NotStarted", "InProgress", "Completed", "Blocked".
        Si non spécifié, un statut aléatoire sera attribué.

    .PARAMETER WithMetadata
        Indique si des métadonnées doivent être générées pour la tâche.

    .PARAMETER WithDependencies
        Indique si des dépendances doivent être générées pour la tâche.

    .PARAMETER ExistingTasks
        Liste des tâches existantes, utilisée pour générer des dépendances valides.

    .EXAMPLE
        New-RandomTask -Id "1.1" -ParentId "1" -IndentLevel 2 -Status "InProgress"
        Génère une tâche avec l'ID "1.1", le parent "1", le niveau d'indentation 2 et le statut "InProgress".

    .EXAMPLE
        New-RandomTask -WithMetadata -WithDependencies -ExistingTasks $tasks
        Génère une tâche aléatoire avec des métadonnées et des dépendances basées sur les tâches existantes.

    .OUTPUTS
        System.Management.Automation.PSObject
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [string]$ParentId,

        [Parameter(Mandatory = $false)]
        [int]$IndentLevel = 0,

        [Parameter(Mandatory = $false)]
        [ValidateSet("NotStarted", "InProgress", "Completed", "Blocked")]
        [string]$Status,

        [Parameter(Mandatory = $false)]
        [switch]$WithMetadata,

        [Parameter(Mandatory = $false)]
        [switch]$WithDependencies,

        [Parameter(Mandatory = $false)]
        [array]$ExistingTasks = @()
    )

    # Générer un ID aléatoire si non spécifié
    if (-not $Id) {
        if ($ParentId) {
            $Id = "$ParentId.$([Guid]::NewGuid().ToString().Substring(0, 4))"
        } else {
            $Id = [Guid]::NewGuid().ToString().Substring(0, 8)
        }
    }

    # Calculer le niveau d'indentation en fonction du ParentId si non spécifié
    if ($ParentId -and $IndentLevel -eq 0) {
        $parentTask = $ExistingTasks | Where-Object { $_.Id -eq $ParentId }
        if ($parentTask) {
            $IndentLevel = $parentTask.IndentLevel + 1
        } else {
            $IndentLevel = 1
        }
    }

    # Générer un statut aléatoire si non spécifié
    if (-not $Status) {
        $statuses = @("NotStarted", "InProgress", "Completed", "Blocked")
        $weights = @(40, 30, 25, 5) # Pondération pour rendre certains statuts plus probables

        $totalWeight = ($weights | Measure-Object -Sum).Sum
        $randomValue = Get-Random -Minimum 1 -Maximum $totalWeight

        $cumulativeWeight = 0
        for ($i = 0; $i -lt $statuses.Count; $i++) {
            $cumulativeWeight += $weights[$i]
            if ($randomValue -le $cumulativeWeight) {
                $Status = $statuses[$i]
                break
            }
        }
    }

    # Générer une description aléatoire
    $verbs = @("Implémenter", "Développer", "Créer", "Concevoir", "Optimiser", "Tester", "Documenter", "Analyser", "Refactoriser", "Intégrer")
    $adjectives = @("nouveau", "amélioré", "optimisé", "robuste", "flexible", "modulaire", "extensible", "performant", "sécurisé", "intuitif")
    $nouns = @("système", "module", "composant", "fonctionnalité", "interface", "service", "algorithme", "framework", "architecture", "processus")
    $domains = @("authentification", "autorisation", "logging", "caching", "reporting", "monitoring", "analytics", "notification", "synchronisation", "configuration")

    $verb = $verbs | Get-Random
    $adjective = $adjectives | Get-Random
    $noun = $nouns | Get-Random
    $domain = $domains | Get-Random

    $description = "$verb un $adjective $noun de $domain"

    # Générer des métadonnées aléatoires si demandé
    $metadata = @{}

    if ($WithMetadata) {
        # Dates de début et de fin
        $startDate = (Get-Date).AddDays(-1 * (Get-Random -Minimum 0 -Maximum 30))
        $endDate = $startDate.AddDays(Get-Random -Minimum 1 -Maximum 60)

        $metadata["StartDate"] = $startDate.ToString("yyyy-MM-dd")
        $metadata["EndDate"] = $endDate.ToString("yyyy-MM-dd")
        $metadata["Duration"] = [math]::Round(($endDate - $startDate).TotalDays, 0)

        # Priorité
        $priorities = @("Low", "Medium", "High", "Critical")
        $metadata["Priority"] = $priorities | Get-Random

        # Assigné à
        $assignees = @("Alice", "Bob", "Charlie", "Dave", "Eve", "Frank", "Grace", "Heidi", "Ivan", "Judy")
        $metadata["AssignedTo"] = $assignees | Get-Random

        # Tags
        $tags = @("Frontend", "Backend", "Database", "API", "UI", "UX", "Security", "Performance", "Documentation", "Testing")
        $tagCount = Get-Random -Minimum 1 -Maximum 4
        $metadata["Tags"] = $tags | Get-Random -Count $tagCount

        # Estimation
        $estimationUnits = @("hours", "days", "points")
        $metadata["EstimationUnit"] = $estimationUnits | Get-Random
        $metadata["Estimation"] = Get-Random -Minimum 1 -Maximum 40

        # URL
        $metadata["URL"] = "https://example.com/tasks/$Id"
    }

    # Générer des dépendances aléatoires si demandé
    $dependencies = @()

    if ($WithDependencies -and $ExistingTasks.Count -gt 0) {
        $potentialDependencies = $ExistingTasks | Where-Object { $_.Id -ne $Id -and $_.Id -ne $ParentId }

        if ($potentialDependencies.Count -gt 0) {
            $dependencyCount = Get-Random -Minimum 0 -Maximum ([Math]::Min(3, $potentialDependencies.Count))

            if ($dependencyCount -gt 0) {
                $dependencies = $potentialDependencies | Get-Random -Count $dependencyCount | ForEach-Object { $_.Id }
            }
        }
    }

    # Créer l'objet tâche
    $task = [PSCustomObject]@{
        Id           = $Id
        Description  = $description
        Status       = $Status
        ParentId     = $ParentId
        IndentLevel  = $IndentLevel
        Metadata     = $metadata
        Dependencies = $dependencies
        Children     = @()
        LineNumber   = 0
        Path         = ""
        Context      = ""
    }

    return $task
}

# Fonction pour générer un ensemble de tâches aléatoires
function New-RandomTaskSet {
    <#
    .SYNOPSIS
        Génère un ensemble de tâches aléatoires pour les tests.

    .DESCRIPTION
        Cette fonction génère un ensemble de tâches aléatoires avec une structure hiérarchique.
        Elle peut être utilisée pour créer des jeux de données synthétiques pour les tests de performance.

    .PARAMETER TaskCount
        Le nombre total de tâches à générer.

    .PARAMETER MaxDepth
        La profondeur maximale de la hiérarchie des tâches.

    .PARAMETER WithMetadata
        Indique si des métadonnées doivent être générées pour les tâches.

    .PARAMETER WithDependencies
        Indique si des dépendances doivent être générées pour les tâches.

    .PARAMETER DependencyDensity
        La densité des dépendances entre les tâches (0.0 à 1.0).

    .PARAMETER HierarchyType
        Le type de hiérarchie à générer. Les valeurs possibles sont "Balanced", "Flat", "Deep".

    .EXAMPLE
        New-RandomTaskSet -TaskCount 100 -MaxDepth 3 -WithMetadata -WithDependencies
        Génère un ensemble de 100 tâches avec une profondeur maximale de 3, des métadonnées et des dépendances.

    .OUTPUTS
        System.Array
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$TaskCount = 100,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 3,

        [Parameter(Mandatory = $false)]
        [switch]$WithMetadata,

        [Parameter(Mandatory = $false)]
        [switch]$WithDependencies,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0, 1.0)]
        [double]$DependencyDensity = 0.2,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Balanced", "Flat", "Deep")]
        [string]$HierarchyType = "Balanced"
    )

    $tasks = @()

    # Déterminer la distribution des tâches par niveau selon le type de hiérarchie
    $levelDistribution = @{}

    switch ($HierarchyType) {
        "Balanced" {
            # Distribution équilibrée entre les niveaux
            for ($level = 0; $level -le $MaxDepth; $level++) {
                $levelDistribution[$level] = [math]::Round($TaskCount / ($MaxDepth + 1))
            }
        }
        "Flat" {
            # La plupart des tâches au niveau 0 et 1
            $levelDistribution[0] = [math]::Round($TaskCount * 0.3)
            $levelDistribution[1] = [math]::Round($TaskCount * 0.6)

            for ($level = 2; $level -le $MaxDepth; $level++) {
                $levelDistribution[$level] = [math]::Round($TaskCount * 0.1 / ($MaxDepth - 1))
            }
        }
        "Deep" {
            # Distribution qui favorise les niveaux profonds
            $totalWeight = ($MaxDepth + 1) * ($MaxDepth + 2) / 2

            for ($level = 0; $level -le $MaxDepth; $level++) {
                $weight = $level + 1
                $levelDistribution[$level] = [math]::Round($TaskCount * $weight / $totalWeight)
            }
        }
    }

    # Ajuster la distribution pour s'assurer que le nombre total de tâches est correct
    $totalTasks = ($levelDistribution.Values | Measure-Object -Sum).Sum

    if ($totalTasks -ne $TaskCount) {
        $diff = $TaskCount - $totalTasks
        $levelDistribution[0] += $diff
    }

    # Générer les tâches de niveau 0 (racines)
    $rootCount = $levelDistribution[0]

    for ($i = 1; $i -le $rootCount; $i++) {
        $task = New-RandomTask -Id "$i" -IndentLevel 0 -WithMetadata:$WithMetadata
        $tasks += $task
    }

    # Générer les tâches pour les niveaux suivants
    for ($level = 1; $level -le $MaxDepth; $level++) {
        $levelTaskCount = $levelDistribution[$level]
        $potentialParents = $tasks | Where-Object { $_.IndentLevel -eq ($level - 1) }

        if ($potentialParents.Count -eq 0) {
            continue
        }

        $tasksPerParent = [math]::Ceiling($levelTaskCount / $potentialParents.Count)
        $taskIndex = 1

        foreach ($parent in $potentialParents) {
            for ($i = 1; $i -le $tasksPerParent -and $taskIndex -le $levelTaskCount; $i++) {
                $childId = "$($parent.Id).$i"
                $task = New-RandomTask -Id $childId -ParentId $parent.Id -IndentLevel $level -WithMetadata:$WithMetadata -ExistingTasks $tasks
                $tasks += $task
                $parent.Children += $childId
                $taskIndex++
            }
        }
    }

    # Ajouter des dépendances si demandé
    if ($WithDependencies) {
        $nonRootTasks = $tasks | Where-Object { $_.IndentLevel -gt 0 }
        $dependencyCount = [math]::Round($nonRootTasks.Count * $DependencyDensity)

        for ($i = 0; $i -lt $dependencyCount; $i++) {
            $task = $nonRootTasks | Get-Random
            $potentialDependencies = $tasks | Where-Object {
                $_.Id -ne $task.Id -and
                $_.ParentId -ne $task.Id -and
                $task.ParentId -ne $_.Id -and
                -not $_.Dependencies.Contains($task.Id)
            }

            if ($potentialDependencies.Count -gt 0) {
                $dependency = $potentialDependencies | Get-Random

                if (-not $task.Dependencies.Contains($dependency.Id)) {
                    $task.Dependencies += $dependency.Id
                }
            }
        }
    }

    # Ajouter des numéros de ligne et des chemins fictifs
    for ($i = 0; $i -lt $tasks.Count; $i++) {
        $tasks[$i].LineNumber = ($i + 1) * 3
        $tasks[$i].Path = "projet/roadmaps/synthetic/roadmap_$([Guid]::NewGuid().ToString().Substring(0, 8)).md"
        $tasks[$i].Context = "Section $([math]::Floor($i / 10) + 1)"
    }

    return $tasks
}

# Fonction pour convertir un ensemble de tâches en markdown
function ConvertTo-MarkdownRoadmap {
    <#
    .SYNOPSIS
        Convertit un ensemble de tâches en format markdown.

    .DESCRIPTION
        Cette fonction prend un ensemble de tâches et les convertit en un document markdown
        qui peut être utilisé pour les tests ou comme modèle de roadmap.

    .PARAMETER Tasks
        L'ensemble de tâches à convertir.

    .PARAMETER IncludeMetadata
        Indique si les métadonnées des tâches doivent être incluses dans le markdown.

    .PARAMETER IncludeDependencies
        Indique si les dépendances des tâches doivent être incluses dans le markdown.

    .PARAMETER Title
        Le titre du document markdown.

    .EXAMPLE
        $tasks = New-RandomTaskSet -TaskCount 100
        ConvertTo-MarkdownRoadmap -Tasks $tasks -Title "Roadmap de test"
        Convertit un ensemble de 100 tâches en un document markdown avec le titre "Roadmap de test".

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDependencies,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Roadmap générée automatiquement"
    )

    $markdown = @()
    $markdown += "# $Title"
    $markdown += "Date de génération: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $markdown += "Nombre de tâches: $($Tasks.Count)"
    $markdown += ""

    # Trier les tâches par ID pour assurer l'ordre hiérarchique
    $sortedTasks = $Tasks | Sort-Object -Property @{Expression = { $_.Id }; Ascending = $true }

    # Organiser les tâches par niveau d'indentation
    $tasksByLevel = @{}

    foreach ($task in $sortedTasks) {
        $level = $task.IndentLevel

        if (-not $tasksByLevel.ContainsKey($level)) {
            $tasksByLevel[$level] = @()
        }

        $tasksByLevel[$level] += $task
    }

    # Générer les sections pour chaque niveau
    $currentSection = ""
    $sectionCounter = 1

    foreach ($task in $sortedTasks) {
        # Déterminer si une nouvelle section doit être créée
        if ($task.IndentLevel -eq 0 -and $task.Context -ne $currentSection) {
            $currentSection = $task.Context
            $markdown += "## $currentSection"
            $markdown += ""
            $sectionCounter++
        }

        # Générer l'indentation
        $indent = "  " * $task.IndentLevel

        # Déterminer le statut
        $checkbox = switch ($task.Status) {
            "Completed" { "[x]" }
            default { "[ ]" }
        }

        # Générer la ligne de tâche
        $taskLine = "$indent- $checkbox **$($task.Id)** $($task.Description)"
        $markdown += $taskLine

        # Ajouter les métadonnées si demandé
        if ($IncludeMetadata -and $task.Metadata.Count -gt 0) {
            $markdown += "$indent  <details>"
            $markdown += "$indent    <summary>Métadonnées</summary>"
            $markdown += "$indent    "

            foreach ($key in $task.Metadata.Keys) {
                $value = $task.Metadata[$key]

                if ($value -is [array]) {
                    $value = $value -join ", "
                }

                $markdown += "$indent    - **$key**: $value"
            }

            $markdown += "$indent  </details>"
        }

        # Ajouter les dépendances si demandé
        if ($IncludeDependencies -and $task.Dependencies.Count -gt 0) {
            $dependenciesStr = $task.Dependencies -join ", "
            $markdown += "$indent  > Dépendances: $dependenciesStr"
        }
    }

    return $markdown -join "`n"
}

# Fonction pour sauvegarder un roadmap markdown dans un fichier
function Save-MarkdownRoadmap {
    <#
    .SYNOPSIS
        Sauvegarde un roadmap markdown dans un fichier.

    .DESCRIPTION
        Cette fonction prend un ensemble de tâches, les convertit en markdown et les sauvegarde dans un fichier.

    .PARAMETER Tasks
        L'ensemble de tâches à convertir et sauvegarder.

    .PARAMETER OutputPath
        Le chemin du fichier de sortie.

    .PARAMETER IncludeMetadata
        Indique si les métadonnées des tâches doivent être incluses dans le markdown.

    .PARAMETER IncludeDependencies
        Indique si les dépendances des tâches doivent être incluses dans le markdown.

    .PARAMETER Title
        Le titre du document markdown.

    .PARAMETER Force
        Indique si le fichier existant doit être écrasé.

    .EXAMPLE
        $tasks = New-RandomTaskSet -TaskCount 100
        Save-MarkdownRoadmap -Tasks $tasks -OutputPath "C:\Temp\roadmap.md" -Title "Roadmap de test"
        Convertit un ensemble de 100 tâches en un document markdown et le sauvegarde dans le fichier spécifié.

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDependencies,

        [Parameter(Mandatory = $false)]
        [string]$Title = "Roadmap générée automatiquement",

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Vérifier si le fichier existe déjà
    if (Test-Path -Path $OutputPath -PathType Leaf) {
        if (-not $Force) {
            Write-Error "Le fichier $OutputPath existe déjà. Utilisez -Force pour l'écraser."
            return $false
        }
    }

    # Créer le répertoire parent si nécessaire
    $parentDir = Split-Path -Path $OutputPath -Parent

    if (-not (Test-Path -Path $parentDir -PathType Container)) {
        New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
    }

    # Convertir les tâches en markdown
    $markdown = ConvertTo-MarkdownRoadmap -Tasks $Tasks -IncludeMetadata:$IncludeMetadata -IncludeDependencies:$IncludeDependencies -Title $Title

    # Sauvegarder le markdown dans un fichier
    $markdown | Out-File -FilePath $OutputPath -Encoding UTF8 -Force:$Force

    Write-Output "Roadmap sauvegardé dans $OutputPath"
    return $true
}

# Exporter les fonctions
Export-ModuleMember -Function New-RandomTask, New-RandomTaskSet, ConvertTo-MarkdownRoadmap, Save-MarkdownRoadmap
