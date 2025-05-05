# Script pour mettre Ã  jour les tÃ¢ches d'extraction d'Ã©lÃ©ments spÃ©cifiques dans la roadmap

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
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4",      # CrÃ©er des fonctions d'extraction d'Ã©lÃ©ments spÃ©cifiques (fonctions, paramÃ¨tres, etc.)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.1",    # ImplÃ©menter une fonction pour extraire les fonctions d'un script
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.1.1",  # CrÃ©er la structure de base pour identifier les nÅ“uds FunctionDefinitionAst
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.1.2",  # Ajouter des options de filtrage par nom de fonction
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.1.3",  # ImplÃ©menter l'extraction des mÃ©tadonnÃ©es de fonction (paramÃ¨tres, corps, etc.)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.1.4",  # CrÃ©er des options pour le format de sortie (simple/dÃ©taillÃ©)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.2",    # DÃ©velopper une fonction pour extraire les paramÃ¨tres d'un script ou d'une fonction
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.2.1",  # CrÃ©er la structure pour identifier les blocs de paramÃ¨tres (ParamBlockAst)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.2.2",  # ImplÃ©menter l'extraction des attributs de paramÃ¨tres (type, valeur par dÃ©faut, etc.)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.2.3",  # Ajouter la prise en charge des paramÃ¨tres de script et de fonction
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.2.4",  # CrÃ©er des options pour filtrer les paramÃ¨tres par nom ou attribut
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.3",    # CrÃ©er une fonction pour extraire les variables d'un script
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.3.1",  # ImplÃ©menter la dÃ©tection des nÅ“uds VariableExpressionAst
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.3.2",  # Ajouter des options pour filtrer par portÃ©e (scope) de variable
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.3.3",  # CrÃ©er une fonctionnalitÃ© pour dÃ©tecter les assignations de variables
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.3.4",  # ImplÃ©menter l'exclusion des variables automatiques ($_, $PSItem, etc.)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.4",    # DÃ©velopper une fonction pour extraire les appels de commandes
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.4.1",  # CrÃ©er la structure pour identifier les nÅ“uds CommandAst
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.4.2",  # ImplÃ©menter l'extraction des arguments et options de commande
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.4.3",  # Ajouter des options pour filtrer par nom de commande ou type
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.4.4",  # CrÃ©er une fonctionnalitÃ© pour analyser les pipelines de commandes
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.5",    # ImplÃ©menter une fonction pour extraire les structures de contrÃ´le
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.5.1",  # CrÃ©er la dÃ©tection des structures conditionnelles (if, switch)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.5.2",  # ImplÃ©menter l'extraction des boucles (foreach, while, do)
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.5.3",  # Ajouter la prise en charge des blocs try/catch/finally
    "2.1.2.4.1.2.3.2.2.5.3.2.2.1.4.5.4"   # CrÃ©er des options pour analyser la complexitÃ© des structures
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
