# Guide d'utilisation du format XML

Ce guide explique comment utiliser les fonctionnalités de support du format XML pour convertir, analyser et valider des fichiers XML.

## Structure XML pour les Roadmaps

Le format XML pour les roadmaps utilise la structure suivante :

```xml
<?xml version="1.0" encoding="UTF-8"?>
<roadmap title="Titre de la Roadmap">
  <overview>Vue d'ensemble de la roadmap.</overview>
  <section id="1" title="Titre de la section">
    <metadata>
      <Complexite>Niveau de complexité</Complexite>
      <Temps_estime>Estimation de temps</Temps_estime>
      <Progression>Pourcentage de progression</Progression>
    </metadata>
    <phase id="1" title="Titre de la phase" completed="false">
      <task title="Titre de la tâche" estimatedTime="Temps estimé" startDate="Date de début" completed="false">
        <subtask title="Titre de la sous-tâche" completed="false" />
      </task>
      <note>Note concernant la phase.</note>
    </phase>
  </section>
</roadmap>
```

## Conversion entre Roadmap et XML

### Convertir une Roadmap en XML

```powershell
# Convertir un fichier Roadmap en XML
ConvertFrom-RoadmapFileToXmlFile -RoadmapPath "roadmap.md" -XmlPath "roadmap.xml"

# Convertir une chaîne Roadmap en XML
$roadmapContent = Get-Content -Path "roadmap.md" -Raw
$xmlContent = ConvertFrom-RoadmapToXml -RoadmapContent $roadmapContent
```

### Convertir un XML en Roadmap

```powershell
# Convertir un fichier XML en Roadmap
ConvertFrom-XmlFileToRoadmapFile -XmlPath "roadmap.xml" -RoadmapPath "roadmap.md"

# Convertir une chaîne XML en Roadmap
$xmlContent = Get-Content -Path "roadmap.xml" -Raw
$roadmapContent = ConvertFrom-XmlToRoadmap -XmlContent $xmlContent
```

## Analyse et validation XML

### Détecter les éléments XML

```powershell
# Détecter les éléments XML dans un fichier
$elements = Get-XmlElementsFromFile -XmlPath "roadmap.xml"

# Afficher les éléments
$elements | ForEach-Object { $_.ToString() }
```

### Générer un rapport de structure XML

```powershell
# Générer un rapport de structure XML
$report = Get-XmlStructureReportFromFile -XmlPath "roadmap.xml" -OutputPath "structure_report.html" -AsHtml
```

### Valider un fichier XML

```powershell
# Valider un fichier XML
$result = Test-XmlFile -XmlPath "roadmap.xml"

# Afficher le résultat
$result.ToString()
```

### Générer un rapport de validation XML

```powershell
# Générer un rapport de validation XML
$result = Test-XmlFile -XmlPath "roadmap.xml"
$report = Get-XmlValidationReport -ValidationResult $result -AsHtml
$report | Out-File -FilePath "validation_report.html" -Encoding UTF8
```

### Valider un fichier XML par rapport à un schéma XSD

```powershell
# Valider un fichier XML par rapport à un schéma XSD
$result = Test-XmlFileAgainstSchema -XmlPath "roadmap.xml" -SchemaPath "roadmap.xsd"

# Afficher le résultat
$result.ToString()
```

### Générer un schéma XSD à partir d'un fichier XML

```powershell
# Générer un schéma XSD à partir d'un fichier XML
New-XsdSchemaFromXml -XmlPath "roadmap.xml" -SchemaPath "roadmap.xsd"
```

## Manipulation de fichiers XML

### Importer un fichier XML

```powershell
# Importer un fichier XML
$xmlDoc = Import-XmlFile -FilePath "roadmap.xml"
```

### Exporter un objet en XML

```powershell
# Exporter un objet en XML
$data = @{
    roadmap = @{
        title = "Titre de la Roadmap"
        overview = "Vue d'ensemble de la roadmap."
        sections = @(
            @{
                id = 1
                title = "Titre de la section"
                phases = @(
                    @{
                        id = 1
                        title = "Titre de la phase"
                        completed = $false
                    }
                )
            }
        )
    }
}

Export-XmlFile -InputObject $data -FilePath "roadmap.xml"
```

## Affichage XML

### Afficher un fichier XML sous forme d'arborescence

```powershell
# Afficher un fichier XML sous forme d'arborescence
Show-XmlTree -XmlPath "roadmap.xml"
```

### Afficher un fichier XML formaté

```powershell
# Afficher un fichier XML formaté
Show-XmlFormatted -XmlPath "roadmap.xml"
```

## Exemples pratiques

### Exemple 1 : Extraire toutes les tâches d'une roadmap XML

```powershell
# Importer le fichier XML
$xmlDoc = Import-XmlFile -FilePath "roadmap.xml"

# Extraire toutes les tâches
$tasks = $xmlDoc.SelectNodes("//task")

# Afficher les informations sur les tâches
foreach ($task in $tasks) {
    $taskTitle = $task.GetAttribute("title")
    $taskCompleted = $task.GetAttribute("completed")
    $taskEstimatedTime = $task.GetAttribute("estimatedTime")
    
    Write-Host "Tâche: $taskTitle"
    Write-Host "  Terminée: $taskCompleted"
    Write-Host "  Temps estimé: $taskEstimatedTime"
    
    # Extraire les sous-tâches
    $subtasks = $task.SelectNodes("subtask")
    
    if ($subtasks.Count -gt 0) {
        Write-Host "  Sous-tâches:"
        
        foreach ($subtask in $subtasks) {
            $subtaskTitle = $subtask.GetAttribute("title")
            $subtaskCompleted = $subtask.GetAttribute("completed")
            
            Write-Host "    - $subtaskTitle (Terminée: $subtaskCompleted)"
        }
    }
    
    Write-Host ""
}
```

### Exemple 2 : Calculer la progression d'une roadmap XML

```powershell
# Importer le fichier XML
$xmlDoc = Import-XmlFile -FilePath "roadmap.xml"

# Extraire toutes les tâches
$tasks = $xmlDoc.SelectNodes("//task")
$totalTasks = $tasks.Count
$completedTasks = ($tasks | Where-Object { $_.GetAttribute("completed") -eq "true" }).Count

# Calculer la progression
$progression = if ($totalTasks -gt 0) { [math]::Round(($completedTasks / $totalTasks) * 100, 2) } else { 0 }

Write-Host "Progression de la roadmap: $progression% ($completedTasks/$totalTasks tâches terminées)"

# Extraire toutes les phases
$phases = $xmlDoc.SelectNodes("//phase")
$totalPhases = $phases.Count
$completedPhases = ($phases | Where-Object { $_.GetAttribute("completed") -eq "true" }).Count

# Calculer la progression des phases
$phaseProgression = if ($totalPhases -gt 0) { [math]::Round(($completedPhases / $totalPhases) * 100, 2) } else { 0 }

Write-Host "Progression des phases: $phaseProgression% ($completedPhases/$totalPhases phases terminées)"
```

### Exemple 3 : Mettre à jour une roadmap XML

```powershell
# Importer le fichier XML
$xmlDoc = Import-XmlFile -FilePath "roadmap.xml"

# Trouver une tâche spécifique
$task = $xmlDoc.SelectSingleNode("//task[@title='Analyser les besoins']")

if ($task -ne $null) {
    # Mettre à jour l'attribut completed
    $task.SetAttribute("completed", "true")
    
    # Mettre à jour la date de fin
    $task.SetAttribute("endDate", (Get-Date -Format "dd/MM/yyyy"))
    
    # Enregistrer les modifications
    $xmlDoc.Save("roadmap_updated.xml")
    
    Write-Host "Tâche 'Analyser les besoins' marquée comme terminée."
}
else {
    Write-Host "Tâche 'Analyser les besoins' non trouvée."
}
```

## Dépannage

### Problèmes courants

#### Erreur lors de la conversion de Roadmap en XML

Si vous rencontrez une erreur lors de la conversion d'une roadmap en XML, vérifiez que le format de la roadmap est correct. La roadmap doit suivre une structure spécifique avec des titres, des métadonnées, des phases, des tâches et des sous-tâches.

```powershell
# Valider la structure de la roadmap
$roadmapContent = Get-Content -Path "roadmap.md" -Raw
$xmlContent = ConvertFrom-RoadmapToXml -RoadmapContent $roadmapContent

# Valider le XML généré
$result = Test-XmlContent -XmlContent $xmlContent
if (-not $result.IsValid) {
    Write-Host "Erreurs de validation XML :"
    $result.Errors | ForEach-Object { $_.ToString() }
}
```

#### Caractères spéciaux dans les fichiers XML

Si vous rencontrez des problèmes avec des caractères spéciaux dans les fichiers XML, assurez-vous que les fichiers sont encodés en UTF-8 :

```powershell
# Lire le contenu du fichier
$content = Get-Content -Path "roadmap.xml" -Raw

# Enregistrer le fichier en UTF-8
Set-Content -Path "roadmap.xml" -Value $content -Encoding UTF8
```
