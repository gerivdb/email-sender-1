<#
.SYNOPSIS
    Décompose une tâche de roadmap en sous-tâches plus granulaires directement dans le document.

.DESCRIPTION
    Cette fonction prend une tâche de roadmap et la décompose en sous-tâches plus granulaires
    en insérant ces sous-tâches directement dans le document. Elle respecte le format existant
    du document, y compris l'indentation et les cases à cocher.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à modifier.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à décomposer (par exemple, "1.2.1.3.2.3").

.PARAMETER SubTasks
    Liste des sous-tâches à créer. Chaque sous-tâche doit être un objet avec les propriétés Title et Description.

.PARAMETER IndentationStyle
    Style d'indentation à utiliser. Par défaut, utilise le style détecté dans le document.
    Options : "Spaces2", "Spaces4", "Tab".

.PARAMETER CheckboxStyle
    Style de case à cocher à utiliser. Par défaut, utilise le style détecté dans le document.
    Options : "GitHub", "Custom".

.EXAMPLE
    $subTasks = @(
        @{ Title = "Analyser les besoins"; Description = "Identifier les exigences spécifiques" },
        @{ Title = "Concevoir la solution"; Description = "Créer une architecture adaptée" },
        @{ Title = "Implémenter le code"; Description = "Développer selon les spécifications" },
        @{ Title = "Tester la solution"; Description = "Vérifier le bon fonctionnement" }
    )
    Split-RoadmapTask -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -SubTasks $subTasks

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>
function Split-RoadmapTask {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$TaskIdentifier,

        [Parameter(Mandatory = $true)]
        [object[]]$SubTasks,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Spaces2", "Spaces4", "Tab", "Auto")]
        [string]$IndentationStyle = "Auto",

        [Parameter(Mandatory = $false)]
        [ValidateSet("GitHub", "Custom", "Auto")]
        [string]$CheckboxStyle = "Auto"
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier spécifié n'existe pas : $FilePath"
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8

    # Trouver la ligne contenant la tâche à décomposer
    $taskLineIndex = -1
    $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"

    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $taskLinePattern) {
            $taskLineIndex = $i
            break
        }
    }

    if ($taskLineIndex -eq -1) {
        throw "Tâche avec l'identifiant '$TaskIdentifier' non trouvée dans le fichier."
    }

    # Analyser la ligne de tâche pour déterminer l'indentation et le style de case à cocher
    $taskLine = $content[$taskLineIndex]

    # Déterminer l'indentation
    $indentation = ""
    if ($taskLine -match "^(\s+)") {
        $indentation = $matches[1]
    }

    # Déterminer le style d'indentation pour les sous-tâches
    $subTaskIndentation = ""
    if ($IndentationStyle -eq "Auto") {
        # Détecter automatiquement le style d'indentation utilisé dans le document
        if ($indentation -match "^\t+$") {
            $subTaskIndentation = $indentation + "`t"
        } elseif ($indentation -match "^( {2})+$") {
            $subTaskIndentation = $indentation + "  "
        } elseif ($indentation -match "^( {4})+$") {
            $subTaskIndentation = $indentation + "    "
        } else {
            # Par défaut, utiliser 2 espaces
            $subTaskIndentation = $indentation + "  "
        }
    } else {
        # Utiliser le style spécifié
        switch ($IndentationStyle) {
            "Spaces2" { $subTaskIndentation = $indentation + "  " }
            "Spaces4" { $subTaskIndentation = $indentation + "    " }
            "Tab" { $subTaskIndentation = $indentation + "`t" }
        }
    }

    # Déterminer le style de case à cocher
    $checkboxFormat = "- [ ] "
    if ($CheckboxStyle -eq "Auto") {
        # Détecter automatiquement le style de case à cocher utilisé dans le document
        if ($taskLine -match "-\s+\[\s*\]") {
            $checkboxFormat = "- [ ] "
        } elseif ($taskLine -match "-\s+\[\s*x\s*\]") {
            $checkboxFormat = "- [ ] "  # Utiliser le même format mais non coché
        } elseif ($taskLine -match "\*\s+\[\s*\]") {
            $checkboxFormat = "* [ ] "
        } else {
            # Par défaut, utiliser le format GitHub
            $checkboxFormat = "- [ ] "
        }
    } else {
        # Utiliser le style spécifié
        switch ($CheckboxStyle) {
            "GitHub" { $checkboxFormat = "- [ ] " }
            "Custom" { $checkboxFormat = "* [ ] " }
        }
    }

    # Déterminer le format de numérotation des sous-tâches
    $nextSubTaskNumber = 1
    $subTaskIdFormat = "$TaskIdentifier.$nextSubTaskNumber"

    # Créer les lignes de sous-tâches
    $subTaskLines = @()
    foreach ($subTask in $SubTasks) {
        $subTaskId = "$TaskIdentifier.$nextSubTaskNumber"
        $subTaskLine = "$subTaskIndentation$checkboxFormat**$subTaskId** $($subTask.Title)"
        $subTaskLines += $subTaskLine

        # Ajouter la description si elle existe
        if ($subTask.Description) {
            $descriptionLines = $subTask.Description -split "`n"
            foreach ($descLine in $descriptionLines) {
                $subTaskLines += "$subTaskIndentation  $descLine"
            }
        }

        $nextSubTaskNumber++
    }

    # Insérer les sous-tâches après la tâche principale
    $newContent = @()
    for ($i = 0; $i -lt $content.Count; $i++) {
        $newContent += $content[$i]

        if ($i -eq $taskLineIndex) {
            # Ajouter les sous-tâches après la tâche principale
            $newContent += $subTaskLines
        }
    }

    # Écrire le contenu modifié dans le fichier - ÉCRASE (OVERWRITE) le contenu existant
    if ($PSCmdlet.ShouldProcess($FilePath, "Modifier le fichier en ajoutant des sous-tâches")) {
        # Cette opération ÉCRASE (OVERWRITE) le contenu du fichier original
        # Le document est directement modifié, sans affichage intermédiaire
        $newContent | Set-Content -Path $FilePath -Encoding UTF8
        Write-Output "Tâche '$TaskIdentifier' décomposée avec succès en $($SubTasks.Count) sous-tâches."
        Write-Output "IMPORTANT: Le document '$FilePath' a été DIRECTEMENT MODIFIÉ (OVERWRITE)."
    }
}
