<#
.SYNOPSIS
    Exporte une roadmap au format Markdown vers un fichier JSON.

.DESCRIPTION
    Ce script analyse un fichier de roadmap au format Markdown et le convertit en JSON
    pour faciliter le parsing automatique et l'intégration avec d'autres outils.

.PARAMETER MarkdownPath
    Chemin vers le fichier Markdown de la roadmap.

.PARAMETER JsonPath
    Chemin où le fichier JSON sera enregistré. Si non spécifié, le fichier sera enregistré
    au même emplacement que le fichier Markdown avec l'extension .json.

.EXAMPLE
    .\Export-RoadmapToJSON.ps1 -MarkdownPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"

.NOTES
    Auteur: Équipe DevOps
    Date: 2025-04-20
    Version: 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$MarkdownPath,

    [Parameter(Mandatory = $false)]
    [string]$JsonPath = $null
)

function ConvertFrom-Markdown {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MarkdownPath
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $MarkdownPath)) {
        throw "Le fichier '$MarkdownPath' n'existe pas."
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $MarkdownPath -Raw -Encoding UTF8

    # Extraire le nom du projet (titre de niveau 1)
    $projectNameMatch = [regex]::Match($content, '# (.+)')
    $projectName = if ($projectNameMatch.Success) { $projectNameMatch.Groups[1].Value } else { "Projet inconnu" }

    # Structure de base pour le JSON
    $roadmapJson = @{
        project      = $projectName
        version      = "1.0.0"
        last_updated = (Get-Date).ToString("yyyy-MM-dd")
        sections     = @()
    }

    # Analyser les sections principales (niveau 2)
    $sectionMatches = [regex]::Matches($content, '## (\d+)\. (.+?)(?=\r?\n\r?\n|\z)')

    foreach ($sectionMatch in $sectionMatches) {
        $sectionId = $sectionMatch.Groups[1].Value
        $sectionName = $sectionMatch.Groups[2].Value

        $section = @{
            id          = $sectionId
            name        = $sectionName
            description = ""
            responsible = ""
            status      = "Non commencé"
            progress    = 0
            subsections = @()
        }

        # Analyser les sous-sections (niveau 3)
        $subsectionPattern = "### $sectionId\.(\d+) (.+?)(?=\r?\n\r?\n|\z)"
        $subsectionMatches = [regex]::Matches($content, $subsectionPattern)

        foreach ($subsectionMatch in $subsectionMatches) {
            $subsectionId = "$sectionId." + $subsectionMatch.Groups[1].Value
            $subsectionName = $subsectionMatch.Groups[2].Value

            $subsection = @{
                id             = $subsectionId
                name           = $subsectionName
                complexity     = "Moyenne"
                estimated_days = 0
                progress       = 0
                dependencies   = "Aucune"
                tools          = @{}
                files          = @()
                guidelines     = @{}
                tasks          = @()
            }

            # Analyser les tâches (niveau 4)
            $taskPattern = "#### $subsectionId\.(\d+) (.+?)(?=\r?\n)"
            $taskMatches = [regex]::Matches($content, $taskPattern)

            foreach ($taskMatch in $taskMatches) {
                $taskId = "$subsectionId." + $taskMatch.Groups[1].Value
                $taskName = $taskMatch.Groups[2].Value

                $task = @{
                    id              = $taskId
                    name            = $taskName
                    complexity      = "Moyenne"
                    estimated_days  = 0
                    progress        = 0
                    status          = "Non commencé"
                    start_date      = ""
                    end_date        = ""
                    responsible     = ""
                    tags            = @()
                    files_to_create = @()
                    subtasks        = @()
                }

                $subsection.tasks += $task
            }

            $section.subsections += $subsection
        }

        $roadmapJson.sections += $section
    }

    return $roadmapJson
}

# Fonction principale
try {
    # Déterminer le chemin de sortie JSON
    if (-not $JsonPath) {
        $JsonPath = [System.IO.Path]::ChangeExtension($MarkdownPath, "json")
    }

    # Convertir le Markdown en JSON
    $roadmapJson = ConvertFrom-Markdown -MarkdownPath $MarkdownPath

    # Convertir en JSON et enregistrer
    $jsonContent = $roadmapJson | ConvertTo-Json -Depth 10
    $jsonContent | Out-File -FilePath $JsonPath -Encoding UTF8

    Write-Host "Roadmap exportée avec succès vers '$JsonPath'"
} catch {
    Write-Error "Erreur lors de l'exportation de la roadmap: $_"
}
