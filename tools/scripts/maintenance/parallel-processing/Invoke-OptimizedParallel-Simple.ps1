<#
.SYNOPSIS
    ExÃ©cute un traitement parallÃ¨le optimisÃ© en utilisant des Runspace Pools.
.DESCRIPTION
    Ce script fournit une fonction pour exÃ©cuter un traitement parallÃ¨le optimisÃ©
    en utilisant des Runspace Pools, qui sont plus performants que les Jobs PowerShell
    traditionnels. Compatible avec PowerShell 5.1.
.PARAMETER ScriptBlock
    Le bloc de script Ã  exÃ©cuter pour chaque Ã©lÃ©ment d'entrÃ©e.
.PARAMETER InputObject
    Les objets Ã  traiter en parallÃ¨le.
.PARAMETER MaxThreads
    Le nombre maximum de threads Ã  utiliser. Par dÃ©faut, utilise le nombre de processeurs + 1.
.PARAMETER SharedVariables
    Hashtable de variables Ã  partager avec tous les runspaces.
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
    CompatibilitÃ©: PowerShell 5.1 et supÃ©rieur
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
        # DÃ©terminer le nombre optimal de threads si non spÃ©cifiÃ©
        if ($MaxThreads -le 0) {
            $processorCount = [Environment]::ProcessorCount
            $MaxThreads = $processorCount + 1
            Write-Verbose "Nombre de threads automatiquement dÃ©fini Ã  $MaxThreads (processeurs + 1)"
        }

        # CrÃ©er l'Ã©tat de session initial pour partager des variables
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

        # Ajouter les variables partagÃ©es Ã  l'Ã©tat de session initial
        foreach ($key in $SharedVariables.Keys) {
            $value = $SharedVariables[$key]
            $variable = [System.Management.Automation.Runspaces.SessionStateVariableEntry]::new(
                $key, $value, "Variable partagÃ©e: $key"
            )
            $iss.Variables.Add($variable)
        }

        # CrÃ©er et ouvrir le pool de runspaces
        $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(
            1,                  # Nombre minimum de runspaces
            $MaxThreads,        # Nombre maximum de runspaces
            $iss,               # Ã‰tat de session initial
            $Host               # HÃ´te PowerShell actuel
        )
        $runspacePool.Open()

        # Initialiser les collections pour stocker les tÃ¢ches et les rÃ©sultats
        $runspaces = [System.Collections.Generic.List[hashtable]]::new()
        $results = [System.Collections.Generic.List[object]]::new()

        # Compteurs pour le suivi
        $totalItems = 0
        $processedItems = 0
    }

    process {
        foreach ($item in $InputObject) {
            $totalItems++

            # CrÃ©er une instance PowerShell pour cet Ã©lÃ©ment
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool

            # Ajouter le script et les paramÃ¨tres
            [void]$powershell.AddScript($ScriptBlock).AddArgument($item)

            # DÃ©marrer l'exÃ©cution asynchrone
            $handle = $powershell.BeginInvoke()

            # Stocker les informations sur cette tÃ¢che
            $runspaces.Add(@{
                PowerShell = $powershell
                Handle = $handle
                Item = $item
            })

            # VÃ©rifier si des tÃ¢ches sont terminÃ©es
            for ($i = $runspaces.Count - 1; $i -ge 0; $i--) {
                $runspace = $runspaces[$i]
                if ($runspace.Handle.IsCompleted) {
                    $powershell = $runspace.PowerShell

                    try {
                        # RÃ©cupÃ©rer le rÃ©sultat
                        $result = $powershell.EndInvoke($runspace.Handle)

                        # CrÃ©er un objet de rÃ©sultat
                        $resultObject = [PSCustomObject]@{
                            InputObject = $runspace.Item
                            Success = $true
                            Result = $result
                            ErrorRecord = $null
                        }

                        $results.Add($resultObject)
                    }
                    catch {
                        # CrÃ©er un objet de rÃ©sultat avec erreur
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
        # Attendre que toutes les tÃ¢ches soient terminÃ©es
        while ($runspaces.Count -gt 0) {
            for ($i = $runspaces.Count - 1; $i -ge 0; $i--) {
                $runspace = $runspaces[$i]
                if ($runspace.Handle.IsCompleted) {
                    $powershell = $runspace.PowerShell

                    try {
                        # RÃ©cupÃ©rer le rÃ©sultat
                        $result = $powershell.EndInvoke($runspace.Handle)

                        # CrÃ©er un objet de rÃ©sultat
                        $resultObject = [PSCustomObject]@{
                            InputObject = $runspace.Item
                            Success = $true
                            Result = $result
                            ErrorRecord = $null
                        }

                        $results.Add($resultObject)
                    }
                    catch {
                        # CrÃ©er un objet de rÃ©sultat avec erreur
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

        # Retourner les rÃ©sultats
        return $results
    }
}

# Fonction exportÃ©e automatiquement lors de l'importation du script
