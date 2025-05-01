<#
.SYNOPSIS
    Décompose interactivement une tâche de roadmap en sous-tâches plus granulaires.

.DESCRIPTION
    Cette fonction permet de décomposer interactivement une tâche de roadmap en sous-tâches
    plus granulaires directement dans le document. Elle utilise la fonction Split-RoadmapTask
    pour effectuer la décomposition.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap à modifier.

.PARAMETER TaskIdentifier
    Identifiant de la tâche à décomposer (par exemple, "1.2.1.3.2.3").
    Si non spécifié, l'utilisateur sera invité à le saisir.

.PARAMETER SubTasksInput
    Texte contenant les sous-tâches à créer, une par ligne.
    Si non spécifié, l'utilisateur sera invité à les saisir.

.PARAMETER IndentationStyle
    Style d'indentation à utiliser. Par défaut, utilise le style détecté dans le document.
    Options : "Spaces2", "Spaces4", "Tab", "Auto".

.PARAMETER CheckboxStyle
    Style de case à cocher à utiliser. Par défaut, utilise le style détecté dans le document.
    Options : "GitHub", "Custom", "Auto".

.EXAMPLE
    Invoke-RoadmapGranularization -FilePath "Roadmap/roadmap.md"

.EXAMPLE
    Invoke-RoadmapGranularization -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -SubTasksInput @"
    Analyser les besoins
    Concevoir la solution
    Implémenter le code
    Tester la solution
    "@

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>
function Invoke-RoadmapGranularization {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifier,

        [Parameter(Mandatory = $false)]
        [string]$SubTasksInput,

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

    # Importer la fonction Split-RoadmapTask si elle n'est pas déjà disponible
    if (-not (Get-Command -Name Split-RoadmapTask -ErrorAction SilentlyContinue)) {
        # Essayer de trouver le fichier dans le même répertoire
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
        if ($scriptPath) {
            $splitTaskPath = Join-Path -Path $scriptPath -ChildPath "Split-RoadmapTask-Fixed.ps1"
            if (Test-Path -Path $splitTaskPath) {
                . $splitTaskPath
            } else {
                $splitTaskPath = Join-Path -Path $scriptPath -ChildPath "Split-RoadmapTask.ps1"
                if (Test-Path -Path $splitTaskPath) {
                    . $splitTaskPath
                } else {
                    # Essayer de trouver dans le répertoire du projet
                    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath)))
                    $splitTaskPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Split-RoadmapTask-Fixed.ps1"
                    if (Test-Path -Path $splitTaskPath) {
                        . $splitTaskPath
                    } else {
                        $splitTaskPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Split-RoadmapTask.ps1"
                        if (Test-Path -Path $splitTaskPath) {
                            . $splitTaskPath
                        } else {
                            throw "La fonction Split-RoadmapTask est introuvable. Assurez-vous que le fichier Split-RoadmapTask.ps1 est présent dans le répertoire $scriptPath."
                        }
                    }
                }
            }
        } else {
            throw "La fonction Split-RoadmapTask est introuvable et impossible de déterminer le chemin du script."
        }
    }

    # Si l'identifiant de tâche n'est pas spécifié, afficher le contenu du fichier et demander à l'utilisateur
    if (-not $TaskIdentifier) {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8

        # Afficher le contenu avec des numéros de ligne
        Write-Host "Contenu du fichier de roadmap :" -ForegroundColor Cyan
        for ($i = 0; $i -lt $content.Count; $i++) {
            Write-Host ("{0,5}: {1}" -f ($i + 1), $content[$i])
        }

        # Demander à l'utilisateur de saisir l'identifiant de la tâche
        $TaskIdentifier = Read-Host -Prompt "Entrez l'identifiant de la tâche à décomposer (par exemple, 1.2.1.3.2.3)"

        if (-not $TaskIdentifier) {
            throw "Aucun identifiant de tâche spécifié. Opération annulée."
        }
    }

    # Si les sous-tâches ne sont pas spécifiées, demander à l'utilisateur
    if (-not $SubTasksInput) {
        Write-Host "Entrez les sous-tâches à créer, une par ligne. Terminez par une ligne vide." -ForegroundColor Cyan
        $lines = @()
        $line = Read-Host

        while ($line) {
            $lines += $line
            $line = Read-Host
        }

        $SubTasksInput = $lines -join "`n"

        if (-not $SubTasksInput) {
            throw "Aucune sous-tâche spécifiée. Opération annulée."
        }
    }

    # Convertir le texte des sous-tâches en tableau d'objets
    $subTasks = @()
    $lines = $SubTasksInput -split "`n" | Where-Object { $_ -match '\S' }  # Ignorer les lignes vides

    foreach ($line in $lines) {
        $subTask = @{
            Title       = $line.Trim()
            Description = ""  # Pas de description pour l'instant
        }
        $subTasks += $subTask
    }

    # Appeler la fonction Split-RoadmapTask
    if ($PSCmdlet.ShouldProcess($FilePath, "Décomposer la tâche '$TaskIdentifier' en $($subTasks.Count) sous-tâches")) {
        Split-RoadmapTask -FilePath $FilePath -TaskIdentifier $TaskIdentifier -SubTasks $subTasks -IndentationStyle $IndentationStyle -CheckboxStyle $CheckboxStyle
    }
}
