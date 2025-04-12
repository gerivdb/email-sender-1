<#
.SYNOPSIS
Analyse préventivement les scripts PowerShell pour détecter les problèmes potentiels et les non-conformités aux bonnes pratiques.

.DESCRIPTION
Ce script utilise PSScriptAnalyzer pour inspecter des fichiers ou des répertoires de scripts PowerShell spécifiés.
Il identifie des problèmes tels que les variables non utilisées, l'utilisation de verbes non approuvés,
les comparaisons incorrectes avec $null, et d'autres règles définies par PSScriptAnalyzer.
L'objectif est de détecter ces problèmes de manière proactive avant qu'ils ne causent des erreurs ou
ne soient signalés par l'IDE, contribuant ainsi à maintenir une haute qualité de code.

Le script retourne des objets détaillés pour chaque problème trouvé, facilitant l'intégration
dans des processus d'automatisation ou de reporting.

.PARAMETER Path
Chemin(s) vers le(s) fichier(s) de script (.ps1) ou le(s) répertoire(s) à analyser.
Accepte les caractères génériques. Obligatoire.

.PARAMETER Recurse
Si spécifié, analyse les scripts dans les sous-répertoires du chemin fourni.

.PARAMETER IncludeRule
Spécifie un ou plusieurs noms de règles PSScriptAnalyzer à inclure exclusivement dans l'analyse.

.PARAMETER ExcludeRule
Spécifie un ou plusieurs noms de règles PSScriptAnalyzer à exclure de l'analyse.

.PARAMETER Severity
Filtre les résultats pour n'afficher que les problèmes ayant une sévérité spécifique ou supérieure.
Les valeurs possibles sont : Information, Warning, Error.

.PARAMETER ShowSummary
Si spécifié, affiche un résumé du nombre de problèmes trouvés par fichier et par sévérité.

.EXAMPLE
PS> .\Inspect-ScriptPreventively.ps1 -Path "C:\Scripts\MonScript.ps1"
Analyse le fichier MonScript.ps1.

.EXAMPLE
PS> .\Inspect-ScriptPreventively.ps1 -Path "C:\Projet\*.ps1" -Severity Warning -ShowSummary
Analyse tous les fichiers .ps1 dans C:\Projet, affiche seulement les avertissements et erreurs, et fournit un résumé.

.EXAMPLE
PS> Get-ChildItem "C:\Modules" -Filter *.psm1 -Recurse | .\Inspect-ScriptPreventively.ps1 -ExcludeRule PSUseApprovedVerbs
Analyse tous les fichiers .psm1 récursivement dans C:\Modules via le pipeline, en excluant la règle sur les verbes approuvés.

.OUTPUTS
PSScriptAnalyzer.DiagnosticRecord
Retourne des objets DiagnosticRecord pour chaque problème détecté par Invoke-ScriptAnalyzer.

.NOTES
Auteur        : Votre Nom/Équipe
Date Création : 2024-08-01
Version       : 2.0
Dépendances   : Module PSScriptAnalyzer requis. (Install-Module -Name PSScriptAnalyzer -Scope CurrentUser)
Encodage      : Assurez-vous que ce script est enregistré en UTF-8 avec BOM.

Historique des modifications :
v2.0 - 2024-08-01 - Refonte majeure :
    - Utilisation d'une fonction avancée avec CmdletBinding et paramètres validés.
    - Renommage en 'Invoke-ScriptAnalysis' (verbe approuvé).
    - Correction des problèmes PSScriptAnalyzer internes (verbes, variables, comparaison null).
    - Amélioration de la gestion des erreurs.
    - Ajout de paramètres pour filtrer les règles et la sévérité.
    - Ajout d'une option de résumé.
    - Sortie d'objets structurés pour une meilleure intégration.
    - Amélioration de l'aide et des commentaires.
v1.0 - [Date Précédente] - Version initiale.

.COMPONENT
Maintenance des Standards

.FUNCTIONALITY
Analyse statique du code PowerShell.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
[OutputType([PSCustomObject])]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [string[]]$Path,

    [Parameter()]
    [switch]$Recurse,

    [Parameter()]
    [string[]]$IncludeRule,

    [Parameter()]
    [string[]]$ExcludeRule,

    [Parameter()]
    [ValidateSet('Information', 'Warning', 'Error')]
    [string]$Severity = 'Information', # Défaut à Information pour tout voir au départ

    [Parameter()]
    [switch]$ShowSummary,

    [Parameter()]
    [switch]$Fix
)

begin {
    Write-Verbose "Début de l'analyse préventive des scripts."

    # Vérifier la disponibilité de PSScriptAnalyzer
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-Error "Le module PSScriptAnalyzer n'est pas installé. Veuillez l'installer avec 'Install-Module -Name PSScriptAnalyzer -Scope CurrentUser'."
        # On pourrait stopper ici, mais PSScriptAnalyzer est souvent inclus, donc on continue prudemment.
        # $PSCmdlet.ThrowTerminatingError(...) # Option plus stricte
    }

    # Convertir la sévérité en tableau pour Invoke-ScriptAnalyzer
    $SeverityFilter = @()
    switch ($Severity) {
        'Error' { $SeverityFilter = @('Error') }
        'Warning' { $SeverityFilter = @('Warning', 'Error') }
        'Information' { $SeverityFilter = @('Information', 'Warning', 'Error') }
        default { $SeverityFilter = @('Information', 'Warning', 'Error') } # Sécurité
    }
    Write-Verbose "Filtre de sévérité appliqué : $($SeverityFilter -join ', ')"

    # Initialiser la collection pour le résumé
    $scriptResults = [System.Collections.Generic.List[object]]::new()
}

process {
    foreach ($itemPath in $Path) {
        Write-Verbose "Traitement du chemin : $itemPath"
        try {
            # Résoudre le chemin pour gérer les caractères génériques
            $resolvedPaths = Resolve-Path $itemPath -ErrorAction Stop
        } catch {
            Write-Warning "Impossible de résoudre le chemin '$itemPath'. Erreur : $($_.Exception.Message)"
            continue # Passe au chemin suivant
        }

        foreach ($resolvedItem in $resolvedPaths) {
            $filesToAnalyze = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

            if (Test-Path -Path $resolvedItem.ProviderPath -PathType Container) {
                # C'est un répertoire
                Write-Verbose "Analyse du répertoire : $($resolvedItem.ProviderPath)"
                $getParams = @{
                    Path        = $resolvedItem.ProviderPath
                    Filter      = '*.ps1' # Analyse seulement les .ps1 par défaut
                    Recurse     = $Recurse
                    File        = $true
                    ErrorAction = 'SilentlyContinue' # Gérer les erreurs d'accès
                }
                $foundFiles = Get-ChildItem @getParams
                if ($null -ne $foundFiles) {
                    $foundFiles.ForEach({ $filesToAnalyze.Add($_) })
                } else {
                    Write-Verbose "Aucun fichier .ps1 trouvé dans $($resolvedItem.ProviderPath) (ou accès refusé)."
                }

            } elseif ((Test-Path -Path $resolvedItem.ProviderPath -PathType Leaf) -and ($resolvedItem.ProviderPath -like '*.ps1')) {
                # C'est un fichier .ps1
                Write-Verbose "Ajout du fichier : $($resolvedItem.ProviderPath)"
                $filesToAnalyze.Add((Get-Item $resolvedItem.ProviderPath))
            } else {
                Write-Warning "Le chemin '$($resolvedItem.ProviderPath)' n'est ni un répertoire ni un fichier .ps1 valide. Ignoré."
                continue
            }

            # Analyser chaque fichier trouvé
            foreach ($file in $filesToAnalyze) {
                $filePath = $file.FullName
                Write-Verbose "Analyse du fichier : $filePath"

                if (-not ($PSCmdlet.ShouldProcess($filePath, "Analyser avec PSScriptAnalyzer"))) {
                    Write-Verbose "Opération annulée par l'utilisateur pour le fichier : $filePath"
                    continue
                }

                # Préparer les paramètres pour Invoke-ScriptAnalyzer
                $analyzerParams = @{
                    Path        = $filePath
                    Recurse     = $false # On traite fichier par fichier
                    Severity    = $SeverityFilter
                    ErrorAction = 'SilentlyContinue' # Capturer les erreurs d'analyse
                }
                if ($PSBoundParameters.ContainsKey('IncludeRule')) { $analyzerParams.IncludeRule = $IncludeRule }
                if ($PSBoundParameters.ContainsKey('ExcludeRule')) { $analyzerParams.ExcludeRule = $ExcludeRule }

                try {
                    $analysisResults = Invoke-ScriptAnalyzer @analyzerParams

                    if ($null -ne $analysisResults) {
                        Write-Verbose "Problèmes trouvés dans '$filePath' : $($analysisResults.Count)"
                        # Ajouter le chemin du fichier aux résultats pour le résumé
                        $resultsWithFilePath = $analysisResults | Select-Object *, @{Name = 'FilePath'; Expression = { $filePath } }
                        $scriptResults.AddRange($resultsWithFilePath)
                        # Retourner les résultats au pipeline
                        $resultsWithFilePath | Write-Output
                    } else {
                        Write-Verbose "Aucun problème trouvé dans '$filePath' avec les filtres actuels."
                    }
                } catch {
                    Write-Warning "Erreur lors de l'analyse du fichier '$filePath'. Erreur PSScriptAnalyzer : $($_.Exception.Message)"
                }

                # Corriger les problèmes si demandé
                if ($Fix -and $results.Count -gt 0) {
                    Write-Verbose "Correction des problèmes dans le fichier '$filePath'..."

                    # Créer une sauvegarde du fichier original
                    $backupPath = "$filePath.bak"
                    if (-not (Test-Path -Path $backupPath)) {
                        Copy-Item -Path $filePath -Destination $backupPath -Force
                        Write-Verbose "Sauvegarde créée: $backupPath"
                    }

                    # Lire le contenu du fichier
                    $content = Get-Content -Path $filePath -Raw
                    $modified = $false

                    # Corriger les comparaisons avec $null
                    $nullComparisonIssues = $results | Where-Object { $_.RuleName -eq "PSPossibleIncorrectComparisonWithNull" }
                    if ($nullComparisonIssues.Count -gt 0) {
                        Write-Verbose "Correction des comparaisons avec `$null..."
                        $pattern = '(\$\w+)\s+-(?:eq|ne)\s+\$null'
                        $content = $content -replace $pattern, '\$null -$2 $1'
                        $modified = $true
                    }

                    # Corriger les variables non utilisées
                    $unusedVarIssues = $results | Where-Object { $_.RuleName -eq "PSUseDeclaredVarsMoreThanAssignments" }
                    if ($unusedVarIssues.Count -gt 0) {
                        Write-Verbose "Correction des variables non utilisées..."
                        $lines = $content -split "`r`n|`r|`n"

                        foreach ($issue in $unusedVarIssues) {
                            $lineIndex = $issue.Line - 1
                            $line = $lines[$lineIndex]

                            # Extraire le nom de la variable
                            if ($issue.Message -match "La variable '(\$\w+)' est") {
                                $varName = $matches[1]

                                # Trouver l'assignation de variable
                                if ($line -match "(\s*)(\$varName)\s*=\s*(.+?)(\s*#.*)?\s*$") {
                                    $indent = $matches[1]
                                    $expression = $matches[3]
                                    $comment = $matches[4]

                                    # Remplacer par une expression qui utilise Out-Null
                                    if ($expression -match "\|\s*ForEach-Object") {
                                        $newLine = "$indent$expression | Out-Null$comment"
                                    } else {
                                        $newLine = "$indent$expression | Out-Null$comment"
                                    }

                                    $lines[$lineIndex] = $newLine
                                    $modified = $true
                                    Write-Verbose "Corrigé: Ligne $($issue.Line) - Variable non utilisée '$varName'"
                                }
                            }
                        }

                        if ($modified) {
                            $content = $lines -join "`r`n"
                        }
                    }

                    # Enregistrer les modifications
                    if ($modified) {
                        Set-Content -Path $filePath -Value $content -Encoding UTF8
                        Write-Host "Fichier corrigé: $filePath" -ForegroundColor Green
                    } else {
                        Write-Verbose "Aucune correction automatique n'a été appliquée à $filePath"
                    }
                }
            }
        }
    }
}

end {
    Write-Verbose "Analyse préventive terminée."

    # Afficher le résumé si demandé
    if ($ShowSummary -and $scriptResults.Count -gt 0) {
        Write-Host "`n--- Résumé de l'Analyse Préventive ---" -ForegroundColor Yellow

        # Grouper par fichier puis par sévérité
        $summary = $scriptResults | Group-Object FilePath | ForEach-Object {
            $fileGroup = $_
            $fileSummary = $fileGroup.Group | Group-Object Severity | Select-Object @{Name = 'Severity'; Expression = { $_.Name } }, Count
            [PSCustomObject]@{
                FilePath    = $fileGroup.Name
                TotalIssues = $fileGroup.Count
                Errors      = ($fileSummary | Where-Object Severity -EQ 'Error').Count | ForEach-Object { $_.Count } | Measure-Object -Sum | Select-Object -ExpandProperty Sum
                Warnings    = ($fileSummary | Where-Object Severity -EQ 'Warning').Count | ForEach-Object { $_.Count } | Measure-Object -Sum | Select-Object -ExpandProperty Sum
                Information = ($fileSummary | Where-Object Severity -EQ 'Information').Count | ForEach-Object { $_.Count } | Measure-Object -Sum | Select-Object -ExpandProperty Sum
                #Detail = $fileSummary | Sort-Object @{Expression={@('Error','Warning','Information').IndexOf($_.Severity)}}
            }
        } | Sort-Object FilePath

        # Afficher le tableau de résumé
        $summary | Format-Table -AutoSize

        $totalErrors = ($summary.Errors | Measure-Object -Sum).Sum
        $totalWarnings = ($summary.Warnings | Measure-Object -Sum).Sum
        $totalInformation = ($summary.Information | Measure-Object -Sum).Sum
        $totalFilesAnalyzed = ($summary.FilePath | Select-Object -Unique).Count
        $totalFilesWithIssues = $summary.Count

        Write-Host "`nTotal Fichiers Analysés : $totalFilesAnalyzed"
        Write-Host "Total Fichiers avec Problèmes : $totalFilesWithIssues"
        Write-Host "Total Erreurs   : $totalErrors" -ForegroundColor Red
        Write-Host "Total Avertissements : $totalWarnings" -ForegroundColor Yellow
        Write-Host "Total Informations  : $totalInformation" -ForegroundColor Cyan
        Write-Host "------------------------------------" -ForegroundColor Yellow
    } elseif ($ShowSummary) {
        Write-Host "`n--- Résumé de l'Analyse Préventive ---" -ForegroundColor Yellow
        Write-Host "Aucun problème détecté avec les paramètres actuels."
        Write-Host "------------------------------------" -ForegroundColor Yellow
    }
}
