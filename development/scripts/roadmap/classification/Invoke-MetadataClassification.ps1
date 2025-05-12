# Invoke-MetadataClassification.ps1
# Module pour la classification par analyse de métadonnées
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Fournit des fonctions pour la classification des tâches par analyse de métadonnées.

.DESCRIPTION
    Ce module fournit des fonctions pour la classification des tâches par analyse de métadonnées,
    en utilisant les tags, attributs et autres métadonnées associées aux tâches.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$utilsPath = Join-Path -Path $parentPath -ChildPath "utils"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"

if (Test-Path $parseRoadmapPath) {
    . $parseRoadmapPath
    Write-Verbose "Module Parse-Roadmap.ps1 chargé."
} else {
    Write-Error "Module Parse-Roadmap.ps1 introuvable à l'emplacement: $parseRoadmapPath"
    exit
}

# Fonction principale pour la classification par analyse de métadonnées
function Invoke-MetadataClassification {
    <#
    .SYNOPSIS
        Classifie les tâches d'une roadmap par analyse de métadonnées.

    .DESCRIPTION
        Cette fonction classifie les tâches d'une roadmap par analyse de métadonnées,
        en utilisant les tags, attributs et autres métadonnées associées aux tâches.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats de la classification.
        Si non spécifié, un dossier temporaire est utilisé.

    .PARAMETER MetadataFields
        Les champs de métadonnées à utiliser pour la classification.
        Par défaut, tous les champs de métadonnées sont utilisés.

    .PARAMETER WeightingScheme
        Le schéma de pondération à utiliser pour les différents champs de métadonnées.
        Par défaut, tous les champs ont un poids égal.

    .PARAMETER ClusteringAlgorithm
        L'algorithme de clustering à utiliser.
        Par défaut, "hierarchical".

    .PARAMETER NumberOfClusters
        Le nombre de clusters à créer.
        Par défaut, 0 (déterminé automatiquement).

    .PARAMETER MinimumSimilarity
        La similarité minimale pour considérer deux tâches comme similaires.
        Par défaut, 0.7 (70%).

    .EXAMPLE
        Invoke-MetadataClassification -RoadmapPath "C:\Roadmaps\roadmap.md" -MetadataFields @("Tags", "Priority", "Status") -NumberOfClusters 10
        Classifie les tâches d'une roadmap en 10 clusters en utilisant les tags, la priorité et le statut.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",

        [Parameter(Mandatory = $false)]
        [string[]]$MetadataFields = @(),

        [Parameter(Mandatory = $false)]
        [hashtable]$WeightingScheme = @{},

        [Parameter(Mandatory = $false)]
        [ValidateSet("hierarchical", "kmeans", "dbscan")]
        [string]$ClusteringAlgorithm = "hierarchical",

        [Parameter(Mandatory = $false)]
        [int]$NumberOfClusters = 0,

        [Parameter(Mandatory = $false)]
        [double]$MinimumSimilarity = 0.7
    )

    try {
        # Vérifier que le fichier de roadmap existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }
        
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path $env:TEMP -ChildPath "MetadataClassification"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Générer un identifiant unique pour cette exécution
        $executionId = [Guid]::NewGuid().ToString()
        $executionPath = Join-Path -Path $OutputPath -ChildPath $executionId
        
        # Créer le dossier d'exécution
        if (-not (Test-Path $executionPath)) {
            New-Item -Path $executionPath -ItemType Directory -Force | Out-Null
        }
        
        # Analyser la roadmap pour extraire les tâches
        Write-Verbose "Extraction des tâches de la roadmap..."
        $roadmapContent = Get-Content -Path $RoadmapPath
        $parsedRoadmap = Parse-RoadmapContent -Content $roadmapContent
        $tasks = $parsedRoadmap.Tasks
        
        Write-Verbose "Nombre total de tâches: $($tasks.Count)"
        
        # Extraire les métadonnées des tâches
        Write-Verbose "Extraction des métadonnées des tâches..."
        $taskMetadata = Get-TaskMetadata -Tasks $tasks
        
        # Déterminer les champs de métadonnées à utiliser
        if ($MetadataFields.Count -eq 0) {
            # Utiliser tous les champs de métadonnées disponibles
            $MetadataFields = $taskMetadata.Fields
        }
        
        Write-Verbose "Champs de métadonnées utilisés: $($MetadataFields -join ", ")"
        
        # Déterminer le schéma de pondération
        if ($WeightingScheme.Count -eq 0) {
            # Utiliser un poids égal pour tous les champs
            $WeightingScheme = @{}
            
            foreach ($field in $MetadataFields) {
                $WeightingScheme[$field] = 1.0 / $MetadataFields.Count
            }
        }
        
        # Calculer la matrice de similarité
        Write-Verbose "Calcul de la matrice de similarité..."
        $similarityMatrix = Get-MetadataSimilarityMatrix -TaskMetadata $taskMetadata -MetadataFields $MetadataFields -WeightingScheme $WeightingScheme -MinimumSimilarity $MinimumSimilarity
        
        # Déterminer le nombre de clusters si non spécifié
        if ($NumberOfClusters -le 0) {
            $NumberOfClusters = Get-OptimalClusterCount -SimilarityMatrix $similarityMatrix -Tasks $tasks
            Write-Verbose "Nombre optimal de clusters déterminé: $NumberOfClusters"
        }
        
        # Appliquer l'algorithme de clustering
        Write-Verbose "Application de l'algorithme de clustering: $ClusteringAlgorithm..."
        $clusters = switch ($ClusteringAlgorithm) {
            "hierarchical" { Invoke-HierarchicalClustering -SimilarityMatrix $similarityMatrix -NumberOfClusters $NumberOfClusters }
            "kmeans" { Invoke-KMeansClustering -TaskMetadata $taskMetadata -MetadataFields $MetadataFields -WeightingScheme $WeightingScheme -NumberOfClusters $NumberOfClusters }
            "dbscan" { Invoke-DBSCANClustering -SimilarityMatrix $similarityMatrix -MinimumSimilarity $MinimumSimilarity }
        }
        
        # Générer les étiquettes pour chaque cluster
        Write-Verbose "Génération des étiquettes pour les clusters..."
        $labeledClusters = Get-MetadataClusterLabels -Clusters $clusters -TaskMetadata $taskMetadata -MetadataFields $MetadataFields
        
        # Sauvegarder les résultats
        $resultFilePath = Join-Path -Path $executionPath -ChildPath "classification-result.json"
        $labeledClusters | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFilePath -Encoding UTF8
        
        # Générer un rapport HTML
        $reportFilePath = Join-Path -Path $executionPath -ChildPath "classification-report.html"
        $report = Get-MetadataClassificationReport -LabeledClusters $labeledClusters -TaskMetadata $taskMetadata -MetadataFields $MetadataFields -WeightingScheme $WeightingScheme
        $report | Out-File -FilePath $reportFilePath -Encoding UTF8
        
        # Créer l'objet de configuration
        $config = [PSCustomObject]@{
            RoadmapPath = $RoadmapPath
            OutputPath = $executionPath
            MetadataFields = $MetadataFields
            WeightingScheme = $WeightingScheme
            ClusteringAlgorithm = $ClusteringAlgorithm
            NumberOfClusters = $NumberOfClusters
            MinimumSimilarity = $MinimumSimilarity
            StartTime = Get-Date
            Tasks = $tasks
            TaskMetadata = $taskMetadata
            Clusters = $clusters
            SimilarityMatrix = $similarityMatrix
        }
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            Config = $config
            LabeledClusters = $labeledClusters
            ResultFilePath = $resultFilePath
            ReportFilePath = $reportFilePath
            ExecutionTime = (Get-Date) - $config.StartTime
        }
        
        return $result
    } catch {
        Write-Error "Échec de la classification par analyse de métadonnées: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour extraire les métadonnées des tâches
function Get-TaskMetadata {
    <#
    .SYNOPSIS
        Extrait les métadonnées des tâches.

    .DESCRIPTION
        Cette fonction extrait les métadonnées des tâches,
        notamment les tags, attributs et autres métadonnées.

    .PARAMETER Tasks
        Les tâches pour lesquelles extraire les métadonnées.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks
    )

    try {
        # Initialiser les structures de données
        $taskMetadata = [PSCustomObject]@{
            Tasks = @{}
            Fields = @()
            Values = @{}
        }
        
        # Analyser chaque tâche
        foreach ($task in $Tasks) {
            $taskId = $task.Id
            $metadata = @{}
            
            # Extraire les métadonnées de base
            $metadata["Status"] = if ($task.PSObject.Properties.Name.Contains("Status")) { $task.Status } else { "Unknown" }
            $metadata["Level"] = if ($task.PSObject.Properties.Name.Contains("Level")) { $task.Level } else { 0 }
            $metadata["ParentId"] = if ($task.PSObject.Properties.Name.Contains("ParentId")) { $task.ParentId } else { "" }
            
            # Extraire les tags et attributs
            $tags = @()
            $attributes = @{}
            
            if ($task.PSObject.Properties.Name.Contains("Title")) {
                $title = $task.Title
                
                # Extraire les tags (format: #tag)
                $tagMatches = [regex]::Matches($title, '#([a-zA-Z0-9_-]+)')
                
                foreach ($match in $tagMatches) {
                    $tag = $match.Groups[1].Value
                    $tags += $tag
                }
                
                # Extraire les attributs (format: #key:value)
                $attrMatches = [regex]::Matches($title, '#([a-zA-Z0-9_-]+):([a-zA-Z0-9_-]+)')
                
                foreach ($match in $attrMatches) {
                    $key = $match.Groups[1].Value
                    $value = $match.Groups[2].Value
                    $attributes[$key] = $value
                }
            }
            
            $metadata["Tags"] = $tags
            
            # Ajouter les attributs comme champs de métadonnées
            foreach ($key in $attributes.Keys) {
                $metadata[$key] = $attributes[$key]
            }
            
            # Stocker les métadonnées de la tâche
            $taskMetadata.Tasks[$taskId] = $metadata
            
            # Mettre à jour la liste des champs de métadonnées
            foreach ($field in $metadata.Keys) {
                if (-not $taskMetadata.Fields.Contains($field)) {
                    $taskMetadata.Fields += $field
                    $taskMetadata.Values[$field] = @{}
                }
                
                # Mettre à jour les valeurs possibles pour ce champ
                $value = $metadata[$field]
                
                if ($value -is [array]) {
                    foreach ($item in $value) {
                        if (-not $taskMetadata.Values[$field].ContainsKey($item)) {
                            $taskMetadata.Values[$field][$item] = 0
                        }
                        
                        $taskMetadata.Values[$field][$item]++
                    }
                } else {
                    if (-not $taskMetadata.Values[$field].ContainsKey($value)) {
                        $taskMetadata.Values[$field][$value] = 0
                    }
                    
                    $taskMetadata.Values[$field][$value]++
                }
            }
        }
        
        return $taskMetadata
    } catch {
        Write-Error "Échec de l'extraction des métadonnées: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour calculer la matrice de similarité basée sur les métadonnées
function Get-MetadataSimilarityMatrix {
    <#
    .SYNOPSIS
        Calcule la matrice de similarité basée sur les métadonnées.

    .DESCRIPTION
        Cette fonction calcule la matrice de similarité basée sur les métadonnées,
        en utilisant les champs de métadonnées spécifiés et le schéma de pondération.

    .PARAMETER TaskMetadata
        Les métadonnées des tâches.

    .PARAMETER MetadataFields
        Les champs de métadonnées à utiliser pour le calcul de similarité.

    .PARAMETER WeightingScheme
        Le schéma de pondération à utiliser pour les différents champs de métadonnées.

    .PARAMETER MinimumSimilarity
        La similarité minimale pour considérer deux tâches comme similaires.

    .OUTPUTS
        Hashtable
    #>
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$TaskMetadata,

        [Parameter(Mandatory = $true)]
        [string[]]$MetadataFields,

        [Parameter(Mandatory = $true)]
        [hashtable]$WeightingScheme,

        [Parameter(Mandatory = $false)]
        [double]$MinimumSimilarity = 0.7
    )

    try {
        $similarityMatrix = @{}
        $taskIds = $TaskMetadata.Tasks.Keys
        
        # Calculer la similarité entre chaque paire de tâches
        foreach ($taskId1 in $taskIds) {
            $similarityMatrix[$taskId1] = @{}
            $metadata1 = $TaskMetadata.Tasks[$taskId1]
            
            foreach ($taskId2 in $taskIds) {
                if ($taskId1 -eq $taskId2) {
                    # La similarité d'une tâche avec elle-même est 1
                    $similarityMatrix[$taskId1][$taskId2] = 1.0
                } else {
                    $metadata2 = $TaskMetadata.Tasks[$taskId2]
                    
                    # Calculer la similarité pour chaque champ de métadonnées
                    $totalSimilarity = 0
                    $totalWeight = 0
                    
                    foreach ($field in $MetadataFields) {
                        if ($metadata1.ContainsKey($field) -and $metadata2.ContainsKey($field)) {
                            $weight = $WeightingScheme[$field]
                            $similarity = Get-FieldSimilarity -Field $field -Value1 $metadata1[$field] -Value2 $metadata2[$field]
                            
                            $totalSimilarity += $similarity * $weight
                            $totalWeight += $weight
                        }
                    }
                    
                    # Normaliser la similarité
                    $similarity = if ($totalWeight -gt 0) { $totalSimilarity / $totalWeight } else { 0 }
                    
                    # Ne stocker que les similarités supérieures au seuil
                    if ($similarity -ge $MinimumSimilarity) {
                        $similarityMatrix[$taskId1][$taskId2] = $similarity
                    }
                }
            }
        }
        
        return $similarityMatrix
    } catch {
        Write-Error "Échec du calcul de la matrice de similarité: $($_.Exception.Message)"
        return @{}
    }
}

# Fonction pour calculer la similarité entre deux valeurs d'un champ
function Get-FieldSimilarity {
    <#
    .SYNOPSIS
        Calcule la similarité entre deux valeurs d'un champ.

    .DESCRIPTION
        Cette fonction calcule la similarité entre deux valeurs d'un champ,
        en utilisant différentes méthodes selon le type de champ.

    .PARAMETER Field
        Le nom du champ.

    .PARAMETER Value1
        La première valeur.

    .PARAMETER Value2
        La deuxième valeur.

    .OUTPUTS
        Double
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Field,

        [Parameter(Mandatory = $true)]
        $Value1,

        [Parameter(Mandatory = $true)]
        $Value2
    )

    try {
        # Calculer la similarité selon le type de champ et de valeur
        if ($Value1 -is [array] -and $Value2 -is [array]) {
            # Similarité entre deux ensembles (ex: tags)
            return Get-SetSimilarity -Set1 $Value1 -Set2 $Value2
        } elseif ($Value1 -is [string] -and $Value2 -is [string]) {
            # Similarité entre deux chaînes
            return Get-StringSimilarity -String1 $Value1 -String2 $Value2
        } elseif ($Value1 -is [int] -and $Value2 -is [int]) {
            # Similarité entre deux nombres
            return Get-NumericSimilarity -Number1 $Value1 -Number2 $Value2
        } else {
            # Similarité par égalité
            return if ($Value1 -eq $Value2) { 1.0 } else { 0.0 }
        }
    } catch {
        Write-Error "Échec du calcul de la similarité de champ: $($_.Exception.Message)"
        return 0
    }
}

# Fonction pour calculer la similarité entre deux ensembles
function Get-SetSimilarity {
    <#
    .SYNOPSIS
        Calcule la similarité entre deux ensembles.

    .DESCRIPTION
        Cette fonction calcule la similarité entre deux ensembles,
        en utilisant le coefficient de Jaccard.

    .PARAMETER Set1
        Le premier ensemble.

    .PARAMETER Set2
        Le deuxième ensemble.

    .OUTPUTS
        Double
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Set1,

        [Parameter(Mandatory = $true)]
        [array]$Set2
    )

    try {
        # Calculer le coefficient de Jaccard
        $intersection = $Set1 | Where-Object { $Set2 -contains $_ }
        $union = ($Set1 + $Set2) | Select-Object -Unique
        
        if ($union.Count -eq 0) {
            return 0
        }
        
        return $intersection.Count / $union.Count
    } catch {
        Write-Error "Échec du calcul de la similarité d'ensemble: $($_.Exception.Message)"
        return 0
    }
}

# Fonction pour calculer la similarité entre deux chaînes
function Get-StringSimilarity {
    <#
    .SYNOPSIS
        Calcule la similarité entre deux chaînes.

    .DESCRIPTION
        Cette fonction calcule la similarité entre deux chaînes,
        en utilisant la distance de Levenshtein normalisée.

    .PARAMETER String1
        La première chaîne.

    .PARAMETER String2
        La deuxième chaîne.

    .OUTPUTS
        Double
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$String1,

        [Parameter(Mandatory = $true)]
        [string]$String2
    )

    try {
        # Cas particuliers
        if ($String1 -eq $String2) {
            return 1.0
        }
        
        if ([string]::IsNullOrEmpty($String1) -or [string]::IsNullOrEmpty($String2)) {
            return 0.0
        }
        
        # Calculer la distance de Levenshtein
        $n = $String1.Length
        $m = $String2.Length
        $d = New-Object 'int[,]' ($n + 1), ($m + 1)
        
        for ($i = 0; $i -le $n; $i++) {
            $d[$i, 0] = $i
        }
        
        for ($j = 0; $j -le $m; $j++) {
            $d[0, $j] = $j
        }
        
        for ($i = 1; $i -le $n; $i++) {
            for ($j = 1; $j -le $m; $j++) {
                $cost = if ($String2[$j - 1] -eq $String1[$i - 1]) { 0 } else { 1 }
                
                $d[$i, $j] = [Math]::Min(
                    [Math]::Min(
                        $d[$i - 1, $j] + 1,      # Suppression
                        $d[$i, $j - 1] + 1       # Insertion
                    ),
                    $d[$i - 1, $j - 1] + $cost   # Substitution
                )
            }
        }
        
        $distance = $d[$n, $m]
        $maxLength = [Math]::Max($n, $m)
        
        # Normaliser la distance
        return 1.0 - ($distance / $maxLength)
    } catch {
        Write-Error "Échec du calcul de la similarité de chaîne: $($_.Exception.Message)"
        return 0
    }
}

# Fonction pour calculer la similarité entre deux nombres
function Get-NumericSimilarity {
    <#
    .SYNOPSIS
        Calcule la similarité entre deux nombres.

    .DESCRIPTION
        Cette fonction calcule la similarité entre deux nombres,
        en utilisant une fonction de décroissance exponentielle.

    .PARAMETER Number1
        Le premier nombre.

    .PARAMETER Number2
        Le deuxième nombre.

    .OUTPUTS
        Double
    #>
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory = $true)]
        [int]$Number1,

        [Parameter(Mandatory = $true)]
        [int]$Number2
    )

    try {
        # Calculer la similarité basée sur la différence absolue
        $diff = [Math]::Abs($Number1 - $Number2)
        
        # Utiliser une fonction de décroissance exponentielle
        return [Math]::Exp(-$diff / 10.0)
    } catch {
        Write-Error "Échec du calcul de la similarité numérique: $($_.Exception.Message)"
        return 0
    }
}
