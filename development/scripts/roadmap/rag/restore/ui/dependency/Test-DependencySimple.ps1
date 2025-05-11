# Test-DependencySimple.ps1
# Script de test simplifié pour la visualisation des dépendances
# Version: 1.0
# Date: 2025-05-15

Write-Host "=== TEST DE VISUALISATION DES DÉPENDANCES ===" -ForegroundColor Cyan

# Fonction pour simuler Get-RestorePoints
function Get-RestorePoints {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",

        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )

    # Créer des points de restauration de test
    $points = @(
        [PSCustomObject]@{
            Id           = "archive1-1"
            Name         = "Archive 1-1"
            Description  = "Première archive de test"
            CreatedAt    = [DateTime]::Now.AddDays(-30).ToString("o")
            ModifiedAt   = [DateTime]::Now.AddDays(-25).ToString("o")
            ArchivedAt   = [DateTime]::Now.AddDays(-20).ToString("o")
            Type         = "Document"
            Category     = "Test"
            Tags         = @("test", "document", "important")
            Status       = "Active"
            Version      = "1.0"
            Author       = "Jean Dupont"
            Size         = 1024
            Checksum     = "abc123"
            References   = @("archive1-2", "archive2-1")
            Dependencies = @("archive1-2")
        },
        [PSCustomObject]@{
            Id           = "archive1-2"
            Name         = "Archive 1-2"
            Description  = "Deuxième archive de test"
            CreatedAt    = [DateTime]::Now.AddDays(-28).ToString("o")
            ModifiedAt   = [DateTime]::Now.AddDays(-26).ToString("o")
            ArchivedAt   = [DateTime]::Now.AddDays(-24).ToString("o")
            Type         = "Image"
            Category     = "Test"
            Tags         = @("test", "image")
            Status       = "Archived"
            Version      = "1.1"
            Author       = "Marie Martin"
            Size         = 2048
            Checksum     = "def456"
            Resolution   = "1920x1080"
            References   = @("archive2-1")
            Dependencies = @("archive2-1")
        },
        [PSCustomObject]@{
            Id           = "archive2-1"
            Name         = "Archive 2-1"
            Description  = "Troisième archive de test"
            CreatedAt    = [DateTime]::Now.AddDays(-20).ToString("o")
            ModifiedAt   = [DateTime]::Now.AddDays(-15).ToString("o")
            ArchivedAt   = [DateTime]::Now.AddDays(-10).ToString("o")
            Type         = "Document"
            Category     = "Production"
            Tags         = @("production", "document", "important")
            Status       = "Active"
            Version      = "2.0"
            Author       = "Jean Dupont"
            Size         = 1536
            Checksum     = "ghi789"
            PageCount    = 42
            References   = @("archive3-1")
            Dependencies = @("archive3-1")
        }
    )

    return $points
}

# Fonction pour simuler Get-RestorePointDependencies
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

    # Récupérer tous les points de restauration
    $allPoints = Get-RestorePoints

    # Créer des dépendances de test
    $dependencies = @()

    # Ajouter des dépendances directes
    if ($RestorePoint.PSObject.Properties.Match("Dependencies").Count -and $null -ne $RestorePoint.Dependencies) {
        foreach ($depId in $RestorePoint.Dependencies) {
            $depPoint = $allPoints | Where-Object { $_.Id -eq $depId } | Select-Object -First 1

            if ($null -ne $depPoint) {
                $dependencies += [PSCustomObject]@{
                    SourceId = $RestorePoint.Id
                    TargetId = $depPoint.Id
                    Type     = "Direct"
                    Strength = 1.0
                    Source   = $RestorePoint
                    Target   = $depPoint
                }
            }
        }
    }

    # Ajouter des dépendances implicites
    foreach ($point in $allPoints) {
        if ($point.Id -eq $RestorePoint.Id) {
            continue
        }

        # Dépendance par auteur
        if ($point.Author -eq $RestorePoint.Author) {
            $dependencies += [PSCustomObject]@{
                SourceId = $RestorePoint.Id
                TargetId = $point.Id
                Type     = "Author"
                Strength = 0.3
                Source   = $RestorePoint
                Target   = $point
            }
        }

        # Dépendance par type et catégorie
        if ($point.Type -eq $RestorePoint.Type -and $point.Category -eq $RestorePoint.Category) {
            $dependencies += [PSCustomObject]@{
                SourceId = $RestorePoint.Id
                TargetId = $point.Id
                Type     = "Type,Category"
                Strength = 0.4
                Source   = $RestorePoint
                Target   = $point
            }
        }
    }

    return $dependencies
}

# Fonction pour simuler New-DependencyGraph
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

    # Créer un graphe de test
    $graph = [PSCustomObject]@{
        Nodes           = @()
        Edges           = @()
        Layout          = $Layout
        IncludeStrength = $IncludeStrength
        GroupByType     = $GroupByType
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
            Id       = $nodeId
            Name     = $nodeName
            Type     = $nodeType
            Category = $nodeCategory
            Data     = $node
        }
    }

    # Ajouter les arêtes au graphe
    foreach ($dependency in $Dependencies) {
        $graph.Edges += [PSCustomObject]@{
            Source   = $dependency.SourceId
            Target   = $dependency.TargetId
            Type     = $dependency.Type
            Strength = $dependency.Strength
        }
    }

    return $graph
}

# Fonction pour simuler Export-DependencyGraphToDot
function Export-DependencyGraphToDot {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Graph,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "$env:TEMP\dependency_graph.dot"
    )

    # Simuler l'exportation du graphe
    $dot = "digraph DependencyGraph {`n"
    $dot += "  // Graph settings`n"
    $dot += "  graph [rankdir=LR, fontname=Arial, fontsize=12, overlap=false, splines=true];`n"
    $dot += "  node [shape=box, style=filled, fontname=Arial, fontsize=10];`n"
    $dot += "  edge [fontname=Arial, fontsize=8];`n"
    $dot += "`n"

    # Ajouter les nœuds
    $dot += "  // Nodes`n"
    foreach ($node in $Graph.Nodes) {
        $dot += "  `"$($node.Id)`" [label=`"$($node.Name)`", fillcolor=`"lightblue`"];`n"
    }

    $dot += "`n"

    # Ajouter les arêtes
    $dot += "  // Edges`n"
    foreach ($edge in $Graph.Edges) {
        $dot += "  `"$($edge.Source)`" -> `"$($edge.Target)`" [label=`"$($edge.Type)`"];`n"
    }

    $dot += "}`n"

    # Écrire le contenu dans le fichier de sortie
    $dot | Set-Content -Path $OutputPath -Force

    return $OutputPath
}

# Test simple des fonctions
Write-Host "Test des fonctions de dépendance..." -ForegroundColor Cyan

# Récupérer les points de restauration
$points = Get-RestorePoints
Write-Host "Points de restauration récupérés: $($points.Count)" -ForegroundColor Green

# Analyser les dépendances du premier point
$dependencies = Get-RestorePointDependencies -RestorePoint $points[0]
Write-Host "Dépendances trouvées: $($dependencies.Count)" -ForegroundColor Green

# Créer un graphe
$graph = New-DependencyGraph -Dependencies $dependencies -Layout "Hierarchical" -IncludeStrength -GroupByType
Write-Host "Graphe créé avec $($graph.Nodes.Count) nœuds et $($graph.Edges.Count) arêtes" -ForegroundColor Green

# Exporter le graphe
$dotFile = Export-DependencyGraphToDot -Graph $graph -OutputPath "$env:TEMP\test_dependency_graph.dot"
Write-Host "Graphe exporté vers: $dotFile" -ForegroundColor Green

Write-Host "Tests termines avec succes!" -ForegroundColor Cyan
