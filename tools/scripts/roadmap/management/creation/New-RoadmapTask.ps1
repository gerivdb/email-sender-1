<#
.SYNOPSIS
    CrÃ©e une nouvelle tÃ¢che dans la roadmap selon le template standard.

.DESCRIPTION
    Ce script gÃ©nÃ¨re une nouvelle tÃ¢che dans un fichier de roadmap au format Markdown
    en suivant le template standard. Il permet de spÃ©cifier les mÃ©tadonnÃ©es de la tÃ¢che
    et gÃ©nÃ¨re automatiquement la structure des sous-tÃ¢ches.

.PARAMETER MarkdownPath
    Chemin vers le fichier Markdown de la roadmap.

.PARAMETER SectionId
    Identifiant de la section principale (ex: 1, 2, 3).

.PARAMETER SubsectionId
    Identifiant de la sous-section (ex: 1, 2, 3).

.PARAMETER TaskName
    Nom de la tÃ¢che Ã  crÃ©er.

.PARAMETER Complexity
    ComplexitÃ© de la tÃ¢che (Faible, Moyenne, Ã‰levÃ©e).

.PARAMETER EstimatedDays
    Nombre de jours estimÃ©s pour la tÃ¢che.

.PARAMETER StartDate
    Date de dÃ©but prÃ©vue (format: JJ/MM/AAAA).

.PARAMETER EndDate
    Date d'achÃ¨vement prÃ©vue (format: JJ/MM/AAAA).

.PARAMETER Responsible
    Personne ou Ã©quipe responsable de la tÃ¢che.

.PARAMETER Tags
    Tags associÃ©s Ã  la tÃ¢che (sÃ©parÃ©s par des virgules).

.PARAMETER FilesToCreate
    Liste des fichiers Ã  crÃ©er (format: chemin|description).

.EXAMPLE
    .\New-RoadmapTask.ps1 -MarkdownPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md" -SectionId 1 -SubsectionId 2 -TaskName "ImplÃ©mentation du parser JSON" -Complexity "Moyenne" -EstimatedDays 3 -StartDate "15/06/2025" -EndDate "17/06/2025" -Responsible "Ã‰quipe Dev" -Tags "json,parser,optimisation" -FilesToCreate "src/parsers/json_parser.py|Parser JSON principal","tests/parsers/test_json_parser.py|Tests unitaires du parser JSON"

.NOTES
    Auteur: Ã‰quipe DevOps
    Date: 2025-04-20
    Version: 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$MarkdownPath,

    [Parameter(Mandatory = $true)]
    [int]$SectionId,

    [Parameter(Mandatory = $true)]
    [int]$SubsectionId,

    [Parameter(Mandatory = $true)]
    [string]$TaskName,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Faible", "Moyenne", "Ã‰levÃ©e")]
    [string]$Complexity = "Moyenne",

    [Parameter(Mandatory = $true)]
    [int]$EstimatedDays,

    [Parameter(Mandatory = $true)]
    [string]$StartDate,

    [Parameter(Mandatory = $true)]
    [string]$EndDate,

    [Parameter(Mandatory = $true)]
    [string]$Responsible,

    [Parameter(Mandatory = $false)]
    [string]$Tags = "",

    [Parameter(Mandatory = $false)]
    [string[]]$FilesToCreate = @()
)

function New-RoadmapTask {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MarkdownPath,

        [Parameter(Mandatory = $true)]
        [int]$SectionId,

        [Parameter(Mandatory = $true)]
        [int]$SubsectionId,

        [Parameter(Mandatory = $true)]
        [string]$TaskName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Faible", "Moyenne", "Ã‰levÃ©e")]
        [string]$Complexity = "Moyenne",

        [Parameter(Mandatory = $true)]
        [int]$EstimatedDays,

        [Parameter(Mandatory = $true)]
        [string]$StartDate,

        [Parameter(Mandatory = $true)]
        [string]$EndDate,

        [Parameter(Mandatory = $true)]
        [string]$Responsible,

        [Parameter(Mandatory = $false)]
        [string]$Tags = "",

        [Parameter(Mandatory = $false)]
        [string[]]$FilesToCreate = @()
    )

    # VÃ©rifier si le fichier de roadmap existe
    if (-not (Test-Path -Path $MarkdownPath)) {
        throw "Le fichier de roadmap '$MarkdownPath' n'existe pas."
    }

    # Lire le contenu du fichier de roadmap
    $content = Get-Content -Path $MarkdownPath -Encoding UTF8

    # Trouver la sous-section
    $subsectionFound = $false
    $subsectionPattern = "### $SectionId\.$SubsectionId "
    $subsectionIndex = -1

    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $subsectionPattern) {
            $subsectionFound = $true
            $subsectionIndex = $i
            break
        }
    }

    if (-not $subsectionFound) {
        throw "La sous-section $SectionId.$SubsectionId n'a pas Ã©tÃ© trouvÃ©e dans le fichier de roadmap."
    }

    # Trouver le prochain numÃ©ro de tÃ¢che
    $taskPattern = "#### $SectionId\.$SubsectionId\.(\d+) "
    $nextTaskNumber = 1

    for ($i = $subsectionIndex; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $taskPattern) {
            $taskNumber = [int]$matches[1]
            if ($taskNumber -ge $nextTaskNumber) {
                $nextTaskNumber = $taskNumber + 1
            }
        }
        
        # ArrÃªter la recherche si on atteint une autre sous-section
        if ($i -gt $subsectionIndex && $content[$i] -match '^### ') {
            break
        }
    }

    # Formater les tags
    $formattedTags = if ($Tags) {
        "#" + ($Tags -split ',' -join ' #')
    }
    else {
        ""
    }

    # GÃ©nÃ©rer le contenu de la tÃ¢che
    $taskId = "$SectionId.$SubsectionId.$nextTaskNumber"
    $taskContent = @(
        "#### $taskId $TaskName",
        "**ComplexitÃ©**: $Complexity",
        "**Temps estimÃ©**: $EstimatedDays jours",
        "**Progression**: 0% - *Non commencÃ©*",
        "**Date de dÃ©but prÃ©vue**: $StartDate",
        "**Date d'achÃ¨vement prÃ©vue**: $EndDate",
        "**Responsable**: $Responsible"
    )

    if ($formattedTags) {
        $taskContent += "**Tags**: $formattedTags"
    }

    $taskContent += ""

    # Ajouter les fichiers Ã  crÃ©er/modifier
    if ($FilesToCreate.Count -gt 0) {
        $taskContent += "##### Fichiers Ã  crÃ©er/modifier"
        $taskContent += "| Chemin | Description | Statut |"
        $taskContent += "|--------|-------------|--------|"
        
        foreach ($fileInfo in $FilesToCreate) {
            $filePath, $fileDesc = $fileInfo -split '\|', 2
            $taskContent += "| `$filePath` | $fileDesc | Ã€ crÃ©er |"
        }
        
        $taskContent += ""
    }

    # Ajouter le format de journalisation
    $taskContent += "##### Format de journalisation"
    $taskContent += '```json'
    $taskContent += '{' 
    $taskContent += '  "module": "' + $TaskName.Replace(' ', '') + '",'
    $taskContent += '  "version": "1.0.0",'
    $taskContent += '  "date": "' + ([DateTime]::ParseExact($EndDate, "dd/MM/yyyy", $null).ToString("yyyy-MM-dd")) + '",'
    $taskContent += '  "changes": ['
    $taskContent += '    {"feature": "FonctionnalitÃ© 1", "status": "Non commencÃ©"},'
    $taskContent += '    {"feature": "FonctionnalitÃ© 2", "status": "Non commencÃ©"}'
    $taskContent += '  ]'
    $taskContent += '}'
    $taskContent += '```'
    $taskContent += ""

    # GÃ©nÃ©rer les jours et sous-tÃ¢ches
    $hoursPerDay = 8
    for ($day = 1; $day -le $EstimatedDays; $day++) {
        $dayDesc = if ($day -eq 1) {
            "Analyse et conception"
        }
        elseif ($day -eq $EstimatedDays) {
            "Tests et validation"
        }
        else {
            "ImplÃ©mentation - Jour $day"
        }
        
        $taskContent += "##### Jour $day - $dayDesc (${hoursPerDay}h)"
        
        # GÃ©nÃ©rer des sous-tÃ¢ches pour chaque jour
        $subtasksPerDay = 4
        $hoursPerSubtask = $hoursPerDay / $subtasksPerDay
        
        for ($subtask = 1; $subtask -le $subtasksPerDay; $subtask++) {
            $subtaskDesc = if ($day -eq 1) {
                switch ($subtask) {
                    1 { "Analyser les besoins" }
                    2 { "Concevoir l'architecture" }
                    3 { "CrÃ©er les tests unitaires initiaux (TDD)" }
                    4 { "PrÃ©parer l'environnement de dÃ©veloppement" }
                }
            }
            elseif ($day -eq $EstimatedDays) {
                switch ($subtask) {
                    1 { "ExÃ©cuter les tests unitaires" }
                    2 { "Corriger les bugs identifiÃ©s" }
                    3 { "Optimiser les performances" }
                    4 { "Documenter le module" }
                }
            }
            else {
                "ImplÃ©menter la fonctionnalitÃ© $subtask"
            }
            
            $taskContent += "- [ ] **Sous-tÃ¢che $day.$subtask**: $subtaskDesc (${hoursPerSubtask}h)"
            $taskContent += "  - **Description**: [Description dÃ©taillÃ©e]"
            $taskContent += "  - **Livrable**: [Description du livrable]"
            $taskContent += "  - **Fichier**: `[chemin/vers/fichier]`"
            $taskContent += "  - **Outils**: [Outils utilisÃ©s]"
            $taskContent += "  - **Statut**: Non commencÃ©"
            $taskContent += ""
        }
    }

    # Trouver l'emplacement oÃ¹ insÃ©rer la tÃ¢che
    $insertIndex = -1
    $inSubsection = $false

    for ($i = $subsectionIndex + 1; $i -lt $content.Count; $i++) {
        # Si on trouve une autre sous-section ou section, insÃ©rer avant
        if ($content[$i] -match '^### ' || $content[$i] -match '^## ') {
            $insertIndex = $i
            break
        }
        
        # Si on trouve une tÃ¢che avec un numÃ©ro supÃ©rieur, insÃ©rer avant
        if ($content[$i] -match "#### $SectionId\.$SubsectionId\.(\d+) ") {
            $currentTaskNumber = [int]$matches[1]
            if ($currentTaskNumber -gt $nextTaskNumber) {
                $insertIndex = $i
                break
            }
        }
        
        # Garder trace de la derniÃ¨re tÃ¢che de la sous-section
        if ($content[$i] -match "#### $SectionId\.$SubsectionId\.") {
            $inSubsection = $true
            $lastTaskIndex = $i
        }
    }

    # Si on n'a pas trouvÃ© d'emplacement mais qu'on a trouvÃ© des tÃ¢ches dans la sous-section,
    # insÃ©rer aprÃ¨s la derniÃ¨re tÃ¢che
    if ($insertIndex -eq -1 && $inSubsection) {
        # Trouver la fin de la derniÃ¨re tÃ¢che
        for ($i = $lastTaskIndex + 1; $i -lt $content.Count; $i++) {
            if ($content[$i] -match '^#### ' || $content[$i] -match '^### ' || $content[$i] -match '^## ') {
                $insertIndex = $i
                break
            }
        }
        
        # Si on n'a toujours pas trouvÃ©, insÃ©rer Ã  la fin du fichier
        if ($insertIndex -eq -1) {
            $insertIndex = $content.Count
        }
    }
    # Si on n'a pas trouvÃ© d'emplacement et qu'il n'y a pas de tÃ¢ches dans la sous-section,
    # insÃ©rer juste aprÃ¨s la sous-section
    elseif ($insertIndex -eq -1) {
        $insertIndex = $subsectionIndex + 1
        
        # Sauter les mÃ©tadonnÃ©es de la sous-section
        while ($insertIndex -lt $content.Count && 
               ($content[$insertIndex] -match '^\*\*' || [string]::IsNullOrWhiteSpace($content[$insertIndex]))) {
            $insertIndex++
        }
    }

    # InsÃ©rer la tÃ¢che
    $newContent = $content[0..($insertIndex - 1)]
    $newContent += $taskContent
    $newContent += $content[$insertIndex..($content.Count - 1)]

    # Enregistrer les modifications
    $newContent | Out-File -FilePath $MarkdownPath -Encoding UTF8
    
    return @{
        taskId = $taskId
        taskName = $TaskName
        insertIndex = $insertIndex
    }
}

# Fonction principale
try {
    $result = New-RoadmapTask -MarkdownPath $MarkdownPath -SectionId $SectionId -SubsectionId $SubsectionId `
                             -TaskName $TaskName -Complexity $Complexity -EstimatedDays $EstimatedDays `
                             -StartDate $StartDate -EndDate $EndDate -Responsible $Responsible `
                             -Tags $Tags -FilesToCreate $FilesToCreate
    
    Write-Host "TÃ¢che crÃ©Ã©e avec succÃ¨s:"
    Write-Host "  ID: $($result.taskId)"
    Write-Host "  Nom: $($result.taskName)"
    Write-Host "  InsÃ©rÃ©e Ã  la ligne: $($result.insertIndex)"
}
catch {
    Write-Error "Erreur lors de la crÃ©ation de la tÃ¢che: $_"
}
