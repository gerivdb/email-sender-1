# Script pour mettre Ã  jour les tÃ¢ches spÃ©cifiques dans le fichier de roadmap principal

$roadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\roadmap_complete_converted.md"
$taskIds = @(
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.1",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.2",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.3",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.4"
)

# VÃ©rifier si le fichier de roadmap existe
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
Write-Host "TÃ¢ches Ã  mettre Ã  jour : $($taskIds -join ', ')" -ForegroundColor Cyan

# Parcourir le contenu et mettre Ã  jour les tÃ¢ches
$updatedContent = $content.Clone()
$updatedTasks = 0
$taskLines = @()

for ($i = 0; $i -lt $content.Count; $i++) {
    $line = $content[$i]

    # VÃ©rifier si la ligne correspond Ã  une tÃ¢che
    if ($line -match '^\s*-\s+\[([ xX])\]\s+(\*\*)?(\d+(\.\d+)*)\s*(\*\*)?\s+(.+)$') {
        $status = $matches[1]
        $taskId = $matches[3]
        $taskName = $matches[6]

        # VÃ©rifier si la tÃ¢che est dans la liste des tÃ¢ches Ã  mettre Ã  jour
        if ($taskIds -contains $taskId) {
            Write-Host "TÃ¢che trouvÃ©e Ã  la ligne $($i+1) : [$status] $taskId $taskName" -ForegroundColor Yellow
            $taskLines += ($i + 1)

            # VÃ©rifier si la tÃ¢che est dÃ©jÃ  cochÃ©e
            if ($status -eq 'x' -or $status -eq 'X') {
                Write-Host "  TÃ¢che dÃ©jÃ  cochÃ©e." -ForegroundColor Green
                continue
            }

            # Mettre Ã  jour la tÃ¢che
            $updatedLine = $line -replace '\[ \]', '[x]'
            $updatedContent[$i] = $updatedLine
            $updatedTasks++

            Write-Host "  TÃ¢che mise Ã  jour : $updatedLine" -ForegroundColor Green
        }
    }
}

# Afficher un rÃ©sumÃ©
if ($taskLines.Count -eq 0) {
    Write-Host "`nAucune tÃ¢che correspondante trouvÃ©e dans le fichier de roadmap." -ForegroundColor Red
    exit 1
}

Write-Host "`nTÃ¢ches trouvÃ©es aux lignes : $($taskLines -join ', ')" -ForegroundColor Cyan

# Sauvegarder le contenu mis Ã  jour
if ($updatedTasks -gt 0) {
    $updatedContent | Set-Content -Path $roadmapPath -Encoding UTF8
    Write-Host "`nLe fichier de roadmap a Ã©tÃ© mis Ã  jour avec $updatedTasks tÃ¢ches cochÃ©es." -ForegroundColor Green
} else {
    Write-Host "`nAucune tÃ¢che n'a Ã©tÃ© mise Ã  jour." -ForegroundColor Yellow
}
