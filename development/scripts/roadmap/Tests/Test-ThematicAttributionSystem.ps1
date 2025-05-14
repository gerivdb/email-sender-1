#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour le système d'attribution thématique automatique.
.DESCRIPTION
    Ce script teste les fonctionnalités du module ThematicAttributionSystem.
.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
#>

[CmdletBinding()]
param()

# Importer le module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\modules\ThematicAttributionSystem.psm1"
Import-Module $modulePath -Force

# Définir les catégories thématiques pour les tests
$categories = @(
    @{
        Name     = "Frontend"
        Keywords = @("interface", "utilisateur", "UI", "design", "responsive", "mobile", "web", "CSS", "HTML", "JavaScript", "React", "Vue", "Angular")
        Prefix   = "FE"
    },
    @{
        Name     = "Backend"
        Keywords = @("serveur", "API", "base de données", "SQL", "NoSQL", "performance", "scalabilité", "sécurité", "authentification", "autorisation", "cache", "microservices")
        Prefix   = "BE"
    },
    @{
        Name     = "Infrastructure"
        Keywords = @("déploiement", "CI/CD", "conteneurs", "Docker", "Kubernetes", "cloud", "AWS", "Azure", "GCP", "monitoring", "logging", "alerting", "scaling", "infrastructure", "pipeline")
        Prefix   = "INFRA"
    },
    @{
        Name     = "Data"
        Keywords = @("données", "data", "analytics", "analyse", "statistiques", "machine learning", "IA", "intelligence artificielle", "ETL", "big data", "visualisation")
        Prefix   = "DATA"
    },
    @{
        Name     = "UX/UI"
        Keywords = @("expérience utilisateur", "UX", "UI", "design", "maquette", "prototype", "wireframe", "accessibilité", "ergonomie", "interface")
        Prefix   = "UX"
    },
    @{
        Name     = "DevOps"
        Keywords = @("automatisation", "pipeline", "CI/CD", "intégration continue", "déploiement continu", "monitoring", "observabilité", "infrastructure as code", "IaC")
        Prefix   = "DEVOPS"
    },
    @{
        Name     = "Security"
        Keywords = @("sécurité", "OWASP", "authentification", "autorisation", "chiffrement", "cryptographie", "audit", "vulnérabilité", "pentest", "firewall")
        Prefix   = "SEC"
    },
    @{
        Name     = "Testing"
        Keywords = @("test", "qualité", "QA", "unitaire", "intégration", "e2e", "end-to-end", "performance", "charge", "stress", "automatisation", "TDD", "BDD")
        Prefix   = "TEST"
    },
    @{
        Name     = "Documentation"
        Keywords = @("documentation", "guide", "manuel", "tutoriel", "wiki", "référence", "API doc", "spécification", "explication")
        Prefix   = "DOC"
    },
    @{
        Name     = "Project"
        Keywords = @("projet", "gestion", "planning", "roadmap", "backlog", "sprint", "agile", "scrum", "kanban", "réunion", "coordination")
        Prefix   = "PROJ"
    },
    @{
        Name     = "Thematic"
        Keywords = @("thème", "thématique", "attribution", "catégorie", "classification", "taxonomie", "tag", "étiquette", "analyse", "contenu", "sémantique")
        Prefix   = "THEME"
    }
)

# Initialiser le système d'attribution thématique
Initialize-ThematicSystem -Categories $categories -Verbose

# Test 1: Analyse de contenu simple
Write-Host "`n=== Test 1: Analyse de contenu simple ===" -ForegroundColor Cyan
$content = "Développer l'interface utilisateur responsive avec HTML et CSS"
$title = "UI Frontend"
$themes = Get-ContentThemes -Content $content -Title $title -MaxThemes 3
Write-Host "Contenu: $content"
Write-Host "Titre: $title"
Write-Host "Thèmes détectés:"
$themes | Format-Table -AutoSize

# Test 2: Analyse de contenu mixte
Write-Host "`n=== Test 2: Analyse de contenu mixte ===" -ForegroundColor Cyan
$content = "Optimiser les requêtes SQL de la base de données et améliorer l'interface utilisateur"
$title = "Optimisation backend et frontend"
$themes = Get-ContentThemes -Content $content -Title $title -MaxThemes 3
Write-Host "Contenu: $content"
Write-Host "Titre: $title"
Write-Host "Thèmes détectés:"
$themes | Format-Table -AutoSize

# Test 3: Attribution thématique à un élément
Write-Host "`n=== Test 3: Attribution thématique à un élément ===" -ForegroundColor Cyan
$task = [PSCustomObject]@{
    Title       = "Configurer le pipeline CI/CD"
    Description = "Mettre en place un pipeline d'intégration et de déploiement continu avec Docker et Kubernetes"
    Themes      = @()
}
Write-Host "Avant attribution:"
$task | Format-List

$updatedTask = Set-ItemThematicAttributes -Item $task -TitleField "Title" -DescriptionField "Description" -ThemeField "Themes"
Write-Host "Après attribution:"
$updatedTask | Format-List
$updatedTask.Themes | Format-Table -AutoSize

# Test 4: Test automatique du système
Write-Host "`n=== Test 4: Test automatique du système ===" -ForegroundColor Cyan
$testResult = Test-ThematicAttribution -Verbose
Write-Host "Résultat du test automatique: $testResult" -ForegroundColor $(if ($testResult) { "Green" } else { "Red" })

# Test 5: Analyse d'un élément de roadmap réel
Write-Host "`n=== Test 5: Analyse d'un élément de roadmap réel ===" -ForegroundColor Cyan
$roadmapItem = [PSCustomObject]@{
    id          = "3.2.1.1.1"
    title       = "Développer le système d'attribution thématique automatique"
    description = "Créer un système capable d'analyser le contenu des éléments de roadmap et de leur attribuer automatiquement des thèmes pertinents en fonction de leur contenu."
    type        = "task"
    status      = "in_progress"
    themes      = @()
}
Write-Host "Élément de roadmap:"
$roadmapItem | Format-List id, title, description, type, status

$updatedRoadmapItem = Set-ItemThematicAttributes -Item $roadmapItem -ThemeField "themes"
Write-Host "Thèmes attribués:"
$updatedRoadmapItem.themes | Format-Table -AutoSize

Write-Host "`nTous les tests sont terminés." -ForegroundColor Green
