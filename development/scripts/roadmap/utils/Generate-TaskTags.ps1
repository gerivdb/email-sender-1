# Generate-TaskTags.ps1
# Script pour générer des tags thématiques cohérents pour les tâches
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Génère des tags thématiques cohérents pour les tâches.

.DESCRIPTION
    Ce script fournit des fonctions pour générer des tags thématiques cohérents pour les tâches,
    en tenant compte du contenu des tâches, de la structure hiérarchique et des dépendances.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Fonction pour générer des tags thématiques pour une tâche
function Get-TaskThematicTags {
    <#
    .SYNOPSIS
        Génère des tags thématiques pour une tâche en fonction de son contenu.

    .DESCRIPTION
        Cette fonction génère des tags thématiques pour une tâche en fonction de son contenu,
        en utilisant des techniques d'analyse de texte et de correspondance de modèles.

    .PARAMETER Task
        La tâche pour laquelle générer des tags thématiques.

    .PARAMETER TitleField
        Le nom du champ contenant le titre de la tâche.
        Par défaut: "Title".

    .PARAMETER DescriptionField
        Le nom du champ contenant la description de la tâche.
        Par défaut: "Description".

    .PARAMETER CategoryField
        Le nom du champ contenant la catégorie de la tâche.
        Par défaut: "Category".

    .PARAMETER PredefinedTags
        Liste de tags prédéfinis à utiliser pour la correspondance.
        Si non spécifié, une liste par défaut sera utilisée.

    .PARAMETER MaxTags
        Nombre maximum de tags à générer.
        Par défaut: 5.

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des tags identiques à chaque exécution avec la même graine.

    .EXAMPLE
        Get-TaskThematicTags -Task $task
        Génère des tags thématiques pour la tâche spécifiée.

    .OUTPUTS
        System.String[]
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Task,

        [Parameter(Mandatory = $false)]
        [string]$TitleField = "Title",

        [Parameter(Mandatory = $false)]
        [string]$DescriptionField = "Description",

        [Parameter(Mandatory = $false)]
        [string]$CategoryField = "Category",

        [Parameter(Mandatory = $false)]
        [string[]]$PredefinedTags = @(
            # Tags techniques
            "développement", "test", "documentation", "déploiement", "conception", "architecture",
            "optimisation", "refactoring", "maintenance", "sécurité", "performance", "accessibilité",
            "internationalisation", "localisation", "monitoring", "logging", "debugging", "analyse",
            
            # Tags fonctionnels
            "interface", "backend", "frontend", "api", "base de données", "authentification",
            "autorisation", "notification", "rapport", "configuration", "intégration", "export",
            "import", "synchronisation", "validation", "workflow", "automatisation", "planification",
            
            # Tags de priorité
            "critique", "urgent", "important", "optionnel", "nice-to-have", "bloquant",
            
            # Tags de statut
            "en cours", "terminé", "en attente", "bloqué", "reporté", "annulé",
            
            # Tags spécifiques au projet
            "roadmap", "rag", "vectorisation", "indexation", "recherche", "extraction",
            "classification", "clustering", "embedding", "n8n", "powershell", "python",
            "javascript", "typescript", "html", "css", "sql", "nosql", "rest", "graphql",
            "websocket", "http", "smtp", "ftp", "ssh", "git", "github", "gitlab", "azure",
            "aws", "gcp", "docker", "kubernetes", "jenkins", "travis", "circleci", "sonarqube",
            "jira", "confluence", "slack", "teams", "discord", "email", "sms", "push",
            "mobile", "desktop", "web", "cloud", "on-premise", "hybrid", "microservice",
            "monolith", "serverless", "container", "vm", "iaas", "paas", "saas", "faas"
        ),

        [Parameter(Mandatory = $false)]
        [int]$MaxTags = 5,

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )

    # Initialiser le générateur de nombres aléatoires
    if ($null -ne $RandomSeed) {
        $random = New-Object System.Random($RandomSeed)
    }
    else {
        $random = New-Object System.Random
    }

    # Extraire le texte de la tâche
    $title = if ($Task.PSObject.Properties.Name.Contains($TitleField) -and $Task.$TitleField) {
        $Task.$TitleField
    }
    else {
        ""
    }

    $description = if ($Task.PSObject.Properties.Name.Contains($DescriptionField) -and $Task.$DescriptionField) {
        $Task.$DescriptionField
    }
    else {
        ""
    }

    $category = if ($Task.PSObject.Properties.Name.Contains($CategoryField) -and $Task.$CategoryField) {
        $Task.$CategoryField
    }
    else {
        ""
    }

    # Combiner le texte pour l'analyse
    $text = "$title $description $category".ToLower()

    # Nettoyer le texte
    $text = $text -replace '[^\p{L}\p{N}\s]', ' '  # Remplacer les caractères non alphanumériques par des espaces
    $text = $text -replace '\s+', ' '              # Remplacer les espaces multiples par un seul espace
    $text = $text.Trim()                           # Supprimer les espaces au début et à la fin

    # Extraire les mots-clés du texte
    $words = $text -split '\s+'
    $wordCounts = @{}
    foreach ($word in $words) {
        if ($word.Length -ge 3) {  # Ignorer les mots trop courts
            if ($wordCounts.ContainsKey($word)) {
                $wordCounts[$word]++
            }
            else {
                $wordCounts[$word] = 1
            }
        }
    }

    # Trouver les tags correspondants
    $matchedTags = @{}
    foreach ($tag in $PredefinedTags) {
        $tagWords = $tag -split '\s+'
        $score = 0

        foreach ($tagWord in $tagWords) {
            if ($text -match $tagWord) {
                $score += 2  # Score plus élevé pour les correspondances exactes
            }
            elseif ($words -contains $tagWord) {
                $score += 1  # Score pour les correspondances de mots
            }
        }

        if ($score -gt 0) {
            $matchedTags[$tag] = $score
        }
    }

    # Ajouter des tags basés sur les mots-clés fréquents
    $topWords = $wordCounts.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10 -ExpandProperty Key
    foreach ($word in $topWords) {
        if ($word.Length -ge 5 -and -not $matchedTags.ContainsKey($word)) {  # Mots plus longs comme tags potentiels
            $matchedTags[$word] = $wordCounts[$word]
        }
    }

    # Sélectionner les meilleurs tags
    $selectedTags = $matchedTags.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First $MaxTags -ExpandProperty Key

    # Ajouter un élément aléatoire pour éviter la monotonie
    if ($selectedTags.Count -lt $MaxTags -and $PredefinedTags.Count -gt 0) {
        $remainingTags = $PredefinedTags | Where-Object { $selectedTags -notcontains $_ }
        $randomTagCount = [Math]::Min($MaxTags - $selectedTags.Count, 2)  # Ajouter au maximum 2 tags aléatoires

        for ($i = 0; $i -lt $randomTagCount; $i++) {
            if ($remainingTags.Count -gt 0) {
                $randomIndex = $random.Next(0, $remainingTags.Count)
                $randomTag = $remainingTags[$randomIndex]
                $selectedTags += $randomTag
                $remainingTags = $remainingTags | Where-Object { $_ -ne $randomTag }
            }
        }
    }

    return $selectedTags
}

# Fonction pour attribuer des tags thématiques à une hiérarchie de tâches
function New-TaskTagAssignment {
    <#
    .SYNOPSIS
        Attribue des tags thématiques à une hiérarchie de tâches.

    .DESCRIPTION
        Cette fonction attribue des tags thématiques à une hiérarchie de tâches,
        en tenant compte du contenu des tâches, de la structure hiérarchique et des dépendances.

    .PARAMETER Tasks
        Les tâches auxquelles attribuer des tags thématiques.

    .PARAMETER TagsField
        Le nom du champ dans lequel stocker les tags dans les tâches.
        Par défaut: "Tags".

    .PARAMETER TitleField
        Le nom du champ contenant le titre de la tâche.
        Par défaut: "Title".

    .PARAMETER DescriptionField
        Le nom du champ contenant la description de la tâche.
        Par défaut: "Description".

    .PARAMETER CategoryField
        Le nom du champ contenant la catégorie de la tâche.
        Par défaut: "Category".

    .PARAMETER ParentIdField
        Le nom du champ contenant l'ID du parent dans les tâches.
        Par défaut: "ParentId".

    .PARAMETER IdField
        Le nom du champ contenant l'ID de la tâche.
        Par défaut: "Id".

    .PARAMETER ChildrenField
        Le nom du champ contenant les IDs des enfants dans les tâches.
        Par défaut: "Children".

    .PARAMETER DependenciesField
        Le nom du champ contenant les IDs des dépendances dans les tâches.
        Par défaut: "Dependencies".

    .PARAMETER MaxTagsPerTask
        Nombre maximum de tags par tâche.
        Par défaut: 5.

    .PARAMETER RandomSeed
        Graine pour le générateur de nombres aléatoires. Si spécifiée, permet de générer
        des tags identiques à chaque exécution avec la même graine.

    .EXAMPLE
        New-TaskTagAssignment -Tasks $tasks
        Attribue des tags thématiques aux tâches spécifiées.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$TagsField = "Tags",

        [Parameter(Mandatory = $false)]
        [string]$TitleField = "Title",

        [Parameter(Mandatory = $false)]
        [string]$DescriptionField = "Description",

        [Parameter(Mandatory = $false)]
        [string]$CategoryField = "Category",

        [Parameter(Mandatory = $false)]
        [string]$ParentIdField = "ParentId",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id",

        [Parameter(Mandatory = $false)]
        [string]$ChildrenField = "Children",

        [Parameter(Mandatory = $false)]
        [string]$DependenciesField = "Dependencies",

        [Parameter(Mandatory = $false)]
        [int]$MaxTagsPerTask = 5,

        [Parameter(Mandatory = $false)]
        [int]$RandomSeed = $null
    )

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $tasksById[$id] = $task
    }

    # Fonction récursive pour attribuer des tags
    function Set-TagsRecursively {
        param (
            [PSObject]$Task,
            [string[]]$InheritedTags = @()
        )

        # Générer des tags thématiques pour la tâche
        $generatedTags = Get-TaskThematicTags -Task $Task -TitleField $TitleField -DescriptionField $DescriptionField -CategoryField $CategoryField -MaxTags $MaxTagsPerTask -RandomSeed ($RandomSeed + $Task.$IdField.GetHashCode())

        # Combiner les tags générés avec les tags hérités
        $allTags = $generatedTags + $InheritedTags | Select-Object -Unique

        # Limiter le nombre de tags
        if ($allTags.Count -gt $MaxTagsPerTask) {
            $allTags = $allTags | Select-Object -First $MaxTagsPerTask
        }

        # Assigner les tags à la tâche
        if (-not $Task.PSObject.Properties.Name.Contains($TagsField)) {
            Add-Member -InputObject $Task -MemberType NoteProperty -Name $TagsField -Value $allTags
        }
        else {
            $Task.$TagsField = $allTags
        }

        # Traiter les enfants
        $childrenIds = @()
        if ($Task.PSObject.Properties.Name.Contains($ChildrenField) -and $Task.$ChildrenField) {
            $childrenIds = $Task.$ChildrenField
        }

        foreach ($childId in $childrenIds) {
            if ($tasksById.ContainsKey($childId)) {
                $child = $tasksById[$childId]
                Set-TagsRecursively -Task $child -InheritedTags $allTags
            }
        }
    }

    # Trouver les tâches racines (sans parent)
    $rootTasks = $Tasks | Where-Object { -not $_.$ParentIdField }

    # Attribuer des tags pour chaque arbre
    foreach ($rootTask in $rootTasks) {
        Set-TagsRecursively -Task $rootTask
    }

    # Mettre à jour les tags en fonction des dépendances
    Update-TaskTagsHierarchy -Tasks $Tasks -TagsField $TagsField -IdField $IdField -DependenciesField $DependenciesField -MaxTagsPerTask $MaxTagsPerTask

    return $Tasks
}

# Fonction pour mettre à jour les tags pour maintenir la cohérence hiérarchique
function Update-TaskTagsHierarchy {
    <#
    .SYNOPSIS
        Met à jour les tags pour maintenir la cohérence hiérarchique.

    .DESCRIPTION
        Cette fonction met à jour les tags pour maintenir la cohérence hiérarchique,
        en tenant compte des dépendances entre les tâches.

    .PARAMETER Tasks
        Les tâches à mettre à jour.

    .PARAMETER TagsField
        Le nom du champ contenant les tags dans les tâches.
        Par défaut: "Tags".

    .PARAMETER IdField
        Le nom du champ contenant l'ID de la tâche.
        Par défaut: "Id".

    .PARAMETER DependenciesField
        Le nom du champ contenant les IDs des dépendances dans les tâches.
        Par défaut: "Dependencies".

    .PARAMETER MaxTagsPerTask
        Nombre maximum de tags par tâche.
        Par défaut: 5.

    .EXAMPLE
        Update-TaskTagsHierarchy -Tasks $tasks
        Met à jour les tags des tâches pour maintenir la cohérence hiérarchique.

    .OUTPUTS
        System.Management.Automation.PSObject[]
    #>
    [CmdletBinding()]
    [OutputType([PSObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Tasks,

        [Parameter(Mandatory = $false)]
        [string]$TagsField = "Tags",

        [Parameter(Mandatory = $false)]
        [string]$IdField = "Id",

        [Parameter(Mandatory = $false)]
        [string]$DependenciesField = "Dependencies",

        [Parameter(Mandatory = $false)]
        [int]$MaxTagsPerTask = 5
    )

    # Créer un dictionnaire pour accéder rapidement aux tâches par ID
    $tasksById = @{}
    foreach ($task in $Tasks) {
        $id = $task.$IdField
        $tasksById[$id] = $task
    }

    # Mettre à jour les tags en fonction des dépendances
    foreach ($task in $Tasks) {
        # Vérifier si la tâche a des dépendances
        if ($task.PSObject.Properties.Name.Contains($DependenciesField) -and $task.$DependenciesField -and $task.$DependenciesField.Count -gt 0) {
            $dependencies = $task.$DependenciesField
            $dependencyTags = @()

            # Collecter les tags des dépendances
            foreach ($depId in $dependencies) {
                if ($tasksById.ContainsKey($depId) -and $tasksById[$depId].PSObject.Properties.Name.Contains($TagsField)) {
                    $dependencyTags += $tasksById[$depId].$TagsField
                }
            }

            # Ajouter les tags des dépendances à la tâche
            if ($dependencyTags.Count -gt 0) {
                $currentTags = $task.$TagsField
                $allTags = $currentTags + $dependencyTags | Select-Object -Unique

                # Limiter le nombre de tags
                if ($allTags.Count -gt $MaxTagsPerTask) {
                    $allTags = $allTags | Select-Object -First $MaxTagsPerTask
                }

                $task.$TagsField = $allTags
            }
        }
    }

    # Calculer les statistiques des tags
    $tagStats = @{}
    foreach ($task in $Tasks) {
        if ($task.PSObject.Properties.Name.Contains($TagsField) -and $task.$TagsField) {
            foreach ($tag in $task.$TagsField) {
                if ($tagStats.ContainsKey($tag)) {
                    $tagStats[$tag]++
                }
                else {
                    $tagStats[$tag] = 1
                }
            }
        }
    }

    # Identifier les tags les plus courants
    $commonTags = $tagStats.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 10 -ExpandProperty Key

    # Ajouter des tags communs aux tâches qui ont peu de tags
    foreach ($task in $Tasks) {
        if ($task.PSObject.Properties.Name.Contains($TagsField)) {
            $currentTags = $task.$TagsField
            if ($currentTags.Count -lt 2) {
                $tagsToAdd = $commonTags | Where-Object { $currentTags -notcontains $_ } | Select-Object -First ($MaxTagsPerTask - $currentTags.Count)
                $task.$TagsField = $currentTags + $tagsToAdd
            }
        }
    }

    return $Tasks
}
