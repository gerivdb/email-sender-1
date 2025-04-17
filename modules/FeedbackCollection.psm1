#Requires -Version 5.1
<#
.SYNOPSIS
    Module de collecte de feedback pour EMAIL_SENDER_1.
.DESCRIPTION
    Ce module fournit des fonctions pour collecter, stocker et analyser
    les feedbacks des utilisateurs.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-05-22
#>

# Variables globales
$script:FeedbackPath = Join-Path -Path $PSScriptRoot -ChildPath "..\feedback"
$script:LogsPath = Join-Path -Path $PSScriptRoot -ChildPath "..\logs\feedback"

# Fonction pour écrire dans le journal
function Write-FeedbackLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Créer le dossier des logs s'il n'existe pas
    if (-not (Test-Path -Path $script:LogsPath)) {
        New-Item -Path $script:LogsPath -ItemType Directory -Force | Out-Null
    }
    
    # Fichier de log
    $logFile = Join-Path -Path $script:LogsPath -ChildPath "feedback_$(Get-Date -Format 'yyyyMMdd').log"
    
    # Écrire dans le fichier de log
    $logMessage | Out-File -FilePath $logFile -Append -Encoding utf8
    
    # Afficher dans la console
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

# Fonction pour soumettre un feedback
function Submit-Feedback {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Component,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("Bug", "Feature Request", "Performance Issue", "Other")]
        [string]$FeedbackType,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $false)]
        [string]$UserName = $env:USERNAME,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$Severity = 3
    )
    
    # Créer le dossier de feedback s'il n'existe pas
    if (-not (Test-Path -Path $script:FeedbackPath)) {
        New-Item -Path $script:FeedbackPath -ItemType Directory -Force | Out-Null
    }
    
    # Créer l'objet de feedback
    $feedback = [PSCustomObject]@{
        Id = [guid]::NewGuid().ToString()
        Component = $Component
        FeedbackType = $FeedbackType
        Description = $Description
        UserName = $UserName
        Severity = $Severity
        Status = "New"
        CreatedAt = (Get-Date).ToString("o")
        UpdatedAt = (Get-Date).ToString("o")
        Comments = @()
    }
    
    # Enregistrer le feedback
    $feedbackFile = Join-Path -Path $script:FeedbackPath -ChildPath "feedback_$($feedback.Id).json"
    $feedback | ConvertTo-Json -Depth 10 | Out-File -FilePath $feedbackFile -Encoding utf8
    
    Write-FeedbackLog "Nouveau feedback soumis: $($feedback.Id) - $Component - $FeedbackType" -Level "SUCCESS"
    
    return $feedback
}

# Fonction pour obtenir tous les feedbacks
function Get-Feedbacks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Component = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Bug", "Feature Request", "Performance Issue", "Other", "")]
        [string]$FeedbackType = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("New", "In Progress", "Resolved", "Closed", "")]
        [string]$Status = "",
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$MinSeverity = 1,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 5)]
        [int]$MaxSeverity = 5
    )
    
    # Vérifier si le dossier de feedback existe
    if (-not (Test-Path -Path $script:FeedbackPath)) {
        Write-FeedbackLog "Le dossier de feedback n'existe pas: $($script:FeedbackPath)" -Level "WARNING"
        return @()
    }
    
    # Obtenir tous les fichiers de feedback
    $feedbackFiles = Get-ChildItem -Path $script:FeedbackPath -Filter "feedback_*.json"
    
    if ($feedbackFiles.Count -eq 0) {
        Write-FeedbackLog "Aucun feedback trouvé" -Level "INFO"
        return @()
    }
    
    # Charger et filtrer les feedbacks
    $feedbacks = @()
    
    foreach ($file in $feedbackFiles) {
        try {
            $feedback = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
            
            # Appliquer les filtres
            $match = $true
            
            if ($Component -and $feedback.Component -ne $Component) {
                $match = $false
            }
            
            if ($FeedbackType -and $feedback.FeedbackType -ne $FeedbackType) {
                $match = $false
            }
            
            if ($Status -and $feedback.Status -ne $Status) {
                $match = $false
            }
            
            if ($feedback.Severity -lt $MinSeverity -or $feedback.Severity -gt $MaxSeverity) {
                $match = $false
            }
            
            if ($match) {
                $feedbacks += $feedback
            }
        }
        catch {
            Write-FeedbackLog "Erreur lors du chargement du feedback $($file.FullName): $_" -Level "ERROR"
        }
    }
    
    return $feedbacks
}

# Fonction pour mettre à jour un feedback
function Update-Feedback {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("New", "In Progress", "Resolved", "Closed")]
        [string]$Status = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Comment = "",
        
        [Parameter(Mandatory = $false)]
        [string]$CommentBy = $env:USERNAME
    )
    
    # Vérifier si le dossier de feedback existe
    if (-not (Test-Path -Path $script:FeedbackPath)) {
        Write-FeedbackLog "Le dossier de feedback n'existe pas: $($script:FeedbackPath)" -Level "ERROR"
        return $null
    }
    
    # Obtenir le fichier de feedback
    $feedbackFile = Join-Path -Path $script:FeedbackPath -ChildPath "feedback_$Id.json"
    
    if (-not (Test-Path -Path $feedbackFile)) {
        Write-FeedbackLog "Feedback non trouvé: $Id" -Level "ERROR"
        return $null
    }
    
    # Charger le feedback
    try {
        $feedback = Get-Content -Path $feedbackFile -Raw | ConvertFrom-Json
        
        # Mettre à jour le statut si spécifié
        if ($Status) {
            $feedback.Status = $Status
        }
        
        # Ajouter un commentaire si spécifié
        if ($Comment) {
            if (-not $feedback.Comments) {
                $feedback | Add-Member -MemberType NoteProperty -Name "Comments" -Value @()
            }
            
            $feedback.Comments += [PSCustomObject]@{
                Text = $Comment
                By = $CommentBy
                CreatedAt = (Get-Date).ToString("o")
            }
        }
        
        # Mettre à jour la date de mise à jour
        $feedback.UpdatedAt = (Get-Date).ToString("o")
        
        # Enregistrer le feedback mis à jour
        $feedback | ConvertTo-Json -Depth 10 | Out-File -FilePath $feedbackFile -Encoding utf8
        
        Write-FeedbackLog "Feedback mis à jour: $Id" -Level "SUCCESS"
        
        return $feedback
    }
    catch {
        Write-FeedbackLog "Erreur lors de la mise à jour du feedback $Id: $_" -Level "ERROR"
        return $null
    }
}

# Fonction pour analyser les feedbacks
function Analyze-Feedbacks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )
    
    # Obtenir tous les feedbacks
    $feedbacks = Get-Feedbacks
    
    if ($feedbacks.Count -eq 0) {
        Write-FeedbackLog "Aucun feedback à analyser" -Level "INFO"
        return $null
    }
    
    # Analyser par composant
    $componentStats = $feedbacks | Group-Object -Property Component | Select-Object @{Name="Component"; Expression={$_.Name}}, @{Name="Count"; Expression={$_.Count}}
    
    # Analyser par type de feedback
    $typeStats = $feedbacks | Group-Object -Property FeedbackType | Select-Object @{Name="FeedbackType"; Expression={$_.Name}}, @{Name="Count"; Expression={$_.Count}}
    
    # Analyser par statut
    $statusStats = $feedbacks | Group-Object -Property Status | Select-Object @{Name="Status"; Expression={$_.Name}}, @{Name="Count"; Expression={$_.Count}}
    
    # Analyser par sévérité
    $severityStats = $feedbacks | Group-Object -Property Severity | Select-Object @{Name="Severity"; Expression={$_.Name}}, @{Name="Count"; Expression={$_.Count}}
    
    # Créer le rapport d'analyse
    $analysis = [PSCustomObject]@{
        GeneratedAt = (Get-Date).ToString("o")
        TotalFeedbacks = $feedbacks.Count
        ComponentStats = $componentStats
        TypeStats = $typeStats
        StatusStats = $statusStats
        SeverityStats = $severityStats
    }
    
    # Enregistrer le rapport si demandé
    if ($OutputPath) {
        $outputDir = Split-Path -Path $OutputPath -Parent
        
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        $analysis | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
        
        Write-FeedbackLog "Rapport d'analyse enregistré dans $OutputPath" -Level "SUCCESS"
    }
    
    return $analysis
}

# Fonction pour identifier les opportunités d'amélioration
function Identify-ImprovementOpportunities {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )
    
    # Obtenir tous les feedbacks
    $feedbacks = Get-Feedbacks
    
    if ($feedbacks.Count -eq 0) {
        Write-FeedbackLog "Aucun feedback à analyser" -Level "INFO"
        return $null
    }
    
    # Identifier les composants avec le plus de bugs
    $buggyComponents = $feedbacks | Where-Object { $_.FeedbackType -eq "Bug" } | Group-Object -Property Component | Sort-Object -Property Count -Descending | Select-Object @{Name="Component"; Expression={$_.Name}}, @{Name="BugCount"; Expression={$_.Count}}
    
    # Identifier les composants avec le plus de problèmes de performance
    $slowComponents = $feedbacks | Where-Object { $_.FeedbackType -eq "Performance Issue" } | Group-Object -Property Component | Sort-Object -Property Count -Descending | Select-Object @{Name="Component"; Expression={$_.Name}}, @{Name="PerformanceIssueCount"; Expression={$_.Count}}
    
    # Identifier les demandes de fonctionnalités les plus populaires
    $popularFeatures = $feedbacks | Where-Object { $_.FeedbackType -eq "Feature Request" } | Group-Object -Property Description | Sort-Object -Property Count -Descending | Select-Object @{Name="Feature"; Expression={$_.Name}}, @{Name="RequestCount"; Expression={$_.Count}}
    
    # Identifier les problèmes critiques non résolus
    $criticalIssues = $feedbacks | Where-Object { $_.Severity -ge 4 -and $_.Status -ne "Resolved" -and $_.Status -ne "Closed" } | Select-Object Id, Component, FeedbackType, Description, Severity, Status
    
    # Créer le rapport d'opportunités d'amélioration
    $opportunities = [PSCustomObject]@{
        GeneratedAt = (Get-Date).ToString("o")
        BuggyComponents = $buggyComponents
        SlowComponents = $slowComponents
        PopularFeatures = $popularFeatures
        CriticalIssues = $criticalIssues
    }
    
    # Enregistrer le rapport si demandé
    if ($OutputPath) {
        $outputDir = Split-Path -Path $OutputPath -Parent
        
        if (-not (Test-Path -Path $outputDir)) {
            New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
        }
        
        $opportunities | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
        
        Write-FeedbackLog "Rapport d'opportunités d'amélioration enregistré dans $OutputPath" -Level "SUCCESS"
    }
    
    return $opportunities
}

# Exporter les fonctions
Export-ModuleMember -Function Submit-Feedback, Get-Feedbacks, Update-Feedback, Analyze-Feedbacks, Identify-ImprovementOpportunities
