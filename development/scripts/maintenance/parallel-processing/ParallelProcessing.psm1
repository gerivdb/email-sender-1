#Requires -Version 5.1
<#
.SYNOPSIS
    Module de traitement parallÃ¨le optimisÃ© pour PowerShell 5.1 et supÃ©rieur.
.DESCRIPTION
    Ce module fournit des fonctions pour exÃ©cuter des traitements parallÃ¨les optimisÃ©s
    en utilisant des Runspace Pools, qui sont plus performants que les Jobs PowerShell
    traditionnels. Il inclut des fonctions spÃ©cifiques pour l'analyse et la correction
    parallÃ¨les de scripts PowerShell.
.NOTES
    Auteur: [Votre Nom/AI Assistant]
    Version: 2.0
    CompatibilitÃ©: PowerShell 5.1 et supÃ©rieur
#>

#region Core Parallel Execution Function (Invoke-OptimizedParallel)
# --- Copiez/Collez ici la dÃ©finition COMPLÃˆTE et AMÃ‰LIORÃ‰E ---
# --- de la fonction Invoke-OptimizedParallel de la rÃ©ponse prÃ©cÃ©dente ---
# --- Assurez-vous qu'elle n'est PAS exportÃ©e si elle est interne, ---
# --- ou ajoutez-la Ã  FunctionsToExport si elle doit Ãªtre publique. ---

<#
.SYNOPSIS
    ExÃ©cute un bloc de script sur plusieurs Ã©lÃ©ments en parallÃ¨le en utilisant des Runspace Pools optimisÃ©s.
.DESCRIPTION
    (Description complÃ¨te de Invoke-OptimizedParallel ici...)
.PARAMETER ScriptBlock
    (Description complÃ¨te du paramÃ¨tre ScriptBlock ici...)
.PARAMETER InputObject
    (Description complÃ¨te du paramÃ¨tre InputObject ici...)
.PARAMETER MaxThreads
    (Description complÃ¨te du paramÃ¨tre MaxThreads ici...)
.PARAMETER ThrottleLimit
    (Description complÃ¨te du paramÃ¨tre ThrottleLimit ici...)
.PARAMETER SharedVariables
    (Description complÃ¨te du paramÃ¨tre SharedVariables ici...)
.OUTPUTS
    PSCustomObject[]
    (Description complÃ¨te des sorties ici...)
.EXAMPLE
    (Exemples complets pour Invoke-OptimizedParallel ici...)
.NOTES
    (Notes complÃ¨tes pour Invoke-OptimizedParallel ici...)
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

    # ==========================================================
    # ||  COLLEZ ICI LE CORPS COMPLET DE LA FONCTION          ||
    # ||  Invoke-OptimizedParallel AMÃ‰LIORÃ‰E PRÃ‰CÃ‰DEMMENT     ||
    # ==========================================================
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
        $iss = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault2()
        $iss.UseDefaultThreadOptions = $true
        foreach ($key in $SharedVariables.Keys) {
            $iss.Variables.Add([System.Management.Automation.Runspaces.SessionStateVariableEntry]::new($key, $SharedVariables[$key], 'Shared variable'))
            Write-Verbose "Variable partagÃ©e '$key' ajoutÃ©e Ã  l'Ã©tat initial."
        }
        try {
            $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxThreads, $iss, $Host)
            $runspacePool.Open()
            Write-Verbose "Runspace Pool crÃ©Ã© et ouvert avec Min=1, Max=$MaxThreads threads."
        } catch { Write-Error "Impossible de crÃ©er ou d'ouvrir le Runspace Pool: $($_.Exception.Message)"; throw $_ }
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
                     Write-Warning "TÃ¢che pour l'Ã©lÃ©ment '$inputItem' a gÃ©nÃ©rÃ© des erreurs non-terminating (voir ci-dessous)."
                     $psInstance.Streams.Error | ForEach-Object { Write-Warning $_.ToString() }
                }
            } catch { $taskSuccess = $false; $taskErrorRecord = $_.ErrorRecord; Write-Verbose "Erreur dÃ©tectÃ©e lors du traitement de l'Ã©lÃ©ment '$inputItem': $($taskErrorRecord.Exception.Message)" }
            finally {
                $outputObject = [PSCustomObject]@{ InputObject = $inputItem; Success = $taskSuccess; Result = $taskResult; ErrorRecord = $taskErrorRecord; RunspaceId = $taskInfo.RunspaceId }
                $allResults.Add($outputObject); $psInstance.Dispose(); Write-Verbose "Instance PowerShell pour l'Ã©lÃ©ment '$inputItem' nettoyÃ©e."
            }
        }
        Write-Verbose "Initialisation terminÃ©e. En attente des Ã©lÃ©ments d'entrÃ©e..."; $startTime = Get-Date
    }
    process {
        foreach ($item in $InputObject) {
            $totalInputItems++; if ($null -eq $runspacePool -or $runspacePool.RunspacePoolStateInfo.State -ne 'Opened') { Write-Error "Le Runspace Pool n'est pas disponible. ArrÃªt."; return }
            while ($tasks.Count -ge $ThrottleLimit) {
                Write-Verbose "Limite d'Ã©tranglement ($ThrottleLimit tÃ¢ches actives) atteinte. Attente..."; $waitHandles = $tasks.Handle
                $completedIndex = [System.Threading.WaitHandle]::WaitAny($waitHandles, [timespan]::FromSeconds(5))
                if ($completedIndex -ne [System.Threading.WaitHandle]::WaitTimeout) {
                    $completedTaskInfo = $tasks[$completedIndex]; Write-Verbose "TÃ¢che Ã  l'index $completedIndex terminÃ©e. Traitement..."; & $script:ProcessCompletedTask -taskInfo $completedTaskInfo -waitHandleIndex $completedIndex
                    $tasks.RemoveAt($completedIndex); $totalCompleted++
                    if ($totalInputItems -gt 0) { $percent = [math]::Round(($totalCompleted / $totalInputItems) * 100); Write-Progress -Activity "ExÃ©cution ParallÃ¨le" -Status "$totalCompleted/$totalInputItems Ã‰lÃ©ments traitÃ©s" -PercentComplete $percent -Id 1 }
                } else { Write-Verbose "Timeout d'attente atteint..." }
            }
            $psInstance = [powershell]::Create().AddScript({ param($__InputItem_Param, $__ScriptBlock_Param); $VerbosePreference = $using:VerbosePreference; $DebugPreference = $using:DebugPreference; $ErrorActionPreference = $using:ErrorActionPreference; $WarningPreference = $using:WarningPreference; & $__ScriptBlock_Param $__InputItem_Param }).AddParameter('__InputItem_Param', $item).AddParameter('__ScriptBlock_Param', $ScriptBlock)
            $psInstance.RunspacePool = $runspacePool; $asyncResult = $psInstance.BeginInvoke(); $totalSubmitted++
            $taskInfo = @{ Handle = $asyncResult; Instance = $psInstance; InputItem = $item; SubmitTime = (Get-Date); RunspaceId = $null }; $tasks.Add($taskInfo)
            Write-Verbose "TÃ¢che soumise pour l'Ã©lÃ©ment '$item' (Total soumis: $totalSubmitted)."
        }
    }
    end {
        Write-Verbose "Phase 'End': Tous les Ã©lÃ©ments d'entrÃ©e ($totalInputItems). Attente des $($tasks.Count) tÃ¢ches restantes...";
        while ($tasks.Count -gt 0) {
            $waitHandles = $tasks.Handle; $completedIndex = [System.Threading.WaitHandle]::WaitAny($waitHandles, [timespan]::FromMinutes(1))
            if ($completedIndex -ne [System.Threading.WaitHandle]::WaitTimeout) {
                $completedTaskInfo = $tasks[$completedIndex]; Write-Verbose "TÃ¢che restante Ã  l'index $completedIndex terminÃ©e. Traitement..."; & $script:ProcessCompletedTask -taskInfo $completedTaskInfo -waitHandleIndex $completedIndex
                $tasks.RemoveAt($completedIndex); $totalCompleted++
                if ($totalInputItems -gt 0) { $percent = [math]::Round(($totalCompleted / $totalInputItems) * 100); Write-Progress -Activity "ExÃ©cution ParallÃ¨le" -Status "$totalCompleted/$totalInputItems Ã‰lÃ©ments traitÃ©s" -PercentComplete $percent -Id 1 }
            } else { Write-Warning "Timeout d'attente long atteint ($($tasks.Count) tÃ¢ches restantes)..."; }
        }
        Write-Progress -Activity "ExÃ©cution ParallÃ¨le" -Completed -Id 1; $endTime = Get-Date; $duration = $endTime - $startTime
        Write-Verbose "Traitement parallÃ¨le terminÃ©. DurÃ©e: $($duration.ToString('g'))"; Write-Verbose "Total traitÃ©s: $totalCompleted. RÃ©sultats collectÃ©s: $($allResults.Count)."
        if ($null -ne $runspacePool) { Write-Verbose "Fermeture du Runspace Pool..."; $runspacePool.Close(); $runspacePool.Dispose(); Write-Verbose "Runspace Pool fermÃ©." }
        Write-Verbose "Retour des $($allResults.Count) objets de rÃ©sultats."; return $allResults
    }
}
#endregion

#region Default Error Patterns (Shared)
# DÃ©fini dans la portÃ©e du script (module) pour Ãªtre partagÃ©
$script:DefaultErrorPatterns = @(
    @{
        Name        = "HardcodedPath"
        Pattern     = '(?<![\\])(["''])((?:[A-Za-z]:[\\/]|\\\\)[^''"]+)\1'
        Description = "Chemin absolu codÃ© en dur dÃ©tectÃ©"
        Correction  = {
            param($Line)
            $match = [regex]::Match($Line, '(?<![\\])(["''])((?:[A-Za-z]:[\\/]|\\\\)[^''"]+)\1')
            if ($match.Success) {
                $quote = $match.Groups[1].Value
                $placeholder = "(Join-Path -Path `$PSScriptRoot -ChildPath ""CHEMIN_RELATIF_A_DETERMINER"")" # Placeholder
                Write-Warning "Remplacement d'un chemin codÃ© en dur par un placeholder : $($match.Value)"
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
            Write-Verbose "Ajout de -ErrorAction Stop Ã  un cmdlet I/O"
            return $Line -replace '(\b(Get-Content|Set-Content|Copy-Item|Move-Item|Remove-Item)\b(?![^`n]*?-ErrorAction))', '$1 -ErrorAction Stop'
        }
    },
    @{
        Name        = "WriteHostForOutput"
        Pattern     = '\bWrite-Host\b'
        Description = "Utilisation de Write-Host dÃ©tectÃ©e (prÃ©fÃ©rer Write-Output/Verbose/etc.)"
        Correction  = {
            param($Line)
            Write-Warning "Remplacement de Write-Host par Write-Output. VÃ©rifiez si Write-Verbose/Warning est plus appropriÃ©."
            return $Line -replace '\bWrite-Host\b', 'Write-Output'
        }
    }
    # Ajoutez d'autres patterns/corrections ici
)
#endregion

#region Script Analysis Function
<#
.SYNOPSIS
    Analyse plusieurs scripts PowerShell en parallÃ¨le pour dÃ©tecter des patterns spÃ©cifiques.
.DESCRIPTION
    Utilise Invoke-OptimizedParallel pour lire et analyser rapidement le contenu de plusieurs
    fichiers de script (.ps1) Ã  la recherche de patterns d'erreurs ou de style courants dÃ©finis.
.PARAMETER ScriptPaths
    Un tableau de chemins vers les fichiers de script PowerShell (.ps1) Ã  analyser.
    Les chemins relatifs sont rÃ©solus par rapport au rÃ©pertoire courant. Peut accepter l'entrÃ©e du pipeline.
.PARAMETER MaxThreads
    Nombre maximum de threads pour l'analyse parallÃ¨le. Par dÃ©faut, utilise le nombre de processeurs.
.PARAMETER ErrorPatterns
    Optionnel. Un tableau de hashtables personnalisÃ©es dÃ©finissant les patterns Ã  rechercher.
    Chaque hashtable doit avoir au moins les clÃ©s 'Name' (string) et 'Pattern' (string, regex).
    Si non fourni, utilise les patterns par dÃ©faut du module.
.OUTPUTS
    PSCustomObject[]
    Retourne les objets de rÃ©sultats dÃ©taillÃ©s de Invoke-OptimizedParallel.
    Le champ `.Result` de chaque objet contiendra un tableau des problÃ¨mes trouvÃ©s pour ce script,
    ou $null s'il n'y a pas de problÃ¨me ou si l'analyse a Ã©chouÃ©.
    Chaque problÃ¨me est un PSCustomObject avec {Name, Description, LineNumber, Line, Match}.
.EXAMPLE
    Get-ChildItem C:\Scripts -Filter *.ps1 -Recurse | Invoke-ParallelScriptAnalysis -MaxThreads 4 -Verbose

    # Filtrer les rÃ©sultats pour voir les scripts avec des problÃ¨mes
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
        [int]$MaxThreads = 0, # Sera dÃ©fini par Invoke-OptimizedParallel

        [Parameter(Mandatory = $false)]
        [array]$ErrorPatterns = $script:DefaultErrorPatterns # Utilise les defaults du module
    )

    begin {
        Write-Verbose "Initialisation de l'analyse parallÃ¨le des scripts."
        $validScriptPaths = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
        $analysisScriptBlock = {
            param($fileInfo) # ReÃ§oit un objet FileInfo validÃ©

            $scriptPath = $fileInfo.FullName
            $patternsToUse = $using:patterns # AccÃ¨de aux patterns partagÃ©s

            Write-Verbose "[Analyse] Traitement de: $scriptPath"
            $detectedIssues = [System.Collections.Generic.List[object]]::new()

            # Lire le contenu une seule fois
            # Utiliser -ErrorAction Stop pour que l'erreur soit capturÃ©e par Invoke-OptimizedParallel
            $scriptContent = Get-Content -LiteralPath $scriptPath -Raw -Encoding UTF8 -ErrorAction Stop
            # PrÃ©-splitter pour obtenir les numÃ©ros de ligne plus facilement
            $scriptLines = $scriptContent.Split("`n")

            foreach ($pattern in $patternsToUse) {
                try {
                    # Utiliser la correspondance Regex statique pour potentiellement plus de perf
                    $regexMatches = [regex]::Matches($scriptContent, $pattern.Pattern)

                    foreach ($match in $regexMatches) {
                        # Calcul plus fiable du numÃ©ro de ligne
                        $lineNumber = 1 + $scriptContent.Substring(0, $match.Index).Split("`n").Count - 1

                        # VÃ©rifier les limites du tableau de lignes
                        $lineContent = ""
                        if ($lineNumber -gt 0 -and $lineNumber -le $scriptLines.Length) {
                             $lineContent = $scriptLines[$lineNumber - 1].Trim()
                        } else {
                             Write-Warning "[Analyse] Impossible de dÃ©terminer la ligne pour le match '$($match.Value)' Ã  l'index $($match.Index) dans '$scriptPath'. Ligne calculÃ©e: $lineNumber"
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
                    # Capturer les erreurs liÃ©es Ã  une regex spÃ©cifique, mais continuer avec les autres patterns
                    Write-Warning "[Analyse] Erreur lors de l'application du pattern '$($pattern.Name)' sur '$scriptPath': $($_.Exception.Message)"
                    # Ne pas faire Ã©chouer toute l'analyse pour un mauvais pattern
                }
            }

            # Retourner la liste des problÃ¨mes dÃ©tectÃ©s (sera dans le champ .Result de l'objet final)
            # Retourne $null ou une liste vide si aucun problÃ¨me n'est trouvÃ©
            if ($detectedIssues.Count -gt 0) {
                return $detectedIssues
            } else {
                return $null # Ou @() selon la prÃ©fÃ©rence
            }
        } # Fin AnalysisScriptBlock
    } # Fin Begin

    process {
        # Valider chaque chemin reÃ§u
        foreach ($path in $ScriptPaths) {
            try {
                $resolvedPath = Resolve-Path -LiteralPath $path -ErrorAction Stop
                $fileInfo = Get-Item -LiteralPath $resolvedPath.ProviderPath -ErrorAction Stop

                if ($fileInfo -is [System.IO.FileInfo] -and $fileInfo.Extension -eq '.ps1') {
                    $validScriptPaths.Add($fileInfo)
                    Write-Verbose "Chemin validÃ© et ajoutÃ© pour analyse : $($fileInfo.FullName)"
                } else {
                    Write-Warning "Le chemin '$($resolvedPath.ProviderPath)' n'est pas un fichier .ps1 valide."
                }
            } catch {
                 Write-Warning "Impossible de valider ou d'accÃ©der au chemin '$path': $($_.Exception.Message)"
            }
        }
    } # Fin Process

    end {
        Write-Host "Lancement de l'analyse parallÃ¨le pour $($validScriptPaths.Count) scripts valides..."
        if ($validScriptPaths.Count -eq 0) {
            Write-Warning "Aucun script valide Ã  analyser."
            return # Retourne un tableau vide
        }

        # ExÃ©cuter l'analyse en parallÃ¨le
        $analysisResults = Invoke-OptimizedParallel -InputObject $validScriptPaths `
                                                    -ScriptBlock $analysisScriptBlock `
                                                    -MaxThreads $MaxThreads `
                                                    -SharedVariables @{ patterns = $ErrorPatterns } `
                                                    -Verbose:$VerbosePreference `
                                                    -Debug:$DebugPreference `
                                                    -ErrorAction SilentlyContinue # GÃ©rer les erreurs via l'objet de rÃ©sultat

        # Traiter et rÃ©sumer les rÃ©sultats
        $totalIssuesFound = 0
        $scriptsWithIssues = 0
        $failedScripts = 0

        foreach ($res in $analysisResults) {
            if (-not $res.Success) {
                $failedScripts++
                Write-Warning "Ã‰chec de l'analyse pour '$($res.InputObject.FullName)': $($res.ErrorRecord.Exception.Message)"
            } elseif ($res.Result -is [array] -and $res.Result.Count -gt 0) {
                $scriptsWithIssues++
                $totalIssuesFound += $res.Result.Count
            }
        }

        Write-Host "`n--- RÃ©sumÃ© de l'Analyse ---"
        Write-Host "Scripts TentÃ©s    : $($analysisResults.Count)"
        Write-Host "Analyses RÃ©ussies : $($analysisResults.Count - $failedScripts)"
        Write-Host "Analyses Ã‰chouÃ©es : $failedScripts"
        Write-Host "Scripts avec ProblÃ¨mes DÃ©tectÃ©s : $scriptsWithIssues"
        Write-Host "Total ProblÃ¨mes DÃ©tectÃ©s        : $totalIssuesFound"

        # Optionnel : Afficher les top scripts avec problÃ¨mes
        if ($totalIssuesFound -gt 0) {
            Write-Host "`nTop 5 des scripts avec le plus de problÃ¨mes :"
            $analysisResults | Where-Object { $_.Success -and $_.Result } |
             Sort-Object -Property @{Expression = { $_.Result.Count }} -Descending |
             Select-Object -First 5 |
             ForEach-Object { Write-Host ('  - {0} ({1} problÃ¨mes)' -f $_.InputObject.Name, $_.Result.Count) }
        }

        # Retourner les rÃ©sultats dÃ©taillÃ©s bruts de Invoke-OptimizedParallel
        return $analysisResults
    } # Fin End
}
#endregion

#region Script Correction Function
<#
.SYNOPSIS
    Analyse et corrige plusieurs scripts PowerShell en parallÃ¨le.
.DESCRIPTION
    Utilise Invoke-OptimizedParallel pour analyser des scripts PowerShell Ã  la recherche
    de patterns dÃ©finis, puis applique les corrections correspondantes.
    CrÃ©e des fichiers de sauvegarde (.bak) avant de modifier les scripts originaux,
    sauf si -WhatIf est utilisÃ©.
.PARAMETER ScriptPaths
    Un tableau de chemins vers les fichiers de script PowerShell (.ps1) Ã  corriger.
    Les chemins relatifs sont rÃ©solus par rapport au rÃ©pertoire courant. Peut accepter l'entrÃ©e du pipeline.
.PARAMETER MaxThreads
    Nombre maximum de threads pour la correction parallÃ¨le. Par dÃ©faut, utilise le nombre de processeurs.
.PARAMETER ErrorPatterns
    Optionnel. Un tableau de hashtables personnalisÃ©es dÃ©finissant les patterns et leurs corrections.
    Chaque hashtable doit avoir 'Name' (string), 'Pattern' (string, regex), 'Description' (string),
    et 'Correction' (scriptblock prenant une ligne et retournant la ligne corrigÃ©e).
    Si non fourni, utilise les patterns par dÃ©faut du module.
.OUTPUTS
    PSCustomObject[]
    Retourne les objets de rÃ©sultats dÃ©taillÃ©s de Invoke-OptimizedParallel.
    Le champ `.Result` de chaque objet contiendra un PSCustomObject rÃ©sumant la correction pour ce script
    ({IssuesFound, CorrectionsAttempted, CorrectionsMade, BackupPath}), ou $null si l'opÃ©ration a Ã©chouÃ© avant la correction.
.EXAMPLE
    Get-ChildItem C:\ScriptsToFix -Filter *.ps1 | Invoke-ParallelScriptCorrection -MaxThreads 4 -Verbose

    # Voir ce qui serait fait sans modifier les fichiers
    Get-ChildItem C:\ScriptsToFix -Filter *.ps1 | Invoke-ParallelScriptCorrection -WhatIf

    # Examiner les rÃ©sultats
    $correctionResults | Where-Object {$_.Success -and $_.Result.CorrectionsMade -gt 0} |
        Format-Table @{N='Script';E={$_.InputObject.Name}}, @{N='Corrections';E={$_.Result.CorrectionsMade}} -AutoSize

    $correctionResults | Where-Object {-not $_.Success} | ForEach-Object {
         Write-Warning ("Ã‰chec correction pour {0}: {1}" -f $_.InputObject.Name, $_.ErrorRecord.Exception.Message)
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
        [int]$MaxThreads = 0, # Sera dÃ©fini par Invoke-OptimizedParallel

        [Parameter(Mandatory = $false)]
        [array]$ErrorPatterns = $script:DefaultErrorPatterns # Utilise les defaults du module
    )

    begin {
        Write-Verbose "Initialisation de la correction parallÃ¨le des scripts."
        $validScriptPaths = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

        # ScriptBlock pour la correction d'UN SEUL fichier
        $correctionScriptBlock = {
            param($fileInfo) # ReÃ§oit un objet FileInfo validÃ©

            $scriptPath = $fileInfo.FullName
            $patternsToUse = $using:patterns # Patterns partagÃ©s
            $useWhatIf = $using:whatifPreferenceEffective # Indicateur WhatIf partagÃ©

            Write-Verbose "[Correction] Traitement de: $scriptPath"
            $correctionSummary = [PSCustomObject]@{
                IssuesFound = 0
                CorrectionsAttempted = 0
                CorrectionsMade = 0
                BackupPath = $null
                FileWritten = $false
            }

            # 1. Lire le contenu - Laisser Invoke-OptimizedParallel gÃ©rer l'erreur si Ã©chec
            $scriptLines = Get-Content -LiteralPath $scriptPath -Encoding UTF8 -ErrorAction Stop
            $scriptContent = $scriptLines -join "`n" # Pour la dÃ©tection multi-lignes

            # 2. DÃ©tecter tous les problÃ¨mes AVANT de modifier
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
                            Pattern     = $pattern.Pattern # Utile pour le dÃ©bogage
                            LineNumber  = $lineNumber
                            Line        = $lineContent
                            MatchValue  = $match.Value
                            CorrectionSB= $pattern.Correction # Le scriptblock de correction lui-mÃªme
                        }
                        $detectedIssues.Add($issue)
                    }
                } catch {
                    Write-Warning "[Correction] Erreur lors de la dÃ©tection avec le pattern '$($pattern.Name)' sur '$scriptPath': $($_.Exception.Message)"
                }
            }

            # Si aucun problÃ¨me, retourner le rÃ©sumÃ© initial
            if ($detectedIssues.Count -eq 0) {
                Write-Verbose "[Correction] Aucun problÃ¨me dÃ©tectÃ© dans '$scriptPath'."
                return $correctionSummary
            }

            # 3. PrÃ©parer la correction (tri, sauvegarde si nÃ©cessaire)
            $sortedIssues = $detectedIssues | Sort-Object -Property LineNumber -Descending
            $linesToModify = $scriptLines.Clone() # Travailler sur une copie
            $madeChanges = $false

            # -- Simulation ou Action RÃ©elle --
            if ($useWhatIf) {
                 Write-Host "[WhatIf] ExÃ©cution de l'opÃ©ration 'Corriger le script' sur la cible '$scriptPath'."
            } else {
                 # CrÃ©er la sauvegarde seulement si on n'est pas en WhatIf
                 $correctionSummary.BackupPath = "$scriptPath.bak"
                 Write-Verbose "[Correction] CrÃ©ation de la sauvegarde : $($correctionSummary.BackupPath)"
                 try {
                    Copy-Item -LiteralPath $scriptPath -Destination $correctionSummary.BackupPath -Force -ErrorAction Stop
                 } catch {
                     Write-Error "[Correction] Impossible de crÃ©er le fichier de sauvegarde '$($correctionSummary.BackupPath)' pour '$scriptPath'. Correction annulÃ©e pour ce fichier. Erreur: $($_.Exception.Message)"
                     throw "Ã‰chec de la sauvegarde. Correction annulÃ©e." # Provoque une erreur gÃ©rÃ©e par Invoke-OptimizedParallel
                 }
            }

            # 4. Appliquer les corrections (en mÃ©moire ou simulation)
            foreach ($issue in $sortedIssues) {
                $lineIndex = $issue.LineNumber - 1

                # VÃ©rifier si l'index est valide (sÃ©curitÃ© supplÃ©mentaire)
                if ($lineIndex -lt 0 -or $lineIndex -ge $linesToModify.Length) {
                    Write-Warning "[Correction] Index de ligne invalide ($lineIndex) pour le problÃ¨me '$($issue.Name)' dans '$scriptPath'. Correction ignorÃ©e."
                    continue
                }

                $originalLine = $linesToModify[$lineIndex]
                $correctionSummary.CorrectionsAttempted++
                $correctedLine = $null

                try {
                    # ExÃ©cuter le scriptblock de correction
                    $correctedLine = & $issue.CorrectionSB $originalLine

                    if ($originalLine -ne $correctedLine) {
                        $madeChanges = $true
                        $correctionSummary.CorrectionsMade++
                        if ($useWhatIf) {
                            Write-Host "[WhatIf] Correction '$($issue.Name)' Ã  la ligne $($issue.LineNumber) dans '$scriptPath':"
                            Write-Host "[WhatIf]   < $($originalLine)"
                            Write-Host "[WhatIf]   > $($correctedLine)"
                            # Ne pas modifier $linesToModify en WhatIf pour simuler Ã©tat initial pour chaque correction
                        } else {
                            Write-Verbose "[Correction] Application '$($issue.Name)' Ligne $($issue.LineNumber): '$correctedLine'"
                            $linesToModify[$lineIndex] = $correctedLine
                        }
                    } else {
                         Write-Verbose "[Correction] La correction '$($issue.Name)' n'a produit aucun changement pour la ligne $($issue.LineNumber)."
                    }
                } catch {
                    Write-Warning "[Correction] Erreur lors de l'application de la correction '$($issue.Name)' Ã  la ligne $($issue.LineNumber) dans '$scriptPath': $($_.Exception.Message)"
                    # Continuer avec les autres corrections
                }
            } # Fin foreach issue

            # 5. Sauvegarder si des changements ont eu lieu et pas en WhatIf
            if ($madeChanges -and (-not $useWhatIf)) {
                Write-Verbose "[Correction] Sauvegarde du fichier corrigÃ© : $scriptPath"
                try {
                    # Utiliser Set-Content pour gÃ©rer l'encodage plus explicitement si nÃ©cessaire, ou Out-File
                    $linesToModify | Out-File -LiteralPath $scriptPath -Encoding UTF8 -Force -ErrorAction Stop
                    $correctionSummary.FileWritten = $true
                } catch {
                     Write-Error "[Correction] ERREUR lors de la sauvegarde du fichier corrigÃ© '$scriptPath'. VÃ©rifiez le fichier et la sauvegarde '$($correctionSummary.BackupPath)'. Erreur: $($_.Exception.Message)"
                     # L'erreur sera capturÃ©e par Invoke-OptimizedParallel, mais le fichier peut Ãªtre dans un Ã©tat incohÃ©rent.
                     throw "Ã‰chec de l'Ã©criture du fichier corrigÃ©."
                }
            } elseif ($madeChanges -and $useWhatIf) {
                 Write-Host "[WhatIf] Le fichier '$scriptPath' aurait Ã©tÃ© sauvegardÃ© avec $($correctionSummary.CorrectionsMade) corrections."
            } else {
                 Write-Verbose "[Correction] Aucune modification nette appliquÃ©e ou mode WhatIf actif. Fichier non sauvegardÃ©."
            }

            # Retourner le rÃ©sumÃ© de la correction (sera dans le champ .Result)
            return $correctionSummary

        } # Fin CorrectionScriptBlock
    } # Fin Begin

    process {
         # Valider chaque chemin reÃ§u
        foreach ($path in $ScriptPaths) {
            try {
                $resolvedPath = Resolve-Path -LiteralPath $path -ErrorAction Stop
                $fileInfo = Get-Item -LiteralPath $resolvedPath.ProviderPath -ErrorAction Stop

                 # VÃ©rifier aussi les permissions en Ã©criture si on n'est pas en WhatIf
                $isWritable = $false
                if (-not $WhatIfPreference) {
                    try {
                       [System.IO.File]::Open($fileInfo.FullName, 'Open', 'Write').Close() # Test rapide d'Ã©criture
                       $isWritable = $true
                    } catch {
                       Write-Warning "Le fichier '$($fileInfo.FullName)' n'est pas accessible en Ã©criture. Il sera ignorÃ© pour la correction rÃ©elle."
                    }
                }

                if ($fileInfo -is [System.IO.FileInfo] -and $fileInfo.Extension -eq '.ps1' -and ($WhatIfPreference -or $isWritable)) {
                    $validScriptPaths.Add($fileInfo)
                    Write-Verbose "Chemin validÃ© et ajoutÃ© pour correction : $($fileInfo.FullName)"
                } else {
                    if ($fileInfo.Extension -ne '.ps1') { Write-Warning "Le chemin '$($resolvedPath.ProviderPath)' n'est pas un fichier .ps1." }
                    # Le message d'erreur d'Ã©criture a dÃ©jÃ  Ã©tÃ© affichÃ©
                }
            } catch {
                 Write-Warning "Impossible de valider ou d'accÃ©der au chemin '$path': $($_.Exception.Message)"
            }
        }
    } # Fin Process

    end {
        Write-Host "Lancement de la correction parallÃ¨le pour $($validScriptPaths.Count) scripts valides et accessibles..."
        if ($validScriptPaths.Count -eq 0) {
            Write-Warning "Aucun script valide et accessible Ã  corriger."
            return # Retourne un tableau vide
        }

        # DÃ©terminer l'Ã©tat effectif de WhatIf
        $whatifEffective = $PSCmdlet.ShouldProcess("les $($validScriptPaths.Count) scripts", "Appliquer les corrections")

        # ExÃ©cuter la correction en parallÃ¨le
        $correctionResults = Invoke-OptimizedParallel -InputObject $validScriptPaths `
                                                    -ScriptBlock $correctionScriptBlock `
                                                    -MaxThreads $MaxThreads `
                                                    -SharedVariables @{ patterns = $ErrorPatterns; whatifPreferenceEffective = $whatifEffective } `
                                                    -Verbose:$VerbosePreference `
                                                    -Debug:$DebugPreference `
                                                    -ErrorAction SilentlyContinue

         # Traiter et rÃ©sumer les rÃ©sultats
        $totalIssuesFound = 0
        $totalCorrectionsAttempted = 0
        $totalCorrectionsMade = 0
        $filesCorrected = 0
        $failedScripts = 0

        foreach ($res in $correctionResults) {
            if (-not $res.Success) {
                $failedScripts++
                # Message d'erreur dÃ©jÃ  affichÃ© par le catch du ScriptBlock ou Invoke-OptimizedParallel
            } elseif ($res.Result -is [PSCustomObject]) {
                 # Additionner les compteurs du rÃ©sumÃ© retournÃ© dans .Result
                 $totalIssuesFound += $res.Result.IssuesFound
                 $totalCorrectionsAttempted += $res.Result.CorrectionsAttempted
                 $totalCorrectionsMade += $res.Result.CorrectionsMade
                 if ($res.Result.FileWritten) {
                     $filesCorrected++
                 }
            }
        }

        Write-Host "`n--- RÃ©sumÃ© de la Correction ---"
        Write-Host "Mode WhatIf Actif      : $($whatifEffective)"
        Write-Host "Scripts TentÃ©s         : $($correctionResults.Count)"
        Write-Host "Corrections RÃ©ussies   : $($correctionResults.Count - $failedScripts)"
        Write-Host "Corrections Ã‰chouÃ©es   : $failedScripts"
        Write-Host "Total ProblÃ¨mes TrouvÃ©s: $totalIssuesFound"
        # Write-Host "Corrections Tentatives : $totalCorrectionsAttempted" # Peut-Ãªtre trop dÃ©taillÃ©
        Write-Host "Corrections AppliquÃ©es : $totalCorrectionsMade ($($filesCorrected) fichiers modifiÃ©s)"

        # Optionnel : Afficher les top scripts corrigÃ©s
        if ($totalCorrectionsMade -gt 0) {
            Write-Host "`nTop 5 des scripts avec le plus de corrections appliquÃ©es :"
             $correctionResults | Where-Object { $_.Success -and $_.Result.CorrectionsMade -gt 0 } |
             Sort-Object -Property @{Expression = { $_.Result.CorrectionsMade }} -Descending |
             Select-Object -First 5 |
             ForEach-Object { Write-Host ('  - {0} ({1} corrections)' -f $_.InputObject.Name, $_.Result.CorrectionsMade) }
        }

        # Retourner les rÃ©sultats dÃ©taillÃ©s bruts de Invoke-OptimizedParallel
        return $correctionResults
    } # Fin End
}
#endregion

#region Module Exports
# Exporter uniquement les fonctions destinÃ©es Ã  l'utilisateur final
Export-ModuleMember -Function Invoke-OptimizedParallel, Invoke-ParallelScriptAnalysis, Invoke-ParallelScriptCorrection
#endregion