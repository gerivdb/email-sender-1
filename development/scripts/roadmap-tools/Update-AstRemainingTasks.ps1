# Script pour mettre à jour les tâches restantes de l'AST Navigator dans la roadmap

$roadmapPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\roadmap_complete_converted.md"

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

# Liste des tâches à mettre à jour
$taskIds = @(
    # Fonctions de recherche spécialisées
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.3",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.3.1",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.3.2",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.3.3",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.3.4",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.3.5",
    
    # Fonctions de navigation relationnelle
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.4",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.4.1",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.4.2",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.4.3",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.4.4",
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.4.5"
)

# Parcourir le contenu et mettre à jour les tâches
$updatedContent = $content.Clone()
$tasksUpdated = 0

for ($i = 0; $i -lt $content.Count; $i++) {
    $line = $content[$i]
    
    # Vérifier si la ligne correspond à une tâche
    if ($line -match '^\s*-\s+\[([ xX])\]\s+(\*\*)?(\d+(\.\d+)*)\s*(\*\*)?\s+(.+)$') {
        $status = $matches[1]
        $currentTaskId = $matches[3]
        $taskName = $matches[6]
        
        # Vérifier si c'est une tâche que nous cherchons
        if ($taskIds -contains $currentTaskId) {
            Write-Host "Tâche trouvée à la ligne $($i+1) : [$status] $currentTaskId $taskName" -ForegroundColor Yellow
            
            # Vérifier si la tâche est déjà cochée
            if ($status -eq 'x' -or $status -eq 'X') {
                Write-Host "  Tâche déjà cochée." -ForegroundColor Green
                continue
            }
            
            # Mettre à jour la tâche
            $updatedLine = $line -replace '\[ \]', '[x]'
            $updatedContent[$i] = $updatedLine
            $tasksUpdated++
            
            Write-Host "  Tâche mise à jour : $updatedLine" -ForegroundColor Green
        }
    }
}

# Vérifier si des tâches ont été mises à jour
if ($tasksUpdated -eq 0) {
    Write-Host "Aucune tâche n'a été mise à jour." -ForegroundColor Yellow
    exit 0
}

# Sauvegarder le contenu mis à jour
$updatedContent | Set-Content -Path $roadmapPath -Encoding UTF8
Write-Host "`nLe fichier de roadmap a été mis à jour avec succès." -ForegroundColor Green
Write-Host "$tasksUpdated tâches ont été mises à jour." -ForegroundColor Green
