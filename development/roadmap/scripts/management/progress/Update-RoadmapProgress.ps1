<#
.SYNOPSIS
    Met Ã  jour automatiquement les pourcentages de progression dans un fichier de roadmap.

.DESCRIPTION
    Ce script analyse un fichier de roadmap au format Markdown et met Ã  jour les pourcentages
    de progression en fonction de l'Ã©tat des sous-tÃ¢ches. Il calcule la progression des tÃ¢ches,
    sous-sections et sections principales.

.PARAMETER MarkdownPath
    Chemin vers le fichier Markdown de la roadmap.

.EXAMPLE
    .\Update-RoadmapProgress.ps1 -MarkdownPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\Roadmap\roadmap_complete.md"

.NOTES
    Auteur: Ã‰quipe DevOps
    Date: 2025-04-20
    Version: 1.0.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$MarkdownPath
)

function Update-RoadmapProgress {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$MarkdownPath
    )

    # VÃ©rifier si le fichier existe
    if (-not (Test-Path -Path $MarkdownPath)) {
        throw "Le fichier '$MarkdownPath' n'existe pas."
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $MarkdownPath -Encoding UTF8

    # Structure pour stocker les informations de progression
    $progressInfo = @{
        sections = @{}
        subsections = @{}
        tasks = @{}
    }

    # Analyser les sous-tÃ¢ches et calculer leur progression
    for ($i = 0; $i -lt $content.Count; $i++) {
        $line = $content[$i]
        
        # DÃ©tecter les sous-tÃ¢ches
        if ($line -match '- \[([ x])\] \*\*Sous-tÃ¢che (\d+\.\d+)\*\*: (.+?) \((\d+)h\)') {
            $completed = $matches[1] -eq 'x'
            $subtaskId = $matches[2]
            $taskId = $subtaskId -replace '\.\d+$', ''
            
            # Extraire l'ID de la tÃ¢che parente
            $taskPattern = '#### (\d+\.\d+\.\d+) '
            for ($j = $i; $j -ge 0; $j--) {
                if ($content[$j] -match $taskPattern) {
                    $taskId = $matches[1]
                    break
                }
            }
            
            # Mettre Ã  jour les informations de progression de la tÃ¢che
            if (-not $progressInfo.tasks.ContainsKey($taskId)) {
                $progressInfo.tasks[$taskId] = @{
                    total = 0
                    completed = 0
                }
            }
            
            $progressInfo.tasks[$taskId].total++
            if ($completed) {
                $progressInfo.tasks[$taskId].completed++
            }
        }
    }

    # Calculer la progression des tÃ¢ches
    foreach ($taskId in $progressInfo.tasks.Keys) {
        $taskInfo = $progressInfo.tasks[$taskId]
        $taskProgress = if ($taskInfo.total -gt 0) { [math]::Round(($taskInfo.completed / $taskInfo.total) * 100) } else { 0 }
        
        # DÃ©terminer le statut en fonction de la progression
        $taskStatus = switch ($taskProgress) {
            0 { "Non commencÃ©" }
            { $_ -ge 1 -and $_ -lt 90 } { "En cours" }
            { $_ -ge 90 -and $_ -lt 100 } { "Presque terminÃ©" }
            100 { "TerminÃ©" }
            default { "Non commencÃ©" }
        }
        
        # Mettre Ã  jour la progression de la tÃ¢che dans le contenu
        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match "#### $taskId ") {
                # Trouver la ligne de progression
                for ($j = $i + 1; $j -lt $content.Count; $j++) {
                    if ($content[$j] -match '\*\*Progression\*\*: \d+% - \*.+?\*') {
                        $content[$j] = $content[$j] -replace '\*\*Progression\*\*: \d+% - \*.+?\*', "**Progression**: $taskProgress% - *$taskStatus*"
                        break
                    }
                }
                break
            }
        }
        
        # Extraire l'ID de la sous-section parente
        $subsectionId = $taskId -replace '\.\d+$', ''
        
        # Mettre Ã  jour les informations de progression de la sous-section
        if (-not $progressInfo.subsections.ContainsKey($subsectionId)) {
            $progressInfo.subsections[$subsectionId] = @{
                tasks = @()
            }
        }
        
        $progressInfo.subsections[$subsectionId].tasks += @{
            id = $taskId
            progress = $taskProgress
        }
    }

    # Calculer la progression des sous-sections
    foreach ($subsectionId in $progressInfo.subsections.Keys) {
        $subsectionInfo = $progressInfo.subsections[$subsectionId]
        $totalProgress = 0
        $taskCount = 0
        
        foreach ($task in $subsectionInfo.tasks) {
            $totalProgress += $task.progress
            $taskCount++
        }
        
        $subsectionProgress = if ($taskCount -gt 0) { [math]::Round($totalProgress / $taskCount) } else { 0 }
        
        # Mettre Ã  jour la progression de la sous-section dans le contenu
        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match "### $subsectionId ") {
                # Trouver la ligne de progression
                for ($j = $i + 1; $j -lt $content.Count; $j++) {
                    if ($content[$j] -match '\*\*Progression globale\*\*: \d+%') {
                        $content[$j] = $content[$j] -replace '\*\*Progression globale\*\*: \d+%', "**Progression globale**: $subsectionProgress%"
                        break
                    }
                }
                break
            }
        }
        
        # Extraire l'ID de la section parente
        $sectionId = $subsectionId -replace '\.\d+$', ''
        
        # Mettre Ã  jour les informations de progression de la section
        if (-not $progressInfo.sections.ContainsKey($sectionId)) {
            $progressInfo.sections[$sectionId] = @{
                subsections = @()
            }
        }
        
        $progressInfo.sections[$sectionId].subsections += @{
            id = $subsectionId
            progress = $subsectionProgress
        }
    }

    # Calculer la progression des sections
    foreach ($sectionId in $progressInfo.sections.Keys) {
        $sectionInfo = $progressInfo.sections[$sectionId]
        $totalProgress = 0
        $subsectionCount = 0
        
        foreach ($subsection in $sectionInfo.subsections) {
            $totalProgress += $subsection.progress
            $subsectionCount++
        }
        
        $sectionProgress = if ($subsectionCount -gt 0) { [math]::Round($totalProgress / $subsectionCount) } else { 0 }
        
        # DÃ©terminer le statut en fonction de la progression
        $sectionStatus = switch ($sectionProgress) {
            0 { "Non commencÃ©" }
            { $_ -ge 1 -and $_ -lt 90 } { "En cours" }
            { $_ -ge 90 -and $_ -lt 100 } { "Presque terminÃ©" }
            100 { "TerminÃ©" }
            default { "Non commencÃ©" }
        }
        
        # Mettre Ã  jour la progression de la section dans le contenu
        for ($i = 0; $i -lt $content.Count; $i++) {
            if ($content[$i] -match "## $sectionId\. ") {
                # Trouver la ligne de statut global
                for ($j = $i + 1; $j -lt $content.Count; $j++) {
                    if ($content[$j] -match '\*\*Statut global\*\*: .+? - \d+%') {
                        $content[$j] = $content[$j] -replace '\*\*Statut global\*\*: .+? - \d+%', "**Statut global**: $sectionStatus - $sectionProgress%"
                        break
                    }
                }
                break
            }
        }
    }

    # Enregistrer les modifications
    $content | Out-File -FilePath $MarkdownPath -Encoding UTF8
    
    return @{
        sections = $progressInfo.sections
        subsections = $progressInfo.subsections
        tasks = $progressInfo.tasks
    }
}

# Fonction principale
try {
    $progressInfo = Update-RoadmapProgress -MarkdownPath $MarkdownPath
    
    Write-Host "Progression mise Ã  jour avec succÃ¨s dans '$MarkdownPath'"
    
    # Afficher un rÃ©sumÃ© des mises Ã  jour
    Write-Host "`nRÃ©sumÃ© des mises Ã  jour de progression:"
    
    Write-Host "`nSections:"
    foreach ($sectionId in $progressInfo.sections.Keys | Sort-Object) {
        $sectionInfo = $progressInfo.sections[$sectionId]
        $totalProgress = 0
        $subsectionCount = 0
        
        foreach ($subsection in $sectionInfo.subsections) {
            $totalProgress += $subsection.progress
            $subsectionCount++
        }
        
        $sectionProgress = if ($subsectionCount -gt 0) { [math]::Round($totalProgress / $subsectionCount) } else { 0 }
        
        Write-Host "  Section $sectionId : $sectionProgress%"
    }
    
    Write-Host "`nSous-sections:"
    foreach ($subsectionId in $progressInfo.subsections.Keys | Sort-Object) {
        $subsectionInfo = $progressInfo.subsections[$subsectionId]
        $totalProgress = 0
        $taskCount = 0
        
        foreach ($task in $subsectionInfo.tasks) {
            $totalProgress += $task.progress
            $taskCount++
        }
        
        $subsectionProgress = if ($taskCount -gt 0) { [math]::Round($totalProgress / $taskCount) } else { 0 }
        
        Write-Host "  Sous-section $subsectionId : $subsectionProgress%"
    }
    
    Write-Host "`nTÃ¢ches:"
    foreach ($taskId in $progressInfo.tasks.Keys | Sort-Object) {
        $taskInfo = $progressInfo.tasks[$taskId]
        $taskProgress = if ($taskInfo.total -gt 0) { [math]::Round(($taskInfo.completed / $taskInfo.total) * 100) } else { 0 }
        
        Write-Host "  TÃ¢che $taskId : $taskProgress% ($($taskInfo.completed)/$($taskInfo.total) sous-tÃ¢ches)"
    }
}
catch {
    Write-Error "Erreur lors de la mise Ã  jour de la progression: $_"
}
