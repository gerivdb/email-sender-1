# DependencyManager.ps1
# Module de gestion des dépendances entre points de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$viewerPath = Join-Path -Path (Split-Path -Parent $scriptPath) -ChildPath "RestorePointsViewer.ps1"

if (Test-Path -Path $viewerPath) {
    . $viewerPath
} else {
    Write-Error "Le fichier RestorePointsViewer.ps1 est introuvable."
    exit 1
}

# Fonction pour analyser les dépendances entre points de restauration
function Get-RestorePointDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject]$RestorePoint,
        
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [switch]$Recursive,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 3,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeReverse,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )
    
    begin {
        # Récupérer tous les points de restauration
        $allPoints = Get-RestorePoints -ArchivePath $ArchivePath -UseCache:$UseCache
        
        # Fonction récursive pour analyser les dépendances
        function Get-Dependencies {
            param (
                [Parameter(Mandatory = $true)]
                [PSObject]$Point,
                
                [Parameter(Mandatory = $false)]
                [int]$CurrentDepth = 0,
                
                [Parameter(Mandatory = $false)]
                [System.Collections.ArrayList]$VisitedPoints = @()
            )
            
            # Vérifier si la profondeur maximale est atteinte
            if ($CurrentDepth -ge $MaxDepth) {
                return @()
            }
            
            # Vérifier si le point a déjà été visité (pour éviter les cycles)
            if ($VisitedPoints -contains $Point.Id) {
                return @()
            }
            
            # Ajouter le point courant à la liste des points visités
            $VisitedPoints.Add($Point.Id) | Out-Null
            
            # Initialiser la liste des dépendances
            $dependencies = @()
            
            # Analyser les dépendances directes
            $directDependencies = @()
            
            # Vérifier si le point a des références à d'autres points
            if ($Point.PSObject.Properties.Match("References").Count -and $null -ne $Point.References) {
                $references = $Point.References
                
                # Convertir en tableau si ce n'est pas déjà le cas
                if ($references -isnot [System.Array]) {
                    $references = @($references)
                }
                
                # Trouver les points correspondant aux références
                foreach ($reference in $references) {
                    $referencedPoint = $allPoints | Where-Object { $_.Id -eq $reference } | Select-Object -First 1
                    
                    if ($null -ne $referencedPoint) {
                        $directDependencies += $referencedPoint
                    }
                }
            }
            
            # Vérifier si le point a des dépendances explicites
            if ($Point.PSObject.Properties.Match("Dependencies").Count -and $null -ne $Point.Dependencies) {
                $explicitDependencies = $Point.Dependencies
                
                # Convertir en tableau si ce n'est pas déjà le cas
                if ($explicitDependencies -isnot [System.Array]) {
                    $explicitDependencies = @($explicitDependencies)
                }
                
                # Trouver les points correspondant aux dépendances explicites
                foreach ($dependency in $explicitDependencies) {
                    $dependencyPoint = $allPoints | Where-Object { $_.Id -eq $dependency } | Select-Object -First 1
                    
                    if ($null -ne $dependencyPoint) {
                        $directDependencies += $dependencyPoint
                    }
                }
            }
            
            # Analyser les dépendances implicites basées sur les métadonnées
            # Par exemple, les points avec le même auteur, type, ou catégorie peuvent être liés
            $implicitDependencies = @()
            
            # Dépendances par auteur
            if ($Point.PSObject.Properties.Match("Author").Count -and $null -ne $Point.Author) {
                $sameAuthorPoints = $allPoints | Where-Object { 
                    $_.Id -ne $Point.Id -and 
                    $_.PSObject.Properties.Match("Author").Count -and 
                    $_.Author -eq $Point.Author 
                }
                
                $implicitDependencies += $sameAuthorPoints
            }
            
            # Dépendances par type et catégorie
            if ($Point.PSObject.Properties.Match("Type").Count -and $null -ne $Point.Type -and
                $Point.PSObject.Properties.Match("Category").Count -and $null -ne $Point.Category) {
                $sameTypeAndCategoryPoints = $allPoints | Where-Object { 
                    $_.Id -ne $Point.Id -and 
                    $_.PSObject.Properties.Match("Type").Count -and $_.Type -eq $Point.Type -and
                    $_.PSObject.Properties.Match("Category").Count -and $_.Category -eq $Point.Category
                }
                
                $implicitDependencies += $sameTypeAndCategoryPoints
            }
            
            # Dépendances par tags communs
            if ($Point.PSObject.Properties.Match("Tags").Count -and $null -ne $Point.Tags) {
                $tags = $Point.Tags
                
                # Convertir en tableau si ce n'est pas déjà le cas
                if ($tags -isnot [System.Array]) {
                    $tags = @($tags)
                }
                
                $sameTagsPoints = $allPoints | Where-Object { 
                    $_.Id -ne $Point.Id -and 
                    $_.PSObject.Properties.Match("Tags").Count -and 
                    $null -ne $_.Tags
                } | Where-Object {
                    $pointTags = $_.Tags
                    
                    # Convertir en tableau si ce n'est pas déjà le cas
                    if ($pointTags -isnot [System.Array]) {
                        $pointTags = @($pointTags)
                    }
                    
                    # Vérifier s'il y a au moins un tag commun
                    $commonTags = $tags | Where-Object { $pointTags -contains $_ }
                    $commonTags.Count -gt 0
                }
                
                $implicitDependencies += $sameTagsPoints
            }
            
            # Dépendances par date (points créés le même jour)
            if ($Point.PSObject.Properties.Match("CreatedAt").Count -and $null -ne $Point.CreatedAt) {
                try {
                    $createdDate = [DateTime]::Parse($Point.CreatedAt).Date
                    
                    $sameDatePoints = $allPoints | Where-Object { 
                        $_.Id -ne $Point.Id -and 
                        $_.PSObject.Properties.Match("CreatedAt").Count -and 
                        $null -ne $_.CreatedAt
                    } | Where-Object {
                        try {
                            $pointDate = [DateTime]::Parse($_.CreatedAt).Date
                            $pointDate -eq $createdDate
                        } catch {
                            $false
                        }
                    }
                    
                    $implicitDependencies += $sameDatePoints
                } catch {
                    # Ignorer les erreurs de parsing de date
                }
            }
            
            # Ajouter les dépendances directes à la liste des dépendances
            foreach ($dependency in $directDependencies) {
                $dependencies += [PSCustomObject]@{
                    SourceId = $Point.Id
                    TargetId = $dependency.Id
                    Type = "Direct"
                    Strength = 1.0
                    Source = $Point
                    Target = $dependency
                }
            }
            
            # Ajouter les dépendances implicites à la liste des dépendances
            foreach ($dependency in $implicitDependencies) {
                # Calculer la force de la dépendance implicite
                $strength = 0.0
                $dependencyType = "Implicit"
                
                # Vérifier les différents critères de dépendance
                if ($Point.PSObject.Properties.Match("Author").Count -and $dependency.PSObject.Properties.Match("Author").Count -and
                    $Point.Author -eq $dependency.Author) {
                    $strength += 0.3
                    $dependencyType = "Author"
                }
                
                if ($Point.PSObject.Properties.Match("Type").Count -and $dependency.PSObject.Properties.Match("Type").Count -and
                    $Point.Type -eq $dependency.Type) {
                    $strength += 0.2
                    $dependencyType = if ($dependencyType -eq "Implicit") { "Type" } else { "$dependencyType,Type" }
                }
                
                if ($Point.PSObject.Properties.Match("Category").Count -and $dependency.PSObject.Properties.Match("Category").Count -and
                    $Point.Category -eq $dependency.Category) {
                    $strength += 0.2
                    $dependencyType = if ($dependencyType -eq "Implicit") { "Category" } else { "$dependencyType,Category" }
                }
                
                if ($Point.PSObject.Properties.Match("Tags").Count -and $dependency.PSObject.Properties.Match("Tags").Count -and
                    $null -ne $Point.Tags -and $null -ne $dependency.Tags) {
                    $pointTags = if ($Point.Tags -is [System.Array]) { $Point.Tags } else { @($Point.Tags) }
                    $dependencyTags = if ($dependency.Tags -is [System.Array]) { $dependency.Tags } else { @($dependency.Tags) }
                    
                    $commonTags = $pointTags | Where-Object { $dependencyTags -contains $_ }
                    $strength += 0.1 * $commonTags.Count
                    
                    if ($commonTags.Count -gt 0) {
                        $dependencyType = if ($dependencyType -eq "Implicit") { "Tags" } else { "$dependencyType,Tags" }
                    }
                }
                
                if ($Point.PSObject.Properties.Match("CreatedAt").Count -and $dependency.PSObject.Properties.Match("CreatedAt").Count -and
                    $null -ne $Point.CreatedAt -and $null -ne $dependency.CreatedAt) {
                    try {
                        $pointDate = [DateTime]::Parse($Point.CreatedAt).Date
                        $dependencyDate = [DateTime]::Parse($dependency.CreatedAt).Date
                        
                        if ($pointDate -eq $dependencyDate) {
                            $strength += 0.2
                            $dependencyType = if ($dependencyType -eq "Implicit") { "Date" } else { "$dependencyType,Date" }
                        }
                    } catch {
                        # Ignorer les erreurs de parsing de date
                    }
                }
                
                # Ajouter la dépendance si sa force est suffisante
                if ($strength -ge 0.2) {
                    $dependencies += [PSCustomObject]@{
                        SourceId = $Point.Id
                        TargetId = $dependency.Id
                        Type = $dependencyType
                        Strength = $strength
                        Source = $Point
                        Target = $dependency
                    }
                }
            }
            
            # Si récursif, analyser les dépendances des dépendances
            if ($Recursive) {
                foreach ($dependency in ($directDependencies + $implicitDependencies) | Select-Object -Unique) {
                    $subDependencies = Get-Dependencies -Point $dependency -CurrentDepth ($CurrentDepth + 1) -VisitedPoints $VisitedPoints
                    $dependencies += $subDependencies
                }
            }
            
            return $dependencies
        }
    }
    
    process {
        # Initialiser la liste des dépendances
        $dependencies = @()
        
        # Analyser les dépendances du point de restauration
        $dependencies += Get-Dependencies -Point $RestorePoint
        
        # Si demandé, analyser les dépendances inverses (points qui dépendent de ce point)
        if ($IncludeReverse) {
            foreach ($point in $allPoints) {
                if ($point.Id -eq $RestorePoint.Id) {
                    continue
                }
                
                $pointDependencies = Get-Dependencies -Point $point
                $reverseDependencies = $pointDependencies | Where-Object { $_.TargetId -eq $RestorePoint.Id }
                
                foreach ($dependency in $reverseDependencies) {
                    $dependencies += [PSCustomObject]@{
                        SourceId = $dependency.TargetId
                        TargetId = $dependency.SourceId
                        Type = "Reverse,$($dependency.Type)"
                        Strength = $dependency.Strength * 0.8
                        Source = $dependency.Target
                        Target = $dependency.Source
                    }
                }
            }
        }
        
        return $dependencies
    }
}

# Fonction pour créer un graphe de dépendances
function New-DependencyGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Dependencies,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Hierarchical", "Circular", "Force")]
        [string]$Layout = "Hierarchical",
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeStrength,
        
        [Parameter(Mandatory = $false)]
        [switch]$GroupByType
    )
    
    # Initialiser le graphe
    $graph = [PSCustomObject]@{
        Nodes = @()
        Edges = @()
        Layout = $Layout
        IncludeStrength = $IncludeStrength
        GroupByType = $GroupByType
    }
    
    # Extraire les nœuds uniques
    $uniqueNodes = @{}
    
    foreach ($dependency in $Dependencies) {
        if (-not $uniqueNodes.ContainsKey($dependency.SourceId)) {
            $uniqueNodes[$dependency.SourceId] = $dependency.Source
        }
        
        if (-not $uniqueNodes.ContainsKey($dependency.TargetId)) {
            $uniqueNodes[$dependency.TargetId] = $dependency.Target
        }
    }
    
    # Ajouter les nœuds au graphe
    foreach ($nodeId in $uniqueNodes.Keys) {
        $node = $uniqueNodes[$nodeId]
        
        $nodeType = if ($node.PSObject.Properties.Match("Type").Count) { $node.Type } else { "Unknown" }
        $nodeCategory = if ($node.PSObject.Properties.Match("Category").Count) { $node.Category } else { "Unknown" }
        $nodeName = if ($node.PSObject.Properties.Match("Name").Count) { $node.Name } else { $nodeId }
        
        $graph.Nodes += [PSCustomObject]@{
            Id = $nodeId
            Name = $nodeName
            Type = $nodeType
            Category = $nodeCategory
            Data = $node
        }
    }
    
    # Ajouter les arêtes au graphe
    foreach ($dependency in $Dependencies) {
        $graph.Edges += [PSCustomObject]@{
            Source = $dependency.SourceId
            Target = $dependency.TargetId
            Type = $dependency.Type
            Strength = $dependency.Strength
        }
    }
    
    return $graph
}

# Fonction pour exporter un graphe de dépendances au format DOT (Graphviz)
function Export-DependencyGraphToDot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Graph,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$env:TEMP\dependency_graph.dot"
    )
    
    # Initialiser le contenu DOT
    $dot = "digraph DependencyGraph {`n"
    $dot += "  // Graph settings`n"
    $dot += "  graph [rankdir=LR, fontname=Arial, fontsize=12, overlap=false, splines=true];`n"
    $dot += "  node [shape=box, style=filled, fontname=Arial, fontsize=10];`n"
    $dot += "  edge [fontname=Arial, fontsize=8];`n"
    $dot += "`n"
    
    # Ajouter les nœuds
    $dot += "  // Nodes`n"
    
    if ($Graph.GroupByType) {
        # Regrouper les nœuds par type
        $nodesByType = $Graph.Nodes | Group-Object -Property Type
        
        foreach ($typeGroup in $nodesByType) {
            $dot += "  subgraph cluster_$($typeGroup.Name.Replace(' ', '_')) {`n"
            $dot += "    label=`"$($typeGroup.Name)`";`n"
            $dot += "    style=filled;`n"
            $dot += "    color=lightgrey;`n"
            
            foreach ($node in $typeGroup.Group) {
                $color = switch ($node.Type) {
                    "Document" { "lightblue" }
                    "Image" { "lightgreen" }
                    "Video" { "lightcoral" }
                    "Audio" { "lightyellow" }
                    default { "white" }
                }
                
                $dot += "    `"$($node.Id)`" [label=`"$($node.Name)`", fillcolor=`"$color`"];`n"
            }
            
            $dot += "  }`n"
        }
    } else {
        # Ajouter les nœuds sans regroupement
        foreach ($node in $Graph.Nodes) {
            $color = switch ($node.Type) {
                "Document" { "lightblue" }
                "Image" { "lightgreen" }
                "Video" { "lightcoral" }
                "Audio" { "lightyellow" }
                default { "white" }
            }
            
            $dot += "  `"$($node.Id)`" [label=`"$($node.Name)`", fillcolor=`"$color`"];`n"
        }
    }
    
    $dot += "`n"
    
    # Ajouter les arêtes
    $dot += "  // Edges`n"
    
    foreach ($edge in $Graph.Edges) {
        $style = switch -Regex ($edge.Type) {
            "Direct" { "solid" }
            "Reverse" { "dashed" }
            default { "dotted" }
        }
        
        $weight = if ($Graph.IncludeStrength) { [Math]::Round($edge.Strength * 5) } else { 1 }
        $penwidth = if ($Graph.IncludeStrength) { [Math]::Max(1, [Math]::Round($edge.Strength * 3)) } else { 1 }
        
        $label = if ($Graph.IncludeStrength) { "$($edge.Type) ($([Math]::Round($edge.Strength, 2)))" } else { $edge.Type }
        
        $dot += "  `"$($edge.Source)`" -> `"$($edge.Target)`" [label=`"$label`", style=$style, weight=$weight, penwidth=$penwidth];`n"
    }
    
    $dot += "}`n"
    
    # Écrire le contenu dans le fichier de sortie
    $dot | Set-Content -Path $OutputPath -Force
    
    return $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Get-RestorePointDependencies, New-DependencyGraph, Export-DependencyGraphToDot
