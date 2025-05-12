# Analyze-RoadmapStructure.ps1
# Module pour analyser la structure des roadmaps existantes
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Analyse la structure des roadmaps existantes pour générer des statistiques et modèles.

.DESCRIPTION
    Ce module fournit des fonctions pour analyser les roadmaps existantes,
    extraire des statistiques structurelles, analyser les distributions de métadonnées
    et détecter des patterns récurrents. Ces données sont utilisées pour créer
    des modèles statistiques permettant de générer des roadmaps réalistes.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$parserPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"

if (Test-Path $parserPath) {
    . $parserPath
} else {
    Write-Error "Module Parse-Roadmap.ps1 introuvable à l'emplacement: $parserPath"
    exit
}

# Structure pour stocker les statistiques d'une roadmap
class RoadmapStatistics {
    [string]$RoadmapName
    [int]$TotalTasks
    [int]$CompletedTasks
    [int]$PendingTasks
    [int]$MaxDepth
    [hashtable]$TasksPerLevel = @{}
    [hashtable]$TasksPerStatus = @{}
    [hashtable]$TasksPerCategory = @{}
    [hashtable]$DependencyCounts = @{}
    [hashtable]$BranchingFactors = @{}
    [hashtable]$TaskNameLengths = @{}
    [hashtable]$TaskDescriptionLengths = @{}
    [System.Collections.ArrayList]$TaskPatterns = @()
    [hashtable]$MetadataDistributions = @{}
    
    RoadmapStatistics([string]$name) {
        $this.RoadmapName = $name
    }
}

# Fonction pour extraire les statistiques structurelles d'une roadmap
function Get-RoadmapStructuralStatistics {
    <#
    .SYNOPSIS
        Extrait les statistiques structurelles d'une roadmap.

    .DESCRIPTION
        Cette fonction analyse une roadmap et extrait diverses statistiques structurelles,
        comme le nombre total de tâches, la profondeur maximale, le nombre de tâches par niveau, etc.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap à analyser.

    .PARAMETER IncludeTaskDetails
        Si spécifié, inclut les détails de chaque tâche dans les statistiques.

    .EXAMPLE
        Get-RoadmapStructuralStatistics -RoadmapPath "C:\Roadmaps\plan-dev-v8.md"
        Analyse la roadmap spécifiée et retourne ses statistiques structurelles.

    .OUTPUTS
        RoadmapStatistics
    #>
    [CmdletBinding()]
    [OutputType([RoadmapStatistics])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeTaskDetails
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path $RoadmapPath)) {
        Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
        return $null
    }

    # Extraire le nom de la roadmap à partir du chemin du fichier
    $roadmapName = [System.IO.Path]::GetFileNameWithoutExtension($RoadmapPath)
    
    # Créer un objet pour stocker les statistiques
    $stats = [RoadmapStatistics]::new($roadmapName)
    
    # Parser la roadmap
    $roadmap = Parse-RoadmapFile -FilePath $RoadmapPath
    
    if ($null -eq $roadmap) {
        Write-Error "Échec du parsing de la roadmap: $RoadmapPath"
        return $null
    }
    
    # Calculer les statistiques de base
    $stats.TotalTasks = $roadmap.Tasks.Count
    $stats.CompletedTasks = ($roadmap.Tasks | Where-Object { $_.Status -eq "Completed" }).Count
    $stats.PendingTasks = $stats.TotalTasks - $stats.CompletedTasks
    
    # Calculer la profondeur maximale
    $stats.MaxDepth = ($roadmap.Tasks | ForEach-Object { $_.Id.Split('.').Count } | Measure-Object -Maximum).Maximum
    
    # Calculer le nombre de tâches par niveau
    for ($i = 1; $i -le $stats.MaxDepth; $i++) {
        $tasksAtLevel = ($roadmap.Tasks | Where-Object { $_.Id.Split('.').Count -eq $i }).Count
        $stats.TasksPerLevel[$i] = $tasksAtLevel
    }
    
    # Calculer le nombre de tâches par statut
    $statuses = $roadmap.Tasks | ForEach-Object { $_.Status } | Sort-Object -Unique
    foreach ($status in $statuses) {
        $count = ($roadmap.Tasks | Where-Object { $_.Status -eq $status }).Count
        $stats.TasksPerStatus[$status] = $count
    }
    
    # Calculer le nombre de tâches par catégorie (si disponible)
    if ($roadmap.Tasks[0].PSObject.Properties.Name -contains "Category") {
        $categories = $roadmap.Tasks | ForEach-Object { $_.Category } | Where-Object { $_ } | Sort-Object -Unique
        foreach ($category in $categories) {
            $count = ($roadmap.Tasks | Where-Object { $_.Category -eq $category }).Count
            $stats.TasksPerCategory[$category] = $count
        }
    }
    
    # Calculer les facteurs de branchement (nombre d'enfants directs)
    $parentIds = $roadmap.Tasks | ForEach-Object { $_.ParentId } | Where-Object { $_ } | Sort-Object -Unique
    foreach ($parentId in $parentIds) {
        $childCount = ($roadmap.Tasks | Where-Object { $_.ParentId -eq $parentId }).Count
        $stats.BranchingFactors[$parentId] = $childCount
    }
    
    # Calculer les distributions de longueur des noms et descriptions de tâches
    $roadmap.Tasks | ForEach-Object {
        $nameLength = $_.Title.Length
        $descLength = if ($_.Description) { $_.Description.Length } else { 0 }
        
        if (-not $stats.TaskNameLengths.ContainsKey($nameLength)) {
            $stats.TaskNameLengths[$nameLength] = 0
        }
        $stats.TaskNameLengths[$nameLength]++
        
        if (-not $stats.TaskDescriptionLengths.ContainsKey($descLength)) {
            $stats.TaskDescriptionLengths[$descLength] = 0
        }
        $stats.TaskDescriptionLengths[$descLength]++
    }
    
    # Calculer les statistiques de dépendances
    if ($roadmap.Tasks[0].PSObject.Properties.Name -contains "Dependencies") {
        $roadmap.Tasks | ForEach-Object {
            if ($_.Dependencies -and $_.Dependencies.Count -gt 0) {
                $depCount = $_.Dependencies.Count
                if (-not $stats.DependencyCounts.ContainsKey($depCount)) {
                    $stats.DependencyCounts[$depCount] = 0
                }
                $stats.DependencyCounts[$depCount]++
            }
        }
    }
    
    return $stats
}

# Fonction pour analyser les distributions de métadonnées
function Get-RoadmapMetadataDistributions {
    <#
    .SYNOPSIS
        Analyse les distributions de métadonnées dans une roadmap.

    .DESCRIPTION
        Cette fonction analyse les distributions de diverses métadonnées dans une roadmap,
        comme les statuts, les catégories, les priorités, etc.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap à analyser.

    .PARAMETER MetadataFields
        Liste des champs de métadonnées à analyser. Par défaut: Status, Category, Priority.

    .EXAMPLE
        Get-RoadmapMetadataDistributions -RoadmapPath "C:\Roadmaps\plan-dev-v8.md"
        Analyse les distributions de métadonnées dans la roadmap spécifiée.

    .OUTPUTS
        Hashtable
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [string[]]$MetadataFields = @("Status", "Category", "Priority")
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path $RoadmapPath)) {
        Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
        return $null
    }
    
    # Parser la roadmap
    $roadmap = Parse-RoadmapFile -FilePath $RoadmapPath
    
    if ($null -eq $roadmap) {
        Write-Error "Échec du parsing de la roadmap: $RoadmapPath"
        return $null
    }
    
    # Créer un hashtable pour stocker les distributions
    $distributions = @{}
    
    # Analyser chaque champ de métadonnées
    foreach ($field in $MetadataFields) {
        if ($roadmap.Tasks[0].PSObject.Properties.Name -contains $field) {
            $values = $roadmap.Tasks | ForEach-Object { $_.$field } | Where-Object { $_ } | Sort-Object
            $distribution = @{}
            
            foreach ($value in $values) {
                if (-not $distribution.ContainsKey($value)) {
                    $distribution[$value] = 0
                }
                $distribution[$value]++
            }
            
            # Calculer les pourcentages
            $total = $values.Count
            $percentages = @{}
            foreach ($key in $distribution.Keys) {
                $percentages[$key] = [math]::Round(($distribution[$key] / $total) * 100, 2)
            }
            
            $distributions[$field] = @{
                "Counts" = $distribution
                "Percentages" = $percentages
                "Total" = $total
            }
        }
    }
    
    # Analyser les distributions par niveau
    $levelDistributions = @{}
    $maxDepth = ($roadmap.Tasks | ForEach-Object { $_.Id.Split('.').Count } | Measure-Object -Maximum).Maximum
    
    for ($level = 1; $level -le $maxDepth; $level++) {
        $tasksAtLevel = $roadmap.Tasks | Where-Object { $_.Id.Split('.').Count -eq $level }
        $levelDist = @{}
        
        foreach ($field in $MetadataFields) {
            if ($roadmap.Tasks[0].PSObject.Properties.Name -contains $field) {
                $values = $tasksAtLevel | ForEach-Object { $_.$field } | Where-Object { $_ } | Sort-Object
                $distribution = @{}
                
                foreach ($value in $values) {
                    if (-not $distribution.ContainsKey($value)) {
                        $distribution[$value] = 0
                    }
                    $distribution[$value]++
                }
                
                $levelDist[$field] = $distribution
            }
        }
        
        $levelDistributions["Level$level"] = $levelDist
    }
    
    $distributions["ByLevel"] = $levelDistributions
    
    return $distributions
}

# Fonction pour détecter les patterns récurrents dans les roadmaps
function Get-RoadmapRecurringPatterns {
    <#
    .SYNOPSIS
        Détecte les patterns récurrents dans une roadmap.

    .DESCRIPTION
        Cette fonction analyse une roadmap pour détecter des patterns récurrents,
        comme des séquences de tâches similaires, des structures hiérarchiques répétitives, etc.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap à analyser.

    .PARAMETER MinPatternSize
        La taille minimale d'un pattern (nombre de tâches) pour qu'il soit considéré.
        Par défaut: 3.

    .PARAMETER SimilarityThreshold
        Le seuil de similarité (0-1) pour considérer deux séquences comme similaires.
        Par défaut: 0.7.

    .EXAMPLE
        Get-RoadmapRecurringPatterns -RoadmapPath "C:\Roadmaps\plan-dev-v8.md"
        Détecte les patterns récurrents dans la roadmap spécifiée.

    .OUTPUTS
        System.Collections.ArrayList
    #>
    [CmdletBinding()]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [int]$MinPatternSize = 3,

        [Parameter(Mandatory = $false)]
        [double]$SimilarityThreshold = 0.7
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path $RoadmapPath)) {
        Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
        return $null
    }
    
    # Parser la roadmap
    $roadmap = Parse-RoadmapFile -FilePath $RoadmapPath
    
    if ($null -eq $roadmap) {
        Write-Error "Échec du parsing de la roadmap: $RoadmapPath"
        return $null
    }
    
    # Créer une liste pour stocker les patterns détectés
    $patterns = New-Object System.Collections.ArrayList
    
    # Fonction pour calculer la similarité entre deux tâches
    function Get-TaskSimilarity {
        param (
            [PSObject]$Task1,
            [PSObject]$Task2
        )
        
        # Calculer la similarité basée sur différents attributs
        $titleSimilarity = if ($Task1.Title -and $Task2.Title) {
            $commonWords = Compare-Object -ReferenceObject $Task1.Title.Split(" ") -DifferenceObject $Task2.Title.Split(" ") -IncludeEqual | 
                Where-Object { $_.SideIndicator -eq "==" } | 
                Measure-Object | 
                Select-Object -ExpandProperty Count
            $totalWords = ($Task1.Title.Split(" ").Count + $Task2.Title.Split(" ").Count) / 2
            $commonWords / $totalWords
        } else { 0 }
        
        $statusSimilarity = if ($Task1.Status -eq $Task2.Status) { 1 } else { 0 }
        
        $categorySimilarity = if ($Task1.PSObject.Properties.Name -contains "Category" -and 
                                 $Task2.PSObject.Properties.Name -contains "Category" -and
                                 $Task1.Category -and $Task2.Category) {
            if ($Task1.Category -eq $Task2.Category) { 1 } else { 0 }
        } else { 0 }
        
        # Pondérer les différentes similarités
        $similarity = ($titleSimilarity * 0.6) + ($statusSimilarity * 0.2) + ($categorySimilarity * 0.2)
        return $similarity
    }
    
    # Fonction pour détecter les patterns structurels
    function Get-StructuralPatterns {
        param (
            [PSObject[]]$Tasks
        )
        
        $structuralPatterns = New-Object System.Collections.ArrayList
        
        # Regrouper les tâches par niveau
        $tasksByLevel = @{}
        foreach ($task in $Tasks) {
            $level = $task.Id.Split('.').Count
            if (-not $tasksByLevel.ContainsKey($level)) {
                $tasksByLevel[$level] = @()
            }
            $tasksByLevel[$level] += $task
        }
        
        # Analyser les patterns de branchement
        foreach ($level in $tasksByLevel.Keys | Sort-Object) {
            if ($level -lt 2) { continue } # Ignorer le niveau racine
            
            $tasksAtLevel = $tasksByLevel[$level]
            $parentGroups = $tasksAtLevel | Group-Object -Property ParentId
            
            foreach ($group in $parentGroups) {
                if ($group.Count -ge $MinPatternSize) {
                    # Analyser la structure des enfants
                    $childStructure = @{
                        "ParentId" = $group.Name
                        "ChildCount" = $group.Count
                        "Pattern" = "Groupe de $($group.Count) tâches sous le parent $($group.Name)"
                        "Tasks" = $group.Group.Id
                    }
                    
                    [void]$structuralPatterns.Add($childStructure)
                }
            }
        }
        
        return $structuralPatterns
    }
    
    # Détecter les patterns structurels
    $structuralPatterns = Get-StructuralPatterns -Tasks $roadmap.Tasks
    foreach ($pattern in $structuralPatterns) {
        [void]$patterns.Add(@{
            "Type" = "Structural"
            "Pattern" = $pattern.Pattern
            "Tasks" = $pattern.Tasks
        })
    }
    
    # Détecter les patterns de séquence (tâches similaires qui se suivent)
    $sortedTasks = $roadmap.Tasks | Sort-Object -Property Id
    for ($i = 0; $i -lt ($sortedTasks.Count - $MinPatternSize + 1); $i++) {
        $sequence = $sortedTasks[$i..($i + $MinPatternSize - 1)]
        $isPattern = $true
        
        # Vérifier si les tâches de la séquence sont similaires
        for ($j = 0; $j -lt ($sequence.Count - 1); $j++) {
            $similarity = Get-TaskSimilarity -Task1 $sequence[$j] -Task2 $sequence[$j + 1]
            if ($similarity -lt $SimilarityThreshold) {
                $isPattern = $false
                break
            }
        }
        
        if ($isPattern) {
            [void]$patterns.Add(@{
                "Type" = "Sequence"
                "Pattern" = "Séquence de $MinPatternSize tâches similaires"
                "Tasks" = $sequence.Id
                "Similarity" = $similarity
            })
        }
    }
    
    return $patterns
}

# Fonction principale pour analyser une roadmap
function Invoke-RoadmapAnalysis {
    <#
    .SYNOPSIS
        Analyse complète d'une roadmap.

    .DESCRIPTION
        Cette fonction effectue une analyse complète d'une roadmap, incluant
        les statistiques structurelles, les distributions de métadonnées et
        la détection de patterns récurrents.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap à analyser.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats de l'analyse. Si non spécifié,
        les résultats sont retournés mais non sauvegardés.

    .PARAMETER Format
        Le format de sortie des résultats. Valeurs possibles: JSON, XML, CLIXML.
        Par défaut: JSON.

    .EXAMPLE
        Invoke-RoadmapAnalysis -RoadmapPath "C:\Roadmaps\plan-dev-v8.md" -OutputPath "C:\Analysis"
        Analyse la roadmap spécifiée et sauvegarde les résultats au format JSON.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "XML", "CLIXML")]
        [string]$Format = "JSON"
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path $RoadmapPath)) {
        Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
        return $null
    }
    
    # Extraire le nom de la roadmap à partir du chemin du fichier
    $roadmapName = [System.IO.Path]::GetFileNameWithoutExtension($RoadmapPath)
    
    # Effectuer l'analyse complète
    $structuralStats = Get-RoadmapStructuralStatistics -RoadmapPath $RoadmapPath
    $metadataDistributions = Get-RoadmapMetadataDistributions -RoadmapPath $RoadmapPath
    $recurringPatterns = Get-RoadmapRecurringPatterns -RoadmapPath $RoadmapPath
    
    # Créer l'objet de résultats
    $results = [PSCustomObject]@{
        RoadmapName = $roadmapName
        AnalysisDate = Get-Date
        StructuralStatistics = $structuralStats
        MetadataDistributions = $metadataDistributions
        RecurringPatterns = $recurringPatterns
    }
    
    # Sauvegarder les résultats si un chemin de sortie est spécifié
    if ($OutputPath) {
        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Construire le chemin du fichier de sortie
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $outputFile = Join-Path -Path $OutputPath -ChildPath "$roadmapName-analysis-$timestamp.$($Format.ToLower())"
        
        # Sauvegarder les résultats dans le format spécifié
        switch ($Format) {
            "JSON" {
                $results | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding utf8
            }
            "XML" {
                $results | Export-Clixml -Path $outputFile
            }
            "CLIXML" {
                $results | Export-Clixml -Path $outputFile
            }
        }
        
        Write-Host "Analyse sauvegardée dans: $outputFile"
    }
    
    return $results
}
