﻿# Generate-HierarchicalStructures.ps1
# Script pour générer des structures hiérarchiques avancées pour les roadmaps
# Version: 1.0
# Date: 2025-05-15

# Importer le module de génération de tâches aléatoires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$randomTasksModulePath = Join-Path -Path $scriptPath -ChildPath "Generate-RandomTasks.ps1"

if (Test-Path -Path $randomTasksModulePath) {
    . $randomTasksModulePath
} else {
    Write-Error "Module de génération de tâches aléatoires non trouvé: $randomTasksModulePath"
    exit 1
}

# Fonction pour générer une structure hiérarchique en arbre équilibré
function New-BalancedTreeStructure {
    <#
    .SYNOPSIS
        Génère une structure hiérarchique en arbre équilibré.

    .DESCRIPTION
        Cette fonction génère une structure hiérarchique en arbre équilibré où chaque nœud
        a approximativement le même nombre d'enfants.

    .PARAMETER NodeCount
        Le nombre total de nœuds dans l'arbre.

    .PARAMETER MaxDepth
        La profondeur maximale de l'arbre.

    .PARAMETER BranchingFactor
        Le facteur de branchement (nombre moyen d'enfants par nœud).

    .PARAMETER WithMetadata
        Indique si des métadonnées doivent être générées pour les nœuds.

    .PARAMETER WithDependencies
        Indique si des dépendances doivent être générées entre les nœuds.

    .PARAMETER DependencyDensity
        La densité des dépendances entre les nœuds (0.0 à 1.0).

    .EXAMPLE
        New-BalancedTreeStructure -NodeCount 100 -MaxDepth 3 -BranchingFactor 3
        Génère un arbre équilibré avec 100 nœuds, une profondeur maximale de 3 et un facteur de branchement de 3.

    .OUTPUTS
        System.Array
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$NodeCount = 100,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 3,

        [Parameter(Mandatory = $false)]
        [int]$BranchingFactor = 3,

        [Parameter(Mandatory = $false)]
        [switch]$WithMetadata,

        [Parameter(Mandatory = $false)]
        [switch]$WithDependencies,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0, 1.0)]
        [double]$DependencyDensity = 0.2
    )

    # Calculer le nombre de nœuds par niveau
    $nodesPerLevel = @{}
    $totalNodes = 0

    for ($level = 0; $level -le $MaxDepth; $level++) {
        if ($level -eq 0) {
            $nodesPerLevel[$level] = 1 # Racine
        } else {
            $nodesPerLevel[$level] = [math]::Min($nodesPerLevel[$level - 1] * $BranchingFactor, $NodeCount - $totalNodes)
        }

        $totalNodes += $nodesPerLevel[$level]

        if ($totalNodes -ge $NodeCount) {
            break
        }
    }

    # Ajuster le nombre de nœuds pour atteindre exactement NodeCount
    if ($totalNodes -lt $NodeCount) {
        $diff = $NodeCount - $totalNodes
        $lastLevel = ($nodesPerLevel.Keys | Measure-Object -Maximum).Maximum
        $nodesPerLevel[$lastLevel] += $diff
    } elseif ($totalNodes -gt $NodeCount) {
        $diff = $totalNodes - $NodeCount
        $lastLevel = ($nodesPerLevel.Keys | Measure-Object -Maximum).Maximum
        $nodesPerLevel[$lastLevel] -= $diff
    }

    # Générer les nœuds
    $nodes = @()
    $nodeIndex = 1

    # Générer la racine
    $rootNode = New-RandomTask -Id "1" -IndentLevel 0 -WithMetadata:$WithMetadata
    $nodes += $rootNode

    # Générer les nœuds pour chaque niveau
    for ($level = 1; $level -le $MaxDepth; $level++) {
        $parentsFromPreviousLevel = $nodes | Where-Object { $_.IndentLevel -eq ($level - 1) }
        $nodesForThisLevel = $nodesPerLevel[$level]

        if ($parentsFromPreviousLevel.Count -eq 0 -or $nodesForThisLevel -eq 0) {
            continue
        }

        $nodesPerParent = [math]::Ceiling($nodesForThisLevel / $parentsFromPreviousLevel.Count)
        $nodeCounter = 0

        foreach ($parent in $parentsFromPreviousLevel) {
            for ($i = 1; $i -le $nodesPerParent -and $nodeCounter -lt $nodesForThisLevel; $i++) {
                $childId = "$($parent.Id).$i"
                $childNode = New-RandomTask -Id $childId -ParentId $parent.Id -IndentLevel $level -WithMetadata:$WithMetadata -ExistingTasks $nodes
                $nodes += $childNode
                $parent.Children += $childId
                $nodeCounter++
            }
        }
    }

    # Ajouter des dépendances si demandé
    if ($WithDependencies) {
        $nonRootNodes = $nodes | Where-Object { $_.IndentLevel -gt 0 }
        $dependencyCount = [math]::Round($nonRootNodes.Count * $DependencyDensity)

        for ($i = 0; $i -lt $dependencyCount; $i++) {
            $node = $nonRootNodes | Get-Random
            $potentialDependencies = $nodes | Where-Object {
                $_.Id -ne $node.Id -and
                $_.ParentId -ne $node.Id -and
                $node.ParentId -ne $_.Id -and
                -not $_.Dependencies.Contains($node.Id)
            }

            if ($potentialDependencies.Count -gt 0) {
                $dependency = $potentialDependencies | Get-Random

                if (-not $node.Dependencies.Contains($dependency.Id)) {
                    $node.Dependencies += $dependency.Id
                }
            }
        }
    }

    return $nodes
}

# Fonction pour générer une structure hiérarchique en arbre déséquilibré
function New-UnbalancedTreeStructure {
    <#
    .SYNOPSIS
        Génère une structure hiérarchique en arbre déséquilibré.

    .DESCRIPTION
        Cette fonction génère une structure hiérarchique en arbre déséquilibré où certaines
        branches sont beaucoup plus profondes que d'autres.

    .PARAMETER NodeCount
        Le nombre total de nœuds dans l'arbre.

    .PARAMETER MaxDepth
        La profondeur maximale de l'arbre.

    .PARAMETER ImbalanceFactor
        Le facteur de déséquilibre (0.0 à 1.0). Plus la valeur est élevée, plus l'arbre est déséquilibré.

    .PARAMETER WithMetadata
        Indique si des métadonnées doivent être générées pour les nœuds.

    .PARAMETER WithDependencies
        Indique si des dépendances doivent être générées entre les nœuds.

    .PARAMETER DependencyDensity
        La densité des dépendances entre les nœuds (0.0 à 1.0).

    .EXAMPLE
        New-UnbalancedTreeStructure -NodeCount 100 -MaxDepth 5 -ImbalanceFactor 0.7
        Génère un arbre déséquilibré avec 100 nœuds, une profondeur maximale de 5 et un facteur de déséquilibre de 0.7.

    .OUTPUTS
        System.Array
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$NodeCount = 100,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 5,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0, 1.0)]
        [double]$ImbalanceFactor = 0.7,

        [Parameter(Mandatory = $false)]
        [switch]$WithMetadata,

        [Parameter(Mandatory = $false)]
        [switch]$WithDependencies,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0, 1.0)]
        [double]$DependencyDensity = 0.2
    )

    # Générer les nœuds
    $nodes = @()

    # Générer la racine
    $rootNode = New-RandomTask -Id "1" -IndentLevel 0 -WithMetadata:$WithMetadata
    $nodes += $rootNode

    # Calculer le nombre de branches principales
    $mainBranchCount = [math]::Max(2, [math]::Round(($NodeCount - 1) * (1 - $ImbalanceFactor) / $MaxDepth))

    # Générer les branches principales
    for ($i = 1; $i -le $mainBranchCount; $i++) {
        $branchId = "$($rootNode.Id).$i"
        $branchNode = New-RandomTask -Id $branchId -ParentId $rootNode.Id -IndentLevel 1 -WithMetadata:$WithMetadata -ExistingTasks $nodes
        $nodes += $branchNode
        $rootNode.Children += $branchId
    }

    # Calculer le nombre de nœuds restants
    $remainingNodes = $NodeCount - $nodes.Count

    # Distribuer les nœuds restants de manière déséquilibrée
    $currentLevel = 2
    $currentBranch = 1

    while ($remainingNodes > 0 -and $currentLevel -le $MaxDepth) {
        # Sélectionner une branche pour ajouter des nœuds
        $parentBranchId = "$($rootNode.Id).$currentBranch"
        $parentBranch = $nodes | Where-Object { $_.Id -eq $parentBranchId }

        if (-not $parentBranch) {
            $currentBranch = ($currentBranch % $mainBranchCount) + 1
            continue
        }

        # Calculer le nombre de nœuds à ajouter à cette branche à ce niveau
        $nodesForThisBranch = [math]::Min(
            [math]::Max(1, [math]::Round($remainingNodes * $ImbalanceFactor / ($MaxDepth - $currentLevel + 1))),
            $remainingNodes
        )

        # Ajouter les nœuds
        for ($i = 1; $i -le $nodesForThisBranch; $i++) {
            $nodeId = "$($parentBranchId).$i"
            $node = New-RandomTask -Id $nodeId -ParentId $parentBranchId -IndentLevel $currentLevel -WithMetadata:$WithMetadata -ExistingTasks $nodes
            $nodes += $node
            $parentBranch.Children += $nodeId
            $remainingNodes--

            if ($remainingNodes -le 0) {
                break
            }
        }

        # Passer à la branche suivante ou au niveau suivant
        $currentBranch = ($currentBranch % $mainBranchCount) + 1

        if ($currentBranch -eq 1) {
            $currentLevel++
        }
    }

    # Ajouter des dépendances si demandé
    if ($WithDependencies) {
        $nonRootNodes = $nodes | Where-Object { $_.IndentLevel -gt 0 }
        $dependencyCount = [math]::Round($nonRootNodes.Count * $DependencyDensity)

        for ($i = 0; $i -lt $dependencyCount; $i++) {
            $node = $nonRootNodes | Get-Random
            $potentialDependencies = $nodes | Where-Object {
                $_.Id -ne $node.Id -and
                $_.ParentId -ne $node.Id -and
                $node.ParentId -ne $_.Id -and
                -not $_.Dependencies.Contains($node.Id)
            }

            if ($potentialDependencies.Count -gt 0) {
                $dependency = $potentialDependencies | Get-Random

                if (-not $node.Dependencies.Contains($dependency.Id)) {
                    $node.Dependencies += $dependency.Id
                }
            }
        }
    }

    return $nodes
}

# Fonction pour générer une structure hiérarchique en réseau (avec des dépendances croisées)
function New-NetworkStructure {
    <#
    .SYNOPSIS
        Génère une structure hiérarchique en réseau avec des dépendances croisées.

    .DESCRIPTION
        Cette fonction génère une structure hiérarchique en réseau où les nœuds ont
        de nombreuses dépendances croisées, formant un graphe plutôt qu'un arbre pur.

    .PARAMETER NodeCount
        Le nombre total de nœuds dans le réseau.

    .PARAMETER MaxDepth
        La profondeur maximale de la hiérarchie.

    .PARAMETER ConnectionDensity
        La densité des connexions entre les nœuds (0.0 à 1.0).

    .PARAMETER WithMetadata
        Indique si des métadonnées doivent être générées pour les nœuds.

    .EXAMPLE
        New-NetworkStructure -NodeCount 100 -MaxDepth 3 -ConnectionDensity 0.3
        Génère un réseau avec 100 nœuds, une profondeur maximale de 3 et une densité de connexion de 0.3.

    .OUTPUTS
        System.Array
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$NodeCount = 100,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 3,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0.0, 1.0)]
        [double]$ConnectionDensity = 0.3,

        [Parameter(Mandatory = $false)]
        [switch]$WithMetadata
    )

    # D'abord, générer une structure en arbre équilibré comme base
    $nodes = New-BalancedTreeStructure -NodeCount $NodeCount -MaxDepth $MaxDepth -WithMetadata:$WithMetadata -WithDependencies:$false

    # Calculer le nombre de connexions à ajouter
    $maxPossibleConnections = $NodeCount * ($NodeCount - 1) / 2
    $targetConnectionCount = [math]::Round($maxPossibleConnections * $ConnectionDensity)

    # Compter les connexions existantes (relations parent-enfant)
    $existingConnectionCount = ($nodes | Where-Object { $_.ParentId }).Count

    # Calculer le nombre de connexions supplémentaires à ajouter
    $additionalConnectionCount = [math]::Max(0, $targetConnectionCount - $existingConnectionCount)

    # Ajouter des connexions supplémentaires (dépendances)
    $attemptCount = 0
    $maxAttempts = $additionalConnectionCount * 2
    $addedConnections = 0

    while ($addedConnections -lt $additionalConnectionCount -and $attemptCount -lt $maxAttempts) {
        $attemptCount++

        # Sélectionner deux nœuds aléatoires
        $node1 = $nodes | Get-Random
        $node2 = $nodes | Get-Random

        # Vérifier si la connexion est valide
        if ($node1.Id -eq $node2.Id -or
            $node1.ParentId -eq $node2.Id -or
            $node2.ParentId -eq $node1.Id -or
            $node1.Dependencies.Contains($node2.Id) -or
            $node2.Dependencies.Contains($node1.Id)) {
            continue
        }

        # Ajouter la dépendance
        $node1.Dependencies += $node2.Id
        $addedConnections++
    }

    return $nodes
}

# Fonction pour générer une structure hiérarchique en matrice
function New-MatrixStructure {
    <#
    .SYNOPSIS
        Génère une structure hiérarchique en matrice.

    .DESCRIPTION
        Cette fonction génère une structure hiérarchique en matrice où les nœuds ont
        deux types de relations hiérarchiques (fonctionnelle et projet).

    .PARAMETER NodeCount
        Le nombre total de nœuds dans la matrice.

    .PARAMETER FunctionalDimension
        Le nombre de catégories fonctionnelles.

    .PARAMETER ProjectDimension
        Le nombre de projets.

    .PARAMETER WithMetadata
        Indique si des métadonnées doivent être générées pour les nœuds.

    .EXAMPLE
        New-MatrixStructure -NodeCount 100 -FunctionalDimension 5 -ProjectDimension 4
        Génère une structure en matrice avec 100 nœuds, 5 catégories fonctionnelles et 4 projets.

    .OUTPUTS
        System.Array
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$NodeCount = 100,

        [Parameter(Mandatory = $false)]
        [int]$FunctionalDimension = 5,

        [Parameter(Mandatory = $false)]
        [int]$ProjectDimension = 4,

        [Parameter(Mandatory = $false)]
        [switch]$WithMetadata
    )

    $nodes = @()

    # Générer la racine
    $rootNode = New-RandomTask -Id "0" -IndentLevel 0 -WithMetadata:$WithMetadata
    $rootNode.Description = "Racine de la structure en matrice"
    $nodes += $rootNode

    # Générer les catégories fonctionnelles
    $functionalCategories = @()

    for ($i = 1; $i -le $FunctionalDimension; $i++) {
        $categoryId = "F$i"
        $category = New-RandomTask -Id $categoryId -ParentId $rootNode.Id -IndentLevel 1 -WithMetadata:$WithMetadata -ExistingTasks $nodes
        $category.Description = "Catégorie fonctionnelle $i"
        $nodes += $category
        $rootNode.Children += $categoryId
        $functionalCategories += $category
    }

    # Générer les projets
    $projects = @()

    for ($i = 1; $i -le $ProjectDimension; $i++) {
        $projectId = "P$i"
        $project = New-RandomTask -Id $projectId -ParentId $rootNode.Id -IndentLevel 1 -WithMetadata:$WithMetadata -ExistingTasks $nodes
        $project.Description = "Projet $i"
        $nodes += $project
        $rootNode.Children += $projectId
        $projects += $project
    }

    # Calculer le nombre de nœuds par cellule de la matrice
    $cellCount = $FunctionalDimension * $ProjectDimension
    $nodesPerCell = [math]::Max(1, [math]::Floor(($NodeCount - 1 - $FunctionalDimension - $ProjectDimension) / $cellCount))

    # Générer les nœuds pour chaque cellule de la matrice
    $nodeCounter = 0
    $remainingNodes = $NodeCount - $nodes.Count

    foreach ($category in $functionalCategories) {
        foreach ($project in $projects) {
            $nodesForThisCell = [math]::Min($nodesPerCell, $remainingNodes)

            for ($i = 1; $i -le $nodesForThisCell; $i++) {
                $nodeId = "M$($category.Id)_$($project.Id)_$i"
                $node = New-RandomTask -Id $nodeId -IndentLevel 2 -WithMetadata:$WithMetadata -ExistingTasks $nodes

                # Ajouter des relations fonctionnelles et de projet
                $node.ParentId = $category.Id
                $node.Dependencies += $project.Id

                $nodes += $node
                $category.Children += $nodeId
                $remainingNodes--

                if ($remainingNodes -le 0) {
                    break
                }
            }

            if ($remainingNodes -le 0) {
                break
            }
        }

        if ($remainingNodes -le 0) {
            break
        }
    }

    return $nodes
}

# Fonction pour générer une structure hiérarchique en étoile
function New-StarStructure {
    <#
    .SYNOPSIS
        Génère une structure hiérarchique en étoile.

    .DESCRIPTION
        Cette fonction génère une structure hiérarchique en étoile où un nœud central
        est connecté à de nombreux nœuds périphériques.

    .PARAMETER NodeCount
        Le nombre total de nœuds dans la structure.

    .PARAMETER CentralNodeCount
        Le nombre de nœuds centraux.

    .PARAMETER WithMetadata
        Indique si des métadonnées doivent être générées pour les nœuds.

    .EXAMPLE
        New-StarStructure -NodeCount 100 -CentralNodeCount 3
        Génère une structure en étoile avec 100 nœuds et 3 nœuds centraux.

    .OUTPUTS
        System.Array
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$NodeCount = 100,

        [Parameter(Mandatory = $false)]
        [int]$CentralNodeCount = 3,

        [Parameter(Mandatory = $false)]
        [switch]$WithMetadata
    )

    $nodes = @()

    # Générer la racine
    $rootNode = New-RandomTask -Id "0" -IndentLevel 0 -WithMetadata:$WithMetadata
    $rootNode.Description = "Racine de la structure en étoile"
    $nodes += $rootNode

    # Générer les nœuds centraux
    $centralNodes = @()

    for ($i = 1; $i -le $CentralNodeCount; $i++) {
        $nodeId = "C$i"
        $node = New-RandomTask -Id $nodeId -ParentId $rootNode.Id -IndentLevel 1 -WithMetadata:$WithMetadata -ExistingTasks $nodes
        $node.Description = "Nœud central $i"
        $nodes += $node
        $rootNode.Children += $nodeId
        $centralNodes += $node
    }

    # Calculer le nombre de nœuds périphériques par nœud central
    $remainingNodes = $NodeCount - $nodes.Count
    $nodesPerCentral = [math]::Floor($remainingNodes / $CentralNodeCount)

    # Générer les nœuds périphériques
    foreach ($centralNode in $centralNodes) {
        $nodesForThisCentral = [math]::Min($nodesPerCentral, $remainingNodes)

        for ($i = 1; $i -le $nodesForThisCentral; $i++) {
            $nodeId = "$($centralNode.Id)_P$i"
            $node = New-RandomTask -Id $nodeId -ParentId $centralNode.Id -IndentLevel 2 -WithMetadata:$WithMetadata -ExistingTasks $nodes
            $nodes += $node
            $centralNode.Children += $nodeId
            $remainingNodes--

            if ($remainingNodes -le 0) {
                break
            }
        }

        if ($remainingNodes -le 0) {
            break
        }
    }

    # Distribuer les nœuds restants
    $centralIndex = 0

    while ($remainingNodes > 0) {
        $centralNode = $centralNodes[$centralIndex]
        $nodeCount = $centralNode.Children.Count

        $nodeId = "$($centralNode.Id)_P$($nodeCount + 1)"
        $node = New-RandomTask -Id $nodeId -ParentId $centralNode.Id -IndentLevel 2 -WithMetadata:$WithMetadata -ExistingTasks $nodes
        $nodes += $node
        $centralNode.Children += $nodeId
        $remainingNodes--

        $centralIndex = ($centralIndex + 1) % $CentralNodeCount
    }

    return $nodes
}

# Exporter les fonctions
Export-ModuleMember -Function New-BalancedTreeStructure, New-UnbalancedTreeStructure, New-NetworkStructure, New-MatrixStructure, New-StarStructure
