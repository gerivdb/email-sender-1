#Requires -Version 5.1
<#
.SYNOPSIS
    DÃ©tecte les changements significatifs dans les fichiers d'une pull request.

.DESCRIPTION
    Ce script analyse les modifications apportÃ©es aux fichiers d'une pull request
    et dÃ©termine si elles sont significatives en fonction de divers critÃ¨res.

.PARAMETER RepositoryPath
    Le chemin du dÃ©pÃ´t Ã  analyser.
    Par dÃ©faut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER PullRequestNumber
    Le numÃ©ro de la pull request Ã  analyser.
    Si non spÃ©cifiÃ©, la derniÃ¨re pull request sera utilisÃ©e.

.PARAMETER OutputPath
    Le chemin oÃ¹ enregistrer les rÃ©sultats de l'analyse.
    Par dÃ©faut: "reports\pr-analysis\significant_changes.json"

.PARAMETER ThresholdRatio
    Le ratio de changement Ã  partir duquel une modification est considÃ©rÃ©e comme significative.
    Par dÃ©faut: 0.1 (10%)

.PARAMETER MinimumChanges
    Le nombre minimum de lignes modifiÃ©es pour qu'un fichier soit considÃ©rÃ© comme significativement modifiÃ©.
    Par dÃ©faut: 5

.PARAMETER DetailLevel
    Le niveau de dÃ©tail des rÃ©sultats.
    Valeurs possibles: "Basic", "Detailed", "Comprehensive"
    Par dÃ©faut: "Detailed"

.EXAMPLE
    .\Test-SignificantChanges.ps1
    Analyse les changements significatifs dans la derniÃ¨re pull request.

.EXAMPLE
    .\Test-SignificantChanges.ps1 -PullRequestNumber 42 -ThresholdRatio 0.05 -DetailLevel "Comprehensive"
    Analyse les changements significatifs dans la pull request #42 avec un seuil de 5% et un niveau de dÃ©tail complet.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$RepositoryPath = "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo",

    [Parameter()]
    [int]$PullRequestNumber = 0,

    [Parameter()]
    [string]$OutputPath = "reports\pr-analysis\significant_changes.json",

    [Parameter()]
    [double]$ThresholdRatio = 0.1,

    [Parameter()]
    [int]$MinimumChanges = 5,

    [Parameter()]
    [ValidateSet("Basic", "Detailed", "Comprehensive")]
    [string]$DetailLevel = "Detailed"
)

# Importer les modules nÃ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$modulesToImport = @(
    "FileContentIndexer.psm1"
)

foreach ($module in $modulesToImport) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath $module
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        Write-Error "Module $module non trouvÃ© Ã  l'emplacement: $modulePath"
        exit 1
    }
}

# Fonction pour obtenir les informations sur la pull request
function Get-PullRequestInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter()]
        [int]$PRNumber = 0
    )

    try {
        # VÃ©rifier si le dÃ©pÃ´t existe
        if (-not (Test-Path -Path $RepoPath)) {
            throw "Le dÃ©pÃ´t n'existe pas Ã  l'emplacement spÃ©cifiÃ©: $RepoPath"
        }

        # Changer de rÃ©pertoire vers le dÃ©pÃ´t
        Push-Location -Path $RepoPath

        try {
            # Si aucun numÃ©ro de PR n'est spÃ©cifiÃ©, utiliser la derniÃ¨re PR
            if ($PRNumber -eq 0) {
                $prs = gh pr list --json number, title, headRefName, baseRefName, createdAt --limit 1 | ConvertFrom-Json
                if ($prs.Count -eq 0) {
                    throw "Aucune pull request trouvÃ©e dans le dÃ©pÃ´t."
                }
                $pr = $prs[0]
            } else {
                $pr = gh pr view $PRNumber --json number, title, headRefName, baseRefName, createdAt | ConvertFrom-Json
                if ($null -eq $pr) {
                    throw "Pull request #$PRNumber non trouvÃ©e."
                }
            }

            # Obtenir les fichiers modifiÃ©s
            $files = gh pr view $pr.number --json files | ConvertFrom-Json

            # CrÃ©er l'objet d'informations sur la PR
            $prInfo = [PSCustomObject]@{
                Number     = $pr.number
                Title      = $pr.title
                HeadBranch = $pr.headRefName
                BaseBranch = $pr.baseRefName
                CreatedAt  = $pr.createdAt
                Files      = $files.files
                FileCount  = $files.files.Count
                Additions  = ($files.files | Measure-Object additions -Sum).Sum
                Deletions  = ($files.files | Measure-Object deletions -Sum).Sum
                Changes    = ($files.files | Measure-Object additions, deletions -Sum).Sum
            }

            return $prInfo
        } finally {
            # Revenir au rÃ©pertoire prÃ©cÃ©dent
            Pop-Location
        }
    } catch {
        Write-Error "Erreur lors de la rÃ©cupÃ©ration des informations sur la pull request: $_"
        return $null
    }
}

# Fonction pour obtenir le contenu des versions d'un fichier
function Get-FileVersions {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoPath,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$BaseBranch,

        [Parameter(Mandatory = $true)]
        [string]$HeadBranch
    )

    try {
        # Changer de rÃ©pertoire vers le dÃ©pÃ´t
        Push-Location -Path $RepoPath

        try {
            $baseContent = $null
            $headContent = $null

            # Obtenir le contenu de la version de base
            try {
                $baseContent = git show "$BaseBranch`:$FilePath" 2>$null
            } catch {
                # Le fichier n'existe peut-Ãªtre pas dans la branche de base
                $baseContent = ""
            }

            # Obtenir le contenu de la version de tÃªte
            try {
                $headContent = git show "$HeadBranch`:$FilePath" 2>$null
            } catch {
                # Le fichier n'existe peut-Ãªtre pas dans la branche de tÃªte
                $headContent = ""
            }

            return [PSCustomObject]@{
                BaseBranch     = $BaseBranch
                HeadBranch     = $HeadBranch
                FilePath       = $FilePath
                BaseContent    = $baseContent
                HeadContent    = $headContent
                IsNewFile      = [string]::IsNullOrEmpty($baseContent) -and -not [string]::IsNullOrEmpty($headContent)
                IsDeletedFile  = -not [string]::IsNullOrEmpty($baseContent) -and [string]::IsNullOrEmpty($headContent)
                IsModifiedFile = -not [string]::IsNullOrEmpty($baseContent) -and -not [string]::IsNullOrEmpty($headContent) -and ($baseContent -ne $headContent)
            }
        } finally {
            # Revenir au rÃ©pertoire prÃ©cÃ©dent
            Pop-Location
        }
    } catch {
        Write-Error "Erreur lors de la rÃ©cupÃ©ration des versions du fichier $FilePath : $_"
        return $null
    }
}

# Fonction pour analyser les changements significatifs
function Test-FileChanges {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$FileVersions,

        [Parameter(Mandatory = $true)]
        [object]$Indexer,

        [Parameter(Mandatory = $true)]
        [double]$Threshold,

        [Parameter(Mandatory = $true)]
        [int]$MinChanges
    )

    try {
        # CrÃ©er l'objet de rÃ©sultat
        $result = [PSCustomObject]@{
            FilePath       = $FileVersions.FilePath
            IsNewFile      = $FileVersions.IsNewFile
            IsDeletedFile  = $FileVersions.IsDeletedFile
            IsModifiedFile = $FileVersions.IsModifiedFile
            IsSignificant  = $false
            Reason         = ""
            Details        = $null
            Score          = 0 # Score de significativitÃ©
        }

        # VÃ©rifier si le fichier est nouveau ou supprimÃ©
        if ($FileVersions.IsNewFile) {
            $result.IsSignificant = $true
            $result.Reason = "Nouveau fichier"
            $result.Score = 100
            return $result
        }

        if ($FileVersions.IsDeletedFile) {
            $result.IsSignificant = $true
            $result.Reason = "Fichier supprimÃ©"
            $result.Score = 100
            return $result
        }

        # Comparer les versions
        $comparison = Compare-FileVersions -Indexer $Indexer -FilePath $FileVersions.FilePath -OldContent $FileVersions.BaseContent -NewContent $FileVersions.HeadContent

        # Stocker les dÃ©tails de la comparaison
        $result.Details = $comparison

        # VÃ©rifier si les changements sont significatifs
        $isSignificant = $false
        $reasons = @()
        $score = 0

        # VÃ©rifier les fonctions ajoutÃ©es, supprimÃ©es ou modifiÃ©es
        if ($comparison.AddedFunctions.Count -gt 0) {
            $isSignificant = $true
            $reasons += "Fonctions ajoutÃ©es: $($comparison.AddedFunctions.Count)"
            $score += 20 * $comparison.AddedFunctions.Count
        }

        if ($comparison.RemovedFunctions.Count -gt 0) {
            $isSignificant = $true
            $reasons += "Fonctions supprimÃ©es: $($comparison.RemovedFunctions.Count)"
            $score += 20 * $comparison.RemovedFunctions.Count
        }

        if ($comparison.ModifiedFunctions.Count -gt 0) {
            $isSignificant = $true
            $reasons += "Fonctions modifiÃ©es: $($comparison.ModifiedFunctions.Count)"
            $score += 15 * $comparison.ModifiedFunctions.Count
        }

        # VÃ©rifier les classes ajoutÃ©es ou supprimÃ©es
        if ($comparison.AddedClasses.Count -gt 0) {
            $isSignificant = $true
            $reasons += "Classes ajoutÃ©es: $($comparison.AddedClasses.Count)"
            $score += 25 * $comparison.AddedClasses.Count
        }

        if ($comparison.RemovedClasses.Count -gt 0) {
            $isSignificant = $true
            $reasons += "Classes supprimÃ©es: $($comparison.RemovedClasses.Count)"
            $score += 25 * $comparison.RemovedClasses.Count
        }

        # VÃ©rifier les imports ajoutÃ©s ou supprimÃ©s
        if ($comparison.AddedImports.Count -gt 0) {
            $reasons += "Imports ajoutÃ©s: $($comparison.AddedImports.Count)"
            $score += 5 * $comparison.AddedImports.Count

            # VÃ©rifier si les imports sont significatifs (frameworks importants)
            $importantImports = @('System', 'Microsoft', 'Threading', 'Parallel', 'Async', 'Task', 'Reflection')
            foreach ($import in $comparison.AddedImports) {
                foreach ($important in $importantImports) {
                    if ($import.Name -like "*$important*") {
                        $isSignificant = $true
                        $score += 10
                        break
                    }
                }
            }
        }

        if ($comparison.RemovedImports.Count -gt 0) {
            $reasons += "Imports supprimÃ©s: $($comparison.RemovedImports.Count)"
            $score += 5 * $comparison.RemovedImports.Count
        }

        # VÃ©rifier le ratio de changement
        if ($comparison.ChangeRatio -ge $Threshold) {
            $isSignificant = $true
            $reasons += "Ratio de changement Ã©levÃ©: $([Math]::Round($comparison.ChangeRatio * 100, 2))%"
            $score += [Math]::Min(50, [Math]::Round($comparison.ChangeRatio * 100))
        }

        # VÃ©rifier le nombre minimum de lignes modifiÃ©es
        $totalChanges = $comparison.AddedLines + $comparison.RemovedLines
        if ($totalChanges -ge $MinChanges) {
            $isSignificant = $true
            $reasons += "Nombre de lignes modifiÃ©es: $totalChanges"
            $score += [Math]::Min(30, $totalChanges)
        }

        # VÃ©rifier les mots-clÃ©s importants dans les modifications
        $keywords = @('security', 'performance', 'optimization', 'critical', 'fix', 'bug', 'error', 'exception', 'crash', 'memory', 'leak')
        $content = $FileVersions.HeadContent
        foreach ($keyword in $keywords) {
            if ($content -match $keyword) {
                $isSignificant = $true
                $reasons += "Mot-clÃ© important dÃ©tectÃ©: $keyword"
                $score += 15
                break
            }
        }

        # Mettre Ã  jour le rÃ©sultat
        $result.IsSignificant = $isSignificant
        $result.Reason = $reasons -join ", "
        $result.Score = [Math]::Min(100, $score)

        return $result
    } catch {
        Write-Error "Erreur lors de l'analyse des changements du fichier $($FileVersions.FilePath) : $_"
        return $null
    }
}

# Point d'entrÃ©e principal
try {
    # Obtenir les informations sur la pull request
    $prInfo = Get-PullRequestInfo -RepoPath $RepositoryPath -PRNumber $PullRequestNumber
    if ($null -eq $prInfo) {
        Write-Error "Impossible d'obtenir les informations sur la pull request."
        exit 1
    }

    # Afficher les informations sur la pull request
    Write-Host "Informations sur la pull request:" -ForegroundColor Cyan
    Write-Host "  NumÃ©ro: #$($prInfo.Number)" -ForegroundColor White
    Write-Host "  Titre: $($prInfo.Title)" -ForegroundColor White
    Write-Host "  Branche source: $($prInfo.HeadBranch)" -ForegroundColor White
    Write-Host "  Branche cible: $($prInfo.BaseBranch)" -ForegroundColor White
    Write-Host "  Fichiers modifiÃ©s: $($prInfo.FileCount)" -ForegroundColor White
    Write-Host "  Ajouts: $($prInfo.Additions)" -ForegroundColor White
    Write-Host "  Suppressions: $($prInfo.Deletions)" -ForegroundColor White
    Write-Host "  Modifications totales: $($prInfo.Changes)" -ForegroundColor White

    # CrÃ©er l'indexeur de contenu
    $indexer = New-FileContentIndexer -IndexPath (Join-Path -Path $env:TEMP -ChildPath "PRFileIndexes") -PersistIndices $true
    if ($null -eq $indexer) {
        Write-Error "Impossible de crÃ©er l'indexeur de contenu."
        exit 1
    }

    # Analyser chaque fichier
    $results = [System.Collections.Generic.List[object]]::new()
    $significantFiles = 0
    $totalFiles = $prInfo.Files.Count

    Write-Host "`nAnalyse des changements significatifs..." -ForegroundColor Cyan
    Write-Host "  Seuil de ratio de changement: $([Math]::Round($ThresholdRatio * 100, 2))%" -ForegroundColor White
    Write-Host "  Nombre minimum de lignes modifiÃ©es: $MinimumChanges" -ForegroundColor White
    Write-Host "  Niveau de dÃ©tail: $DetailLevel" -ForegroundColor White

    $i = 0
    foreach ($file in $prInfo.Files) {
        $i++
        $filePath = $file.path

        # Afficher la progression
        Write-Progress -Activity "Analyse des changements significatifs" -Status "Fichier $i/$totalFiles" -PercentComplete (($i / $totalFiles) * 100)

        # Obtenir les versions du fichier
        $fileVersions = Get-FileVersions -RepoPath $RepositoryPath -FilePath $filePath -BaseBranch $prInfo.BaseBranch -HeadBranch $prInfo.HeadBranch
        if ($null -eq $fileVersions) {
            Write-Warning "Impossible d'obtenir les versions du fichier: $filePath"
            continue
        }

        # Analyser les changements
        $fileResult = Test-FileChanges -FileVersions $fileVersions -Indexer $indexer -Threshold $ThresholdRatio -MinChanges $MinimumChanges
        if ($null -eq $fileResult) {
            Write-Warning "Impossible d'analyser les changements du fichier: $filePath"
            continue
        }

        # Ajouter le rÃ©sultat Ã  la liste
        $results.Add($fileResult)

        # Mettre Ã  jour le compteur de fichiers significatifs
        if ($fileResult.IsSignificant) {
            $significantFiles++
        }
    }

    Write-Progress -Activity "Analyse des changements significatifs" -Completed

    # CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # CrÃ©er l'objet de rÃ©sultat final
    $finalResult = [PSCustomObject]@{
        PullRequest      = [PSCustomObject]@{
            Number     = $prInfo.Number
            Title      = $prInfo.Title
            HeadBranch = $prInfo.HeadBranch
            BaseBranch = $prInfo.BaseBranch
            CreatedAt  = $prInfo.CreatedAt
        }
        TotalFiles       = $totalFiles
        SignificantFiles = $significantFiles
        SignificantRatio = if ($totalFiles -gt 0) { [Math]::Round(($significantFiles / $totalFiles) * 100, 2) } else { 0 }
        ThresholdRatio   = [Math]::Round($ThresholdRatio * 100, 2)
        MinimumChanges   = $MinimumChanges
        DetailLevel      = $DetailLevel
        Results          = $results
    }

    # Filtrer les dÃ©tails en fonction du niveau de dÃ©tail
    if ($DetailLevel -eq "Basic") {
        foreach ($result in $finalResult.Results) {
            $result.Details = $null
        }
    } elseif ($DetailLevel -eq "Detailed") {
        foreach ($result in $finalResult.Results) {
            if ($null -ne $result.Details) {
                # Conserver uniquement les informations essentielles
                $result.Details = [PSCustomObject]@{
                    AddedLines         = $result.Details.AddedLines
                    RemovedLines       = $result.Details.RemovedLines
                    ModifiedLines      = $result.Details.ModifiedLines
                    ChangeRatio        = $result.Details.ChangeRatio
                    AddedFunctions     = $result.Details.AddedFunctions.Count
                    RemovedFunctions   = $result.Details.RemovedFunctions.Count
                    ModifiedFunctions  = $result.Details.ModifiedFunctions.Count
                    AddedClasses       = $result.Details.AddedClasses.Count
                    RemovedClasses     = $result.Details.RemovedClasses.Count
                    AddedImports       = $result.Details.AddedImports.Count
                    RemovedImports     = $result.Details.RemovedImports.Count
                    SignificantChanges = $result.Details.SignificantChanges
                }
            }
        }
    }

    # Trier les rÃ©sultats par score
    $finalResult.Results = $finalResult.Results | Sort-Object -Property Score -Descending

    # Enregistrer le rÃ©sultat
    $finalResult | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8

    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© de l'analyse:" -ForegroundColor Cyan
    Write-Host "  Fichiers analysÃ©s: $totalFiles" -ForegroundColor White
    Write-Host "  Fichiers avec changements significatifs: $significantFiles ($($finalResult.SignificantRatio)%)" -ForegroundColor White
    Write-Host "  RÃ©sultat enregistrÃ©: $OutputPath" -ForegroundColor White

    # Afficher les fichiers avec changements significatifs
    if ($significantFiles -gt 0) {
        Write-Host "`nFichiers avec changements significatifs:" -ForegroundColor Yellow
        foreach ($result in ($results | Where-Object { $_.IsSignificant } | Sort-Object -Property Score -Descending)) {
            $scoreColor = switch ($result.Score) {
                { $_ -ge 80 } { "Red" }
                { $_ -ge 50 } { "Yellow" }
                default { "White" }
            }

            Write-Host "  $($result.FilePath)" -ForegroundColor White
            Write-Host "    Score: $($result.Score)/100" -ForegroundColor $scoreColor
            Write-Host "    Raison: $($result.Reason)" -ForegroundColor Gray
        }
    }

    # Retourner le rÃ©sultat
    return $finalResult
} catch {
    Write-Error "Erreur lors de l'analyse des changements significatifs: $_"
    exit 1
}
