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
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4",      # Créer des fonctions d'extraction d'éléments spécifiques (fonctions, paramètres, etc.)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.1",    # Implémenter une fonction pour extraire les fonctions d'un script
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.1.1",  # Créer la structure de base pour identifier les nœuds FunctionDefinitionAst
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.1.2",  # Ajouter des options de filtrage par nom de fonction
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.1.3",  # Implémenter l'extraction des métadonnées de fonction (paramètres, corps, etc.)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.1.4",  # Créer des options pour le format de sortie (simple/détaillé)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.2",    # Développer une fonction pour extraire les paramètres d'un script ou d'une fonction
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.2.1",  # Créer la structure pour identifier les blocs de paramètres (ParamBlockAst)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.2.2",  # Implémenter l'extraction des attributs de paramètres (type, valeur par défaut, etc.)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.2.3",  # Ajouter la prise en charge des paramètres de script et de fonction
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.2.4",  # Créer des options pour filtrer les paramètres par nom ou attribut
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.3",    # Créer une fonction pour extraire les variables d'un script
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.3.1",  # Implémenter la détection des nœuds VariableExpressionAst
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.3.2",  # Ajouter des options pour filtrer par portée (scope) de variable
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.3.3",  # Créer une fonctionnalité pour détecter les assignations de variables
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.3.4",  # Implémenter l'exclusion des variables automatiques ($_, $PSItem, etc.)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.4",    # Développer une fonction pour extraire les appels de commandes
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.4.1",  # Créer la structure pour identifier les nœuds CommandAst
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.4.2",  # Implémenter l'extraction des arguments et options de commande
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.4.3",  # Ajouter des options pour filtrer par nom de commande ou type
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.4.4",  # Créer une fonctionnalité pour analyser les pipelines de commandes
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.5",    # Implémenter une fonction pour extraire les structures de contrôle
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.5.1",  # Créer la détection des structures conditionnelles (if, switch)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.5.2",  # Implémenter l'extraction des boucles (foreach, while, do)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.5.3",  # Ajouter la prise en charge des blocs try/catch/finally
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.5.4"   # Créer des options pour analyser la complexité des structures
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
