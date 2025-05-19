# Implémentation originale de Wait-ForCompletedRunspace (sans délai adaptatif ni vérification par lots)
# Cette fonction est utilisée pour les tests de performance comparatifs

function Wait-ForCompletedRunspaceOriginal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [object[]]$Runspaces,

        [Parameter(Mandatory = $false)]
        [switch]$WaitForAll,

        [Parameter(Mandatory = $false)]
        [switch]$NoProgress,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = 300,

        [Parameter(Mandatory = $false)]
        [int]$SleepMilliseconds = 50,

        [Parameter(Mandatory = $false)]
        [switch]$CleanupOnTimeout
    )

    begin {
        # Initialiser les variables
        $completedRunspaces = [System.Collections.Generic.List[object]]::new()
        $timeout = [datetime]::Now.AddSeconds($TimeoutSeconds)
        $processedRunspaces = 0
        $ActivityName = "Attente des runspaces"

        # Convertir les runspaces en liste si nécessaire
        if ($Runspaces -is [System.Collections.IEnumerable] -and $Runspaces -isnot [System.Collections.Generic.List[object]]) {
            Write-Verbose "Runspaces implémente IEnumerable. Conversion en List<PSObject>."
            $runspacesToProcess = [System.Collections.Generic.List[object]]::new()
            foreach ($runspace in $Runspaces) {
                $runspacesToProcess.Add($runspace)
            }
        }
        else {
            $runspacesToProcess = $Runspaces
        }

        $totalRunspaces = $runspacesToProcess.Count
        Write-Verbose "Nombre total de runspaces à traiter après conversion : $totalRunspaces"
        Write-Verbose "Attente de $totalRunspaces runspaces..."

        # Afficher la barre de progression
        if (-not $NoProgress -and $totalRunspaces -gt 0) {
            $progressParams = @{
                Activity        = $ActivityName
                Status          = "Attente de $totalRunspaces runspaces..."
                PercentComplete = 0
            }
            Write-Progress @progressParams
        }
    }

    process {
        # Attendre les runspaces
        $activeRunspaces = $runspacesToProcess.Count

        while ($activeRunspaces -gt 0 -and [datetime]::Now -lt $timeout) {
            # Vérifier les runspaces terminés
            for ($i = 0; $i -lt $runspacesToProcess.Count; $i++) {
                $runspace = $runspacesToProcess[$i]

                if ($null -ne $runspace -and $null -ne $runspace.Handle -and $runspace.Handle.IsCompleted) {
                    # Ajouter à la liste des runspaces complétés
                    $completedRunspaces.Add($runspace)

                    # Supprimer de la liste des runspaces actifs
                    $runspacesToProcess.RemoveAt($i)
                    $i--
                    $activeRunspaces--
                    $processedRunspaces++

                    # Mettre à jour la barre de progression
                    if (-not $NoProgress -and $totalRunspaces -gt 0) {
                        $percentComplete = [Math]::Min(100, [Math]::Floor(($processedRunspaces / $totalRunspaces) * 100))
                        $progressParams = @{
                            Activity        = $ActivityName
                            Status          = "Runspace $processedRunspaces sur $totalRunspaces complété"
                            PercentComplete = $percentComplete
                        }
                        Write-Progress @progressParams
                    }

                    # Si on n'attend pas tous les runspaces, retourner immédiatement
                    if (-not $WaitForAll) {
                        if (-not $NoProgress) {
                            Write-Progress -Activity $ActivityName -Completed
                        }

                        # Forcer la sortie de la boucle
                        break
                    }
                }
            }

            # Pause pour éviter de surcharger le CPU
            Start-Sleep -Milliseconds $SleepMilliseconds

            # Vérifier si on a atteint le timeout
            if ([datetime]::Now -ge $timeout -and $activeRunspaces -gt 0) {
                Write-Warning "Timeout atteint. $activeRunspaces runspaces toujours actifs."

                # Nettoyer les runspaces non complétés si demandé
                if ($CleanupOnTimeout) {
                    Write-Verbose "Nettoyage des runspaces non complétés après timeout..."
                    for ($i = 0; $i -lt $runspacesToProcess.Count; $i++) {
                        $runspace = $runspacesToProcess[$i]
                        if ($null -ne $runspace -and $null -ne $runspace.PowerShell) {
                            try {
                                $runspace.PowerShell.Stop()
                                $runspace.PowerShell.Dispose()
                            }
                            catch {
                                Write-Warning "Erreur lors du nettoyage du runspace $i : $_"
                            }
                        }
                    }
                }

                break
            }
        }

        # Terminer la barre de progression
        if (-not $NoProgress) {
            Write-Progress -Activity $ActivityName -Completed
        }

        # Afficher le nombre de runspaces complétés
        Write-Verbose "$processedRunspaces runspaces complétés sur $totalRunspaces."
    }

    end {
        # Retourner les runspaces complétés
        $result = [PSCustomObject]@{
            Count   = $completedRunspaces.Count
            Results = $completedRunspaces
        }

        Write-Verbose "Type de retour final: $($result.Results.GetType().FullName), Count: $($result.Count)"
        return $result
    }
}
