#Requires -Version 5.1
<#
.SYNOPSIS
    Connecte les rapports d'analyse aux plateformes Git (GitHub/GitLab).

.DESCRIPTION
    Ce script permet de publier les rÃ©sultats d'analyse de pull requests
    directement sur GitHub ou GitLab, en ajoutant des commentaires et
    des vÃ©rifications de statut.

.PARAMETER InputPath
    Le chemin du fichier JSON contenant les rÃ©sultats d'analyse.

.PARAMETER Platform
    La plateforme Git Ã  utiliser.
    Valeurs possibles: "GitHub", "GitLab"
    Par dÃ©faut: "GitHub"

.PARAMETER RepositoryPath
    Le chemin du dÃ©pÃ´t local.
    Par dÃ©faut: le rÃ©pertoire de travail actuel

.PARAMETER PullRequestNumber
    Le numÃ©ro de la pull request Ã  mettre Ã  jour.
    Si non spÃ©cifiÃ©, il sera extrait des donnÃ©es d'analyse.

.PARAMETER CommentStyle
    Le style de commentaire Ã  utiliser.
    Valeurs possibles: "Summary", "Detailed", "Inline"
    Par dÃ©faut: "Summary"

.PARAMETER AddStatusCheck
    Indique s'il faut ajouter une vÃ©rification de statut Ã  la pull request.
    Par dÃ©faut: $true

.PARAMETER FailOnError
    Indique si la vÃ©rification de statut doit Ã©chouer en cas d'erreurs.
    Par dÃ©faut: $true

.PARAMETER FailOnWarning
    Indique si la vÃ©rification de statut doit Ã©chouer en cas d'avertissements.
    Par dÃ©faut: $false

.PARAMETER ReportUrl
    L'URL du rapport complet, si disponible.
    Par dÃ©faut: ""

.EXAMPLE
    .\Connect-ReportToGitPlatform.ps1 -InputPath "reports\pr-analysis\analysis_42.json" -CommentStyle "Inline"
    Publie les rÃ©sultats d'analyse sur GitHub avec des commentaires en ligne.

.EXAMPLE
    .\Connect-ReportToGitPlatform.ps1 -InputPath "reports\pr-analysis\analysis_42.json" -Platform "GitLab" -FailOnWarning $true
    Publie les rÃ©sultats d'analyse sur GitLab avec une vÃ©rification de statut qui Ã©choue en cas d'avertissements.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
    
    PrÃ©requis: 
    - GitHub CLI (gh) ou GitLab CLI (glab) doit Ãªtre installÃ© et configurÃ©
    - L'utilisateur doit Ãªtre authentifiÃ© avec les droits nÃ©cessaires
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputPath,

    [Parameter()]
    [ValidateSet("GitHub", "GitLab")]
    [string]$Platform = "GitHub",

    [Parameter()]
    [string]$RepositoryPath = ".",

    [Parameter()]
    [int]$PullRequestNumber = 0,

    [Parameter()]
    [ValidateSet("Summary", "Detailed", "Inline")]
    [string]$CommentStyle = "Summary",

    [Parameter()]
    [bool]$AddStatusCheck = $true,

    [Parameter()]
    [bool]$FailOnError = $true,

    [Parameter()]
    [bool]$FailOnWarning = $false,

    [Parameter()]
    [string]$ReportUrl = ""
)

# VÃ©rifier que le fichier d'entrÃ©e existe
if (-not (Test-Path -Path $InputPath)) {
    Write-Error "Le fichier d'entrÃ©e n'existe pas: $InputPath"
    exit 1
}

# Charger les donnÃ©es d'analyse
try {
    $analysisData = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement des donnÃ©es d'analyse: $_"
    exit 1
}

# Extraire le numÃ©ro de pull request si non spÃ©cifiÃ©
if ($PullRequestNumber -eq 0) {
    $PullRequestNumber = $analysisData.PullRequest.Number
}

if ($PullRequestNumber -eq 0) {
    Write-Error "NumÃ©ro de pull request non spÃ©cifiÃ© et non trouvÃ© dans les donnÃ©es d'analyse."
    exit 1
}

# Extraire les informations de base
$totalIssues = $analysisData.TotalIssues

# Extraire tous les problÃ¨mes
$issues = @()
foreach ($result in $analysisData.Results | Where-Object { $_.Success -and $_.Issues.Count -gt 0 }) {
    foreach ($issue in $result.Issues) {
        $issues += [PSCustomObject]@{
            FilePath = $result.FilePath
            Type = $issue.Type
            Line = $issue.Line
            Column = $issue.Column
            Message = $issue.Message
            Severity = $issue.Severity
            Rule = $issue.Rule
        }
    }
}

# Compter les problÃ¨mes par sÃ©vÃ©ritÃ©
$errorCount = ($issues | Where-Object { $_.Severity -eq "Error" }).Count
$warningCount = ($issues | Where-Object { $_.Severity -eq "Warning" }).Count
$infoCount = ($issues | Where-Object { $_.Severity -eq "Information" }).Count

# DÃ©terminer le statut global
$status = "success"
if ($errorCount -gt 0 -and $FailOnError) {
    $status = "failure"
} elseif ($warningCount -gt 0 -and $FailOnWarning) {
    $status = "failure"
}

# Changer de rÃ©pertoire vers le dÃ©pÃ´t
Push-Location -Path $RepositoryPath

try {
    # VÃ©rifier que la plateforme CLI est installÃ©e
    $cliCommand = switch ($Platform) {
        "GitHub" { "gh" }
        "GitLab" { "glab" }
    }
    
    if (-not (Get-Command $cliCommand -ErrorAction SilentlyContinue)) {
        Write-Error "La commande $cliCommand n'est pas disponible. Veuillez installer et configurer $Platform CLI."
        exit 1
    }
    
    # GÃ©nÃ©rer le commentaire en fonction du style choisi
    $comment = switch ($CommentStyle) {
        "Summary" {
            $summaryComment = @"
## Rapport d'analyse de code

### RÃ©sumÃ©
- **Erreurs**: $errorCount
- **Avertissements**: $warningCount
- **Informations**: $infoCount
- **Total**: $totalIssues

"@
            
            if ($status -eq "failure") {
                $summaryComment += "âš ï¸ **Des problÃ¨mes ont Ã©tÃ© dÃ©tectÃ©s qui nÃ©cessitent votre attention.**`n`n"
            } else {
                $summaryComment += "âœ… **Aucun problÃ¨me critique dÃ©tectÃ©.**`n`n"
            }
            
            if (-not [string]::IsNullOrWhiteSpace($ReportUrl)) {
                $summaryComment += "ðŸ“Š [Voir le rapport complet]($ReportUrl)`n`n"
            }
            
            $summaryComment
        }
        "Detailed" {
            $detailedComment = @"
## Rapport d'analyse de code

### RÃ©sumÃ©
- **Erreurs**: $errorCount
- **Avertissements**: $warningCount
- **Informations**: $infoCount
- **Total**: $totalIssues

"@
            
            if ($status -eq "failure") {
                $detailedComment += "âš ï¸ **Des problÃ¨mes ont Ã©tÃ© dÃ©tectÃ©s qui nÃ©cessitent votre attention.**`n`n"
            } else {
                $detailedComment += "âœ… **Aucun problÃ¨me critique dÃ©tectÃ©.**`n`n"
            }
            
            if (-not [string]::IsNullOrWhiteSpace($ReportUrl)) {
                $detailedComment += "ðŸ“Š [Voir le rapport complet]($ReportUrl)`n`n"
            }
            
            # Ajouter les problÃ¨mes critiques
            if ($errorCount -gt 0) {
                $detailedComment += "### Erreurs critiques`n`n"
                $detailedComment += "| Fichier | Ligne | Message | RÃ¨gle |`n"
                $detailedComment += "|---------|-------|---------|-------|`n"
                
                foreach ($issue in ($issues | Where-Object { $_.Severity -eq "Error" } | Select-Object -First 10)) {
                    $detailedComment += "| $($issue.FilePath) | $($issue.Line) | $($issue.Message) | $($issue.Rule) |`n"
                }
                
                if ($errorCount -gt 10) {
                    $detailedComment += "| ... | ... | ... | ... |`n"
                }
                
                $detailedComment += "`n"
            }
            
            # Ajouter les avertissements
            if ($warningCount -gt 0) {
                $detailedComment += "### Avertissements`n`n"
                $detailedComment += "| Fichier | Ligne | Message | RÃ¨gle |`n"
                $detailedComment += "|---------|-------|---------|-------|`n"
                
                foreach ($issue in ($issues | Where-Object { $_.Severity -eq "Warning" } | Select-Object -First 10)) {
                    $detailedComment += "| $($issue.FilePath) | $($issue.Line) | $($issue.Message) | $($issue.Rule) |`n"
                }
                
                if ($warningCount -gt 10) {
                    $detailedComment += "| ... | ... | ... | ... |`n"
                }
                
                $detailedComment += "`n"
            }
            
            $detailedComment
        }
        "Inline" {
            # Pour les commentaires en ligne, nous utiliserons un commentaire de rÃ©sumÃ©
            # et ajouterons des commentaires individuels pour chaque problÃ¨me
            @"
## Rapport d'analyse de code

### RÃ©sumÃ©
- **Erreurs**: $errorCount
- **Avertissements**: $warningCount
- **Informations**: $infoCount
- **Total**: $totalIssues

$(if ($status -eq "failure") { "âš ï¸ **Des problÃ¨mes ont Ã©tÃ© dÃ©tectÃ©s qui nÃ©cessitent votre attention.**" } else { "âœ… **Aucun problÃ¨me critique dÃ©tectÃ©.**" })

$(if (-not [string]::IsNullOrWhiteSpace($ReportUrl)) { "ðŸ“Š [Voir le rapport complet]($ReportUrl)" })

*Note: Des commentaires individuels ont Ã©tÃ© ajoutÃ©s pour chaque problÃ¨me.*
"@
        }
    }
    
    # Publier le commentaire sur la plateforme
    switch ($Platform) {
        "GitHub" {
            # Ajouter un commentaire Ã  la PR
            $comment | gh pr comment $PullRequestNumber --body-file -
            
            # Ajouter des commentaires en ligne si demandÃ©
            if ($CommentStyle -eq "Inline") {
                $reviewComments = @()
                
                foreach ($issue in $issues) {
                    if ($issue.Severity -in @("Error", "Warning")) {
                        $reviewComments += [PSCustomObject]@{
                            path = $issue.FilePath
                            line = $issue.Line
                            body = "**$($issue.Severity)**: $($issue.Message) ($($issue.Rule))"
                        }
                    }
                }
                
                if ($reviewComments.Count -gt 0) {
                    $reviewCommentsJson = $reviewComments | ConvertTo-Json -Compress
                    $reviewCommentsJson | gh pr review $PullRequestNumber --comment --body "Analyse de code automatique" --comments-json -
                }
            }
            
            # Ajouter une vÃ©rification de statut si demandÃ©
            if ($AddStatusCheck) {
                $statusTitle = "Analyse de code"
                $statusSummary = switch ($status) {
                    "success" { "Aucun problÃ¨me critique dÃ©tectÃ©." }
                    "failure" { "Des problÃ¨mes ont Ã©tÃ© dÃ©tectÃ©s qui nÃ©cessitent votre attention." }
                    default { "Analyse de code terminÃ©e." }
                }
                
                # Obtenir le SHA du dernier commit de la PR
                $prDetails = gh pr view $PullRequestNumber --json headRefOid | ConvertFrom-Json
                $commitSha = $prDetails.headRefOid
                
                # CrÃ©er une vÃ©rification de statut
                gh api repos/:owner/:repo/statuses/$commitSha -f state=$status -f context="$statusTitle" -f description="$statusSummary" -f target_url="$ReportUrl"
            }
        }
        "GitLab" {
            # Ajouter un commentaire Ã  la PR (appelÃ©e MR dans GitLab)
            $comment | glab mr note $PullRequestNumber --message-file -
            
            # Ajouter des commentaires en ligne si demandÃ©
            if ($CommentStyle -eq "Inline") {
                foreach ($issue in $issues) {
                    if ($issue.Severity -in @("Error", "Warning")) {
                        $inlineComment = "**$($issue.Severity)**: $($issue.Message) ($($issue.Rule))"
                        glab mr note $PullRequestNumber --message "$inlineComment" --file "$($issue.FilePath)" --line "$($issue.Line)"
                    }
                }
            }
            
            # Ajouter une vÃ©rification de statut si demandÃ©
            if ($AddStatusCheck) {
                $statusName = "analyse-de-code"
                $statusDescription = switch ($status) {
                    "success" { "Aucun problÃ¨me critique dÃ©tectÃ©." }
                    "failure" { "Des problÃ¨mes ont Ã©tÃ© dÃ©tectÃ©s qui nÃ©cessitent votre attention." }
                    default { "Analyse de code terminÃ©e." }
                }
                
                # Obtenir le SHA du dernier commit de la MR
                $mrDetails = glab mr view $PullRequestNumber --json sha | ConvertFrom-Json
                $commitSha = $mrDetails.sha
                
                # CrÃ©er une vÃ©rification de statut
                glab api projects/:id/statuses/$commitSha -f state=$status -f name="$statusName" -f description="$statusDescription" -f target_url="$ReportUrl"
            }
        }
    }
    
    Write-Host "Rapport connectÃ© avec succÃ¨s Ã  $Platform" -ForegroundColor Green
    Write-Host "  Pull Request: #$PullRequestNumber" -ForegroundColor White
    Write-Host "  Style de commentaire: $CommentStyle" -ForegroundColor White
    Write-Host "  VÃ©rification de statut: $AddStatusCheck" -ForegroundColor White
    Write-Host "  Statut: $status" -ForegroundColor White
    
    return $true
} catch {
    Write-Error "Erreur lors de la connexion du rapport Ã  $Platform : $($_.ToString())"
    return $false
} finally {
    # Revenir au rÃ©pertoire prÃ©cÃ©dent
    Pop-Location
}
