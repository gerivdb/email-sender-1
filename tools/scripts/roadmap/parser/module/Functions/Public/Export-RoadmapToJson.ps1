<#
.SYNOPSIS
    Exporte une roadmap au format JSON.

.DESCRIPTION
    La fonction Export-RoadmapToJson exporte une roadmap au format JSON.
    Elle peut exporter la roadmap complÃ¨te ou seulement certaines sections.

.PARAMETER Roadmap
    L'objet roadmap Ã  exporter.

.PARAMETER OutputPath
    Chemin du fichier de sortie pour le JSON.

.PARAMETER IncludeMetadata
    Indique si les mÃ©tadonnÃ©es doivent Ãªtre incluses dans l'export.

.PARAMETER IncludeDependencies
    Indique si les dÃ©pendances doivent Ãªtre incluses dans l'export.

.PARAMETER PrettyPrint
    Indique si le JSON doit Ãªtre formatÃ© pour Ãªtre lisible.

.EXAMPLE
    $roadmap = ConvertFrom-MarkdownToRoadmapExtended -FilePath ".\roadmap.md" -IncludeMetadata -DetectDependencies
    Export-RoadmapToJson -Roadmap $roadmap -OutputPath ".\roadmap.json" -IncludeMetadata -IncludeDependencies -PrettyPrint
    Exporte la roadmap au format JSON avec mÃ©tadonnÃ©es et dÃ©pendances.

.OUTPUTS
    [string] ReprÃ©sentant la roadmap au format JSON.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
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

    # Fonction rÃ©cursive pour convertir une tÃ¢che en objet JSON
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
        
        # Ajouter les mÃ©tadonnÃ©es si demandÃ©
        if ($IncludeMetadata -and $Task.PSObject.Properties.Name -contains "Metadata" -and $Task.Metadata.Count -gt 0) {
            $jsonTask | Add-Member -MemberType NoteProperty -Name "Metadata" -Value $Task.Metadata
        }
        
        # Ajouter les dÃ©pendances si demandÃ©
        if ($IncludeDependencies -and $Task.PSObject.Properties.Name -contains "Dependencies" -and $Task.Dependencies.Count -gt 0) {
            $dependencyIds = $Task.Dependencies | ForEach-Object { $_.Id }
            $jsonTask | Add-Member -MemberType NoteProperty -Name "DependsOn" -Value $dependencyIds
        }
        
        # Ajouter les sous-tÃ¢ches
        foreach ($subTask in $Task.SubTasks) {
            $jsonTask.SubTasks += (ConvertTo-JsonTask -Task $subTask)
        }
        
        return $jsonTask
    }

    # CrÃ©er l'objet JSON
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
        
        # Ajouter les tÃ¢ches
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

    # Ã‰crire dans un fichier si demandÃ©
    if (-not [string]::IsNullOrEmpty($OutputPath)) {
        $json | Out-File -FilePath $OutputPath -Encoding UTF8
    }

    return $json
}
