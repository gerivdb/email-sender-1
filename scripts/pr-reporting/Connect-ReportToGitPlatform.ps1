#Requires -Version 5.1
<#
.SYNOPSIS
    Connecte les rapports d'analyse aux plateformes Git (GitHub/GitLab).

.DESCRIPTION
    Ce script permet de publier les résultats d'analyse de pull requests
    directement sur GitHub ou GitLab, en ajoutant des commentaires et
    des vérifications de statut.

.PARAMETER InputPath
    Le chemin du fichier JSON contenant les résultats d'analyse.

.PARAMETER Platform
    La plateforme Git à utiliser.
    Valeurs possibles: "GitHub", "GitLab"
    Par défaut: "GitHub"

.PARAMETER RepositoryPath
    Le chemin du dépôt local.
    Par défaut: le répertoire de travail actuel

.PARAMETER PullRequestNumber
    Le numéro de la pull request à mettre à jour.
    Si non spécifié, il sera extrait des données d'analyse.

.PARAMETER CommentStyle
    Le style de commentaire à utiliser.
    Valeurs possibles: "Summary", "Detailed", "Inline"
    Par défaut: "Summary"

.PARAMETER AddStatusCheck
    Indique s'il faut ajouter une vérification de statut à la pull request.
    Par défaut: $true

.PARAMETER FailOnError
    Indique si la vérification de statut doit échouer en cas d'erreurs.
    Par défaut: $true

.PARAMETER FailOnWarning
    Indique si la vérification de statut doit échouer en cas d'avertissements.
    Par défaut: $false

.PARAMETER ReportUrl
    L'URL du rapport complet, si disponible.
    Par défaut: ""

.EXAMPLE
    .\Connect-ReportToGitPlatform.ps1 -InputPath "reports\pr-analysis\analysis_42.json" -CommentStyle "Inline"
    Publie les résultats d'analyse sur GitHub avec des commentaires en ligne.

.EXAMPLE
    .\Connect-ReportToGitPlatform.ps1 -InputPath "reports\pr-analysis\analysis_42.json" -Platform "GitLab" -FailOnWarning $true
    Publie les résultats d'analyse sur GitLab avec une vérification de statut qui échoue en cas d'avertissements.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-29
    
    Prérequis: 
    - GitHub CLI (gh) ou GitLab CLI (glab) doit être installé et configuré
    - L'utilisateur doit être authentifié avec les droits nécessaires
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

# Vérifier que le fichier d'entrée existe
if (-not (Test-Path -Path $InputPath)) {
    Write-Error "Le fichier d'entrée n'existe pas: $InputPath"
    exit 1
}

# Charger les données d'analyse
try {
    $analysisData = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
} catch {
    Write-Error "Erreur lors du chargement des données d'analyse: $_"
    exit 1
}

# Extraire le numéro de pull request si non spécifié
if ($PullRequestNumber -eq 0) {
    $PullRequestNumber = $analysisData.PullRequest.Number
}

if ($PullRequestNumber -eq 0) {
    Write-Error "Numéro de pull request non spécifié et non trouvé dans les données d'analyse."
    exit 1
}

# Extraire les informations de base
$totalIssues = $analysisData.TotalIssues

# Extraire tous les problèmes
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

# Compter les problèmes par sévérité
$errorCount = ($issues | Where-Object { $_.Severity -eq "Error" }).Count
$warningCount = ($issues | Where-Object { $_.Severity -eq "Warning" }).Count
$infoCount = ($issues | Where-Object { $_.Severity -eq "Information" }).Count

# Déterminer le statut global
$status = "success"
if ($errorCount -gt 0 -and $FailOnError) {
    $status = "failure"
} elseif ($warningCount -gt 0 -and $FailOnWarning) {
    $status = "failure"
}

# Changer de répertoire vers le dépôt
Push-Location -Path $RepositoryPath

try {
    # Vérifier que la plateforme CLI est installée
    $cliCommand = switch ($Platform) {
        "GitHub" { "gh" }
        "GitLab" { "glab" }
    }
    
    if (-not (Get-Command $cliCommand -ErrorAction SilentlyContinue)) {
        Write-Error "La commande $cliCommand n'est pas disponible. Veuillez installer et configurer $Platform CLI."
        exit 1
    }
    
    # Générer le commentaire en fonction du style choisi
    $comment = switch ($CommentStyle) {
        "Summary" {
            $summaryComment = @"
## Rapport d'analyse de code

### Résumé
- **Erreurs**: $errorCount
- **Avertissements**: $warningCount
- **Informations**: $infoCount
- **Total**: $totalIssues

"@
            
            if ($status -eq "failure") {
                $summaryComment += "⚠️ **Des problèmes ont été détectés qui nécessitent votre attention.**`n`n"
            } else {
                $summaryComment += "✅ **Aucun problème critique détecté.**`n`n"
            }
            
            if (-not [string]::IsNullOrWhiteSpace($ReportUrl)) {
                $summaryComment += "📊 [Voir le rapport complet]($ReportUrl)`n`n"
            }
            
            $summaryComment
        }
        "Detailed" {
            $detailedComment = @"
## Rapport d'analyse de code

### Résumé
- **Erreurs**: $errorCount
- **Avertissements**: $warningCount
- **Informations**: $infoCount
- **Total**: $totalIssues

"@
            
            if ($status -eq "failure") {
                $detailedComment += "⚠️ **Des problèmes ont été détectés qui nécessitent votre attention.**`n`n"
            } else {
                $detailedComment += "✅ **Aucun problème critique détecté.**`n`n"
            }
            
            if (-not [string]::IsNullOrWhiteSpace($ReportUrl)) {
                $detailedComment += "📊 [Voir le rapport complet]($ReportUrl)`n`n"
            }
            
            # Ajouter les problèmes critiques
            if ($errorCount -gt 0) {
                $detailedComment += "### Erreurs critiques`n`n"
                $detailedComment += "| Fichier | Ligne | Message | Règle |`n"
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
                $detailedComment += "| Fichier | Ligne | Message | Règle |`n"
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
            # Pour les commentaires en ligne, nous utiliserons un commentaire de résumé
            # et ajouterons des commentaires individuels pour chaque problème
            @"
## Rapport d'analyse de code

### Résumé
- **Erreurs**: $errorCount
- **Avertissements**: $warningCount
- **Informations**: $infoCount
- **Total**: $totalIssues

$(if ($status -eq "failure") { "⚠️ **Des problèmes ont été détectés qui nécessitent votre attention.**" } else { "✅ **Aucun problème critique détecté.**" })

$(if (-not [string]::IsNullOrWhiteSpace($ReportUrl)) { "📊 [Voir le rapport complet]($ReportUrl)" })

*Note: Des commentaires individuels ont été ajoutés pour chaque problème.*
"@
        }
    }
    
    # Publier le commentaire sur la plateforme
    switch ($Platform) {
        "GitHub" {
            # Ajouter un commentaire à la PR
            $comment | gh pr comment $PullRequestNumber --body-file -
            
            # Ajouter des commentaires en ligne si demandé
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
            
            # Ajouter une vérification de statut si demandé
            if ($AddStatusCheck) {
                $statusTitle = "Analyse de code"
                $statusSummary = switch ($status) {
                    "success" { "Aucun problème critique détecté." }
                    "failure" { "Des problèmes ont été détectés qui nécessitent votre attention." }
                    default { "Analyse de code terminée." }
                }
                
                # Obtenir le SHA du dernier commit de la PR
                $prDetails = gh pr view $PullRequestNumber --json headRefOid | ConvertFrom-Json
                $commitSha = $prDetails.headRefOid
                
                # Créer une vérification de statut
                gh api repos/:owner/:repo/statuses/$commitSha -f state=$status -f context="$statusTitle" -f description="$statusSummary" -f target_url="$ReportUrl"
            }
        }
        "GitLab" {
            # Ajouter un commentaire à la PR (appelée MR dans GitLab)
            $comment | glab mr note $PullRequestNumber --message-file -
            
            # Ajouter des commentaires en ligne si demandé
            if ($CommentStyle -eq "Inline") {
                foreach ($issue in $issues) {
                    if ($issue.Severity -in @("Error", "Warning")) {
                        $inlineComment = "**$($issue.Severity)**: $($issue.Message) ($($issue.Rule))"
                        glab mr note $PullRequestNumber --message "$inlineComment" --file "$($issue.FilePath)" --line "$($issue.Line)"
                    }
                }
            }
            
            # Ajouter une vérification de statut si demandé
            if ($AddStatusCheck) {
                $statusName = "analyse-de-code"
                $statusDescription = switch ($status) {
                    "success" { "Aucun problème critique détecté." }
                    "failure" { "Des problèmes ont été détectés qui nécessitent votre attention." }
                    default { "Analyse de code terminée." }
                }
                
                # Obtenir le SHA du dernier commit de la MR
                $mrDetails = glab mr view $PullRequestNumber --json sha | ConvertFrom-Json
                $commitSha = $mrDetails.sha
                
                # Créer une vérification de statut
                glab api projects/:id/statuses/$commitSha -f state=$status -f name="$statusName" -f description="$statusDescription" -f target_url="$ReportUrl"
            }
        }
    }
    
    Write-Host "Rapport connecté avec succès à $Platform" -ForegroundColor Green
    Write-Host "  Pull Request: #$PullRequestNumber" -ForegroundColor White
    Write-Host "  Style de commentaire: $CommentStyle" -ForegroundColor White
    Write-Host "  Vérification de statut: $AddStatusCheck" -ForegroundColor White
    Write-Host "  Statut: $status" -ForegroundColor White
    
    return $true
} catch {
    Write-Error "Erreur lors de la connexion du rapport à $Platform : $($_.ToString())"
    return $false
} finally {
    # Revenir au répertoire précédent
    Pop-Location
}
