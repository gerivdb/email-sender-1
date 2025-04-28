# Test-RoadmapParser.ps1
# Script pour tester le parser de roadmap

# Importer le module RoadmapParser
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapParser.ps1"
. $modulePath

# Chemin du fichier de roadmap Ã  analyser
$roadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"

# VÃ©rifier si le fichier existe
if (-not (Test-Path -Path $roadmapFilePath)) {
    Write-Error "Le fichier de roadmap n'existe pas: $roadmapFilePath"
    exit 1
}

# CrÃ©er le rÃ©pertoire d'analyse s'il n'existe pas
$analysisDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\analysis"
if (-not (Test-Path -Path $analysisDir)) {
    New-Item -Path $analysisDir -ItemType Directory -Force | Out-Null
    Write-Host "RÃ©pertoire d'analyse crÃ©Ã©: $analysisDir" -ForegroundColor Green
}

# Analyser la structure du fichier de roadmap
Write-Host "Analyse de la structure du fichier de roadmap..." -ForegroundColor Cyan
$structureInfo = Get-RoadmapStructureInfo -FilePath $roadmapFilePath

# Afficher les informations de base
Write-Host "`nInformations de base:" -ForegroundColor Green
Write-Host "  TÃ¢ches totales: $($structureInfo.Progress.TotalTasks)"
Write-Host "  TÃ¢ches terminÃ©es: $($structureInfo.Progress.CompleteTasks)"
Write-Host "  TÃ¢ches en cours: $($structureInfo.Progress.IncompleteTasks)"
Write-Host "  Pourcentage de complÃ©tion: $($structureInfo.Progress.CompletionPercentage)%"

# GÃ©nÃ©rer un rapport de structure
Write-Host "`nGÃ©nÃ©ration d'un rapport de structure..." -ForegroundColor Cyan
$structureReportPath = Join-Path -Path $analysisDir -ChildPath "structure-report.md"
$structureReport = New-RoadmapStructureReport -StructureInfo $structureInfo -OutputPath $structureReportPath
Write-Host "Rapport de structure gÃ©nÃ©rÃ©: $structureReportPath" -ForegroundColor Green

# GÃ©nÃ©rer un rapport de progression
Write-Host "`nGÃ©nÃ©ration d'un rapport de progression..." -ForegroundColor Cyan
$progressReportPath = Join-Path -Path $analysisDir -ChildPath "progress-report.md"
$progressReport = New-ProgressReport -FilePath $roadmapFilePath -OutputPath $progressReportPath
Write-Host "Rapport de progression gÃ©nÃ©rÃ©: $progressReportPath" -ForegroundColor Green

# Parser le fichier de roadmap en structure de tÃ¢ches
Write-Host "`nParsing du fichier de roadmap en structure de tÃ¢ches..." -ForegroundColor Cyan
$taskStructure = ConvertFrom-MarkdownToTaskStructure -FilePath $roadmapFilePath

# Afficher les informations de la structure de tÃ¢ches
Write-Host "`nInformations de la structure de tÃ¢ches:" -ForegroundColor Green
Write-Host "  Titre: $($taskStructure.Title)"
Write-Host "  Nombre de tÃ¢ches de premier niveau: $($taskStructure.Tasks.Count)"

# Fonction rÃ©cursive pour compter les tÃ¢ches
function Count-Tasks {
    param (
        [Parameter(Mandatory = $true)]
        [array]$Tasks
    )

    $count = $Tasks.Count

    foreach ($task in $Tasks) {
        $count += Count-Tasks -Tasks $task.Children
    }

    return $count
}

$totalTasks = Count-Tasks -Tasks $taskStructure.Tasks
Write-Host "  Nombre total de tÃ¢ches: $totalTasks"

# Convertir la structure de tÃ¢ches en markdown
Write-Host "`nConversion de la structure de tÃ¢ches en markdown..." -ForegroundColor Cyan
$outputMarkdownPath = Join-Path -Path $analysisDir -ChildPath "roadmap-regenerated.md"
$markdown = ConvertTo-MarkdownFromTaskStructure -TaskStructure $taskStructure -OutputPath $outputMarkdownPath
Write-Host "Markdown gÃ©nÃ©rÃ©: $outputMarkdownPath" -ForegroundColor Green

# Tester la mise Ã  jour du statut d'une tÃ¢che
Write-Host "`nTest de mise Ã  jour du statut d'une tÃ¢che..." -ForegroundColor Cyan
$testFilePath = Join-Path -Path $analysisDir -ChildPath "roadmap-test.md"
Copy-Item -Path $roadmapFilePath -Destination $testFilePath -Force
$taskId = "1.1.1"
$newStatus = "Complete"
$updated = Update-TaskStatus -FilePath $testFilePath -TaskId $taskId -Status $newStatus -SaveChanges
Write-Host "Statut de la tÃ¢che $taskId mis Ã  jour: $updated" -ForegroundColor $(if ($updated) { "Green" } else { "Red" })

# Tester l'ajout d'une nouvelle tÃ¢che
Write-Host "`nTest d'ajout d'une nouvelle tÃ¢che..." -ForegroundColor Cyan
$newTaskId = "1.1.1.4"
$newTaskTitle = "Nouvelle tÃ¢che de test"
$parentTaskId = "1.1.1"
$added = Add-Task -FilePath $testFilePath -TaskId $newTaskId -Title $newTaskTitle -ParentTaskId $parentTaskId -SaveChanges
Write-Host "TÃ¢che $newTaskId ajoutÃ©e: $added" -ForegroundColor $(if ($added) { "Green" } else { "Red" })

# Tester la suppression d'une tÃ¢che
Write-Host "`nTest de suppression d'une tÃ¢che..." -ForegroundColor Cyan
$removed = Remove-Task -FilePath $testFilePath -TaskId $newTaskId -SaveChanges
Write-Host "TÃ¢che $newTaskId supprimÃ©e: $removed" -ForegroundColor $(if ($removed) { "Green" } else { "Red" })

Write-Host "`nTests terminÃ©s." -ForegroundColor Cyan
