<#
.SYNOPSIS
    DÃ©compose une tÃ¢che de roadmap en sous-tÃ¢ches plus granulaires directement dans le document.

.DESCRIPTION
    Cette fonction prend une tÃ¢che de roadmap et la dÃ©compose en sous-tÃ¢ches plus granulaires
    en insÃ©rant ces sous-tÃ¢ches directement dans le document. Elle respecte le format existant
    du document, y compris l'indentation et les cases Ã  cocher.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  modifier.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  dÃ©composer (par exemple, "1.2.1.3.2.3").

.PARAMETER SubTasks
    Liste des sous-tÃ¢ches Ã  crÃ©er. Chaque sous-tÃ¢che doit Ãªtre un objet avec les propriÃ©tÃ©s Title et Description.

.PARAMETER IndentationStyle
    Style d'indentation Ã  utiliser. Par dÃ©faut, utilise le style dÃ©tectÃ© dans le document.
    Options : "Spaces2", "Spaces4", "Tab".

.PARAMETER CheckboxStyle
    Style de case Ã  cocher Ã  utiliser. Par dÃ©faut, utilise le style dÃ©tectÃ© dans le document.
    Options : "GitHub", "Custom".

.EXAMPLE
    $subTasks = @(
        @{ Title = "Analyser les besoins"; Description = "Identifier les exigences spÃ©cifiques" },
        @{ Title = "Concevoir la solution"; Description = "CrÃ©er une architecture adaptÃ©e" },
        @{ Title = "ImplÃ©menter le code"; Description = "DÃ©velopper selon les spÃ©cifications" },
        @{ Title = "Tester la solution"; Description = "VÃ©rifier le bon fonctionnement" }
    )
    Split-RoadmapTask -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -SubTasks $subTasks

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
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

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8

    # Trouver la ligne contenant la tÃ¢che Ã  dÃ©composer
    $taskLineIndex = -1
    $taskLinePattern = ".*\b$([regex]::Escape($TaskIdentifier))\b.*"

    for ($i = 0; $i -lt $content.Count; $i++) {
        if ($content[$i] -match $taskLinePattern) {
            $taskLineIndex = $i
            break
        }
    }

    if ($taskLineIndex -eq -1) {
        throw "TÃ¢che avec l'identifiant '$TaskIdentifier' non trouvÃ©e dans le fichier."
    }

    # Analyser la ligne de tÃ¢che pour dÃ©terminer l'indentation et le style de case Ã  cocher
    $taskLine = $content[$taskLineIndex]

    # DÃ©terminer l'indentation
    $indentation = ""
    if ($taskLine -match "^(\s+)") {
        $indentation = $matches[1]
    }

    # DÃ©terminer le style d'indentation pour les sous-tÃ¢ches
    $subTaskIndentation = ""
    if ($IndentationStyle -eq "Auto") {
        # DÃ©tecter automatiquement le style d'indentation utilisÃ© dans le document
        if ($indentation -match "^\t+$") {
            $subTaskIndentation = $indentation + "`t"
        } elseif ($indentation -match "^( {2})+$") {
            $subTaskIndentation = $indentation + "  "
        } elseif ($indentation -match "^( {4})+$") {
            $subTaskIndentation = $indentation + "    "
        } else {
            # Par dÃ©faut, utiliser 2 espaces
            $subTaskIndentation = $indentation + "  "
        }
    } else {
        # Utiliser le style spÃ©cifiÃ©
        switch ($IndentationStyle) {
            "Spaces2" { $subTaskIndentation = $indentation + "  " }
            "Spaces4" { $subTaskIndentation = $indentation + "    " }
            "Tab" { $subTaskIndentation = $indentation + "`t" }
        }
    }

    # DÃ©terminer le style de case Ã  cocher
    $checkboxFormat = "- [ ] "
    if ($CheckboxStyle -eq "Auto") {
        # DÃ©tecter automatiquement le style de case Ã  cocher utilisÃ© dans le document
        if ($taskLine -match "-\s+\[\s*\]") {
            $checkboxFormat = "- [ ] "
        } elseif ($taskLine -match "-\s+\[\s*x\s*\]") {
            $checkboxFormat = "- [ ] "  # Utiliser le mÃªme format mais non cochÃ©
        } elseif ($taskLine -match "\*\s+\[\s*\]") {
            $checkboxFormat = "* [ ] "
        } else {
            # Par dÃ©faut, utiliser le format GitHub
            $checkboxFormat = "- [ ] "
        }
    } else {
        # Utiliser le style spÃ©cifiÃ©
        switch ($CheckboxStyle) {
            "GitHub" { $checkboxFormat = "- [ ] " }
            "Custom" { $checkboxFormat = "* [ ] " }
        }
    }

    # DÃ©terminer le format de numÃ©rotation des sous-tÃ¢ches
    $nextSubTaskNumber = 1
    $subTaskIdFormat = "$TaskIdentifier.$nextSubTaskNumber"

    # CrÃ©er les lignes de sous-tÃ¢ches
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

    # InsÃ©rer les sous-tÃ¢ches aprÃ¨s la tÃ¢che principale
    $newContent = @()
    for ($i = 0; $i -lt $content.Count; $i++) {
        $newContent += $content[$i]

        if ($i -eq $taskLineIndex) {
            # Ajouter les sous-tÃ¢ches aprÃ¨s la tÃ¢che principale
            $newContent += $subTaskLines
        }
    }

    # Ã‰crire le contenu modifiÃ© dans le fichier - Ã‰CRASE (OVERWRITE) le contenu existant
    if ($PSCmdlet.ShouldProcess($FilePath, "Modifier le fichier en ajoutant des sous-tÃ¢ches")) {
        # Cette opÃ©ration Ã‰CRASE (OVERWRITE) le contenu du fichier original
        # Le document est directement modifiÃ©, sans affichage intermÃ©diaire
        $newContent | Set-Content -Path $FilePath -Encoding UTF8
        Write-Output "TÃ¢che '$TaskIdentifier' dÃ©composÃ©e avec succÃ¨s en $($SubTasks.Count) sous-tÃ¢ches."
        Write-Output "IMPORTANT: Le document '$FilePath' a Ã©tÃ© DIRECTEMENT MODIFIÃ‰ (OVERWRITE)."
    }
}
