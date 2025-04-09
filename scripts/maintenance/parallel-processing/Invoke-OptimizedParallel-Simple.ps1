<#
.SYNOPSIS
    Exécute un traitement parallèle optimisé en utilisant des Runspace Pools.
.DESCRIPTION
    Ce script fournit une fonction pour exécuter un traitement parallèle optimisé
    en utilisant des Runspace Pools, qui sont plus performants que les Jobs PowerShell
    traditionnels. Compatible avec PowerShell 5.1.
.PARAMETER ScriptBlock
    Le bloc de script à exécuter pour chaque élément d'entrée.
.PARAMETER InputObject
    Les objets à traiter en parallèle.
.PARAMETER MaxThreads
    Le nombre maximum de threads à utiliser. Par défaut, utilise le nombre de processeurs + 1.
.PARAMETER SharedVariables
    Hashtable de variables à partager avec tous les runspaces.
.EXAMPLE
    $files = Get-ChildItem -Path C:\Scripts -Filter *.ps1
    $results = $files | Invoke-OptimizedParallel -ScriptBlock {
        param($file)
        # Analyser le fichier
        $content = Get-Content -Path $file.FullName -Raw
        $lineCount = ($content -split "`n").Length
        return [PSCustomObject]@{
            File = $file.Name
            Lines = $lineCount
            Size = $file.Length
        }
    }
.NOTES
    Auteur: Augment Agent
    Version: 2.0
    Compatibilité: PowerShell 5.1 et supérieur
#>
function Invoke-OptimizedParallel {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$InputObject,

        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0,

        [Parameter(Mandatory = $false)]
        [hashtable]$SharedVariables = @{}
    )

    begin {
        # Déterminer le nombre optimal de threads si non spécifié
        if ($MaxThreads -le 0) {
            $processorCount = [Environment]::ProcessorCount
            $MaxThreads = $processorCount + 1
            Write-Verbose "Nombre de threads automatiquement défini à $MaxThreads (processeurs + 1)"
        }

        # Créer l'état de session initial pour partager des variables
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

        # Ajouter les variables partagées à l'état de session initial
        foreach ($key in $SharedVariables.Keys) {
            $value = $SharedVariables[$key]
            $variable = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new(
                $key, $value, "Variable partagée: $key"
            )
            $iss.Variables.Add($variable)
        }

        # Créer et ouvrir le pool de runspaces
        $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(
            1,                  # Nombre minimum de runspaces
            $MaxThreads,        # Nombre maximum de runspaces
            $iss,               # État de session initial
            $Host               # Hôte PowerShell actuel
        )
        $runspacePool.Open()

        # Initialiser les collections pour stocker les tâches et les résultats
        $runspaces = [System.Collections.Generic.List[hashtable]]::new()
        $results = [System.Collections.Generic.List[object]]::new()

        # Compteurs pour le suivi
        $totalItems = 0
        $processedItems = 0
    }

    process {
        foreach ($item in $InputObject) {
            $totalItems++

            # Créer une instance PowerShell pour cet élément
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter le script et les paramètres
            [void]$powershell.AddScript($ScriptBlock).AddArgument($item)

            # Démarrer l'exécution asynchrone
            $handle = $powershell.BeginInvoke()

            # Stocker les informations sur cette tâche
            $runspaces.Add(@{
                PowerShell = $powershell
                Handle = $handle
                Item = $item
            })

            # Vérifier si des tâches sont terminées
            for ($i = $runspaces.Count - 1; $i -ge 0; $i--) {
                $runspace = $runspaces[$i]
                if ($runspace.Handle.IsCompleted) {
                    $powershell = $runspace.PowerShell

                    try {
                        # Récupérer le résultat
                        $result = $powershell.EndInvoke($runspace.Handle)

                        # Créer un objet de résultat
                        $resultObject = [PSCustomObject]@{
                            InputObject = $runspace.Item
                            Success = $true
                            Result = $result
                            ErrorRecord = $null
                        }

                        $results.Add($resultObject)
                    }
                    catch {
                        # Créer un objet de résultat avec erreur
                        $resultObject = [PSCustomObject]@{
                            InputObject = $runspace.Item
                            Success = $false
                            Result = $null
                            ErrorRecord = $_
                        }

                        $results.Add($resultObject)
                    }
                    finally {
                        # Nettoyer les ressources
                        $powershell.Dispose()
                        $runspaces.RemoveAt($i)
                        $processedItems++
                    }
                }
            }
        }
    }

    end {
        # Attendre que toutes les tâches soient terminées
        while ($runspaces.Count -gt 0) {
            for ($i = $runspaces.Count - 1; $i -ge 0; $i--) {
                $runspace = $runspaces[$i]
                if ($runspace.Handle.IsCompleted) {
                    $powershell = $runspace.PowerShell

                    try {
                        # Récupérer le résultat
                        $result = $powershell.EndInvoke($runspace.Handle)

                        # Créer un objet de résultat
                        $resultObject = [PSCustomObject]@{
                            InputObject = $runspace.Item
                            Success = $true
                            Result = $result
                            ErrorRecord = $null
                        }

                        $results.Add($resultObject)
                    }
                    catch {
                        # Créer un objet de résultat avec erreur
                        $resultObject = [PSCustomObject]@{
                            InputObject = $runspace.Item
                            Success = $false
                            Result = $null
                            ErrorRecord = $_
                        }

                        $results.Add($resultObject)
                    }
                    finally {
                        # Nettoyer les ressources
                        $powershell.Dispose()
                        $runspaces.RemoveAt($i)
                        $processedItems++
                    }
                }
            }

            if ($runspaces.Count -gt 0) {
                Start-Sleep -Milliseconds 100
            }
        }

        # Nettoyer le pool de runspaces
        if ($null -ne $runspacePool) {
            $runspacePool.Close()
            $runspacePool.Dispose()
        }

        # Retourner les résultats
        return $results
    }
}

# Fonction exportée automatiquement lors de l'importation du script
