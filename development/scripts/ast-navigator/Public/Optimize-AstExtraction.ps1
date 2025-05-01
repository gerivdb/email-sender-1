#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise les performances des fonctions d'extraction AST pour les grands scripts.
.DESCRIPTION
    Cette fonction fournit des optimisations pour améliorer les performances des fonctions
    d'extraction AST lors du traitement de grands scripts PowerShell. Elle implémente
    des techniques comme la mise en cache, le traitement par lots et la limitation de profondeur.
.PARAMETER Ast
    L'objet AST (Abstract Syntax Tree) à analyser.
.PARAMETER NodeType
    Le type de nœud AST à extraire (FunctionDefinition, Parameter, Variable, Command, etc.).
.PARAMETER MaxDepth
    La profondeur maximale de l'arbre AST à parcourir. Utile pour limiter l'analyse des grands scripts.
.PARAMETER BatchSize
    La taille des lots pour le traitement par lots. Utile pour optimiser l'utilisation de la mémoire.
.PARAMETER UseCache
    Indique si le cache doit être utilisé pour stocker et récupérer les résultats d'extraction.
.PARAMETER CacheTimeout
    Durée de validité du cache en minutes. Par défaut: 60 minutes.
.EXAMPLE
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(".\MonScript.ps1", [ref]$null, [ref]$null)
    $functions = Optimize-AstExtraction -Ast $ast -NodeType "FunctionDefinition" -MaxDepth 5 -UseCache
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2023-05-01
#>
function Optimize-AstExtraction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,

        [Parameter(Mandatory = $true)]
        [ValidateSet("FunctionDefinition", "Parameter", "Variable", "Command", "All")]
        [string]$NodeType,

        [Parameter(Mandatory = $false)]
        [int]$MaxDepth = 0,

        [Parameter(Mandatory = $false)]
        [int]$BatchSize = 0,

        [Parameter(Mandatory = $false)]
        [switch]$UseCache,

        [Parameter(Mandatory = $false)]
        [int]$CacheTimeout = 60
    )

    # Initialiser le cache si nécessaire
    if ($UseCache -and -not $script:AstExtractionCache) {
        $script:AstExtractionCache = @{}
        $script:AstExtractionCacheTimestamps = @{}
    }

    # Fonction pour générer une clé de cache unique
    function Get-CacheKey {
        param(
            [System.Management.Automation.Language.Ast]$Ast,
            [string]$NodeType,
            [int]$MaxDepth
        )

        # Utiliser le contenu du script et sa date de modification comme partie de la clé
        $scriptContent = $Ast.Extent.Text
        $scriptHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($scriptContent)
        )
        $scriptHashString = [System.BitConverter]::ToString($scriptHash).Replace("-", "")

        return "$scriptHashString-$NodeType-$MaxDepth"
    }

    # Vérifier si le résultat est dans le cache
    if ($UseCache) {
        $cacheKey = Get-CacheKey -Ast $Ast -NodeType $NodeType -MaxDepth $MaxDepth

        if ($script:AstExtractionCache.ContainsKey($cacheKey)) {
            $cacheTimestamp = $script:AstExtractionCacheTimestamps[$cacheKey]
            $cacheAge = (Get-Date) - $cacheTimestamp

            # Vérifier si le cache est encore valide
            if ($cacheAge.TotalMinutes -lt $CacheTimeout) {
                Write-Verbose "Résultat récupéré du cache pour $NodeType (âge: $($cacheAge.TotalMinutes) minutes)"
                return $script:AstExtractionCache[$cacheKey]
            } else {
                # Supprimer l'entrée de cache expirée
                $script:AstExtractionCache.Remove($cacheKey)
                $script:AstExtractionCacheTimestamps.Remove($cacheKey)
                Write-Verbose "Cache expiré pour $NodeType (âge: $($cacheAge.TotalMinutes) minutes)"
            }
        }
    }

    # Fonction pour traiter l'AST par lots
    function Process-AstInBatches {
        param(
            [System.Management.Automation.Language.Ast]$Ast,
            [string]$NodeType,
            [int]$MaxDepth,
            [int]$BatchSize
        )

        # Obtenir tous les nœuds à traiter
        $allNodes = @()

        # Fonction récursive pour collecter les nœuds
        function Collect-Nodes {
            param(
                [System.Management.Automation.Language.Ast]$CurrentAst,
                [int]$CurrentDepth = 0
            )

            if ($MaxDepth -gt 0 -and $CurrentDepth -gt $MaxDepth) {
                return
            }

            $allNodes += $CurrentAst

            foreach ($childAst in $CurrentAst.FindAll({ $true }, $false)) {
                Collect-Nodes -CurrentAst $childAst -CurrentDepth ($CurrentDepth + 1)
            }
        }

        Collect-Nodes -CurrentAst $Ast

        # Traiter les nœuds par lots
        $results = @()
        $currentBatch = @()
        $nodeCount = $allNodes.Count

        for ($i = 0; $i -lt $nodeCount; $i++) {
            $currentBatch += $allNodes[$i]

            if ($currentBatch.Count -ge $BatchSize -or $i -eq ($nodeCount - 1)) {
                # Traiter le lot actuel
                $batchResults = Process-NodeBatch -Nodes $currentBatch -NodeType $NodeType
                $results += $batchResults

                # Réinitialiser le lot
                $currentBatch = @()

                # Forcer le garbage collection pour libérer de la mémoire
                [System.GC]::Collect()
            }
        }

        return $results
    }

    # Fonction pour traiter un lot de nœuds
    function Process-NodeBatch {
        param(
            [System.Management.Automation.Language.Ast[]]$Nodes,
            [string]$NodeType
        )

        $results = @()

        foreach ($node in $Nodes) {
            # Filtrer selon le type de nœud
            switch ($NodeType) {
                "FunctionDefinition" {
                    if ($node -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
                        $results += $node
                    }
                }
                "Parameter" {
                    if ($node -is [System.Management.Automation.Language.ParameterAst]) {
                        $results += $node
                    }
                }
                "Variable" {
                    if ($node -is [System.Management.Automation.Language.VariableExpressionAst]) {
                        $results += $node
                    }
                }
                "Command" {
                    if ($node -is [System.Management.Automation.Language.CommandAst]) {
                        $results += $node
                    }
                }
                "All" {
                    $results += $node
                }
            }
        }

        return $results
    }

    # Fonction pour extraire les nœuds avec limitation de profondeur
    function Extract-NodesWithDepthLimit {
        param(
            [System.Management.Automation.Language.Ast]$Ast,
            [string]$NodeType,
            [int]$MaxDepth
        )

        # Définir le prédicat en fonction du type de nœud
        $predicate = {
            param($node)

            switch ($NodeType) {
                "FunctionDefinition" { return $node -is [System.Management.Automation.Language.FunctionDefinitionAst] }
                "Parameter" { return $node -is [System.Management.Automation.Language.ParameterAst] }
                "Variable" { return $node -is [System.Management.Automation.Language.VariableExpressionAst] }
                "Command" { return $node -is [System.Management.Automation.Language.CommandAst] }
                "All" { return $true }
            }
        }

        # Si MaxDepth est spécifié, utiliser une approche personnalisée
        if ($MaxDepth -gt 0) {
            $results = @()

            # Fonction récursive pour parcourir l'AST avec limite de profondeur
            function Find-NodesWithDepth {
                param(
                    [System.Management.Automation.Language.Ast]$CurrentAst,
                    [int]$CurrentDepth = 0
                )

                if ($CurrentDepth -gt $MaxDepth) {
                    return
                }

                # Vérifier si le nœud actuel correspond au prédicat
                if (& $predicate $CurrentAst) {
                    $results += $CurrentAst
                }

                # Parcourir les nœuds enfants
                foreach ($childAst in $CurrentAst.FindAll({ $true }, $false)) {
                    Find-NodesWithDepth -CurrentAst $childAst -CurrentDepth ($CurrentDepth + 1)
                }
            }

            Find-NodesWithDepth -CurrentAst $Ast
            return $results
        } else {
            # Utiliser la méthode standard FindAll si MaxDepth n'est pas spécifié
            return $Ast.FindAll($predicate, $true)
        }
    }

    # Exécuter l'extraction optimisée
    $result = $null

    try {
        # Mesurer les performances
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Choisir la méthode d'extraction en fonction des paramètres
        if ($BatchSize -gt 0) {
            Write-Verbose "Utilisation du traitement par lots (taille: $BatchSize)"
            $result = Process-AstInBatches -Ast $Ast -NodeType $NodeType -MaxDepth $MaxDepth -BatchSize $BatchSize
        } else {
            Write-Verbose "Utilisation de l'extraction avec limite de profondeur (max: $MaxDepth)"
            $result = Extract-NodesWithDepthLimit -Ast $Ast -NodeType $NodeType -MaxDepth $MaxDepth
        }

        $stopwatch.Stop()
        Write-Verbose "Extraction terminée en $($stopwatch.ElapsedMilliseconds) ms"

        # Stocker le résultat dans le cache si nécessaire
        if ($UseCache) {
            $cacheKey = Get-CacheKey -Ast $Ast -NodeType $NodeType -MaxDepth $MaxDepth
            $script:AstExtractionCache[$cacheKey] = $result
            $script:AstExtractionCacheTimestamps[$cacheKey] = Get-Date
            Write-Verbose "Résultat stocké dans le cache pour $NodeType"
        }

        return $result
    } catch {
        Write-Error "Erreur lors de l'extraction optimisée: $_"
        throw
    }
}

# Fonction pour nettoyer le cache d'extraction AST
function Clear-AstExtractionCache {
    [CmdletBinding()]
    param()

    if ($script:AstExtractionCache) {
        $cacheSize = $script:AstExtractionCache.Count
        $script:AstExtractionCache = @{}
        $script:AstExtractionCacheTimestamps = @{}
        Write-Verbose "Cache d'extraction AST nettoyé ($cacheSize entrées supprimées)"
    } else {
        Write-Verbose "Le cache d'extraction AST est déjà vide"
    }
}

# Fonction pour obtenir des statistiques sur le cache d'extraction AST
function Get-AstExtractionCacheStatistics {
    [CmdletBinding()]
    param()

    if (-not $script:AstExtractionCache) {
        return [PSCustomObject]@{
            Enabled     = $false
            EntryCount  = 0
            OldestEntry = $null
            NewestEntry = $null
            AverageAge  = 0
        }
    }

    $now = Get-Date
    $ages = @()
    $oldest = $now
    $newest = [DateTime]::MinValue

    foreach ($timestamp in $script:AstExtractionCacheTimestamps.Values) {
        $age = $now - $timestamp
        $ages += $age

        if ($timestamp -lt $oldest) {
            $oldest = $timestamp
        }

        if ($timestamp -gt $newest) {
            $newest = $timestamp
        }
    }

    $averageAge = if ($ages.Count -gt 0) {
        ($ages | Measure-Object -Property TotalMinutes -Average).Average
    } else {
        0
    }

    return [PSCustomObject]@{
        Enabled     = $true
        EntryCount  = $script:AstExtractionCache.Count
        OldestEntry = if ($oldest -ne $now) { $oldest } else { $null }
        NewestEntry = if ($newest -ne [DateTime]::MinValue) { $newest } else { $null }
        AverageAge  = $averageAge
    }
}

# Les fonctions sont exportées par le module
