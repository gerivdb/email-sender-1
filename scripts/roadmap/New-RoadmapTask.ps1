<#
.SYNOPSIS
    Crée une nouvelle tâche dans la roadmap selon le template standard.

.DESCRIPTION
    Ce script génère une nouvelle tâche dans un fichier de roadmap au format Markdown
    en suivant le template standard. Il permet de spécifier les métadonnées de la tâche
    et génère automatiquement la structure des sous-tâches.

.PARAMETER MarkdownPath
    Chemin vers le fichier Markdown de la roadmap.

.PARAMETER SectionId
    Identifiant de la section principale (ex: 1, 2, 3).

.PARAMETER SubsectionId
    Identifiant de la sous-section (ex: 1, 2, 3).

.PARAMETER TaskName
    Nom de la tâche à créer.

.PARAMETER Complexity
    Complexité de la tâche (Faible, Moyenne, Élevée).

.PARAMETER EstimatedDays
    Nombre de jours estimés pour la tâche.

.PARAMETER StartDate
    Date de début prévue (format: JJ/MM/AAAA).

.PARAMETER EndDate
    Date d'achèvement prévue (format: JJ/MM/AAAA).

.PARAMETER Responsible
    Personne ou équipe responsable de la tâche.

.PARAMETER Tags
    Tags associés à la tâche (séparés par des virgules).

.PARAMETER FilesToCreate
    Liste des fichiers à créer (format: chemin|description).

.EXAMPLE
    .\New-RoadmapTask.ps1 -MarkdownPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md" -SectionId 1 -SubsectionId 2 -TaskName "Implémentation du parser JSON" -Complexity "Moyenne" -EstimatedDays 3 -StartDate "15/06/2025" -EndDate "17/06/2025" -Responsible "Équipe Dev" -Tags "json,parser,optimisation" -FilesToCreate "src/parsers/json_parser.py|Parser JSON principal","tests/parsers/test_json_parser.py|Tests unitaires du parser JSON"

.NOTES
    Auteur: Équipe DevOps
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
    [ValidateSet("Faible", "Moyenne", "Élevée")]
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
        [ValidateSet("Faible", "Moyenne", "Élevée")]
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

    # Vérifier si le fichier de roadmap existe
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
        throw "La sous-section $SectionId.$SubsectionId n'a pas été trouvée dans le fichier de roadmap."
    }

    # Trouver le prochain numéro de tâche
    $taskPattern = "#### $SectionId\.$SubsectionId\.(\d+) "
    $nextTaskNumber = 1

    for ($i = $subsectionIndex; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $taskPattern) {
            $taskNumber = [int]$matches[1]
            if ($taskNumber -ge $nextTaskNumber) {
                $nextTaskNumber = $taskNumber + 1
            }
        }
        
        # Arrêter la recherche si on atteint une autre sous-section
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

    # Générer le contenu de la tâche
    $taskId = "$SectionId.$SubsectionId.$nextTaskNumber"
    $taskContent = @(
        "#### $taskId $TaskName",
        "**Complexité**: $Complexity",
        "**Temps estimé**: $EstimatedDays jours",
        "**Progression**: 0% - *Non commencé*",
        "**Date de début prévue**: $StartDate",
        "**Date d'achèvement prévue**: $EndDate",
        "**Responsable**: $Responsible"
    )

    if ($formattedTags) {
        $taskContent += "**Tags**: $formattedTags"
    }

    $taskContent += ""

    # Ajouter les fichiers à créer/modifier
    if ($FilesToCreate.Count -gt 0) {
        $taskContent += "##### Fichiers à créer/modifier"
        $taskContent += "| Chemin | Description | Statut |"
        $taskContent += "|--------|-------------|--------|"
        
        foreach ($fileInfo in $FilesToCreate) {
            $filePath, $fileDesc = $fileInfo -split '\|', 2
            $taskContent += "| `$filePath` | $fileDesc | À créer |"
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
    $taskContent += '    {"feature": "Fonctionnalité 1", "status": "Non commencé"},'
    $taskContent += '    {"feature": "Fonctionnalité 2", "status": "Non commencé"}'
    $taskContent += '  ]'
    $taskContent += '}'
    $taskContent += '```'
    $taskContent += ""

    # Générer les jours et sous-tâches
    $hoursPerDay = 8
    for ($day = 1; $day -le $EstimatedDays; $day++) {
        $dayDesc = if ($day -eq 1) {
            "Analyse et conception"
        }
        elseif ($day -eq $EstimatedDays) {
            "Tests et validation"
        }
        else {
            "Implémentation - Jour $day"
        }
        
        $taskContent += "##### Jour $day - $dayDesc (${hoursPerDay}h)"
        
        # Générer des sous-tâches pour chaque jour
        $subtasksPerDay = 4
        $hoursPerSubtask = $hoursPerDay / $subtasksPerDay
        
        for ($subtask = 1; $subtask -le $subtasksPerDay; $subtask++) {
            $subtaskDesc = if ($day -eq 1) {
                switch ($subtask) {
                    1 { "Analyser les besoins" }
                    2 { "Concevoir l'architecture" }
                    3 { "Créer les tests unitaires initiaux (TDD)" }
                    4 { "Préparer l'environnement de développement" }
                }
            }
            elseif ($day -eq $EstimatedDays) {
                switch ($subtask) {
                    1 { "Exécuter les tests unitaires" }
                    2 { "Corriger les bugs identifiés" }
                    3 { "Optimiser les performances" }
                    4 { "Documenter le module" }
                }
            }
            else {
                "Implémenter la fonctionnalité $subtask"
            }
            
            $taskContent += "- [ ] **Sous-tâche $day.$subtask**: $subtaskDesc (${hoursPerSubtask}h)"
            $taskContent += "  - **Description**: [Description détaillée]"
            $taskContent += "  - **Livrable**: [Description du livrable]"
            $taskContent += "  - **Fichier**: `[chemin/vers/fichier]`"
            $taskContent += "  - **Outils**: [Outils utilisés]"
            $taskContent += "  - **Statut**: Non commencé"
            $taskContent += ""
        }
    }

    # Trouver l'emplacement où insérer la tâche
    $insertIndex = -1
    $inSubsection = $false

    for ($i = $subsectionIndex + 1; $i -lt $content.Count; $i++) {
        # Si on trouve une autre sous-section ou section, insérer avant
        if ($content[$i] -match '^### ' || $content[$i] -match '^## ') {
            $insertIndex = $i
            break
        }
        
        # Si on trouve une tâche avec un numéro supérieur, insérer avant
        if ($content[$i] -match "#### $SectionId\.$SubsectionId\.(\d+) ") {
            $currentTaskNumber = [int]$matches[1]
            if ($currentTaskNumber -gt $nextTaskNumber) {
                $insertIndex = $i
                break
            }
        }
        
        # Garder trace de la dernière tâche de la sous-section
        if ($content[$i] -match "#### $SectionId\.$SubsectionId\.") {
            $inSubsection = $true
            $lastTaskIndex = $i
        }
    }

    # Si on n'a pas trouvé d'emplacement mais qu'on a trouvé des tâches dans la sous-section,
    # insérer après la dernière tâche
    if ($insertIndex -eq -1 && $inSubsection) {
        # Trouver la fin de la dernière tâche
        for ($i = $lastTaskIndex + 1; $i -lt $content.Count; $i++) {
            if ($content[$i] -match '^#### ' || $content[$i] -match '^### ' || $content[$i] -match '^## ') {
                $insertIndex = $i
                break
            }
        }
        
        # Si on n'a toujours pas trouvé, insérer à la fin du fichier
        if ($insertIndex -eq -1) {
            $insertIndex = $content.Count
        }
    }
    # Si on n'a pas trouvé d'emplacement et qu'il n'y a pas de tâches dans la sous-section,
    # insérer juste après la sous-section
    elseif ($insertIndex -eq -1) {
        $insertIndex = $subsectionIndex + 1
        
        # Sauter les métadonnées de la sous-section
        while ($insertIndex -lt $content.Count && 
               ($content[$insertIndex] -match '^\*\*' || [string]::IsNullOrWhiteSpace($content[$insertIndex]))) {
            $insertIndex++
        }
    }

    # Insérer la tâche
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
    
    Write-Host "Tâche créée avec succès:"
    Write-Host "  ID: $($result.taskId)"
    Write-Host "  Nom: $($result.taskName)"
    Write-Host "  Insérée à la ligne: $($result.insertIndex)"
}
catch {
    Write-Error "Erreur lors de la création de la tâche: $_"
}
