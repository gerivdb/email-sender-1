#Requires -Version 5.1
<#
.SYNOPSIS
    Test simple du système d'attribution thématique automatique.
.DESCRIPTION
    Ce script teste le système d'attribution thématique sur des exemples simples.
.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
#>

[CmdletBinding()]
param()

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\ThematicAttributionSystem.psm1"
Import-Module $modulePath -Force

# Définir les catégories thématiques pour les tests
$categories = @(
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
        Keywords = @("déploiement", "CI/CD", "conteneurs", "Docker", "Kubernetes", "cloud", "AWS", "Azure", "GCP", "monitoring", "logging", "alerting", "scaling", "infrastructure", "pipeline")
        Prefix = "INFRA"
    },
    @{
        Name = "Thematic"
        Keywords = @("thème", "thématique", "attribution", "catégorie", "classification", "taxonomie", "tag", "étiquette", "analyse", "contenu", "sémantique")
        Prefix = "THEME"
    },
    @{
        Name = "Architecture"
        Keywords = @("architecture", "conception", "design pattern", "modèle", "structure", "composant", "module", "service", "microservice", "monolithe", "cognitive")
        Prefix = "ARCH"
    }
)

# Initialiser le système d'attribution thématique
Write-Host "Initialisation du système d'attribution thématique..." -ForegroundColor Cyan
Initialize-ThematicSystem -Categories $categories

# Exemples de test
$testCases = @(
    @{
        Title = "Développer l'interface utilisateur responsive"
        Description = "Créer une interface utilisateur responsive avec HTML, CSS et JavaScript"
        ExpectedThemes = @("Frontend")
    },
    @{
        Title = "Optimiser les requêtes SQL"
        Description = "Améliorer les performances des requêtes SQL dans la base de données"
        ExpectedThemes = @("Backend")
    },
    @{
        Title = "Configurer le déploiement CI/CD"
        Description = "Mettre en place un pipeline CI/CD avec Docker et Kubernetes"
        ExpectedThemes = @("Infrastructure", "DevOps")
    },
    @{
        Title = "Développer le système d'attribution thématique automatique"
        Description = "Créer un système capable d'analyser le contenu des éléments de roadmap et de leur attribuer automatiquement des thèmes pertinents en fonction de leur contenu."
        ExpectedThemes = @("Thematic")
    },
    @{
        Title = "Implémenter l'architecture cognitive"
        Description = "Développer l'architecture cognitive à 10 niveaux pour la gestion des roadmaps"
        ExpectedThemes = @("Architecture")
    }
)

# Tester chaque cas
foreach ($test in $testCases) {
    Write-Host "`n=== Test: $($test.Title) ===" -ForegroundColor Cyan
    Write-Host "Description: $($test.Description)"
    Write-Host "Thèmes attendus: $($test.ExpectedThemes -join ', ')"
    
    $themes = Get-ContentThemes -Content $test.Description -Title $test.Title -MaxThemes 3
    
    Write-Host "Thèmes détectés:" -ForegroundColor Yellow
    $themes | Format-Table -AutoSize
    
    # Vérifier si les thèmes attendus sont présents
    $themeNames = $themes | Select-Object -ExpandProperty Theme
    $success = $false
    foreach ($expectedTheme in $test.ExpectedThemes) {
        if ($themeNames -contains $expectedTheme) {
            $success = $true
            break
        }
    }
    
    if ($success) {
        Write-Host "Résultat: Réussi" -ForegroundColor Green
    } else {
        Write-Host "Résultat: Échoué" -ForegroundColor Red
    }
}

Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
