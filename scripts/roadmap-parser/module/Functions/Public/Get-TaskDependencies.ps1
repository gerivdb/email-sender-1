<#
.SYNOPSIS
    Analyse et gère les dépendances entre les tâches d'une roadmap.

.DESCRIPTION
    La fonction Get-TaskDependencies analyse une roadmap pour détecter et gérer les dépendances entre les tâches.
    Elle peut détecter les dépendances explicites et implicites, et générer une visualisation des dépendances.

.PARAMETER FilePath
    Chemin du fichier markdown à analyser.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour la visualisation des dépendances.

.EXAMPLE
    Get-TaskDependencies -FilePath ".\roadmap.md" -OutputPath ".\dependencies.md"
    Analyse les dépendances de la roadmap et génère une visualisation.

.OUTPUTS
    [PSCustomObject] Représentant les dépendances de la roadmap.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function Get-TaskDependencies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier '$FilePath' n'existe pas."
    }

    # Créer l'objet de résultat
    $result = [PSCustomObject]@{
        FilePath      = $FilePath
        Tasks         = @{}
        Dependencies  = @()
        Visualization = ""
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Encoding UTF8 -Raw
    $lines = $content -split "`r?`n"

    # Extraire les tâches et les dépendances
    $taskRegex = [regex]::new('^\s*[-*+]\s*(?:\[([ xX~!])\])?\s*(?:\*\*([^*]+)\*\*)?\s*(.*)$')
    $dependsRegex = [regex]::new('@depends:([\w\.-]+)')
    $refRegex = [regex]::new('ref:([\w\.-]+)')

    foreach ($line in $lines) {
        $taskMatch = $taskRegex.Match($line)
        if ($taskMatch.Success) {
            $id = $taskMatch.Groups[2].Value
            $title = $taskMatch.Groups[3].Value

            if (-not [string]::IsNullOrEmpty($id)) {
                # Ajouter la tâche au dictionnaire
                $result.Tasks[$id] = [PSCustomObject]@{
                    Id    = $id
                    Title = $title
                    Line  = $line
                }

                # Détecter les dépendances explicites
                $dependsMatch = $dependsRegex.Match($title)
                if ($dependsMatch.Success) {
                    $dependsOn = $dependsMatch.Groups[1].Value
                    $result.Dependencies += [PSCustomObject]@{
                        TaskId    = $id
                        DependsOn = $dependsOn
                        Type      = "Explicit"
                    }
                }

                # Détecter les dépendances implicites
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

    # Générer une visualisation des dépendances
    if ($result.Dependencies.Count -gt 0) {
        $sb = [System.Text.StringBuilder]::new()

        $sb.AppendLine('```mermaid') | Out-Null
        $sb.AppendLine('graph TD') | Out-Null

        # Ajouter les nœuds
        foreach ($id in $result.Tasks.Keys) {
            $task = $result.Tasks[$id]
            $sb.AppendLine("    $id[$($id): $($task.Title)]") | Out-Null
        }

        # Ajouter les relations de dépendance
        foreach ($dependency in $result.Dependencies) {
            $sb.AppendLine("    $($dependency.DependsOn) --> $($dependency.TaskId)") | Out-Null
        }

        $sb.AppendLine('```') | Out-Null

        $result.Visualization = $sb.ToString()

        # Écrire la visualisation dans un fichier si demandé
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            $result.Visualization | Out-File -FilePath $OutputPath -Encoding UTF8
        }
    }

    return $result
}
