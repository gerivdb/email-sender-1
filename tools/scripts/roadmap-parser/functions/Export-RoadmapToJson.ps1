<#
.SYNOPSIS
    Exporte une roadmap au format JSON.

.DESCRIPTION
    La fonction Export-RoadmapToJson exporte une roadmap au format JSON.
    Elle peut exporter la roadmap complète ou seulement certaines sections.

.PARAMETER Roadmap
    L'objet roadmap à exporter.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour le JSON.

.PARAMETER IncludeMetadata
    Indique si les métadonnées doivent être incluses dans l'export.

.PARAMETER IncludeDependencies
    Indique si les dépendances doivent être incluses dans l'export.

.PARAMETER PrettyPrint
    Indique si le JSON doit être formaté pour être lisible.

.EXAMPLE
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
    Export-RoadmapToJson -Roadmap $roadmap -OutputPath ".\roadmap.json" -IncludeMetadata -IncludeDependencies -PrettyPrint
    Exporte la roadmap au format JSON avec métadonnées et dépendances.

.OUTPUTS
    [string] Représentant la roadmap au format JSON.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function Export-RoadmapToJson {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCustomObject]$Roadmap,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetadata,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDependencies,

        [Parameter(Mandatory = $false)]
        [switch]$PrettyPrint
    )

    # Fonction récursive pour convertir une tâche en objet JSON
    function ConvertTo-JsonTask {
        param (
            [PSCustomObject]$Task
        )
        
        $jsonTask = [PSCustomObject]@{
            Id = $Task.Id
            Title = $Task.Title
            Status = $Task.Status
            SubTasks = @()
        }
        
        # Ajouter les métadonnées si demandé
        if ($IncludeMetadata -and $Task.PSObject.Properties.Name -contains "Metadata" -and $Task.Metadata.Count -gt 0) {
            $jsonTask | Add-Member -MemberType NoteProperty -Name "Metadata" -Value $Task.Metadata
        }
        
        # Ajouter les dépendances si demandé
        if ($IncludeDependencies -and $Task.PSObject.Properties.Name -contains "Dependencies" -and $Task.Dependencies.Count -gt 0) {
            $dependencyIds = $Task.Dependencies | ForEach-Object { $_.Id }
            $jsonTask | Add-Member -MemberType NoteProperty -Name "DependsOn" -Value $dependencyIds
        }
        
        # Ajouter les sous-tâches
        foreach ($subTask in $Task.SubTasks) {
            $jsonTask.SubTasks += (ConvertTo-JsonTask -Task $subTask)
        }
        
        return $jsonTask
    }

    # Créer l'objet JSON
    $jsonRoadmap = [PSCustomObject]@{
        Title = $Roadmap.Title
        Description = $Roadmap.Description
        Sections = @()
    }

    # Ajouter les sections
    foreach ($section in $Roadmap.Sections) {
        $jsonSection = [PSCustomObject]@{
            Title = $section.Title
            Tasks = @()
        }
        
        # Ajouter les tâches
        foreach ($task in $section.Tasks) {
            $jsonSection.Tasks += (ConvertTo-JsonTask -Task $task)
        }
        
        $jsonRoadmap.Sections += $jsonSection
    }

    # Convertir en JSON
    $jsonOptions = if ($PrettyPrint) {
        @{
            Depth = 100
            Compress = $false
        }
    } else {
        @{
            Depth = 100
            Compress = $true
        }
    }
    
    $json = $jsonRoadmap | ConvertTo-Json @jsonOptions

    # Écrire dans un fichier si demandé
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $json | Out-File -FilePath $OutputPath -Encoding UTF8
    }

    return $json
}
