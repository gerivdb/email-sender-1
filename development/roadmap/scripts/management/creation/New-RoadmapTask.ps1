<#
.SYNOPSIS
    CrÃƒÂ©e une nouvelle tÃƒÂ¢che dans la roadmap selon le template standard.

.DESCRIPTION
    Ce script gÃƒÂ©nÃƒÂ¨re une nouvelle tÃƒÂ¢che dans un fichier de roadmap au format Markdown
    en suivant le template standard. Il permet de spÃƒÂ©cifier les mÃƒÂ©tadonnÃƒÂ©es de la tÃƒÂ¢che
    et gÃƒÂ©nÃƒÂ¨re automatiquement la structure des sous-tÃƒÂ¢ches.

.PARAMETER MarkdownPath
    Chemin vers le fichier Markdown de la roadmap.

.PARAMETER SectionId
    Identifiant de la section principale (ex: 1, 2, 3).

.PARAMETER SubsectionId
    Identifiant de la sous-section (ex: 1, 2, 3).

.PARAMETER TaskName
    Nom de la tÃƒÂ¢che ÃƒÂ  crÃƒÂ©er.

.PARAMETER Complexity
    ComplexitÃƒÂ© de la tÃƒÂ¢che (Faible, Moyenne, Ãƒâ€°levÃƒÂ©e).

.PARAMETER EstimatedDays
    Nombre de jours estimÃƒÂ©s pour la tÃƒÂ¢che.

.PARAMETER StartDate
    Date de dÃƒÂ©but prÃƒÂ©vue (format: JJ/MM/AAAA).

.PARAMETER EndDate
    Date d'achÃƒÂ¨vement prÃƒÂ©vue (format: JJ/MM/AAAA).

.PARAMETER Responsible
    Personne ou ÃƒÂ©quipe responsable de la tÃƒÂ¢che.

.PARAMETER Tags
    Tags associÃƒÂ©s ÃƒÂ  la tÃƒÂ¢che (sÃƒÂ©parÃƒÂ©s par des virgules).

.PARAMETER FilesToCreate
    Liste des fichiers ÃƒÂ  crÃƒÂ©er (format: chemin|description).

.EXAMPLE
    .\New-RoadmapTask.ps1 -MarkdownPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md" -SectionId 1 -SubsectionId 2 -TaskName "ImplÃƒÂ©mentation du parser JSON" -Complexity "Moyenne" -EstimatedDays 3 -StartDate "15/06/2025" -EndDate "17/06/2025" -Responsible "Ãƒâ€°quipe Dev" -Tags "json,parser,optimisation" -FilesToCreate "src/parsers/json_parser.py|Parser JSON principal","development/testing/tests/parsers/test_json_parser.py|Tests unitaires du parser JSON"

.NOTES
    Auteur: Ãƒâ€°quipe DevOps
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
    [ValidateSet("Faible", "Moyenne", "Ãƒâ€°levÃƒÂ©e")]
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
        [ValidateSet("Faible", "Moyenne", "Ãƒâ€°levÃƒÂ©e")]
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

    # VÃƒÂ©rifier si le fichier de roadmap existe
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
        throw "La sous-section $SectionId.$SubsectionId n'a pas ÃƒÂ©tÃƒÂ© trouvÃƒÂ©e dans le fichier de roadmap."
    }

    # Trouver le prochain numÃƒÂ©ro de tÃƒÂ¢che
    $taskPattern = "#### $SectionId\.$SubsectionId\.(\d+) "
    $nextTaskNumber = 1

    for ($i = $subsectionIndex; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $taskPattern) {
            $taskNumber = [int]$matches[1]
            if ($taskNumber -ge $nextTaskNumber) {
                $nextTaskNumber = $taskNumber + 1
            }
        }
        
        # ArrÃƒÂªter la recherche si on atteint une autre sous-section
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

    # GÃƒÂ©nÃƒÂ©rer le contenu de la tÃƒÂ¢che
    $taskId = "$SectionId.$SubsectionId.$nextTaskNumber"
    $taskContent = @(
        "#### $taskId $TaskName",
        "**ComplexitÃƒÂ©**: $Complexity",
        "**Temps estimÃƒÂ©**: $EstimatedDays jours",
        "**Progression**: 0% - *Non commencÃƒÂ©*",
        "**Date de dÃƒÂ©but prÃƒÂ©vue**: $StartDate",
        "**Date d'achÃƒÂ¨vement prÃƒÂ©vue**: $EndDate",
        "**Responsable**: $Responsible"
    )

    if ($formattedTags) {
        $taskContent += "**Tags**: $formattedTags"
    }

    $taskContent += ""

    # Ajouter les fichiers ÃƒÂ  crÃƒÂ©er/modifier
    if ($FilesToCreate.Count -gt 0) {
        $taskContent += "##### Fichiers ÃƒÂ  crÃƒÂ©er/modifier"
        $taskContent += "| Chemin | Description | Statut |"
        $taskContent += "|--------|-------------|--------|"
        
        foreach ($fileInfo in $FilesToCreate) {
            $filePath, $fileDesc = $fileInfo -split '\|', 2
            $taskContent += "| `$filePath` | $fileDesc | Ãƒâ‚¬ crÃƒÂ©er |"
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
    $taskContent += '    {"feature": "FonctionnalitÃƒÂ© 1", "status": "Non commencÃƒÂ©"},'
    $taskContent += '    {"feature": "FonctionnalitÃƒÂ© 2", "status": "Non commencÃƒÂ©"}'
    $taskContent += '  ]'
    $taskContent += '}'
    $taskContent += '```'
    $taskContent += ""

    # GÃƒÂ©nÃƒÂ©rer les jours et sous-tÃƒÂ¢ches
    $hoursPerDay = 8
    for ($day = 1; $day -le $EstimatedDays; $day++) {
        $dayDesc = if ($day -eq 1) {
            "Analyse et conception"
        }
        elseif ($day -eq $EstimatedDays) {
            "Tests et validation"
        }
        else {
            "ImplÃƒÂ©mentation - Jour $day"
        }
        
        $taskContent += "##### Jour $day - $dayDesc (${hoursPerDay}h)"
        
        # GÃƒÂ©nÃƒÂ©rer des sous-tÃƒÂ¢ches pour chaque jour
        $subtasksPerDay = 4
        $hoursPerSubtask = $hoursPerDay / $subtasksPerDay
        
        for ($subtask = 1; $subtask -le $subtasksPerDay; $subtask++) {
            $subtaskDesc = if ($day -eq 1) {
                switch ($subtask) {
                    1 { "Analyser les besoins" }
                    2 { "Concevoir l'architecture" }
                    3 { "CrÃƒÂ©er les tests unitaires initiaux (TDD)" }
                    4 { "PrÃƒÂ©parer l'environnement de dÃƒÂ©veloppement" }
                }
            }
            elseif ($day -eq $EstimatedDays) {
                switch ($subtask) {
                    1 { "ExÃƒÂ©cuter les tests unitaires" }
                    2 { "Corriger les bugs identifiÃƒÂ©s" }
                    3 { "Optimiser les performances" }
                    4 { "Documenter le module" }
                }
            }
            else {
                "ImplÃƒÂ©menter la fonctionnalitÃƒÂ© $subtask"
            }
            
            $taskContent += "- [ ] **Sous-tÃƒÂ¢che $day.$subtask**: $subtaskDesc (${hoursPerSubtask}h)"
            $taskContent += "  - **Description**: [Description dÃƒÂ©taillÃƒÂ©e]"
            $taskContent += "  - **Livrable**: [Description du livrable]"
            $taskContent += "  - **Fichier**: `[chemin/vers/fichier]`"
            $taskContent += "  - **Outils**: [Outils utilisÃƒÂ©s]"
            $taskContent += "  - **Statut**: Non commencÃƒÂ©"
            $taskContent += ""
        }
    }

    # Trouver l'emplacement oÃƒÂ¹ insÃƒÂ©rer la tÃƒÂ¢che
    $insertIndex = -1
    $inSubsection = $false

    for ($i = $subsectionIndex + 1; $i -lt $content.Count; $i++) {
        # Si on trouve une autre sous-section ou section, insÃƒÂ©rer avant
        if ($content[$i] -match '^### ' || $content[$i] -match '^## ') {
            $insertIndex = $i
            break
        }
        
        # Si on trouve une tÃƒÂ¢che avec un numÃƒÂ©ro supÃƒÂ©rieur, insÃƒÂ©rer avant
        if ($content[$i] -match "#### $SectionId\.$SubsectionId\.(\d+) ") {
            $currentTaskNumber = [int]$matches[1]
            if ($currentTaskNumber -gt $nextTaskNumber) {
                $insertIndex = $i
                break
            }
        }
        
        # Garder trace de la derniÃƒÂ¨re tÃƒÂ¢che de la sous-section
        if ($content[$i] -match "#### $SectionId\.$SubsectionId\.") {
            $inSubsection = $true
            $lastTaskIndex = $i
        }
    }

    # Si on n'a pas trouvÃƒÂ© d'emplacement mais qu'on a trouvÃƒÂ© des tÃƒÂ¢ches dans la sous-section,
    # insÃƒÂ©rer aprÃƒÂ¨s la derniÃƒÂ¨re tÃƒÂ¢che
    if ($insertIndex -eq -1 && $inSubsection) {
        # Trouver la fin de la derniÃƒÂ¨re tÃƒÂ¢che
        for ($i = $lastTaskIndex + 1; $i -lt $content.Count; $i++) {
            if ($content[$i] -match '^#### ' || $content[$i] -match '^### ' || $content[$i] -match '^## ') {
                $insertIndex = $i
                break
            }
        }
        
        # Si on n'a toujours pas trouvÃƒÂ©, insÃƒÂ©rer ÃƒÂ  la fin du fichier
        if ($insertIndex -eq -1) {
            $insertIndex = $content.Count
        }
    }
    # Si on n'a pas trouvÃƒÂ© d'emplacement et qu'il n'y a pas de tÃƒÂ¢ches dans la sous-section,
    # insÃƒÂ©rer juste aprÃƒÂ¨s la sous-section
    elseif ($insertIndex -eq -1) {
        $insertIndex = $subsectionIndex + 1
        
        # Sauter les mÃƒÂ©tadonnÃƒÂ©es de la sous-section
        while ($insertIndex -lt $content.Count && 
               ($content[$insertIndex] -match '^\*\*' || [string]::IsNullOrWhiteSpace($content[$insertIndex]))) {
            $insertIndex++
        }
    }

    # InsÃƒÂ©rer la tÃƒÂ¢che
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
    
    Write-Host "TÃƒÂ¢che crÃƒÂ©ÃƒÂ©e avec succÃƒÂ¨s:"
    Write-Host "  ID: $($result.taskId)"
    Write-Host "  Nom: $($result.taskName)"
    Write-Host "  InsÃƒÂ©rÃƒÂ©e ÃƒÂ  la ligne: $($result.insertIndex)"
}
catch {
    Write-Error "Erreur lors de la crÃƒÂ©ation de la tÃƒÂ¢che: $_"
}
