# Script pour mettre à jour la tâche d'optimisation des performances pour les grands arbres syntaxiques

$roadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\roadmap_complete_converted.md"
$taskId = "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.1.5"

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
Write-Host "Tâche à mettre à jour : $taskId" -ForegroundColor Cyan

# Parcourir le contenu et mettre à jour la tâche
$updatedContent = $content.Clone()
$taskFound = $false
$taskLine = 0

for ($i = 0; $i -lt $content.Count; $i++) {
    $line = $content[$i]
    
    # Vérifier si la ligne correspond à la tâche
    if ($line -match '^\s*-\s+\[([ xX])\]\s+(\*\*)?(\d+(\.\d+)*)\s*(\*\*)?\s+(.+)$') {
        $status = $matches[1]
        $currentTaskId = $matches[3]
        $taskName = $matches[6]
        
        # Vérifier si c'est la tâche que nous cherchons
        if ($currentTaskId -eq $taskId) {
            Write-Host "Tâche trouvée à la ligne $($i+1) : [$status] $currentTaskId $taskName" -ForegroundColor Yellow
            $taskFound = $true
            $taskLine = $i
            
            # Vérifier si la tâche est déjà cochée
            if ($status -eq 'x' -or $status -eq 'X') {
                Write-Host "  Tâche déjà cochée." -ForegroundColor Green
                exit 0
            }
            
            # Mettre à jour la tâche
            $updatedLine = $line -replace '\[ \]', '[x]'
            $updatedContent[$i] = $updatedLine
            
            Write-Host "  Tâche mise à jour : $updatedLine" -ForegroundColor Green
            break
        }
    }
}

# Vérifier si la tâche a été trouvée
if (-not $taskFound) {
    Write-Error "La tâche avec l'ID '$taskId' n'a pas été trouvée dans le fichier de roadmap."
    exit 1
}

# Sauvegarder le contenu mis à jour
$updatedContent | Set-Content -Path $roadmapPath -Encoding UTF8
Write-Host "`nLe fichier de roadmap a été mis à jour avec succès." -ForegroundColor Green
Write-Host "Tâche mise à jour à la ligne $($taskLine+1)." -ForegroundColor Green
