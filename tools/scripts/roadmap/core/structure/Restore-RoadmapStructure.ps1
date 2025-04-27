#Requires -Version 5.1
<#
.SYNOPSIS
    Restaure la structure correcte du fichier roadmap aprÃ¨s l'archivage des tÃ¢ches.
.DESCRIPTION
    Ce script corrige la structure du fichier roadmap aprÃ¨s l'archivage des tÃ¢ches
    en s'assurant que les sections et sous-sections sont correctement prÃ©servÃ©es.
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

    # VÃ©rifier si le fichier de roadmap existe
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

        # DÃ©tecter les sections principales (## Titre)
        if ($line -match '^## (?!Archive)') {
            # Si on a dÃ©jÃ  une section en cours, l'ajouter Ã  la liste
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
        # DÃ©tecter les sections principales qui ne commencent pas par ## (cas spÃ©cial pour "6. Security")
        elseif ($line -match '^#### (\d+\.\d+\.\d+) ' -and $line -match '^#### 6\.') {
            # Si on a dÃ©jÃ  une section en cours, l'ajouter Ã  la liste
            if ($currentSection) {
                $sections += @{
                    title   = $currentSection
                    content = $currentSectionContent
                }
            }

            # Commencer une nouvelle section pour "6. Security"
            $currentSection = "## 6. Security"
            $currentSectionContent = @("## 6. Security", "**Description**: Modules de sÃ©curitÃ©, d'authentification et de protection des donnÃ©es.", "**Responsable**: Ã‰quipe SÃ©curitÃ©", "**Statut global**: PlanifiÃ© - 5%", "", "### 6.1 Gestion des secrets", "**ComplexitÃ©**: Ã‰levÃ©e", "**Temps estimÃ© total**: 10 jours", "**Progression globale**: 0%", "**DÃ©pendances**: Aucune", "", $line)
        }
        # Ajouter la ligne Ã  la section en cours
        elseif ($currentSection) {
            $currentSectionContent += $line
        }
    }

    # Ajouter la derniÃ¨re section si elle existe
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

    # Ajouter une seule section d'archive Ã  la fin
    $newContent += "## Archive"
    $newContent += "[TÃ¢ches archivÃ©es](archive/roadmap_archive.md)"

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
        Write-Host "Restauration de la structure du roadmap rÃ©ussie."
        Write-Host "$($result.sectionCount) sections principales identifiÃ©es et restaurÃ©es dans '$($result.roadmapPath)'."
    }
} catch {
    Write-Error "Erreur lors de la restauration de la structure du roadmap: $_"
}
