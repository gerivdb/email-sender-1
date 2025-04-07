# Script de test pour le convertisseur Roadmap-XML

# Importer le module de conversion
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$implementationPath = Join-Path -Path $scriptPath -ChildPath "..\Implementation"
$converterPath = Join-Path -Path $implementationPath -ChildPath "RoadmapXmlConverter.ps1"

# Créer le dossier de sortie des tests
$testOutputPath = Join-Path -Path $scriptPath -ChildPath "Output"
if (-not (Test-Path -Path $testOutputPath)) {
    New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
}

# Importer le module
Write-Host "Importation du module de conversion Roadmap-XML..."
. $converterPath

# Fonction pour exécuter les tests
function Invoke-RoadmapXmlConverterTests {
    # Compteurs de tests
    $totalTests = 0
    $passedTests = 0
    $failedTests = 0
    
    # Fonction pour exécuter un test
    function Test-Case {
        param (
            [string]$Name,
            [scriptblock]$Test
        )
        
        $totalTests++
        Write-Host "Test: $Name" -ForegroundColor Cyan
        
        try {
            & $Test
            Write-Host "  Réussi" -ForegroundColor Green
            $script:passedTests++
        }
        catch {
            Write-Host "  Échoué: $_" -ForegroundColor Red
            $script:failedTests++
        }
        
        Write-Host ""
    }
    
    # Test 1: Conversion Roadmap vers XML
    Test-Case -Name "Conversion Roadmap vers XML" -Test {
        $roadmapContent = @"
# Roadmap de test

## Vue d'ensemble des taches par priorite et complexite

Ceci est une vue d'ensemble de test.

## 1. Section de test
**Complexite**: Moyenne
**Temps estime**: 3-5 jours
**Progression**: 50%

- [ ] **Phase 1: Test**
  - [x] Tâche 1 (1 jour) - *Démarrée le 01/01/2025*
    - [x] Sous-tâche 1
    - [ ] Sous-tâche 2
  - [ ] Tâche 2 (2 jours)
  > *Note: Ceci est une note*

"@
        
        $xmlContent = ConvertFrom-RoadmapToXml -RoadmapContent $roadmapContent
        
        # Vérifier que le XML est valide
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDoc.LoadXml($xmlContent)
        
        # Vérifier la structure du XML
        $rootElement = $xmlDoc.DocumentElement
        if ($rootElement.Name -ne "roadmap") {
            throw "L'élément racine n'est pas 'roadmap'"
        }
        
        if ($rootElement.GetAttribute("title") -ne "Roadmap de test") {
            throw "Le titre est incorrect: $($rootElement.GetAttribute('title'))"
        }
        
        $overviewElement = $rootElement.SelectSingleNode("overview")
        if (-not $overviewElement -or $overviewElement.InnerText -ne "Ceci est une vue d'ensemble de test.") {
            throw "La vue d'ensemble est incorrecte"
        }
        
        $sectionElement = $rootElement.SelectSingleNode("section")
        if (-not $sectionElement -or $sectionElement.GetAttribute("id") -ne "1" -or $sectionElement.GetAttribute("title") -ne "Section de test") {
            throw "La section est incorrecte"
        }
        
        $metadataElement = $sectionElement.SelectSingleNode("metadata")
        if (-not $metadataElement) {
            throw "L'élément metadata est manquant"
        }
        
        $complexityElement = $metadataElement.SelectSingleNode("Complexite")
        if (-not $complexityElement -or $complexityElement.InnerText -ne "Moyenne") {
            throw "La complexité est incorrecte"
        }
        
        $phaseElement = $sectionElement.SelectSingleNode("phase")
        if (-not $phaseElement -or $phaseElement.GetAttribute("id") -ne "1" -or $phaseElement.GetAttribute("title") -ne "Test") {
            throw "La phase est incorrecte"
        }
        
        $taskElement = $phaseElement.SelectSingleNode("task")
        if (-not $taskElement -or $taskElement.GetAttribute("title") -ne "Tâche 1") {
            throw "La tâche est incorrecte"
        }
        
        $subtaskElement = $taskElement.SelectSingleNode("subtask")
        if (-not $subtaskElement -or $subtaskElement.GetAttribute("title") -ne "Sous-tâche 1") {
            throw "La sous-tâche est incorrecte"
        }
        
        $noteElement = $phaseElement.SelectSingleNode("note")
        if (-not $noteElement -or $noteElement.InnerText -ne "Ceci est une note") {
            throw "La note est incorrecte"
        }
        
        # Enregistrer le XML généré pour inspection
        $outputPath = Join-Path -Path $testOutputPath -ChildPath "roadmap_to_xml.xml"
        Set-Content -Path $outputPath -Value $xmlContent -Encoding UTF8
        
        Write-Host "  XML généré enregistré dans: $outputPath"
    }
    
    # Test 2: Conversion XML vers Roadmap
    Test-Case -Name "Conversion XML vers Roadmap" -Test {
        $xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<roadmap title="Roadmap de test">
  <overview>Ceci est une vue d'ensemble de test.</overview>
  <section id="1" title="Section de test">
    <metadata>
      <Complexite>Moyenne</Complexite>
      <Temps_estime>3-5 jours</Temps_estime>
      <Progression>50%</Progression>
    </metadata>
    <phase id="1" title="Test" completed="false">
      <task title="Tâche 1" estimatedTime="1 jour" startDate="Démarrée le 01/01/2025" completed="true">
        <subtask title="Sous-tâche 1" completed="true" />
        <subtask title="Sous-tâche 2" completed="false" />
      </task>
      <task title="Tâche 2" estimatedTime="2 jours" completed="false" />
      <note>Ceci est une note</note>
    </phase>
  </section>
</roadmap>
"@
        
        $roadmapContent = ConvertFrom-XmlToRoadmap -XmlContent $xmlContent
        
        # Vérifier que le Markdown est valide
        if (-not $roadmapContent.StartsWith("# Roadmap de test")) {
            throw "Le titre est incorrect"
        }
        
        if (-not $roadmapContent.Contains("## Vue d'ensemble")) {
            throw "La vue d'ensemble est manquante"
        }
        
        if (-not $roadmapContent.Contains("## 1. Section de test")) {
            throw "La section est incorrecte"
        }
        
        if (-not $roadmapContent.Contains("**Complexite**: Moyenne")) {
            throw "La complexité est incorrecte"
        }
        
        if (-not $roadmapContent.Contains("- [ ] **Phase 1: Test**")) {
            throw "La phase est incorrecte"
        }
        
        if (-not $roadmapContent.Contains("  - [x] Tâche 1 (1 jour) - *Démarrée le 01/01/2025*")) {
            throw "La tâche est incorrecte"
        }
        
        if (-not $roadmapContent.Contains("    - [x] Sous-tâche 1")) {
            throw "La sous-tâche est incorrecte"
        }
        
        if (-not $roadmapContent.Contains("  > *Note: Ceci est une note*")) {
            throw "La note est incorrecte"
        }
        
        # Enregistrer le Markdown généré pour inspection
        $outputPath = Join-Path -Path $testOutputPath -ChildPath "xml_to_roadmap.md"
        Set-Content -Path $outputPath -Value $roadmapContent -Encoding UTF8
        
        Write-Host "  Markdown généré enregistré dans: $outputPath"
    }
    
    # Test 3: Conversion aller-retour
    Test-Case -Name "Conversion aller-retour (Roadmap -> XML -> Roadmap)" -Test {
        $originalRoadmap = @"
# Roadmap de test

## Vue d'ensemble des taches par priorite et complexite

Ceci est une vue d'ensemble de test.

## 1. Section de test
**Complexite**: Moyenne
**Temps estime**: 3-5 jours
**Progression**: 50%

- [ ] **Phase 1: Test**
  - [x] Tâche 1 (1 jour) - *Démarrée le 01/01/2025*
    - [x] Sous-tâche 1
    - [ ] Sous-tâche 2
  - [ ] Tâche 2 (2 jours)
  > *Note: Ceci est une note*

"@
        
        # Roadmap -> XML
        $xmlContent = ConvertFrom-RoadmapToXml -RoadmapContent $originalRoadmap
        
        # XML -> Roadmap
        $convertedRoadmap = ConvertFrom-XmlToRoadmap -XmlContent $xmlContent
        
        # Enregistrer les fichiers pour inspection
        $originalPath = Join-Path -Path $testOutputPath -ChildPath "original_roadmap.md"
        $convertedPath = Join-Path -Path $testOutputPath -ChildPath "converted_roadmap.md"
        
        Set-Content -Path $originalPath -Value $originalRoadmap -Encoding UTF8
        Set-Content -Path $convertedPath -Value $convertedRoadmap -Encoding UTF8
        
        Write-Host "  Roadmap original enregistré dans: $originalPath"
        Write-Host "  Roadmap converti enregistré dans: $convertedPath"
        
        # Vérifier que les éléments essentiels sont préservés
        $essentialElements = @(
            "# Roadmap de test",
            "## Vue d'ensemble",
            "Ceci est une vue d'ensemble de test.",
            "## 1. Section de test",
            "**Complexite**: Moyenne",
            "**Temps estime**: 3-5 jours",
            "**Progression**: 50%",
            "- [ ] **Phase 1: Test**",
            "  - [x] Tâche 1 (1 jour) - *Démarrée le 01/01/2025*",
            "    - [x] Sous-tâche 1",
            "    - [ ] Sous-tâche 2",
            "  - [ ] Tâche 2 (2 jours)",
            "  > *Note: Ceci est une note*"
        )
        
        foreach ($element in $essentialElements) {
            if (-not $convertedRoadmap.Contains($element)) {
                throw "Élément manquant dans le Roadmap converti: $element"
            }
        }
    }
    
    # Test 4: Conversion de fichier Roadmap vers fichier XML
    Test-Case -Name "Conversion de fichier Roadmap vers fichier XML" -Test {
        # Créer un fichier Roadmap temporaire
        $roadmapContent = @"
# Roadmap de test

## Vue d'ensemble des taches par priorite et complexite

Ceci est une vue d'ensemble de test.

## 1. Section de test
**Complexite**: Moyenne
**Temps estime**: 3-5 jours
**Progression**: 50%

- [ ] **Phase 1: Test**
  - [x] Tâche 1 (1 jour) - *Démarrée le 01/01/2025*
    - [x] Sous-tâche 1
    - [ ] Sous-tâche 2
  - [ ] Tâche 2 (2 jours)
  > *Note: Ceci est une note*

"@
        
        $roadmapPath = Join-Path -Path $testOutputPath -ChildPath "test_roadmap.md"
        $xmlPath = Join-Path -Path $testOutputPath -ChildPath "test_roadmap.xml"
        
        Set-Content -Path $roadmapPath -Value $roadmapContent -Encoding UTF8
        
        # Convertir le fichier
        ConvertFrom-RoadmapFileToXmlFile -RoadmapPath $roadmapPath -XmlPath $xmlPath
        
        # Vérifier que le fichier XML a été créé
        if (-not (Test-Path -Path $xmlPath)) {
            throw "Le fichier XML n'a pas été créé"
        }
        
        # Vérifier que le XML est valide
        $xmlContent = Get-Content -Path $xmlPath -Raw
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDoc.LoadXml($xmlContent)
        
        # Vérifier la structure du XML
        $rootElement = $xmlDoc.DocumentElement
        if ($rootElement.Name -ne "roadmap") {
            throw "L'élément racine n'est pas 'roadmap'"
        }
        
        Write-Host "  Fichier XML généré: $xmlPath"
    }
    
    # Test 5: Conversion de fichier XML vers fichier Roadmap
    Test-Case -Name "Conversion de fichier XML vers fichier Roadmap" -Test {
        # Créer un fichier XML temporaire
        $xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<roadmap title="Roadmap de test">
  <overview>Ceci est une vue d'ensemble de test.</overview>
  <section id="1" title="Section de test">
    <metadata>
      <Complexite>Moyenne</Complexite>
      <Temps_estime>3-5 jours</Temps_estime>
      <Progression>50%</Progression>
    </metadata>
    <phase id="1" title="Test" completed="false">
      <task title="Tâche 1" estimatedTime="1 jour" startDate="Démarrée le 01/01/2025" completed="true">
        <subtask title="Sous-tâche 1" completed="true" />
        <subtask title="Sous-tâche 2" completed="false" />
      </task>
      <task title="Tâche 2" estimatedTime="2 jours" completed="false" />
      <note>Ceci est une note</note>
    </phase>
  </section>
</roadmap>
"@
        
        $xmlPath = Join-Path -Path $testOutputPath -ChildPath "test_xml.xml"
        $roadmapPath = Join-Path -Path $testOutputPath -ChildPath "test_xml.md"
        
        Set-Content -Path $xmlPath -Value $xmlContent -Encoding UTF8
        
        # Convertir le fichier
        ConvertFrom-XmlFileToRoadmapFile -XmlPath $xmlPath -RoadmapPath $roadmapPath
        
        # Vérifier que le fichier Roadmap a été créé
        if (-not (Test-Path -Path $roadmapPath)) {
            throw "Le fichier Roadmap n'a pas été créé"
        }
        
        # Vérifier que le Markdown est valide
        $roadmapContent = Get-Content -Path $roadmapPath -Raw
        
        if (-not $roadmapContent.StartsWith("# Roadmap de test")) {
            throw "Le titre est incorrect"
        }
        
        Write-Host "  Fichier Roadmap généré: $roadmapPath"
    }
    
    # Afficher le résumé des tests
    Write-Host "Résumé des tests:" -ForegroundColor Yellow
    Write-Host "  Total: $totalTests" -ForegroundColor Cyan
    Write-Host "  Réussis: $passedTests" -ForegroundColor Green
    Write-Host "  Échoués: $failedTests" -ForegroundColor Red
    
    return @{
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
    }
}

# Exécuter les tests
Write-Host "Exécution des tests du convertisseur Roadmap-XML..." -ForegroundColor Yellow
$results = Invoke-RoadmapXmlConverterTests

# Afficher le chemin des fichiers de sortie
Write-Host "Les fichiers de sortie des tests sont disponibles dans: $testOutputPath" -ForegroundColor Cyan

# Retourner les résultats
return $results
