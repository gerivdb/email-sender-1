#
# RoadmapParserCore.psm1
#
# Fichier principal du module RoadmapParserCore (version minimale)
#

# DÃ©finir une fonction simple
function ConvertFrom-MarkdownToRoadmap {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$Encoding = "UTF8"
    )
    
    Write-Host "Conversion du fichier markdown $FilePath en roadmap..."
    
    # Structure pour stocker la roadmap
    $roadmap = @{
        FilePath = $FilePath
        Tasks = @()
        Statistics = @{
            TotalTasks = 0
            CompletedTasks = 0
            InProgressTasks = 0
            PendingTasks = 0
            BlockedTasks = 0
        }
        Metadata = @{
            CreatedAt = Get-Date
            LastModifiedAt = (Get-Item -Path $FilePath).LastWriteTime
            Encoding = $Encoding
        }
    }
    
    return $roadmap
}

# Exporter la fonction
Export-ModuleMember -Function ConvertFrom-MarkdownToRoadmap
