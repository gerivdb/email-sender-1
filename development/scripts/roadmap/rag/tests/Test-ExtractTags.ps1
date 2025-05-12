# Test-ExtractTags.ps1
# Script de test pour extraire les tags d'une roadmap
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "sample-roadmap.md",

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = "TagFormats.test.json"
)

# Importer les modules nécessaires
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$metadataDir = Join-Path -Path (Split-Path -Parent $scriptDir) -ChildPath "metadata"

# Importer les fonctions nécessaires
. (Join-Path -Path $metadataDir -ChildPath "Manage-TagFormats-Fixed.ps1")

# Fonction pour extraire les tâches du contenu
function Get-TasksFromContent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Content
    )

    $tasks = @()

    # Expression régulière pour extraire les tâches avec leur ID et leur texte
    $taskRegex = '- \[([ x])\] \*\*([^*]+)\*\* (.+?)(?=\n- \[|$)'

    $taskMatches = [regex]::Matches($Content, $taskRegex, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    foreach ($match in $taskMatches) {
        $status = $match.Groups[1].Value -eq 'x'
        $id = $match.Groups[2].Value.Trim()
        $text = $match.Groups[3].Value.Trim()

        $task = @{
            Id     = $id
            Text   = $text
            Status = $status
        }

        $tasks += $task
    }

    return $tasks
}

# Fonction pour extraire les tags d'une tâche
function Get-TagsFromTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Task,

        [Parameter(Mandatory = $true)]
        [PSObject]$Config
    )

    $tags = @()

    # Parcourir tous les types de tags dans la configuration
    Write-Host "  Texte de la tâche: $($Task.Text)" -ForegroundColor Gray

    foreach ($tagType in $Config.tag_formats.PSObject.Properties.Name) {
        $tagTypeConfig = $Config.tag_formats.$tagType
        Write-Host "  Vérification du type de tag: $tagType" -ForegroundColor Gray

        # Parcourir tous les formats pour ce type de tag
        foreach ($format in $tagTypeConfig.formats) {
            $pattern = $format.pattern
            Write-Host "    Vérification du pattern: $pattern" -ForegroundColor Gray

            # Rechercher les correspondances dans le texte de la tâche
            $tagMatches = [regex]::Matches($Task.Text, $pattern)
            Write-Host "    Nombre de correspondances: $($tagMatches.Count)" -ForegroundColor Gray

            foreach ($match in $tagMatches) {
                $value = $null

                # Extraire la valeur si un groupe de capture est spécifié
                if ($format.value_group -gt 0 -and $match.Groups.Count -gt $format.value_group) {
                    $value = $match.Groups[$format.value_group].Value
                }

                $tag = @{
                    Type      = $tagType
                    Name      = $format.name
                    Value     = $value
                    Unit      = $format.unit
                    FullMatch = $match.Value
                }

                $tags += $tag
            }
        }
    }

    return $tags
}

# Fonction principale
function Main {
    # Vérifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        Write-Host "Le fichier de roadmap n'existe pas: $RoadmapPath" -ForegroundColor Red
        return
    }

    # Vérifier si le fichier de configuration existe
    if (-not (Test-Path -Path $ConfigPath)) {
        Write-Host "Le fichier de configuration n'existe pas: $ConfigPath" -ForegroundColor Red
        return
    }

    # Créer une configuration directement dans le script
    $config = [PSCustomObject]@{
        name        = "Tag Formats Configuration"
        description = "Configuration des formats de tags pour les tests"
        version     = "1.0.0"
        updated_at  = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        tag_formats = [PSCustomObject]@{
            priority   = [PSCustomObject]@{
                name        = "priority"
                description = "Tags de priorité"
                formats     = @(
                    [PSCustomObject]@{
                        name        = "High"
                        pattern     = "#priority:high"
                        description = "Priorité haute"
                        example     = "#priority:high"
                        value_group = 0
                        unit        = ""
                    },
                    [PSCustomObject]@{
                        name        = "Medium"
                        pattern     = "#priority:medium"
                        description = "Priorité moyenne"
                        example     = "#priority:medium"
                        value_group = 0
                        unit        = ""
                    },
                    [PSCustomObject]@{
                        name        = "Low"
                        pattern     = "#priority:low"
                        description = "Priorité basse"
                        example     = "#priority:low"
                        value_group = 0
                        unit        = ""
                    }
                )
            }
            category   = [PSCustomObject]@{
                name        = "category"
                description = "Tags de catégorie"
                formats     = @(
                    [PSCustomObject]@{
                        name        = "Frontend"
                        pattern     = "#category:frontend"
                        description = "Catégorie frontend"
                        example     = "#category:frontend"
                        value_group = 0
                        unit        = ""
                    },
                    [PSCustomObject]@{
                        name        = "Backend"
                        pattern     = "#category:backend"
                        description = "Catégorie backend"
                        example     = "#category:backend"
                        value_group = 0
                        unit        = ""
                    },
                    [PSCustomObject]@{
                        name        = "Database"
                        pattern     = "#category:database"
                        description = "Catégorie base de données"
                        example     = "#category:database"
                        value_group = 0
                        unit        = ""
                    },
                    [PSCustomObject]@{
                        name        = "DevOps"
                        pattern     = "#category:devops"
                        description = "Catégorie DevOps"
                        example     = "#category:devops"
                        value_group = 0
                        unit        = ""
                    }
                )
            }
            time       = [PSCustomObject]@{
                name        = "time"
                description = "Tags de temps"
                formats     = @(
                    [PSCustomObject]@{
                        name        = "Hours"
                        pattern     = "#time:(\\d+)h"
                        description = "Temps en heures"
                        example     = "#time:3h"
                        value_group = 1
                        unit        = "h"
                    }
                )
            }
            dependency = [PSCustomObject]@{
                name        = "dependency"
                description = "Tags de dépendance"
                formats     = @(
                    [PSCustomObject]@{
                        name        = "Depends"
                        pattern     = "#depends:(\\d+\\.\\d+)"
                        description = "Dépend de la tâche spécifiée"
                        example     = "#depends:1.2"
                        value_group = 1
                        unit        = ""
                    }
                )
            }
        }
    }

    Write-Host "Configuration créée directement dans le script" -ForegroundColor Green

    if (-not $config) {
        Write-Host "Impossible de charger la configuration des formats de tags" -ForegroundColor Red
        return
    }

    # Afficher la configuration
    Write-Host "Configuration chargée:" -ForegroundColor Cyan
    Write-Host "  Nom: $($config.name)" -ForegroundColor Yellow
    Write-Host "  Description: $($config.description)" -ForegroundColor Yellow
    Write-Host "  Version: $($config.version)" -ForegroundColor Yellow

    # Vérifier si la propriété tag_formats existe
    if ($config.tag_formats) {
        Write-Host "  La propriété tag_formats existe" -ForegroundColor Green

        # Afficher les formats de tags disponibles
        Write-Host "Formats de tags disponibles:" -ForegroundColor Cyan
        $tagTypes = $config.tag_formats.PSObject.Properties.Name
        Write-Host "  Nombre de types de tags: $($tagTypes.Count)" -ForegroundColor Yellow

        foreach ($tagType in $tagTypes) {
            Write-Host "  Type de tag: $tagType" -ForegroundColor Yellow

            if ($config.tag_formats.$tagType.formats) {
                Write-Host "    Nombre de formats: $($config.tag_formats.$tagType.formats.Count)" -ForegroundColor Yellow

                foreach ($format in $config.tag_formats.$tagType.formats) {
                    Write-Host "    Format: $($format.name), Pattern: $($format.pattern)" -ForegroundColor Gray
                }
            } else {
                Write-Host "    Aucun format trouvé pour ce type de tag" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "  La propriété tag_formats n'existe pas" -ForegroundColor Red
        return
    }

    # Lire le contenu du fichier de roadmap
    $content = Get-Content -Path $RoadmapPath -Raw

    # Extraire les tâches du contenu
    $tasks = Get-TasksFromContent -Content $content

    Write-Host "Nombre de tâches trouvées: $($tasks.Count)" -ForegroundColor Cyan

    # Extraire les tags de chaque tâche
    $allTags = @()

    foreach ($task in $tasks) {
        $tags = Get-TagsFromTask -Task $task -Config $config

        Write-Host "Tâche $($task.Id): $($tags.Count) tags trouvés" -ForegroundColor Cyan

        foreach ($tag in $tags) {
            $allTags += $tag

            Write-Host "  - Type: $($tag.Type), Name: $($tag.Name), Value: $($tag.Value), Unit: $($tag.Unit)" -ForegroundColor Yellow
        }
    }

    Write-Host "Nombre total de tags trouvés: $($allTags.Count)" -ForegroundColor Green
}

# Exécuter la fonction principale
Main
