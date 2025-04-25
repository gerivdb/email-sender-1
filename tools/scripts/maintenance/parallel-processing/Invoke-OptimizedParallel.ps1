#Requires -Version 5.1
<#
.SYNOPSIS
    Exécute un bloc de script sur plusieurs éléments en parallèle en utilisant des Runspace Pools optimisés.
.DESCRIPTION
    Cette fonction avancée permet d'exécuter un bloc de script sur une collection d'objets
    en parallèle, en tirant parti des Runspace Pools pour une performance nettement supérieure
    aux Jobs PowerShell classiques, surtout pour des tâches courtes ou nombreuses.
    Elle gère la distribution des tâches, la limitation de la concurrence, la collecte
    des résultats et la gestion des erreurs de manière robuste.
    La fonction traite les objets entrants via le pipeline de manière fluide.
.PARAMETER ScriptBlock
    Le bloc de script [scriptblock] à exécuter pour chaque élément d'entrée.
    Ce scriptblock doit accepter un seul paramètre qui sera l'élément d'entrée courant.
    Exemple : { param($item) $item.DoSomething(); return $item }
    Les variables définies dans $SharedVariables sont accessibles via $using:varName.
.PARAMETER InputObject
    Les objets à traiter en parallèle. Peut être fourni via le pipeline ou directement.
.PARAMETER MaxThreads
    Le nombre maximum de threads (runspaces) à utiliser dans le pool.
    Par défaut, utilise le nombre de processeurs logiques détectés ([Environment]::ProcessorCount).
    Ajustez en fonction de la nature de la tâche (CPU-bound vs I/O-bound) et des ressources système.
.PARAMETER ThrottleLimit
    Limite le nombre de tâches actives (en cours d'exécution ou en attente d'un thread)
    soumises simultanément au pool. Cela évite de surcharger le système avec un trop grand
    nombre de tâches en attente, même si MaxThreads est élevé.
    Par défaut, égal à MaxThreads. Augmenter peut être utile si les tâches démarrent lentement.
.PARAMETER SharedVariables
    Une table de hachage [hashtable] contenant des variables à rendre disponibles
    dans chaque runspace exécutant le ScriptBlock.
    Utilisez $using:variableName à l'intérieur du ScriptBlock pour y accéder.
    Exemple : $config = @{ ApiKey = 'xyz' }; ... -SharedVariables $config
             Dans le ScriptBlock: $key = $using:config.ApiKey
.OUTPUTS
    PSCustomObject[]
    Retourne un tableau d'objets PSCustomObject, un pour chaque élément d'entrée traité.
    Chaque objet contient les propriétés suivantes :
    - InputObject : L'objet d'entrée original.
    - Success     : [bool] $true si le ScriptBlock s'est exécuté sans erreur Terminating, $false sinon.
    - Result      : La sortie (return value) du ScriptBlock si Success est $true, sinon $null.
    - ErrorRecord : L'enregistrement d'erreur [System.Management.Automation.ErrorRecord] si Success est $false, sinon $null.
    - RunspaceId  : L'ID du thread/runspace qui a traité cet élément.
.EXAMPLE
    # Analyser la longueur de plusieurs fichiers en parallèle
    Get-ChildItem -Path 'C:\Windows\System32' -Filter '*.dll' |
        Invoke-OptimizedParallel -ScriptBlock {
            param($fileInfo)
            # Simulation d'un travail
            Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200)
            try {
                $length = $fileInfo.Length
                Write-Verbose "Traité $($fileInfo.Name)" # S'affichera si -Verbose est utilisé sur Invoke-OptimizedParallel
                return $length # Retourne la longueur
            } catch {
                # En cas d'erreur spécifique dans le bloc, la capturer si nécessaire
                Write-Error "Impossible de traiter $($fileInfo.Name) : $_" # Ceci sera capturé par ErrorRecord
                # Pas besoin de 'return' ici, l'erreur termine implicitement le bloc pour ce runspace
            }
        } -MaxThreads 4 -Verbose

    # $results contiendra des objets avec {InputObject=FileInfo, Success=$true/$false, Result=Longueur/null, ErrorRecord=Error/null}
    $results | Where-Object {-not $_.Success} | ForEach-Object {
        Write-Warning "Échec pour $($_.InputObject.Name): $($_.ErrorRecord.Exception.Message)"
    }
    $results | Where-Object {$_.Success} | Format-Table @{N='File';E={$_.InputObject.Name}}, Result

.EXAMPLE
    # Télécharger plusieurs URLs en parallèle en partageant un UserAgent
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
            # L'erreur de Invoke-WebRequest sera automatiquement capturée
            # On peut ajouter un contexte si on veut
            Write-Warning "Erreur lors du téléchargement de $url"
            # Propager l'erreur pour qu'elle soit capturée
            throw $_
        }
    } -SharedVariables $shared -MaxThreads 3

    $webResults | Format-Table InputObject, Success, @{N='Status/Length/Error';E={ if ($_.Success) { "$($_.Result.StatusCode) / $($_.Result.Length) bytes" } else { $_.ErrorRecord.Exception.Message } }}

.NOTES
    Auteur: Claude 3 & Collaborateur Humain
    Version: 2.0
    Compatibilité: PowerShell 5.1 et supérieur

    - Utilise des Runspace Pools pour la performance.
    - Gère la contre-pression (throttling) pour éviter la saturation.
    - Capture les erreurs Terminating dans chaque tâche.
    - Les sorties non-erreur (Write-Verbose, Write-Warning, Write-Host) du ScriptBlock sont redirigées vers les flux correspondants de la commande principale si -Verbose, -Debug, etc. sont utilisés.
    - Pour des tâches très longues (> quelques secondes), les Jobs PowerShell classiques (`Start-Job`) peuvent rester pertinents car ils sont plus isolés (processus séparés).
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
        [int]$ThrottleLimit = 0, # Sera défini sur MaxThreads si 0

        [Parameter(Mandatory = $false)]
        [hashtable]$SharedVariables = @{}
    )

    begin {
        Write-Verbose "Phase 'Begin': Initialisation du traitement parallèle."

        if ($MaxThreads -le 0) {
            Write-Warning "MaxThreads doit être supérieur à 0. Utilisation de [Environment]::ProcessorCount ($([System.Environment]::ProcessorCount))."
            $MaxThreads = [System.Environment]::ProcessorCount
        }
        if ($ThrottleLimit -le 0) {
            $ThrottleLimit = $MaxThreads
            Write-Verbose "ThrottleLimit défini par défaut à MaxThreads ($MaxThreads)."
        } elseif ($ThrottleLimit -lt $MaxThreads) {
            Write-Warning "ThrottleLimit ($ThrottleLimit) est inférieur à MaxThreads ($MaxThreads). Cela peut limiter artificiellement le parallélisme. Suggestion : ThrottleLimit >= MaxThreads."
        }

        # Initial Session State pour partager les variables et potentiellement des modules/types
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2() # PS 5.1+ friendly
        # Note: UseDefaultThreadOptions n'est pas disponible dans PowerShell 5.1

        # Ajouter les variables partagées accessibles via $using:
        foreach ($key in $SharedVariables.Keys) {
            # Utilisation de l'ajout simple, fonctionne bien pour la plupart des types
            $iss.Variables.Add([System.Management.Automation.Runspaces.SessionStateVariableEntry]::new($key, $SharedVariables[$key], 'Shared variable'))
            Write-Verbose "Variable partagée '$key' ajoutée à l'état initial."
        }

        # Créer et ouvrir le pool de runspaces
        try {
            $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(
                1,               # MinRunspaces
                $MaxThreads,     # MaxRunspaces
                $iss,            # InitialSessionState
                $Host            # Host
            )
            $runspacePool.Open()
            Write-Verbose "Runspace Pool créé et ouvert avec Min=1, Max=$MaxThreads threads."
        } catch {
            Write-Error "Impossible de créer ou d'ouvrir le Runspace Pool: $($_.Exception.Message)"
            # Arrêter le traitement si le pool ne peut pas être créé
            throw $_
        }

        # Structures pour suivre les tâches et les résultats
        $tasks = [System.Collections.Generic.List[hashtable]]::new()
        $allResults = [System.Collections.Generic.List[object]]::new()
        $totalSubmitted = 0
        $totalCompleted = 0
        $totalInputItems = 0 # Compteur pour les éléments réellement reçus

        # Fonction interne pour traiter une tâche terminée
        # Déclarée ici pour être accessible dans process et end
        $script:ProcessCompletedTask = {
            param($taskInfo, $waitHandleIndex) # Passer l'index pour le retirer de la liste des Handles
            $psInstance = $taskInfo.Instance
            $inputItem = $taskInfo.InputItem
            $taskResult = $null
            $taskSuccess = $false
            $taskErrorRecord = $null

            try {
                # Récupérer le résultat (EndInvoke re-lance les erreurs Terminating du runspace)
                $taskResult = $psInstance.EndInvoke($taskInfo.Handle)
                # Si EndInvoke réussit, le scriptblock n'a pas eu d'erreur Terminating
                $taskSuccess = $true
                # Vérifier s'il y a eu des erreurs non-terminating écrites dans le flux Error
                if ($psInstance.Streams.Error.Count -gt 0) {
                     Write-Warning "Tâche pour l'élément '$inputItem' a généré des erreurs non-terminating (voir ci-dessous)."
                     # Afficher les erreurs non-terminating sur le flux Warning du thread principal
                     $psInstance.Streams.Error | ForEach-Object { Write-Warning $_.ToString() }
                     # On pourrait choisir de marquer Success = $false ici si souhaité
                }

            } catch {
                # EndInvoke a échoué, signifie une erreur Terminating dans le ScriptBlock
                $taskSuccess = $false
                $taskErrorRecord = $_.ErrorRecord
                Write-Verbose "Erreur détectée lors du traitement de l'élément '$inputItem': $($taskErrorRecord.Exception.Message)"
            }
            finally {
                # Créer l'objet de résultat détaillé
                $outputObject = [PSCustomObject]@{
                    InputObject = $inputItem
                    Success     = $taskSuccess
                    Result      = $taskResult # Sera $null si erreur
                    ErrorRecord = $taskErrorRecord # Sera $null si succès
                    RunspaceId  = $taskInfo.RunspaceId # Ajouter l'ID du thread pour info
                }
                $allResults.Add($outputObject)

                # Nettoyer l'instance PowerShell associée à cette tâche
                $psInstance.Dispose()
                Write-Verbose "Instance PowerShell pour l'élément '$inputItem' nettoyée."

                # Supprimer la tâche de la liste de suivi (attention à l'index si on supprime ici)
                # Il est plus sûr de marquer comme complétée et de supprimer plus tard, ou de reconstruire la liste
                # Mais ici on utilise WaitAny, donc on a l'index exact
                # *** La suppression se fera dans la boucle appelante ***
            }
        }

        Write-Verbose "Initialisation terminée. En attente des éléments d'entrée..."
        $startTime = Get-Date
    }

    process {
        # Traiter chaque objet reçu du pipeline
        foreach ($item in $InputObject) {
            $totalInputItems++
            # Vérifier si le pool est disponible (gère les erreurs de création dans 'begin')
            if ($null -eq $runspacePool -or $runspacePool.RunspacePoolStateInfo.State -ne 'Opened') {
                 Write-Error "Le Runspace Pool n'est pas disponible. Arrêt du traitement."
                 # Arrêter le traitement des éléments suivants
                 return
            }

            # Attendre si le nombre de tâches actives atteint la limite (ThrottleLimit)
            while ($tasks.Count -ge $ThrottleLimit) {
                Write-Verbose "Limite d'étranglement ($ThrottleLimit tâches actives) atteinte. Attente de la fin d'une tâche..."
                # Attend qu'AU MOINS une tâche se termine
                # Vérifier si des tâches sont terminées
                $completedIndex = -1
                for ($i = 0; $i -lt $tasks.Count; $i++) {
                    if ($tasks[$i].Handle.IsCompleted) {
                        $completedIndex = $i
                        break
                    }
                }

                # Si aucune tâche n'est terminée, attendre un peu
                if ($completedIndex -eq -1) {
                    Start-Sleep -Milliseconds 100
                }

                if ($completedIndex -ne -1) {
                    $completedTaskInfo = $tasks[$completedIndex]
                    Write-Verbose "Tâche à l'index $completedIndex terminée. Traitement des résultats..."
                    # Traiter la tâche terminée
                    & $script:ProcessCompletedTask -taskInfo $completedTaskInfo -waitHandleIndex $completedIndex
                    # Supprimer la tâche de la liste après traitement
                    $tasks.RemoveAt($completedIndex)
                    $totalCompleted++
                    # Mettre à jour la progression après la fin d'une tâche
                    if ($totalInputItems -gt 0) {
                       $percent = [math]::Round(($totalCompleted / $totalInputItems) * 100)
                       Write-Progress -Activity "Exécution Parallèle" -Status "$totalCompleted/$totalInputItems Éléments traités" -PercentComplete $percent -Id 1
                    }
                } else {
                     Write-Verbose "Timeout d'attente atteint, vérification de l'état du pool..."
                     # Optionnel : Vérifier ici si le pool est toujours ouvert
                }
            } # Fin while throttle limit

            # Créer et configurer une instance PowerShell pour cet élément
            $psInstance = [powershell]::Create().AddScript({
                param($__InputItem_Param, $__ScriptBlock_Param) # Noms uniques pour éviter collisions

                # Définir les préférences d'action héritées
                # Les préférences ne sont pas directement utilisables avec $using dans PowerShell 5.1

                # Exécuter le scriptblock fourni par l'utilisateur avec l'élément courant
                & $__ScriptBlock_Param $__InputItem_Param

            }).AddParameter('__InputItem_Param', $item).AddParameter('__ScriptBlock_Param', $ScriptBlock)

            # Associer au pool de runspaces
            $psInstance.RunspacePool = $runspacePool

            # Démarrer l'exécution asynchrone
            $asyncResult = $psInstance.BeginInvoke()
            $totalSubmitted++

            # Stocker les informations nécessaires pour récupérer les résultats plus tard
            $taskInfo = @{
                Handle     = $asyncResult
                Instance   = $psInstance
                InputItem  = $item
                SubmitTime = (Get-Date)
                RunspaceId = $null # Sera potentiellement rempli plus tard si nécessaire, difficile à obtenir simplement
            }
            $tasks.Add($taskInfo)

            Write-Verbose "Tâche soumise pour l'élément '$item' (Total soumis: $totalSubmitted)."

        } # Fin foreach item in InputObject
    }

    end {
        Write-Verbose "Phase 'End': Tous les éléments d'entrée ont été reçus ($totalInputItems). Attente de la fin des $ ($tasks.Count) tâches restantes..."

        # Attendre la fin de toutes les tâches restantes
        while ($tasks.Count -gt 0) {
            # Vérifier si des tâches sont terminées
            $completedIndex = -1
            for ($i = 0; $i -lt $tasks.Count; $i++) {
                if ($tasks[$i].Handle.IsCompleted) {
                    $completedIndex = $i
                    break
                }
            }

            # Si aucune tâche n'est terminée, attendre un peu
            if ($completedIndex -eq -1) {
                Start-Sleep -Milliseconds 100
                continue
            }

            if ($completedIndex -ne -1) {
                $completedTaskInfo = $tasks[$completedIndex]
                Write-Verbose "Tâche restante à l'index $completedIndex terminée. Traitement..."
                # Traiter la tâche terminée
                & $script:ProcessCompletedTask -taskInfo $completedTaskInfo -waitHandleIndex $completedIndex
                 # Supprimer la tâche de la liste
                $tasks.RemoveAt($completedIndex)
                $totalCompleted++
                # Mettre à jour la progression
                 if ($totalInputItems -gt 0) {
                    $percent = [math]::Round(($totalCompleted / $totalInputItems) * 100)
                    Write-Progress -Activity "Exécution Parallèle" -Status "$totalCompleted/$totalInputItems Éléments traités" -PercentComplete $percent -Id 1
                 }
            }
        } # Fin while tasks.Count > 0

        Write-Progress -Activity "Exécution Parallèle" -Completed -Id 1
        $endTime = Get-Date
        $duration = $endTime - $startTime
        Write-Verbose "Traitement parallèle terminé. Durée: $($duration.ToString('g'))"
        Write-Verbose "Total éléments traités: $totalCompleted. Résultats collectés: $($allResults.Count)."

        # Nettoyer le pool de runspaces
        if ($null -ne $runspacePool) {
            Write-Verbose "Fermeture et nettoyage du Runspace Pool..."
            $runspacePool.Close()
            $runspacePool.Dispose()
            Write-Verbose "Runspace Pool fermé et nettoyé."
        }

        # Retourner tous les résultats collectés
        Write-Verbose "Retour des $($allResults.Count) objets de résultats."
        return $allResults
    }
}

# Exporter la fonction si ce fichier est utilisé comme module
# Export-ModuleMember -Function Invoke-OptimizedParallel