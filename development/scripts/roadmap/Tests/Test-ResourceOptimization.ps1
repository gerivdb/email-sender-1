# Test-ResourceOptimization.ps1
# Script de test pour l'optimisation des ressources
# Version: 1.0
# Date: 2025-05-15

<#
.SYNOPSIS
    Teste les fonctionnalités d'optimisation des ressources.

.DESCRIPTION
    Ce script teste les fonctionnalités d'optimisation des ressources,
    notamment la gestion intelligente de la mémoire, la prioritisation des tâches et le monitoring des performances.

.NOTES
    Auteur: Équipe de développement
    Version: 1.0
#>

# Importer les modules requis
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$performancePath = Join-Path -Path $parentPath -ChildPath "performance"
$optimizeResourceUsagePath = Join-Path -Path $performancePath -ChildPath "Optimize-ResourceUsage.ps1"

if (Test-Path $optimizeResourceUsagePath) {
    . $optimizeResourceUsagePath
    Write-Host "Module Optimize-ResourceUsage.ps1 chargé." -ForegroundColor Green
} else {
    Write-Error "Module Optimize-ResourceUsage.ps1 introuvable à l'emplacement: $optimizeResourceUsagePath"
    exit
}

# Fonction pour tester la gestion intelligente de la mémoire
function Test-IntelligentMemoryManagement {
    <#
    .SYNOPSIS
        Teste la gestion intelligente de la mémoire.

    .DESCRIPTION
        Cette fonction teste la gestion intelligente de la mémoire en simulant une utilisation intensive de la mémoire
        et en vérifiant que la gestion de la mémoire fonctionne correctement.

    .PARAMETER DurationSeconds
        La durée du test en secondes.
        Par défaut, 30 secondes.

    .PARAMETER MaxMemoryUsageMB
        L'utilisation maximale de mémoire en mégaoctets.
        Par défaut, 512 Mo.

    .PARAMETER MemoryReleaseThresholdMB
        Le seuil d'utilisation de la mémoire à partir duquel la libération est déclenchée.
        Par défaut, 384 Mo (75% de MaxMemoryUsageMB).

    .EXAMPLE
        Test-IntelligentMemoryManagement -DurationSeconds 60 -MaxMemoryUsageMB 1024 -MemoryReleaseThresholdMB 768
        Teste la gestion intelligente de la mémoire pendant 60 secondes avec une utilisation maximale de 1 Go et un seuil de libération de 768 Mo.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$DurationSeconds = 30,

        [Parameter(Mandatory = $false)]
        [int]$MaxMemoryUsageMB = 512,

        [Parameter(Mandatory = $false)]
        [int]$MemoryReleaseThresholdMB = 0
    )

    try {
        # Activer la gestion intelligente de la mémoire
        Write-Host "Activation de la gestion intelligente de la mémoire..." -ForegroundColor Cyan
        $memoryManager = Enable-IntelligentMemoryManagement -MaxMemoryUsageMB $MaxMemoryUsageMB -MemoryReleaseThresholdMB $MemoryReleaseThresholdMB -MonitoringIntervalSeconds 2
        
        if ($null -eq $memoryManager) {
            Write-Error "Échec de l'activation de la gestion intelligente de la mémoire."
            return $null
        }
        
        Write-Host "Gestion intelligente de la mémoire activée." -ForegroundColor Green
        Write-Host "Utilisation maximale de mémoire: $MaxMemoryUsageMB Mo" -ForegroundColor Green
        Write-Host "Seuil de libération de mémoire: $($memoryManager.Config.MemoryReleaseThresholdMB) Mo" -ForegroundColor Green
        
        # Simuler une utilisation intensive de la mémoire
        Write-Host "Simulation d'une utilisation intensive de la mémoire pendant $DurationSeconds secondes..." -ForegroundColor Cyan
        $startTime = Get-Date
        $endTime = $startTime.AddSeconds($DurationSeconds)
        $memoryObjects = @()
        
        while ((Get-Date) -lt $endTime) {
            # Allouer de la mémoire
            $memoryObjects += "X" * 1MB * (Get-Random -Minimum 10 -Maximum 50)
            
            # Afficher les statistiques actuelles
            $stats = $memoryManager.GetStatistics.Invoke()
            Write-Host "Utilisation mémoire: $([Math]::Round($stats.CurrentMemoryUsage.MemoryUsage.WorkingSetMB, 2)) Mo, Libérations: $($stats.MemoryReleaseCount)" -ForegroundColor Yellow
            
            # Attendre un peu
            Start-Sleep -Seconds 1
        }
        
        # Obtenir les statistiques finales
        $finalStats = $memoryManager.GetStatistics.Invoke()
        
        # Arrêter la gestion de la mémoire
        $memoryManager.StopMonitoring.Invoke()
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            DurationSeconds = $DurationSeconds
            MaxMemoryUsageMB = $MaxMemoryUsageMB
            MemoryReleaseThresholdMB = $memoryManager.Config.MemoryReleaseThresholdMB
            MemoryReleaseCount = $finalStats.MemoryReleaseCount
            TotalMemoryReleasedMB = $finalStats.TotalMemoryReleasedMB
            AverageMemoryUsageMB = $finalStats.AverageMemoryUsage
            TestDate = Get-Date
        }
        
        # Afficher les résultats
        Write-Host
        Write-Host "Test de gestion intelligente de la mémoire terminé." -ForegroundColor Cyan
        Write-Host "Nombre de libérations de mémoire: $($finalStats.MemoryReleaseCount)" -ForegroundColor Green
        Write-Host "Total de mémoire libérée: $($finalStats.TotalMemoryReleasedMB) Mo" -ForegroundColor Green
        Write-Host "Utilisation moyenne de mémoire: $([Math]::Round($finalStats.AverageMemoryUsage, 2)) Mo" -ForegroundColor Green
        
        return $result
    } catch {
        Write-Error "Échec du test de gestion intelligente de la mémoire: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour tester la prioritisation des tâches
function Test-TaskPrioritization {
    <#
    .SYNOPSIS
        Teste la prioritisation des tâches.

    .DESCRIPTION
        Cette fonction teste la prioritisation des tâches en créant une roadmap de test
        et en vérifiant que la prioritisation des tâches fonctionne correctement.

    .PARAMETER TaskCount
        Le nombre de tâches à générer pour le test.
        Par défaut, 100 tâches.

    .PARAMETER PriorityLevels
        Le nombre de niveaux de priorité.
        Par défaut, 5 niveaux.

    .PARAMETER OutputPath
        Le chemin où sauvegarder les résultats du test.
        Si non spécifié, un dossier temporaire est utilisé.

    .EXAMPLE
        Test-TaskPrioritization -TaskCount 200 -PriorityLevels 10
        Teste la prioritisation des tâches avec 200 tâches et 10 niveaux de priorité.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$TaskCount = 100,

        [Parameter(Mandatory = $false)]
        [int]$PriorityLevels = 5,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )

    try {
        # Déterminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = Join-Path -Path $env:TEMP -ChildPath "TaskPrioritizationTest"
        }
        
        # Créer le dossier de sortie s'il n'existe pas
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Créer une roadmap de test
        $roadmapPath = Join-Path -Path $OutputPath -ChildPath "test-roadmap.md"
        
        # Créer le contenu de la roadmap
        $content = @()
        $content += "# Roadmap de test pour la prioritisation des tâches"
        $content += ""
        $content += "Cette roadmap est générée automatiquement pour tester la prioritisation des tâches."
        $content += ""
        
        # Générer les tâches
        for ($i = 1; $i -le $TaskCount; $i++) {
            $status = if ($i % 3 -eq 0) { "[x]" } else { "[ ]" }
            $priority = switch ($i % 3) {
                0 { "high" }
                1 { "medium" }
                2 { "low" }
            }
            $complexity = switch ($i % 3) {
                0 { "high" }
                1 { "medium" }
                2 { "low" }
            }
            $dueDate = (Get-Date).AddDays(Get-Random -Minimum 1 -Maximum 60).ToString("yyyy-MM-dd")
            
            $content += "- $status **$i** Tâche de test $i (#priority:$priority #complexity:$complexity #due:$dueDate)"
            
            # Ajouter des sous-tâches pour certaines tâches
            if ($i % 10 -eq 0) {
                for ($j = 1; $j -le 5; $j++) {
                    $subStatus = if ($j % 2 -eq 0) { "[x]" } else { "[ ]" }
                    $content += "  - $subStatus **$i.$j** Sous-tâche $j de la tâche $i"
                }
            }
        }
        
        # Écrire le contenu dans le fichier
        $content | Out-File -FilePath $roadmapPath -Encoding UTF8
        
        # Activer la prioritisation des tâches
        Write-Host "Activation de la prioritisation des tâches..." -ForegroundColor Cyan
        $prioritizer = Enable-TaskPrioritization -RoadmapPath $roadmapPath -PriorityLevels $PriorityLevels
        
        if ($null -eq $prioritizer) {
            Write-Error "Échec de l'activation de la prioritisation des tâches."
            return $null
        }
        
        Write-Host "Prioritisation des tâches activée." -ForegroundColor Green
        Write-Host "Nombre de tâches: $($prioritizer.PrioritizedTasks.Count)" -ForegroundColor Green
        Write-Host "Niveaux de priorité: $PriorityLevels" -ForegroundColor Green
        
        # Obtenir les tâches prioritaires
        $topTasks = $prioritizer.GetTopPriorityTasks.Invoke(10)
        
        # Afficher les tâches prioritaires
        Write-Host
        Write-Host "Top 10 tâches prioritaires:" -ForegroundColor Cyan
        
        foreach ($task in $topTasks) {
            Write-Host "  Tâche $($task.Id): Priorité $($task.Priority)" -ForegroundColor Yellow
        }
        
        # Recalculer les priorités
        Write-Host
        Write-Host "Recalcul des priorités..." -ForegroundColor Cyan
        $updatedTasks = $prioritizer.RecalculatePriorities.Invoke()
        
        # Obtenir les nouvelles tâches prioritaires
        $newTopTasks = $prioritizer.GetTopPriorityTasks.Invoke(10)
        
        # Afficher les nouvelles tâches prioritaires
        Write-Host
        Write-Host "Top 10 tâches prioritaires après recalcul:" -ForegroundColor Cyan
        
        foreach ($task in $newTopTasks) {
            Write-Host "  Tâche $($task.Id): Priorité $($task.Priority)" -ForegroundColor Yellow
        }
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            TaskCount = $TaskCount
            PriorityLevels = $PriorityLevels
            TotalTasks = $prioritizer.PrioritizedTasks.Count
            TopPriorityTasks = $topTasks
            NewTopPriorityTasks = $newTopTasks
            RoadmapPath = $roadmapPath
            ResultFilePath = $prioritizer.ResultFilePath
            TestDate = Get-Date
        }
        
        return $result
    } catch {
        Write-Error "Échec du test de prioritisation des tâches: $($_.Exception.Message)"
        return $null
    }
}

# Fonction pour tester le monitoring des performances
function Test-PerformanceMonitoring {
    <#
    .SYNOPSIS
        Teste le monitoring des performances.

    .DESCRIPTION
        Cette fonction teste le monitoring des performances en simulant une charge de travail
        et en vérifiant que le monitoring des performances fonctionne correctement.

    .PARAMETER DurationSeconds
        La durée du test en secondes.
        Par défaut, 30 secondes.

    .PARAMETER MonitoringIntervalSeconds
        L'intervalle de surveillance des performances en secondes.
        Par défaut, 2 secondes.

    .PARAMETER EnableDashboard
        Indique si le tableau de bord en temps réel est activé.
        Par défaut, $true.

    .EXAMPLE
        Test-PerformanceMonitoring -DurationSeconds 60 -MonitoringIntervalSeconds 5 -EnableDashboard $true
        Teste le monitoring des performances pendant 60 secondes avec un intervalle de 5 secondes et le tableau de bord activé.

    .OUTPUTS
        PSObject
    #>
    [CmdletBinding()]
    [OutputType([PSObject])]
    param (
        [Parameter(Mandatory = $false)]
        [int]$DurationSeconds = 30,

        [Parameter(Mandatory = $false)]
        [int]$MonitoringIntervalSeconds = 2,

        [Parameter(Mandatory = $false)]
        [bool]$EnableDashboard = $true
    )

    try {
        # Activer le monitoring des performances
        Write-Host "Activation du monitoring des performances..." -ForegroundColor Cyan
        $monitor = Enable-PerformanceMonitoring -MonitoringIntervalSeconds $MonitoringIntervalSeconds -EnableDashboard $EnableDashboard
        
        if ($null -eq $monitor) {
            Write-Error "Échec de l'activation du monitoring des performances."
            return $null
        }
        
        Write-Host "Monitoring des performances activé." -ForegroundColor Green
        Write-Host "Intervalle de surveillance: $MonitoringIntervalSeconds secondes" -ForegroundColor Green
        Write-Host "Tableau de bord activé: $EnableDashboard" -ForegroundColor Green
        
        if ($EnableDashboard) {
            Write-Host "Ouverture du tableau de bord..." -ForegroundColor Cyan
            $monitor.OpenDashboard.Invoke()
        }
        
        # Simuler une charge de travail
        Write-Host "Simulation d'une charge de travail pendant $DurationSeconds secondes..." -ForegroundColor Cyan
        $startTime = Get-Date
        $endTime = $startTime.AddSeconds($DurationSeconds)
        
        while ((Get-Date) -lt $endTime) {
            # Simuler une charge CPU
            $cpuLoad = Get-Random -Minimum 1 -Maximum 10
            for ($i = 0; $i -lt $cpuLoad; $i++) {
                $null = 1..1000000 | ForEach-Object { $_ * $_ }
            }
            
            # Simuler une charge mémoire
            $memoryLoad = Get-Random -Minimum 1 -Maximum 5
            $memoryObjects = @()
            for ($i = 0; $i -lt $memoryLoad; $i++) {
                $memoryObjects += "X" * 1MB
            }
            
            # Simuler des opérations disque
            $diskLoad = Get-Random -Minimum 1 -Maximum 3
            for ($i = 0; $i -lt $diskLoad; $i++) {
                $tempFile = [System.IO.Path]::GetTempFileName()
                "X" * 1MB | Out-File -FilePath $tempFile -Encoding UTF8
                $content = Get-Content -Path $tempFile
                Remove-Item -Path $tempFile -Force
            }
            
            # Afficher les métriques actuelles
            $metrics = $monitor.GetCurrentMetrics.Invoke()
            if ($null -ne $metrics) {
                Write-Host "CPU: $($metrics.CPU.CurrentValue)%, Mémoire: $($metrics.Memory.CurrentValue)%, Disque: $($metrics.Disk.CurrentValue)%" -ForegroundColor Yellow
            }
            
            # Attendre un peu
            Start-Sleep -Seconds 1
        }
        
        # Exporter les données de performance
        Write-Host
        Write-Host "Exportation des données de performance..." -ForegroundColor Cyan
        $csvPath = Join-Path -Path $env:TEMP -ChildPath "performance-data.csv"
        $jsonPath = Join-Path -Path $env:TEMP -ChildPath "performance-data.json"
        $htmlPath = Join-Path -Path $env:TEMP -ChildPath "performance-report.html"
        
        $csvExport = $monitor.ExportPerformanceData.Invoke($csvPath, "CSV")
        $jsonExport = $monitor.ExportPerformanceData.Invoke($jsonPath, "JSON")
        $htmlExport = $monitor.ExportPerformanceData.Invoke($htmlPath, "HTML")
        
        Write-Host "Données CSV exportées vers: $csvPath" -ForegroundColor Green
        Write-Host "Données JSON exportées vers: $jsonPath" -ForegroundColor Green
        Write-Host "Rapport HTML exporté vers: $htmlPath" -ForegroundColor Green
        
        # Obtenir les alertes récentes
        $alerts = $monitor.GetRecentAlerts.Invoke()
        
        Write-Host
        Write-Host "Alertes récentes:" -ForegroundColor Cyan
        
        if ($alerts.Count -eq 0) {
            Write-Host "  Aucune alerte récente." -ForegroundColor Yellow
        } else {
            foreach ($alert in $alerts) {
                Write-Host "  $($alert.Timestamp): $($alert.Message)" -ForegroundColor Yellow
            }
        }
        
        # Arrêter le monitoring
        $monitor.StopMonitoring.Invoke()
        
        # Créer l'objet de résultat
        $result = [PSCustomObject]@{
            DurationSeconds = $DurationSeconds
            MonitoringIntervalSeconds = $MonitoringIntervalSeconds
            EnableDashboard = $EnableDashboard
            CSVExportPath = $csvPath
            JSONExportPath = $jsonPath
            HTMLReportPath = $htmlPath
            AlertCount = $alerts.Count
            TestDate = Get-Date
        }
        
        return $result
    } catch {
        Write-Error "Échec du test de monitoring des performances: $($_.Exception.Message)"
        return $null
    }
}

# Exécuter les tests
Write-Host "=== TESTS D'OPTIMISATION DES RESSOURCES ===" -ForegroundColor Cyan
Write-Host

# Test de la gestion intelligente de la mémoire
Write-Host "=== TEST DE LA GESTION INTELLIGENTE DE LA MÉMOIRE ===" -ForegroundColor Cyan
$memoryResult = Test-IntelligentMemoryManagement -DurationSeconds 20 -MaxMemoryUsageMB 256
Write-Host

# Test de la prioritisation des tâches
Write-Host "=== TEST DE LA PRIORITISATION DES TÂCHES ===" -ForegroundColor Cyan
$prioritizationResult = Test-TaskPrioritization -TaskCount 50 -PriorityLevels 5
Write-Host

# Test du monitoring des performances
Write-Host "=== TEST DU MONITORING DES PERFORMANCES ===" -ForegroundColor Cyan
$monitoringResult = Test-PerformanceMonitoring -DurationSeconds 20 -MonitoringIntervalSeconds 2 -EnableDashboard $true
Write-Host

# Afficher les résultats
Write-Host "=== RÉSUMÉ DES TESTS ===" -ForegroundColor Cyan
Write-Host

if ($null -ne $memoryResult) {
    Write-Host "Gestion intelligente de la mémoire:" -ForegroundColor Yellow
    Write-Host "  Nombre de libérations: $($memoryResult.MemoryReleaseCount)" -ForegroundColor Green
    Write-Host "  Total de mémoire libérée: $($memoryResult.TotalMemoryReleasedMB) Mo" -ForegroundColor Green
    Write-Host "  Utilisation moyenne: $([Math]::Round($memoryResult.AverageMemoryUsageMB, 2)) Mo" -ForegroundColor Green
    Write-Host
}

if ($null -ne $prioritizationResult) {
    Write-Host "Prioritisation des tâches:" -ForegroundColor Yellow
    Write-Host "  Nombre total de tâches: $($prioritizationResult.TotalTasks)" -ForegroundColor Green
    Write-Host "  Tâche la plus prioritaire: $($prioritizationResult.TopPriorityTasks[0].Id) (Priorité $($prioritizationResult.TopPriorityTasks[0].Priority))" -ForegroundColor Green
    Write-Host "  Roadmap de test: $($prioritizationResult.RoadmapPath)" -ForegroundColor Green
    Write-Host
}

if ($null -ne $monitoringResult) {
    Write-Host "Monitoring des performances:" -ForegroundColor Yellow
    Write-Host "  Durée du test: $($monitoringResult.DurationSeconds) secondes" -ForegroundColor Green
    Write-Host "  Nombre d'alertes: $($monitoringResult.AlertCount)" -ForegroundColor Green
    Write-Host "  Rapport HTML: $($monitoringResult.HTMLReportPath)" -ForegroundColor Green
    Write-Host
}
