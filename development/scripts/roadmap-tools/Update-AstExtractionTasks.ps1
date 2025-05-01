# Script pour mettre à jour les tâches d'extraction d'éléments spécifiques dans la roadmap

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
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.6",      # Créer des fonctions d'extraction d'éléments spécifiques (fonctions, paramètres, etc.)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.6.1",    # Implémenter une fonction pour extraire les fonctions d'un script
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.6.2",    # Développer une fonction pour extraire les paramètres d'un script ou d'une fonction
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.3.6.3"     # Créer une fonction pour extraire les variables d'un script
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
