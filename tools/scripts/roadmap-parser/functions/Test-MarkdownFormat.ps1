<#
.SYNOPSIS
    Valide le format d'un fichier markdown pour s'assurer qu'il est compatible avec le parser de roadmap.

.DESCRIPTION
    La fonction Test-MarkdownFormat vérifie qu'un fichier markdown respecte le format attendu
    pour être correctement traité par les fonctions de conversion en roadmap.
    Elle effectue diverses vérifications comme la présence d'un titre, la structure des sections,
    le format des tâches, etc.

.PARAMETER FilePath
    Chemin du fichier markdown à valider.

.PARAMETER Strict
    Indique si la validation doit être stricte (erreur en cas de non-conformité) ou souple (avertissements).

.EXAMPLE
    Test-MarkdownFormat -FilePath ".\roadmap.md"
    Valide le format du fichier roadmap.md avec des avertissements pour les non-conformités.

.EXAMPLE
    Test-MarkdownFormat -FilePath ".\roadmap.md" -Strict
    Valide le format du fichier roadmap.md et génère des erreurs pour les non-conformités.

.OUTPUTS
    [PSCustomObject] Représentant le résultat de la validation avec les éventuels problèmes détectés.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function Test-MarkdownFormat {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [switch]$Strict
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        IsValid    = $true
        Errors     = [System.Collections.ArrayList]::new()
        Warnings   = [System.Collections.ArrayList]::new()
        Statistics = [PSCustomObject]@{
            TotalLines               = 0
            TitleCount               = 0
            SectionCount             = 0
            TaskCount                = 0
            TaskWithIdCount          = 0
            TaskWithoutIdCount       = 0
            TaskWithCheckboxCount    = 0
            TaskWithoutCheckboxCount = 0
        }
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw
    $lines = $content -split "`r?`n"
    $result.Statistics.TotalLines = $lines.Count

    # Expressions régulières pour la validation
    $titleRegex = [regex]::new('^#\s+.+$')
    $sectionRegex = [regex]::new('^##\s+.+$')
    $taskRegex = [regex]::new('^\s*[-*+]\s+(?:\[[ xX~!]\])?\s*(?:\*\*([^*]+)\*\*)?\s*.*$')
    $taskWithCheckboxRegex = [regex]::new('^\s*[-*+]\s+\[[ xX~!]\]\s*.*$')
    $taskWithIdRegex = [regex]::new('^\s*[-*+]\s+(?:\[[ xX~!]\])?\s*\*\*([^*]+)\*\*\s*.*$')

    # Vérifier la présence d'un titre
    $hasTitle = $false
    foreach ($line in $lines) {
        if ($titleRegex.IsMatch($line)) {
            $hasTitle = $true
            $result.Statistics.TitleCount++
            break
        }
    }

    if (-not $hasTitle) {
        $message = "Le fichier ne contient pas de titre (ligne commençant par #)."
        if ($Strict) {
            $result.IsValid = $false
            $result.Errors.Add($message) | Out-Null
        } else {
            $result.IsValid = $false
            $result.Warnings.Add($message) | Out-Null
        }
    }

    # Vérifier la présence de sections
    $hasSections = $false
    foreach ($line in $lines) {
        if ($sectionRegex.IsMatch($line)) {
            $hasSections = $true
            $result.Statistics.SectionCount++
        }
    }

    if (-not $hasSections) {
        $message = "Le fichier ne contient pas de sections (lignes commençant par ##)."
        if ($Strict) {
            $result.IsValid = $false
            $result.Errors.Add($message) | Out-Null
        } else {
            $result.IsValid = $false
            $result.Warnings.Add($message) | Out-Null
        }
    }

    # Vérifier le format des tâches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        # Vérifier si la ligne est une tâche
        if ($line -match '^\s*[-*+]\s+') {
            $result.Statistics.TaskCount++

            # Vérifier si la tâche a une case à cocher
            if ($taskWithCheckboxRegex.IsMatch($line)) {
                $result.Statistics.TaskWithCheckboxCount++
            } else {
                $result.Statistics.TaskWithoutCheckboxCount++
                $message = "La tâche à la ligne $lineNumber n'a pas de case à cocher."
                if ($Strict) {
                    $result.IsValid = $false
                    $result.Errors.Add($message) | Out-Null
                } else {
                    $result.IsValid = $false
                    $result.Warnings.Add($message) | Out-Null
                }
            }

            # Vérifier si la tâche a un identifiant
            if ($taskWithIdRegex.IsMatch($line)) {
                $result.Statistics.TaskWithIdCount++
            } else {
                $result.Statistics.TaskWithoutIdCount++
                $message = "La tâche à la ligne $lineNumber n'a pas d'identifiant."
                if ($Strict) {
                    $result.IsValid = $false
                    $result.Errors.Add($message) | Out-Null
                } else {
                    $result.IsValid = $false
                    $result.Warnings.Add($message) | Out-Null
                }
            }

            # Vérifier le format général de la tâche
            if (-not $taskRegex.IsMatch($line)) {
                $message = "La tâche à la ligne $lineNumber ne respecte pas le format attendu."
                if ($Strict) {
                    $result.IsValid = $false
                    $result.Errors.Add($message) | Out-Null
                } else {
                    $result.IsValid = $false
                    $result.Warnings.Add($message) | Out-Null
                }
            }
        }
    }

    # Vérifier qu'il y a au moins une tâche
    if ($result.Statistics.TaskCount -eq 0) {
        $message = "Le fichier ne contient aucune tâche."
        if ($Strict) {
            $result.IsValid = $false
            $result.Errors.Add($message) | Out-Null
        } else {
            $result.IsValid = $false
            $result.Warnings.Add($message) | Out-Null
        }
    }

    return $result
}
