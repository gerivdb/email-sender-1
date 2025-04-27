<#
.SYNOPSIS
    Fonctions pour la résolution des cycles de dépendances.

.DESCRIPTION
    Ce script contient des fonctions pour résoudre les cycles de dépendances
    détectés dans un projet.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-04-25
#>

# Fonction pour résoudre un cycle de dépendances
function Resolve-DependencyCycle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cycle,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("REMOVE_EDGE", "EXTRACT_INTERFACE", "DEPENDENCY_INVERSION", "MEDIATOR")]
        [string]$Strategy = "REMOVE_EDGE"
    )
    
    try {
        # Vérifier si le cycle est valide
        if (-not $Cycle -or -not $Cycle.Files -or $Cycle.Files.Count -lt 2) {
            Write-Warning "Cycle invalide ou incomplet."
            return $false
        }
        
        # Résoudre le cycle selon la stratégie spécifiée
        switch ($Strategy) {
            "REMOVE_EDGE" {
                # Supprimer l'arête la moins importante du cycle
                $result = Remove-CycleEdge -Cycle $Cycle -Graph $Graph
                return $result
            }
            "EXTRACT_INTERFACE" {
                # Extraire une interface pour briser le cycle
                $result = Extract-Interface -Cycle $Cycle -Graph $Graph
                return $result
            }
            "DEPENDENCY_INVERSION" {
                # Appliquer le principe d'inversion de dépendance
                $result = Apply-DependencyInversion -Cycle $Cycle -Graph $Graph
                return $result
            }
            "MEDIATOR" {
                # Introduire un médiateur pour briser le cycle
                $result = Introduce-Mediator -Cycle $Cycle -Graph $Graph
                return $result
            }
            default {
                Write-Warning "Stratégie de résolution non reconnue : $Strategy"
                return $false
            }
        }
    }
    catch {
        Write-Error "Erreur lors de la résolution du cycle de dépendances : $_"
        return $false
    }
}

# Fonction pour supprimer l'arête la moins importante d'un cycle
function Remove-CycleEdge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cycle,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Trouver l'arête la moins importante du cycle
        $minImportance = [double]::MaxValue
        $edgeToRemove = $null
        
        for ($i = 0; $i -lt $Cycle.Files.Count - 1; $i++) {
            $source = $Cycle.Files[$i]
            $target = $Cycle.Files[$i + 1]
            
            # Calculer l'importance de l'arête (nombre de dépendances)
            $importance = ($Graph[$source] | Where-Object { $_ -eq $target }).Count
            
            if ($importance -lt $minImportance) {
                $minImportance = $importance
                $edgeToRemove = @{
                    Source = $source
                    Target = $target
                }
            }
        }
        
        # Vérifier également la dernière arête du cycle
        $source = $Cycle.Files[-1]
        $target = $Cycle.Files[0]
        $importance = ($Graph[$source] | Where-Object { $_ -eq $target }).Count
        
        if ($importance -lt $minImportance) {
            $minImportance = $importance
            $edgeToRemove = @{
                Source = $source
                Target = $target
            }
        }
        
        # Supprimer l'arête du graphe
        if ($edgeToRemove) {
            $Graph[$edgeToRemove.Source] = $Graph[$edgeToRemove.Source] | Where-Object { $_ -ne $edgeToRemove.Target }
            
            Write-Host "Arête supprimée : $($edgeToRemove.Source) -> $($edgeToRemove.Target)" -ForegroundColor Green
            return $true
        }
        
        Write-Warning "Aucune arête à supprimer trouvée dans le cycle."
        return $false
    }
    catch {
        Write-Error "Erreur lors de la suppression de l'arête du cycle : $_"
        return $false
    }
}

# Fonction pour extraire une interface
function Extract-Interface {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cycle,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Identifier le fichier le plus dépendant dans le cycle
        $maxDependencies = 0
        $fileToExtract = $null
        
        foreach ($file in $Cycle.Files) {
            $dependencies = 0
            
            foreach ($otherFile in $Cycle.Files) {
                if ($file -ne $otherFile -and $Graph[$file] -contains $otherFile) {
                    $dependencies++
                }
            }
            
            if ($dependencies -gt $maxDependencies) {
                $maxDependencies = $dependencies
                $fileToExtract = $file
            }
        }
        
        if ($fileToExtract) {
            # Simuler l'extraction d'une interface
            $interfaceName = "I" + (Split-Path -Leaf $fileToExtract).Replace(".ps1", "").Replace(".psm1", "")
            
            Write-Host "Interface extraite : $interfaceName pour $fileToExtract" -ForegroundColor Green
            
            # Mettre à jour le graphe (simulation)
            foreach ($file in $Cycle.Files) {
                if ($file -ne $fileToExtract -and $Graph[$file] -contains $fileToExtract) {
                    # Remplacer la dépendance directe par une dépendance à l'interface
                    $Graph[$file] = $Graph[$file] | Where-Object { $_ -ne $fileToExtract }
                    # Ajouter une dépendance simulée à l'interface
                    # Dans un cas réel, il faudrait créer le fichier d'interface
                }
            }
            
            return $true
        }
        
        Write-Warning "Aucun fichier approprié pour l'extraction d'interface trouvé dans le cycle."
        return $false
    }
    catch {
        Write-Error "Erreur lors de l'extraction d'interface : $_"
        return $false
    }
}

# Fonction pour appliquer le principe d'inversion de dépendance
function Apply-DependencyInversion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cycle,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Identifier les deux fichiers les plus fortement couplés dans le cycle
        $maxCoupling = 0
        $filePair = $null
        
        for ($i = 0; $i -lt $Cycle.Files.Count; $i++) {
            $file1 = $Cycle.Files[$i]
            $file2 = $Cycle.Files[($i + 1) % $Cycle.Files.Count]
            
            $coupling = 0
            if ($Graph[$file1] -contains $file2) { $coupling++ }
            if ($Graph[$file2] -contains $file1) { $coupling++ }
            
            if ($coupling -gt $maxCoupling) {
                $maxCoupling = $coupling
                $filePair = @{
                    File1 = $file1
                    File2 = $file2
                }
            }
        }
        
        if ($filePair) {
            # Simuler l'application du principe d'inversion de dépendance
            $abstractionName = "Abstract" + (Split-Path -Leaf $filePair.File1).Replace(".ps1", "").Replace(".psm1", "")
            
            Write-Host "Principe d'inversion de dépendance appliqué entre $($filePair.File1) et $($filePair.File2)" -ForegroundColor Green
            Write-Host "Abstraction créée : $abstractionName" -ForegroundColor Green
            
            # Mettre à jour le graphe (simulation)
            if ($Graph[$filePair.File1] -contains $filePair.File2) {
                $Graph[$filePair.File1] = $Graph[$filePair.File1] | Where-Object { $_ -ne $filePair.File2 }
            }
            
            if ($Graph[$filePair.File2] -contains $filePair.File1) {
                $Graph[$filePair.File2] = $Graph[$filePair.File2] | Where-Object { $_ -ne $filePair.File1 }
            }
            
            return $true
        }
        
        Write-Warning "Aucune paire de fichiers appropriée pour l'inversion de dépendance trouvée dans le cycle."
        return $false
    }
    catch {
        Write-Error "Erreur lors de l'application du principe d'inversion de dépendance : $_"
        return $false
    }
}

# Fonction pour introduire un médiateur
function Introduce-Mediator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cycle,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Créer un nom pour le médiateur
        $mediatorName = "Mediator_" + (Get-Random)
        
        Write-Host "Médiateur introduit : $mediatorName pour le cycle de longueur $($Cycle.Files.Count)" -ForegroundColor Green
        
        # Mettre à jour le graphe (simulation)
        for ($i = 0; $i -lt $Cycle.Files.Count; $i++) {
            $file1 = $Cycle.Files[$i]
            $file2 = $Cycle.Files[($i + 1) % $Cycle.Files.Count]
            
            if ($Graph[$file1] -contains $file2) {
                $Graph[$file1] = $Graph[$file1] | Where-Object { $_ -ne $file2 }
            }
        }
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'introduction d'un médiateur : $_"
        return $false
    }
}

# Fonction pour résoudre tous les cycles dans un graphe
function Resolve-AllDependencyCycles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$Cycles,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("REMOVE_EDGE", "EXTRACT_INTERFACE", "DEPENDENCY_INVERSION", "MEDIATOR")]
        [string]$Strategy = "REMOVE_EDGE",
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoFix
    )
    
    try {
        $resolvedCount = 0
        $totalCycles = $Cycles.Count
        
        Write-Host "Résolution de $totalCycles cycles de dépendances..." -ForegroundColor Cyan
        
        foreach ($cycle in $Cycles) {
            Write-Host "Cycle $($resolvedCount + 1)/$totalCycles : $($cycle.Files.Count) fichiers" -ForegroundColor Yellow
            
            if ($AutoFix) {
                $result = Resolve-DependencyCycle -Cycle $cycle -Graph $Graph -Strategy $Strategy
                
                if ($result) {
                    $resolvedCount++
                    Write-Host "  Résolu avec succès." -ForegroundColor Green
                } else {
                    Write-Host "  Échec de la résolution." -ForegroundColor Red
                }
            } else {
                # Afficher les informations sur le cycle
                Write-Host "  Fichiers impliqués :" -ForegroundColor Yellow
                foreach ($file in $cycle.Files) {
                    Write-Host "    - $file" -ForegroundColor Yellow
                }
                
                Write-Host "  Sévérité : $($cycle.Severity)" -ForegroundColor Yellow
                
                if ($cycle.Description) {
                    Write-Host "  Description : $($cycle.Description)" -ForegroundColor Yellow
                }
                
                # Proposer des solutions
                Write-Host "  Solutions possibles :" -ForegroundColor Cyan
                Write-Host "    1. Supprimer une dépendance (REMOVE_EDGE)" -ForegroundColor Cyan
                Write-Host "    2. Extraire une interface (EXTRACT_INTERFACE)" -ForegroundColor Cyan
                Write-Host "    3. Appliquer l'inversion de dépendance (DEPENDENCY_INVERSION)" -ForegroundColor Cyan
                Write-Host "    4. Introduire un médiateur (MEDIATOR)" -ForegroundColor Cyan
            }
            
            Write-Host ""
        }
        
        if ($AutoFix) {
            Write-Host "Résolution terminée. $resolvedCount/$totalCycles cycles résolus." -ForegroundColor Cyan
        } else {
            Write-Host "Analyse terminée. $totalCycles cycles détectés." -ForegroundColor Cyan
            Write-Host "Pour résoudre automatiquement les cycles, utilisez le paramètre -AutoFix." -ForegroundColor Cyan
        }
        
        return @{
            TotalCycles = $totalCycles
            ResolvedCycles = $resolvedCount
            Graph = $Graph
        }
    }
    catch {
        Write-Error "Erreur lors de la résolution des cycles de dépendances : $_"
        return @{
            TotalCycles = $Cycles.Count
            ResolvedCycles = $resolvedCount
            Graph = $Graph
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Resolve-DependencyCycle, Remove-CycleEdge, Extract-Interface, Apply-DependencyInversion, Introduce-Mediator, Resolve-AllDependencyCycles
