# Test-PerformanceComparison.ps1
# Script pour comparer les performances des différentes versions de la fonction de conversion markdown

# Importer les fonctions à tester
$baseFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmap.ps1"
$extendedFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapExtended.ps1"
$optimizedFunctionPath = Join-Path -Path $PSScriptRoot -ChildPath "..\functions\ConvertFrom-MarkdownToRoadmapOptimized.ps1"

. $baseFunctionPath
. $extendedFunctionPath
. $optimizedFunctionPath

# Créer un répertoire temporaire pour les tests
$testDir = Join-Path -Path $PSScriptRoot -ChildPath "temp"
if (-not (Test-Path -Path $testDir)) {
    New-Item -Path $testDir -ItemType Directory -Force | Out-Null
}

# Fonction pour générer un fichier markdown de test de taille spécifiée
function New-TestMarkdownFile {
    param (
        [string]$FilePath,
        [int]$SectionCount = 5,
        [int]$TasksPerSection = 20,
        [int]$SubTasksPerTask = 5,
        [int]$SubSubTasksPerSubTask = 3
    )
    
    $sb = [System.Text.StringBuilder]::new()
    
    # Ajouter le titre et la description
    $sb.AppendLine("# Roadmap de Test Performance") | Out-Null
    $sb.AppendLine("") | Out-Null
    $sb.AppendLine("Ceci est une roadmap générée pour tester les performances des fonctions de conversion.") | Out-Null
    $sb.AppendLine("") | Out-Null
    
    # Générer les sections
    for ($s = 1; $s -le $SectionCount; $s++) {
        $sb.AppendLine("## Section $s") | Out-Null
        $sb.AppendLine("") | Out-Null
        
        # Générer les tâches
        for ($t = 1; $t -le $TasksPerSection; $t++) {
            $taskId = "S$s-T$t"
            $status = switch ($t % 4) {
                0 { "[ ]" }
                1 { "[x]" }
                2 { "[~]" }
                3 { "[!]" }
            }
            
            $sb.AppendLine("- $status **$taskId** Tâche $t de la section $s") | Out-Null
            
            # Générer les sous-tâches
            for ($st = 1; $st -le $SubTasksPerTask; $st++) {
                $subTaskId = "$taskId.$st"
                $subStatus = switch ($st % 4) {
                    0 { "[ ]" }
                    1 { "[x]" }
                    2 { "[~]" }
                    3 { "[!]" }
                }
                
                $sb.AppendLine("  - $subStatus **$subTaskId** Sous-tâche $st de la tâche $t") | Out-Null
                
                # Générer les sous-sous-tâches
                for ($sst = 1; $sst -le $SubSubTasksPerSubTask; $sst++) {
                    $subSubTaskId = "$subTaskId.$sst"
                    $subSubStatus = switch ($sst % 4) {
                        0 { "[ ]" }
                        1 { "[x]" }
                        2 { "[~]" }
                        3 { "[!]" }
                    }
                    
                    # Ajouter des métadonnées aléatoires
                    $metadata = @()
                    if ($sst % 3 -eq 0) {
                        $metadata += "@john"
                    }
                    if ($sst % 5 -eq 0) {
                        $metadata += "#important"
                    }
                    if ($sst % 7 -eq 0) {
                        $metadata += "P$($sst % 3 + 1)"
                    }
                    if ($sst % 11 -eq 0) {
                        $metadata += "@date:2023-07-$($sst % 30 + 1)"
                    }
                    if ($sst % 13 -eq 0 -and $s -gt 1) {
                        $metadata += "@depends:S$($s-1)-T$t"
                    }
                    
                    $metadataStr = if ($metadata.Count -gt 0) { " " + ($metadata -join " ") } else { "" }
                    
                    $sb.AppendLine("    - $subSubStatus **$subSubTaskId** Sous-sous-tâche $sst de la sous-tâche $st$metadataStr") | Out-Null
                }
            }
            
            $sb.AppendLine("") | Out-Null
        }
    }
    
    # Écrire le contenu dans le fichier
    $sb.ToString() | Out-File -FilePath $FilePath -Encoding UTF8
    
    # Retourner des statistiques sur le fichier généré
    $stats = [PSCustomObject]@{
        FilePath = $FilePath
        SectionCount = $SectionCount
        TaskCount = $SectionCount * $TasksPerSection
        SubTaskCount = $SectionCount * $TasksPerSection * $SubTasksPerTask
        SubSubTaskCount = $SectionCount * $TasksPerSection * $SubTasksPerTask * $SubSubTasksPerSubTask
        TotalTaskCount = $SectionCount * $TasksPerSection * (1 + $SubTasksPerTask * (1 + $SubSubTasksPerSubTask))
        FileSizeBytes = (Get-Item -Path $FilePath).Length
        FileSizeKB = [Math]::Round((Get-Item -Path $FilePath).Length / 1KB, 2)
    }
    
    return $stats
}

# Fonction pour mesurer les performances d'une fonction
function Measure-FunctionPerformance {
    param (
        [string]$FunctionName,
        [string]$FilePath,
        [hashtable]$Parameters = @{},
        [int]$Iterations = 1
    )
    
    $results = @()
    
    for ($i = 1; $i -le $Iterations; $i++) {
        # Forcer le garbage collector avant chaque test
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        
        $startMemory = [System.GC]::GetTotalMemory($true)
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Exécuter la fonction
        $Parameters["FilePath"] = $FilePath
        $result = & $FunctionName @Parameters
        
        $stopwatch.Stop()
        $endMemory = [System.GC]::GetTotalMemory($true)
        
        $memoryUsed = $endMemory - $startMemory
        
        $results += [PSCustomObject]@{
            Iteration = $i
            ElapsedMilliseconds = $stopwatch.ElapsedMilliseconds
            MemoryUsedBytes = $memoryUsed
            MemoryUsedMB = [Math]::Round($memoryUsed / 1MB, 2)
            TaskCount = if ($result.AllTasks) { $result.AllTasks.Count } else { ($result.Sections | ForEach-Object { $_.Tasks.Count }) -join "+" }
        }
    }
    
    # Calculer les moyennes
    $avgTime = ($results | Measure-Object -Property ElapsedMilliseconds -Average).Average
    $avgMemory = ($results | Measure-Object -Property MemoryUsedBytes -Average).Average
    
    $summary = [PSCustomObject]@{
        FunctionName = $FunctionName
        Iterations = $Iterations
        AverageTimeMs = [Math]::Round($avgTime, 2)
        AverageMemoryMB = [Math]::Round($avgMemory / 1MB, 2)
        Results = $results
    }
    
    return $summary
}

try {
    # Générer des fichiers de test de différentes tailles
    Write-Host "Génération des fichiers de test..." -ForegroundColor Cyan
    
    $smallFilePath = Join-Path -Path $testDir -ChildPath "small.md"
    $smallFileStats = New-TestMarkdownFile -FilePath $smallFilePath -SectionCount 2 -TasksPerSection 5 -SubTasksPerTask 3 -SubSubTasksPerSubTask 2
    
    $mediumFilePath = Join-Path -Path $testDir -ChildPath "medium.md"
    $mediumFileStats = New-TestMarkdownFile -FilePath $mediumFilePath -SectionCount 5 -TasksPerSection 10 -SubTasksPerTask 5 -SubSubTasksPerSubTask 3
    
    $largeFilePath = Join-Path -Path $testDir -ChildPath "large.md"
    $largeFileStats = New-TestMarkdownFile -FilePath $largeFilePath -SectionCount 10 -TasksPerSection 20 -SubTasksPerTask 8 -SubSubTasksPerSubTask 5
    
    # Afficher les statistiques des fichiers générés
    Write-Host "`nStatistiques des fichiers générés:" -ForegroundColor Green
    Write-Host "Petit fichier: $($smallFileStats.TotalTaskCount) tâches, $($smallFileStats.FileSizeKB) KB" -ForegroundColor Yellow
    Write-Host "Fichier moyen: $($mediumFileStats.TotalTaskCount) tâches, $($mediumFileStats.FileSizeKB) KB" -ForegroundColor Yellow
    Write-Host "Grand fichier: $($largeFileStats.TotalTaskCount) tâches, $($largeFileStats.FileSizeKB) KB" -ForegroundColor Yellow
    
    # Tester les performances sur le petit fichier
    Write-Host "`nTest de performances sur le petit fichier:" -ForegroundColor Cyan
    
    $baseParams = @{}
    $extendedParams = @{ IncludeMetadata = $true; DetectDependencies = $true; ValidateStructure = $true }
    $optimizedParams = @{ IncludeMetadata = $true; DetectDependencies = $true; ValidateStructure = $true; BlockSize = 500 }
    
    $basePerf = Measure-FunctionPerformance -FunctionName "ConvertFrom-MarkdownToRoadmap" -FilePath $smallFilePath -Parameters $baseParams -Iterations 3
    $extendedPerf = Measure-FunctionPerformance -FunctionName "ConvertFrom-MarkdownToRoadmapExtended" -FilePath $smallFilePath -Parameters $extendedParams -Iterations 3
    $optimizedPerf = Measure-FunctionPerformance -FunctionName "ConvertFrom-MarkdownToRoadmapOptimized" -FilePath $smallFilePath -Parameters $optimizedParams -Iterations 3
    
    Write-Host "Fonction de base: $($basePerf.AverageTimeMs) ms, $($basePerf.AverageMemoryMB) MB" -ForegroundColor Yellow
    Write-Host "Fonction étendue: $($extendedPerf.AverageTimeMs) ms, $($extendedPerf.AverageMemoryMB) MB" -ForegroundColor Yellow
    Write-Host "Fonction optimisée: $($optimizedPerf.AverageTimeMs) ms, $($optimizedPerf.AverageMemoryMB) MB" -ForegroundColor Yellow
    
    # Tester les performances sur le fichier moyen
    Write-Host "`nTest de performances sur le fichier moyen:" -ForegroundColor Cyan
    
    $basePerf = Measure-FunctionPerformance -FunctionName "ConvertFrom-MarkdownToRoadmap" -FilePath $mediumFilePath -Parameters $baseParams -Iterations 2
    $extendedPerf = Measure-FunctionPerformance -FunctionName "ConvertFrom-MarkdownToRoadmapExtended" -FilePath $mediumFilePath -Parameters $extendedParams -Iterations 2
    $optimizedPerf = Measure-FunctionPerformance -FunctionName "ConvertFrom-MarkdownToRoadmapOptimized" -FilePath $mediumFilePath -Parameters $optimizedParams -Iterations 2
    
    Write-Host "Fonction de base: $($basePerf.AverageTimeMs) ms, $($basePerf.AverageMemoryMB) MB" -ForegroundColor Yellow
    Write-Host "Fonction étendue: $($extendedPerf.AverageTimeMs) ms, $($extendedPerf.AverageMemoryMB) MB" -ForegroundColor Yellow
    Write-Host "Fonction optimisée: $($optimizedPerf.AverageTimeMs) ms, $($optimizedPerf.AverageMemoryMB) MB" -ForegroundColor Yellow
    
    # Tester les performances sur le grand fichier
    Write-Host "`nTest de performances sur le grand fichier:" -ForegroundColor Cyan
    
    $basePerf = Measure-FunctionPerformance -FunctionName "ConvertFrom-MarkdownToRoadmap" -FilePath $largeFilePath -Parameters $baseParams -Iterations 1
    $extendedPerf = Measure-FunctionPerformance -FunctionName "ConvertFrom-MarkdownToRoadmapExtended" -FilePath $largeFilePath -Parameters $extendedParams -Iterations 1
    $optimizedPerf = Measure-FunctionPerformance -FunctionName "ConvertFrom-MarkdownToRoadmapOptimized" -FilePath $largeFilePath -Parameters $optimizedParams -Iterations 1
    
    Write-Host "Fonction de base: $($basePerf.AverageTimeMs) ms, $($basePerf.AverageMemoryMB) MB" -ForegroundColor Yellow
    Write-Host "Fonction étendue: $($extendedPerf.AverageTimeMs) ms, $($extendedPerf.AverageMemoryMB) MB" -ForegroundColor Yellow
    Write-Host "Fonction optimisée: $($optimizedPerf.AverageTimeMs) ms, $($optimizedPerf.AverageMemoryMB) MB" -ForegroundColor Yellow
    
    Write-Host "`nTests de performance terminés." -ForegroundColor Green
}
catch {
    Write-Host "Erreur lors des tests de performance: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
}
finally {
    # Nettoyer les fichiers de test
    if (Test-Path -Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force
        Write-Host "`nRépertoire de test nettoyé: $testDir" -ForegroundColor Gray
    }
}
