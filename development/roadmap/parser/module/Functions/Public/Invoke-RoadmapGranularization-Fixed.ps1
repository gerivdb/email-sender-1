<#
.SYNOPSIS
    DÃ©compose interactivement une tÃ¢che de roadmap en sous-tÃ¢ches plus granulaires.

.DESCRIPTION
    Cette fonction permet de dÃ©composer interactivement une tÃ¢che de roadmap en sous-tÃ¢ches
    plus granulaires directement dans le document. Elle utilise la fonction Split-RoadmapTask
    pour effectuer la dÃ©composition.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  modifier.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  dÃ©composer (par exemple, "1.2.1.3.2.3").
    Si non spÃ©cifiÃ©, l'utilisateur sera invitÃ© Ã  le saisir.

.PARAMETER SubTasksInput
    Texte contenant les sous-tÃ¢ches Ã  crÃ©er, une par ligne.
    Si non spÃ©cifiÃ©, l'utilisateur sera invitÃ© Ã  les saisir.

.PARAMETER IndentationStyle
    Style d'indentation Ã  utiliser. Par dÃ©faut, utilise le style dÃ©tectÃ© dans le document.
    Options : "Spaces2", "Spaces4", "Tab", "Auto".

.PARAMETER CheckboxStyle
    Style de case Ã  cocher Ã  utiliser. Par dÃ©faut, utilise le style dÃ©tectÃ© dans le document.
    Options : "GitHub", "Custom", "Auto".

.EXAMPLE
    Invoke-RoadmapGranularization -FilePath "Roadmap/roadmap.md"

.EXAMPLE
    Invoke-RoadmapGranularization -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -SubTasksInput @"
    Analyser les besoins
    Concevoir la solution
    ImplÃ©menter le code
    Tester la solution
    "@

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
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

    # VÃ©rifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier spÃ©cifiÃ© n'existe pas : $FilePath"
    }

    # Importer la fonction Split-RoadmapTask si elle n'est pas dÃ©jÃ  disponible
    if (-not (Get-Command -Name Split-RoadmapTask -ErrorAction SilentlyContinue)) {
        # Essayer de trouver le fichier dans le mÃªme rÃ©pertoire
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
                    # Essayer de trouver dans le rÃ©pertoire du projet
                    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath)))
                    $splitTaskPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Split-RoadmapTask-Fixed.ps1"
                    if (Test-Path -Path $splitTaskPath) {
                        . $splitTaskPath
                    } else {
                        $splitTaskPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\module\Functions\Public\Split-RoadmapTask.ps1"
                        if (Test-Path -Path $splitTaskPath) {
                            . $splitTaskPath
                        } else {
                            throw "La fonction Split-RoadmapTask est introuvable. Assurez-vous que le fichier Split-RoadmapTask.ps1 est prÃ©sent dans le rÃ©pertoire $scriptPath."
                        }
                    }
                }
            }
        } else {
            throw "La fonction Split-RoadmapTask est introuvable et impossible de dÃ©terminer le chemin du script."
        }
    }

    # Si l'identifiant de tÃ¢che n'est pas spÃ©cifiÃ©, afficher le contenu du fichier et demander Ã  l'utilisateur
    if (-not $TaskIdentifier) {
        # Lire le contenu du fichier
        $content = Get-Content -Path $FilePath -Encoding UTF8

        # Afficher le contenu avec des numÃ©ros de ligne
        Write-Host "Contenu du fichier de roadmap :" -ForegroundColor Cyan
        for ($i = 0; $i -lt $content.Count; $i++) {
            Write-Host ("{0,5}: {1}" -f ($i + 1), $content[$i])
        }

        # Demander Ã  l'utilisateur de saisir l'identifiant de la tÃ¢che
        $TaskIdentifier = Read-Host -Prompt "Entrez l'identifiant de la tÃ¢che Ã  dÃ©composer (par exemple, 1.2.1.3.2.3)"

        if (-not $TaskIdentifier) {
            throw "Aucun identifiant de tÃ¢che spÃ©cifiÃ©. OpÃ©ration annulÃ©e."
        }
    }

    # Si les sous-tÃ¢ches ne sont pas spÃ©cifiÃ©es, demander Ã  l'utilisateur
    if (-not $SubTasksInput) {
        Write-Host "Entrez les sous-tÃ¢ches Ã  crÃ©er, une par ligne. Terminez par une ligne vide." -ForegroundColor Cyan
        $lines = @()
        $line = Read-Host

        while ($line) {
            $lines += $line
            $line = Read-Host
        }

        $SubTasksInput = $lines -join "`n"

        if (-not $SubTasksInput) {
            throw "Aucune sous-tÃ¢che spÃ©cifiÃ©e. OpÃ©ration annulÃ©e."
        }
    }

    # Convertir le texte des sous-tÃ¢ches en tableau d'objets
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
    if ($PSCmdlet.ShouldProcess($FilePath, "DÃ©composer la tÃ¢che '$TaskIdentifier' en $($subTasks.Count) sous-tÃ¢ches")) {
        Split-RoadmapTask -FilePath $FilePath -TaskIdentifier $TaskIdentifier -SubTasks $subTasks -IndentationStyle $IndentationStyle -CheckboxStyle $CheckboxStyle
    }
}
