#Requires -Version 5.1
<#
.SYNOPSIS
    Détecte les changements significatifs dans les fichiers d'une pull request.

.DESCRIPTION
    Ce script analyse les modifications apportées aux fichiers d'une pull request
    et détermine si elles sont significatives en fonction de divers critères.

.PARAMETER RepositoryPath
    Le chemin du dépôt à analyser.
    Par défaut: "D:\DO\WEB\N8N_tests\PROJETS\PR-Analysis-TestRepo"

.PARAMETER PullRequestNumber
    Le numéro de la pull request à analyser.
    Si non spécifié, la dernière pull request sera utilisée.

.PARAMETER OutputPath
    Le chemin où enregistrer les résultats de l'analyse.
    Par défaut: "reports\pr-analysis\significant_changes.json"

.PARAMETER ThresholdRatio
    Le ratio de changement à partir duquel une modification est considérée comme significative.
    Par défaut: 0.1 (10%)

.PARAMETER MinimumChanges
    Le nombre minimum de lignes modifiées pour qu'un fichier soit considéré comme significativement modifié.
    Par défaut: 5

.PARAMETER DetailLevel
    Le niveau de détail des résultats.
    Valeurs possibles: "Basic", "Detailed", "Comprehensive"
    Par défaut: "Detailed"

.EXAMPLE
    .\Test-SignificantChanges.ps1
    Analyse les changements significatifs dans la dernière pull request.

.EXAMPLE
    .\Test-SignificantChanges.ps1 -PullRequestNumber 42 -ThresholdRatio 0.05 -DetailLevel "Comprehensive"
    Analyse les changements significatifs dans la pull request #42 avec un seuil de 5% et un niveau de détail complet.

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

# Importer les modules nécessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
$modulesToImport = @(
    "FileContentIndexer.psm1"
)

foreach ($module in $modulesToImport) {
    $modulePath = Join-Path -Path $modulesPath -ChildPath $module
    if (Test-Path -Path $modulePath) {
        Import-Module $modulePath -Force
    } else {
        Write-Error "Module $module non trouvé à l'emplacement: $modulePath"
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
        # Vérifier si le dépôt existe
        if (-not (Test-Path -Path $RepoPath)) {
            throw "Le dépôt n'existe pas à l'emplacement spécifié: $RepoPath"
        }

        # Changer de répertoire vers le dépôt
        Push-Location -Path $RepoPath

        try {
            # Si aucun numéro de PR n'est spécifié, utiliser la dernière PR
            if ($PRNumber -eq 0) {
                $prs = gh pr list --json number, title, headRefName, baseRefName, createdAt --limit 1 | ConvertFrom-Json
                if ($prs.Count -eq 0) {
                    throw "Aucune pull request trouvée dans le dépôt."
                }
                $pr = $prs[0]
            } else {
                $pr = gh pr view $PRNumber --json number, title, headRefName, baseRefName, createdAt | ConvertFrom-Json
                if ($null -eq $pr) {
                    throw "Pull request #$PRNumber non trouvée."
                }
            }

            # Obtenir les fichiers modifiés
            $files = gh pr view $pr.number --json files | ConvertFrom-Json

            # Créer l'objet d'informations sur la PR
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
            # Revenir au répertoire précédent
            Pop-Location
        }
    } catch {
        Write-Error "Erreur lors de la récupération des informations sur la pull request: $_"
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
        # Changer de répertoire vers le dépôt
        Push-Location -Path $RepoPath

        try {
            $baseContent = $null
            $headContent = $null

            # Obtenir le contenu de la version de base
            try {
                $baseContent = git show "$BaseBranch`:$FilePath" 2>$null
            } catch {
                # Le fichier n'existe peut-être pas dans la branche de base
                $baseContent = ""
            }

            # Obtenir le contenu de la version de tête
            try {
                $headContent = git show "$HeadBranch`:$FilePath" 2>$null
            } catch {
                # Le fichier n'existe peut-être pas dans la branche de tête
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
            # Revenir au répertoire précédent
            Pop-Location
        }
    } catch {
        Write-Error "Erreur lors de la récupération des versions du fichier $FilePath : $_"
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
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            FilePath       = $FileVersions.FilePath
            IsNewFile      = $FileVersions.IsNewFile
            IsDeletedFile  = $FileVersions.IsDeletedFile
            IsModifiedFile = $FileVersions.IsModifiedFile
            IsSignificant  = $false
            Reason         = ""
            Details        = $null
            Score          = 0 # Score de significativité
        }

        # Vérifier si le fichier est nouveau ou supprimé
        if ($FileVersions.IsNewFile) {
            $result.IsSignificant = $true
            $result.Reason = "Nouveau fichier"
            $result.Score = 100
            return $result
        }

        if ($FileVersions.IsDeletedFile) {
            $result.IsSignificant = $true
            $result.Reason = "Fichier supprimé"
            $result.Score = 100
            return $result
        }

        # Comparer les versions
        $comparison = Compare-FileVersions -Indexer $Indexer -FilePath $FileVersions.FilePath -OldContent $FileVersions.BaseContent -NewContent $FileVersions.HeadContent

        # Stocker les détails de la comparaison
        $result.Details = $comparison

        # Vérifier si les changements sont significatifs
        $isSignificant = $false
        $reasons = @()
        $score = 0

        # Vérifier les fonctions ajoutées, supprimées ou modifiées
        if ($comparison.AddedFunctions.Count -gt 0) {
            $isSignificant = $true
            $reasons += "Fonctions ajoutées: $($comparison.AddedFunctions.Count)"
            $score += 20 * $comparison.AddedFunctions.Count
        }

        if ($comparison.RemovedFunctions.Count -gt 0) {
            $isSignificant = $true
            $reasons += "Fonctions supprimées: $($comparison.RemovedFunctions.Count)"
            $score += 20 * $comparison.RemovedFunctions.Count
        }

        if ($comparison.ModifiedFunctions.Count -gt 0) {
            $isSignificant = $true
            $reasons += "Fonctions modifiées: $($comparison.ModifiedFunctions.Count)"
            $score += 15 * $comparison.ModifiedFunctions.Count
        }

        # Vérifier les classes ajoutées ou supprimées
        if ($comparison.AddedClasses.Count -gt 0) {
            $isSignificant = $true
            $reasons += "Classes ajoutées: $($comparison.AddedClasses.Count)"
            $score += 25 * $comparison.AddedClasses.Count
        }

        if ($comparison.RemovedClasses.Count -gt 0) {
            $isSignificant = $true
            $reasons += "Classes supprimées: $($comparison.RemovedClasses.Count)"
            $score += 25 * $comparison.RemovedClasses.Count
        }

        # Vérifier les imports ajoutés ou supprimés
        if ($comparison.AddedImports.Count -gt 0) {
            $reasons += "Imports ajoutés: $($comparison.AddedImports.Count)"
            $score += 5 * $comparison.AddedImports.Count

            # Vérifier si les imports sont significatifs (frameworks importants)
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
            $reasons += "Imports supprimés: $($comparison.RemovedImports.Count)"
            $score += 5 * $comparison.RemovedImports.Count
        }

        # Vérifier le ratio de changement
        if ($comparison.ChangeRatio -ge $Threshold) {
            $isSignificant = $true
            $reasons += "Ratio de changement élevé: $([Math]::Round($comparison.ChangeRatio * 100, 2))%"
            $score += [Math]::Min(50, [Math]::Round($comparison.ChangeRatio * 100))
        }

        # Vérifier le nombre minimum de lignes modifiées
        $totalChanges = $comparison.AddedLines + $comparison.RemovedLines
        if ($totalChanges -ge $MinChanges) {
            $isSignificant = $true
            $reasons += "Nombre de lignes modifiées: $totalChanges"
            $score += [Math]::Min(30, $totalChanges)
        }

        # Vérifier les mots-clés importants dans les modifications
        $keywords = @('security', 'performance', 'optimization', 'critical', 'fix', 'bug', 'error', 'exception', 'crash', 'memory', 'leak')
        $content = $FileVersions.HeadContent
        foreach ($keyword in $keywords) {
            if ($content -match $keyword) {
                $isSignificant = $true
                $reasons += "Mot-clé important détecté: $keyword"
                $score += 15
                break
            }
        }

        # Mettre à jour le résultat
        $result.IsSignificant = $isSignificant
        $result.Reason = $reasons -join ", "
        $result.Score = [Math]::Min(100, $score)

        return $result
    } catch {
        Write-Error "Erreur lors de l'analyse des changements du fichier $($FileVersions.FilePath) : $_"
        return $null
    }
}

# Point d'entrée principal
try {
    # Obtenir les informations sur la pull request
    $prInfo = Get-PullRequestInfo -RepoPath $RepositoryPath -PRNumber $PullRequestNumber
    if ($null -eq $prInfo) {
        Write-Error "Impossible d'obtenir les informations sur la pull request."
        exit 1
    }

    # Afficher les informations sur la pull request
    Write-Host "Informations sur la pull request:" -ForegroundColor Cyan
    Write-Host "  Numéro: #$($prInfo.Number)" -ForegroundColor White
    Write-Host "  Titre: $($prInfo.Title)" -ForegroundColor White
    Write-Host "  Branche source: $($prInfo.HeadBranch)" -ForegroundColor White
    Write-Host "  Branche cible: $($prInfo.BaseBranch)" -ForegroundColor White
    Write-Host "  Fichiers modifiés: $($prInfo.FileCount)" -ForegroundColor White
    Write-Host "  Ajouts: $($prInfo.Additions)" -ForegroundColor White
    Write-Host "  Suppressions: $($prInfo.Deletions)" -ForegroundColor White
    Write-Host "  Modifications totales: $($prInfo.Changes)" -ForegroundColor White

    # Créer l'indexeur de contenu
    $indexer = New-FileContentIndexer -IndexPath (Join-Path -Path $env:TEMP -ChildPath "PRFileIndexes") -PersistIndices $true
    if ($null -eq $indexer) {
        Write-Error "Impossible de créer l'indexeur de contenu."
        exit 1
    }

    # Analyser chaque fichier
    $results = [System.Collections.Generic.List[object]]::new()
    $significantFiles = 0
    $totalFiles = $prInfo.Files.Count

    Write-Host "`nAnalyse des changements significatifs..." -ForegroundColor Cyan
    Write-Host "  Seuil de ratio de changement: $([Math]::Round($ThresholdRatio * 100, 2))%" -ForegroundColor White
    Write-Host "  Nombre minimum de lignes modifiées: $MinimumChanges" -ForegroundColor White
    Write-Host "  Niveau de détail: $DetailLevel" -ForegroundColor White

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

        # Ajouter le résultat à la liste
        $results.Add($fileResult)

        # Mettre à jour le compteur de fichiers significatifs
        if ($fileResult.IsSignificant) {
            $significantFiles++
        }
    }

    Write-Progress -Activity "Analyse des changements significatifs" -Completed

    # Créer le répertoire de sortie s'il n'existe pas
    $outputDir = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path -Path $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }

    # Créer l'objet de résultat final
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

    # Filtrer les détails en fonction du niveau de détail
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

    # Trier les résultats par score
    $finalResult.Results = $finalResult.Results | Sort-Object -Property Score -Descending

    # Enregistrer le résultat
    $finalResult | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8

    # Afficher un résumé
    Write-Host "`nRésumé de l'analyse:" -ForegroundColor Cyan
    Write-Host "  Fichiers analysés: $totalFiles" -ForegroundColor White
    Write-Host "  Fichiers avec changements significatifs: $significantFiles ($($finalResult.SignificantRatio)%)" -ForegroundColor White
    Write-Host "  Résultat enregistré: $OutputPath" -ForegroundColor White

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

    # Retourner le résultat
    return $finalResult
} catch {
    Write-Error "Erreur lors de l'analyse des changements significatifs: $_"
    exit 1
}
