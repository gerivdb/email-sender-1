# Optimize-Performance.ps1
# Script pour optimiser les performances du systÃ¨me de dÃ©tection des tÃ¢ches

param (
    [Parameter(Mandatory = $false)]
    [string]$ConversationsFolder = ".\conversations",
    
    [Parameter(Mandatory = $false)]
    [int]$BatchSize = 5,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Chemins des fichiers
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$processConversationPath = Join-Path -Path $scriptPath -ChildPath "Process-Conversation.ps1"
$performanceLogPath = Join-Path -Path $scriptPath -ChildPath "performance-log.txt"

# VÃ©rifier que le dossier de conversations existe
if (-not (Test-Path -Path $ConversationsFolder)) {
    Write-Error "Le dossier de conversations '$ConversationsFolder' n'existe pas."
    exit 1
}

# VÃ©rifier que le script de traitement des conversations existe
if (-not (Test-Path -Path $processConversationPath)) {
    Write-Error "Le script Process-Conversation.ps1 n'a pas Ã©tÃ© trouvÃ© Ã  l'emplacement : $processConversationPath"
    exit 1
}

# Fonction pour journaliser les performances
function Write-Performance {
    param (
        [string]$Operation,
        [int]$FileCount,
        [int]$ElapsedMs,
        [int]$TaskCount
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $avgTimePerFile = [math]::Round($ElapsedMs / $FileCount)
    $avgTimePerTask = if ($TaskCount -gt 0) { [math]::Round($ElapsedMs / $TaskCount) } else { 0 }
    
    $logEntry = "[$timestamp] $Operation : $FileCount fichiers, $TaskCount tÃ¢ches, $ElapsedMs ms total, $avgTimePerFile ms/fichier, $avgTimePerTask ms/tÃ¢che"
    
    if (-not (Test-Path -Path $performanceLogPath)) {
        New-Item -Path $performanceLogPath -ItemType File -Force | Out-Null
    }
    
    Add-Content -Path $performanceLogPath -Value $logEntry
    
    return @{
        Operation = $Operation
        FileCount = $FileCount
        TaskCount = $TaskCount
        ElapsedMs = $ElapsedMs
        AvgTimePerFile = $avgTimePerFile
        AvgTimePerTask = $avgTimePerTask
    }
}

# Fonction pour traiter un lot de fichiers de conversation
function Invoke-ConversationBatch {
    param (
        [array]$Files,
        [switch]$Verbose
    )
    
    $startTime = Get-Date
    $totalTaskCount = 0
    
    foreach ($file in $Files) {
        if ($Verbose) {
            Write-Host "Traitement du fichier : $($file.FullName)"
        }
        
        $verboseParam = if ($Verbose) { "-Verbose" } else { "" }
        
        $command = "powershell -ExecutionPolicy Bypass -File `"$processConversationPath`" -ConversationFile `"$($file.FullName)`" $verboseParam"
        
        try {
            $result = Invoke-Expression $command
            $taskCount = $result.Count
            $totalTaskCount += $taskCount
            
            if ($Verbose) {
                Write-Host "  TÃ¢ches dÃ©tectÃ©es : $taskCount"
            }
        }
        catch {
            Write-Error "Erreur lors du traitement du fichier '$($file.FullName)' : $_"
        }
    }
    
    $endTime = Get-Date
    $elapsedMs = [math]::Round(($endTime - $startTime).TotalMilliseconds)
    
    return @{
        FileCount = $Files.Count
        TaskCount = $totalTaskCount
        ElapsedMs = $elapsedMs
    }
}

# Fonction pour optimiser les performances
function Optimize-ProcessingPerformance {
    param (
        [string]$FolderPath,
        [int]$BatchSize,
        [switch]$Verbose
    )
    
    Write-Host "Optimisation des performances du systÃ¨me de dÃ©tection des tÃ¢ches"
    Write-Host ""
    
    # Obtenir la liste des fichiers de conversation
    $conversationFiles = Get-ChildItem -Path $FolderPath -Filter "*.txt" | Where-Object { -not $_.PSIsContainer }
    
    if ($conversationFiles.Count -eq 0) {
        Write-Host "Aucun fichier de conversation trouvÃ© dans le dossier '$FolderPath'."
        return
    }
    
    Write-Host "Fichiers de conversation trouvÃ©s : $($conversationFiles.Count)"
    Write-Host "Taille de lot : $BatchSize"
    Write-Host ""
    
    # Traiter les fichiers un par un
    Write-Host "Test de performance : traitement individuel"
    $individualResults = @()
    
    foreach ($file in $conversationFiles) {
        $result = Invoke-ConversationBatch -Files @($file) -Verbose:$Verbose
        $individualResults += $result
    }
    
    $individualTotalFiles = ($individualResults | Measure-Object -Property FileCount -Sum).Sum
    $individualTotalTasks = ($individualResults | Measure-Object -Property TaskCount -Sum).Sum
    $individualTotalTime = ($individualResults | Measure-Object -Property ElapsedMs -Sum).Sum
    
    $individualPerformance = Write-Performance -Operation "Traitement individuel" -FileCount $individualTotalFiles -ElapsedMs $individualTotalTime -TaskCount $individualTotalTasks
    
    Write-Host "  Fichiers traitÃ©s : $($individualTotalFiles)"
    Write-Host "  TÃ¢ches dÃ©tectÃ©es : $($individualTotalTasks)"
    Write-Host "  Temps total : $($individualTotalTime) ms"
    Write-Host "  Temps moyen par fichier : $($individualPerformance.AvgTimePerFile) ms"
    Write-Host "  Temps moyen par tÃ¢che : $($individualPerformance.AvgTimePerTask) ms"
    Write-Host ""
    
    # Traiter les fichiers par lots
    Write-Host "Test de performance : traitement par lots"
    $batchResults = @()
    
    for ($i = 0; $i -lt $conversationFiles.Count; $i += $BatchSize) {
        $batch = $conversationFiles[$i..([Math]::Min($i + $BatchSize - 1, $conversationFiles.Count - 1))]
        $result = Invoke-ConversationBatch -Files $batch -Verbose:$Verbose
        $batchResults += $result
    }
    
    $batchTotalFiles = ($batchResults | Measure-Object -Property FileCount -Sum).Sum
    $batchTotalTasks = ($batchResults | Measure-Object -Property TaskCount -Sum).Sum
    $batchTotalTime = ($batchResults | Measure-Object -Property ElapsedMs -Sum).Sum
    
    $batchPerformance = Write-Performance -Operation "Traitement par lots" -FileCount $batchTotalFiles -ElapsedMs $batchTotalTime -TaskCount $batchTotalTasks
    
    Write-Host "  Fichiers traitÃ©s : $($batchTotalFiles)"
    Write-Host "  TÃ¢ches dÃ©tectÃ©es : $($batchTotalTasks)"
    Write-Host "  Temps total : $($batchTotalTime) ms"
    Write-Host "  Temps moyen par fichier : $($batchPerformance.AvgTimePerFile) ms"
    Write-Host "  Temps moyen par tÃ¢che : $($batchPerformance.AvgTimePerTask) ms"
    Write-Host ""
    
    # Comparer les performances
    $timeSaved = $individualTotalTime - $batchTotalTime
    $percentSaved = if ($individualTotalTime -gt 0) { [math]::Round(($timeSaved / $individualTotalTime) * 100) } else { 0 }
    
    Write-Host "Comparaison des performances :"
    Write-Host "  Temps Ã©conomisÃ© : $timeSaved ms ($percentSaved%)"
    
    if ($percentSaved > 0) {
        Write-Host "  Le traitement par lots est plus rapide." -ForegroundColor Green
        
        # Recommandation de taille de lot optimale
        if ($BatchSize > 1) {
            $avgTimePerBatch = ($batchResults | Measure-Object -Property ElapsedMs -Average).Average
            $recommendedBatchSize = [math]::Max(1, [math]::Min(20, [math]::Round($BatchSize * (1000 / $avgTimePerBatch))))
            
            Write-Host "  Taille de lot recommandÃ©e : $recommendedBatchSize" -ForegroundColor Cyan
        }
    }
    else {
        Write-Host "  Le traitement individuel est plus rapide." -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "Journal de performance sauvegardÃ© dans : $performanceLogPath"
}

# ExÃ©cuter la fonction principale
Optimize-ProcessingPerformance -FolderPath $ConversationsFolder -BatchSize $BatchSize -Verbose:$Verbose


