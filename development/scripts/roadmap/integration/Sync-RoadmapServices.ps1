# Sync-RoadmapServices.ps1
# Script principal pour synchroniser les roadmaps avec différents services externes
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Synchronise les roadmaps avec différents services externes.

.DESCRIPTION
    Ce script synchronise les roadmaps avec différents services externes,
    comme Notion, GitHub, Jira, etc.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$integrationPath = Join-Path -Path $scriptPath -ChildPath "integration"
$utilsPath = Join-Path -Path $scriptPath -ChildPath "utils"

$connectNotionRoadmapPath = Join-Path -Path $integrationPath -ChildPath "Connect-NotionRoadmap.ps1"
$connectGitHubRoadmapPath = Join-Path -Path $integrationPath -ChildPath "Connect-GitHubRoadmap.ps1"
$importExportNotionPath = Join-Path -Path $integrationPath -ChildPath "Import-ExportNotion.ps1"
$manageNotionTemplatesPath = Join-Path -Path $integrationPath -ChildPath "Manage-NotionTemplates.ps1"
$parseRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Parse-Roadmap.ps1"
$generateRoadmapPath = Join-Path -Path $utilsPath -ChildPath "Generate-Roadmap.ps1"

Write-Host "Chargement des modules..." -ForegroundColor Cyan

if (Test-Path $connectNotionRoadmapPath) {
    . $connectNotionRoadmapPath
    Write-Host "  Module Connect-NotionRoadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Connect-NotionRoadmap.ps1 introuvable à l'emplacement: $connectNotionRoadmapPath" -ForegroundColor Red
    exit
}

if (Test-Path $connectGitHubRoadmapPath) {
    . $connectGitHubRoadmapPath
    Write-Host "  Module Connect-GitHubRoadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Connect-GitHubRoadmap.ps1 introuvable à l'emplacement: $connectGitHubRoadmapPath" -ForegroundColor Red
    exit
}

if (Test-Path $importExportNotionPath) {
    . $importExportNotionPath
    Write-Host "  Module Import-ExportNotion.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Import-ExportNotion.ps1 introuvable à l'emplacement: $importExportNotionPath" -ForegroundColor Red
    exit
}

if (Test-Path $manageNotionTemplatesPath) {
    . $manageNotionTemplatesPath
    Write-Host "  Module Manage-NotionTemplates.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Manage-NotionTemplates.ps1 introuvable à l'emplacement: $manageNotionTemplatesPath" -ForegroundColor Red
    exit
}

if (Test-Path $parseRoadmapPath) {
    . $parseRoadmapPath
    Write-Host "  Module Parse-Roadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Parse-Roadmap.ps1 introuvable à l'emplacement: $parseRoadmapPath" -ForegroundColor Red
    exit
}

if (Test-Path $generateRoadmapPath) {
    . $generateRoadmapPath
    Write-Host "  Module Generate-Roadmap.ps1 chargé." -ForegroundColor Green
} else {
    Write-Host "  Module Generate-Roadmap.ps1 introuvable à l'emplacement: $generateRoadmapPath" -ForegroundColor Red
    exit
}

# Fonction pour afficher le menu principal
function Show-MainMenu {
    Clear-Host
    Write-Host "=== SYNCHRONISATION DES ROADMAPS ===" -ForegroundColor Cyan
    Write-Host
    Write-Host "1. Synchroniser avec Notion" -ForegroundColor Yellow
    Write-Host "2. Synchroniser bidirectionnellement avec Notion" -ForegroundColor Yellow
    Write-Host "3. Exporter une base de données Notion" -ForegroundColor Yellow
    Write-Host "4. Importer une base de données Notion" -ForegroundColor Yellow
    Write-Host "5. Créer un template Notion" -ForegroundColor Yellow
    Write-Host "6. Appliquer un template Notion" -ForegroundColor Yellow
    Write-Host "7. Lister les templates Notion" -ForegroundColor Yellow
    Write-Host "8. Synchroniser avec GitHub (Issues)" -ForegroundColor Yellow
    Write-Host "9. Synchroniser avec GitHub (Projets)" -ForegroundColor Yellow
    Write-Host "10. Synchroniser avec GitHub (Pull Requests)" -ForegroundColor Yellow
    Write-Host "11. Synchroniser avec tous les services" -ForegroundColor Yellow
    Write-Host "12. Configurer les services" -ForegroundColor Yellow
    Write-Host "13. Quitter" -ForegroundColor Yellow
    Write-Host
    Write-Host "Entrez votre choix (1-13): " -ForegroundColor Cyan -NoNewline

    $choice = Read-Host
    return $choice
}

# Fonction pour synchroniser avec Notion
function Sync-WithNotion {
    Clear-Host
    Write-Host "=== SYNCHRONISER AVEC NOTION ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Chemin de la roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Chemin de roadmap invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Token d'intégration Notion: " -ForegroundColor Yellow -NoNewline
    $notionToken = Read-Host

    if ([string]::IsNullOrEmpty($notionToken)) {
        Write-Host "Token d'intégration Notion invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "ID de la base de données Notion (laisser vide pour en créer une nouvelle): " -ForegroundColor Yellow -NoNewline
    $databaseId = Read-Host

    if ([string]::IsNullOrEmpty($databaseId)) {
        Write-Host "ID de la page parent Notion: " -ForegroundColor Yellow -NoNewline
        $parentPageId = Read-Host

        if ([string]::IsNullOrEmpty($parentPageId)) {
            Write-Host "ID de la page parent Notion invalide." -ForegroundColor Red
            Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
            Read-Host
            return
        }
    } else {
        $parentPageId = ""
    }

    # Se connecter à l'API Notion
    Write-Host
    Write-Host "Connexion à l'API Notion..." -ForegroundColor Cyan

    $connection = Connect-NotionApi -Token $notionToken

    if ($null -eq $connection) {
        Write-Host "Échec de la connexion à l'API Notion." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Synchroniser la roadmap avec Notion
    Write-Host "Synchronisation de la roadmap avec Notion..." -ForegroundColor Cyan

    $result = Sync-RoadmapToNotion -Connection $connection -RoadmapPath $roadmapPath -DatabaseId $databaseId -ParentPageId $parentPageId

    if ($null -ne $result) {
        Write-Host "Synchronisation réussie!" -ForegroundColor Green
        Write-Host "Base de données Notion: $($result.DatabaseId)" -ForegroundColor Green
        Write-Host "Titre: $($result.Title)" -ForegroundColor Green
        Write-Host "Nombre de tâches: $($result.TaskCount)" -ForegroundColor Green
    } else {
        Write-Host "Échec de la synchronisation avec Notion." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour synchroniser bidirectionnellement avec Notion
function Sync-WithNotionBidirectional {
    Clear-Host
    Write-Host "=== SYNCHRONISER BIDIRECTIONNELLEMENT AVEC NOTION ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Chemin de la roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Chemin de roadmap invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Token d'intégration Notion: " -ForegroundColor Yellow -NoNewline
    $notionToken = Read-Host

    if ([string]::IsNullOrEmpty($notionToken)) {
        Write-Host "Token d'intégration Notion invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "ID de la base de données Notion (laisser vide pour en créer une nouvelle): " -ForegroundColor Yellow -NoNewline
    $databaseId = Read-Host

    if ([string]::IsNullOrEmpty($databaseId)) {
        Write-Host "ID de la page parent Notion: " -ForegroundColor Yellow -NoNewline
        $parentPageId = Read-Host

        if ([string]::IsNullOrEmpty($parentPageId)) {
            Write-Host "ID de la page parent Notion invalide." -ForegroundColor Red
            Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
            Read-Host
            return
        }
    } else {
        $parentPageId = ""
    }

    Write-Host "Direction de la synchronisation (ToNotion/FromNotion/Both, défaut: Both): " -ForegroundColor Yellow -NoNewline
    $direction = Read-Host

    if ([string]::IsNullOrEmpty($direction)) {
        $direction = "Both"
    }

    Write-Host "Résolution des conflits (Local/Remote/Newer/Ask, défaut: Ask): " -ForegroundColor Yellow -NoNewline
    $conflictResolution = Read-Host

    if ([string]::IsNullOrEmpty($conflictResolution)) {
        $conflictResolution = "Ask"
    }

    # Se connecter à l'API Notion
    Write-Host
    Write-Host "Connexion à l'API Notion..." -ForegroundColor Cyan

    $connection = Connect-NotionApi -Token $notionToken

    if ($null -eq $connection) {
        Write-Host "Échec de la connexion à l'API Notion." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Synchroniser bidirectionnellement la roadmap avec Notion
    Write-Host "Synchronisation bidirectionnelle de la roadmap avec Notion..." -ForegroundColor Cyan

    $result = Sync-RoadmapBidirectional -Connection $connection -RoadmapPath $roadmapPath -DatabaseId $databaseId -ParentPageId $parentPageId -Direction $direction -ConflictResolution $conflictResolution

    if ($null -ne $result) {
        Write-Host "Synchronisation bidirectionnelle réussie!" -ForegroundColor Green
        Write-Host "Base de données Notion: $($result.DatabaseId)" -ForegroundColor Green
        Write-Host "Titre: $($result.Title)" -ForegroundColor Green
        Write-Host "Nombre de tâches: $($result.TaskCount)" -ForegroundColor Green

        if ($result.PSObject.Properties.Name -contains "TasksAdded") {
            Write-Host "Tâches ajoutées: $($result.TasksAdded)" -ForegroundColor Green
        }

        if ($result.PSObject.Properties.Name -contains "TasksDeleted") {
            Write-Host "Tâches supprimées: $($result.TasksDeleted)" -ForegroundColor Green
        }

        if ($result.PSObject.Properties.Name -contains "Conflicts") {
            Write-Host "Conflits: $($result.Conflicts)" -ForegroundColor Green
        }

        if ($result.PSObject.Properties.Name -contains "ResolvedConflicts") {
            Write-Host "Conflits résolus: $($result.ResolvedConflicts)" -ForegroundColor Green
        }
    } else {
        Write-Host "Échec de la synchronisation bidirectionnelle avec Notion." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour exporter une base de données Notion
function Export-WithNotion {
    Clear-Host
    Write-Host "=== EXPORTER UNE BASE DE DONNÉES NOTION ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Token d'intégration Notion: " -ForegroundColor Yellow -NoNewline
    $notionToken = Read-Host

    if ([string]::IsNullOrEmpty($notionToken)) {
        Write-Host "Token d'intégration Notion invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "ID de la base de données Notion: " -ForegroundColor Yellow -NoNewline
    $databaseId = Read-Host

    if ([string]::IsNullOrEmpty($databaseId)) {
        Write-Host "ID de la base de données Notion invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Chemin du fichier de sortie (laisser vide pour utiliser le dossier courant): " -ForegroundColor Yellow -NoNewline
    $outputPath = Read-Host

    Write-Host "Inclure le contenu des pages (o/n, défaut: n): " -ForegroundColor Yellow -NoNewline
    $includeContent = Read-Host
    $includeContentSwitch = $includeContent -eq "o"

    # Se connecter à l'API Notion
    Write-Host
    Write-Host "Connexion à l'API Notion..." -ForegroundColor Cyan

    $connection = Connect-NotionApi -Token $notionToken

    if ($null -eq $connection) {
        Write-Host "Échec de la connexion à l'API Notion." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Exporter la base de données Notion
    Write-Host "Export de la base de données Notion..." -ForegroundColor Cyan

    $result = Export-NotionDatabase -Connection $connection -DatabaseId $databaseId -OutputPath $outputPath -IncludeContent:$includeContentSwitch

    if ($null -ne $result) {
        Write-Host "Export réussi!" -ForegroundColor Green
        Write-Host "Base de données Notion: $($result.DatabaseId)" -ForegroundColor Green
        Write-Host "Titre: $($result.Title)" -ForegroundColor Green
        Write-Host "Nombre de pages: $($result.PageCount)" -ForegroundColor Green
        Write-Host "Fichier d'export: $($result.OutputPath)" -ForegroundColor Green
    } else {
        Write-Host "Échec de l'export de la base de données Notion." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour importer une base de données Notion
function Import-WithNotion {
    Clear-Host
    Write-Host "=== IMPORTER UNE BASE DE DONNÉES NOTION ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Token d'intégration Notion: " -ForegroundColor Yellow -NoNewline
    $notionToken = Read-Host

    if ([string]::IsNullOrEmpty($notionToken)) {
        Write-Host "Token d'intégration Notion invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Chemin du fichier d'entrée: " -ForegroundColor Yellow -NoNewline
    $inputPath = Read-Host

    if ([string]::IsNullOrEmpty($inputPath) -or -not (Test-Path $inputPath)) {
        Write-Host "Chemin du fichier d'entrée invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "ID de la base de données Notion existante (laisser vide pour en créer une nouvelle): " -ForegroundColor Yellow -NoNewline
    $databaseId = Read-Host

    if ([string]::IsNullOrEmpty($databaseId)) {
        Write-Host "ID de la page parent Notion: " -ForegroundColor Yellow -NoNewline
        $parentPageId = Read-Host

        if ([string]::IsNullOrEmpty($parentPageId)) {
            Write-Host "ID de la page parent Notion invalide." -ForegroundColor Red
            Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
            Read-Host
            return
        }
    } else {
        $parentPageId = ""
    }

    Write-Host "Importer le contenu des pages (o/n, défaut: n): " -ForegroundColor Yellow -NoNewline
    $importContent = Read-Host
    $importContentSwitch = $importContent -eq "o"

    # Se connecter à l'API Notion
    Write-Host
    Write-Host "Connexion à l'API Notion..." -ForegroundColor Cyan

    $connection = Connect-NotionApi -Token $notionToken

    if ($null -eq $connection) {
        Write-Host "Échec de la connexion à l'API Notion." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Importer la base de données Notion
    Write-Host "Import de la base de données Notion..." -ForegroundColor Cyan

    $result = Import-NotionDatabase -Connection $connection -InputPath $inputPath -DatabaseId $databaseId -ParentPageId $parentPageId -ImportContent:$importContentSwitch

    if ($null -ne $result) {
        Write-Host "Import réussi!" -ForegroundColor Green
        Write-Host "Base de données Notion: $($result.DatabaseId)" -ForegroundColor Green
        Write-Host "Titre: $($result.Title)" -ForegroundColor Green
        Write-Host "Pages créées: $($result.PagesCreated)" -ForegroundColor Green
        Write-Host "Pages mises à jour: $($result.PagesUpdated)" -ForegroundColor Green
    } else {
        Write-Host "Échec de l'import de la base de données Notion." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour créer un template Notion
function New-WithNotionTemplate {
    Clear-Host
    Write-Host "=== CRÉER UN TEMPLATE NOTION ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Token d'intégration Notion: " -ForegroundColor Yellow -NoNewline
    $notionToken = Read-Host

    if ([string]::IsNullOrEmpty($notionToken)) {
        Write-Host "Token d'intégration Notion invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "ID de la base de données Notion: " -ForegroundColor Yellow -NoNewline
    $databaseId = Read-Host

    if ([string]::IsNullOrEmpty($databaseId)) {
        Write-Host "ID de la base de données Notion invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nom du template: " -ForegroundColor Yellow -NoNewline
    $templateName = Read-Host

    if ([string]::IsNullOrEmpty($templateName)) {
        Write-Host "Nom du template invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Description du template: " -ForegroundColor Yellow -NoNewline
    $templateDescription = Read-Host

    Write-Host "Chemin du fichier de sortie (laisser vide pour utiliser le dossier par défaut): " -ForegroundColor Yellow -NoNewline
    $outputPath = Read-Host

    Write-Host "Inclure le contenu des pages (o/n, défaut: n): " -ForegroundColor Yellow -NoNewline
    $includeContent = Read-Host
    $includeContentSwitch = $includeContent -eq "o"

    # Se connecter à l'API Notion
    Write-Host
    Write-Host "Connexion à l'API Notion..." -ForegroundColor Cyan

    $connection = Connect-NotionApi -Token $notionToken

    if ($null -eq $connection) {
        Write-Host "Échec de la connexion à l'API Notion." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Créer le template
    Write-Host "Création du template..." -ForegroundColor Cyan

    $result = New-NotionTemplate -Connection $connection -DatabaseId $databaseId -TemplateName $templateName -TemplateDescription $templateDescription -OutputPath $outputPath -IncludeContent:$includeContentSwitch

    if ($null -ne $result) {
        Write-Host "Création du template réussie!" -ForegroundColor Green
        Write-Host "Nom du template: $($result.TemplateName)" -ForegroundColor Green
        Write-Host "Description: $($result.TemplateDescription)" -ForegroundColor Green
        Write-Host "Base de données Notion: $($result.DatabaseId)" -ForegroundColor Green
        Write-Host "Nombre de pages: $($result.PageCount)" -ForegroundColor Green
        Write-Host "Fichier de template: $($result.OutputPath)" -ForegroundColor Green
    } else {
        Write-Host "Échec de la création du template." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour appliquer un template Notion
function Use-NotionTemplate {
    Clear-Host
    Write-Host "=== APPLIQUER UN TEMPLATE NOTION ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Token d'intégration Notion: " -ForegroundColor Yellow -NoNewline
    $notionToken = Read-Host

    if ([string]::IsNullOrEmpty($notionToken)) {
        Write-Host "Token d'intégration Notion invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Chemin du fichier de template: " -ForegroundColor Yellow -NoNewline
    $templatePath = Read-Host

    if ([string]::IsNullOrEmpty($templatePath) -or -not (Test-Path $templatePath)) {
        Write-Host "Chemin du fichier de template invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "ID de la base de données Notion existante (laisser vide pour en créer une nouvelle): " -ForegroundColor Yellow -NoNewline
    $databaseId = Read-Host

    if ([string]::IsNullOrEmpty($databaseId)) {
        Write-Host "ID de la page parent Notion: " -ForegroundColor Yellow -NoNewline
        $parentPageId = Read-Host

        if ([string]::IsNullOrEmpty($parentPageId)) {
            Write-Host "ID de la page parent Notion invalide." -ForegroundColor Red
            Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
            Read-Host
            return
        }
    } else {
        $parentPageId = ""
    }

    Write-Host "Inclure le contenu des pages (o/n, défaut: n): " -ForegroundColor Yellow -NoNewline
    $includeContent = Read-Host
    $includeContentSwitch = $includeContent -eq "o"

    # Se connecter à l'API Notion
    Write-Host
    Write-Host "Connexion à l'API Notion..." -ForegroundColor Cyan

    $connection = Connect-NotionApi -Token $notionToken

    if ($null -eq $connection) {
        Write-Host "Échec de la connexion à l'API Notion." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Appliquer le template
    Write-Host "Application du template..." -ForegroundColor Cyan

    $result = Apply-NotionTemplate -Connection $connection -TemplatePath $templatePath -DatabaseId $databaseId -ParentPageId $parentPageId -IncludeContent:$includeContentSwitch

    if ($null -ne $result) {
        Write-Host "Application du template réussie!" -ForegroundColor Green
        Write-Host "Nom du template: $($result.TemplateName)" -ForegroundColor Green
        Write-Host "Description: $($result.TemplateDescription)" -ForegroundColor Green
        Write-Host "Base de données Notion: $($result.DatabaseId)" -ForegroundColor Green
        Write-Host "Pages créées: $($result.PagesCreated)" -ForegroundColor Green
    } else {
        Write-Host "Échec de l'application du template." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour lister les templates Notion
function Get-WithNotionTemplates {
    Clear-Host
    Write-Host "=== LISTER LES TEMPLATES NOTION ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Dossier des templates (laisser vide pour utiliser le dossier par défaut): " -ForegroundColor Yellow -NoNewline
    $templatesDir = Read-Host

    # Lister les templates
    Write-Host "Liste des templates..." -ForegroundColor Cyan

    $templates = Get-NotionTemplates -TemplatesDir $templatesDir

    if ($null -ne $templates -and $templates.Count -gt 0) {
        Write-Host "Templates trouvés: $($templates.Count)" -ForegroundColor Green

        # Afficher les templates
        foreach ($template in $templates) {
            Write-Host
            Write-Host "Nom: $($template.Name)" -ForegroundColor Green
            Write-Host "Description: $($template.Description)" -ForegroundColor Green
            Write-Host "Créé le: $($template.CreatedAt)" -ForegroundColor Green
            Write-Host "Nombre de pages: $($template.PageCount)" -ForegroundColor Green
            Write-Host "Chemin: $($template.Path)" -ForegroundColor Green
        }
    } else {
        Write-Host "Aucun template trouvé." -ForegroundColor Yellow
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour synchroniser avec GitHub
function Sync-WithGitHub {
    Clear-Host
    Write-Host "=== SYNCHRONISER AVEC GITHUB ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Chemin de la roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Chemin de roadmap invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Token d'accès personnel GitHub: " -ForegroundColor Yellow -NoNewline
    $githubToken = Read-Host

    if ([string]::IsNullOrEmpty($githubToken)) {
        Write-Host "Token d'accès personnel GitHub invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Propriétaire du dépôt GitHub: " -ForegroundColor Yellow -NoNewline
    $owner = Read-Host

    if ([string]::IsNullOrEmpty($owner)) {
        Write-Host "Propriétaire du dépôt GitHub invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nom du dépôt GitHub: " -ForegroundColor Yellow -NoNewline
    $repo = Read-Host

    if ([string]::IsNullOrEmpty($repo)) {
        Write-Host "Nom du dépôt GitHub invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Préfixe des labels (défaut: roadmap): " -ForegroundColor Yellow -NoNewline
    $labelPrefix = Read-Host

    if ([string]::IsNullOrEmpty($labelPrefix)) {
        $labelPrefix = "roadmap"
    }

    # Se connecter à l'API GitHub
    Write-Host
    Write-Host "Connexion à l'API GitHub..." -ForegroundColor Cyan

    $connection = Connect-GitHubApi -Token $githubToken

    if ($null -eq $connection) {
        Write-Host "Échec de la connexion à l'API GitHub." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Synchroniser la roadmap avec GitHub
    Write-Host "Synchronisation de la roadmap avec GitHub..." -ForegroundColor Cyan

    $result = Sync-RoadmapToGitHub -Connection $connection -RoadmapPath $roadmapPath -Owner $owner -Repo $repo -LabelPrefix $labelPrefix

    if ($null -ne $result) {
        Write-Host "Synchronisation réussie!" -ForegroundColor Green
        Write-Host "Dépôt GitHub: $($result.Repository)" -ForegroundColor Green
        Write-Host "Titre: $($result.Title)" -ForegroundColor Green
        Write-Host "Nombre total d'issues: $($result.TotalIssues)" -ForegroundColor Green
        Write-Host "Issues créées: $($result.CreatedIssues)" -ForegroundColor Green
        Write-Host "Issues mises à jour: $($result.UpdatedIssues)" -ForegroundColor Green
    } else {
        Write-Host "Échec de la synchronisation avec GitHub." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour synchroniser avec les projets GitHub
function Sync-WithGitHubProject {
    Clear-Host
    Write-Host "=== SYNCHRONISER AVEC GITHUB (PROJETS) ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Chemin de la roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Chemin de roadmap invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Token d'accès personnel GitHub: " -ForegroundColor Yellow -NoNewline
    $githubToken = Read-Host

    if ([string]::IsNullOrEmpty($githubToken)) {
        Write-Host "Token d'accès personnel GitHub invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Propriétaire du dépôt GitHub: " -ForegroundColor Yellow -NoNewline
    $owner = Read-Host

    if ([string]::IsNullOrEmpty($owner)) {
        Write-Host "Propriétaire du dépôt GitHub invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nom du dépôt GitHub: " -ForegroundColor Yellow -NoNewline
    $repo = Read-Host

    if ([string]::IsNullOrEmpty($repo)) {
        Write-Host "Nom du dépôt GitHub invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nom du projet GitHub (laisser vide pour utiliser le titre de la roadmap): " -ForegroundColor Yellow -NoNewline
    $projectName = Read-Host

    Write-Host "ID du projet GitHub existant (laisser vide pour créer un nouveau projet): " -ForegroundColor Yellow -NoNewline
    $projectIdInput = Read-Host

    $projectId = 0
    if (-not [string]::IsNullOrEmpty($projectIdInput)) {
        if (-not [int]::TryParse($projectIdInput, [ref]$projectId)) {
            Write-Host "ID du projet GitHub invalide." -ForegroundColor Red
            Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
            Read-Host
            return
        }
    }

    Write-Host "Créer des issues pour les tâches (o/n, défaut: o): " -ForegroundColor Yellow -NoNewline
    $createIssues = Read-Host
    $createIssuesSwitch = $createIssues -ne "n"

    # Se connecter à l'API GitHub
    Write-Host
    Write-Host "Connexion à l'API GitHub..." -ForegroundColor Cyan

    $connection = Connect-GitHubApi -Token $githubToken

    if ($null -eq $connection) {
        Write-Host "Échec de la connexion à l'API GitHub." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Synchroniser la roadmap avec un projet GitHub
    Write-Host "Synchronisation de la roadmap avec un projet GitHub..." -ForegroundColor Cyan

    $result = Sync-RoadmapToGitHubProject -Connection $connection -RoadmapPath $roadmapPath -Owner $owner -Repo $repo -ProjectName $projectName -ProjectId $projectId -CreateIssues:$createIssuesSwitch

    if ($null -ne $result) {
        Write-Host "Synchronisation réussie!" -ForegroundColor Green
        Write-Host "Dépôt GitHub: $($result.Repository)" -ForegroundColor Green
        Write-Host "Projet GitHub: $($result.Project.name) (ID: $($result.Project.id))" -ForegroundColor Green
        Write-Host "Issues créées: $($result.IssuesCreated)" -ForegroundColor Green
        Write-Host "Issues mises à jour: $($result.IssuesUpdated)" -ForegroundColor Green
        Write-Host "Cartes créées: $($result.CardsCreated)" -ForegroundColor Green
    } else {
        Write-Host "Échec de la synchronisation avec GitHub." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour synchroniser avec les pull requests GitHub
function Sync-WithGitHubPullRequests {
    Clear-Host
    Write-Host "=== SYNCHRONISER AVEC GITHUB (PULL REQUESTS) ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Chemin de la roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Chemin de roadmap invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Token d'accès personnel GitHub: " -ForegroundColor Yellow -NoNewline
    $githubToken = Read-Host

    if ([string]::IsNullOrEmpty($githubToken)) {
        Write-Host "Token d'accès personnel GitHub invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Propriétaire du dépôt GitHub: " -ForegroundColor Yellow -NoNewline
    $owner = Read-Host

    if ([string]::IsNullOrEmpty($owner)) {
        Write-Host "Propriétaire du dépôt GitHub invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Nom du dépôt GitHub: " -ForegroundColor Yellow -NoNewline
    $repo = Read-Host

    if ([string]::IsNullOrEmpty($repo)) {
        Write-Host "Nom du dépôt GitHub invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    Write-Host "Branche cible (défaut: main): " -ForegroundColor Yellow -NoNewline
    $baseBranch = Read-Host

    if ([string]::IsNullOrEmpty($baseBranch)) {
        $baseBranch = "main"
    }

    Write-Host "Préfixe des branches source (défaut: feature/): " -ForegroundColor Yellow -NoNewline
    $headBranchPrefix = Read-Host

    if ([string]::IsNullOrEmpty($headBranchPrefix)) {
        $headBranchPrefix = "feature/"
    }

    Write-Host "Créer des issues pour les tâches (o/n, défaut: o): " -ForegroundColor Yellow -NoNewline
    $createIssues = Read-Host
    $createIssuesSwitch = $createIssues -ne "n"

    # Se connecter à l'API GitHub
    Write-Host
    Write-Host "Connexion à l'API GitHub..." -ForegroundColor Cyan

    $connection = Connect-GitHubApi -Token $githubToken

    if ($null -eq $connection) {
        Write-Host "Échec de la connexion à l'API GitHub." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Synchroniser la roadmap avec les pull requests GitHub
    Write-Host "Synchronisation de la roadmap avec les pull requests GitHub..." -ForegroundColor Cyan

    $result = Sync-RoadmapToGitHubPullRequests -Connection $connection -RoadmapPath $roadmapPath -Owner $owner -Repo $repo -BaseBranch $baseBranch -HeadBranchPrefix $headBranchPrefix -CreateIssues:$createIssuesSwitch

    if ($null -ne $result) {
        Write-Host "Synchronisation réussie!" -ForegroundColor Green
        Write-Host "Dépôt GitHub: $($result.Repository)" -ForegroundColor Green
        Write-Host "Branche cible: $($result.BaseBranch)" -ForegroundColor Green
        Write-Host "Préfixe des branches source: $($result.HeadBranchPrefix)" -ForegroundColor Green
        Write-Host "Pull requests créées: $($result.PullRequestsCreated)" -ForegroundColor Green
        Write-Host "Pull requests liées: $($result.PullRequestsLinked)" -ForegroundColor Green
    } else {
        Write-Host "Échec de la synchronisation avec GitHub." -ForegroundColor Red
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour synchroniser avec tous les services
function Sync-WithAllServices {
    Clear-Host
    Write-Host "=== SYNCHRONISER AVEC TOUS LES SERVICES ===" -ForegroundColor Cyan
    Write-Host

    # Demander les paramètres
    Write-Host "Chemin de la roadmap: " -ForegroundColor Yellow -NoNewline
    $roadmapPath = Read-Host

    if ([string]::IsNullOrEmpty($roadmapPath) -or -not (Test-Path $roadmapPath)) {
        Write-Host "Chemin de roadmap invalide." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    # Charger la configuration
    $configPath = Join-Path -Path $scriptPath -ChildPath "config\services.json"

    if (-not (Test-Path $configPath)) {
        Write-Host "Fichier de configuration introuvable. Veuillez configurer les services d'abord." -ForegroundColor Red
        Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
        Read-Host
        return
    }

    $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

    # Synchroniser avec Notion
    if ($config.Notion.Enabled) {
        Write-Host
        Write-Host "Synchronisation avec Notion..." -ForegroundColor Cyan

        $connection = Connect-NotionApi -Token $config.Notion.Token

        if ($null -ne $connection) {
            $result = Sync-RoadmapToNotion -Connection $connection -RoadmapPath $roadmapPath -DatabaseId $config.Notion.DatabaseId -ParentPageId $config.Notion.ParentPageId

            if ($null -ne $result) {
                Write-Host "Synchronisation avec Notion réussie!" -ForegroundColor Green
                Write-Host "Base de données Notion: $($result.DatabaseId)" -ForegroundColor Green
                Write-Host "Titre: $($result.Title)" -ForegroundColor Green
                Write-Host "Nombre de tâches: $($result.TaskCount)" -ForegroundColor Green
            } else {
                Write-Host "Échec de la synchronisation avec Notion." -ForegroundColor Red
            }
        } else {
            Write-Host "Échec de la connexion à l'API Notion." -ForegroundColor Red
        }
    }

    # Synchroniser avec GitHub (Issues)
    if ($config.GitHub.Enabled) {
        Write-Host
        Write-Host "Synchronisation avec GitHub (Issues)..." -ForegroundColor Cyan

        $connection = Connect-GitHubApi -Token $config.GitHub.Token

        if ($null -ne $connection) {
            $result = Sync-RoadmapToGitHub -Connection $connection -RoadmapPath $roadmapPath -Owner $config.GitHub.Owner -Repo $config.GitHub.Repo -LabelPrefix $config.GitHub.LabelPrefix

            if ($null -ne $result) {
                Write-Host "Synchronisation avec GitHub (Issues) réussie!" -ForegroundColor Green
                Write-Host "Dépôt GitHub: $($result.Repository)" -ForegroundColor Green
                Write-Host "Titre: $($result.Title)" -ForegroundColor Green
                Write-Host "Nombre total d'issues: $($result.TotalIssues)" -ForegroundColor Green
                Write-Host "Issues créées: $($result.CreatedIssues)" -ForegroundColor Green
                Write-Host "Issues mises à jour: $($result.UpdatedIssues)" -ForegroundColor Green
            } else {
                Write-Host "Échec de la synchronisation avec GitHub (Issues)." -ForegroundColor Red
            }
        } else {
            Write-Host "Échec de la connexion à l'API GitHub." -ForegroundColor Red
        }
    }

    # Synchroniser avec GitHub (Projets)
    if ($config.GitHub.Enabled -and $config.GitHub.EnableProjects) {
        Write-Host
        Write-Host "Synchronisation avec GitHub (Projets)..." -ForegroundColor Cyan

        $connection = Connect-GitHubApi -Token $config.GitHub.Token

        if ($null -ne $connection) {
            $result = Sync-RoadmapToGitHubProject -Connection $connection -RoadmapPath $roadmapPath -Owner $config.GitHub.Owner -Repo $config.GitHub.Repo -ProjectName $config.GitHub.ProjectName -ProjectId $config.GitHub.ProjectId -CreateIssues:$config.GitHub.CreateIssues

            if ($null -ne $result) {
                Write-Host "Synchronisation avec GitHub (Projets) réussie!" -ForegroundColor Green
                Write-Host "Dépôt GitHub: $($result.Repository)" -ForegroundColor Green
                Write-Host "Projet GitHub: $($result.Project.name) (ID: $($result.Project.id))" -ForegroundColor Green
                Write-Host "Issues créées: $($result.IssuesCreated)" -ForegroundColor Green
                Write-Host "Issues mises à jour: $($result.IssuesUpdated)" -ForegroundColor Green
                Write-Host "Cartes créées: $($result.CardsCreated)" -ForegroundColor Green
            } else {
                Write-Host "Échec de la synchronisation avec GitHub (Projets)." -ForegroundColor Red
            }
        } else {
            Write-Host "Échec de la connexion à l'API GitHub." -ForegroundColor Red
        }
    }

    # Synchroniser avec GitHub (Pull Requests)
    if ($config.GitHub.Enabled -and $config.GitHub.EnablePullRequests) {
        Write-Host
        Write-Host "Synchronisation avec GitHub (Pull Requests)..." -ForegroundColor Cyan

        $connection = Connect-GitHubApi -Token $config.GitHub.Token

        if ($null -ne $connection) {
            $result = Sync-RoadmapToGitHubPullRequests -Connection $connection -RoadmapPath $roadmapPath -Owner $config.GitHub.Owner -Repo $config.GitHub.Repo -BaseBranch $config.GitHub.BaseBranch -HeadBranchPrefix $config.GitHub.HeadBranchPrefix -CreateIssues:$config.GitHub.CreateIssues

            if ($null -ne $result) {
                Write-Host "Synchronisation avec GitHub (Pull Requests) réussie!" -ForegroundColor Green
                Write-Host "Dépôt GitHub: $($result.Repository)" -ForegroundColor Green
                Write-Host "Branche cible: $($result.BaseBranch)" -ForegroundColor Green
                Write-Host "Préfixe des branches source: $($result.HeadBranchPrefix)" -ForegroundColor Green
                Write-Host "Pull requests créées: $($result.PullRequestsCreated)" -ForegroundColor Green
                Write-Host "Pull requests liées: $($result.PullRequestsLinked)" -ForegroundColor Green
            } else {
                Write-Host "Échec de la synchronisation avec GitHub (Pull Requests)." -ForegroundColor Red
            }
        } else {
            Write-Host "Échec de la connexion à l'API GitHub." -ForegroundColor Red
        }
    }

    Write-Host
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Fonction pour configurer les services
function Set-ServiceConfiguration {
    Clear-Host
    Write-Host "=== CONFIGURER LES SERVICES ===" -ForegroundColor Cyan
    Write-Host

    # Créer le dossier de configuration s'il n'existe pas
    $configDir = Join-Path -Path $scriptPath -ChildPath "config"

    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }

    $configPath = Join-Path -Path $configDir -ChildPath "services.json"

    # Charger la configuration existante si elle existe
    if (Test-Path $configPath) {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
    } else {
        $config = [PSCustomObject]@{
            Notion = [PSCustomObject]@{
                Enabled      = $false
                Token        = ""
                DatabaseId   = ""
                ParentPageId = ""
            }
            GitHub = [PSCustomObject]@{
                Enabled            = $false
                Token              = ""
                Owner              = ""
                Repo               = ""
                LabelPrefix        = "roadmap"
                EnableProjects     = $false
                ProjectName        = ""
                ProjectId          = 0
                EnablePullRequests = $false
                BaseBranch         = "main"
                HeadBranchPrefix   = "feature/"
                CreateIssues       = $true
            }
        }
    }

    # Configurer Notion
    Write-Host "Configuration de Notion:" -ForegroundColor Yellow
    Write-Host "  Activer Notion (o/n, défaut: $($config.Notion.Enabled ? 'o' : 'n')): " -ForegroundColor Yellow -NoNewline
    $notionEnabled = Read-Host

    if (-not [string]::IsNullOrEmpty($notionEnabled)) {
        $config.Notion.Enabled = $notionEnabled -eq "o"
    }

    if ($config.Notion.Enabled) {
        Write-Host "  Token d'intégration Notion (défaut: $($config.Notion.Token)): " -ForegroundColor Yellow -NoNewline
        $notionToken = Read-Host

        if (-not [string]::IsNullOrEmpty($notionToken)) {
            $config.Notion.Token = $notionToken
        }

        Write-Host "  ID de la base de données Notion (défaut: $($config.Notion.DatabaseId)): " -ForegroundColor Yellow -NoNewline
        $notionDatabaseId = Read-Host

        if (-not [string]::IsNullOrEmpty($notionDatabaseId)) {
            $config.Notion.DatabaseId = $notionDatabaseId
        }

        Write-Host "  ID de la page parent Notion (défaut: $($config.Notion.ParentPageId)): " -ForegroundColor Yellow -NoNewline
        $notionParentPageId = Read-Host

        if (-not [string]::IsNullOrEmpty($notionParentPageId)) {
            $config.Notion.ParentPageId = $notionParentPageId
        }
    }

    # Configurer GitHub
    Write-Host
    Write-Host "Configuration de GitHub:" -ForegroundColor Yellow
    Write-Host "  Activer GitHub (o/n, défaut: $($config.GitHub.Enabled ? 'o' : 'n')): " -ForegroundColor Yellow -NoNewline
    $githubEnabled = Read-Host

    if (-not [string]::IsNullOrEmpty($githubEnabled)) {
        $config.GitHub.Enabled = $githubEnabled -eq "o"
    }

    if ($config.GitHub.Enabled) {
        Write-Host "  Token d'accès personnel GitHub (défaut: $($config.GitHub.Token)): " -ForegroundColor Yellow -NoNewline
        $githubToken = Read-Host

        if (-not [string]::IsNullOrEmpty($githubToken)) {
            $config.GitHub.Token = $githubToken
        }

        Write-Host "  Propriétaire du dépôt GitHub (défaut: $($config.GitHub.Owner)): " -ForegroundColor Yellow -NoNewline
        $githubOwner = Read-Host

        if (-not [string]::IsNullOrEmpty($githubOwner)) {
            $config.GitHub.Owner = $githubOwner
        }

        Write-Host "  Nom du dépôt GitHub (défaut: $($config.GitHub.Repo)): " -ForegroundColor Yellow -NoNewline
        $githubRepo = Read-Host

        if (-not [string]::IsNullOrEmpty($githubRepo)) {
            $config.GitHub.Repo = $githubRepo
        }

        Write-Host "  Préfixe des labels (défaut: $($config.GitHub.LabelPrefix)): " -ForegroundColor Yellow -NoNewline
        $githubLabelPrefix = Read-Host

        if (-not [string]::IsNullOrEmpty($githubLabelPrefix)) {
            $config.GitHub.LabelPrefix = $githubLabelPrefix
        }

        Write-Host "  Activer les projets GitHub (o/n, défaut: $($config.GitHub.EnableProjects ? 'o' : 'n')): " -ForegroundColor Yellow -NoNewline
        $githubEnableProjects = Read-Host

        if (-not [string]::IsNullOrEmpty($githubEnableProjects)) {
            $config.GitHub.EnableProjects = $githubEnableProjects -eq "o"
        }

        if ($config.GitHub.EnableProjects) {
            Write-Host "  Nom du projet GitHub (défaut: $($config.GitHub.ProjectName)): " -ForegroundColor Yellow -NoNewline
            $githubProjectName = Read-Host

            if (-not [string]::IsNullOrEmpty($githubProjectName)) {
                $config.GitHub.ProjectName = $githubProjectName
            }

            Write-Host "  ID du projet GitHub existant (défaut: $($config.GitHub.ProjectId)): " -ForegroundColor Yellow -NoNewline
            $githubProjectIdInput = Read-Host

            if (-not [string]::IsNullOrEmpty($githubProjectIdInput)) {
                $projectId = 0
                if ([int]::TryParse($githubProjectIdInput, [ref]$projectId)) {
                    $config.GitHub.ProjectId = $projectId
                }
            }
        }

        Write-Host "  Activer les pull requests GitHub (o/n, défaut: $($config.GitHub.EnablePullRequests ? 'o' : 'n')): " -ForegroundColor Yellow -NoNewline
        $githubEnablePullRequests = Read-Host

        if (-not [string]::IsNullOrEmpty($githubEnablePullRequests)) {
            $config.GitHub.EnablePullRequests = $githubEnablePullRequests -eq "o"
        }

        if ($config.GitHub.EnablePullRequests) {
            Write-Host "  Branche cible (défaut: $($config.GitHub.BaseBranch)): " -ForegroundColor Yellow -NoNewline
            $githubBaseBranch = Read-Host

            if (-not [string]::IsNullOrEmpty($githubBaseBranch)) {
                $config.GitHub.BaseBranch = $githubBaseBranch
            }

            Write-Host "  Préfixe des branches source (défaut: $($config.GitHub.HeadBranchPrefix)): " -ForegroundColor Yellow -NoNewline
            $githubHeadBranchPrefix = Read-Host

            if (-not [string]::IsNullOrEmpty($githubHeadBranchPrefix)) {
                $config.GitHub.HeadBranchPrefix = $githubHeadBranchPrefix
            }
        }

        Write-Host "  Créer des issues pour les tâches (o/n, défaut: $($config.GitHub.CreateIssues ? 'o' : 'n')): " -ForegroundColor Yellow -NoNewline
        $githubCreateIssues = Read-Host

        if (-not [string]::IsNullOrEmpty($githubCreateIssues)) {
            $config.GitHub.CreateIssues = $githubCreateIssues -eq "o"
        }
    }

    # Sauvegarder la configuration
    $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $configPath -Encoding utf8

    Write-Host
    Write-Host "Configuration sauvegardée dans: $configPath" -ForegroundColor Green
    Write-Host "Appuyez sur une touche pour revenir au menu principal..." -ForegroundColor Yellow
    Read-Host
}

# Boucle principale
$exit = $false
while (-not $exit) {
    $choice = Show-MainMenu

    switch ($choice) {
        "1" { Sync-WithNotion }
        "2" { Sync-WithNotionBidirectional }
        "3" { Export-WithNotion }
        "4" { Import-WithNotion }
        "5" { New-WithNotionTemplate }
        "6" { Use-NotionTemplate }
        "7" { Get-WithNotionTemplates }
        "8" { Sync-WithGitHub }
        "9" { Sync-WithGitHubProject }
        "10" { Sync-WithGitHubPullRequests }
        "11" { Sync-WithAllServices }
        "12" { Set-ServiceConfiguration }
        "13" { $exit = $true }
        default {
            Write-Host "Choix invalide. Appuyez sur une touche pour continuer..." -ForegroundColor Red
            Read-Host
        }
    }
}

Write-Host "Au revoir!" -ForegroundColor Cyan
