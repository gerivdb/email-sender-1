<#
.SYNOPSIS
    Script de génération d'un rapport global de validation des bénéfices de Hygen.

.DESCRIPTION
    Ce script génère un rapport global de validation des bénéfices de Hygen
    en combinant les résultats des mesures de bénéfices et des retours utilisateurs.

.PARAMETER BenefitsReportPath
    Chemin du rapport de bénéfices. Par défaut, "n8n\docs\hygen-benefits-report.md".

.PARAMETER FeedbackReportPath
    Chemin du rapport de satisfaction. Par défaut, "n8n\docs\hygen-user-feedback-report.md".

.PARAMETER OutputPath
    Chemin du rapport global de validation. Par défaut, "n8n\docs\hygen-validation-report.md".

.EXAMPLE
    .\generate-validation-report.ps1
    Génère un rapport global de validation avec les chemins par défaut.

.EXAMPLE
    .\generate-validation-report.ps1 -BenefitsReportPath "benefits.md" -FeedbackReportPath "feedback.md" -OutputPath "validation.md"
    Génère un rapport global de validation avec des chemins personnalisés.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-12
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$BenefitsReportPath = "",
    
    [Parameter(Mandatory=$false)]
    [string]$FeedbackReportPath = "",
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ""
)

# Définir les couleurs pour les messages
$successColor = "Green"
$errorColor = "Red"
$infoColor = "Cyan"
$warningColor = "Yellow"

# Fonction pour afficher un message de succès
function Write-Success {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✓ $Message" -ForegroundColor $successColor
}

# Fonction pour afficher un message d'erreur
function Write-Error {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "✗ $Message" -ForegroundColor $errorColor
}

# Fonction pour afficher un message d'information
function Write-Info {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "ℹ $Message" -ForegroundColor $infoColor
}

# Fonction pour afficher un message d'avertissement
function Write-Warning {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    Write-Host "⚠ $Message" -ForegroundColor $warningColor
}

# Fonction pour obtenir le chemin du projet
function Get-ProjectPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $projectRoot = (Get-Item $scriptPath).Parent.Parent.Parent.FullName
    return $projectRoot
}

# Fonction pour extraire les informations du rapport de bénéfices
function Extract-BenefitsInfo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ReportPath
    )
    
    if (-not (Test-Path -Path $ReportPath)) {
        Write-Error "Le rapport de bénéfices n'existe pas: $ReportPath"
        return $null
    }
    
    try {
        $content = Get-Content -Path $ReportPath -Raw
        
        # Extraire le gain de temps moyen
        $timeGainMatch = [regex]::Match($content, "Gain de temps moyen\*\*:\s*([0-9.]+)%")
        $timeGain = if ($timeGainMatch.Success) { [double]$timeGainMatch.Groups[1].Value } else { 0 }
        
        # Extraire le taux de standardisation moyen
        $standardizationMatch = [regex]::Match($content, "Taux de standardisation moyen\*\*:\s*([0-9.]+)%")
        $standardization = if ($standardizationMatch.Success) { [double]$standardizationMatch.Groups[1].Value } else { 0 }
        
        # Extraire le taux d'organisation moyen
        $organizationMatch = [regex]::Match($content, "Taux d'organisation moyen\*\*:\s*([0-9.]+)%")
        $organization = if ($organizationMatch.Success) { [double]$organizationMatch.Groups[1].Value } else { 0 }
        
        # Extraire les points positifs
        $positivesSection = [regex]::Match($content, "## Analyse des bénéfices\s+### Gain de temps\s+(.*?)###", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $positives = if ($positivesSection.Success) { $positivesSection.Groups[1].Value.Trim() } else { "" }
        
        # Extraire les recommandations
        $recommendationsSection = [regex]::Match($content, "## Recommandations\s+(.*?)##", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $recommendations = if ($recommendationsSection.Success) { $recommendationsSection.Groups[1].Value.Trim() } else { "" }
        
        # Extraire la conclusion
        $conclusionSection = [regex]::Match($content, "## Conclusion\s+(.*?)$", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $conclusion = if ($conclusionSection.Success) { $conclusionSection.Groups[1].Value.Trim() } else { "" }
        
        return @{
            TimeGain = $timeGain
            Standardization = $standardization
            Organization = $organization
            Positives = $positives
            Recommendations = $recommendations
            Conclusion = $conclusion
        }
    }
    catch {
        Write-Error "Erreur lors de l'extraction des informations du rapport de bénéfices: $_"
        return $null
    }
}

# Fonction pour extraire les informations du rapport de satisfaction
function Extract-FeedbackInfo {
    param (
        [Parameter(Mandatory=$true)]
        [string]$ReportPath
    )
    
    if (-not (Test-Path -Path $ReportPath)) {
        Write-Error "Le rapport de satisfaction n'existe pas: $ReportPath"
        return $null
    }
    
    try {
        $content = Get-Content -Path $ReportPath -Raw
        
        # Extraire le nombre d'utilisateurs
        $usersMatch = [regex]::Match($content, "Nombre d'utilisateurs interrogés\*\*:\s*([0-9]+)")
        $users = if ($usersMatch.Success) { [int]$usersMatch.Groups[1].Value } else { 0 }
        
        # Extraire la note globale moyenne
        $overallRatingMatch = [regex]::Match($content, "Note globale moyenne\*\*:\s*([0-9.]+)")
        $overallRating = if ($overallRatingMatch.Success) { [double]$overallRatingMatch.Groups[1].Value } else { 0 }
        
        # Extraire la satisfaction générale
        $satisfactionMatch = [regex]::Match($content, "Satisfaction générale\*\*:\s*([A-Za-zÀ-ÖØ-öø-ÿ]+)")
        $satisfaction = if ($satisfactionMatch.Success) { $satisfactionMatch.Groups[1].Value } else { "" }
        
        # Extraire les points positifs
        $positivesSection = [regex]::Match($content, "## Points positifs\s+(.*?)##", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $positives = if ($positivesSection.Success) {
            $positivesSection.Groups[1].Value.Trim() -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "^- " } | ForEach-Object { $_.Substring(2) }
        } else {
            @()
        }
        
        # Extraire les points négatifs
        $negativesSection = [regex]::Match($content, "## Points négatifs\s+(.*?)##", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $negatives = if ($negativesSection.Success) {
            $negativesSection.Groups[1].Value.Trim() -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "^- " } | ForEach-Object { $_.Substring(2) }
        } else {
            @()
        }
        
        # Extraire les suggestions
        $suggestionsSection = [regex]::Match($content, "## Suggestions d'amélioration\s+(.*?)##", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $suggestions = if ($suggestionsSection.Success) {
            $suggestionsSection.Groups[1].Value.Trim() -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -match "^- " } | ForEach-Object { $_.Substring(2) }
        } else {
            @()
        }
        
        # Extraire les recommandations
        $recommendationsSection = [regex]::Match($content, "## Recommandations\s+(.*?)##", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $recommendations = if ($recommendationsSection.Success) { $recommendationsSection.Groups[1].Value.Trim() } else { "" }
        
        # Extraire la conclusion
        $conclusionSection = [regex]::Match($content, "## Conclusion\s+(.*?)$", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        $conclusion = if ($conclusionSection.Success) { $conclusionSection.Groups[1].Value.Trim() } else { "" }
        
        return @{
            Users = $users
            OverallRating = $overallRating
            Satisfaction = $satisfaction
            Positives = $positives
            Negatives = $negatives
            Suggestions = $suggestions
            Recommendations = $recommendations
            Conclusion = $conclusion
        }
    }
    catch {
        Write-Error "Erreur lors de l'extraction des informations du rapport de satisfaction: $_"
        return $null
    }
}

# Fonction pour générer un rapport global de validation
function Generate-ValidationReport {
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$BenefitsInfo,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$FeedbackInfo,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    if ($PSCmdlet.ShouldProcess($OutputPath, "Générer le rapport")) {
        # Calculer le score global de validation
        $timeGainScore = $BenefitsInfo["TimeGain"] / 20 # Ramener à une note sur 5
        $standardizationScore = $BenefitsInfo["Standardization"] / 20 # Ramener à une note sur 5
        $organizationScore = $BenefitsInfo["Organization"] / 20 # Ramener à une note sur 5
        $userSatisfactionScore = $FeedbackInfo["OverallRating"]
        
        $overallScore = ($timeGainScore + $standardizationScore + $organizationScore + $userSatisfactionScore) / 4
        
        # Déterminer le statut global
        $overallStatus = if ($overallScore -ge 4.5) {
            "Excellent"
        } elseif ($overallScore -ge 4.0) {
            "Très bon"
        } elseif ($overallScore -ge 3.5) {
            "Bon"
        } elseif ($overallScore -ge 3.0) {
            "Moyen"
        } else {
            "Faible"
        }
        
        # Générer le rapport
        $report = @"
# Rapport global de validation des bénéfices de Hygen

## Date
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résumé

- **Score global de validation**: $($overallScore.ToString("0.0")) / 5
- **Statut global**: $overallStatus
- **Gain de temps**: $($BenefitsInfo["TimeGain"].ToString("0.00"))%
- **Standardisation du code**: $($BenefitsInfo["Standardization"].ToString("0.00"))%
- **Organisation des fichiers**: $($BenefitsInfo["Organization"].ToString("0.00"))%
- **Satisfaction des utilisateurs**: $($FeedbackInfo["OverallRating"].ToString("0.0")) / 5 ($($FeedbackInfo["Satisfaction"]))
- **Nombre d'utilisateurs interrogés**: $($FeedbackInfo["Users"])

## Bénéfices mesurés

### Gain de temps

$($BenefitsInfo["Positives"])

### Standardisation du code

L'utilisation de Hygen permet une standardisation du code de **$($BenefitsInfo["Standardization"].ToString("0.00"))%**. Cela signifie que la grande majorité des composants générés sont conformes aux standards définis, ce qui garantit une cohérence et une qualité optimales.

### Organisation des fichiers

L'utilisation de Hygen permet une organisation des fichiers de **$($BenefitsInfo["Organization"].ToString("0.00"))%**. Cela signifie que la plupart des composants sont placés au bon endroit dans la structure du projet, ce qui facilite la maintenance et la navigation.

## Retours des utilisateurs

### Points positifs

"@
        
        foreach ($positive in $FeedbackInfo["Positives"]) {
            $report += "`n- $positive"
        }
        
        $report += @"

### Points négatifs

"@
        
        if ($FeedbackInfo["Negatives"].Count -gt 0) {
            foreach ($negative in $FeedbackInfo["Negatives"]) {
                $report += "`n- $negative"
            }
        } else {
            $report += "`n- Aucun point négatif signalé"
        }
        
        $report += @"

### Suggestions d'amélioration

"@
        
        if ($FeedbackInfo["Suggestions"].Count -gt 0) {
            foreach ($suggestion in $FeedbackInfo["Suggestions"]) {
                $report += "`n- $suggestion"
            }
        } else {
            $report += "`n- Aucune suggestion d'amélioration"
        }
        
        $report += @"

## Analyse globale

"@
        
        if ($overallScore -ge 4.5) {
            $report += @"

L'utilisation de Hygen dans le projet apporte des bénéfices **excellents**. Les mesures objectives montrent un gain de temps très significatif, une standardisation du code très élevée et une organisation des fichiers très efficace. Les retours des utilisateurs sont également très positifs, avec une satisfaction globale excellente.

Les bénéfices de Hygen sont clairement démontrés et justifient pleinement son adoption dans le projet. L'outil permet d'accélérer considérablement le développement, d'améliorer la qualité du code et de faciliter la maintenance du projet.
"@
        } elseif ($overallScore -ge 4.0) {
            $report += @"

L'utilisation de Hygen dans le projet apporte des bénéfices **très bons**. Les mesures objectives montrent un gain de temps significatif, une standardisation du code élevée et une organisation des fichiers efficace. Les retours des utilisateurs sont également positifs, avec une satisfaction globale très bonne.

Les bénéfices de Hygen sont clairement démontrés et justifient son adoption dans le projet. L'outil permet d'accélérer le développement, d'améliorer la qualité du code et de faciliter la maintenance du projet.
"@
        } elseif ($overallScore -ge 3.5) {
            $report += @"

L'utilisation de Hygen dans le projet apporte des bénéfices **bons**. Les mesures objectives montrent un gain de temps notable, une standardisation du code correcte et une organisation des fichiers satisfaisante. Les retours des utilisateurs sont globalement positifs, avec une satisfaction globale bonne.

Les bénéfices de Hygen sont démontrés et justifient son adoption dans le projet, bien que certaines améliorations soient souhaitables pour maximiser son potentiel.
"@
        } elseif ($overallScore -ge 3.0) {
            $report += @"

L'utilisation de Hygen dans le projet apporte des bénéfices **moyens**. Les mesures objectives montrent un gain de temps modéré, une standardisation du code acceptable et une organisation des fichiers correcte. Les retours des utilisateurs sont mitigés, avec une satisfaction globale moyenne.

Les bénéfices de Hygen sont présents mais limités. Des améliorations significatives sont nécessaires pour justifier pleinement son adoption dans le projet.
"@
        } else {
            $report += @"

L'utilisation de Hygen dans le projet apporte des bénéfices **faibles**. Les mesures objectives montrent un gain de temps limité, une standardisation du code insuffisante et une organisation des fichiers problématique. Les retours des utilisateurs sont négatifs, avec une satisfaction globale faible.

Les bénéfices de Hygen sont très limités et ne justifient pas son adoption dans le projet sans des améliorations majeures.
"@
        }
        
        $report += @"

## Recommandations

"@
        
        if ($overallScore -ge 4.0) {
            $report += @"

1. **Continuer à utiliser et promouvoir Hygen** dans le projet
2. **Étendre l'utilisation de Hygen** à d'autres parties du projet
3. **Former tous les développeurs** à l'utilisation de Hygen
4. **Améliorer les templates** pour augmenter encore la standardisation et l'organisation
5. **Adresser les points négatifs** signalés par les utilisateurs
6. **Implémenter les suggestions** d'amélioration les plus pertinentes
7. **Surveiller régulièrement les bénéfices** pour s'assurer qu'ils restent significatifs
8. **Documenter les bonnes pratiques** d'utilisation de Hygen
9. **Partager les succès** avec d'autres équipes et projets
10. **Contribuer à l'amélioration** de Hygen en partageant des retours avec la communauté
"@
        } elseif ($overallScore -ge 3.0) {
            $report += @"

1. **Continuer à utiliser Hygen** dans le projet, mais avec des améliorations
2. **Améliorer les templates** pour augmenter la standardisation et l'organisation
3. **Adresser en priorité les points négatifs** signalés par les utilisateurs
4. **Implémenter les suggestions** d'amélioration les plus pertinentes
5. **Former les développeurs** à l'utilisation optimale de Hygen
6. **Limiter l'utilisation de Hygen** aux cas où il apporte une réelle valeur ajoutée
7. **Recueillir régulièrement des retours** pour mesurer les progrès
8. **Évaluer d'autres outils** en complément de Hygen
9. **Documenter les cas d'utilisation** où Hygen est le plus bénéfique
10. **Revoir la stratégie d'adoption** de Hygen dans 3 à 6 mois
"@
        } else {
            $report += @"

1. **Réévaluer l'utilisation de Hygen** dans le projet
2. **Limiter l'utilisation de Hygen** aux cas spécifiques où il apporte une réelle valeur ajoutée
3. **Adresser les problèmes majeurs** identifiés dans les mesures et les retours
4. **Explorer des alternatives** à Hygen qui pourraient mieux répondre aux besoins du projet
5. **Recueillir des retours détaillés** pour comprendre précisément les problèmes
6. **Améliorer significativement les templates** si la décision est prise de continuer avec Hygen
7. **Former les développeurs** à l'utilisation optimale de Hygen ou de l'alternative choisie
8. **Établir des critères clairs** pour décider quand utiliser Hygen
9. **Mesurer régulièrement les bénéfices** pour évaluer les progrès
10. **Prendre une décision définitive** sur l'utilisation de Hygen dans les 3 mois
"@
        }
        
        $report += @"

## Conclusion

"@
        
        if ($overallScore -ge 4.5) {
            $report += "`nHygen est un outil **extrêmement bénéfique** pour le projet. Les mesures objectives et les retours des utilisateurs confirment que son adoption apporte une valeur ajoutée très significative. L'utilisation de Hygen devrait être encouragée, étendue et optimisée pour maximiser ses bénéfices."
        } elseif ($overallScore -ge 4.0) {
            $report += "`nHygen est un outil **très bénéfique** pour le projet. Les mesures objectives et les retours des utilisateurs confirment que son adoption apporte une valeur ajoutée significative. L'utilisation de Hygen devrait être encouragée et optimisée pour maximiser ses bénéfices."
        } elseif ($overallScore -ge 3.5) {
            $report += "`nHygen est un outil **bénéfique** pour le projet. Les mesures objectives et les retours des utilisateurs confirment que son adoption apporte une valeur ajoutée, bien que des améliorations soient souhaitables. L'utilisation de Hygen devrait être maintenue et optimisée pour augmenter ses bénéfices."
        } elseif ($overallScore -ge 3.0) {
            $report += "`nHygen est un outil **modérément bénéfique** pour le projet. Les mesures objectives et les retours des utilisateurs montrent que son adoption apporte une valeur ajoutée limitée. L'utilisation de Hygen devrait être réévaluée et des améliorations significatives devraient être apportées pour justifier son maintien."
        } else {
            $report += "`nHygen est un outil **peu bénéfique** pour le projet. Les mesures objectives et les retours des utilisateurs montrent que son adoption n'apporte pas une valeur ajoutée suffisante. L'utilisation de Hygen devrait être sérieusement réévaluée et des alternatives devraient être explorées."
        }
        
        $report += @"

## Prochaines étapes

1. Présenter ce rapport à l'équipe de développement
2. Discuter des recommandations et établir un plan d'action
3. Mettre en œuvre les améliorations prioritaires
4. Surveiller régulièrement les bénéfices et la satisfaction des utilisateurs
5. Réévaluer l'utilisation de Hygen dans 6 mois
"@
        
        Set-Content -Path $OutputPath -Value $report
        Write-Success "Rapport global de validation généré: $OutputPath"
        
        return $OutputPath
    } else {
        return $null
    }
}

# Fonction principale
function Start-ValidationReportGeneration {
    Write-Info "Génération du rapport global de validation des bénéfices de Hygen..."
    
    # Déterminer les chemins
    $projectRoot = Get-ProjectPath
    $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
    $docsFolder = Join-Path -Path $n8nRoot -ChildPath "docs"
    
    if ([string]::IsNullOrEmpty($BenefitsReportPath)) {
        $BenefitsReportPath = Join-Path -Path $docsFolder -ChildPath "hygen-benefits-report.md"
    }
    
    if ([string]::IsNullOrEmpty($FeedbackReportPath)) {
        $FeedbackReportPath = Join-Path -Path $docsFolder -ChildPath "hygen-user-feedback-report.md"
    }
    
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = Join-Path -Path $docsFolder -ChildPath "hygen-validation-report.md"
    }
    
    # Vérifier si les rapports existent
    $benefitsReportExists = Test-Path -Path $BenefitsReportPath
    $feedbackReportExists = Test-Path -Path $FeedbackReportPath
    
    if (-not $benefitsReportExists) {
        Write-Warning "Le rapport de bénéfices n'existe pas: $BenefitsReportPath"
        Write-Info "Exécution du script de mesure des bénéfices..."
        
        $measureBenefitsScript = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "measure-hygen-benefits.ps1"
        
        if (Test-Path -Path $measureBenefitsScript) {
            & $measureBenefitsScript -OutputPath $BenefitsReportPath
            $benefitsReportExists = Test-Path -Path $BenefitsReportPath
        } else {
            Write-Error "Le script de mesure des bénéfices n'existe pas: $measureBenefitsScript"
        }
    }
    
    if (-not $feedbackReportExists) {
        Write-Warning "Le rapport de satisfaction n'existe pas: $FeedbackReportPath"
        Write-Info "Exécution du script de collecte des retours utilisateurs..."
        
        $collectFeedbackScript = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "collect-user-feedback.ps1"
        
        if (Test-Path -Path $collectFeedbackScript) {
            & $collectFeedbackScript -OutputPath $FeedbackReportPath
            $feedbackReportExists = Test-Path -Path $FeedbackReportPath
        } else {
            Write-Error "Le script de collecte des retours utilisateurs n'existe pas: $collectFeedbackScript"
        }
    }
    
    # Vérifier à nouveau si les rapports existent
    if (-not $benefitsReportExists) {
        Write-Error "Impossible de générer le rapport de bénéfices"
        return $false
    }
    
    if (-not $feedbackReportExists) {
        Write-Error "Impossible de générer le rapport de satisfaction"
        return $false
    }
    
    # Extraire les informations des rapports
    $benefitsInfo = Extract-BenefitsInfo -ReportPath $BenefitsReportPath
    $feedbackInfo = Extract-FeedbackInfo -ReportPath $FeedbackReportPath
    
    if (-not $benefitsInfo) {
        Write-Error "Impossible d'extraire les informations du rapport de bénéfices"
        return $false
    }
    
    if (-not $feedbackInfo) {
        Write-Error "Impossible d'extraire les informations du rapport de satisfaction"
        return $false
    }
    
    # Générer le rapport global de validation
    $reportPath = Generate-ValidationReport -BenefitsInfo $benefitsInfo -FeedbackInfo $feedbackInfo -OutputPath $OutputPath
    
    # Afficher le résultat
    if ($reportPath) {
        Write-Success "Rapport global de validation généré: $reportPath"
    } else {
        Write-Error "Impossible de générer le rapport global de validation"
    }
    
    return $reportPath
}

# Exécuter la génération du rapport
Start-ValidationReportGeneration
