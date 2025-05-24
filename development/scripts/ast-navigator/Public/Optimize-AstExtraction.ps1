#Requires -Version 5.1
<#
.SYNOPSIS
    Optimise les performances des fonctions d'extraction AST pour les grands scripts.
.DESCRIPTION
    Cette fonction fournit des optimisations pour amÃ©liorer les performances des fonctions
    d'extraction AST lors du traitement de grands scripts PowerShell. Elle implÃ©mente
    des techniques comme la mise en cache, le traitement par lots et la limitation de profondeur.
.PARAMETER Ast
    L'objet AST (Abstract Syntax Tree) Ã  analyser.
.PARAMETER NodeType
    Le type de nÅ“ud AST Ã  extraire (FunctionDefinition, Parameter, Variable, Command, etc.).
.PARAMETER MaxDepth
    La profondeur maximale de l'arbre AST Ã  parcourir. Utile pour limiter l'analyse des grands scripts.
.PARAMETER BatchSize
    La taille des lots pour le traitement par lots. Utile pour optimiser l'utilisation de la mÃ©moire.
.PARAMETER UseCache
    Indique si le cache doit Ãªtre utilisÃ© pour stocker et rÃ©cupÃ©rer les rÃ©sultats d'extraction.
.PARAMETER CacheTimeout
    DurÃ©e de validitÃ© du cache en minutes. Par dÃ©faut: 60 minutes.
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

    # Initialiser le cache si nÃ©cessaire
    if ($UseCache -and -not $script:AstExtractionCache) {
        $script:AstExtractionCache = @{}
        $script:AstExtractionCacheTimestamps = @{}
    }

    # Fonction pour gÃ©nÃ©rer une clÃ© de cache unique
    function Get-CacheKey {
        param(
            [System.Management.Automation.Language.Ast]$Ast,
            [string]$NodeType,
            [int]$MaxDepth
        )

        # Utiliser le contenu du script et sa date de modification comme partie de la clÃ©
        $scriptContent = $Ast.Extent.Text
        $scriptHash = [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($scriptContent)
        )
        $scriptHashString = [System.BitConverter]::ToString($scriptHash).Replace("-", "")

        return "$scriptHashString-$NodeType-$MaxDepth"
    }

    # VÃ©rifier si le rÃ©sultat est dans le cache
    if ($UseCache) {
        $cacheKey = Get-CacheKey -Ast $Ast -NodeType $NodeType -MaxDepth $MaxDepth

        if ($script:AstExtractionCache.ContainsKey($cacheKey)) {
            $cacheTimestamp = $script:AstExtractionCacheTimestamps[$cacheKey]
            $cacheAge = (Get-Date) - $cacheTimestamp

            # VÃ©rifier si le cache est encore valide
            if ($cacheAge.TotalMinutes -lt $CacheTimeout) {
                Write-Verbose "RÃ©sultat rÃ©cupÃ©rÃ© du cache pour $NodeType (Ã¢ge: $($cacheAge.TotalMinutes) minutes)"
                return $script:AstExtractionCache[$cacheKey]
            } else {
                # Supprimer l'entrÃ©e de cache expirÃ©e
                $script:AstExtractionCache.Remove($cacheKey)
                $script:AstExtractionCacheTimestamps.Remove($cacheKey)
                Write-Verbose "Cache expirÃ© pour $NodeType (Ã¢ge: $($cacheAge.TotalMinutes) minutes)"
            }
        }
    }

    # Fonction pour traiter l'AST par lots
    function Invoke-AstInBatches {
        param(
            [System.Management.Automation.Language.Ast]$Ast,
            [string]$NodeType,
            [int]$MaxDepth,
            [int]$BatchSize
        )

        # Obtenir tous les nÅ“uds Ã  traiter
        $allNodes = @()

        # Fonction rÃ©cursive pour collecter les nÅ“uds
        function Get-Nodes {
            param(
                [System.Management.Automation.Language.Ast]$CurrentAst,
                [int]$CurrentDepth = 0
            )

            if ($MaxDepth -gt 0 -and $CurrentDepth -gt $MaxDepth) {
                return
            }

            $allNodes += $CurrentAst

            foreach ($childAst in $CurrentAst.FindAll({ $true }, $false)) {
                Get-Nodes -CurrentAst $childAst -CurrentDepth ($CurrentDepth + 1)
            }
        }

        Get-Nodes -CurrentAst $Ast

        # Traiter les nÅ“uds par lots
        $results = @()
        $currentBatch = @()
        $nodeCount = $allNodes.Count

        for ($i = 0; $i -lt $nodeCount; $i++) {
            $currentBatch += $allNodes[$i]

            if ($currentBatch.Count -ge $BatchSize -or $i -eq ($nodeCount - 1)) {
                # Traiter le lot actuel
                $batchResults = Invoke-NodeBatch -Nodes $currentBatch -NodeType $NodeType
                $results += $batchResults

                # RÃ©initialiser le lot
                $currentBatch = @()

                # Forcer le garbage collection pour libÃ©rer de la mÃ©moire
                [System.GC]::Collect()
            }
        }

        return $results
    }

    # Fonction pour traiter un lot de nÅ“uds
    function Invoke-NodeBatch {
        param(
            [System.Management.Automation.Language.Ast[]]$Nodes,
            [string]$NodeType
        )

        $results = @()

        foreach ($node in $Nodes) {
            # Filtrer selon le type de nÅ“ud
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

    # Fonction pour extraire les nÅ“uds avec limitation de profondeur
    function Export-NodesWithDepthLimit {
        param(
            [System.Management.Automation.Language.Ast]$Ast,
            [string]$NodeType,
            [int]$MaxDepth
        )

        # DÃ©finir le prÃ©dicat en fonction du type de nÅ“ud
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

        # Si MaxDepth est spÃ©cifiÃ©, utiliser une approche personnalisÃ©e
        if ($MaxDepth -gt 0) {
            $results = @()

            # Fonction rÃ©cursive pour parcourir l'AST avec limite de profondeur
            function Find-NodesWithDepth {
                param(
                    [System.Management.Automation.Language.Ast]$CurrentAst,
                    [int]$CurrentDepth = 0
                )

                if ($CurrentDepth -gt $MaxDepth) {
                    return
                }

                # VÃ©rifier si le nÅ“ud actuel correspond au prÃ©dicat
                if (& $predicate $CurrentAst) {
                    $results += $CurrentAst
                }

                # Parcourir les nÅ“uds enfants
                foreach ($childAst in $CurrentAst.FindAll({ $true }, $false)) {
                    Find-NodesWithDepth -CurrentAst $childAst -CurrentDepth ($CurrentDepth + 1)
                }
            }

            Find-NodesWithDepth -CurrentAst $Ast
            return $results
        } else {
            # Utiliser la mÃ©thode standard FindAll si MaxDepth n'est pas spÃ©cifiÃ©
            return $Ast.FindAll($predicate, $true)
        }
    }

    # ExÃ©cuter l'extraction optimisÃ©e
    $result = $null

    try {
        # Mesurer les performances
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        # Choisir la mÃ©thode d'extraction en fonction des paramÃ¨tres
        if ($BatchSize -gt 0) {
            Write-Verbose "Utilisation du traitement par lots (taille: $BatchSize)"
            $result = Invoke-AstInBatches -Ast $Ast -NodeType $NodeType -MaxDepth $MaxDepth -BatchSize $BatchSize
        } else {
            Write-Verbose "Utilisation de l'extraction avec limite de profondeur (max: $MaxDepth)"
            $result = Export-NodesWithDepthLimit -Ast $Ast -NodeType $NodeType -MaxDepth $MaxDepth
        }

        $stopwatch.Stop()
        Write-Verbose "Extraction terminÃ©e en $($stopwatch.ElapsedMilliseconds) ms"

        # Stocker le rÃ©sultat dans le cache si nÃ©cessaire
        if ($UseCache) {
            $cacheKey = Get-CacheKey -Ast $Ast -NodeType $NodeType -MaxDepth $MaxDepth
            $script:AstExtractionCache[$cacheKey] = $result
            $script:AstExtractionCacheTimestamps[$cacheKey] = Get-Date
            Write-Verbose "RÃ©sultat stockÃ© dans le cache pour $NodeType"
        }

        return $result
    } catch {
        Write-Error "Erreur lors de l'extraction optimisÃ©e: $_"
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
        Write-Verbose "Cache d'extraction AST nettoyÃ© ($cacheSize entrÃ©es supprimÃ©es)"
    } else {
        Write-Verbose "Le cache d'extraction AST est dÃ©jÃ  vide"
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

# Les fonctions sont exportÃ©es par le module

