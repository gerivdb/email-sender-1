#Requires -Version 5.1
<#
.SYNOPSIS
    Restaure la structure correcte du fichier roadmap après l'archivage des tâches.
.DESCRIPTION
    Ce script corrige la structure du fichier roadmap après l'archivage des tâches
    en s'assurant que les sections et sous-sections sont correctement préservées.
.PARAMETER RoadmapPath
    Chemin vers le fichier Markdown de la roadmap.
.EXAMPLE
    .\Restore-RoadmapStructure.ps1 -RoadmapPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"
.NOTES
    Auteur: EMAIL_SENDER_1 Team
    Date: 2023-07-04
    Version: 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$RoadmapPath
)

function Restore-RoadmapStructure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath
    )

    # Vérifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $RoadmapPath)) {
        throw "Le fichier de roadmap '$RoadmapPath' n'existe pas."
    }

    # Lire le contenu du fichier de roadmap
    $content = Get-Content -Path $RoadmapPath -Encoding UTF8

    # Structure pour stocker les sections et sous-sections
    $sections = @()
    $currentSection = $null
    $currentSectionContent = @()

    # Identifier les sections principales (## Titre)
    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]

        # Détecter les sections principales (## Titre)
        if ($line -match '^## (?!Archive)') {
            # Si on a déjà une section en cours, l'ajouter à la liste
            if ($currentSection) {
                $sections += @{
                    title   = $currentSection
                    content = $currentSectionContent
                }
            }

            # Commencer une nouvelle section
            $currentSection = $line
            $currentSectionContent = @($line)
        }
        # Ignorer les sections d'archive
        elseif ($line -match '^## Archive') {
            # Ne rien faire, ignorer cette section
        }
        # Détecter les sections principales qui ne commencent pas par ## (cas spécial pour "6. Security")
        elseif ($line -match '^#### (\d+\.\d+\.\d+) ' -and $line -match '^#### 6\.') {
            # Si on a déjà une section en cours, l'ajouter à la liste
            if ($currentSection) {
                $sections += @{
                    title   = $currentSection
                    content = $currentSectionContent
                }
            }

            # Commencer une nouvelle section pour "6. Security"
            $currentSection = "## 6. Security"
            $currentSectionContent = @("## 6. Security", "**Description**: Modules de sécurité, d'authentification et de protection des données.", "**Responsable**: Équipe Sécurité", "**Statut global**: Planifié - 5%", "", "### 6.1 Gestion des secrets", "**Complexité**: Élevée", "**Temps estimé total**: 10 jours", "**Progression globale**: 0%", "**Dépendances**: Aucune", "", $line)
        }
        # Ajouter la ligne à la section en cours
        elseif ($currentSection) {
            $currentSectionContent += $line
        }
    }

    # Ajouter la dernière section si elle existe
    if ($currentSection) {
        $sections += @{
            title   = $currentSection
            content = $currentSectionContent
        }
    }

    # Reconstruire le contenu du fichier
    $newContent = @()

    # Ajouter chaque section
    foreach ($section in $sections) {
        $newContent += $section.content
        $newContent += ""
    }

    # Ajouter une seule section d'archive à la fin
    $newContent += "## Archive"
    $newContent += "[Tâches archivées](archive/roadmap_archive.md)"

    # Enregistrer les modifications
    $newContent | Out-File -FilePath $RoadmapPath -Encoding UTF8

    return @{
        sectionCount = $sections.Count
        roadmapPath  = $RoadmapPath
    }
}

# Fonction principale
try {
    $result = Restore-RoadmapStructure -RoadmapPath $RoadmapPath

    if ($result) {
        Write-Host "Restauration de la structure du roadmap réussie."
        Write-Host "$($result.sectionCount) sections principales identifiées et restaurées dans '$($result.roadmapPath)'."
    }
} catch {
    Write-Error "Erreur lors de la restauration de la structure du roadmap: $_"
}
