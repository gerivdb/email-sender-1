# Script pour mettre Ã  jour la tÃ¢che d'implÃ©mentation d'une fonction de parcours en profondeur (DFS) de l'AST

$roadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\roadmap_complete_converted.md"

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

# Liste des tÃ¢ches Ã  mettre Ã  jour
$taskIds = @(
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1"      # TÃ¢che : ImplÃ©menter une fonction de parcours en profondeur (DFS) de l'AST
)

# Parcourir le contenu et mettre Ã  jour les tÃ¢ches
$updatedContent = $content.Clone()
$tasksUpdated = 0

for ($i = 0; $i -lt $content.Count; $i++) {
    $line = $content[$i]
    
    # VÃ©rifier si la ligne correspond Ã  une tÃ¢che
    if ($line -match '^\s*-\s+\[([ xX])\]\s+(\*\*)?(\d+(\.\d+)*)\s*(\*\*)?\s+(.+)$') {
        $status = $matches[1]
        $currentTaskId = $matches[3]
        $taskName = $matches[6]
        
        # VÃ©rifier si c'est une tÃ¢che que nous cherchons
        if ($taskIds -contains $currentTaskId) {
            Write-Host "TÃ¢che trouvÃ©e Ã  la ligne $($i+1) : [$status] $currentTaskId $taskName" -ForegroundColor Yellow
            
            # VÃ©rifier si la tÃ¢che est dÃ©jÃ  cochÃ©e
            if ($status -eq 'x' -or $status -eq 'X') {
                Write-Host "  TÃ¢che dÃ©jÃ  cochÃ©e." -ForegroundColor Green
                continue
            }
            
            # Mettre Ã  jour la tÃ¢che
            $updatedLine = $line -replace '\[ \]', '[x]'
            $updatedContent[$i] = $updatedLine
            $tasksUpdated++
            
            Write-Host "  TÃ¢che mise Ã  jour : $updatedLine" -ForegroundColor Green
        }
    }
}

# VÃ©rifier si des tÃ¢ches ont Ã©tÃ© mises Ã  jour
if ($tasksUpdated -eq 0) {
    Write-Host "Aucune tÃ¢che n'a Ã©tÃ© mise Ã  jour." -ForegroundColor Yellow
    exit 0
}

# Sauvegarder le contenu mis Ã  jour
$updatedContent | Set-Content -Path $roadmapPath -Encoding UTF8
Write-Host "`nLe fichier de roadmap a Ã©tÃ© mis Ã  jour avec succÃ¨s." -ForegroundColor Green
Write-Host "$tasksUpdated tÃ¢ches ont Ã©tÃ© mises Ã  jour." -ForegroundColor Green
