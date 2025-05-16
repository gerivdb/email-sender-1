#Requires -Version 5.1
<#
.SYNOPSIS
    Applique l'attribution thématique automatique aux roadmaps.
.DESCRIPTION
    Ce script analyse les roadmaps existantes et leur attribue automatiquement des thèmes.
.PARAMETER RoadmapPath
    Chemin vers le fichier JSON de la roadmap à analyser.
.PARAMETER OutputPath
    Chemin où enregistrer la roadmap avec les thèmes attribués.
.PARAMETER MaxThemesPerItem
    Nombre maximum de thèmes à attribuer par élément.
.PARAMETER ThemeField
    Nom du champ où stocker les thèmes.
.EXAMPLE
    .\Apply-ThematicAttribution.ps1 -RoadmapPath "projet\roadmaps\json\plan-dev-v12-architecture-cognitive.json" -OutputPath "projet\roadmaps\json\plan-dev-v12-architecture-cognitive-with-themes.json"
.NOTES
    Version: 1.0
    Auteur: EMAIL_SENDER_1 Team
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RoadmapPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "",

    [Parameter(Mandatory = $false)]
    [int]$MaxThemesPerItem = 3,

    [Parameter(Mandatory = $false)]
    [string]$ThemeField = "themes"
)

# Importer le module d'attribution thématique
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "modules\ThematicAttributionSystem.psm1"
Import-Module $modulePath -Force

# Fonction pour créer un répertoire si nécessaire
function New-DirectoryIfNotExists {
    param([string]$Path)

    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-Verbose "Répertoire créé: $Path"
    }
}

# Fonction pour traiter récursivement les éléments de la roadmap
function Update-RoadmapItems {
    param(
        [PSObject]$Item,
        [string]$TitleField = "title",
        [string]$DescriptionField = "description",
        [string]$ChildrenField = "children"
    )

    # Attribuer des thèmes à l'élément actuel
    $Item = Set-ItemThematicAttributes -Item $Item -TitleField $TitleField -DescriptionField $DescriptionField -ThemeField $ThemeField -MaxThemes $MaxThemesPerItem

    # Traiter les enfants récursivement
    if ($Item.$ChildrenField -and $Item.$ChildrenField.Count -gt 0) {
        for ($i = 0; $i -lt $Item.$ChildrenField.Count; $i++) {
            $Item.$ChildrenField[$i] = Update-RoadmapItems -Item $Item.$ChildrenField[$i] -TitleField $TitleField -DescriptionField $DescriptionField -ChildrenField $ChildrenField
        }
    }

    return $Item
}

# Vérifier que le fichier de roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    throw "Le fichier de roadmap n'existe pas: $RoadmapPath"
}

# Définir le chemin de sortie s'il n'est pas spécifié
if (-not $OutputPath) {
    $directory = [System.IO.Path]::GetDirectoryName($RoadmapPath)
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($RoadmapPath)
    $extension = [System.IO.Path]::GetExtension($RoadmapPath)
    $OutputPath = Join-Path -Path $directory -ChildPath "$filename-with-themes$extension"
}

# Créer le répertoire de sortie si nécessaire
$outputDir = [System.IO.Path]::GetDirectoryName($OutputPath)
New-DirectoryIfNotExists -Path $outputDir

# Charger la roadmap
Write-Host "Chargement de la roadmap: $RoadmapPath" -ForegroundColor Cyan
try {
    $roadmap = Get-Content -Path $RoadmapPath -Raw | ConvertFrom-Json -ErrorAction Stop
} catch {
    throw "Erreur lors du chargement de la roadmap: $_"
}

# Définir les catégories thématiques
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
        Keywords = @("déploiement", "CI/CD", "conteneurs", "Docker", "Kubernetes", "cloud", "AWS", "Azure", "GCP", "monitoring", "logging", "alerting", "scaling")
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
        Name     = "Architecture"
        Keywords = @("architecture", "conception", "design pattern", "modèle", "structure", "composant", "module", "service", "microservice", "monolithe")
        Prefix   = "ARCH"
    },
    @{
        Name     = "Cognitive"
        Keywords = @("cognitif", "cognitive", "intelligence", "apprentissage", "connaissance", "sémantique", "ontologie", "taxonomie", "classification", "catégorisation")
        Prefix   = "COG"
    }
)

# Initialiser le système d'attribution thématique
Write-Host "Initialisation du système d'attribution thématique..." -ForegroundColor Cyan
Initialize-ThematicSystem -Categories $categories

# Traiter la roadmap
Write-Host "Attribution des thèmes à la roadmap..." -ForegroundColor Cyan
$roadmapWithThemes = Update-RoadmapItems -Item $roadmap

# Enregistrer la roadmap avec les thèmes
Write-Host "Enregistrement de la roadmap avec les thèmes: $OutputPath" -ForegroundColor Cyan
try {
    $roadmapWithThemes | ConvertTo-Json -Depth 100 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-Host "Roadmap avec thèmes enregistrée avec succès." -ForegroundColor Green
} catch {
    Write-Error "Erreur lors de l'enregistrement de la roadmap: $_"
}

# Afficher un résumé
$totalItems = 0
$itemsWithThemes = 0
$themeDistribution = @{}

function Measure-RoadmapItems {
    param(
        [PSObject]$Item,
        [string]$ChildrenField = "children"
    )

    $script:totalItems++

    if ($Item.$ThemeField -and $Item.$ThemeField.Count -gt 0) {
        $script:itemsWithThemes++

        foreach ($theme in $Item.$ThemeField) {
            $themeName = $theme.Theme
            if (-not $themeDistribution.ContainsKey($themeName)) {
                $themeDistribution[$themeName] = 0
            }
            $themeDistribution[$themeName]++
        }
    }

    if ($Item.$ChildrenField -and $Item.$ChildrenField.Count -gt 0) {
        foreach ($child in $Item.$ChildrenField) {
            Measure-RoadmapItems -Item $child -ChildrenField $ChildrenField
        }
    }
}

Measure-RoadmapItems -Item $roadmapWithThemes

Write-Host "`nRésumé de l'attribution thématique:" -ForegroundColor Cyan
Write-Host "Total d'éléments: $totalItems"
Write-Host "Éléments avec thèmes: $itemsWithThemes ($([math]::Round(($itemsWithThemes / $totalItems) * 100, 2))%)"
Write-Host "`nDistribution des thèmes:"
$themeDistribution.GetEnumerator() | Sort-Object -Property Value -Descending | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value) ($([math]::Round(($_.Value / $itemsWithThemes) * 100, 2))%)"
}
