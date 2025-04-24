# Test-RoadmapParser.ps1
# Script pour tester le parser de roadmap

# Importer le module RoadmapParser
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "RoadmapParser.ps1"
. $modulePath

# Chemin du fichier de roadmap à analyser
$roadmapFilePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete_converted.md"

# Vérifier si le fichier existe
if (-not (Test-Path -Path $roadmapFilePath)) {
    Write-Error "Le fichier de roadmap n'existe pas: $roadmapFilePath"
    exit 1
}

# Créer le répertoire d'analyse s'il n'existe pas
$analysisDir = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\analysis"
if (-not (Test-Path -Path $analysisDir)) {
    New-Item -Path $analysisDir -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire d'analyse créé: $analysisDir" -ForegroundColor Green
}

# Analyser la structure du fichier de roadmap
Write-Host "Analyse de la structure du fichier de roadmap..." -ForegroundColor Cyan
$structureInfo = Get-RoadmapStructureInfo -FilePath $roadmapFilePath

# Afficher les informations de base
Write-Host "`nInformations de base:" -ForegroundColor Green
Write-Host "  Tâches totales: $($structureInfo.Progress.TotalTasks)"
Write-Host "  Tâches terminées: $($structureInfo.Progress.CompleteTasks)"
Write-Host "  Tâches en cours: $($structureInfo.Progress.IncompleteTasks)"
Write-Host "  Pourcentage de complétion: $($structureInfo.Progress.CompletionPercentage)%"

# Générer un rapport de structure
Write-Host "`nGénération d'un rapport de structure..." -ForegroundColor Cyan
$structureReportPath = Join-Path -Path $analysisDir -ChildPath "structure-report.md"
$structureReport = New-RoadmapStructureReport -StructureInfo $structureInfo -OutputPath $structureReportPath
Write-Host "Rapport de structure généré: $structureReportPath" -ForegroundColor Green

# Générer un rapport de progression
Write-Host "`nGénération d'un rapport de progression..." -ForegroundColor Cyan
$progressReportPath = Join-Path -Path $analysisDir -ChildPath "progress-report.md"
$progressReport = New-ProgressReport -FilePath $roadmapFilePath -OutputPath $progressReportPath
Write-Host "Rapport de progression généré: $progressReportPath" -ForegroundColor Green

# Parser le fichier de roadmap en structure de tâches
Write-Host "`nParsing du fichier de roadmap en structure de tâches..." -ForegroundColor Cyan
$taskStructure = ConvertFrom-MarkdownToTaskStructure -FilePath $roadmapFilePath

# Afficher les informations de la structure de tâches
Write-Host "`nInformations de la structure de tâches:" -ForegroundColor Green
Write-Host "  Titre: $($taskStructure.Title)"
Write-Host "  Nombre de tâches de premier niveau: $($taskStructure.Tasks.Count)"

# Fonction récursive pour compter les tâches
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
Write-Host "  Nombre total de tâches: $totalTasks"

# Convertir la structure de tâches en markdown
Write-Host "`nConversion de la structure de tâches en markdown..." -ForegroundColor Cyan
$outputMarkdownPath = Join-Path -Path $analysisDir -ChildPath "roadmap-regenerated.md"
$markdown = ConvertTo-MarkdownFromTaskStructure -TaskStructure $taskStructure -OutputPath $outputMarkdownPath
Write-Host "Markdown généré: $outputMarkdownPath" -ForegroundColor Green

# Tester la mise à jour du statut d'une tâche
Write-Host "`nTest de mise à jour du statut d'une tâche..." -ForegroundColor Cyan
$testFilePath = Join-Path -Path $analysisDir -ChildPath "roadmap-test.md"
Copy-Item -Path $roadmapFilePath -Destination $testFilePath -Force
$taskId = "1.1.1"
$newStatus = "Complete"
$updated = Update-TaskStatus -FilePath $testFilePath -TaskId $taskId -Status $newStatus -SaveChanges
Write-Host "Statut de la tâche $taskId mis à jour: $updated" -ForegroundColor $(if ($updated) { "Green" } else { "Red" })

# Tester l'ajout d'une nouvelle tâche
Write-Host "`nTest d'ajout d'une nouvelle tâche..." -ForegroundColor Cyan
$newTaskId = "1.1.1.4"
$newTaskTitle = "Nouvelle tâche de test"
$parentTaskId = "1.1.1"
$added = Add-Task -FilePath $testFilePath -TaskId $newTaskId -Title $newTaskTitle -ParentTaskId $parentTaskId -SaveChanges
Write-Host "Tâche $newTaskId ajoutée: $added" -ForegroundColor $(if ($added) { "Green" } else { "Red" })

# Tester la suppression d'une tâche
Write-Host "`nTest de suppression d'une tâche..." -ForegroundColor Cyan
$removed = Remove-Task -FilePath $testFilePath -TaskId $newTaskId -SaveChanges
Write-Host "Tâche $newTaskId supprimée: $removed" -ForegroundColor $(if ($removed) { "Green" } else { "Red" })

Write-Host "`nTests terminés." -ForegroundColor Cyan
