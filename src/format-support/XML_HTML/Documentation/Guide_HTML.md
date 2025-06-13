# Guide d'utilisation du format HTML

Ce guide explique comment utiliser les fonctionnalités de support du format HTML pour convertir, analyser et manipuler des fichiers HTML.

## Structure HTML pour les Roadmaps

Le format HTML pour les roadmaps utilise la structure suivante :

```html
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <title>Titre de la Roadmap</title>
    <style>
        /* Styles CSS pour la roadmap */
    </style>
</head>
<body>
    <h1>Titre de la Roadmap</h1>
    
    <div class="overview">
        <h2>Vue d'ensemble des taches par priorite et complexite</h2>
        <p>Vue d'ensemble de la roadmap.</p>
    </div>
    
    <div class="section">
        <h2>1. Titre de la section</h2>
        
        <div class="metadata">
            <p><span class="metadata-label">Complexite:</span> Niveau de complexité</p>
            <p><span class="metadata-label">Temps estime:</span> Estimation de temps</p>
            <p><span class="metadata-label">Progression:</span> Pourcentage de progression</p>
        </div>
        
        <div class="phase">
            <h3><span class="checkbox unchecked"></span>Phase 1: Titre de la phase</h3>
            
            <div class="task">
                <p><span class="checkbox unchecked"></span>Titre de la tâche (Temps estimé) - <em>Date de début</em></p>
                
                <div class="subtask">
                    <p><span class="checkbox unchecked"></span>Titre de la sous-tâche</p>
                </div>
            </div>
            
            <div class="note">
                <p>Note concernant la phase.</p>
            </div>
        </div>
    </div>
</body>
</html>
```plaintext
## Manipulation de fichiers HTML

### Importer un fichier HTML

```powershell
# Importer un fichier HTML

$htmlDoc = Import-HtmlFile -FilePath "roadmap.html"
```plaintext
### Exporter un document HTML

```powershell
# Exporter un document HTML

Export-HtmlFile -HtmlDocument $htmlDoc -FilePath "roadmap_updated.html"
```plaintext
### Convertir une chaîne HTML en document HTML

```powershell
# Convertir une chaîne HTML en document HTML

$htmlString = Get-Content -Path "roadmap.html" -Raw
$htmlDoc = ConvertFrom-Html -HtmlString $htmlString
```plaintext
## Sanitisation HTML

La sanitisation HTML permet de supprimer les éléments dangereux d'un document HTML, comme les scripts et les iframes.

```powershell
# Sanitiser un document HTML

$htmlString = Get-Content -Path "page.html" -Raw
$htmlDoc = ConvertFrom-Html -HtmlString $htmlString -Sanitize
```plaintext
## Requêtes CSS

Les requêtes CSS permettent de sélectionner des éléments dans un document HTML en utilisant des sélecteurs CSS.

```powershell
# Exécuter une requête CSS sur un document HTML

$htmlDoc = Import-HtmlFile -FilePath "roadmap.html"

# Sélectionner tous les titres

$titles = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector "h1, h2, h3"

# Sélectionner toutes les tâches

$tasks = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector ".task"

# Sélectionner toutes les sous-tâches terminées

$completedSubtasks = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector ".subtask .checkbox.checked"
```plaintext
## Extraction de texte

L'extraction de texte permet de récupérer le texte d'un document HTML sans les balises.

```powershell
# Convertir un document HTML en texte brut

$htmlDoc = Import-HtmlFile -FilePath "roadmap.html"
$text = ConvertTo-PlainText -HtmlDocument $htmlDoc
$text | Out-File -FilePath "roadmap.txt" -Encoding UTF8
```plaintext
## Conversion entre formats

### Convertir un document HTML en XML

```powershell
# Convertir un document HTML en XML

$htmlDoc = Import-HtmlFile -FilePath "roadmap.html"
$xmlDoc = ConvertFrom-HtmlToXml -HtmlDocument $htmlDoc
$xmlDoc.Save("roadmap.xml")
```plaintext
### Convertir un document XML en HTML

```powershell
# Convertir un document XML en HTML

$xmlDoc = Import-XmlFile -FilePath "roadmap.xml"
$htmlDoc = ConvertFrom-XmlToHtml -XmlDocument $xmlDoc
Export-HtmlFile -HtmlDocument $htmlDoc -FilePath "roadmap.html"
```plaintext
## Affichage HTML

### Afficher la structure d'un fichier HTML

```powershell
# Afficher la structure d'un fichier HTML

Show-HtmlStructure -HtmlPath "roadmap.html"
```plaintext
### Ouvrir un fichier HTML dans le navigateur

```powershell
# Ouvrir un fichier HTML dans le navigateur

Start-Process "roadmap.html"
```plaintext
## Exemples pratiques

### Exemple 1 : Extraire toutes les tâches d'une roadmap HTML

```powershell
# Importer le fichier HTML

$htmlDoc = Import-HtmlFile -FilePath "roadmap.html"

# Extraire toutes les tâches

$tasks = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector ".task > p"

# Afficher les informations sur les tâches

foreach ($task in $tasks) {
    $taskText = $task.InnerText.Trim()
    
    # Extraire le titre de la tâche (sans la case à cocher)

    $taskTitle = $taskText -replace "^□|^✓", ""
    
    # Déterminer si la tâche est terminée

    $isCompleted = $task.InnerHtml -match "checkbox checked"
    
    Write-Host "Tâche: $taskTitle"
    Write-Host "  Terminée: $isCompleted"
    
    # Extraire les sous-tâches

    $subtasks = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector ".task:has(> p:contains('$taskTitle')) .subtask > p"
    
    if ($subtasks.Count -gt 0) {
        Write-Host "  Sous-tâches:"
        
        foreach ($subtask in $subtasks) {
            $subtaskText = $subtask.InnerText.Trim()
            $subtaskTitle = $subtaskText -replace "^□|^✓", ""
            $isSubtaskCompleted = $subtask.InnerHtml -match "checkbox checked"
            
            Write-Host "    - $subtaskTitle (Terminée: $isSubtaskCompleted)"
        }
    }
    
    Write-Host ""
}
```plaintext
### Exemple 2 : Calculer la progression d'une roadmap HTML

```powershell
# Importer le fichier HTML

$htmlDoc = Import-HtmlFile -FilePath "roadmap.html"

# Extraire toutes les tâches

$tasks = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector ".task > p"
$totalTasks = $tasks.Count
$completedTasks = (Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector ".task > p .checkbox.checked").Count

# Calculer la progression

$progression = if ($totalTasks -gt 0) { [math]::Round(($completedTasks / $totalTasks) * 100, 2) } else { 0 }

Write-Host "Progression de la roadmap: $progression% ($completedTasks/$totalTasks tâches terminées)"

# Extraire toutes les phases

$phases = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector ".phase > h3"
$totalPhases = $phases.Count
$completedPhases = (Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector ".phase > h3 .checkbox.checked").Count

# Calculer la progression des phases

$phaseProgression = if ($totalPhases -gt 0) { [math]::Round(($completedPhases / $totalPhases) * 100, 2) } else { 0 }

Write-Host "Progression des phases: $phaseProgression% ($completedPhases/$totalPhases phases terminées)"
```plaintext
### Exemple 3 : Mettre à jour une roadmap HTML

```powershell
# Importer le fichier HTML

$htmlDoc = Import-HtmlFile -FilePath "roadmap.html"

# Trouver une tâche spécifique

$task = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector ".task > p:contains('Analyser les besoins')" | Select-Object -First 1

if ($task -ne $null) {
    # Mettre à jour la case à cocher

    $checkbox = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector ".task > p:contains('Analyser les besoins') .checkbox" | Select-Object -First 1
    
    if ($checkbox -ne $null) {
        # Remplacer la classe de la case à cocher

        $checkbox.Attributes["class"].Value = "checkbox checked"
        
        # Enregistrer les modifications

        Export-HtmlFile -HtmlDocument $htmlDoc -FilePath "roadmap_updated.html"
        
        Write-Host "Tâche 'Analyser les besoins' marquée comme terminée."
    }
    else {
        Write-Host "Case à cocher non trouvée pour la tâche 'Analyser les besoins'."
    }
}
else {
    Write-Host "Tâche 'Analyser les besoins' non trouvée."
}
```plaintext
## Dépannage

### Problèmes courants

#### Erreur lors de l'installation de HtmlAgilityPack

Si vous rencontrez une erreur lors de l'installation de HtmlAgilityPack, vous pouvez essayer de l'installer manuellement :

```powershell
# Installer NuGet si nécessaire

Install-PackageProvider -Name NuGet -Force

# Installer HtmlAgilityPack

Install-Package HtmlAgilityPack -Force
```plaintext
#### Caractères spéciaux dans les fichiers HTML

Si vous rencontrez des problèmes avec des caractères spéciaux dans les fichiers HTML, assurez-vous que les fichiers sont encodés en UTF-8 :

```powershell
# Lire le contenu du fichier

$content = Get-Content -Path "roadmap.html" -Raw

# Enregistrer le fichier en UTF-8

Set-Content -Path "roadmap.html" -Value $content -Encoding UTF8
```plaintext
#### Problèmes avec les requêtes CSS

Si vous rencontrez des problèmes avec les requêtes CSS, vérifiez que le sélecteur CSS est correct et que les éléments existent dans le document HTML :

```powershell
# Importer le fichier HTML

$htmlDoc = Import-HtmlFile -FilePath "roadmap.html"

# Afficher tous les éléments disponibles

$allElements = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector "*"
$allElements | ForEach-Object { $_.Name + ": " + $_.OuterHtml.Substring(0, [Math]::Min(50, $_.OuterHtml.Length)) + "..." }
```plaintext