#Requires -Version 5.1
<#
.SYNOPSIS
    Divise une charge de travail d'analyse en parties équilibrées.

.DESCRIPTION
    Ce script divise une charge de travail d'analyse en parties équilibrées
    pour une exécution parallèle efficace, en tenant compte de la complexité
    des éléments à analyser.

.PARAMETER InputPath
    Le chemin du fichier d'entrée contenant les éléments à diviser.
    Le fichier doit être au format JSON.

.PARAMETER OutputPath
    Le chemin où enregistrer les résultats de la division.
    Par défaut: "workloads\split_workload.json"

.PARAMETER ChunkCount
    Le nombre de parties à créer.
    Par défaut: nombre de processeurs logiques

.PARAMETER WeightProperty
    Le nom de la propriété à utiliser comme poids pour la répartition.
    Par défaut: "Weight"

.PARAMETER CalculateWeights
    Indique s'il faut calculer les poids des éléments.
    Par défaut: $false

.PARAMETER WeightFunction
    Le nom de la fonction à utiliser pour calculer les poids.
    Valeurs possibles: "Size", "Complexity", "Changes", "Custom"
    Par défaut: "Changes"

.EXAMPLE
    .\Split-AnalysisWorkload.ps1 -InputPath "files_to_analyze.json" -ChunkCount 8
    Divise les fichiers en 8 parties équilibrées.

.EXAMPLE
    .\Split-AnalysisWorkload.ps1 -InputPath "files_to_analyze.json" -CalculateWeights -WeightFunction "Complexity"
    Divise les fichiers en utilisant la complexité comme poids.

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

# Importer le module de parallélisation
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\ParallelPRAnalysis.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module ParallelPRAnalysis non trouvé à l'emplacement: $modulePath"
    exit 1
}

# Fonction pour calculer le poids d'un élément
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
                # Utiliser une estimation de la complexité comme poids
                if ($null -ne $Item.complexity) {
                    return $Item.complexity
                } elseif ($null -ne $Item.Complexity) {
                    return $Item.Complexity
                } else {
                    # Estimer la complexité en fonction du type de fichier
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
                # Utiliser une propriété personnalisée comme poids
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
        Write-Warning "Erreur lors du calcul du poids pour l'élément: $_"
        return 1
    }
}

# Point d'entrée principal
try {
    # Vérifier si le fichier d'entrée existe
    if (-not (Test-Path -Path $InputPath)) {
        Write-Error "Le fichier d'entrée n'existe pas: $InputPath"
        exit 1
    }

    # Charger les éléments à partir du fichier d'entrée
    $items = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
    if ($null -eq $items) {
        Write-Error "Impossible de charger les éléments à partir du fichier d'entrée."
        exit 1
    }

    # Convertir en tableau si nécessaire
    if ($items -isnot [array]) {
        $items = @($items)
    }

    # Afficher des informations sur les éléments
    Write-Host "Éléments chargés: $($items.Count)" -ForegroundColor Cyan

    # Calculer les poids si nécessaire
    if ($CalculateWeights) {
        Write-Host "Calcul des poids avec la fonction: $WeightFunction" -ForegroundColor Cyan
        
        foreach ($item in $items) {
            $weight = Get-ItemWeight -Item $item -Function $WeightFunction
            $item | Add-Member -MemberType NoteProperty -Name $WeightProperty -Value $weight -Force
        }
    }

    # Déterminer le nombre de parties
    $effectiveChunkCount = $ChunkCount
    if ($effectiveChunkCount -le 0) {
        $effectiveChunkCount = [System.Environment]::ProcessorCount
    }
    
    # Limiter le nombre de parties
    $effectiveChunkCount = [Math]::Min($effectiveChunkCount, $items.Count)
    $effectiveChunkCount = [Math]::Max($effectiveChunkCount, 1)
    
    Write-Host "Division de $($items.Count) éléments en $effectiveChunkCount parties..." -ForegroundColor Cyan

    # Créer une fonction de poids pour Split-AnalysisWorkload
    $weightFunction = {
        param($item)
        if ($null -ne $item.$WeightProperty) {
            return $item.$WeightProperty
        } else {
            return 1
        }
    }

    # Diviser les éléments
    $chunks = Split-AnalysisWorkload -Items $items -ChunkCount $effectiveChunkCount -WeightFunction $weightFunction

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Créer l'objet de résultat
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

    # Enregistrer le résultat
    $result | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8

    # Afficher un résumé
    Write-Host "`nRésumé de la division:" -ForegroundColor Cyan
    Write-Host "  Éléments totaux: $($items.Count)" -ForegroundColor White
    Write-Host "  Parties créées: $($chunks.Count)" -ForegroundColor White
    
    for ($i = 0; $i -lt $result.Chunks.Count; $i++) {
        $chunk = $result.Chunks[$i]
        Write-Host "  Partie $($i + 1): $($chunk.ItemCount) éléments, poids total: $($chunk.TotalWeight)" -ForegroundColor White
    }
    
    Write-Host "  Résultat enregistré: $OutputPath" -ForegroundColor White

    # Retourner le résultat
    return $result
} catch {
    Write-Error "Erreur lors de la division de la charge de travail: $_"
    exit 1
}
