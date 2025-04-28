<#
.SYNOPSIS
    Valide le format d'un fichier markdown pour s'assurer qu'il est compatible avec le parser de roadmap.

.DESCRIPTION
    La fonction Test-MarkdownFormat vÃ©rifie qu'un fichier markdown respecte le format attendu
    pour Ãªtre correctement traitÃ© par les fonctions de conversion en roadmap.
    Elle effectue diverses vÃ©rifications comme la prÃ©sence d'un titre, la structure des sections,
    le format des tÃ¢ches, etc.

.PARAMETER FilePath
    Chemin du fichier markdown Ã  valider.

.PARAMETER Strict
    Indique si la validation doit Ãªtre stricte (erreur en cas de non-conformitÃ©) ou souple (avertissements).

.EXAMPLE
    Test-MarkdownFormat -FilePath ".\roadmap.md"
    Valide le format du fichier roadmap.md avec des avertissements pour les non-conformitÃ©s.

.EXAMPLE
    Test-MarkdownFormat -FilePath ".\roadmap.md" -Strict
    Valide le format du fichier roadmap.md et gÃ©nÃ¨re des erreurs pour les non-conformitÃ©s.

.OUTPUTS
    [PSCustomObject] ReprÃ©sentant le rÃ©sultat de la validation avec les Ã©ventuels problÃ¨mes dÃ©tectÃ©s.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
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

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # CrÃ©er l'objet de rÃ©sultat
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

    # Expressions rÃ©guliÃ¨res pour la validation
    $titleRegex = [regex]::new('^#\s+.+$')
    $sectionRegex = [regex]::new('^##\s+.+$')
    $taskRegex = [regex]::new('^\s*[-*+]\s+(?:\[[ xX~!]\])?\s*(?:\*\*([^*]+)\*\*)?\s*.*$')
    $taskWithCheckboxRegex = [regex]::new('^\s*[-*+]\s+\[[ xX~!]\]\s*.*$')
    $taskWithIdRegex = [regex]::new('^\s*[-*+]\s+(?:\[[ xX~!]\])?\s*\*\*([^*]+)\*\*\s*.*$')

    # VÃ©rifier la prÃ©sence d'un titre
    $hasTitle = $false
    foreach ($line in $lines) {
        if ($titleRegex.IsMatch($line)) {
            $hasTitle = $true
            $result.Statistics.TitleCount++
            break
        }
    }

    if (-not $hasTitle) {
        $message = "Le fichier ne contient pas de titre (ligne commenÃ§ant par #)."
        if ($Strict) {
            $result.IsValid = $false
            $result.Errors.Add($message) | Out-Null
        } else {
            $result.IsValid = $false
            $result.Warnings.Add($message) | Out-Null
        }
    }

    # VÃ©rifier la prÃ©sence de sections
    $hasSections = $false
    foreach ($line in $lines) {
        if ($sectionRegex.IsMatch($line)) {
            $hasSections = $true
            $result.Statistics.SectionCount++
        }
    }

    if (-not $hasSections) {
        $message = "Le fichier ne contient pas de sections (lignes commenÃ§ant par ##)."
        if ($Strict) {
            $result.IsValid = $false
            $result.Errors.Add($message) | Out-Null
        } else {
            $result.IsValid = $false
            $result.Warnings.Add($message) | Out-Null
        }
    }

    # VÃ©rifier le format des tÃ¢ches
    $lineNumber = 0
    foreach ($line in $lines) {
        $lineNumber++

        # VÃ©rifier si la ligne est une tÃ¢che
        if ($line -match '^\s*[-*+]\s+') {
            $result.Statistics.TaskCount++

            # VÃ©rifier si la tÃ¢che a une case Ã  cocher
            if ($taskWithCheckboxRegex.IsMatch($line)) {
                $result.Statistics.TaskWithCheckboxCount++
            } else {
                $result.Statistics.TaskWithoutCheckboxCount++
                $message = "La tÃ¢che Ã  la ligne $lineNumber n'a pas de case Ã  cocher."
                if ($Strict) {
                    $result.IsValid = $false
                    $result.Errors.Add($message) | Out-Null
                } else {
                    $result.IsValid = $false
                    $result.Warnings.Add($message) | Out-Null
                }
            }

            # VÃ©rifier si la tÃ¢che a un identifiant
            if ($taskWithIdRegex.IsMatch($line)) {
                $result.Statistics.TaskWithIdCount++
            } else {
                $result.Statistics.TaskWithoutIdCount++
                $message = "La tÃ¢che Ã  la ligne $lineNumber n'a pas d'identifiant."
                if ($Strict) {
                    $result.IsValid = $false
                    $result.Errors.Add($message) | Out-Null
                } else {
                    $result.IsValid = $false
                    $result.Warnings.Add($message) | Out-Null
                }
            }

            # VÃ©rifier le format gÃ©nÃ©ral de la tÃ¢che
            if (-not $taskRegex.IsMatch($line)) {
                $message = "La tÃ¢che Ã  la ligne $lineNumber ne respecte pas le format attendu."
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

    # VÃ©rifier qu'il y a au moins une tÃ¢che
    if ($result.Statistics.TaskCount -eq 0) {
        $message = "Le fichier ne contient aucune tÃ¢che."
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
