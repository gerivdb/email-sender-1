#Requires -Version 5.1
<#
.SYNOPSIS
    Divise une charge de travail d'analyse en parties Ã©quilibrÃ©es.

.DESCRIPTION
    Ce script divise une charge de travail d'analyse en parties Ã©quilibrÃ©es
    pour une exÃ©cution parallÃ¨le efficace, en tenant compte de la complexitÃ©
    des Ã©lÃ©ments Ã  analyser.

.PARAMETER InputPath
    Le chemin du fichier d'entrÃ©e contenant les Ã©lÃ©ments Ã  diviser.
    Le fichier doit Ãªtre au format JSON.

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer les rÃ©sultats de la division.
    Par dÃ©faut: "workloads\split_workload.json"

.PARAMETER ChunkCount
    Le nombre de parties Ã  crÃ©er.
    Par dÃ©faut: nombre de processeurs logiques

.PARAMETER WeightProperty
    Le nom de la propriÃ©tÃ© Ã  utiliser comme poids pour la rÃ©partition.
    Par dÃ©faut: "Weight"

.PARAMETER CalculateWeights
    Indique s'il faut calculer les poids des Ã©lÃ©ments.
    Par dÃ©faut: $false

.PARAMETER WeightFunction
    Le nom de la fonction Ã  utiliser pour calculer les poids.
    Valeurs possibles: "Size", "Complexity", "Changes", "Custom"
    Par dÃ©faut: "Changes"

.EXAMPLE
    .\Split-AnalysisWorkload.ps1 -InputPath "files_to_analyze.json" -ChunkCount 8
    Divise les fichiers en 8 parties Ã©quilibrÃ©es.

.EXAMPLE
    .\Split-AnalysisWorkload.ps1 -InputPath "files_to_analyze.json" -CalculateWeights -WeightFunction "Complexity"
    Divise les fichiers en utilisant la complexitÃ© comme poids.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter()]
    [string]$OutputPath = "workloads\split_workload.json",

    [Parameter()]
    [int]$ChunkCount = 0,

    [Parameter()]
    [string]$WeightProperty = "Weight",

    [Parameter()]
    [switch]$CalculateWeights,

    [Parameter()]
    [ValidateSet("Size", "Complexity", "Changes", "Custom")]
    [string]$WeightFunction = "Changes"
)

# Importer le module de parallÃ©lisation
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\ParallelPRAnalysis.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module ParallelPRAnalysis non trouvÃ© Ã  l'emplacement: $modulePath"
    exit 1
}

# Fonction pour calculer le poids d'un Ã©lÃ©ment
function Get-ItemWeight {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Item,
        
        [Parameter(Mandatory = $true)]
        [string]$Function
    )

    try {
        switch ($Function) {
            "Size" {
                # Utiliser la taille du fichier comme poids
                if ($null -ne $Item.size) {
                    return $Item.size
                } elseif ($null -ne $Item.Size) {
                    return $Item.Size
                } elseif ($null -ne $Item.length) {
                    return $Item.length
                } elseif ($null -ne $Item.Length) {
                    return $Item.Length
                } else {
                    return 1
                }
            }
            "Complexity" {
                # Utiliser une estimation de la complexitÃ© comme poids
                if ($null -ne $Item.complexity) {
                    return $Item.complexity
                } elseif ($null -ne $Item.Complexity) {
                    return $Item.Complexity
                } else {
                    # Estimer la complexitÃ© en fonction du type de fichier
                    $extension = [System.IO.Path]::GetExtension($Item.path)
                    switch ($extension) {
                        ".ps1" { return 3 }
                        ".psm1" { return 4 }
                        ".py" { return 3 }
                        ".cs" { return 3 }
                        ".js" { return 2 }
                        ".html" { return 1 }
                        ".css" { return 1 }
                        default { return 1 }
                    }
                }
            }
            "Changes" {
                # Utiliser le nombre de modifications comme poids
                if ($null -ne $Item.changes) {
                    return $Item.changes
                } elseif ($null -ne $Item.Changes) {
                    return $Item.Changes
                } elseif ($null -ne $Item.additions -and $null -ne $Item.deletions) {
                    return $Item.additions + $Item.deletions
                } elseif ($null -ne $Item.Additions -and $null -ne $Item.Deletions) {
                    return $Item.Additions + $Item.Deletions
                } else {
                    return 1
                }
            }
            "Custom" {
                # Utiliser une propriÃ©tÃ© personnalisÃ©e comme poids
                if ($null -ne $Item.$WeightProperty) {
                    return $Item.$WeightProperty
                } else {
                    return 1
                }
            }
            default {
                return 1
            }
        }
    } catch {
        Write-Warning "Erreur lors du calcul du poids pour l'Ã©lÃ©ment: $_"
        return 1
    }
}

# Point d'entrÃ©e principal
try {
    # VÃ©rifier si le fichier d'entrÃ©e existe
    if (-not (Test-Path -Path $InputPath)) {
        Write-Error "Le fichier d'entrÃ©e n'existe pas: $InputPath"
        exit 1
    }

    # Charger les Ã©lÃ©ments Ã  partir du fichier d'entrÃ©e
    $items = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
    if ($null -eq $items) {
        Write-Error "Impossible de charger les Ã©lÃ©ments Ã  partir du fichier d'entrÃ©e."
        exit 1
    }

    # Convertir en tableau si nÃ©cessaire
    if ($items -isnot [array]) {
        $items = @($items)
    }

    # Afficher des informations sur les Ã©lÃ©ments
    Write-Host "Ã‰lÃ©ments chargÃ©s: $($items.Count)" -ForegroundColor Cyan

    # Calculer les poids si nÃ©cessaire
    if ($CalculateWeights) {
        Write-Host "Calcul des poids avec la fonction: $WeightFunction" -ForegroundColor Cyan
        
        foreach ($item in $items) {
            $weight = Get-ItemWeight -Item $item -Function $WeightFunction
            $item | Add-Member -MemberType NoteProperty -Name $WeightProperty -Value $weight -Force
        }
    }

    # DÃ©terminer le nombre de parties
    $effectiveChunkCount = $ChunkCount
    if ($effectiveChunkCount -le 0) {
        $effectiveChunkCount = [System.Environment]::ProcessorCount
    }
    
    # Limiter le nombre de parties
    $effectiveChunkCount = [Math]::Min($effectiveChunkCount, $items.Count)
    $effectiveChunkCount = [Math]::Max($effectiveChunkCount, 1)
    
    Write-Host "Division de $($items.Count) Ã©lÃ©ments en $effectiveChunkCount parties..." -ForegroundColor Cyan

    # CrÃ©er une fonction de poids pour Split-AnalysisWorkload
    $weightFunction = {
        param($item)
        if ($null -ne $item.$WeightProperty) {
            return $item.$WeightProperty
        } else {
            return 1
        }
    }

    # Diviser les Ã©lÃ©ments
    $chunks = Split-AnalysisWorkload -Items $items -ChunkCount $effectiveChunkCount -WeightFunction $weightFunction

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # CrÃ©er l'objet de rÃ©sultat
    $result = [PSCustomObject]@{
        TotalItems = $items.Count
        ChunkCount = $chunks.Count
        WeightFunction = $WeightFunction
        WeightProperty = $WeightProperty
        Chunks = @()
    }

    # Ajouter des informations sur chaque partie
    for ($i = 0; $i -lt $chunks.Count; $i++) {
        $chunk = $chunks[$i]
        $totalWeight = ($chunk | ForEach-Object { & $weightFunction $_ } | Measure-Object -Sum).Sum
        
        $result.Chunks += [PSCustomObject]@{
            Index = $i
            ItemCount = $chunk.Count
            TotalWeight = $totalWeight
            Items = $chunk
        }
    }

    # Enregistrer le rÃ©sultat
    $result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8

    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© de la division:" -ForegroundColor Cyan
    Write-Host "  Ã‰lÃ©ments totaux: $($items.Count)" -ForegroundColor White
    Write-Host "  Parties crÃ©Ã©es: $($chunks.Count)" -ForegroundColor White
    
    for ($i = 0; $i -lt $result.Chunks.Count; $i++) {
        $chunk = $result.Chunks[$i]
        Write-Host "  Partie $($i + 1): $($chunk.ItemCount) Ã©lÃ©ments, poids total: $($chunk.TotalWeight)" -ForegroundColor White
    }
    
    Write-Host "  RÃ©sultat enregistrÃ©: $OutputPath" -ForegroundColor White

    # Retourner le rÃ©sultat
    return $result
} catch {
    Write-Error "Erreur lors de la division de la charge de travail: $_"
    exit 1
}
