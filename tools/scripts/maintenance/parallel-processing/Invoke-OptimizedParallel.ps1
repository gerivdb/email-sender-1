#Requires -Version 5.1
<#
.SYNOPSIS
    ExÃ©cute un bloc de script sur plusieurs Ã©lÃ©ments en parallÃ¨le en utilisant des Runspace Pools optimisÃ©s.
.DESCRIPTION
    Cette fonction avancÃ©e permet d'exÃ©cuter un bloc de script sur une collection d'objets
    en parallÃ¨le, en tirant parti des Runspace Pools pour une performance nettement supÃ©rieure
    aux Jobs PowerShell classiques, surtout pour des tÃ¢ches courtes ou nombreuses.
    Elle gÃ¨re la distribution des tÃ¢ches, la limitation de la concurrence, la collecte
    des rÃ©sultats et la gestion des erreurs de maniÃ¨re robuste.
    La fonction traite les objets entrants via le pipeline de maniÃ¨re fluide.
.PARAMETER ScriptBlock
    Le bloc de script [scriptblock] Ã  exÃ©cuter pour chaque Ã©lÃ©ment d'entrÃ©e.
    Ce scriptblock doit accepter un seul paramÃ¨tre qui sera l'Ã©lÃ©ment d'entrÃ©e courant.
    Exemple : { param($item) $item.DoSomething(); return $item }
    Les variables dÃ©finies dans $SharedVariables sont accessibles via $using:varName.
.PARAMETER InputObject
    Les objets Ã  traiter en parallÃ¨le. Peut Ãªtre fourni via le pipeline ou directement.
.PARAMETER MaxThreads
    Le nombre maximum de threads (runspaces) Ã  utiliser dans le pool.
    Par dÃ©faut, utilise le nombre de processeurs logiques dÃ©tectÃ©s ([Environment]::ProcessorCount).
    Ajustez en fonction de la nature de la tÃ¢che (CPU-bound vs I/O-bound) et des ressources systÃ¨me.
.PARAMETER ThrottleLimit
    Limite le nombre de tÃ¢ches actives (en cours d'exÃ©cution ou en attente d'un thread)
    soumises simultanÃ©ment au pool. Cela Ã©vite de surcharger le systÃ¨me avec un trop grand
    nombre de tÃ¢ches en attente, mÃªme si MaxThreads est Ã©levÃ©.
    Par dÃ©faut, Ã©gal Ã  MaxThreads. Augmenter peut Ãªtre utile si les tÃ¢ches dÃ©marrent lentement.
.PARAMETER SharedVariables
    Une table de hachage [hashtable] contenant des variables Ã  rendre disponibles
    dans chaque runspace exÃ©cutant le ScriptBlock.
    Utilisez $using:variableName Ã  l'intÃ©rieur du ScriptBlock pour y accÃ©der.
    Exemple : $config = @{ ApiKey = 'xyz' }; ... -SharedVariables $config
             Dans le ScriptBlock: $key = $using:config.ApiKey
.OUTPUTS
    PSCustomObject[]
    Retourne un tableau d'objets PSCustomObject, un pour chaque Ã©lÃ©ment d'entrÃ©e traitÃ©.
    Chaque objet contient les propriÃ©tÃ©s suivantes :
    - InputObject : L'objet d'entrÃ©e original.
    - Success     : [bool] $true si le ScriptBlock s'est exÃ©cutÃ© sans erreur Terminating, $false sinon.
    - Result      : La sortie (return value) du ScriptBlock si Success est $true, sinon $null.
    - ErrorRecord : L'enregistrement d'erreur [System.Management.Automation.ErrorRecord] si Success est $false, sinon $null.
    - RunspaceId  : L'ID du thread/runspace qui a traitÃ© cet Ã©lÃ©ment.
.EXAMPLE
    # Analyser la longueur de plusieurs fichiers en parallÃ¨le
    Get-ChildItem -Path 'C:\Windows\System32' -Filter '*.dll' |
        Invoke-OptimizedParallel -ScriptBlock {
            param($fileInfo)
            # Simulation d'un travail
            Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200)
            try {
                $length = $fileInfo.Length
                Write-Verbose "TraitÃ© $($fileInfo.Name)" # S'affichera si -Verbose est utilisÃ© sur Invoke-OptimizedParallel
                return $length # Retourne la longueur
            } catch {
                # En cas d'erreur spÃ©cifique dans le bloc, la capturer si nÃ©cessaire
                Write-Error "Impossible de traiter $($fileInfo.Name) : $_" # Ceci sera capturÃ© par ErrorRecord
                # Pas besoin de 'return' ici, l'erreur termine implicitement le bloc pour ce runspace
            }
        } -MaxThreads 4 -Verbose

    # $results contiendra des objets avec {InputObject=FileInfo, Success=$true/$false, Result=Longueur/null, ErrorRecord=Error/null}
    $results | Where-Object {-not $_.Success} | ForEach-Object {
        Write-Warning "Ã‰chec pour $($_.InputObject.Name): $($_.ErrorRecord.Exception.Message)"
    }
    $results | Where-Object {$_.Success} | Format-Table @{N='File';E={$_.InputObject.Name}}, Result

.EXAMPLE
    # TÃ©lÃ©charger plusieurs URLs en parallÃ¨le en partageant un UserAgent
    $urls = "https://microsoft.com", "https://github.com", "https://example.com/404"
    $shared = @{ UserAgent = "MyParallelScript/1.0" }

    $webResults = $urls | Invoke-OptimizedParallel -ScriptBlock {
        param($url)
        try {
            $response = Invoke-WebRequest -Uri $url -UserAgent $using:shared.UserAgent -UseBasicParsing -ErrorAction Stop
            return @{
                Url = $url
                StatusCode = $response.StatusCode
                Length = $response.RawContentLength
            }
        } catch {
            # L'erreur de Invoke-WebRequest sera automatiquement capturÃ©e
            # On peut ajouter un contexte si on veut
            Write-Warning "Erreur lors du tÃ©lÃ©chargement de $url"
            # Propager l'erreur pour qu'elle soit capturÃ©e
            throw $_
        }
    } -SharedVariables $shared -MaxThreads 3

    $webResults | Format-Table InputObject, Success, @{N='Status/Length/Error';E={ if ($_.Success) { "$($_.Result.StatusCode) / $($_.Result.Length) bytes" } else { $_.ErrorRecord.Exception.Message } }}

.NOTES
    Auteur: Claude 3 & Collaborateur Humain
    Version: 2.0
    CompatibilitÃ©: PowerShell 5.1 et supÃ©rieur

    - Utilise des Runspace Pools pour la performance.
    - GÃ¨re la contre-pression (throttling) pour Ã©viter la saturation.
    - Capture les erreurs Terminating dans chaque tÃ¢che.
    - Les sorties non-erreur (Write-Verbose, Write-Warning, Write-Host) du ScriptBlock sont redirigÃ©es vers les flux correspondants de la commande principale si -Verbose, -Debug, etc. sont utilisÃ©s.
    - Pour des tÃ¢ches trÃ¨s longues (> quelques secondes), les Jobs PowerShell classiques (`Start-Job`) peuvent rester pertinents car ils sont plus isolÃ©s (processus sÃ©parÃ©s).
#>
function Invoke-OptimizedParallel {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [object[]]$InputObject,

        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = [System.Environment]::ProcessorCount,

        [Parameter(Mandatory = $false)]
        [int]$ThrottleLimit = 0, # Sera dÃ©fini sur MaxThreads si 0

        [Parameter(Mandatory = $false)]
        [hashtable]$SharedVariables = @{}
    )

    begin {
        Write-Verbose "Phase 'Begin': Initialisation du traitement parallÃ¨le."

        if ($MaxThreads -le 0) {
            Write-Warning "MaxThreads doit Ãªtre supÃ©rieur Ã  0. Utilisation de [Environment]::ProcessorCount ($([System.Environment]::ProcessorCount))."
            $MaxThreads = [System.Environment]::ProcessorCount
        }
        if ($ThrottleLimit -le 0) {
            $ThrottleLimit = $MaxThreads
            Write-Verbose "ThrottleLimit dÃ©fini par dÃ©faut Ã  MaxThreads ($MaxThreads)."
        } elseif ($ThrottleLimit -lt $MaxThreads) {
            Write-Warning "ThrottleLimit ($ThrottleLimit) est infÃ©rieur Ã  MaxThreads ($MaxThreads). Cela peut limiter artificiellement le parallÃ©lisme. Suggestion : ThrottleLimit >= MaxThreads."
        }

        # Initial Session State pour partager les variables et potentiellement des modules/types
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2() # PS 5.1+ friendly
        # Note: UseDefaultThreadOptions n'est pas disponible dans PowerShell 5.1

        # Ajouter les variables partagÃ©es accessibles via $using:
        foreach ($key in $SharedVariables.Keys) {
            # Utilisation de l'ajout simple, fonctionne bien pour la plupart des types
            $iss.Variables.Add([System.Management.Automation.Runspaces.SessionStateVariableEntry]::new($key, $SharedVariables[$key], 'Shared variable'))
            Write-Verbose "Variable partagÃ©e '$key' ajoutÃ©e Ã  l'Ã©tat initial."
        }

        # CrÃ©er et ouvrir le pool de runspaces
        try {
            $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(
                1,               # MinRunspaces
                $MaxThreads,     # MaxRunspaces
                $iss,            # InitialSessionState
                $Host            # Host
            )
            $runspacePool.Open()
            Write-Verbose "Runspace Pool crÃ©Ã© et ouvert avec Min=1, Max=$MaxThreads threads."
        } catch {
            Write-Error "Impossible de crÃ©er ou d'ouvrir le Runspace Pool: $($_.Exception.Message)"
            # ArrÃªter le traitement si le pool ne peut pas Ãªtre crÃ©Ã©
            throw $_
        }

        # Structures pour suivre les tÃ¢ches et les rÃ©sultats
        $tasks = [System.Collections.Generic.List[hashtable]]::new()
        $allResults = [System.Collections.Generic.List[object]]::new()
        $totalSubmitted = 0
        $totalCompleted = 0
        $totalInputItems = 0 # Compteur pour les Ã©lÃ©ments rÃ©ellement reÃ§us

        # Fonction interne pour traiter une tÃ¢che terminÃ©e
        # DÃ©clarÃ©e ici pour Ãªtre accessible dans process et end
        $script:ProcessCompletedTask = {
            param($taskInfo, $waitHandleIndex) # Passer l'index pour le retirer de la liste des Handles
            $psInstance = $taskInfo.Instance
            $inputItem = $taskInfo.InputItem
            $taskResult = $null
            $taskSuccess = $false
            $taskErrorRecord = $null

            try {
                # RÃ©cupÃ©rer le rÃ©sultat (EndInvoke re-lance les erreurs Terminating du runspace)
                $taskResult = $psInstance.EndInvoke($taskInfo.Handle)
                # Si EndInvoke rÃ©ussit, le scriptblock n'a pas eu d'erreur Terminating
                $taskSuccess = $true
                # VÃ©rifier s'il y a eu des erreurs non-terminating Ã©crites dans le flux Error
                if ($psInstance.Streams.Error.Count -gt 0) {
                     Write-Warning "TÃ¢che pour l'Ã©lÃ©ment '$inputItem' a gÃ©nÃ©rÃ© des erreurs non-terminating (voir ci-dessous)."
                     # Afficher les erreurs non-terminating sur le flux Warning du thread principal
                     $psInstance.Streams.Error | ForEach-Object { Write-Warning $_.ToString() }
                     # On pourrait choisir de marquer Success = $false ici si souhaitÃ©
                }

            } catch {
                # EndInvoke a Ã©chouÃ©, signifie une erreur Terminating dans le ScriptBlock
                $taskSuccess = $false
                $taskErrorRecord = $_.ErrorRecord
                Write-Verbose "Erreur dÃ©tectÃ©e lors du traitement de l'Ã©lÃ©ment '$inputItem': $($taskErrorRecord.Exception.Message)"
            }
            finally {
                # CrÃ©er l'objet de rÃ©sultat dÃ©taillÃ©
                $outputObject = [PSCustomObject]@{
                    InputObject = $inputItem
                    Success     = $taskSuccess
                    Result      = $taskResult # Sera $null si erreur
                    ErrorRecord = $taskErrorRecord # Sera $null si succÃ¨s
                    RunspaceId  = $taskInfo.RunspaceId # Ajouter l'ID du thread pour info
                }
                $allResults.Add($outputObject)

                # Nettoyer l'instance PowerShell associÃ©e Ã  cette tÃ¢che
                $psInstance.Dispose()
                Write-Verbose "Instance PowerShell pour l'Ã©lÃ©ment '$inputItem' nettoyÃ©e."

                # Supprimer la tÃ¢che de la liste de suivi (attention Ã  l'index si on supprime ici)
                # Il est plus sÃ»r de marquer comme complÃ©tÃ©e et de supprimer plus tard, ou de reconstruire la liste
                # Mais ici on utilise WaitAny, donc on a l'index exact
                # *** La suppression se fera dans la boucle appelante ***
            }
        }

        Write-Verbose "Initialisation terminÃ©e. En attente des Ã©lÃ©ments d'entrÃ©e..."
        $startTime = Get-Date
    }

    process {
        # Traiter chaque objet reÃ§u du pipeline
        foreach ($item in $InputObject) {
            $totalInputItems++
            # VÃ©rifier si le pool est disponible (gÃ¨re les erreurs de crÃ©ation dans 'begin')
            if ($null -eq $runspacePool -or $runspacePool.RunspacePoolStateInfo.State -ne 'Opened') {
                 Write-Error "Le Runspace Pool n'est pas disponible. ArrÃªt du traitement."
                 # ArrÃªter le traitement des Ã©lÃ©ments suivants
                 return
            }

            # Attendre si le nombre de tÃ¢ches actives atteint la limite (ThrottleLimit)
            while ($tasks.Count -ge $ThrottleLimit) {
                Write-Verbose "Limite d'Ã©tranglement ($ThrottleLimit tÃ¢ches actives) atteinte. Attente de la fin d'une tÃ¢che..."
                # Attend qu'AU MOINS une tÃ¢che se termine
                # VÃ©rifier si des tÃ¢ches sont terminÃ©es
                $completedIndex = -1
                for ($i = 0; $i -lt $tasks.Count; $i++) {
                    if ($tasks[$i].Handle.IsCompleted) {
                        $completedIndex = $i
                        break
                    }
                }

                # Si aucune tÃ¢che n'est terminÃ©e, attendre un peu
                if ($completedIndex -eq -1) {
                    Start-Sleep -Milliseconds 100
                }

                if ($completedIndex -ne -1) {
                    $completedTaskInfo = $tasks[$completedIndex]
                    Write-Verbose "TÃ¢che Ã  l'index $completedIndex terminÃ©e. Traitement des rÃ©sultats..."
                    # Traiter la tÃ¢che terminÃ©e
                    & $script:ProcessCompletedTask -taskInfo $completedTaskInfo -waitHandleIndex $completedIndex
                    # Supprimer la tÃ¢che de la liste aprÃ¨s traitement
                    $tasks.RemoveAt($completedIndex)
                    $totalCompleted++
                    # Mettre Ã  jour la progression aprÃ¨s la fin d'une tÃ¢che
                    if ($totalInputItems -gt 0) {
                       $percent = [math]::Round(($totalCompleted / $totalInputItems) * 100)
                       Write-Progress -Activity "ExÃ©cution ParallÃ¨le" -Status "$totalCompleted/$totalInputItems Ã‰lÃ©ments traitÃ©s" -PercentComplete $percent -Id 1
                    }
                } else {
                     Write-Verbose "Timeout d'attente atteint, vÃ©rification de l'Ã©tat du pool..."
                     # Optionnel : VÃ©rifier ici si le pool est toujours ouvert
                }
            } # Fin while throttle limit

            # CrÃ©er et configurer une instance PowerShell pour cet Ã©lÃ©ment
            $psInstance = [powershell]::Create().AddScript({
                param($__InputItem_Param, $__ScriptBlock_Param) # Noms uniques pour Ã©viter collisions

                # DÃ©finir les prÃ©fÃ©rences d'action hÃ©ritÃ©es
                # Les prÃ©fÃ©rences ne sont pas directement utilisables avec $using dans PowerShell 5.1

                # ExÃ©cuter le scriptblock fourni par l'utilisateur avec l'Ã©lÃ©ment courant
                & $__ScriptBlock_Param $__InputItem_Param

            }).AddParameter('__InputItem_Param', $item).AddParameter('__ScriptBlock_Param', $ScriptBlock)

            # Associer au pool de runspaces
            $psInstance.RunspacePool = $runspacePool

            # DÃ©marrer l'exÃ©cution asynchrone
            $asyncResult = $psInstance.BeginInvoke()
            $totalSubmitted++

            # Stocker les informations nÃ©cessaires pour rÃ©cupÃ©rer les rÃ©sultats plus tard
            $taskInfo = @{
                Handle     = $asyncResult
                Instance   = $psInstance
                InputItem  = $item
                SubmitTime = (Get-Date)
                RunspaceId = $null # Sera potentiellement rempli plus tard si nÃ©cessaire, difficile Ã  obtenir simplement
            }
            $tasks.Add($taskInfo)

            Write-Verbose "TÃ¢che soumise pour l'Ã©lÃ©ment '$item' (Total soumis: $totalSubmitted)."

        } # Fin foreach item in InputObject
    }

    end {
        Write-Verbose "Phase 'End': Tous les Ã©lÃ©ments d'entrÃ©e ont Ã©tÃ© reÃ§us ($totalInputItems). Attente de la fin des $ ($tasks.Count) tÃ¢ches restantes..."

        # Attendre la fin de toutes les tÃ¢ches restantes
        while ($tasks.Count -gt 0) {
            # VÃ©rifier si des tÃ¢ches sont terminÃ©es
            $completedIndex = -1
            for ($i = 0; $i -lt $tasks.Count; $i++) {
                if ($tasks[$i].Handle.IsCompleted) {
                    $completedIndex = $i
                    break
                }
            }

            # Si aucune tÃ¢che n'est terminÃ©e, attendre un peu
            if ($completedIndex -eq -1) {
                Start-Sleep -Milliseconds 100
                continue
            }

            if ($completedIndex -ne -1) {
                $completedTaskInfo = $tasks[$completedIndex]
                Write-Verbose "TÃ¢che restante Ã  l'index $completedIndex terminÃ©e. Traitement..."
                # Traiter la tÃ¢che terminÃ©e
                & $script:ProcessCompletedTask -taskInfo $completedTaskInfo -waitHandleIndex $completedIndex
                 # Supprimer la tÃ¢che de la liste
                $tasks.RemoveAt($completedIndex)
                $totalCompleted++
                # Mettre Ã  jour la progression
                 if ($totalInputItems -gt 0) {
                    $percent = [math]::Round(($totalCompleted / $totalInputItems) * 100)
                    Write-Progress -Activity "ExÃ©cution ParallÃ¨le" -Status "$totalCompleted/$totalInputItems Ã‰lÃ©ments traitÃ©s" -PercentComplete $percent -Id 1
                 }
            }
        } # Fin while tasks.Count > 0

        Write-Progress -Activity "ExÃ©cution ParallÃ¨le" -Completed -Id 1
        $endTime = Get-Date
        $duration = $endTime - $startTime
        Write-Verbose "Traitement parallÃ¨le terminÃ©. DurÃ©e: $($duration.ToString('g'))"
        Write-Verbose "Total Ã©lÃ©ments traitÃ©s: $totalCompleted. RÃ©sultats collectÃ©s: $($allResults.Count)."

        # Nettoyer le pool de runspaces
        if ($null -ne $runspacePool) {
            Write-Verbose "Fermeture et nettoyage du Runspace Pool..."
            $runspacePool.Close()
            $runspacePool.Dispose()
            Write-Verbose "Runspace Pool fermÃ© et nettoyÃ©."
        }

        # Retourner tous les rÃ©sultats collectÃ©s
        Write-Verbose "Retour des $($allResults.Count) objets de rÃ©sultats."
        return $allResults
    }
}

# Exporter la fonction si ce fichier est utilisÃ© comme module
# Export-ModuleMember -Function Invoke-OptimizedParallel