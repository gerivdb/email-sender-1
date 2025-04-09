#Requires -Version 5.1
<#
.SYNOPSIS
    Module de traitement parallèle optimisé pour PowerShell 5.1 et supérieur.
.DESCRIPTION
    Ce module fournit des fonctions pour exécuter des traitements parallèles optimisés
    en utilisant des Runspace Pools, qui sont plus performants que les Jobs PowerShell
    traditionnels. Il inclut des fonctions spécifiques pour l'analyse et la correction
    parallèles de scripts PowerShell.
.NOTES
    Auteur: [Votre Nom/AI Assistant]
    Version: 2.0
    Compatibilité: PowerShell 5.1 et supérieur
#>

#region Core Parallel Execution Function (Invoke-OptimizedParallel)
# --- Copiez/Collez ici la définition COMPLÈTE et AMÉLIORÉE ---
# --- de la fonction Invoke-OptimizedParallel de la réponse précédente ---
# --- Assurez-vous qu'elle n'est PAS exportée si elle est interne, ---
# --- ou ajoutez-la à FunctionsToExport si elle doit être publique. ---

<#
.SYNOPSIS
    Exécute un bloc de script sur plusieurs éléments en parallèle en utilisant des Runspace Pools optimisés.
.DESCRIPTION
    (Description complète de Invoke-OptimizedParallel ici...)
.PARAMETER ScriptBlock
    (Description complète du paramètre ScriptBlock ici...)
.PARAMETER InputObject
    (Description complète du paramètre InputObject ici...)
.PARAMETER MaxThreads
    (Description complète du paramètre MaxThreads ici...)
.PARAMETER ThrottleLimit
    (Description complète du paramètre ThrottleLimit ici...)
.PARAMETER SharedVariables
    (Description complète du paramètre SharedVariables ici...)
.OUTPUTS
    PSCustomObject[]
    (Description complète des sorties ici...)
.EXAMPLE
    (Exemples complets pour Invoke-OptimizedParallel ici...)
.NOTES
    (Notes complètes pour Invoke-OptimizedParallel ici...)
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

    # ==========================================================
    # ||  COLLEZ ICI LE CORPS COMPLET DE LA FONCTION          ||
    # ||  Invoke-OptimizedParallel AMÉLIORÉE PRÉCÉDEMMENT     ||
    # ==========================================================
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
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()
        $iss.UseDefaultThreadOptions = $true
        foreach ($key in $SharedVariables.Keys) {
            $iss.Variables.Add([System.Management.Automation.Runspaces.SessionStateVariableEntry]::new($key, $SharedVariables[$key], 'Shared variable'))
            Write-Verbose "Variable partagée '$key' ajoutée à l'état initial."
        }
        try {
            $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $iss, $Host)
            $runspacePool.Open()
            Write-Verbose "Runspace Pool créé et ouvert avec Min=1, Max=$MaxThreads threads."
        } catch { Write-Error "Impossible de créer ou d'ouvrir le Runspace Pool: $($_.Exception.Message)"; throw $_ }
        $tasks = [System.Collections.Generic.List[hashtable]]::new()
        $allResults = [System.Collections.Generic.List[object]]::new()
        $totalSubmitted = 0; $totalCompleted = 0; $totalInputItems = 0
        $script:ProcessCompletedTask = {
            param($taskInfo, $waitHandleIndex)
            $psInstance = $taskInfo.Instance; $inputItem = $taskInfo.InputItem
            $taskResult = $null; $taskSuccess = $false; $taskErrorRecord = $null
            try {
                $taskResult = $psInstance.EndInvoke($taskInfo.Handle); $taskSuccess = $true
                if ($psInstance.Streams.Error.Count -gt 0) {
                     Write-Warning "Tâche pour l'élément '$inputItem' a généré des erreurs non-terminating (voir ci-dessous)."
                     $psInstance.Streams.Error | ForEach-Object { Write-Warning $_.ToString() }
                }
            } catch { $taskSuccess = $false; $taskErrorRecord = $_.ErrorRecord; Write-Verbose "Erreur détectée lors du traitement de l'élément '$inputItem': $($taskErrorRecord.Exception.Message)" }
            finally {
                $outputObject = [PSCustomObject]@{ InputObject = $inputItem; Success = $taskSuccess; Result = $taskResult; ErrorRecord = $taskErrorRecord; RunspaceId = $taskInfo.RunspaceId }
                $allResults.Add($outputObject); $psInstance.Dispose(); Write-Verbose "Instance PowerShell pour l'élément '$inputItem' nettoyée."
            }
        }
        Write-Verbose "Initialisation terminée. En attente des éléments d'entrée..."; $startTime = Get-Date
    }
    process {
        foreach ($item in $InputObject) {
            $totalInputItems++; if ($null -eq $runspacePool -or $runspacePool.RunspacePoolStateInfo.State -ne 'Opened') { Write-Error "Le Runspace Pool n'est pas disponible. Arrêt."; return }
            while ($tasks.Count -ge $ThrottleLimit) {
                Write-Verbose "Limite d'étranglement ($ThrottleLimit tâches actives) atteinte. Attente..."; $waitHandles = $tasks.Handle
                $completedIndex = [System.Threading.WaitHandle]::WaitAny($waitHandles, [timespan]::FromSeconds(5))
                if ($completedIndex -ne [System.Threading.WaitHandle]::WaitTimeout) {
                    $completedTaskInfo = $tasks[$completedIndex]; Write-Verbose "Tâche à l'index $completedIndex terminée. Traitement..."; & $script:ProcessCompletedTask -taskInfo $completedTaskInfo -waitHandleIndex $completedIndex
                    $tasks.RemoveAt($completedIndex); $totalCompleted++
                    if ($totalInputItems -gt 0) { $percent = [math]::Round(($totalCompleted / $totalInputItems) * 100); Write-Progress -Activity "Exécution Parallèle" -Status "$totalCompleted/$totalInputItems Éléments traités" -PercentComplete $percent -Id 1 }
                } else { Write-Verbose "Timeout d'attente atteint..." }
            }
            $psInstance = [powershell]::Create().AddScript({ param($__InputItem_Param, $__ScriptBlock_Param); $VerbosePreference = $using:VerbosePreference; $DebugPreference = $using:DebugPreference; $ErrorActionPreference = $using:ErrorActionPreference; $WarningPreference = $using:WarningPreference; & $__ScriptBlock_Param $__InputItem_Param }).AddParameter('__InputItem_Param', $item).AddParameter('__ScriptBlock_Param', $ScriptBlock)
            $psInstance.RunspacePool = $runspacePool; $asyncResult = $psInstance.BeginInvoke(); $totalSubmitted++
            $taskInfo = @{ Handle = $asyncResult; Instance = $psInstance; InputItem = $item; SubmitTime = (Get-Date); RunspaceId = $null }; $tasks.Add($taskInfo)
            Write-Verbose "Tâche soumise pour l'élément '$item' (Total soumis: $totalSubmitted)."
        }
    }
    end {
        Write-Verbose "Phase 'End': Tous les éléments d'entrée ($totalInputItems). Attente des $($tasks.Count) tâches restantes...";
        while ($tasks.Count -gt 0) {
            $waitHandles = $tasks.Handle; $completedIndex = [System.Threading.WaitHandle]::WaitAny($waitHandles, [timespan]::FromMinutes(1))
            if ($completedIndex -ne [System.Threading.WaitHandle]::WaitTimeout) {
                $completedTaskInfo = $tasks[$completedIndex]; Write-Verbose "Tâche restante à l'index $completedIndex terminée. Traitement..."; & $script:ProcessCompletedTask -taskInfo $completedTaskInfo -waitHandleIndex $completedIndex
                $tasks.RemoveAt($completedIndex); $totalCompleted++
                if ($totalInputItems -gt 0) { $percent = [math]::Round(($totalCompleted / $totalInputItems) * 100); Write-Progress -Activity "Exécution Parallèle" -Status "$totalCompleted/$totalInputItems Éléments traités" -PercentComplete $percent -Id 1 }
            } else { Write-Warning "Timeout d'attente long atteint ($($tasks.Count) tâches restantes)..."; }
        }
        Write-Progress -Activity "Exécution Parallèle" -Completed -Id 1; $endTime = Get-Date; $duration = $endTime - $startTime
        Write-Verbose "Traitement parallèle terminé. Durée: $($duration.ToString('g'))"; Write-Verbose "Total traités: $totalCompleted. Résultats collectés: $($allResults.Count)."
        if ($null -ne $runspacePool) { Write-Verbose "Fermeture du Runspace Pool..."; $runspacePool.Close(); $runspacePool.Dispose(); Write-Verbose "Runspace Pool fermé." }
        Write-Verbose "Retour des $($allResults.Count) objets de résultats."; return $allResults
    }
}
#endregion

#region Default Error Patterns (Shared)
# Défini dans la portée du script (module) pour être partagé
$script:DefaultErrorPatterns = @(
    @{
        Name        = "HardcodedPath"
        Pattern     = '(?<![\\])(["''])((?:[A-Za-z]:[\\/]|\\\\)[^''"]+)\1'
        Description = "Chemin absolu codé en dur détecté"
        Correction  = {
            param($Line)
            $match = [regex]::Match($Line, '(?<![\\])(["''])((?:[A-Za-z]:[\\/]|\\\\)[^''"]+)\1')
            if ($match.Success) {
                $quote = $match.Groups[1].Value
                $placeholder = "(Join-Path -Path `$PSScriptRoot -ChildPath ""CHEMIN_RELATIF_A_DETERMINER"")" # Placeholder
                Write-Warning "Remplacement d'un chemin codé en dur par un placeholder : $($match.Value)"
                return $Line -replace [regex]::Escape($match.Value), ($quote + $placeholder + $quote)
            }
            return $Line
        }
    },
    @{
        Name        = "PotentialNoErrorHandlingIO"
        Pattern     = '(?<!try\s*\{\s*)(?<!\s*\|\s*catch\s*\{\s*)(?:\b(Get-Content|Set-Content|Copy-Item|Move-Item|Remove-Item))\b(?![^`n]*?-ErrorAction)'
        Description = "Gestion d'erreurs potentiellement manquante pour un cmdlet I/O"
        Correction  = {
            param($Line)
            Write-Verbose "Ajout de -ErrorAction Stop à un cmdlet I/O"
            return $Line -replace '(\b(Get-Content|Set-Content|Copy-Item|Move-Item|Remove-Item)\b(?![^`n]*?-ErrorAction))', '$1 -ErrorAction Stop'
        }
    },
    @{
        Name        = "WriteHostForOutput"
        Pattern     = '\bWrite-Host\b'
        Description = "Utilisation de Write-Host détectée (préférer Write-Output/Verbose/etc.)"
        Correction  = {
            param($Line)
            Write-Warning "Remplacement de Write-Host par Write-Output. Vérifiez si Write-Verbose/Warning est plus approprié."
            return $Line -replace '\bWrite-Host\b', 'Write-Output'
        }
    }
    # Ajoutez d'autres patterns/corrections ici
)
#endregion

#region Script Analysis Function
<#
.SYNOPSIS
    Analyse plusieurs scripts PowerShell en parallèle pour détecter des patterns spécifiques.
.DESCRIPTION
    Utilise Invoke-OptimizedParallel pour lire et analyser rapidement le contenu de plusieurs
    fichiers de script (.ps1) à la recherche de patterns d'erreurs ou de style courants définis.
.PARAMETER ScriptPaths
    Un tableau de chemins vers les fichiers de script PowerShell (.ps1) à analyser.
    Les chemins relatifs sont résolus par rapport au répertoire courant. Peut accepter l'entrée du pipeline.
.PARAMETER MaxThreads
    Nombre maximum de threads pour l'analyse parallèle. Par défaut, utilise le nombre de processeurs.
.PARAMETER ErrorPatterns
    Optionnel. Un tableau de hashtables personnalisées définissant les patterns à rechercher.
    Chaque hashtable doit avoir au moins les clés 'Name' (string) et 'Pattern' (string, regex).
    Si non fourni, utilise les patterns par défaut du module.
.OUTPUTS
    PSCustomObject[]
    Retourne les objets de résultats détaillés de Invoke-OptimizedParallel.
    Le champ `.Result` de chaque objet contiendra un tableau des problèmes trouvés pour ce script,
    ou $null s'il n'y a pas de problème ou si l'analyse a échoué.
    Chaque problème est un PSCustomObject avec {Name, Description, LineNumber, Line, Match}.
.EXAMPLE
    Get-ChildItem C:\Scripts -Filter *.ps1 -Recurse | Invoke-ParallelScriptAnalysis -MaxThreads 4 -Verbose

    # Filtrer les résultats pour voir les scripts avec des problèmes
    $analysisResults | Where-Object { $_.Success -and $_.Result } | ForEach-Object {
        Write-Host "--- Script: $($_.InputObject.FullName) ---"
        $_.Result | Format-Table -AutoSize
    }
.NOTES
    Version: 2.0
#>
function Invoke-ParallelScriptAnalysis {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$ScriptPaths,

        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0, # Sera défini par Invoke-OptimizedParallel

        [Parameter(Mandatory = $false)]
        [array]$ErrorPatterns = $script:DefaultErrorPatterns # Utilise les defaults du module
    )

    begin {
        Write-Verbose "Initialisation de l'analyse parallèle des scripts."
        $validScriptPaths = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        $analysisScriptBlock = {
            param($fileInfo) # Reçoit un objet FileInfo validé

            $scriptPath = $fileInfo.FullName
            $patternsToUse = $using:patterns # Accède aux patterns partagés

            Write-Verbose "[Analyse] Traitement de: $scriptPath"
            $detectedIssues = [System.Collections.Generic.List[object]]::new()

            # Lire le contenu une seule fois
            # Utiliser -ErrorAction Stop pour que l'erreur soit capturée par Invoke-OptimizedParallel
            $scriptContent = Get-Content -LiteralPath $scriptPath -Raw -Encoding UTF8 -ErrorAction Stop
            # Pré-splitter pour obtenir les numéros de ligne plus facilement
            $scriptLines = $scriptContent.Split("`n")

            foreach ($pattern in $patternsToUse) {
                try {
                    # Utiliser la correspondance Regex statique pour potentiellement plus de perf
                    $regexMatches = [regex]::Matches($scriptContent, $pattern.Pattern)

                    foreach ($match in $regexMatches) {
                        # Calcul plus fiable du numéro de ligne
                        $lineNumber = 1 + $scriptContent.Substring(0, $match.Index).Split("`n").Count - 1

                        # Vérifier les limites du tableau de lignes
                        $lineContent = ""
                        if ($lineNumber -gt 0 -and $lineNumber -le $scriptLines.Length) {
                             $lineContent = $scriptLines[$lineNumber - 1].Trim()
                        } else {
                             Write-Warning "[Analyse] Impossible de déterminer la ligne pour le match '$($match.Value)' à l'index $($match.Index) dans '$scriptPath'. Ligne calculée: $lineNumber"
                        }

                        $issue = [PSCustomObject]@{
                            Name        = $pattern.Name
                            Description = $pattern.Description
                            LineNumber  = $lineNumber
                            Line        = $lineContent
                            Match       = $match.Value
                        }
                        $detectedIssues.Add($issue)
                    }
                } catch {
                    # Capturer les erreurs liées à une regex spécifique, mais continuer avec les autres patterns
                    Write-Warning "[Analyse] Erreur lors de l'application du pattern '$($pattern.Name)' sur '$scriptPath': $($_.Exception.Message)"
                    # Ne pas faire échouer toute l'analyse pour un mauvais pattern
                }
            }

            # Retourner la liste des problèmes détectés (sera dans le champ .Result de l'objet final)
            # Retourne $null ou une liste vide si aucun problème n'est trouvé
            if ($detectedIssues.Count -gt 0) {
                return $detectedIssues
            } else {
                return $null # Ou @() selon la préférence
            }
        } # Fin AnalysisScriptBlock
    } # Fin Begin

    process {
        # Valider chaque chemin reçu
        foreach ($path in $ScriptPaths) {
            try {
                $resolvedPath = Resolve-Path -LiteralPath $path -ErrorAction Stop
                $fileInfo = Get-Item -LiteralPath $resolvedPath.ProviderPath -ErrorAction Stop

                if ($fileInfo -is [System.IO.FileInfo] -and $fileInfo.Extension -eq '.ps1') {
                    $validScriptPaths.Add($fileInfo)
                    Write-Verbose "Chemin validé et ajouté pour analyse : $($fileInfo.FullName)"
                } else {
                    Write-Warning "Le chemin '$($resolvedPath.ProviderPath)' n'est pas un fichier .ps1 valide."
                }
            } catch {
                 Write-Warning "Impossible de valider ou d'accéder au chemin '$path': $($_.Exception.Message)"
            }
        }
    } # Fin Process

    end {
        Write-Host "Lancement de l'analyse parallèle pour $($validScriptPaths.Count) scripts valides..."
        if ($validScriptPaths.Count -eq 0) {
            Write-Warning "Aucun script valide à analyser."
            return # Retourne un tableau vide
        }

        # Exécuter l'analyse en parallèle
        $analysisResults = Invoke-OptimizedParallel -InputObject $validScriptPaths `
                                                    -ScriptBlock $analysisScriptBlock `
                                                    -MaxThreads $MaxThreads `
                                                    -SharedVariables @{ patterns = $ErrorPatterns } `
                                                    -Verbose:$VerbosePreference `
                                                    -Debug:$DebugPreference `
                                                    -ErrorAction SilentlyContinue # Gérer les erreurs via l'objet de résultat

        # Traiter et résumer les résultats
        $totalIssuesFound = 0
        $scriptsWithIssues = 0
        $failedScripts = 0

        foreach ($res in $analysisResults) {
            if (-not $res.Success) {
                $failedScripts++
                Write-Warning "Échec de l'analyse pour '$($res.InputObject.FullName)': $($res.ErrorRecord.Exception.Message)"
            } elseif ($res.Result -is [array] -and $res.Result.Count -gt 0) {
                $scriptsWithIssues++
                $totalIssuesFound += $res.Result.Count
            }
        }

        Write-Host "`n--- Résumé de l'Analyse ---"
        Write-Host "Scripts Tentés    : $($analysisResults.Count)"
        Write-Host "Analyses Réussies : $($analysisResults.Count - $failedScripts)"
        Write-Host "Analyses Échouées : $failedScripts"
        Write-Host "Scripts avec Problèmes Détectés : $scriptsWithIssues"
        Write-Host "Total Problèmes Détectés        : $totalIssuesFound"

        # Optionnel : Afficher les top scripts avec problèmes
        if ($totalIssuesFound -gt 0) {
            Write-Host "`nTop 5 des scripts avec le plus de problèmes :"
            $analysisResults | Where-Object { $_.Success -and $_.Result } |
             Sort-Object -Property @{Expression = { $_.Result.Count }} -Descending |
             Select-Object -First 5 |
             ForEach-Object { Write-Host ('  - {0} ({1} problèmes)' -f $_.InputObject.Name, $_.Result.Count) }
        }

        # Retourner les résultats détaillés bruts de Invoke-OptimizedParallel
        return $analysisResults
    } # Fin End
}
#endregion

#region Script Correction Function
<#
.SYNOPSIS
    Analyse et corrige plusieurs scripts PowerShell en parallèle.
.DESCRIPTION
    Utilise Invoke-OptimizedParallel pour analyser des scripts PowerShell à la recherche
    de patterns définis, puis applique les corrections correspondantes.
    Crée des fichiers de sauvegarde (.bak) avant de modifier les scripts originaux,
    sauf si -WhatIf est utilisé.
.PARAMETER ScriptPaths
    Un tableau de chemins vers les fichiers de script PowerShell (.ps1) à corriger.
    Les chemins relatifs sont résolus par rapport au répertoire courant. Peut accepter l'entrée du pipeline.
.PARAMETER MaxThreads
    Nombre maximum de threads pour la correction parallèle. Par défaut, utilise le nombre de processeurs.
.PARAMETER ErrorPatterns
    Optionnel. Un tableau de hashtables personnalisées définissant les patterns et leurs corrections.
    Chaque hashtable doit avoir 'Name' (string), 'Pattern' (string, regex), 'Description' (string),
    et 'Correction' (scriptblock prenant une ligne et retournant la ligne corrigée).
    Si non fourni, utilise les patterns par défaut du module.
.OUTPUTS
    PSCustomObject[]
    Retourne les objets de résultats détaillés de Invoke-OptimizedParallel.
    Le champ `.Result` de chaque objet contiendra un PSCustomObject résumant la correction pour ce script
    ({IssuesFound, CorrectionsAttempted, CorrectionsMade, BackupPath}), ou $null si l'opération a échoué avant la correction.
.EXAMPLE
    Get-ChildItem C:\ScriptsToFix -Filter *.ps1 | Invoke-ParallelScriptCorrection -MaxThreads 4 -Verbose

    # Voir ce qui serait fait sans modifier les fichiers
    Get-ChildItem C:\ScriptsToFix -Filter *.ps1 | Invoke-ParallelScriptCorrection -WhatIf

    # Examiner les résultats
    $correctionResults | Where-Object {$_.Success -and $_.Result.CorrectionsMade -gt 0} |
        Format-Table @{N='Script';E={$_.InputObject.Name}}, @{N='Corrections';E={$_.Result.CorrectionsMade}} -AutoSize

    $correctionResults | Where-Object {-not $_.Success} | ForEach-Object {
         Write-Warning ("Échec correction pour {0}: {1}" -f $_.InputObject.Name, $_.ErrorRecord.Exception.Message)
    }
.NOTES
    Version: 2.0
    Prend en charge -WhatIf pour simuler les corrections sans modifier les fichiers.
#>
function Invoke-ParallelScriptCorrection {
    [CmdletBinding(SupportsShouldProcess = $true)] # Active -WhatIf
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [string[]]$ScriptPaths,

        [Parameter(Mandatory = $false)]
        [int]$MaxThreads = 0, # Sera défini par Invoke-OptimizedParallel

        [Parameter(Mandatory = $false)]
        [array]$ErrorPatterns = $script:DefaultErrorPatterns # Utilise les defaults du module
    )

    begin {
        Write-Verbose "Initialisation de la correction parallèle des scripts."
        $validScriptPaths = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

        # ScriptBlock pour la correction d'UN SEUL fichier
        $correctionScriptBlock = {
            param($fileInfo) # Reçoit un objet FileInfo validé

            $scriptPath = $fileInfo.FullName
            $patternsToUse = $using:patterns # Patterns partagés
            $useWhatIf = $using:whatifPreferenceEffective # Indicateur WhatIf partagé

            Write-Verbose "[Correction] Traitement de: $scriptPath"
            $correctionSummary = [PSCustomObject]@{
                IssuesFound = 0
                CorrectionsAttempted = 0
                CorrectionsMade = 0
                BackupPath = $null
                FileWritten = $false
            }

            # 1. Lire le contenu - Laisser Invoke-OptimizedParallel gérer l'erreur si échec
            $scriptLines = Get-Content -LiteralPath $scriptPath -Encoding UTF8 -ErrorAction Stop
            $scriptContent = $scriptLines -join "`n" # Pour la détection multi-lignes

            # 2. Détecter tous les problèmes AVANT de modifier
            $detectedIssues = [System.Collections.Generic.List[object]]::new()
            foreach ($pattern in $patternsToUse) {
                try {
                    $regexMatches = [regex]::Matches($scriptContent, $pattern.Pattern)
                    $correctionSummary.IssuesFound += $regexMatches.Count

                    foreach ($match in $regexMatches) {
                         $lineNumber = 1 + $scriptContent.Substring(0, $match.Index).Split("`n").Count - 1
                         if ($lineNumber -gt 0 -and $lineNumber -le $scriptLines.Length) {
                             $lineContent = $scriptLines[$lineNumber - 1].Trim()
                         } else { $lineContent = "[Ligne hors limites]" }

                         $issue = [PSCustomObject]@{
                            Name        = $pattern.Name
                            Pattern     = $pattern.Pattern # Utile pour le débogage
                            LineNumber  = $lineNumber
                            Line        = $lineContent
                            MatchValue  = $match.Value
                            CorrectionSB= $pattern.Correction # Le scriptblock de correction lui-même
                        }
                        $detectedIssues.Add($issue)
                    }
                } catch {
                    Write-Warning "[Correction] Erreur lors de la détection avec le pattern '$($pattern.Name)' sur '$scriptPath': $($_.Exception.Message)"
                }
            }

            # Si aucun problème, retourner le résumé initial
            if ($detectedIssues.Count -eq 0) {
                Write-Verbose "[Correction] Aucun problème détecté dans '$scriptPath'."
                return $correctionSummary
            }

            # 3. Préparer la correction (tri, sauvegarde si nécessaire)
            $sortedIssues = $detectedIssues | Sort-Object -Property LineNumber -Descending
            $linesToModify = $scriptLines.Clone() # Travailler sur une copie
            $madeChanges = $false

            # -- Simulation ou Action Réelle --
            if ($useWhatIf) {
                 Write-Host "[WhatIf] Exécution de l'opération 'Corriger le script' sur la cible '$scriptPath'."
            } else {
                 # Créer la sauvegarde seulement si on n'est pas en WhatIf
                 $correctionSummary.BackupPath = "$scriptPath.bak"
                 Write-Verbose "[Correction] Création de la sauvegarde : $($correctionSummary.BackupPath)"
                 try {
                    Copy-Item -LiteralPath $scriptPath -Destination $correctionSummary.BackupPath -Force -ErrorAction Stop
                 } catch {
                     Write-Error "[Correction] Impossible de créer le fichier de sauvegarde '$($correctionSummary.BackupPath)' pour '$scriptPath'. Correction annulée pour ce fichier. Erreur: $($_.Exception.Message)"
                     throw "Échec de la sauvegarde. Correction annulée." # Provoque une erreur gérée par Invoke-OptimizedParallel
                 }
            }

            # 4. Appliquer les corrections (en mémoire ou simulation)
            foreach ($issue in $sortedIssues) {
                $lineIndex = $issue.LineNumber - 1

                # Vérifier si l'index est valide (sécurité supplémentaire)
                if ($lineIndex -lt 0 -or $lineIndex -ge $linesToModify.Length) {
                    Write-Warning "[Correction] Index de ligne invalide ($lineIndex) pour le problème '$($issue.Name)' dans '$scriptPath'. Correction ignorée."
                    continue
                }

                $originalLine = $linesToModify[$lineIndex]
                $correctionSummary.CorrectionsAttempted++
                $correctedLine = $null

                try {
                    # Exécuter le scriptblock de correction
                    $correctedLine = & $issue.CorrectionSB $originalLine

                    if ($originalLine -ne $correctedLine) {
                        $madeChanges = $true
                        $correctionSummary.CorrectionsMade++
                        if ($useWhatIf) {
                            Write-Host "[WhatIf] Correction '$($issue.Name)' à la ligne $($issue.LineNumber) dans '$scriptPath':"
                            Write-Host "[WhatIf]   < $($originalLine)"
                            Write-Host "[WhatIf]   > $($correctedLine)"
                            # Ne pas modifier $linesToModify en WhatIf pour simuler état initial pour chaque correction
                        } else {
                            Write-Verbose "[Correction] Application '$($issue.Name)' Ligne $($issue.LineNumber): '$correctedLine'"
                            $linesToModify[$lineIndex] = $correctedLine
                        }
                    } else {
                         Write-Verbose "[Correction] La correction '$($issue.Name)' n'a produit aucun changement pour la ligne $($issue.LineNumber)."
                    }
                } catch {
                    Write-Warning "[Correction] Erreur lors de l'application de la correction '$($issue.Name)' à la ligne $($issue.LineNumber) dans '$scriptPath': $($_.Exception.Message)"
                    # Continuer avec les autres corrections
                }
            } # Fin foreach issue

            # 5. Sauvegarder si des changements ont eu lieu et pas en WhatIf
            if ($madeChanges -and (-not $useWhatIf)) {
                Write-Verbose "[Correction] Sauvegarde du fichier corrigé : $scriptPath"
                try {
                    # Utiliser Set-Content pour gérer l'encodage plus explicitement si nécessaire, ou Out-File
                    $linesToModify | Out-File -LiteralPath $scriptPath -Encoding UTF8 -Force -ErrorAction Stop
                    $correctionSummary.FileWritten = $true
                } catch {
                     Write-Error "[Correction] ERREUR lors de la sauvegarde du fichier corrigé '$scriptPath'. Vérifiez le fichier et la sauvegarde '$($correctionSummary.BackupPath)'. Erreur: $($_.Exception.Message)"
                     # L'erreur sera capturée par Invoke-OptimizedParallel, mais le fichier peut être dans un état incohérent.
                     throw "Échec de l'écriture du fichier corrigé."
                }
            } elseif ($madeChanges -and $useWhatIf) {
                 Write-Host "[WhatIf] Le fichier '$scriptPath' aurait été sauvegardé avec $($correctionSummary.CorrectionsMade) corrections."
            } else {
                 Write-Verbose "[Correction] Aucune modification nette appliquée ou mode WhatIf actif. Fichier non sauvegardé."
            }

            # Retourner le résumé de la correction (sera dans le champ .Result)
            return $correctionSummary

        } # Fin CorrectionScriptBlock
    } # Fin Begin

    process {
         # Valider chaque chemin reçu
        foreach ($path in $ScriptPaths) {
            try {
                $resolvedPath = Resolve-Path -LiteralPath $path -ErrorAction Stop
                $fileInfo = Get-Item -LiteralPath $resolvedPath.ProviderPath -ErrorAction Stop

                 # Vérifier aussi les permissions en écriture si on n'est pas en WhatIf
                $isWritable = $false
                if (-not $WhatIfPreference) {
                    try {
                       [System.IO.File]::Open($fileInfo.FullName, 'Open', 'Write').Close() # Test rapide d'écriture
                       $isWritable = $true
                    } catch {
                       Write-Warning "Le fichier '$($fileInfo.FullName)' n'est pas accessible en écriture. Il sera ignoré pour la correction réelle."
                    }
                }

                if ($fileInfo -is [System.IO.FileInfo] -and $fileInfo.Extension -eq '.ps1' -and ($WhatIfPreference -or $isWritable)) {
                    $validScriptPaths.Add($fileInfo)
                    Write-Verbose "Chemin validé et ajouté pour correction : $($fileInfo.FullName)"
                } else {
                    if ($fileInfo.Extension -ne '.ps1') { Write-Warning "Le chemin '$($resolvedPath.ProviderPath)' n'est pas un fichier .ps1." }
                    # Le message d'erreur d'écriture a déjà été affiché
                }
            } catch {
                 Write-Warning "Impossible de valider ou d'accéder au chemin '$path': $($_.Exception.Message)"
            }
        }
    } # Fin Process

    end {
        Write-Host "Lancement de la correction parallèle pour $($validScriptPaths.Count) scripts valides et accessibles..."
        if ($validScriptPaths.Count -eq 0) {
            Write-Warning "Aucun script valide et accessible à corriger."
            return # Retourne un tableau vide
        }

        # Déterminer l'état effectif de WhatIf
        $whatifEffective = $PSCmdlet.ShouldProcess("les $($validScriptPaths.Count) scripts", "Appliquer les corrections")

        # Exécuter la correction en parallèle
        $correctionResults = Invoke-OptimizedParallel -InputObject $validScriptPaths `
                                                    -ScriptBlock $correctionScriptBlock `
                                                    -MaxThreads $MaxThreads `
                                                    -SharedVariables @{ patterns = $ErrorPatterns; whatifPreferenceEffective = $whatifEffective } `
                                                    -Verbose:$VerbosePreference `
                                                    -Debug:$DebugPreference `
                                                    -ErrorAction SilentlyContinue

         # Traiter et résumer les résultats
        $totalIssuesFound = 0
        $totalCorrectionsAttempted = 0
        $totalCorrectionsMade = 0
        $filesCorrected = 0
        $failedScripts = 0

        foreach ($res in $correctionResults) {
            if (-not $res.Success) {
                $failedScripts++
                # Message d'erreur déjà affiché par le catch du ScriptBlock ou Invoke-OptimizedParallel
            } elseif ($res.Result -is [PSCustomObject]) {
                 # Additionner les compteurs du résumé retourné dans .Result
                 $totalIssuesFound += $res.Result.IssuesFound
                 $totalCorrectionsAttempted += $res.Result.CorrectionsAttempted
                 $totalCorrectionsMade += $res.Result.CorrectionsMade
                 if ($res.Result.FileWritten) {
                     $filesCorrected++
                 }
            }
        }

        Write-Host "`n--- Résumé de la Correction ---"
        Write-Host "Mode WhatIf Actif      : $($whatifEffective)"
        Write-Host "Scripts Tentés         : $($correctionResults.Count)"
        Write-Host "Corrections Réussies   : $($correctionResults.Count - $failedScripts)"
        Write-Host "Corrections Échouées   : $failedScripts"
        Write-Host "Total Problèmes Trouvés: $totalIssuesFound"
        # Write-Host "Corrections Tentatives : $totalCorrectionsAttempted" # Peut-être trop détaillé
        Write-Host "Corrections Appliquées : $totalCorrectionsMade ($($filesCorrected) fichiers modifiés)"

        # Optionnel : Afficher les top scripts corrigés
        if ($totalCorrectionsMade -gt 0) {
            Write-Host "`nTop 5 des scripts avec le plus de corrections appliquées :"
             $correctionResults | Where-Object { $_.Success -and $_.Result.CorrectionsMade -gt 0 } |
             Sort-Object -Property @{Expression = { $_.Result.CorrectionsMade }} -Descending |
             Select-Object -First 5 |
             ForEach-Object { Write-Host ('  - {0} ({1} corrections)' -f $_.InputObject.Name, $_.Result.CorrectionsMade) }
        }

        # Retourner les résultats détaillés bruts de Invoke-OptimizedParallel
        return $correctionResults
    } # Fin End
}
#endregion

#region Module Exports
# Exporter uniquement les fonctions destinées à l'utilisateur final
Export-ModuleMember -Function Invoke-OptimizedParallel, Invoke-ParallelScriptAnalysis, Invoke-ParallelScriptCorrection
#endregion