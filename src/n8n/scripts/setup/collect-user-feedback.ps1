<#
.SYNOPSIS
    Script de collecte des retours des utilisateurs sur Hygen.

.DESCRIPTION
    Ce script collecte les retours des utilisateurs sur Hygen et génère un rapport de satisfaction.

.PARAMETER OutputPath
    Chemin du fichier de rapport de satisfaction. Par défaut, "n8n\docs\hygen-user-feedback-report.md".

.PARAMETER Interactive
    Si spécifié, le script sera exécuté en mode interactif, permettant à l'utilisateur de répondre aux questions.

.PARAMETER FeedbackFile
    Chemin du fichier de retours existant. Si spécifié, le script utilisera ce fichier au lieu de collecter de nouveaux retours.

.EXAMPLE
    .\collect-user-feedback.ps1 -Interactive
    Collecte les retours des utilisateurs en mode interactif.

.EXAMPLE
    .\collect-user-feedback.ps1 -FeedbackFile "feedback.json"
    Génère un rapport à partir d'un fichier de retours existant.

.NOTES
    Auteur: Équipe n8n
    Date de création: 2023-05-12
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$Interactive = $false,
    
    [Parameter(Mandatory=$false)]
    [string]$FeedbackFile = ""
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

# Fonction pour collecter les retours des utilisateurs
function Collect-UserFeedback {
    if (-not $Interactive -and [string]::IsNullOrEmpty($FeedbackFile)) {
        Write-Warning "Mode interactif désactivé et aucun fichier de retours spécifié. Utilisation de données de retours simulées."
        
        # Générer des données de retours simulées
        $feedback = @(
            @{
                UserName = "Développeur 1"
                Role = "Développeur"
                Experience = "Débutant"
                Ratings = @{
                    Installation = 4
                    Utilisation = 5
                    Documentation = 4
                    Templates = 5
                    Utilitaires = 4
                    Bénéfices = 5
                }
                Positives = @(
                    "Gain de temps significatif",
                    "Standardisation du code",
                    "Documentation claire"
                )
                Negatives = @(
                    "Installation un peu complexe"
                )
                Suggestions = @(
                    "Ajouter plus de templates"
                )
                Overall = 4.5
            },
            @{
                UserName = "Développeur 2"
                Role = "Développeur senior"
                Experience = "Expérimenté"
                Ratings = @{
                    Installation = 3
                    Utilisation = 4
                    Documentation = 5
                    Templates = 4
                    Utilitaires = 5
                    Bénéfices = 5
                }
                Positives = @(
                    "Organisation des fichiers",
                    "Facilité d'utilisation",
                    "Intégration avec MCP"
                )
                Negatives = @(
                    "Quelques bugs mineurs"
                )
                Suggestions = @(
                    "Améliorer la gestion des erreurs"
                )
                Overall = 4.2
            },
            @{
                UserName = "Développeur 3"
                Role = "Chef de projet"
                Experience = "Expert"
                Ratings = @{
                    Installation = 5
                    Utilisation = 4
                    Documentation = 5
                    Templates = 4
                    Utilitaires = 4
                    Bénéfices = 5
                }
                Positives = @(
                    "Accélération du développement",
                    "Cohérence du code",
                    "Facilité de maintenance"
                )
                Negatives = @(
                    "Personnalisation limitée"
                )
                Suggestions = @(
                    "Ajouter des options de personnalisation"
                )
                Overall = 4.7
            }
        )
        
        return $feedback
    } elseif (-not [string]::IsNullOrEmpty($FeedbackFile)) {
        # Charger les retours à partir du fichier
        if (Test-Path -Path $FeedbackFile) {
            try {
                $feedback = Get-Content -Path $FeedbackFile -Raw | ConvertFrom-Json
                Write-Success "Retours chargés à partir du fichier: $FeedbackFile"
                return $feedback
            }
            catch {
                Write-Error "Erreur lors du chargement des retours: $_"
                return $null
            }
        } else {
            Write-Error "Le fichier de retours n'existe pas: $FeedbackFile"
            return $null
        }
    } else {
        # Collecter les retours en mode interactif
        $feedback = @()
        
        Write-Info "Collecte des retours des utilisateurs sur Hygen..."
        
        $continueCollecting = $true
        
        while ($continueCollecting) {
            Write-Info "`nNouveau retour utilisateur"
            
            $userName = Read-Host "Nom de l'utilisateur"
            $role = Read-Host "Rôle (Développeur, Chef de projet, etc.)"
            $experience = Read-Host "Expérience (Débutant, Expérimenté, Expert)"
            
            Write-Info "`nVeuillez noter les aspects suivants de Hygen (1-5, 5 étant le meilleur):"
            $installationRating = [int](Read-Host "Installation")
            $usageRating = [int](Read-Host "Utilisation")
            $documentationRating = [int](Read-Host "Documentation")
            $templatesRating = [int](Read-Host "Templates")
            $utilitiesRating = [int](Read-Host "Utilitaires")
            $benefitsRating = [int](Read-Host "Bénéfices")
            
            $ratings = @{
                Installation = $installationRating
                Utilisation = $usageRating
                Documentation = $documentationRating
                Templates = $templatesRating
                Utilitaires = $utilitiesRating
                Bénéfices = $benefitsRating
            }
            
            $overallRating = ($installationRating + $usageRating + $documentationRating + $templatesRating + $utilitiesRating + $benefitsRating) / 6
            
            Write-Info "`nVeuillez indiquer les points positifs de Hygen (séparés par des virgules):"
            $positivesInput = Read-Host "Points positifs"
            $positives = $positivesInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrEmpty($_) }
            
            Write-Info "`nVeuillez indiquer les points négatifs de Hygen (séparés par des virgules):"
            $negativesInput = Read-Host "Points négatifs"
            $negatives = $negativesInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrEmpty($_) }
            
            Write-Info "`nVeuillez indiquer vos suggestions d'amélioration (séparées par des virgules):"
            $suggestionsInput = Read-Host "Suggestions"
            $suggestions = $suggestionsInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrEmpty($_) }
            
            $userFeedback = @{
                UserName = $userName
                Role = $role
                Experience = $experience
                Ratings = $ratings
                Positives = $positives
                Negatives = $negatives
                Suggestions = $suggestions
                Overall = $overallRating
            }
            
            $feedback += $userFeedback
            
            $continueInput = Read-Host "`nVoulez-vous ajouter un autre retour utilisateur? (O/N)"
            $continueCollecting = $continueInput -eq "O" -or $continueInput -eq "o"
        }
        
        # Sauvegarder les retours dans un fichier
        $projectRoot = Get-ProjectPath
        $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
        $dataFolder = Join-Path -Path $n8nRoot -ChildPath "data"
        
        if (-not (Test-Path -Path $dataFolder)) {
            New-Item -Path $dataFolder -ItemType Directory -Force | Out-Null
        }
        
        $feedbackFilePath = Join-Path -Path $dataFolder -ChildPath "hygen-user-feedback.json"
        
        if ($PSCmdlet.ShouldProcess($feedbackFilePath, "Sauvegarder les retours")) {
            $feedback | ConvertTo-Json -Depth 10 | Set-Content -Path $feedbackFilePath
            Write-Success "Retours sauvegardés dans le fichier: $feedbackFilePath"
        }
        
        return $feedback
    }
}

# Fonction pour analyser les retours des utilisateurs
function Analyze-UserFeedback {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Feedback
    )
    
    $results = @{}
    
    # Calculer les moyennes des notes
    $ratingCategories = @(
        "Installation",
        "Utilisation",
        "Documentation",
        "Templates",
        "Utilitaires",
        "Bénéfices"
    )
    
    $averageRatings = @{}
    
    foreach ($category in $ratingCategories) {
        $ratings = $Feedback | ForEach-Object { $_["Ratings"][$category] }
        $average = ($ratings | Measure-Object -Average).Average
        $averageRatings[$category] = $average
    }
    
    $results["AverageRatings"] = $averageRatings
    
    # Calculer la note globale moyenne
    $overallRatings = $Feedback | ForEach-Object { $_["Overall"] }
    $averageOverall = ($overallRatings | Measure-Object -Average).Average
    $results["AverageOverall"] = $averageOverall
    
    # Collecter les points positifs, négatifs et suggestions
    $allPositives = @()
    $allNegatives = @()
    $allSuggestions = @()
    
    foreach ($userFeedback in $Feedback) {
        $allPositives += $userFeedback["Positives"]
        $allNegatives += $userFeedback["Negatives"]
        $allSuggestions += $userFeedback["Suggestions"]
    }
    
    $results["Positives"] = $allPositives
    $results["Negatives"] = $allNegatives
    $results["Suggestions"] = $allSuggestions
    
    # Calculer les statistiques par rôle et expérience
    $roleStats = @{}
    $experienceStats = @{}
    
    foreach ($userFeedback in $Feedback) {
        $role = $userFeedback["Role"]
        $experience = $userFeedback["Experience"]
        $overall = $userFeedback["Overall"]
        
        if (-not $roleStats.ContainsKey($role)) {
            $roleStats[$role] = @()
        }
        
        if (-not $experienceStats.ContainsKey($experience)) {
            $experienceStats[$experience] = @()
        }
        
        $roleStats[$role] += $overall
        $experienceStats[$experience] += $overall
    }
    
    $roleAverages = @{}
    $experienceAverages = @{}
    
    foreach ($role in $roleStats.Keys) {
        $average = ($roleStats[$role] | Measure-Object -Average).Average
        $roleAverages[$role] = $average
    }
    
    foreach ($experience in $experienceStats.Keys) {
        $average = ($experienceStats[$experience] | Measure-Object -Average).Average
        $experienceAverages[$experience] = $average
    }
    
    $results["RoleAverages"] = $roleAverages
    $results["ExperienceAverages"] = $experienceAverages
    
    return $results
}

# Fonction pour générer un rapport de satisfaction
function Generate-SatisfactionReport {
    param (
        [Parameter(Mandatory=$true)]
        [array]$Feedback,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Analysis,
        
        [Parameter(Mandatory=$true)]
        [string]$OutputPath
    )
    
    if ($PSCmdlet.ShouldProcess($OutputPath, "Générer le rapport")) {
        $report = @"
# Rapport de satisfaction des utilisateurs de Hygen

## Date
$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Résumé

- **Nombre d'utilisateurs interrogés**: $($Feedback.Count)
- **Note globale moyenne**: $($Analysis["AverageOverall"].ToString("0.0")) / 5
- **Satisfaction générale**: $(if ($Analysis["AverageOverall"] -ge 4.5) { "Excellente" } elseif ($Analysis["AverageOverall"] -ge 4.0) { "Très bonne" } elseif ($Analysis["AverageOverall"] -ge 3.5) { "Bonne" } elseif ($Analysis["AverageOverall"] -ge 3.0) { "Moyenne" } else { "Faible" })

## Notes par catégorie

| Catégorie | Note moyenne | Satisfaction |
|-----------|--------------|--------------|
"@
        
        foreach ($category in $Analysis["AverageRatings"].Keys) {
            $rating = $Analysis["AverageRatings"][$category]
            $satisfaction = if ($rating -ge 4.5) {
                "Excellente"
            } elseif ($rating -ge 4.0) {
                "Très bonne"
            } elseif ($rating -ge 3.5) {
                "Bonne"
            } elseif ($rating -ge 3.0) {
                "Moyenne"
            } else {
                "Faible"
            }
            
            $report += "`n| $category | $($rating.ToString("0.0")) | $satisfaction |"
        }
        
        $report += @"

## Notes par rôle

| Rôle | Note moyenne | Satisfaction |
|------|--------------|--------------|
"@
        
        foreach ($role in $Analysis["RoleAverages"].Keys) {
            $rating = $Analysis["RoleAverages"][$role]
            $satisfaction = if ($rating -ge 4.5) {
                "Excellente"
            } elseif ($rating -ge 4.0) {
                "Très bonne"
            } elseif ($rating -ge 3.5) {
                "Bonne"
            } elseif ($rating -ge 3.0) {
                "Moyenne"
            } else {
                "Faible"
            }
            
            $report += "`n| $role | $($rating.ToString("0.0")) | $satisfaction |"
        }
        
        $report += @"

## Notes par niveau d'expérience

| Expérience | Note moyenne | Satisfaction |
|------------|--------------|--------------|
"@
        
        foreach ($experience in $Analysis["ExperienceAverages"].Keys) {
            $rating = $Analysis["ExperienceAverages"][$experience]
            $satisfaction = if ($rating -ge 4.5) {
                "Excellente"
            } elseif ($rating -ge 4.0) {
                "Très bonne"
            } elseif ($rating -ge 3.5) {
                "Bonne"
            } elseif ($rating -ge 3.0) {
                "Moyenne"
            } else {
                "Faible"
            }
            
            $report += "`n| $experience | $($rating.ToString("0.0")) | $satisfaction |"
        }
        
        $report += @"

## Points positifs

"@
        
        foreach ($positive in $Analysis["Positives"]) {
            $report += "`n- $positive"
        }
        
        $report += @"

## Points négatifs

"@
        
        if ($Analysis["Negatives"].Count -gt 0) {
            foreach ($negative in $Analysis["Negatives"]) {
                $report += "`n- $negative"
            }
        } else {
            $report += "`n- Aucun point négatif signalé"
        }
        
        $report += @"

## Suggestions d'amélioration

"@
        
        if ($Analysis["Suggestions"].Count -gt 0) {
            foreach ($suggestion in $Analysis["Suggestions"]) {
                $report += "`n- $suggestion"
            }
        } else {
            $report += "`n- Aucune suggestion d'amélioration"
        }
        
        $report += @"

## Analyse de la satisfaction

"@
        
        $overallRating = $Analysis["AverageOverall"]
        
        if ($overallRating -ge 4.5) {
            $report += "`nLa satisfaction des utilisateurs est **excellente**. Hygen est très apprécié pour ses fonctionnalités et ses bénéfices. Les utilisateurs sont très satisfaits de l'outil et le recommandent fortement."
        } elseif ($overallRating -ge 4.0) {
            $report += "`nLa satisfaction des utilisateurs est **très bonne**. Hygen est bien apprécié pour ses fonctionnalités et ses bénéfices. Les utilisateurs sont satisfaits de l'outil et le recommandent."
        } elseif ($overallRating -ge 3.5) {
            $report += "`nLa satisfaction des utilisateurs est **bonne**. Hygen est apprécié pour certaines fonctionnalités et bénéfices, mais des améliorations sont souhaitées. Les utilisateurs sont globalement satisfaits de l'outil."
        } elseif ($overallRating -ge 3.0) {
            $report += "`nLa satisfaction des utilisateurs est **moyenne**. Hygen présente des avantages, mais aussi des inconvénients significatifs. Des améliorations importantes sont nécessaires pour augmenter la satisfaction des utilisateurs."
        } else {
            $report += "`nLa satisfaction des utilisateurs est **faible**. Hygen présente de nombreux problèmes qui affectent négativement l'expérience utilisateur. Des améliorations majeures sont nécessaires pour rendre l'outil plus utile et convivial."
        }
        
        $report += @"

## Recommandations

"@
        
        if ($overallRating -ge 4.0) {
            $report += @"

1. **Continuer à utiliser et promouvoir Hygen** dans le projet
2. **Adresser les points négatifs** signalés par les utilisateurs
3. **Implémenter les suggestions** d'amélioration les plus pertinentes
4. **Étendre l'utilisation de Hygen** à d'autres parties du projet
5. **Former les nouveaux développeurs** à l'utilisation de Hygen
"@
        } elseif ($overallRating -ge 3.0) {
            $report += @"

1. **Améliorer les aspects les moins bien notés** de Hygen
2. **Adresser en priorité les points négatifs** signalés par les utilisateurs
3. **Implémenter les suggestions** d'amélioration les plus pertinentes
4. **Recueillir des retours supplémentaires** pour mieux comprendre les problèmes
5. **Évaluer régulièrement la satisfaction** des utilisateurs pour mesurer les progrès
"@
        } else {
            $report += @"

1. **Réévaluer l'utilisation de Hygen** dans le projet
2. **Adresser les problèmes majeurs** signalés par les utilisateurs
3. **Envisager des alternatives** si les problèmes ne peuvent pas être résolus
4. **Limiter l'utilisation de Hygen** aux cas où il apporte une réelle valeur ajoutée
5. **Recueillir des retours détaillés** pour comprendre précisément les problèmes
"@
        }
        
        $report += @"

## Conclusion

"@
        
        if ($overallRating -ge 4.5) {
            $report += "`nHygen est un outil **très apprécié** par les utilisateurs. Il apporte une réelle valeur ajoutée au projet et son utilisation devrait être encouragée et étendue."
        } elseif ($overallRating -ge 4.0) {
            $report += "`nHygen est un outil **bien apprécié** par les utilisateurs. Il apporte une valeur ajoutée significative au projet, mais quelques améliorations pourraient encore augmenter sa valeur."
        } elseif ($overallRating -ge 3.5) {
            $report += "`nHygen est un outil **globalement apprécié** par les utilisateurs. Il apporte une certaine valeur ajoutée au projet, mais des améliorations sont nécessaires pour maximiser son potentiel."
        } elseif ($overallRating -ge 3.0) {
            $report += "`nHygen est un outil **moyennement apprécié** par les utilisateurs. Sa valeur ajoutée est limitée par plusieurs problèmes qui doivent être résolus pour justifier pleinement son utilisation."
        } else {
            $report += "`nHygen est un outil **peu apprécié** par les utilisateurs. Sa valeur ajoutée est très limitée et son utilisation devrait être réévaluée à moins que des améliorations majeures ne soient apportées."
        }
        
        Set-Content -Path $OutputPath -Value $report
        Write-Success "Rapport de satisfaction généré: $OutputPath"
        
        return $OutputPath
    } else {
        return $null
    }
}

# Fonction principale
function Start-UserFeedbackCollection {
    Write-Info "Collecte des retours des utilisateurs sur Hygen..."
    
    # Déterminer le chemin de sortie
    $projectRoot = Get-ProjectPath
    $n8nRoot = Join-Path -Path $projectRoot -ChildPath "n8n"
    $docsFolder = Join-Path -Path $n8nRoot -ChildPath "docs"
    
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $OutputPath = Join-Path -Path $docsFolder -ChildPath "hygen-user-feedback-report.md"
    }
    
    # Collecter les retours des utilisateurs
    $feedback = Collect-UserFeedback
    
    if (-not $feedback -or $feedback.Count -eq 0) {
        Write-Error "Aucun retour utilisateur collecté"
        return $false
    }
    
    # Analyser les retours des utilisateurs
    $analysis = Analyze-UserFeedback -Feedback $feedback
    
    # Générer un rapport de satisfaction
    $reportPath = Generate-SatisfactionReport -Feedback $feedback -Analysis $analysis -OutputPath $OutputPath
    
    # Afficher le résultat
    if ($reportPath) {
        Write-Success "Rapport de satisfaction généré: $reportPath"
    } else {
        Write-Error "Impossible de générer le rapport de satisfaction"
    }
    
    return $reportPath
}

# Exécuter la collecte des retours
Start-UserFeedbackCollection
