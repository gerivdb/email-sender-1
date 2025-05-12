# Test-SemanticClassification.ps1
# Script de test pour la classification sémantique
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste les fonctionnalités de classification sémantique.

.DESCRIPTION
    Ce script teste les fonctionnalités de classification sémantique,
    notamment la génération d'embeddings, le clustering et l'étiquetage des clusters.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$classificationPath = Join-Path -Path $parentPath -ChildPath "classification"
$semanticClassificationPath = Join-Path -Path $classificationPath -ChildPath "Invoke-SemanticClassification.ps1"

if (Test-Path $semanticClassificationPath) {
    . $semanticClassificationPath
    Write-Host "Module Invoke-SemanticClassification.ps1 chargé." -ForegroundColor Green
} else {
    Write-Error "Module Invoke-SemanticClassification.ps1 introuvable à l'emplacement: $semanticClassificationPath"
    exit
}

# Fonction pour créer une roadmap de test
function New-TestRoadmap {
    <#
    .SYNOPSIS
        Crée une roadmap de test pour la classification sémantique.

    .DESCRIPTION
        Cette fonction crée une roadmap de test pour la classification sémantique,
        avec des tâches appartenant à différentes catégories thématiques.

    .PARAMETER OutputPath
        Le chemin où sauvegarder la roadmap de test.

    .PARAMETER TaskCount
        Le nombre de tâches à générer.
        Par défaut, 100 tâches.

    .PARAMETER Categories
        Les catégories thématiques à utiliser.
        Par défaut, 5 catégories.

    .OUTPUTS
        String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [int]$TaskCount = 100,

        [Parameter(Mandatory = $false)]
        [int]$Categories = 5
    )

    try {
        # Définir les catégories thématiques
        $categoryThemes = @(
            @{
                Name = "Frontend"
                Keywords = @("interface", "utilisateur", "UI", "design", "responsive", "mobile", "web", "CSS", "HTML", "JavaScript", "React", "Vue", "Angular")
                Prefix = "FE"
            },
            @{
                Name = "Backend"
                Keywords = @("serveur", "API", "base de données", "SQL", "NoSQL", "performance", "scalabilité", "sécurité", "authentification", "autorisation", "cache", "microservices")
                Prefix = "BE"
            },
            @{
                Name = "Infrastructure"
                Keywords = @("déploiement", "CI/CD", "conteneurs", "Docker", "Kubernetes", "cloud", "AWS", "Azure", "GCP", "monitoring", "logging", "alerting", "scaling")
                Prefix = "INFRA"
            },
            @{
                Name = "Data Science"
                Keywords = @("données", "analyse", "machine learning", "IA", "intelligence artificielle", "modèle", "prédiction", "classification", "régression", "clustering", "visualisation", "ETL")
                Prefix = "DS"
            },
            @{
                Name = "Sécurité"
                Keywords = @("sécurité", "vulnérabilité", "audit", "pentest", "cryptographie", "chiffrement", "authentification", "autorisation", "OWASP", "firewall", "WAF", "SIEM")
                Prefix = "SEC"
            },
            @{
                Name = "Gestion de projet"
                Keywords = @("planning", "roadmap", "backlog", "sprint", "agile", "scrum", "kanban", "réunion", "revue", "rétrospective", "estimation", "priorisation", "risque")
                Prefix = "PM"
            },
            @{
                Name = "Documentation"
                Keywords = @("documentation", "guide", "manuel", "tutoriel", "référence", "API", "architecture", "diagramme", "UML", "processus", "procédure", "standard")
                Prefix = "DOC"
            },
            @{
                Name = "Tests"
                Keywords = @("test", "unitaire", "intégration", "fonctionnel", "performance", "charge", "stress", "sécurité", "qualité", "couverture", "automatisation", "CI/CD")
                Prefix = "TEST"
            }
        )
        
        # Sélectionner les catégories à utiliser
        $selectedCategories = $categoryThemes | Get-Random -Count $Categories
        
        # Créer le contenu de la roadmap
        $content = @()
        $content += "# Roadmap de test pour la classification sémantique"
        $content += ""
        $content += "Cette roadmap est générée automatiquement pour tester la classification sémantique."
        $content += ""
        
        # Générer les tâches
        for ($i = 1; $i -le $TaskCount; $i++) {
            # Sélectionner une catégorie aléatoire
            $category = $selectedCategories | Get-Random
            
            # Générer un titre de tâche
            $keywords = $category.Keywords | Get-Random -Count (Get-Random -Minimum 2 -Maximum 5)
            $title = "Tâche de $($category.Name): " + ($keywords -join " ")
            
            # Générer un identifiant de tâche
            $taskId = "$($category.Prefix)-$i"
            
            # Générer un statut aléatoire
            $status = if (Get-Random -Minimum 0 -Maximum 100 -lt 30) { "[x]" } else { "[ ]" }
            
            # Ajouter la tâche à la roadmap
            $content += "- $status **$taskId** $title"
            
            # Ajouter des sous-tâches pour certaines tâches
            if (Get-Random -Minimum 0 -Maximum 100 -lt 20) {
                $subTaskCount = Get-Random -Minimum 2 -Maximum 5
                
                for ($j = 1; $j -le $subTaskCount; $j++) {
                    # Générer un titre de sous-tâche
                    $subKeywords = $category.Keywords | Get-Random -Count (Get-Random -Minimum 1 -Maximum 3)
                    $subTitle = "Sous-tâche $j: " + ($subKeywords -join " ")
                    
                    # Générer un identifiant de sous-tâche
                    $subTaskId = "$taskId.$j"
                    
                    # Générer un statut aléatoire
                    $subStatus = if (Get-Random -Minimum 0 -Maximum 100 -lt 50) { "[x]" } else { "[ ]" }
                    
                    # Ajouter la sous-tâche à la roadmap
                    $content += "  - $subStatus **$subTaskId** $subTitle"
                }
            }
        }
        
        # Écrire le contenu dans le fichier
        $content | Out-File -FilePath $OutputPath -Encoding UTF8
        
        return $OutputPath
    } catch {
        Write-Error "Échec de la création de la roadmap de test: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour tester la classification sémantique
function Test-SemanticClassificationFunctionality {
    <#
    .SYNOPSIS
        Teste les fonctionnalités de classification sémantique.

    .DESCRIPTION
        Cette fonction teste les fonctionnalités de classification sémantique,
        notamment la génération d'embeddings, le clustering et l'étiquetage des clusters.

    .PARAMETER RoadmapPath
        Le chemin vers le fichier de roadmap à tester.
        Si non spécifié, une roadmap de test est générée.

    .PARAMETER TaskCount
        Le nombre de tâches à générer pour la roadmap de test.
        Par défaut, 50 tâches.

    .PARAMETER NumberOfClusters
        Le nombre de clusters à créer.
        Par défaut, 5 clusters.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats du test.
        Si non spécifié, un dossier temporaire est utilisé.

    .EXAMPLE
        Test-SemanticClassificationFunctionality -TaskCount 100 -NumberOfClusters 8
        Teste la classification sémantique avec une roadmap de test de 100 tâches et 8 clusters.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RoadmapPath = "",

        [Parameter(Mandatory = $false)]
        [int]$TaskCount = 50,

        [Parameter(Mandatory = $false)]
        [int]$NumberOfClusters = 5,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )

    try {
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path $env:TEMP -ChildPath "SemanticClassificationTest"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Créer une roadmap de test si nécessaire
        if ([string]::IsNullOrEmpty($RoadmapPath)) {
            $testRoadmapPath = Join-Path -Path $OutputPath -ChildPath "test-roadmap.md"
            Write-Host "Création d'une roadmap de test..." -ForegroundColor Cyan
            $RoadmapPath = New-TestRoadmap -OutputPath $testRoadmapPath -TaskCount $TaskCount -Categories 5
            
            if ([string]::IsNullOrEmpty($RoadmapPath)) {
                Write-Error "Échec de la création de la roadmap de test."
                return $null
            }
            
            Write-Host "Roadmap de test créée: $RoadmapPath" -ForegroundColor Green
        }
        
        # Vérifier que le fichier de roadmap existe
        if (-not (Test-Path $RoadmapPath)) {
            Write-Error "Le fichier de roadmap n'existe pas: $RoadmapPath"
            return $null
        }
        
        # Tester la classification sémantique
        Write-Host "Exécution de la classification sémantique..." -ForegroundColor Cyan
        $result = Invoke-SemanticClassification -RoadmapPath $RoadmapPath -OutputPath $OutputPath -NumberOfClusters $NumberOfClusters -ClusteringAlgorithm "kmeans"
        
        if ($null -eq $result) {
            Write-Error "Échec de la classification sémantique."
            return $null
        }
        
        # Afficher les résultats
        Write-Host "Classification sémantique terminée." -ForegroundColor Green
        Write-Host "Nombre de clusters: $($result.LabeledClusters.Count)" -ForegroundColor Green
        Write-Host "Rapport de classification: $($result.ReportFilePath)" -ForegroundColor Green
        
        # Afficher les clusters
        Write-Host
        Write-Host "Résumé des clusters:" -ForegroundColor Cyan
        
        foreach ($cluster in $result.LabeledClusters) {
            Write-Host "  Cluster $($cluster.ClusterId): $($cluster.Label) ($($cluster.TaskCount) tâches)" -ForegroundColor Yellow
        }
        
        # Ouvrir le rapport HTML
        if (Test-Path $result.ReportFilePath) {
            Write-Host
            Write-Host "Ouverture du rapport de classification..." -ForegroundColor Cyan
            Start-Process $result.ReportFilePath
        }
        
        return $result
    } catch {
        Write-Error "Échec du test de classification sémantique: $($_.Exception.Message)"
        return $null
    }
}

# Exécuter le test
Write-Host "=== TEST DE CLASSIFICATION SÉMANTIQUE ===" -ForegroundColor Cyan
Write-Host

$testResult = Test-SemanticClassificationFunctionality -TaskCount 30 -NumberOfClusters 5

if ($null -ne $testResult) {
    Write-Host
    Write-Host "Test de classification sémantique réussi." -ForegroundColor Green
    Write-Host "Temps d'exécution: $($testResult.ExecutionTime.TotalSeconds) secondes" -ForegroundColor Green
} else {
    Write-Host
    Write-Host "Test de classification sémantique échoué." -ForegroundColor Red
}
