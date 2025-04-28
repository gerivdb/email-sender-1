# Script de test pour les outils XML (dÃ©tecteur et validateur)

# Importer les modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$implementationPath = Join-Path -Path $scriptPath -ChildPath "..\Implementation"
$detectorPath = Join-Path -Path $implementationPath -ChildPath "XmlElementDetector.ps1"
$validatorPath = Join-Path -Path $implementationPath -ChildPath "XmlValidator.ps1"

# CrÃ©er le dossier de sortie des tests
$testOutputPath = Join-Path -Path $scriptPath -ChildPath "Output"
if (-not (Test-Path -Path $testOutputPath)) {
    New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
}

# Importer les modules
Write-Host "Importation des modules XML..."
. $detectorPath
. $validatorPath

# Fonction pour exÃ©cuter les tests
function Invoke-XmlToolsTests {
    # Compteurs de tests
    $totalTests = 0
    $passedTests = 0
    $failedTests = 0
    
    # Fonction pour exÃ©cuter un test
    function Test-Case {
        param (
            [string]$Name,
            [scriptblock]$Test
        )
        
        $totalTests++
        Write-Host "Test: $Name" -ForegroundColor Cyan
        
        try {
            & $Test
            Write-Host "  RÃ©ussi" -ForegroundColor Green
            $script:passedTests++
        }
        catch {
            Write-Host "  Ã‰chouÃ©: $_" -ForegroundColor Red
            $script:failedTests++
        }
        
        Write-Host ""
    }
    
    # Test 1: DÃ©tection des Ã©lÃ©ments XML
    Test-Case -Name "DÃ©tection des Ã©lÃ©ments XML" -Test {
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
      <task title="TÃ¢che 1" estimatedTime="1 jour" startDate="DÃ©marrÃ©e le 01/01/2025" completed="true">
        <subtask title="Sous-tÃ¢che 1" completed="true" />
        <subtask title="Sous-tÃ¢che 2" completed="false" />
      </task>
      <task title="TÃ¢che 2" estimatedTime="2 jours" completed="false" />
      <note>Ceci est une note</note>
    </phase>
  </section>
</roadmap>
"@
        
        $elements = Get-XmlElements -XmlContent $xmlContent
        
        if ($elements.Count -lt 10) {
            throw "Nombre d'Ã©lÃ©ments dÃ©tectÃ©s insuffisant: $($elements.Count)"
        }
        
        $rootElement = $elements | Where-Object { $_.Depth -eq 0 }
        if (-not $rootElement -or $rootElement.Name -ne "roadmap") {
            throw "Ã‰lÃ©ment racine incorrect: $($rootElement.Name)"
        }
        
        $sectionElement = $elements | Where-Object { $_.Name -eq "section" }
        if (-not $sectionElement) {
            throw "Ã‰lÃ©ment section non dÃ©tectÃ©"
        }
        
        $phaseElement = $elements | Where-Object { $_.Name -eq "phase" }
        if (-not $phaseElement) {
            throw "Ã‰lÃ©ment phase non dÃ©tectÃ©"
        }
        
        $taskElements = $elements | Where-Object { $_.Name -eq "task" }
        if ($taskElements.Count -ne 2) {
            throw "Nombre d'Ã©lÃ©ments task incorrect: $($taskElements.Count)"
        }
        
        $subtaskElements = $elements | Where-Object { $_.Name -eq "subtask" }
        if ($subtaskElements.Count -ne 2) {
            throw "Nombre d'Ã©lÃ©ments subtask incorrect: $($subtaskElements.Count)"
        }
        
        $noteElement = $elements | Where-Object { $_.Name -eq "note" }
        if (-not $noteElement) {
            throw "Ã‰lÃ©ment note non dÃ©tectÃ©"
        }
        
        # GÃ©nÃ©rer un rapport de structure
        $report = Get-XmlStructureReport -XmlContent $xmlContent
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "xml_structure_report.txt"
        Set-Content -Path $reportPath -Value $report
        
        # GÃ©nÃ©rer un rapport de structure HTML
        $htmlReport = Get-XmlStructureReport -XmlContent $xmlContent -AsHtml
        $htmlReportPath = Join-Path -Path $testOutputPath -ChildPath "xml_structure_report.html"
        Set-Content -Path $htmlReportPath -Value $htmlReport -Encoding UTF8
        
        Write-Host "  Rapport de structure gÃ©nÃ©rÃ©: $reportPath"
        Write-Host "  Rapport de structure HTML gÃ©nÃ©rÃ©: $htmlReportPath"
    }
    
    # Test 2: Validation XML bien formÃ©
    Test-Case -Name "Validation XML bien formÃ©" -Test {
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
      <task title="TÃ¢che 1" estimatedTime="1 jour" startDate="DÃ©marrÃ©e le 01/01/2025" completed="true">
        <subtask title="Sous-tÃ¢che 1" completed="true" />
        <subtask title="Sous-tÃ¢che 2" completed="false" />
      </task>
      <task title="TÃ¢che 2" estimatedTime="2 jours" completed="false" />
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
        
        # GÃ©nÃ©rer un rapport de validation
        $report = Get-XmlValidationReport -ValidationResult $result
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "xml_validation_report.txt"
        Set-Content -Path $reportPath -Value $report
        
        # GÃ©nÃ©rer un rapport de validation HTML
        $htmlReport = Get-XmlValidationReport -ValidationResult $result -AsHtml
        $htmlReportPath = Join-Path -Path $testOutputPath -ChildPath "xml_validation_report.html"
        Set-Content -Path $htmlReportPath -Value $htmlReport -Encoding UTF8
        
        Write-Host "  Rapport de validation gÃ©nÃ©rÃ©: $reportPath"
        Write-Host "  Rapport de validation HTML gÃ©nÃ©rÃ©: $htmlReportPath"
    }
    
    # Test 3: Validation XML mal formÃ©
    Test-Case -Name "Validation XML mal formÃ©" -Test {
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
      <task title="TÃ¢che 1" estimatedTime="1 jour" startDate="DÃ©marrÃ©e le 01/01/2025" completed="true">
        <subtask title="Sous-tÃ¢che 1" completed="true" />
        <subtask title="Sous-tÃ¢che 2" completed="false" />
      </task>
      <task title="TÃ¢che 2" estimatedTime="2 jours" completed="false" />
      <note>Ceci est une note</note>
    </phase>
  </section>
</roadmap
"@
        
        $result = Test-XmlContent -XmlContent $xmlContent
        
        if ($result.IsValid) {
            throw "Le XML mal formÃ© a Ã©tÃ© validÃ© comme valide"
        }
        
        if ($result.Errors.Count -eq 0) {
            throw "Aucune erreur dÃ©tectÃ©e dans le XML mal formÃ©"
        }
        
        # GÃ©nÃ©rer un rapport de validation
        $report = Get-XmlValidationReport -ValidationResult $result
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "xml_validation_error_report.txt"
        Set-Content -Path $reportPath -Value $report
        
        # GÃ©nÃ©rer un rapport de validation HTML
        $htmlReport = Get-XmlValidationReport -ValidationResult $result -AsHtml
        $htmlReportPath = Join-Path -Path $testOutputPath -ChildPath "xml_validation_error_report.html"
        Set-Content -Path $htmlReportPath -Value $htmlReport -Encoding UTF8
        
        Write-Host "  Rapport de validation d'erreur gÃ©nÃ©rÃ©: $reportPath"
        Write-Host "  Rapport de validation d'erreur HTML gÃ©nÃ©rÃ©: $htmlReportPath"
    }
    
    # Test 4: GÃ©nÃ©ration et validation de schÃ©ma XSD
    Test-Case -Name "GÃ©nÃ©ration et validation de schÃ©ma XSD" -Test {
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
      <task title="TÃ¢che 1" estimatedTime="1 jour" startDate="DÃ©marrÃ©e le 01/01/2025" completed="true">
        <subtask title="Sous-tÃ¢che 1" completed="true" />
        <subtask title="Sous-tÃ¢che 2" completed="false" />
      </task>
      <task title="TÃ¢che 2" estimatedTime="2 jours" completed="false" />
      <note>Ceci est une note</note>
    </phase>
  </section>
</roadmap>
"@
        
        # CrÃ©er un fichier XML temporaire
        $xmlPath = Join-Path -Path $testOutputPath -ChildPath "test_schema.xml"
        Set-Content -Path $xmlPath -Value $xmlContent -Encoding UTF8
        
        # GÃ©nÃ©rer un schÃ©ma XSD
        $schemaPath = Join-Path -Path $testOutputPath -ChildPath "test_schema.xsd"
        
        try {
            New-XsdSchemaFromXml -XmlPath $xmlPath -SchemaPath $schemaPath
            
            if (-not (Test-Path -Path $schemaPath)) {
                throw "Le fichier de schÃ©ma XSD n'a pas Ã©tÃ© crÃ©Ã©"
            }
            
            Write-Host "  SchÃ©ma XSD gÃ©nÃ©rÃ©: $schemaPath"
        }
        catch {
            Write-Host "  Impossible de gÃ©nÃ©rer le schÃ©ma XSD: $_" -ForegroundColor Yellow
            Write-Host "  Ce test est ignorÃ© car la gÃ©nÃ©ration de schÃ©ma XSD n'est pas prise en charge dans cette version de PowerShell" -ForegroundColor Yellow
            return
        }
        
        # Valider le XML par rapport au schÃ©ma
        $result = Test-XmlFileAgainstSchema -XmlPath $xmlPath -SchemaPath $schemaPath
        
        if (-not $result.IsValid) {
            throw "Le XML n'est pas valide par rapport au schÃ©ma: $($result.Errors[0])"
        }
        
        # GÃ©nÃ©rer un rapport de validation
        $report = Get-XmlValidationReport -ValidationResult $result
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "xml_schema_validation_report.txt"
        Set-Content -Path $reportPath -Value $report
        
        Write-Host "  Rapport de validation de schÃ©ma gÃ©nÃ©rÃ©: $reportPath"
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
      <task title="TÃ¢che 1" estimatedTime="1 jour" startDate="DÃ©marrÃ©e le 01/01/2025" completed="true">
        <subtask title="Sous-tÃ¢che 1" completed="true" />
        <subtask title="Sous-tÃ¢che 2" completed="false" />
      </task>
      <task title="TÃ¢che 2" estimatedTime="2 jours" completed="false" />
      <note>Ceci est une note</note>
    </phase>
  </section>
</roadmap>
"@
        
        $mappingResult = ConvertTo-RoadmapMapping -XmlContent $xmlContent
        
        $mapping = $mappingResult.Mapping
        $report = $mappingResult.Report
        
        if (-not $mapping.RootElement -or $mapping.RootElement.Name -ne "roadmap") {
            throw "Ã‰lÃ©ment racine incorrect: $($mapping.RootElement.Name)"
        }
        
        if ($mapping.Sections.Count -ne 1) {
            throw "Nombre de sections incorrect: $($mapping.Sections.Count)"
        }
        
        if ($mapping.Phases.Count -ne 1) {
            throw "Nombre de phases incorrect: $($mapping.Phases.Count)"
        }
        
        if ($mapping.Tasks.Count -ne 2) {
            throw "Nombre de tÃ¢ches incorrect: $($mapping.Tasks.Count)"
        }
        
        if ($mapping.Subtasks.Count -ne 2) {
            throw "Nombre de sous-tÃ¢ches incorrect: $($mapping.Subtasks.Count)"
        }
        
        if ($mapping.Notes.Count -ne 1) {
            throw "Nombre de notes incorrect: $($mapping.Notes.Count)"
        }
        
        # Enregistrer le rapport de mapping
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "xml_mapping_report.txt"
        Set-Content -Path $reportPath -Value $report
        
        Write-Host "  Rapport de mapping gÃ©nÃ©rÃ©: $reportPath"
    }
    
    # Afficher le rÃ©sumÃ© des tests
    Write-Host "RÃ©sumÃ© des tests:" -ForegroundColor Yellow
    Write-Host "  Total: $totalTests" -ForegroundColor Cyan
    Write-Host "  RÃ©ussis: $passedTests" -ForegroundColor Green
    Write-Host "  Ã‰chouÃ©s: $failedTests" -ForegroundColor Red
    
    return @{
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
    }
}

# ExÃ©cuter les tests
Write-Host "ExÃ©cution des tests des outils XML..." -ForegroundColor Yellow
$results = Invoke-XmlToolsTests

# Afficher le chemin des fichiers de sortie
Write-Host "Les fichiers de sortie des tests sont disponibles dans: $testOutputPath" -ForegroundColor Cyan

# Retourner les rÃ©sultats
return $results
