<#
.SYNOPSIS
    Analyse et gÃ¨re les dÃ©pendances entre les tÃ¢ches d'une roadmap.

.DESCRIPTION
    La fonction Get-TaskDependencies analyse une roadmap pour dÃ©tecter et gÃ©rer les dÃ©pendances entre les tÃ¢ches.
    Elle peut dÃ©tecter les dÃ©pendances explicites et implicites, et gÃ©nÃ©rer une visualisation des dÃ©pendances.

.PARAMETER FilePath
    Chemin du fichier markdown Ã  analyser.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour la visualisation des dÃ©pendances.

.EXAMPLE
    Get-TaskDependencies -FilePath ".\roadmap.md" -OutputPath ".\dependencies.md"
    Analyse les dÃ©pendances de la roadmap et gÃ©nÃ¨re une visualisation.

.OUTPUTS
    [PSCustomObject] ReprÃ©sentant les dÃ©pendances de la roadmap.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
#>
function Get-TaskDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # CrÃ©er l'objet de rÃ©sultat
    $result = [PSCustomObject]@{
        FilePath      = $FilePath
        Tasks         = @{}
        Dependencies  = @()
        Visualization = ""
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw
    $lines = $content -split "`r?`n"

    # Extraire les tÃ¢ches et les dÃ©pendances
    $taskRegex = [regex]::new('^\s*[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$')
    $dependsRegex = [regex]::new('@depends:([\w\.-]+)')
    $refRegex = [regex]::new('ref:([\w\.-]+)')

    foreach ($line in $lines) {
        $taskMatch = $taskRegex.Match($line)
        if ($taskMatch.Success) {
            $id = $taskMatch.Groups[2].Value
            $title = $taskMatch.Groups[3].Value

            if (-not [string]::IsNullOrEmpty($id)) {
                # Ajouter la tÃ¢che au dictionnaire
                $result.Tasks[$id] = [PSCustomObject]@{
                    Id    = $id
                    Title = $title
                    Line  = $line
                }

                # DÃ©tecter les dÃ©pendances explicites
                $dependsMatch = $dependsRegex.Match($title)
                if ($dependsMatch.Success) {
                    $dependsOn = $dependsMatch.Groups[1].Value
                    $result.Dependencies += [PSCustomObject]@{
                        TaskId    = $id
                        DependsOn = $dependsOn
                        Type      = "Explicit"
                    }
                }

                # DÃ©tecter les dÃ©pendances implicites
                $refMatch = $refRegex.Match($title)
                if ($refMatch.Success) {
                    $refId = $refMatch.Groups[1].Value
                    $result.Dependencies += [PSCustomObject]@{
                        TaskId    = $id
                        DependsOn = $refId
                        Type      = "Implicit"
                    }
                }
            }
        }
    }

    # GÃ©nÃ©rer une visualisation des dÃ©pendances
    if ($result.Dependencies.Count -gt 0) {
        $sb = [System.Text.StringBuilder]::new()

        $sb.AppendLine('```mermaid') | Out-Null
        $sb.AppendLine('graph TD') | Out-Null

        # Ajouter les nÅ“uds
        foreach ($id in $result.Tasks.Keys) {
            $task = $result.Tasks[$id]
            $sb.AppendLine("    $id[$($id): $($task.Title)]") | Out-Null
        }

        # Ajouter les relations de dÃ©pendance
        foreach ($dependency in $result.Dependencies) {
            $sb.AppendLine("    $($dependency.DependsOn) --> $($dependency.TaskId)") | Out-Null
        }

        $sb.AppendLine('```') | Out-Null

        $result.Visualization = $sb.ToString()

        # Ã‰crire la visualisation dans un fichier si demandÃ©
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            $result.Visualization | Out-File -FilePath $OutputPath -Encoding UTF8
        }
    }

    return $result
}
