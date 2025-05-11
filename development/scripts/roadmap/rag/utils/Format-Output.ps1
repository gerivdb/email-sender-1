﻿# Format-Output.ps1
# Module pour formater les sorties des scripts de détection de changements dans les roadmaps
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param()

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$logModulePath = Join-Path -Path $scriptPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )

        Write-Host "[$Level] $Message"
    }
}

# Fonction pour formater les changements en texte
function Format-ChangesAsText {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Changes,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    $output = @()
    $output += "=== RAPPORT DE CHANGEMENTS ==="
    $output += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $output += "Total des changements: $($Changes.Total)"
    $output += ""

    if ($Changes.Added.Count -gt 0) {
        $output += "--- TÂCHES AJOUTÉES ($($Changes.Added.Count)) ---"
        foreach ($task in $Changes.Added) {
            $output += "  - [$($task.Status)] $($task.Id): $($task.Description)"

            if ($Detailed) {
                $output += "    Ligne: $($task.LineNumber)"
                $output += "    Contexte: $($task.Context)"
                $output += ""
            }
        }
        $output += ""
    }

    if ($Changes.Removed.Count -gt 0) {
        $output += "--- TÂCHES SUPPRIMÉES ($($Changes.Removed.Count)) ---"
        foreach ($task in $Changes.Removed) {
            $output += "  - [$($task.Status)] $($task.Id): $($task.Description)"

            if ($Detailed) {
                $output += "    Ligne: $($task.LineNumber)"
                $output += "    Contexte: $($task.Context)"
                $output += ""
            }
        }
        $output += ""
    }

    if ($Changes.StatusChanged.Count -gt 0) {
        $output += "--- STATUTS MODIFIÉS ($($Changes.StatusChanged.Count)) ---"
        foreach ($change in $Changes.StatusChanged) {
            $output += "  - $($change.Task.Id): $($change.Task.Description)"
            $output += "    $($change.OldStatus) -> $($change.NewStatus)"

            if ($Detailed) {
                $output += "    Ligne: $($change.Task.LineNumber)"
                $output += "    Contexte: $($change.Task.Context)"
                $output += ""
            }
        }
        $output += ""
    }

    if ($Changes.ContentChanged.Count -gt 0) {
        $output += "--- CONTENUS MODIFIÉS ($($Changes.ContentChanged.Count)) ---"
        foreach ($change in $Changes.ContentChanged) {
            $output += "  - $($change.Task.Id):"
            $output += "    Ancien: $($change.OldContent)"
            $output += "    Nouveau: $($change.NewContent)"

            if ($Detailed) {
                $output += "    Ligne: $($change.Task.LineNumber)"
                $output += "    Contexte: $($change.Task.Context)"
                $output += ""
            }
        }
        $output += ""
    }

    if ($Changes.Moved.Count -gt 0) {
        $output += "--- TÂCHES DÉPLACÉES ($($Changes.Moved.Count)) ---"
        foreach ($change in $Changes.Moved) {
            $output += "  - $($change.Task.Id): $($change.Task.Description)"
            $output += "    Ligne $($change.OldPosition) -> Ligne $($change.NewPosition)"

            if ($Detailed) {
                $output += "    Contexte: $($change.Task.Context)"
                $output += ""
            }
        }
        $output += ""
    }

    return $output -join "`n"
}

# Fonction pour formater les changements en JSON
function Format-ChangesAsJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Changes,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    $jsonObject = @{
        timestamp       = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        total_changes   = $Changes.Total
        added           = $Changes.Added
        removed         = $Changes.Removed
        status_changed  = $Changes.StatusChanged
        content_changed = $Changes.ContentChanged
        moved           = $Changes.Moved
        detailed        = $Detailed.IsPresent
    }

    if (-not $Detailed) {
        # Simplifier les objets pour une sortie plus concise
        $jsonObject.added = $Changes.Added | Select-Object Id, Description, Status
        $jsonObject.removed = $Changes.Removed | Select-Object Id, Description, Status
        $jsonObject.status_changed = $Changes.StatusChanged | ForEach-Object {
            @{
                id          = $_.Task.Id
                description = $_.Task.Description
                old_status  = $_.OldStatus
                new_status  = $_.NewStatus
            }
        }
        $jsonObject.content_changed = $Changes.ContentChanged | ForEach-Object {
            @{
                id          = $_.Task.Id
                old_content = $_.OldContent
                new_content = $_.NewContent
            }
        }
        $jsonObject.moved = $Changes.Moved | ForEach-Object {
            @{
                id           = $_.Task.Id
                description  = $_.Task.Description
                old_position = $_.OldPosition
                new_position = $_.NewPosition
            }
        }
    }

    return $jsonObject | ConvertTo-Json -Depth 10
}

# Fonction pour formater les changements en Markdown
function Format-ChangesAsMarkdown {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Changes,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    $output = @()
    $output += "# Rapport de changements dans la roadmap"
    $output += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $output += ""
    $output += "**Total des changements: $($Changes.Total)**"
    $output += ""

    if ($Changes.Added.Count -gt 0) {
        $output += "## Tâches ajoutées ($($Changes.Added.Count))"
        foreach ($task in $Changes.Added) {
            $statusMark = $task.Status -eq "Completed" ? "x" : " "
            $output += "- [$statusMark] **$($task.Id)**: $($task.Description)"

            if ($Detailed) {
                $output += "  - Ligne: $($task.LineNumber)"
                $output += "  - Contexte: $($task.Context)"
                $output += ""
            }
        }
        $output += ""
    }

    if ($Changes.Removed.Count -gt 0) {
        $output += "## Tâches supprimées ($($Changes.Removed.Count))"
        foreach ($task in $Changes.Removed) {
            $statusMark = $task.Status -eq "Completed" ? "x" : " "
            $output += "- [$statusMark] **$($task.Id)**: $($task.Description)"

            if ($Detailed) {
                $output += "  - Ligne: $($task.LineNumber)"
                $output += "  - Contexte: $($task.Context)"
                $output += ""
            }
        }
        $output += ""
    }

    if ($Changes.StatusChanged.Count -gt 0) {
        $output += "## Statuts modifiés ($($Changes.StatusChanged.Count))"
        foreach ($change in $Changes.StatusChanged) {
            $output += "- **$($change.Task.Id)**: $($change.Task.Description)"
            $output += "  - De: `$($change.OldStatus)` → À: `$($change.NewStatus)`"

            if ($Detailed) {
                $output += "  - Ligne: $($change.Task.LineNumber)"
                $output += "  - Contexte: $($change.Task.Context)"
                $output += ""
            }
        }
        $output += ""
    }

    if ($Changes.ContentChanged.Count -gt 0) {
        $output += "## Contenus modifiés ($($Changes.ContentChanged.Count))"
            foreach ($change in $Changes.ContentChanged) {
                $output += "- **$($change.Task.Id)**:"
                $output += "  - Ancien: `$($change.OldContent)`"
            $output += "  - Nouveau: `$($change.NewContent)`"

                if ($Detailed) {
                    $output += "  - Ligne: $($change.Task.LineNumber)"
                    $output += "  - Contexte: $($change.Task.Context)"
                    $output += ""
                }
            }
            $output += ""
        }

        if ($Changes.Moved.Count -gt 0) {
            $output += "## Tâches déplacées ($($Changes.Moved.Count))"
            foreach ($change in $Changes.Moved) {
                $output += "- **$($change.Task.Id)**: $($change.Task.Description)"
                $output += "  - Déplacée de la ligne $($change.OldPosition) vers la ligne $($change.NewPosition)"

                if ($Detailed) {
                    $output += "  - Contexte: $($change.Task.Context)"
                    $output += ""
                }
            }
            $output += ""
        }

        return $output -join "`n"
    }

    # Fonction pour formater les changements en HTML
    function Format-ChangesAsHtml {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory = $true)]
            [hashtable]$Changes,

            [Parameter(Mandatory = $false)]
            [switch]$Detailed
        )

        $css = @"
<style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #2c3e50; }
    h2 { color: #3498db; margin-top: 20px; }
    .task { margin-bottom: 10px; }
    .details { margin-left: 20px; color: #7f8c8d; }
    .added { background-color: #e6ffe6; padding: 5px; }
    .removed { background-color: #ffe6e6; padding: 5px; }
    .changed { background-color: #e6f0ff; padding: 5px; }
    .moved { background-color: #fff5e6; padding: 5px; }
    .summary { font-weight: bold; margin-bottom: 15px; }
</style>
"@

        $html = @()
        $html += "<!DOCTYPE html>"
        $html += "<html>"
        $html += "<head>"
        $html += "<title>Rapport de changements dans la roadmap</title>"
        $html += $css
        $html += "</head>"
        $html += "<body>"
        $html += "<h1>Rapport de changements dans la roadmap</h1>"
        $html += "<p>Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>"
        $html += "<p class='summary'>Total des changements: $($Changes.Total)</p>"

        if ($Changes.Added.Count -gt 0) {
            $html += "<h2>Tâches ajoutées ($($Changes.Added.Count))</h2>"
            foreach ($task in $Changes.Added) {
                $statusMark = $task.Status -eq "Completed" ? "✓" : "☐"
                $html += "<div class='task added'>"
                $html += "  <div>$statusMark <strong>$($task.Id)</strong>: $($task.Description)</div>"

                if ($Detailed) {
                    $html += "  <div class='details'>"
                    $html += "    Ligne: $($task.LineNumber)<br>"
                    $html += "    Contexte: $($task.Context)"
                    $html += "  </div>"
                }

                $html += "</div>"
            }
        }

        if ($Changes.Removed.Count -gt 0) {
            $html += "<h2>Tâches supprimées ($($Changes.Removed.Count))</h2>"
            foreach ($task in $Changes.Removed) {
                $statusMark = $task.Status -eq "Completed" ? "✓" : "☐"
                $html += "<div class='task removed'>"
                $html += "  <div>$statusMark <strong>$($task.Id)</strong>: $($task.Description)</div>"

                if ($Detailed) {
                    $html += "  <div class='details'>"
                    $html += "    Ligne: $($task.LineNumber)<br>"
                    $html += "    Contexte: $($task.Context)"
                    $html += "  </div>"
                }

                $html += "</div>"
            }
        }

        if ($Changes.StatusChanged.Count -gt 0) {
            $html += "<h2>Statuts modifiés ($($Changes.StatusChanged.Count))</h2>"
            foreach ($change in $Changes.StatusChanged) {
                $html += "<div class='task changed'>"
                $html += "  <div><strong>$($change.Task.Id)</strong>: $($change.Task.Description)</div>"
                $html += "  <div>De: <code>$($change.OldStatus)</code> → À: <code>$($change.NewStatus)</code></div>"

                if ($Detailed) {
                    $html += "  <div class='details'>"
                    $html += "    Ligne: $($change.Task.LineNumber)<br>"
                    $html += "    Contexte: $($change.Task.Context)"
                    $html += "  </div>"
                }

                $html += "</div>"
            }
        }

        if ($Changes.ContentChanged.Count -gt 0) {
            $html += "<h2>Contenus modifiés ($($Changes.ContentChanged.Count))</h2>"
            foreach ($change in $Changes.ContentChanged) {
                $html += "<div class='task changed'>"
                $html += "  <div><strong>$($change.Task.Id)</strong>:</div>"
                $html += "  <div>Ancien: <code>$($change.OldContent)</code></div>"
                $html += "  <div>Nouveau: <code>$($change.NewContent)</code></div>"

                if ($Detailed) {
                    $html += "  <div class='details'>"
                    $html += "    Ligne: $($change.Task.LineNumber)<br>"
                    $html += "    Contexte: $($change.Task.Context)"
                    $html += "  </div>"
                }

                $html += "</div>"
            }
        }

        if ($Changes.Moved.Count -gt 0) {
            $html += "<h2>Tâches déplacées ($($Changes.Moved.Count))</h2>"
            foreach ($change in $Changes.Moved) {
                $html += "<div class='task moved'>"
                $html += "  <div><strong>$($change.Task.Id)</strong>: $($change.Task.Description)</div>"
                $html += "  <div>Déplacée de la ligne $($change.OldPosition) vers la ligne $($change.NewPosition)</div>"

                if ($Detailed) {
                    $html += "  <div class='details'>"
                    $html += "    Contexte: $($change.Task.Context)"
                    $html += "  </div>"
                }

                $html += "</div>"
            }
        }

        $html += "</body>"
        $html += "</html>"

        return $html -join "`n"
    }

    # Exporter les fonctions
    Export-ModuleMember -Function Format-ChangesAsText, Format-ChangesAsJson, Format-ChangesAsMarkdown, Format-ChangesAsHtml
