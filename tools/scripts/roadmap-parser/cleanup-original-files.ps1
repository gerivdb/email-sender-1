<#
.SYNOPSIS
    Supprime les fichiers originaux aprÃ¨s la rÃ©organisation.

.DESCRIPTION
    Ce script supprime les fichiers originaux qui ont Ã©tÃ© copiÃ©s vers la nouvelle structure
    de dossiers lors de la rÃ©organisation.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

# Liste des fichiers Ã  supprimer
$filesToRemove = @(
    "archi-mode.ps1",
    "debug-mode.ps1",
    "test-mode.ps1",
    "RoadmapParser.ps1",
    "RoadmapParser.psd1",
    "RoadmapParser.psm1",
    "RoadmapParser3.ps1",
    "RoadmapParser3.psd1",
    "RoadmapParser3.psm1",
    "RoadmapParser3Simple.ps1",
    "RoadmapParser3Simple.psm1",
    "RoadmapModel.psd1",
    "RoadmapModel.psm1",
    "RoadmapModel2.psd1",
    "RoadmapModel2.psm1",
    "SimpleModule.psm1",
    "Analyze-RoadmapStructure.ps1",
    "Export-RoadmapStructure.ps1",
    "Find-Dependencies.ps1",
    "Analyze-RoadmapFile.ps1",
    "Generate-ConventionReport.ps1",
    "Generate-ProgressReport.ps1",
    "Generate-RoadmapSummary.ps1",
    "Run-RoadmapAnalysis.ps1",
    "Get-ProjectSpecificSettings.ps1",
    "Test-ConvertFromMarkdown.ps1",
    "Test-ExportFunctions.ps1",
    "Test-MarkdownParsing.ps1",
    "Test-ProjectConventions.ps1",
    "Test-RoadmapModel.ps1",
    "Test-RoadmapModel2.ps1",
    "Test-RoadmapModel3.ps1",
    "Test-RoadmapModel5.ps1",
    "Test-RoadmapParser.ps1",
    "Test-RoadmapParser3.ps1",
    "Test-RoadmapParser3Simple.ps1",
    "Test-RoadmapStructure.ps1",
    "Test-SimpleModule.ps1",
    "Test-StatusMarkers.ps1",
    "Test-TaskIdentifiers.ps1",
    "Test-RoadmapModel-Dependencies.ps1",
    "Test-RoadmapModel2-Dependencies.ps1"
)

# Fonction pour supprimer un fichier
function Remove-FileIfExists {
    param (
        [string]$FilePath
    )
    
    if (Test-Path -Path $FilePath) {
        try {
            Remove-Item -Path $FilePath -Force
            Write-Host "Fichier supprimÃ© : $FilePath" -ForegroundColor Green
        }
        catch {
            Write-Error "Erreur lors de la suppression du fichier $FilePath : $_"
        }
    }
    else {
        Write-Warning "Le fichier n'existe pas : $FilePath"
    }
}

# Demander confirmation avant de supprimer les fichiers
Write-Host "Cette opÃ©ration va supprimer les fichiers originaux suivants :" -ForegroundColor Yellow
foreach ($file in $filesToRemove) {
    Write-Host "  - $file"
}

$confirmation = Read-Host "ÃŠtes-vous sÃ»r de vouloir supprimer ces fichiers ? (O/N)"

if ($confirmation -eq "O" -or $confirmation -eq "o") {
    # Supprimer les fichiers
    foreach ($file in $filesToRemove) {
        $filePath = Join-Path -Path $PSScriptRoot -ChildPath $file
        Remove-FileIfExists -FilePath $filePath
    }
    
    Write-Host "Nettoyage terminÃ©. Les fichiers originaux ont Ã©tÃ© supprimÃ©s." -ForegroundColor Green
}
else {
    Write-Host "OpÃ©ration annulÃ©e. Aucun fichier n'a Ã©tÃ© supprimÃ©." -ForegroundColor Yellow
}
