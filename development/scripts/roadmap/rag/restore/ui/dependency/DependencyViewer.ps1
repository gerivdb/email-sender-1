# DependencyViewer.ps1
# Module de visualisation des dépendances entre points de restauration
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$managerPath = Join-Path -Path $scriptPath -ChildPath "DependencyManager.ps1"

if (Test-Path -Path $managerPath) {
    . $managerPath
} else {
    Write-Error "Le fichier DependencyManager.ps1 est introuvable."
    exit 1
}

# Fonction pour afficher les dépendances d'un point de restauration
function Show-RestorePointDependencies {
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
        [switch]$UseCache,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("List", "Tree", "Graph")]
        [string]$ViewMode = "List"
    )
    
    # Récupérer les dépendances
    $dependencies = Get-RestorePointDependencies -RestorePoint $RestorePoint -ArchivePath $ArchivePath -Recursive:$Recursive -MaxDepth $MaxDepth -IncludeReverse:$IncludeReverse -UseCache:$UseCache
    
    # Afficher les dépendances selon le mode de visualisation
    switch ($ViewMode) {
        "List" {
            Show-DependenciesList -Dependencies $dependencies -RestorePoint $RestorePoint
        }
        "Tree" {
            Show-DependenciesTree -Dependencies $dependencies -RestorePoint $RestorePoint
        }
        "Graph" {
            Show-DependenciesGraph -Dependencies $dependencies -RestorePoint $RestorePoint
        }
    }
}

# Fonction pour afficher les dépendances sous forme de liste
function Show-DependenciesList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Dependencies,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$RestorePoint
    )
    
    Clear-Host
    
    Write-Host "=== DÉPENDANCES DU POINT DE RESTAURATION ===" -ForegroundColor Cyan
    Write-Host "Point: $($RestorePoint.Name) (ID: $($RestorePoint.Id))" -ForegroundColor Yellow
    
    if ($Dependencies.Count -eq 0) {
        Write-Host "`nAucune dépendance trouvée." -ForegroundColor White
        return
    }
    
    # Regrouper les dépendances par type
    $groupedDependencies = $Dependencies | Group-Object -Property Type
    
    Write-Host "`nNombre total de dépendances: $($Dependencies.Count)" -ForegroundColor White
    
    foreach ($group in $groupedDependencies | Sort-Object -Property Name) {
        Write-Host "`nType: $($group.Name) ($($group.Count) dépendances)" -ForegroundColor Green
        
        foreach ($dependency in $group.Group | Sort-Object -Property Strength -Descending) {
            $targetName = if ($dependency.Target.PSObject.Properties.Match("Name").Count) { $dependency.Target.Name } else { $dependency.TargetId }
            $targetType = if ($dependency.Target.PSObject.Properties.Match("Type").Count) { $dependency.Target.Type } else { "Unknown" }
            
            Write-Host "  $targetName (ID: $($dependency.TargetId))" -ForegroundColor White
            Write-Host "    Type: $targetType" -ForegroundColor DarkGray
            Write-Host "    Force: $([Math]::Round($dependency.Strength * 100))%" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Fonction pour afficher les dépendances sous forme d'arbre
function Show-DependenciesTree {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Dependencies,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$RestorePoint
    )
    
    Clear-Host
    
    Write-Host "=== ARBRE DE DÉPENDANCES DU POINT DE RESTAURATION ===" -ForegroundColor Cyan
    Write-Host "Point: $($RestorePoint.Name) (ID: $($RestorePoint.Id))" -ForegroundColor Yellow
    
    if ($Dependencies.Count -eq 0) {
        Write-Host "`nAucune dépendance trouvée." -ForegroundColor White
        return
    }
    
    # Fonction récursive pour afficher l'arbre
    function Show-TreeNode {
        param (
            [Parameter(Mandatory = $true)]
            [string]$NodeId,
            
            [Parameter(Mandatory = $true)]
            [PSObject[]]$AllDependencies,
            
            [Parameter(Mandatory = $false)]
            [int]$Level = 0,
            
            [Parameter(Mandatory = $false)]
            [System.Collections.ArrayList]$VisitedNodes = @()
        )
        
        # Vérifier si le nœud a déjà été visité (pour éviter les cycles)
        if ($VisitedNodes -contains $NodeId) {
            Write-Host "$("  " * $Level)└─ $NodeId (cycle détecté)" -ForegroundColor DarkRed
            return
        }
        
        # Ajouter le nœud courant à la liste des nœuds visités
        $VisitedNodes.Add($NodeId) | Out-Null
        
        # Trouver les dépendances du nœud
        $nodeDependencies = $AllDependencies | Where-Object { $_.SourceId -eq $NodeId }
        
        # Trouver le nœud cible pour afficher son nom
        $nodeTarget = $AllDependencies | Where-Object { $_.TargetId -eq $NodeId } | Select-Object -First 1
        $nodeName = if ($nodeTarget -and $nodeTarget.Target.PSObject.Properties.Match("Name").Count) { $nodeTarget.Target.Name } else { $NodeId }
        
        # Afficher le nœud
        if ($Level -eq 0) {
            Write-Host "$nodeName (ID: $NodeId)" -ForegroundColor Green
        } else {
            $prefix = if ($nodeDependencies.Count -eq 0) { "└─ " } else { "├─ " }
            Write-Host "$("  " * $Level)$prefix$nodeName (ID: $NodeId)" -ForegroundColor White
        }
        
        # Afficher les dépendances du nœud
        $lastIndex = $nodeDependencies.Count - 1
        for ($i = 0; $i -lt $nodeDependencies.Count; $i++) {
            $dependency = $nodeDependencies[$i]
            
            # Créer une copie de la liste des nœuds visités
            $newVisitedNodes = [System.Collections.ArrayList]::new($VisitedNodes)
            
            # Afficher la dépendance
            Show-TreeNode -NodeId $dependency.TargetId -AllDependencies $AllDependencies -Level ($Level + 1) -VisitedNodes $newVisitedNodes
        }
    }
    
    # Afficher l'arbre à partir du point de restauration
    Show-TreeNode -NodeId $RestorePoint.Id -AllDependencies $Dependencies
    
    Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor DarkGray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# Fonction pour afficher les dépendances sous forme de graphe
function Show-DependenciesGraph {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject[]]$Dependencies,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$RestorePoint
    )
    
    Clear-Host
    
    Write-Host "=== GRAPHE DE DÉPENDANCES DU POINT DE RESTAURATION ===" -ForegroundColor Cyan
    Write-Host "Point: $($RestorePoint.Name) (ID: $($RestorePoint.Id))" -ForegroundColor Yellow
    
    if ($Dependencies.Count -eq 0) {
        Write-Host "`nAucune dépendance trouvée." -ForegroundColor White
        return
    }
    
    # Vérifier si Graphviz est installé
    $graphvizInstalled = $false
    try {
        $graphvizVersion = & dot -V 2>&1
        $graphvizInstalled = $true
    } catch {
        $graphvizInstalled = $false
    }
    
    if (-not $graphvizInstalled) {
        Write-Host "`nGraphviz n'est pas installé ou n'est pas dans le PATH." -ForegroundColor Red
        Write-Host "Veuillez installer Graphviz pour visualiser le graphe de dépendances." -ForegroundColor Red
        Write-Host "Téléchargement: https://graphviz.org/download/" -ForegroundColor Yellow
        
        Write-Host "`nAffichage des dépendances sous forme de liste à la place:" -ForegroundColor White
        Show-DependenciesList -Dependencies $Dependencies -RestorePoint $RestorePoint
        return
    }
    
    # Créer le graphe de dépendances
    $graph = New-DependencyGraph -Dependencies $Dependencies -Layout "Hierarchical" -IncludeStrength -GroupByType
    
    # Exporter le graphe au format DOT
    $dotFile = Export-DependencyGraphToDot -Graph $graph -OutputPath "$env:TEMP\dependency_graph.dot"
    
    # Générer l'image du graphe
    $imageFile = "$env:TEMP\dependency_graph.png"
    & dot -Tpng -o $imageFile $dotFile
    
    if (Test-Path -Path $imageFile) {
        Write-Host "`nGraphe généré avec succès." -ForegroundColor Green
        Write-Host "Fichier image: $imageFile" -ForegroundColor White
        
        # Ouvrir l'image avec l'application par défaut
        Start-Process $imageFile
    } else {
        Write-Host "`nÉchec de la génération du graphe." -ForegroundColor Red
        Write-Host "Affichage des dépendances sous forme de liste à la place:" -ForegroundColor White
        Show-DependenciesList -Dependencies $Dependencies -RestorePoint $RestorePoint
    }
}

# Fonction pour afficher le menu de visualisation des dépendances
function Show-DependencyVisualizationMenu {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$RestorePoint,
        
        [Parameter(Mandatory = $false)]
        [string]$ArchivePath = "$env:USERPROFILE\Documents\Archives",
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache
    )
    
    $exit = $false
    
    while (-not $exit) {
        Clear-Host
        
        Write-Host "=== MENU DE VISUALISATION DES DÉPENDANCES ===" -ForegroundColor Cyan
        Write-Host "Point: $($RestorePoint.Name) (ID: $($RestorePoint.Id))" -ForegroundColor Yellow
        Write-Host "1. Afficher les dépendances directes (liste)" -ForegroundColor White
        Write-Host "2. Afficher les dépendances directes (arbre)" -ForegroundColor White
        Write-Host "3. Afficher les dépendances directes (graphe)" -ForegroundColor White
        Write-Host "4. Afficher les dépendances récursives (liste)" -ForegroundColor White
        Write-Host "5. Afficher les dépendances récursives (arbre)" -ForegroundColor White
        Write-Host "6. Afficher les dépendances récursives (graphe)" -ForegroundColor White
        Write-Host "7. Afficher toutes les dépendances (directes et inverses)" -ForegroundColor White
        Write-Host "Q. Quitter" -ForegroundColor White
        Write-Host "=============================================" -ForegroundColor Cyan
        
        $choice = Read-Host "Votre choix"
        
        switch ($choice) {
            "1" {
                Show-RestorePointDependencies -RestorePoint $RestorePoint -ArchivePath $ArchivePath -UseCache:$UseCache -ViewMode "List"
            }
            "2" {
                Show-RestorePointDependencies -RestorePoint $RestorePoint -ArchivePath $ArchivePath -UseCache:$UseCache -ViewMode "Tree"
            }
            "3" {
                Show-RestorePointDependencies -RestorePoint $RestorePoint -ArchivePath $ArchivePath -UseCache:$UseCache -ViewMode "Graph"
            }
            "4" {
                Show-RestorePointDependencies -RestorePoint $RestorePoint -ArchivePath $ArchivePath -UseCache:$UseCache -ViewMode "List" -Recursive -MaxDepth 3
            }
            "5" {
                Show-RestorePointDependencies -RestorePoint $RestorePoint -ArchivePath $ArchivePath -UseCache:$UseCache -ViewMode "Tree" -Recursive -MaxDepth 3
            }
            "6" {
                Show-RestorePointDependencies -RestorePoint $RestorePoint -ArchivePath $ArchivePath -UseCache:$UseCache -ViewMode "Graph" -Recursive -MaxDepth 3
            }
            "7" {
                Show-RestorePointDependencies -RestorePoint $RestorePoint -ArchivePath $ArchivePath -UseCache:$UseCache -ViewMode "Graph" -Recursive -MaxDepth 2 -IncludeReverse
            }
            "Q" {
                $exit = $true
            }
            "q" {
                $exit = $true
            }
            default {
                Write-Host "Choix invalide. Veuillez réessayer." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Show-RestorePointDependencies, Show-DependenciesList, Show-DependenciesTree, Show-DependenciesGraph, Show-DependencyVisualizationMenu
