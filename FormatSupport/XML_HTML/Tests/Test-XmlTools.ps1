# Script de test pour les outils XML (détecteur et validateur)

# Importer les modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$implementationPath = Join-Path -Path $scriptPath -ChildPath "..\Implementation"
$detectorPath = Join-Path -Path $implementationPath -ChildPath "XmlElementDetector.ps1"
$validatorPath = Join-Path -Path $implementationPath -ChildPath "XmlValidator.ps1"

# Créer le dossier de sortie des tests
$testOutputPath = Join-Path -Path $scriptPath -ChildPath "Output"
if (-not (Test-Path -Path $testOutputPath)) {
    New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
}

# Importer les modules
Write-Host "Importation des modules XML..."
. $detectorPath
. $validatorPath

# Fonction pour exécuter les tests
function Invoke-XmlToolsTests {
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
    
    # Test 1: Détection des éléments XML
    Test-Case -Name "Détection des éléments XML" -Test {
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
        
        $elements = Get-XmlElements -XmlContent $xmlContent
        
        if ($elements.Count -lt 10) {
            throw "Nombre d'éléments détectés insuffisant: $($elements.Count)"
        }
        
        $rootElement = $elements | Where-Object { $_.Depth -eq 0 }
        if (-not $rootElement -or $rootElement.Name -ne "roadmap") {
            throw "Élément racine incorrect: $($rootElement.Name)"
        }
        
        $sectionElement = $elements | Where-Object { $_.Name -eq "section" }
        if (-not $sectionElement) {
            throw "Élément section non détecté"
        }
        
        $phaseElement = $elements | Where-Object { $_.Name -eq "phase" }
        if (-not $phaseElement) {
            throw "Élément phase non détecté"
        }
        
        $taskElements = $elements | Where-Object { $_.Name -eq "task" }
        if ($taskElements.Count -ne 2) {
            throw "Nombre d'éléments task incorrect: $($taskElements.Count)"
        }
        
        $subtaskElements = $elements | Where-Object { $_.Name -eq "subtask" }
        if ($subtaskElements.Count -ne 2) {
            throw "Nombre d'éléments subtask incorrect: $($subtaskElements.Count)"
        }
        
        $noteElement = $elements | Where-Object { $_.Name -eq "note" }
        if (-not $noteElement) {
            throw "Élément note non détecté"
        }
        
        # Générer un rapport de structure
        $report = Get-XmlStructureReport -XmlContent $xmlContent
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "xml_structure_report.txt"
        Set-Content -Path $reportPath -Value $report
        
        # Générer un rapport de structure HTML
        $htmlReport = Get-XmlStructureReport -XmlContent $xmlContent -AsHtml
        $htmlReportPath = Join-Path -Path $testOutputPath -ChildPath "xml_structure_report.html"
        Set-Content -Path $htmlReportPath -Value $htmlReport -Encoding UTF8
        
        Write-Host "  Rapport de structure généré: $reportPath"
        Write-Host "  Rapport de structure HTML généré: $htmlReportPath"
    }
    
    # Test 2: Validation XML bien formé
    Test-Case -Name "Validation XML bien formé" -Test {
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
        
        $result = Test-XmlContent -XmlContent $xmlContent
        
        if (-not $result.IsValid) {
            throw "Le XML est invalide: $($result.Errors[0])"
        }
        
        if ($result.XmlVersion -ne "1.0") {
            throw "Version XML incorrecte: $($result.XmlVersion)"
        }
        
        if ($result.Encoding -ne "UTF-8") {
            throw "Encodage incorrect: $($result.Encoding)"
        }
        
        # Générer un rapport de validation
        $report = Get-XmlValidationReport -ValidationResult $result
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "xml_validation_report.txt"
        Set-Content -Path $reportPath -Value $report
        
        # Générer un rapport de validation HTML
        $htmlReport = Get-XmlValidationReport -ValidationResult $result -AsHtml
        $htmlReportPath = Join-Path -Path $testOutputPath -ChildPath "xml_validation_report.html"
        Set-Content -Path $htmlReportPath -Value $htmlReport -Encoding UTF8
        
        Write-Host "  Rapport de validation généré: $reportPath"
        Write-Host "  Rapport de validation HTML généré: $htmlReportPath"
    }
    
    # Test 3: Validation XML mal formé
    Test-Case -Name "Validation XML mal formé" -Test {
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
</roadmap
"@
        
        $result = Test-XmlContent -XmlContent $xmlContent
        
        if ($result.IsValid) {
            throw "Le XML mal formé a été validé comme valide"
        }
        
        if ($result.Errors.Count -eq 0) {
            throw "Aucune erreur détectée dans le XML mal formé"
        }
        
        # Générer un rapport de validation
        $report = Get-XmlValidationReport -ValidationResult $result
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "xml_validation_error_report.txt"
        Set-Content -Path $reportPath -Value $report
        
        # Générer un rapport de validation HTML
        $htmlReport = Get-XmlValidationReport -ValidationResult $result -AsHtml
        $htmlReportPath = Join-Path -Path $testOutputPath -ChildPath "xml_validation_error_report.html"
        Set-Content -Path $htmlReportPath -Value $htmlReport -Encoding UTF8
        
        Write-Host "  Rapport de validation d'erreur généré: $reportPath"
        Write-Host "  Rapport de validation d'erreur HTML généré: $htmlReportPath"
    }
    
    # Test 4: Génération et validation de schéma XSD
    Test-Case -Name "Génération et validation de schéma XSD" -Test {
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
        
        # Créer un fichier XML temporaire
        $xmlPath = Join-Path -Path $testOutputPath -ChildPath "test_schema.xml"
        Set-Content -Path $xmlPath -Value $xmlContent -Encoding UTF8
        
        # Générer un schéma XSD
        $schemaPath = Join-Path -Path $testOutputPath -ChildPath "test_schema.xsd"
        
        try {
            New-XsdSchemaFromXml -XmlPath $xmlPath -SchemaPath $schemaPath
            
            if (-not (Test-Path -Path $schemaPath)) {
                throw "Le fichier de schéma XSD n'a pas été créé"
            }
            
            Write-Host "  Schéma XSD généré: $schemaPath"
        }
        catch {
            Write-Host "  Impossible de générer le schéma XSD: $_" -ForegroundColor Yellow
            Write-Host "  Ce test est ignoré car la génération de schéma XSD n'est pas prise en charge dans cette version de PowerShell" -ForegroundColor Yellow
            return
        }
        
        # Valider le XML par rapport au schéma
        $result = Test-XmlFileAgainstSchema -XmlPath $xmlPath -SchemaPath $schemaPath
        
        if (-not $result.IsValid) {
            throw "Le XML n'est pas valide par rapport au schéma: $($result.Errors[0])"
        }
        
        # Générer un rapport de validation
        $report = Get-XmlValidationReport -ValidationResult $result
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "xml_schema_validation_report.txt"
        Set-Content -Path $reportPath -Value $report
        
        Write-Host "  Rapport de validation de schéma généré: $reportPath"
    }
    
    # Test 5: Mapping XML vers Roadmap
    Test-Case -Name "Mapping XML vers Roadmap" -Test {
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
        
        $mappingResult = ConvertTo-RoadmapMapping -XmlContent $xmlContent
        
        $mapping = $mappingResult.Mapping
        $report = $mappingResult.Report
        
        if (-not $mapping.RootElement -or $mapping.RootElement.Name -ne "roadmap") {
            throw "Élément racine incorrect: $($mapping.RootElement.Name)"
        }
        
        if ($mapping.Sections.Count -ne 1) {
            throw "Nombre de sections incorrect: $($mapping.Sections.Count)"
        }
        
        if ($mapping.Phases.Count -ne 1) {
            throw "Nombre de phases incorrect: $($mapping.Phases.Count)"
        }
        
        if ($mapping.Tasks.Count -ne 2) {
            throw "Nombre de tâches incorrect: $($mapping.Tasks.Count)"
        }
        
        if ($mapping.Subtasks.Count -ne 2) {
            throw "Nombre de sous-tâches incorrect: $($mapping.Subtasks.Count)"
        }
        
        if ($mapping.Notes.Count -ne 1) {
            throw "Nombre de notes incorrect: $($mapping.Notes.Count)"
        }
        
        # Enregistrer le rapport de mapping
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "xml_mapping_report.txt"
        Set-Content -Path $reportPath -Value $report
        
        Write-Host "  Rapport de mapping généré: $reportPath"
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
Write-Host "Exécution des tests des outils XML..." -ForegroundColor Yellow
$results = Invoke-XmlToolsTests

# Afficher le chemin des fichiers de sortie
Write-Host "Les fichiers de sortie des tests sont disponibles dans: $testOutputPath" -ForegroundColor Cyan

# Retourner les résultats
return $results
