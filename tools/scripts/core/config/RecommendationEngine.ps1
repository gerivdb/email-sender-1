# Script pour améliorer les recommandations d'erreurs
# Respecte les principes SOLID, DRY, KISS et Clean Code

# Configuration
$RecommendationConfig = @{
    # Dossier des recommandations
    RecommendationsFolder = Join-Path -Path $env:TEMP -ChildPath "ErrorRecommendations"
    
    # Fichier de base de données des recommandations
    RecommendationsFile = Join-Path -Path $env:TEMP -ChildPath "ErrorRecommendations\recommendations.json"
    
    # Fichier de feedback sur les recommandations
    FeedbackFile = Join-Path -Path $env:TEMP -ChildPath "ErrorRecommendations\feedback.json"
    
    # Seuil de pertinence pour les recommandations
    RelevanceThreshold = 0.6
}

# Fonction pour initialiser le moteur de recommandations
function Initialize-RecommendationEngine {
    param (
        [string]$RecommendationsFolder = "",
        [string]$RecommendationsFile = "",
        [string]$FeedbackFile = "",
        [double]$RelevanceThreshold = 0
    )
    
    # Mettre à jour la configuration avec les paramètres fournis
    if (-not [string]::IsNullOrEmpty($RecommendationsFolder)) {
        $RecommendationConfig.RecommendationsFolder = $RecommendationsFolder
    }
    
    if (-not [string]::IsNullOrEmpty($RecommendationsFile)) {
        $RecommendationConfig.RecommendationsFile = $RecommendationsFile
    }
    
    if (-not [string]::IsNullOrEmpty($FeedbackFile)) {
        $RecommendationConfig.FeedbackFile = $FeedbackFile
    }
    
    if ($RelevanceThreshold -gt 0) {
        $RecommendationConfig.RelevanceThreshold = $RelevanceThreshold
    }
    
    # Créer les dossiers s'ils n'existent pas
    if (-not (Test-Path -Path $RecommendationConfig.RecommendationsFolder)) {
        New-Item -Path $RecommendationConfig.RecommendationsFolder -ItemType Directory -Force | Out-Null
    }
    
    # Créer le fichier de recommandations s'il n'existe pas
    if (-not (Test-Path -Path $RecommendationConfig.RecommendationsFile)) {
        $initialRecommendations = @{
            Recommendations = @()
            LastUpdate = Get-Date -Format "o"
        }
        
        $initialRecommendations | ConvertTo-Json -Depth 5 | Set-Content -Path $RecommendationConfig.RecommendationsFile
    }
    
    # Créer le fichier de feedback s'il n'existe pas
    if (-not (Test-Path -Path $RecommendationConfig.FeedbackFile)) {
        $initialFeedback = @{
            Feedback = @()
            LastUpdate = Get-Date -Format "o"
        }
        
        $initialFeedback | ConvertTo-Json -Depth 5 | Set-Content -Path $RecommendationConfig.FeedbackFile
    }
    
    return $RecommendationConfig
}

# Fonction pour ajouter une recommandation
function Add-ErrorRecommendation {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorPattern,
        
        [Parameter(Mandatory = $true)]
        [string]$Recommendation,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "General",
        
        [Parameter(Mandatory = $false)]
        [string]$Severity = "Warning",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Tags = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$Source = "Manual",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )
    
    # Vérifier si le fichier de recommandations existe
    if (-not (Test-Path -Path $RecommendationConfig.RecommendationsFile)) {
        Initialize-RecommendationEngine
    }
    
    # Charger les recommandations existantes
    $recommendationsData = Get-Content -Path $RecommendationConfig.RecommendationsFile -Raw | ConvertFrom-Json
    
    # Vérifier si la recommandation existe déjà
    $existingRecommendation = $recommendationsData.Recommendations | Where-Object { $_.ErrorPattern -eq $ErrorPattern }
    
    if ($existingRecommendation) {
        Write-Warning "Une recommandation pour ce pattern d'erreur existe déjà."
        return $null
    }
    
    # Créer la recommandation
    $newRecommendation = @{
        ID = [Guid]::NewGuid().ToString()
        ErrorPattern = $ErrorPattern
        Recommendation = $Recommendation
        Category = $Category
        Severity = $Severity
        Tags = $Tags
        Source = $Source
        Metadata = $Metadata
        CreatedAt = Get-Date -Format "o"
        UpdatedAt = Get-Date -Format "o"
        UsageCount = 0
        SuccessCount = 0
        RelevanceScore = 0
    }
    
    # Ajouter la recommandation
    $recommendationsData.Recommendations += $newRecommendation
    $recommendationsData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les recommandations
    $recommendationsData | ConvertTo-Json -Depth 5 | Set-Content -Path $RecommendationConfig.RecommendationsFile
    
    return $newRecommendation
}

# Fonction pour obtenir des recommandations pour une erreur
function Get-ErrorRecommendations {
    param (
        [Parameter(Mandatory = $true)]
        [string]$ErrorMessage,
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [int]$MaxResults = 3,
        
        [Parameter(Mandatory = $false)]
        [double]$MinRelevance = 0
    )
    
    # Utiliser le seuil par défaut si non spécifié
    if ($MinRelevance -le 0) {
        $MinRelevance = $RecommendationConfig.RelevanceThreshold
    }
    
    # Charger les recommandations
    $recommendationsData = Get-Content -Path $RecommendationConfig.RecommendationsFile -Raw | ConvertFrom-Json
    
    # Filtrer par catégorie si spécifiée
    $recommendations = $recommendationsData.Recommendations
    if (-not [string]::IsNullOrEmpty($Category)) {
        $recommendations = $recommendations | Where-Object { $_.Category -eq $Category }
    }
    
    # Calculer la pertinence pour chaque recommandation
    $relevantRecommendations = @()
    
    foreach ($recommendation in $recommendations) {
        try {
            $pattern = [regex]$recommendation.ErrorPattern
            
            if ($pattern.IsMatch($ErrorMessage)) {
                # Calculer un score de pertinence basé sur la longueur du pattern et le nombre d'utilisations réussies
                $patternLength = $recommendation.ErrorPattern.Length
                $successRate = if ($recommendation.UsageCount -gt 0) {
                    $recommendation.SuccessCount / $recommendation.UsageCount
                }
                else {
                    0.5  # Valeur par défaut pour les nouvelles recommandations
                }
                
                $relevance = ($patternLength / 100) * 0.7 + $successRate * 0.3
                $relevance = [Math]::Min(1, $relevance)
                
                if ($relevance -ge $MinRelevance) {
                    $relevantRecommendations += [PSCustomObject]@{
                        Recommendation = $recommendation
                        Relevance = $relevance
                    }
                }
            }
        }
        catch {
            # Ignorer les patterns invalides
            Write-Warning "Pattern d'erreur invalide: $($recommendation.ErrorPattern)"
        }
    }
    
    # Trier par pertinence et limiter le nombre de résultats
    $result = $relevantRecommendations | Sort-Object -Property Relevance -Descending | Select-Object -First $MaxResults
    
    # Mettre à jour les compteurs d'utilisation
    foreach ($item in $result) {
        $recommendation = $item.Recommendation
        $recommendation.UsageCount++
        $recommendation.UpdatedAt = Get-Date -Format "o"
    }
    
    # Enregistrer les recommandations mises à jour
    $recommendationsData.LastUpdate = Get-Date -Format "o"
    $recommendationsData | ConvertTo-Json -Depth 5 | Set-Content -Path $RecommendationConfig.RecommendationsFile
    
    return $result
}

# Fonction pour ajouter un feedback sur une recommandation
function Add-RecommendationFeedback {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RecommendationID,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success,
        
        [Parameter(Mandatory = $false)]
        [int]$Rating = 0,
        
        [Parameter(Mandatory = $false)]
        [string]$Comments = "",
        
        [Parameter(Mandatory = $false)]
        [string]$UserID = $env:USERNAME
    )
    
    # Vérifier si les fichiers existent
    if (-not (Test-Path -Path $RecommendationConfig.RecommendationsFile) -or
        -not (Test-Path -Path $RecommendationConfig.FeedbackFile)) {
        Initialize-RecommendationEngine
    }
    
    # Charger les recommandations
    $recommendationsData = Get-Content -Path $RecommendationConfig.RecommendationsFile -Raw | ConvertFrom-Json
    
    # Trouver la recommandation
    $recommendation = $recommendationsData.Recommendations | Where-Object { $_.ID -eq $RecommendationID }
    
    if (-not $recommendation) {
        Write-Error "Recommandation non trouvée: $RecommendationID"
        return $false
    }
    
    # Mettre à jour les compteurs
    if ($Success) {
        $recommendation.SuccessCount++
    }
    
    # Charger les feedbacks
    $feedbackData = Get-Content -Path $RecommendationConfig.FeedbackFile -Raw | ConvertFrom-Json
    
    # Créer le feedback
    $newFeedback = @{
        ID = [Guid]::NewGuid().ToString()
        RecommendationID = $RecommendationID
        Success = $Success
        Rating = $Rating
        Comments = $Comments
        UserID = $UserID
        Timestamp = Get-Date -Format "o"
    }
    
    # Ajouter le feedback
    $feedbackData.Feedback += $newFeedback
    $feedbackData.LastUpdate = Get-Date -Format "o"
    
    # Enregistrer les données
    $recommendationsData.LastUpdate = Get-Date -Format "o"
    $recommendationsData | ConvertTo-Json -Depth 5 | Set-Content -Path $RecommendationConfig.RecommendationsFile
    $feedbackData | ConvertTo-Json -Depth 5 | Set-Content -Path $RecommendationConfig.FeedbackFile
    
    return $newFeedback
}

# Fonction pour améliorer les recommandations basées sur le feedback
function Update-RecommendationsFromFeedback {
    # Charger les données
    $recommendationsData = Get-Content -Path $RecommendationConfig.RecommendationsFile -Raw | ConvertFrom-Json
    $feedbackData = Get-Content -Path $RecommendationConfig.FeedbackFile -Raw | ConvertFrom-Json
    
    # Grouper les feedbacks par recommandation
    $feedbacksByRecommendation = @{}
    
    foreach ($feedback in $feedbackData.Feedback) {
        $recommendationID = $feedback.RecommendationID
        
        if (-not $feedbacksByRecommendation.ContainsKey($recommendationID)) {
            $feedbacksByRecommendation[$recommendationID] = @()
        }
        
        $feedbacksByRecommendation[$recommendationID] += $feedback
    }
    
    # Mettre à jour les scores de pertinence
    foreach ($recommendation in $recommendationsData.Recommendations) {
        $feedbacks = $feedbacksByRecommendation[$recommendation.ID]
        
        if ($feedbacks -and $feedbacks.Count -gt 0) {
            # Calculer le taux de succès
            $successCount = ($feedbacks | Where-Object { $_.Success } | Measure-Object).Count
            $successRate = $successCount / $feedbacks.Count
            
            # Calculer la note moyenne
            $ratingSum = ($feedbacks | Measure-Object -Property Rating -Sum).Sum
            $ratingAvg = if ($feedbacks.Count -gt 0) { $ratingSum / $feedbacks.Count } else { 0 }
            
            # Mettre à jour le score de pertinence
            $recommendation.RelevanceScore = ($successRate * 0.7) + ($ratingAvg / 5 * 0.3)
        }
    }
    
    # Enregistrer les recommandations mises à jour
    $recommendationsData.LastUpdate = Get-Date -Format "o"
    $recommendationsData | ConvertTo-Json -Depth 5 | Set-Content -Path $RecommendationConfig.RecommendationsFile
    
    return $recommendationsData.Recommendations
}

# Fonction pour générer des recommandations à partir des patterns d'erreur
function New-RecommendationsFromPatterns {
    param (
        [Parameter(Mandatory = $true)]
        [string]$PatternsFile,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    # Vérifier si le fichier de patterns existe
    if (-not (Test-Path -Path $PatternsFile)) {
        Write-Error "Le fichier de patterns n'existe pas: $PatternsFile"
        return $null
    }
    
    # Charger les patterns
    $patternsData = Get-Content -Path $PatternsFile -Raw | ConvertFrom-Json
    
    # Charger les recommandations existantes
    $recommendationsData = Get-Content -Path $RecommendationConfig.RecommendationsFile -Raw | ConvertFrom-Json
    
    $newRecommendations = @()
    $updatedRecommendations = @()
    
    foreach ($pattern in $patternsData.Patterns) {
        # Vérifier si une recommandation existe déjà pour ce pattern
        $existingRecommendation = $recommendationsData.Recommendations | Where-Object { $_.ErrorPattern -eq $pattern.Pattern }
        
        if ($existingRecommendation -and -not $Force) {
            # Mettre à jour la recommandation existante si elle a une solution
            if (-not [string]::IsNullOrEmpty($pattern.Solution)) {
                $existingRecommendation.Recommendation = $pattern.Solution
                $existingRecommendation.UpdatedAt = Get-Date -Format "o"
                $updatedRecommendations += $existingRecommendation
            }
        }
        else {
            # Créer une nouvelle recommandation si le pattern a une solution
            if (-not [string]::IsNullOrEmpty($pattern.Solution)) {
                $newRecommendation = Add-ErrorRecommendation -ErrorPattern $pattern.Pattern `
                    -Recommendation $pattern.Solution -Category $pattern.Category `
                    -Severity $pattern.Severity -Source "Pattern" `
                    -Tags @("Auto-generated")
                
                if ($newRecommendation) {
                    $newRecommendations += $newRecommendation
                }
            }
        }
    }
    
    return @{
        New = $newRecommendations
        Updated = $updatedRecommendations
    }
}

# Fonction pour générer un rapport des recommandations
function New-RecommendationsReport {
    param (
        [Parameter(Mandatory = $false)]
        [string]$Title = "Rapport des recommandations d'erreurs",
        
        [Parameter(Mandatory = $false)]
        [string]$Category = "",
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$OpenOutput
    )
    
    # Charger les recommandations
    $recommendationsData = Get-Content -Path $RecommendationConfig.RecommendationsFile -Raw | ConvertFrom-Json
    
    # Filtrer par catégorie si spécifiée
    $recommendations = $recommendationsData.Recommendations
    if (-not [string]::IsNullOrEmpty($Category)) {
        $recommendations = $recommendations | Where-Object { $_.Category -eq $Category }
    }
    
    # Déterminer le chemin de sortie
    if ([string]::IsNullOrEmpty($OutputPath)) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $fileName = "RecommendationsReport-$timestamp.html"
        $OutputPath = Join-Path -Path $env:TEMP -ChildPath $fileName
    }
    
    # Générer le HTML
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>$Title</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 20px;
            color: #333;
        }
        
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        
        h1, h2, h3 {
            color: #2c3e50;
        }
        
        .header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 1px solid #eee;
        }
        
        .recommendation {
            margin-bottom: 30px;
            padding: 15px;
            background-color: #f8f9fa;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .recommendation h3 {
            margin-top: 0;
            margin-bottom: 10px;
        }
        
        .recommendation-meta {
            font-size: 14px;
            color: #666;
            margin-bottom: 10px;
        }
        
        .pattern {
            font-family: monospace;
            background-color: #f1f1f1;
            padding: 10px;
            border-radius: 4px;
            margin-bottom: 10px;
            overflow-x: auto;
        }
        
        .solution {
            background-color: #e8f5e9;
            padding: 10px;
            border-radius: 4px;
            margin-bottom: 10px;
        }
        
        .tags {
            margin-top: 10px;
        }
        
        .tag {
            display: inline-block;
            background-color: #e0e0e0;
            padding: 4px 8px;
            border-radius: 4px;
            margin-right: 5px;
            font-size: 12px;
        }
        
        .severity-critical {
            color: #d9534f;
            font-weight: bold;
        }
        
        .severity-error {
            color: #f0ad4e;
            font-weight: bold;
        }
        
        .severity-warning {
            color: #5bc0de;
        }
        
        .severity-info {
            color: #5cb85c;
        }
        
        .footer {
            margin-top: 30px;
            text-align: center;
            font-size: 14px;
            color: #888;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>$Title</h1>
            <div>
                <span>Généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</span>
            </div>
        </div>
        
        <div class="summary">
            <p>Nombre total de recommandations: $($recommendations.Count)</p>
            $(if (-not [string]::IsNullOrEmpty($Category)) { "<p>Catégorie: $Category</p>" })
        </div>
        
        <h2>Recommandations d'erreurs</h2>
        
        $(foreach ($recommendation in ($recommendations | Sort-Object -Property RelevanceScore -Descending)) {
            $severityClass = "severity-" + $recommendation.Severity.ToLower()
            $createdAt = [DateTime]::Parse($recommendation.CreatedAt).ToString("yyyy-MM-dd HH:mm:ss")
            $updatedAt = [DateTime]::Parse($recommendation.UpdatedAt).ToString("yyyy-MM-dd HH:mm:ss")
            $relevancePercent = [Math]::Round($recommendation.RelevanceScore * 100, 1)
            
            "<div class='recommendation'>
                <h3>Recommandation #$($recommendation.ID.Substring(0, 8))</h3>
                <div class='recommendation-meta'>
                    <span>Catégorie: $($recommendation.Category)</span> |
                    <span>Sévérité: <span class='$severityClass'>$($recommendation.Severity)</span></span> |
                    <span>Source: $($recommendation.Source)</span> |
                    <span>Pertinence: $relevancePercent%</span>
                </div>
                <div class='recommendation-meta'>
                    <span>Créé le: $createdAt</span> |
                    <span>Mis à jour le: $updatedAt</span> |
                    <span>Utilisations: $($recommendation.UsageCount)</span> |
                    <span>Succès: $($recommendation.SuccessCount)</span>
                </div>
                <div class='pattern'>
                    <strong>Pattern d'erreur:</strong><br>
                    $($recommendation.ErrorPattern)
                </div>
                <div class='solution'>
                    <strong>Recommandation:</strong><br>
                    $($recommendation.Recommendation)
                </div>
                $(if ($recommendation.Tags.Count -gt 0) {
                    "<div class='tags'>
                        $(foreach ($tag in $recommendation.Tags) {
                            "<span class='tag'>$tag</span>"
                        })
                    </div>"
                })
            </div>"
        })
        
        <div class="footer">
            <p>Rapport généré le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")</p>
        </div>
    </div>
</body>
</html>
"@
    
    # Enregistrer le HTML
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    
    # Ouvrir le rapport si demandé
    if ($OpenOutput) {
        Invoke-Item -Path $OutputPath
    }
    
    return $OutputPath
}

# Exporter les fonctions
Export-ModuleMember -Function Initialize-RecommendationEngine, Add-ErrorRecommendation, Get-ErrorRecommendations
Export-ModuleMember -Function Add-RecommendationFeedback, Update-RecommendationsFromFeedback
Export-ModuleMember -Function New-RecommendationsFromPatterns, New-RecommendationsReport
