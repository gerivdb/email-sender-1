# Guide d'intégration pour les développeurs

Ce guide explique comment intégrer le support des formats XML et HTML dans vos propres scripts et applications.

## Intégration avec le module Format-Converters

### Installation

Pour intégrer le support des formats XML et HTML dans le module Format-Converters, utilisez le script d'intégration fourni :

```powershell
# Exécuter le script d'intégration

$scriptPath = "chemin/vers/FormatSupport/XML_HTML/Integration"
& "$scriptPath/Format-Converters-Integration.ps1"
```plaintext
### Utilisation

Une fois l'intégration effectuée, vous pouvez utiliser les convertisseurs XML et HTML dans le module Format-Converters :

```powershell
# Importer le module Format-Converters

$formatConvertersPath = "chemin/vers/Format-Converters"
. "$formatConvertersPath/Format-Converters.ps1"

# Enregistrer les convertisseurs XML et HTML

$converterRegistry = @{}
$xmlHtmlIntegrationPath = Join-Path -Path $formatConvertersPath -ChildPath "Integrations\XML_HTML\XML_HTML_Integration.ps1"
. $xmlHtmlIntegrationPath
$converterRegistry = Register-XmlHtmlConverters -ConverterRegistry $converterRegistry

# Utiliser les convertisseurs

$xmlConverter = $converterRegistry["xml"]
$htmlConverter = $converterRegistry["html"]

# Convertir un fichier XML en Roadmap

$xmlContent = Get-Content -Path "roadmap.xml" -Raw
$roadmapContent = & $xmlConverter.ConvertFromFunction["roadmap"] $xmlContent
```plaintext
## Intégration avec l'interface utilisateur

### Installation

Pour intégrer le support des formats XML et HTML dans l'interface utilisateur, utilisez le script de mise à jour de l'interface utilisateur fourni :

```powershell
# Exécuter le script de mise à jour de l'interface utilisateur

$scriptPath = "chemin/vers/FormatSupport/XML_HTML/Integration"
& "$scriptPath/Update-UserInterface.ps1"
```plaintext
### Utilisation

Une fois l'intégration effectuée, vous pouvez utiliser les formats XML et HTML dans l'interface utilisateur :

```powershell
# Importer le module UI

$uiPath = "chemin/vers/UI"
. "$uiPath/UI.ps1"

# Enregistrer les formats XML et HTML dans l'interface utilisateur

$uiRegistry = @{}
$xmlHtmlUiIntegrationPath = Join-Path -Path $uiPath -ChildPath "XML_HTML\XML_HTML_UI_Integration.ps1"
. $xmlHtmlUiIntegrationPath
$uiRegistry = Register-XmlHtmlFormatsInUI -UiRegistry $uiRegistry

# Utiliser les formats

$xmlFormat = $uiRegistry["xml"]
$htmlFormat = $uiRegistry["html"]

# Afficher les actions disponibles pour le format XML

$xmlFormat.Actions | ForEach-Object { $_.Name }
```plaintext
## Extension du module

### Ajout de nouvelles fonctionnalités

Pour ajouter de nouvelles fonctionnalités au module, vous pouvez créer vos propres scripts dans le dossier `Implementation` :

```powershell
# Créer un nouveau script d'implémentation

$implementationPath = "chemin/vers/FormatSupport/XML_HTML/Implementation"
$newScriptPath = Join-Path -Path $implementationPath -ChildPath "MyNewFeature.ps1"

# Contenu du script

$scriptContent = @"
# Nouvelle fonctionnalité pour le module XML/HTML

# Fonction pour faire quelque chose de nouveau

function Do-SomethingNew {
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$InputPath
    )
    
    # Implémentation de la fonctionnalité

    # ...

    
    return `$result
}

# Exporter la fonction

Export-ModuleMember -Function Do-SomethingNew
"@

# Enregistrer le script

Set-Content -Path $newScriptPath -Value $scriptContent -Encoding UTF8
```plaintext
### Intégration de votre fonctionnalité

Pour intégrer votre nouvelle fonctionnalité dans le module principal, vous devez l'ajouter au fichier `XmlSupport.ps1` :

```powershell
# Modifier le fichier XmlSupport.ps1

$xmlSupportPath = "chemin/vers/FormatSupport/XML_HTML/XmlSupport.ps1"

# Ajouter l'importation de votre script

$xmlSupportContent = Get-Content -Path $xmlSupportPath -Raw
$newScriptImport = "`$myNewFeaturePath = Join-Path -Path `$implementationPath -ChildPath `"MyNewFeature.ps1`"`n. `$myNewFeaturePath"
$xmlSupportContent = $xmlSupportContent -replace "# Importer les modules([\s\S]*?)# Fonction pour afficher l'aide", "# Importer les modules`$1$newScriptImport`n`n# Fonction pour afficher l'aide"

# Ajouter l'exportation de votre fonction

$exportLine = "Export-ModuleMember -Function Do-SomethingNew"
$xmlSupportContent = $xmlSupportContent -replace "# Afficher un message d'accueil", "$exportLine`n`n# Afficher un message d'accueil"

# Enregistrer les modifications

Set-Content -Path $xmlSupportPath -Value $xmlSupportContent -Encoding UTF8
```plaintext
## Création de tests

### Tests unitaires

Pour créer des tests unitaires pour votre fonctionnalité, ajoutez-les au script de test unitaire :

```powershell
# Modifier le fichier de test unitaire

$testUnitPath = "chemin/vers/FormatSupport/XML_HTML/Tests/Test-UnitTests.ps1"

# Ajouter un test pour votre fonctionnalité

$testUnitContent = Get-Content -Path $testUnitPath -Raw
$newTest = @"
    # Tests pour MyNewFeature

    Write-Host "Tests pour MyNewFeature" -ForegroundColor Yellow
    
    Test-Case -Name "MyNewFeature - Test de base" -Test {
        `$result = Do-SomethingNew -InputPath "test.txt"
        
        if (-not `$result) {
            throw "Le résultat est incorrect"
        }
    }
"@
$testUnitContent = $testUnitContent -replace "# Afficher le résumé des tests", "$newTest`n`n    # Afficher le résumé des tests"

# Enregistrer les modifications

Set-Content -Path $testUnitPath -Value $testUnitContent -Encoding UTF8
```plaintext
### Tests d'intégration

Pour créer des tests d'intégration pour votre fonctionnalité, ajoutez-les au script de test d'intégration :

```powershell
# Modifier le fichier de test d'intégration

$testIntegrationPath = "chemin/vers/FormatSupport/XML_HTML/Integration/Test-Integration.ps1"

# Ajouter un test pour votre fonctionnalité

$testIntegrationContent = Get-Content -Path $testIntegrationPath -Raw
$newTest = @"
    # Test pour MyNewFeature

    Test-Case -Name "MyNewFeature - Test d'intégration" -Test {
        `$result = Do-SomethingNew -InputPath "test.txt"
        
        if (-not `$result) {
            throw "Le résultat est incorrect"
        }
        
        Write-Host "  Fonctionnalité MyNewFeature testée avec succès"
    }
"@
$testIntegrationContent = $testIntegrationContent -replace "# Afficher le résumé des tests", "$newTest`n`n    # Afficher le résumé des tests"

# Enregistrer les modifications

Set-Content -Path $testIntegrationPath -Value $testIntegrationContent -Encoding UTF8
```plaintext
## Exemples d'intégration

### Exemple 1 : Intégration avec un script de traitement de fichiers

```powershell
# Importer le module XmlSupport

$xmlSupportPath = "chemin/vers/FormatSupport/XML_HTML/XmlSupport.ps1"
. $xmlSupportPath

# Fonction pour traiter un dossier de fichiers

function Process-Files {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFolder
    )
    
    # Créer le dossier de sortie s'il n'existe pas

    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Traiter les fichiers XML

    $xmlFiles = Get-ChildItem -Path $FolderPath -Filter "*.xml"
    foreach ($xmlFile in $xmlFiles) {
        $outputPath = Join-Path -Path $OutputFolder -ChildPath ($xmlFile.BaseName + ".md")
        ConvertFrom-XmlFileToRoadmapFile -XmlPath $xmlFile.FullName -RoadmapPath $outputPath
        Write-Host "Fichier XML converti: $($xmlFile.Name) -> $($xmlFile.BaseName).md"
    }
    
    # Traiter les fichiers HTML

    $htmlFiles = Get-ChildItem -Path $FolderPath -Filter "*.html"
    foreach ($htmlFile in $htmlFiles) {
        $outputPath = Join-Path -Path $OutputFolder -ChildPath ($htmlFile.BaseName + ".xml")
        $htmlDoc = Import-HtmlFile -FilePath $htmlFile.FullName
        $xmlDoc = ConvertFrom-HtmlToXml -HtmlDocument $htmlDoc
        $xmlDoc.Save($outputPath)
        Write-Host "Fichier HTML converti: $($htmlFile.Name) -> $($htmlFile.BaseName).xml"
    }
    
    # Générer un rapport

    $reportPath = Join-Path -Path $OutputFolder -ChildPath "conversion_report.txt"
    $report = "Rapport de conversion`n"
    $report += "===================`n`n"
    $report += "Fichiers XML convertis: $($xmlFiles.Count)`n"
    $report += "Fichiers HTML convertis: $($htmlFiles.Count)`n"
    $report += "Total: $($xmlFiles.Count + $htmlFiles.Count) fichiers`n"
    Set-Content -Path $reportPath -Value $report -Encoding UTF8
    
    return $reportPath
}

# Utiliser la fonction

$folderPath = "chemin/vers/dossier/de/fichiers"
$outputFolder = "chemin/vers/dossier/de/sortie"
$reportPath = Process-Files -FolderPath $folderPath -OutputFolder $outputFolder
```plaintext
### Exemple 2 : Intégration avec un module de génération de rapports

```powershell
# Importer le module XmlSupport

$xmlSupportPath = "chemin/vers/FormatSupport/XML_HTML/XmlSupport.ps1"
. $xmlSupportPath

# Fonction pour générer un rapport de progression

function Generate-ProgressReport {
    param (
        [Parameter(Mandatory = $true)]
        [string]$RoadmapPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    # Convertir la roadmap en XML

    $tempXmlPath = [System.IO.Path]::GetTempFileName() + ".xml"
    ConvertFrom-RoadmapFileToXmlFile -RoadmapPath $RoadmapPath -XmlPath $tempXmlPath
    
    # Analyser le XML

    $xmlDoc = Import-XmlFile -FilePath $tempXmlPath
    
    # Extraire les informations de progression

    $sections = $xmlDoc.SelectNodes("//section")
    $totalSections = $sections.Count
    
    $phases = $xmlDoc.SelectNodes("//phase")
    $totalPhases = $phases.Count
    $completedPhases = ($phases | Where-Object { $_.GetAttribute("completed") -eq "true" }).Count
    $phaseProgress = if ($totalPhases -gt 0) { [math]::Round(($completedPhases / $totalPhases) * 100, 2) } else { 0 }
    
    $tasks = $xmlDoc.SelectNodes("//task")
    $totalTasks = $tasks.Count
    $completedTasks = ($tasks | Where-Object { $_.GetAttribute("completed") -eq "true" }).Count
    $taskProgress = if ($totalTasks -gt 0) { [math]::Round(($completedTasks / $totalTasks) * 100, 2) } else { 0 }
    
    $subtasks = $xmlDoc.SelectNodes("//subtask")
    $totalSubtasks = $subtasks.Count
    $completedSubtasks = ($subtasks | Where-Object { $_.GetAttribute("completed") -eq "true" }).Count
    $subtaskProgress = if ($totalSubtasks -gt 0) { [math]::Round(($completedSubtasks / $totalSubtasks) * 100, 2) } else { 0 }
    
    # Générer le rapport HTML

    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de progression</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }

        .progress-bar { width: 100%; background-color: #f3f3f3; border-radius: 5px; }

        .progress { height: 30px; background-color: #4CAF50; border-radius: 5px; text-align: center; line-height: 30px; color: white; }

        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }

        th { background-color: #f2f2f2; }

    </style>
</head>
<body>
    <h1>Rapport de progression</h1>
    
    <h2>Progression globale</h2>
    <div class="progress-bar">
        <div class="progress" style="width: $taskProgress%">$taskProgress%</div>
    </div>
    
    <h2>Détails</h2>
    <table>
        <tr>
            <th>Élément</th>
            <th>Total</th>
            <th>Terminés</th>
            <th>Progression</th>
        </tr>
        <tr>
            <td>Sections</td>
            <td>$totalSections</td>
            <td>N/A</td>
            <td>N/A</td>
        </tr>
        <tr>
            <td>Phases</td>
            <td>$totalPhases</td>
            <td>$completedPhases</td>
            <td>$phaseProgress%</td>
        </tr>
        <tr>
            <td>Tâches</td>
            <td>$totalTasks</td>
            <td>$completedTasks</td>
            <td>$taskProgress%</td>
        </tr>
        <tr>
            <td>Sous-tâches</td>
            <td>$totalSubtasks</td>
            <td>$completedSubtasks</td>
            <td>$subtaskProgress%</td>
        </tr>
    </table>
</body>
</html>
"@
    
    # Enregistrer le rapport

    Set-Content -Path $OutputPath -Value $html -Encoding UTF8
    
    # Supprimer le fichier temporaire

    Remove-Item -Path $tempXmlPath -Force
    
    return $OutputPath
}

# Utiliser la fonction

$roadmapPath = "chemin/vers/roadmap.md"
$outputPath = "chemin/vers/rapport.html"
$reportPath = Generate-ProgressReport -RoadmapPath $roadmapPath -OutputPath $outputPath
```plaintext
### Exemple 3 : Intégration avec un script de validation de fichiers

```powershell
# Importer le module XmlSupport

$xmlSupportPath = "chemin/vers/FormatSupport/XML_HTML/XmlSupport.ps1"
. $xmlSupportPath

# Fonction pour valider un dossier de fichiers

function Validate-Files {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FolderPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputFolder
    )
    
    # Créer le dossier de sortie s'il n'existe pas

    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory -Force | Out-Null
    }
    
    # Valider les fichiers XML

    $xmlFiles = Get-ChildItem -Path $FolderPath -Filter "*.xml"
    $validXmlFiles = 0
    $invalidXmlFiles = 0
    
    foreach ($xmlFile in $xmlFiles) {
        $result = Test-XmlFile -XmlPath $xmlFile.FullName
        
        if ($result.IsValid) {
            $validXmlFiles++
        }
        else {
            $invalidXmlFiles++
            $reportPath = Join-Path -Path $OutputFolder -ChildPath ($xmlFile.BaseName + "_validation.html")
            $report = Get-XmlValidationReport -ValidationResult $result -AsHtml
            Set-Content -Path $reportPath -Value $report -Encoding UTF8
            Write-Host "Fichier XML invalide: $($xmlFile.Name) - Rapport: $reportPath"
        }
    }
    
    # Générer un rapport global

    $reportPath = Join-Path -Path $OutputFolder -ChildPath "validation_report.html"
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport de validation</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }

        .success { color: green; }
        .error { color: red; }
        table { border-collapse: collapse; width: 100%; margin-top: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }

        th { background-color: #f2f2f2; }

    </style>
</head>
<body>
    <h1>Rapport de validation</h1>
    
    <h2>Résumé</h2>
    <p>Fichiers XML valides: <span class="success">$validXmlFiles</span></p>
    <p>Fichiers XML invalides: <span class="error">$invalidXmlFiles</span></p>
    <p>Total: $($xmlFiles.Count) fichiers</p>
    
    <h2>Fichiers invalides</h2>
    <table>
        <tr>
            <th>Fichier</th>
            <th>Rapport</th>
        </tr>
"@
    
    foreach ($xmlFile in $xmlFiles) {
        $result = Test-XmlFile -XmlPath $xmlFile.FullName
        
        if (-not $result.IsValid) {
            $reportPath = ($xmlFile.BaseName + "_validation.html")
            $html += @"
        <tr>
            <td>$($xmlFile.Name)</td>
            <td><a href="$reportPath">Voir le rapport</a></td>
        </tr>
"@
        }
    }
    
    $html += @"
    </table>
</body>
</html>
"@
    
    Set-Content -Path $reportPath -Value $html -Encoding UTF8
    
    return $reportPath
}

# Utiliser la fonction

$folderPath = "chemin/vers/dossier/de/fichiers"
$outputFolder = "chemin/vers/dossier/de/sortie"
$reportPath = Validate-Files -FolderPath $folderPath -OutputFolder $outputFolder
```plaintext