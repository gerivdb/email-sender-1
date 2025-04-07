# Tests unitaires pour les modules XML et HTML
# Ce script implémente des tests unitaires complets pour les modules XML et HTML

# Importer les modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$implementationPath = Join-Path -Path $scriptPath -ChildPath "..\Implementation"
$xmlHandlerPath = Join-Path -Path $implementationPath -ChildPath "XMLFormatHandler.ps1"
$htmlHandlerPath = Join-Path -Path $implementationPath -ChildPath "HTMLFormatHandler.ps1"
$converterPath = Join-Path -Path $implementationPath -ChildPath "FormatConverter.ps1"
$roadmapXmlConverterPath = Join-Path -Path $implementationPath -ChildPath "RoadmapXmlConverter.ps1"
$xmlElementDetectorPath = Join-Path -Path $implementationPath -ChildPath "XmlElementDetector.ps1"
$xmlValidatorPath = Join-Path -Path $implementationPath -ChildPath "XmlValidator.ps1"

# Créer le dossier de sortie des tests
$testOutputPath = Join-Path -Path $scriptPath -ChildPath "Output"
if (-not (Test-Path -Path $testOutputPath)) {
    New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
}

# Importer les modules
Write-Host "Importation des modules..."
if (Test-Path -Path $xmlHandlerPath) {
    . $xmlHandlerPath
}
if (Test-Path -Path $htmlHandlerPath) {
    . $htmlHandlerPath
}
if (Test-Path -Path $converterPath) {
    . $converterPath
}
if (Test-Path -Path $roadmapXmlConverterPath) {
    . $roadmapXmlConverterPath
}
if (Test-Path -Path $xmlElementDetectorPath) {
    . $xmlElementDetectorPath
}
if (Test-Path -Path $xmlValidatorPath) {
    . $xmlValidatorPath
}

# Fonction pour exécuter les tests unitaires
function Invoke-UnitTests {
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

    # Tests pour XMLFormatHandler
    Write-Host "Tests pour XMLFormatHandler" -ForegroundColor Yellow

    Test-Case -Name "XMLFormatHandler - Parsing XML simple" -Test {
        $xmlString = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <element>Valeur</element>
</root>
"@

        $xmlDoc = ConvertFrom-Xml -XmlString $xmlString

        if (-not ($xmlDoc -is [System.Xml.XmlDocument])) {
            throw "Le résultat n'est pas un XmlDocument"
        }

        $element = $xmlDoc.SelectSingleNode("//element")
        if (-not $element -or $element.InnerText -ne "Valeur") {
            throw "L'élément n'a pas été correctement parsé"
        }
    }

    Test-Case -Name "XMLFormatHandler - Génération XML" -Test {
        $data = @{
            element = "Valeur"
            nested = @{
                subelement = "Sous-valeur"
            }
        }

        $xmlString = ConvertTo-Xml -InputObject $data

        if (-not $xmlString.Contains("<element>Valeur</element>")) {
            throw "L'élément n'a pas été correctement généré"
        }

        if (-not $xmlString.Contains("<subelement>Sous-valeur</subelement>")) {
            throw "Le sous-élément n'a pas été correctement généré"
        }
    }

    Test-Case -Name "XMLFormatHandler - Import/Export de fichier" -Test {
        $data = @{
            element = "Valeur"
            nested = @{
                subelement = "Sous-valeur"
            }
        }

        $xmlPath = Join-Path -Path $testOutputPath -ChildPath "test_xml_handler.xml"

        # Exporter les données
        Export-XmlFile -InputObject $data -FilePath $xmlPath

        # Vérifier que le fichier a été créé
        if (-not (Test-Path -Path $xmlPath)) {
            throw "Le fichier XML n'a pas été créé"
        }

        # Importer les données
        $importedData = Import-XmlFile -FilePath $xmlPath

        # Vérifier que les données ont été correctement importées
        $element = $importedData.SelectSingleNode("//element")
        if (-not $element -or $element.InnerText -ne "Valeur") {
            throw "L'élément n'a pas été correctement importé"
        }

        $subelement = $importedData.SelectSingleNode("//subelement")
        if (-not $subelement -or $subelement.InnerText -ne "Sous-valeur") {
            throw "Le sous-élément n'a pas été correctement importé"
        }
    }

    # Tests pour HTMLFormatHandler
    Write-Host "Tests pour HTMLFormatHandler" -ForegroundColor Yellow

    Test-Case -Name "HTMLFormatHandler - Parsing HTML simple" -Test {
        $htmlString = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test</title>
</head>
<body>
    <h1>Titre</h1>
    <p>Paragraphe</p>
</body>
</html>
"@

        # Vérifier si HtmlAgilityPack est disponible
        if (-not (Test-HtmlAgilityPackAvailable)) {
            Write-Host "  Installation de HtmlAgilityPack..." -ForegroundColor Yellow
            Install-HtmlAgilityPack
        }

        $htmlDoc = ConvertFrom-Html -HtmlString $htmlString

        if (-not ($htmlDoc -is [HtmlAgilityPack.HtmlDocument])) {
            throw "Le résultat n'est pas un HtmlDocument"
        }

        $h1 = $htmlDoc.DocumentNode.SelectSingleNode("//h1")
        if (-not $h1 -or $h1.InnerText -ne "Titre") {
            throw "L'élément h1 n'a pas été correctement parsé"
        }

        $p = $htmlDoc.DocumentNode.SelectSingleNode("//p")
        if (-not $p -or $p.InnerText -ne "Paragraphe") {
            throw "L'élément p n'a pas été correctement parsé"
        }
    }

    Test-Case -Name "HTMLFormatHandler - Sanitisation HTML" -Test {
        $htmlString = @"
<!DOCTYPE html>
<html>
<body>
    <h1>Titre</h1>
    <p>Paragraphe</p>
    <script>alert('XSS');</script>
    <iframe src="https://malicious.com"></iframe>
    <a href="javascript:alert('XSS')">Lien malveillant</a>
    <a href="https://example.com">Lien sûr</a>
</body>
</html>
"@

        $htmlDoc = ConvertFrom-Html -HtmlString $htmlString -Sanitize

        # Vérifier que les éléments dangereux ont été supprimés
        $script = $htmlDoc.DocumentNode.SelectSingleNode("//script")
        if (-not ($null -eq $script)) {
            throw "L'élément script n'a pas été supprimé"
        }

        $iframe = $htmlDoc.DocumentNode.SelectSingleNode("//iframe")
        if (-not ($null -eq $iframe)) {
            throw "L'élément iframe n'a pas été supprimé"
        }

        # Vérifier que les liens malveillants ont été nettoyés
        $maliciousLink = $htmlDoc.DocumentNode.SelectSingleNode("//a[@href='javascript:alert(\'XSS\')']")
        if (-not ($null -eq $maliciousLink)) {
            throw "Le lien malveillant n'a pas été nettoyé"
        }

        # Vérifier que les liens sûrs sont conservés
        $safeLink = $htmlDoc.DocumentNode.SelectSingleNode("//a[@href='https://example.com']")
        if ($null -eq $safeLink) {
            throw "Le lien sûr a été supprimé"
        }
    }

    Test-Case -Name "HTMLFormatHandler - Requête CSS" -Test {
        $htmlString = @"
<!DOCTYPE html>
<html>
<body>
    <h1>Titre</h1>
    <p class="important">Paragraphe important</p>
    <p>Paragraphe normal</p>
    <div id="content">
        <p>Paragraphe dans div</p>
    </div>
</body>
</html>
"@

        $htmlDoc = ConvertFrom-Html -HtmlString $htmlString

        # Requête par balise
        $paragraphs = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector "p"
        if ($paragraphs.Count -ne 3) {
            throw "Nombre incorrect de paragraphes: $($paragraphs.Count)"
        }

        # Requête par classe
        $importantParagraphs = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector "p.important"
        if ($importantParagraphs.Count -ne 1 -or $importantParagraphs[0].InnerText -ne "Paragraphe important") {
            throw "Paragraphe important non trouvé"
        }

        # Requête par ID
        $content = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector "#content"
        if ($content.Count -ne 1) {
            throw "Div content non trouvé"
        }

        # Requête imbriquée
        $contentParagraphs = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector "#content p"
        if ($contentParagraphs.Count -ne 1 -or $contentParagraphs[0].InnerText -ne "Paragraphe dans div") {
            throw "Paragraphe dans div non trouvé"
        }
    }

    # Tests pour FormatConverter
    Write-Host "Tests pour FormatConverter" -ForegroundColor Yellow

    Test-Case -Name "FormatConverter - Conversion XML vers HTML" -Test {
        $xmlString = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <person id="1">
    <name>John Doe</name>
    <age>30</age>
    <email>john.doe@example.com</email>
  </person>
  <person id="2">
    <name>Jane Smith</name>
    <age>25</age>
    <email>jane.smith@example.com</email>
  </person>
</root>
"@

        $xmlDoc = ConvertFrom-Xml -XmlString $xmlString
        $htmlDoc = ConvertFrom-XmlToHtml -XmlDocument $xmlDoc

        if (-not ($htmlDoc -is [HtmlAgilityPack.HtmlDocument])) {
            throw "Le résultat n'est pas un HtmlDocument"
        }

        $persons = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector ".xml-element"
        if ($persons.Count -lt 2) {
            throw "Nombre incorrect d'éléments convertis"
        }

        $names = Invoke-CssQuery -HtmlDocument $htmlDoc -CssSelector "h3"
        if ($names.Count -lt 3) { # 1 pour root + 2 pour person
            throw "Nombre incorrect de titres"
        }

        $htmlPath = Join-Path -Path $testOutputPath -ChildPath "xml_to_html_converter.html"
        Export-HtmlFile -HtmlDocument $htmlDoc -FilePath $htmlPath

        Write-Host "  HTML généré enregistré dans: $htmlPath"
    }

    Test-Case -Name "FormatConverter - Conversion HTML vers XML" -Test {
        $htmlString = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test</title>
</head>
<body>
    <h1>Titre</h1>
    <p>Paragraphe</p>
    <ul>
        <li>Item 1</li>
        <li>Item 2</li>
    </ul>
</body>
</html>
"@

        $htmlDoc = ConvertFrom-Html -HtmlString $htmlString
        $xmlDoc = ConvertFrom-HtmlToXml -HtmlDocument $htmlDoc

        if (-not ($xmlDoc -is [System.Xml.XmlDocument])) {
            throw "Le résultat n'est pas un XmlDocument"
        }

        $h1 = $xmlDoc.SelectSingleNode("//h1")
        if (-not $h1 -or $h1.InnerText -ne "Titre") {
            throw "L'élément h1 n'a pas été correctement converti"
        }

        $li = $xmlDoc.SelectNodes("//li")
        if ($li.Count -ne 2) {
            throw "Nombre incorrect d'éléments li: $($li.Count)"
        }

        $xmlPath = Join-Path -Path $testOutputPath -ChildPath "html_to_xml_converter.xml"
        $xmlDoc.Save($xmlPath)

        Write-Host "  XML généré enregistré dans: $xmlPath"
    }

    # Tests pour RoadmapXmlConverter
    Write-Host "Tests pour RoadmapXmlConverter" -ForegroundColor Yellow

    Test-Case -Name "RoadmapXmlConverter - Conversion Roadmap vers XML" -Test {
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

        $sectionElement = $rootElement.SelectSingleNode("section")
        if (-not $sectionElement -or $sectionElement.GetAttribute("id") -ne "1" -or $sectionElement.GetAttribute("title") -ne "Section de test") {
            throw "La section est incorrecte"
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
        $outputPath = Join-Path -Path $testOutputPath -ChildPath "roadmap_to_xml_converter.xml"
        Set-Content -Path $outputPath -Value $xmlContent -Encoding UTF8

        Write-Host "  XML généré enregistré dans: $outputPath"
    }

    Test-Case -Name "RoadmapXmlConverter - Conversion XML vers Roadmap" -Test {
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
        $outputPath = Join-Path -Path $testOutputPath -ChildPath "xml_to_roadmap_converter.md"
        Set-Content -Path $outputPath -Value $roadmapContent -Encoding UTF8

        Write-Host "  Markdown généré enregistré dans: $outputPath"
    }

    # Tests pour XmlElementDetector
    Write-Host "Tests pour XmlElementDetector" -ForegroundColor Yellow

    Test-Case -Name "XmlElementDetector - Détection des éléments XML" -Test {
        $xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<root attr1="value1" attr2="value2">
  <element1>Text content</element1>
  <element2>
    <nested>Nested content</nested>
  </element2>
  <element3 attr3="value3" />
</root>
"@

        $elements = Get-XmlElements -XmlContent $xmlContent

        if ($elements.Count -lt 4) { # root, element1, element2, nested, element3
            throw "Nombre d'éléments détectés insuffisant: $($elements.Count)"
        }

        $rootElement = $elements | Where-Object { $_.Depth -eq 0 }
        if (-not $rootElement -or $rootElement.Name -ne "root") {
            throw "Élément racine incorrect: $($rootElement.Name)"
        }

        if ($rootElement.Attributes.Count -ne 2) {
            throw "Nombre d'attributs de l'élément racine incorrect: $($rootElement.Attributes.Count)"
        }

        if ($rootElement.Attributes["attr1"] -ne "value1" -or $rootElement.Attributes["attr2"] -ne "value2") {
            throw "Attributs de l'élément racine incorrects"
        }

        $element1 = $elements | Where-Object { $_.Name -eq "element1" }
        if (-not $element1 -or $element1.Value -ne "Text content") {
            throw "Élément element1 incorrect"
        }

        $nested = $elements | Where-Object { $_.Name -eq "nested" }
        if (-not $nested -or $nested.Value -ne "Nested content") {
            throw "Élément nested incorrect"
        }

        $element3 = $elements | Where-Object { $_.Name -eq "element3" }
        if (-not $element3 -or $element3.Attributes["attr3"] -ne "value3") {
            throw "Élément element3 incorrect"
        }
    }

    Test-Case -Name "XmlElementDetector - Génération de rapport de structure" -Test {
        $xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <element1>Text content</element1>
  <element2>
    <nested>Nested content</nested>
  </element2>
  <element3 attr3="value3" />
</root>
"@

        $report = Get-XmlStructureReport -XmlContent $xmlContent

        if (-not $report.Contains("Rapport de structure XML")) {
            throw "Le rapport ne contient pas le titre"
        }

        if (-not $report.Contains("root")) {
            throw "Le rapport ne contient pas l'élément racine"
        }

        if (-not $report.Contains("element1")) {
            throw "Le rapport ne contient pas element1"
        }

        if (-not $report.Contains("nested")) {
            throw "Le rapport ne contient pas nested"
        }

        if (-not $report.Contains("attr3 = value3")) {
            throw "Le rapport ne contient pas l'attribut attr3"
        }

        # Générer un rapport HTML
        $htmlReport = Get-XmlStructureReport -XmlContent $xmlContent -AsHtml

        if (-not $htmlReport.Contains("<title>Rapport de structure XML</title>")) {
            throw "Le rapport HTML ne contient pas le titre"
        }

        # Vérifier que le rapport HTML contient l'élément racine
        if (-not $htmlReport.Contains("<td class=`"element-name`">root</td>")) {
            throw "Le rapport HTML ne contient pas l'élément racine"
        }

        # Enregistrer les rapports pour inspection
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "xml_structure_report_unit.txt"
        Set-Content -Path $reportPath -Value $report

        $htmlReportPath = Join-Path -Path $testOutputPath -ChildPath "xml_structure_report_unit.html"
        Set-Content -Path $htmlReportPath -Value $htmlReport -Encoding UTF8

        Write-Host "  Rapport de structure généré: $reportPath"
        Write-Host "  Rapport de structure HTML généré: $htmlReportPath"
    }

    # Tests pour XmlValidator
    Write-Host "Tests pour XmlValidator" -ForegroundColor Yellow

    Test-Case -Name "XmlValidator - Validation XML bien formé" -Test {
        $xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <element>Content</element>
</root>
"@

        $result = Test-XmlContent -XmlContent $xmlContent

        if (-not $result.IsValid) {
            throw "Le XML bien formé a été validé comme invalide"
        }

        if ($result.Errors.Count -ne 0) {
            throw "Des erreurs ont été détectées dans le XML bien formé"
        }

        if ($result.XmlVersion -ne "1.0") {
            throw "Version XML incorrecte: $($result.XmlVersion)"
        }

        if ($result.Encoding -ne "UTF-8") {
            throw "Encodage incorrect: $($result.Encoding)"
        }
    }

    Test-Case -Name "XmlValidator - Validation XML mal formé" -Test {
        $xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <element>Content</element>
</root
"@

        $result = Test-XmlContent -XmlContent $xmlContent

        if ($result.IsValid) {
            throw "Le XML mal formé a été validé comme valide"
        }

        if ($result.Errors.Count -eq 0) {
            throw "Aucune erreur détectée dans le XML mal formé"
        }
    }

    Test-Case -Name "XmlValidator - Génération de rapport de validation" -Test {
        $xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
  <element>Content</element>
</root>
"@

        $result = Test-XmlContent -XmlContent $xmlContent
        $report = Get-XmlValidationReport -ValidationResult $result

        if (-not $report.Contains("Rapport de validation XML")) {
            throw "Le rapport ne contient pas le titre"
        }

        if (-not $report.Contains("Validation: Réussie")) {
            throw "Le rapport ne contient pas le statut de validation"
        }

        if (-not $report.Contains("Version XML: 1.0")) {
            throw "Le rapport ne contient pas la version XML"
        }

        if (-not $report.Contains("Encodage: UTF-8")) {
            throw "Le rapport ne contient pas l'encodage"
        }

        # Générer un rapport HTML
        $htmlReport = Get-XmlValidationReport -ValidationResult $result -AsHtml

        if (-not $htmlReport.Contains("<title>Rapport de validation XML</title>")) {
            throw "Le rapport HTML ne contient pas le titre"
        }

        # Vérifier que le rapport HTML contient le statut de validation
        if (-not $htmlReport.Contains("<span class=`"success`">Réussie</span>")) {
            throw "Le rapport HTML ne contient pas le statut de validation"
        }

        # Enregistrer les rapports pour inspection
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "xml_validation_report_unit.txt"
        Set-Content -Path $reportPath -Value $report

        $htmlReportPath = Join-Path -Path $testOutputPath -ChildPath "xml_validation_report_unit.html"
        Set-Content -Path $htmlReportPath -Value $htmlReport -Encoding UTF8

        Write-Host "  Rapport de validation généré: $reportPath"
        Write-Host "  Rapport de validation HTML généré: $htmlReportPath"
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
Write-Host "Exécution des tests unitaires..." -ForegroundColor Yellow
$results = Invoke-UnitTests

# Afficher le chemin des fichiers de sortie
Write-Host "Les fichiers de sortie des tests sont disponibles dans: $testOutputPath" -ForegroundColor Cyan

# Retourner les résultats
return $results
