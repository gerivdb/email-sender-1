<#
.SYNOPSIS
    Fonctions pour la rÃ©solution des cycles de dÃ©pendances.

.DESCRIPTION
    Ce script contient des fonctions pour rÃ©soudre les cycles de dÃ©pendances
    dÃ©tectÃ©s dans un projet.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-04-25
#>

# Fonction pour rÃ©soudre un cycle de dÃ©pendances
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
        # VÃ©rifier si le cycle est valide
        if (-not $Cycle -or -not $Cycle.Files -or $Cycle.Files.Count -lt 2) {
            Write-Warning "Cycle invalide ou incomplet."
            return $false
        }
        
        # RÃ©soudre le cycle selon la stratÃ©gie spÃ©cifiÃ©e
        switch ($Strategy) {
            "REMOVE_EDGE" {
                # Supprimer l'arÃªte la moins importante du cycle
                $result = Remove-CycleEdge -Cycle $Cycle -Graph $Graph
                return $result
            }
            "EXTRACT_INTERFACE" {
                # Extraire une interface pour briser le cycle
                $result = Export-Interface -Cycle $Cycle -Graph $Graph
                return $result
            }
            "DEPENDENCY_INVERSION" {
                # Appliquer le principe d'inversion de dÃ©pendance
                $result = Set-DependencyInversion -Cycle $Cycle -Graph $Graph
                return $result
            }
            "MEDIATOR" {
                # Introduire un mÃ©diateur pour briser le cycle
                $result = Add-Mediator -Cycle $Cycle -Graph $Graph
                return $result
            }
            default {
                Write-Warning "StratÃ©gie de rÃ©solution non reconnue : $Strategy"
                return $false
            }
        }
    }
    catch {
        Write-Error "Erreur lors de la rÃ©solution du cycle de dÃ©pendances : $_"
        return $false
    }
}

# Fonction pour supprimer l'arÃªte la moins importante d'un cycle
function Remove-CycleEdge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cycle,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Trouver l'arÃªte la moins importante du cycle
        $minImportance = [double]::MaxValue
        $edgeToRemove = $null
        
        for ($i = 0; $i -lt $Cycle.Files.Count - 1; $i++) {
            $source = $Cycle.Files[$i]
            $target = $Cycle.Files[$i + 1]
            
            # Calculer l'importance de l'arÃªte (nombre de dÃ©pendances)
            $importance = ($Graph[$source] | Where-Object { $_ -eq $target }).Count
            
            if ($importance -lt $minImportance) {
                $minImportance = $importance
                $edgeToRemove = @{
                    Source = $source
                    Target = $target
                }
            }
        }
        
        # VÃ©rifier Ã©galement la derniÃ¨re arÃªte du cycle
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
        
        # Supprimer l'arÃªte du graphe
        if ($edgeToRemove) {
            $Graph[$edgeToRemove.Source] = $Graph[$edgeToRemove.Source] | Where-Object { $_ -ne $edgeToRemove.Target }
            
            Write-Host "ArÃªte supprimÃ©e : $($edgeToRemove.Source) -> $($edgeToRemove.Target)" -ForegroundColor Green
            return $true
        }
        
        Write-Warning "Aucune arÃªte Ã  supprimer trouvÃ©e dans le cycle."
        return $false
    }
    catch {
        Write-Error "Erreur lors de la suppression de l'arÃªte du cycle : $_"
        return $false
    }
}

# Fonction pour extraire une interface
function Export-Interface {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cycle,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Identifier le fichier le plus dÃ©pendant dans le cycle
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
            
            # Mettre Ã  jour le graphe (simulation)
            foreach ($file in $Cycle.Files) {
                if ($file -ne $fileToExtract -and $Graph[$file] -contains $fileToExtract) {
                    # Remplacer la dÃ©pendance directe par une dÃ©pendance Ã  l'interface
                    $Graph[$file] = $Graph[$file] | Where-Object { $_ -ne $fileToExtract }
                    # Ajouter une dÃ©pendance simulÃ©e Ã  l'interface
                    # Dans un cas rÃ©el, il faudrait crÃ©er le fichier d'interface
                }
            }
            
            return $true
        }
        
        Write-Warning "Aucun fichier appropriÃ© pour l'extraction d'interface trouvÃ© dans le cycle."
        return $false
    }
    catch {
        Write-Error "Erreur lors de l'extraction d'interface : $_"
        return $false
    }
}

# Fonction pour appliquer le principe d'inversion de dÃ©pendance
function Set-DependencyInversion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cycle,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # Identifier les deux fichiers les plus fortement couplÃ©s dans le cycle
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
            # Simuler l'application du principe d'inversion de dÃ©pendance
            $abstractionName = "Abstract" + (Split-Path -Leaf $filePair.File1).Replace(".ps1", "").Replace(".psm1", "")
            
            Write-Host "Principe d'inversion de dÃ©pendance appliquÃ© entre $($filePair.File1) et $($filePair.File2)" -ForegroundColor Green
            Write-Host "Abstraction crÃ©Ã©e : $abstractionName" -ForegroundColor Green
            
            # Mettre Ã  jour le graphe (simulation)
            if ($Graph[$filePair.File1] -contains $filePair.File2) {
                $Graph[$filePair.File1] = $Graph[$filePair.File1] | Where-Object { $_ -ne $filePair.File2 }
            }
            
            if ($Graph[$filePair.File2] -contains $filePair.File1) {
                $Graph[$filePair.File2] = $Graph[$filePair.File2] | Where-Object { $_ -ne $filePair.File1 }
            }
            
            return $true
        }
        
        Write-Warning "Aucune paire de fichiers appropriÃ©e pour l'inversion de dÃ©pendance trouvÃ©e dans le cycle."
        return $false
    }
    catch {
        Write-Error "Erreur lors de l'application du principe d'inversion de dÃ©pendance : $_"
        return $false
    }
}

# Fonction pour introduire un mÃ©diateur
function Add-Mediator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Cycle,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        # CrÃ©er un nom pour le mÃ©diateur
        $mediatorName = "Mediator_" + (Get-Random)
        
        Write-Host "MÃ©diateur introduit : $mediatorName pour le cycle de longueur $($Cycle.Files.Count)" -ForegroundColor Green
        
        # Mettre Ã  jour le graphe (simulation)
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
        Write-Error "Erreur lors de l'introduction d'un mÃ©diateur : $_"
        return $false
    }
}

# Fonction pour rÃ©soudre tous les cycles dans un graphe
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
        
        Write-Host "RÃ©solution de $totalCycles cycles de dÃ©pendances..." -ForegroundColor Cyan
        
        foreach ($cycle in $Cycles) {
            Write-Host "Cycle $($resolvedCount + 1)/$totalCycles : $($cycle.Files.Count) fichiers" -ForegroundColor Yellow
            
            if ($AutoFix) {
                $result = Resolve-DependencyCycle -Cycle $cycle -Graph $Graph -Strategy $Strategy
                
                if ($result) {
                    $resolvedCount++
                    Write-Host "  RÃ©solu avec succÃ¨s." -ForegroundColor Green
                } else {
                    Write-Host "  Ã‰chec de la rÃ©solution." -ForegroundColor Red
                }
            } else {
                # Afficher les informations sur le cycle
                Write-Host "  Fichiers impliquÃ©s :" -ForegroundColor Yellow
                foreach ($file in $cycle.Files) {
                    Write-Host "    - $file" -ForegroundColor Yellow
                }
                
                Write-Host "  SÃ©vÃ©ritÃ© : $($cycle.Severity)" -ForegroundColor Yellow
                
                if ($cycle.Description) {
                    Write-Host "  Description : $($cycle.Description)" -ForegroundColor Yellow
                }
                
                # Proposer des solutions
                Write-Host "  Solutions possibles :" -ForegroundColor Cyan
                Write-Host "    1. Supprimer une dÃ©pendance (REMOVE_EDGE)" -ForegroundColor Cyan
                Write-Host "    2. Extraire une interface (EXTRACT_INTERFACE)" -ForegroundColor Cyan
                Write-Host "    3. Appliquer l'inversion de dÃ©pendance (DEPENDENCY_INVERSION)" -ForegroundColor Cyan
                Write-Host "    4. Introduire un mÃ©diateur (MEDIATOR)" -ForegroundColor Cyan
            }
            
            Write-Host ""
        }
        
        if ($AutoFix) {
            Write-Host "RÃ©solution terminÃ©e. $resolvedCount/$totalCycles cycles rÃ©solus." -ForegroundColor Cyan
        } else {
            Write-Host "Analyse terminÃ©e. $totalCycles cycles dÃ©tectÃ©s." -ForegroundColor Cyan
            Write-Host "Pour rÃ©soudre automatiquement les cycles, utilisez le paramÃ¨tre -AutoFix." -ForegroundColor Cyan
        }
        
        return @{
            TotalCycles = $totalCycles
            ResolvedCycles = $resolvedCount
            Graph = $Graph
        }
    }
    catch {
        Write-Error "Erreur lors de la rÃ©solution des cycles de dÃ©pendances : $_"
        return @{
            TotalCycles = $Cycles.Count
            ResolvedCycles = $resolvedCount
            Graph = $Graph
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Resolve-DependencyCycle, Remove-CycleEdge, Export-Interface, Set-DependencyInversion, Add-Mediator, Resolve-AllDependencyCycles


