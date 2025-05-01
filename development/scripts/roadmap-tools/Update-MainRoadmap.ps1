# Script pour mettre à jour les tâches spécifiques dans le fichier de roadmap principal

$roadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\roadmap_complete_converted.md"
$taskIds = @(
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.1",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.2",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.3",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.4"
)

# Vérifier si le fichier de roadmap existe
if (-not (Test-Path -Path $roadmapPath)) {
    Write-Error "Le fichier de roadmap '$roadmapPath' n'existe pas."
    exit 1
}

# Lire le contenu du fichier de roadmap
$content = Get-Content -Path $roadmapPath -Encoding UTF8
if ($null -eq $content -or $content.Count -eq 0) {
    Write-Error "Le fichier de roadmap est vide."
    exit 1
}

Write-Host "Fichier de roadmap : $roadmapPath" -ForegroundColor Cyan
Write-Host "Nombre de lignes : $($content.Count)" -ForegroundColor Cyan
Write-Host "Tâches à mettre à jour : $($taskIds -join ', ')" -ForegroundColor Cyan

# Parcourir le contenu et mettre à jour les tâches
$updatedContent = $content.Clone()
$updatedTasks = 0
$taskLines = @()

for ($i = 0; $i -lt $content.Count; $i++) {
    $line = $content[$i]

    # Vérifier si la ligne correspond à une tâche
    if ($line -match '^\s*-\s+\[([ xX])\]\s+(\*\*)?(\d+(\.\d+)*)\s*(\*\*)?\s+(.+)$') {
        $status = $matches[1]
        $taskId = $matches[3]
        $taskName = $matches[6]

        # Vérifier si la tâche est dans la liste des tâches à mettre à jour
        if ($taskIds -contains $taskId) {
            Write-Host "Tâche trouvée à la ligne $($i+1) : [$status] $taskId $taskName" -ForegroundColor Yellow
            $taskLines += ($i + 1)

            # Vérifier si la tâche est déjà cochée
            if ($status -eq 'x' -or $status -eq 'X') {
                Write-Host "  Tâche déjà cochée." -ForegroundColor Green
                continue
            }

            # Mettre à jour la tâche
            $updatedLine = $line -replace '\[ \]', '[x]'
            $updatedContent[$i] = $updatedLine
            $updatedTasks++

            Write-Host "  Tâche mise à jour : $updatedLine" -ForegroundColor Green
        }
    }
}

# Afficher un résumé
if ($taskLines.Count -eq 0) {
    Write-Host "`nAucune tâche correspondante trouvée dans le fichier de roadmap." -ForegroundColor Red
    exit 1
}

Write-Host "`nTâches trouvées aux lignes : $($taskLines -join ', ')" -ForegroundColor Cyan

# Sauvegarder le contenu mis à jour
if ($updatedTasks -gt 0) {
    $updatedContent | Set-Content -Path $roadmapPath -Encoding UTF8
    Write-Host "`nLe fichier de roadmap a été mis à jour avec $updatedTasks tâches cochées." -ForegroundColor Green
} else {
    Write-Host "`nAucune tâche n'a été mise à jour." -ForegroundColor Yellow
}
