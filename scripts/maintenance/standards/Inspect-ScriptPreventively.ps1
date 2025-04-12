<#
.SYNOPSIS
Analyse prÃ©ventivement les scripts PowerShell pour dÃ©tecter les problÃ¨mes potentiels et les non-conformitÃ©s aux bonnes pratiques.

.DESCRIPTION
Ce script utilise PSScriptAnalyzer pour inspecter des fichiers ou des rÃ©pertoires de scripts PowerShell spÃ©cifiÃ©s.
Il identifie des problÃ¨mes tels que les variables non utilisÃ©es, l'utilisation de verbes non approuvÃ©s,
les comparaisons incorrectes avec $null, et d'autres rÃ¨gles dÃ©finies par PSScriptAnalyzer.
L'objectif est de dÃ©tecter ces problÃ¨mes de maniÃ¨re proactive avant qu'ils ne causent des erreurs ou
ne soient signalÃ©s par l'IDE, contribuant ainsi Ã  maintenir une haute qualitÃ© de code.

Le script retourne des objets dÃ©taillÃ©s pour chaque problÃ¨me trouvÃ©, facilitant l'intÃ©gration
dans des processus d'automatisation ou de reporting.

.PARAMETER Path
Chemin(s) vers le(s) fichier(s) de script (.ps1) ou le(s) rÃ©pertoire(s) Ã  analyser.
Accepte les caractÃ¨res gÃ©nÃ©riques. Obligatoire.

.PARAMETER Recurse
Si spÃ©cifiÃ©, analyse les scripts dans les sous-rÃ©pertoires du chemin fourni.

.PARAMETER IncludeRule
SpÃ©cifie un ou plusieurs noms de rÃ¨gles PSScriptAnalyzer Ã  inclure exclusivement dans l'analyse.

.PARAMETER ExcludeRule
SpÃ©cifie un ou plusieurs noms de rÃ¨gles PSScriptAnalyzer Ã  exclure de l'analyse.

.PARAMETER Severity
Filtre les rÃ©sultats pour n'afficher que les problÃ¨mes ayant une sÃ©vÃ©ritÃ© spÃ©cifique ou supÃ©rieure.
Les valeurs possibles sont : Information, Warning, Error.

.PARAMETER ShowSummary
Si spÃ©cifiÃ©, affiche un rÃ©sumÃ© du nombre de problÃ¨mes trouvÃ©s par fichier et par sÃ©vÃ©ritÃ©.

.EXAMPLE
PS> .\Inspect-ScriptPreventively.ps1 -Path "C:\Scripts\MonScript.ps1"
Analyse le fichier MonScript.ps1.

.EXAMPLE
PS> .\Inspect-ScriptPreventively.ps1 -Path "C:\Projet\*.ps1" -Severity Warning -ShowSummary
Analyse tous les fichiers .ps1 dans C:\Projet, affiche seulement les avertissements et erreurs, et fournit un rÃ©sumÃ©.

.EXAMPLE
PS> Get-ChildItem "C:\Modules" -Filter *.psm1 -Recurse | .\Inspect-ScriptPreventively.ps1 -ExcludeRule PSUseApprovedVerbs
Analyse tous les fichiers .psm1 rÃ©cursivement dans C:\Modules via le pipeline, en excluant la rÃ¨gle sur les verbes approuvÃ©s.

.OUTPUTS
PSScriptAnalyzer.DiagnosticRecord
Retourne des objets DiagnosticRecord pour chaque problÃ¨me dÃ©tectÃ© par Invoke-ScriptAnalyzer.

.NOTES
Auteur        : Votre Nom/Ã‰quipe
Date CrÃ©ation : 2024-08-01
Version       : 2.0
DÃ©pendances   : Module PSScriptAnalyzer requis. (Install-Module -Name PSScriptAnalyzer -Scope CurrentUser)
Encodage      : Assurez-vous que ce script est enregistrÃ© en UTF-8 avec BOM.

Historique des modifications :
v2.0 - 2024-08-01 - Refonte majeure :
    - Utilisation d'une fonction avancÃ©e avec CmdletBinding et paramÃ¨tres validÃ©s.
    - Renommage en 'Invoke-ScriptAnalysis' (verbe approuvÃ©).
    - Correction des problÃ¨mes PSScriptAnalyzer internes (verbes, variables, comparaison null).
    - AmÃ©lioration de la gestion des erreurs.
    - Ajout de paramÃ¨tres pour filtrer les rÃ¨gles et la sÃ©vÃ©ritÃ©.
    - Ajout d'une option de rÃ©sumÃ©.
    - Sortie d'objets structurÃ©s pour une meilleure intÃ©gration.
    - AmÃ©lioration de l'aide et des commentaires.
v1.0 - [Date PrÃ©cÃ©dente] - Version initiale.

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
    [string]$Severity = 'Information', # DÃ©faut Ã  Information pour tout voir au dÃ©part

    [Parameter()]
    [switch]$ShowSummary,

    [Parameter()]
    [switch]$Fix
)

begin {
    Write-Verbose "DÃ©but de l'analyse prÃ©ventive des scripts."

    # VÃ©rifier la disponibilitÃ© de PSScriptAnalyzer
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        Write-Error "Le module PSScriptAnalyzer n'est pas installÃ©. Veuillez l'installer avec 'Install-Module -Name PSScriptAnalyzer -Scope CurrentUser'."
        # On pourrait stopper ici, mais PSScriptAnalyzer est souvent inclus, donc on continue prudemment.
        # $PSCmdlet.ThrowTerminatingError(...) # Option plus stricte
    }

    # Convertir la sÃ©vÃ©ritÃ© en tableau pour Invoke-ScriptAnalyzer
    $SeverityFilter = @()
    switch ($Severity) {
        'Error' { $SeverityFilter = @('Error') }
        'Warning' { $SeverityFilter = @('Warning', 'Error') }
        'Information' { $SeverityFilter = @('Information', 'Warning', 'Error') }
        default { $SeverityFilter = @('Information', 'Warning', 'Error') } # SÃ©curitÃ©
    }
    Write-Verbose "Filtre de sÃ©vÃ©ritÃ© appliquÃ© : $($SeverityFilter -join ', ')"

    # Initialiser la collection pour le rÃ©sumÃ©
    $scriptResults = [System.Collections.Generic.List[object]]::new()
}

process {
    foreach ($itemPath in $Path) {
        Write-Verbose "Traitement du chemin : $itemPath"
        try {
            # RÃ©soudre le chemin pour gÃ©rer les caractÃ¨res gÃ©nÃ©riques
            $resolvedPaths = Resolve-Path $itemPath -ErrorAction Stop
        } catch {
            Write-Warning "Impossible de rÃ©soudre le chemin '$itemPath'. Erreur : $($_.Exception.Message)"
            continue # Passe au chemin suivant
        }

        foreach ($resolvedItem in $resolvedPaths) {
            $filesToAnalyze = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

            if (Test-Path -Path $resolvedItem.ProviderPath -PathType Container) {
                # C'est un rÃ©pertoire
                Write-Verbose "Analyse du rÃ©pertoire : $($resolvedItem.ProviderPath)"
                $getParams = @{
                    Path        = $resolvedItem.ProviderPath
                    Filter      = '*.ps1' # Analyse seulement les .ps1 par dÃ©faut
                    Recurse     = $Recurse
                    File        = $true
                    ErrorAction = 'SilentlyContinue' # GÃ©rer les erreurs d'accÃ¨s
                }
                $foundFiles = Get-ChildItem @getParams
                if ($null -ne $foundFiles) {
                    $foundFiles.ForEach({ $filesToAnalyze.Add($_) })
                } else {
                    Write-Verbose "Aucun fichier .ps1 trouvÃ© dans $($resolvedItem.ProviderPath) (ou accÃ¨s refusÃ©)."
                }

            } elseif ((Test-Path -Path $resolvedItem.ProviderPath -PathType Leaf) -and ($resolvedItem.ProviderPath -like '*.ps1')) {
                # C'est un fichier .ps1
                Write-Verbose "Ajout du fichier : $($resolvedItem.ProviderPath)"
                $filesToAnalyze.Add((Get-Item $resolvedItem.ProviderPath))
            } else {
                Write-Warning "Le chemin '$($resolvedItem.ProviderPath)' n'est ni un rÃ©pertoire ni un fichier .ps1 valide. IgnorÃ©."
                continue
            }

            # Analyser chaque fichier trouvÃ©
            foreach ($file in $filesToAnalyze) {
                $filePath = $file.FullName
                Write-Verbose "Analyse du fichier : $filePath"

                if (-not ($PSCmdlet.ShouldProcess($filePath, "Analyser avec PSScriptAnalyzer"))) {
                    Write-Verbose "OpÃ©ration annulÃ©e par l'utilisateur pour le fichier : $filePath"
                    continue
                }

                # PrÃ©parer les paramÃ¨tres pour Invoke-ScriptAnalyzer
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
                        Write-Verbose "ProblÃ¨mes trouvÃ©s dans '$filePath' : $($analysisResults.Count)"
                        # Ajouter le chemin du fichier aux rÃ©sultats pour le rÃ©sumÃ©
                        $resultsWithFilePath = $analysisResults | Select-Object *, @{Name = 'FilePath'; Expression = { $filePath } }
                        $scriptResults.AddRange($resultsWithFilePath)
                        # Retourner les rÃ©sultats au pipeline
                        $resultsWithFilePath | Write-Output
                    } else {
                        Write-Verbose "Aucun problÃ¨me trouvÃ© dans '$filePath' avec les filtres actuels."
                    }
                } catch {
                    Write-Warning "Erreur lors de l'analyse du fichier '$filePath'. Erreur PSScriptAnalyzer : $($_.Exception.Message)"
                }

                # Corriger les problÃ¨mes si demandÃ©
                if ($Fix -and $results.Count -gt 0) {
                    Write-Verbose "Correction des problÃ¨mes dans le fichier '$filePath'..."

                    # CrÃ©er une sauvegarde du fichier original
                    $backupPath = "$filePath.bak"
                    if (-not (Test-Path -Path $backupPath)) {
                        Copy-Item -Path $filePath -Destination $backupPath -Force
                        Write-Verbose "Sauvegarde crÃ©Ã©e: $backupPath"
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

                    # Corriger les variables non utilisÃ©es
                    $unusedVarIssues = $results | Where-Object { $_.RuleName -eq "PSUseDeclaredVarsMoreThanAssignments" }
                    if ($unusedVarIssues.Count -gt 0) {
                        Write-Verbose "Correction des variables non utilisÃ©es..."
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
                                    Write-Verbose "CorrigÃ©: Ligne $($issue.Line) - Variable non utilisÃ©e '$varName'"
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
                        Write-Host "Fichier corrigÃ©: $filePath" -ForegroundColor Green
                    } else {
                        Write-Verbose "Aucune correction automatique n'a Ã©tÃ© appliquÃ©e Ã  $filePath"
                    }
                }
            }
        }
    }
}

end {
    Write-Verbose "Analyse prÃ©ventive terminÃ©e."

    # Afficher le rÃ©sumÃ© si demandÃ©
    if ($ShowSummary -and $scriptResults.Count -gt 0) {
        Write-Host "`n--- RÃ©sumÃ© de l'Analyse PrÃ©ventive ---" -ForegroundColor Yellow

        # Grouper par fichier puis par sÃ©vÃ©ritÃ©
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

        # Afficher le tableau de rÃ©sumÃ©
        $summary | Format-Table -AutoSize

        $totalErrors = ($summary.Errors | Measure-Object -Sum).Sum
        $totalWarnings = ($summary.Warnings | Measure-Object -Sum).Sum
        $totalInformation = ($summary.Information | Measure-Object -Sum).Sum
        $totalFilesAnalyzed = ($summary.FilePath | Select-Object -Unique).Count
        $totalFilesWithIssues = $summary.Count

        Write-Host "`nTotal Fichiers AnalysÃ©s : $totalFilesAnalyzed"
        Write-Host "Total Fichiers avec ProblÃ¨mes : $totalFilesWithIssues"
        Write-Host "Total Erreurs   : $totalErrors" -ForegroundColor Red
        Write-Host "Total Avertissements : $totalWarnings" -ForegroundColor Yellow
        Write-Host "Total Informations  : $totalInformation" -ForegroundColor Cyan
        Write-Host "------------------------------------" -ForegroundColor Yellow
    } elseif ($ShowSummary) {
        Write-Host "`n--- RÃ©sumÃ© de l'Analyse PrÃ©ventive ---" -ForegroundColor Yellow
        Write-Host "Aucun problÃ¨me dÃ©tectÃ© avec les paramÃ¨tres actuels."
        Write-Host "------------------------------------" -ForegroundColor Yellow
    }
}
