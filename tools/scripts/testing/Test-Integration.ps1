# Script de test d'intÃ©gration
# Ce script teste l'intÃ©gration des convertisseurs XML et HTML

# Chemins des modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$examplesPath = Join-Path -Path $parentPath -ChildPath "Examples"
$formatConvertersPath = Join-Path -Path (Split-Path -Parent $parentPath) -ChildPath "Format-Converters"
$xmlSupportPath = Join-Path -Path $parentPath -ChildPath "XmlSupport.ps1"

# CrÃ©er le dossier de sortie des tests
$testOutputPath = Join-Path -Path $scriptPath -ChildPath "TestOutput"
if (-not (Test-Path -Path $testOutputPath)) {
    New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
}

# Importer le module XmlSupport
. $xmlSupportPath

# Fonction pour exÃ©cuter les tests d'intÃ©gration
function Invoke-IntegrationTests {
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
    
    # Test 1: Conversion XML vers Roadmap
    Test-Case -Name "Conversion XML vers Roadmap" -Test {
        $xmlPath = Join-Path -Path $examplesPath -ChildPath "example-roadmap.xml"
        $roadmapPath = Join-Path -Path $testOutputPath -ChildPath "example-roadmap.md"
        
        ConvertFrom-XmlFileToRoadmapFile -XmlPath $xmlPath -RoadmapPath $roadmapPath
        
        if (-not (Test-Path -Path $roadmapPath)) {
            throw "Le fichier Roadmap n'a pas Ã©tÃ© crÃ©Ã©"
        }
        
        $roadmapContent = Get-Content -Path $roadmapPath -Raw
        
        if (-not $roadmapContent.Contains("# Exemple de Roadmap")) {
            throw "Le titre est incorrect"
        }
        
        if (-not $roadmapContent.Contains("## 1. Section d'exemple")) {
            throw "La section est incorrecte"
        }
        
        Write-Host "  Fichier Roadmap gÃ©nÃ©rÃ©: $roadmapPath"
    }
    
    # Test 2: Conversion Roadmap vers XML
    Test-Case -Name "Conversion Roadmap vers XML" -Test {
        $roadmapPath = Join-Path -Path $testOutputPath -ChildPath "example-roadmap.md"
        $xmlPath = Join-Path -Path $testOutputPath -ChildPath "example-roadmap-from-md.xml"
        
        ConvertFrom-RoadmapFileToXmlFile -RoadmapPath $roadmapPath -XmlPath $xmlPath
        
        if (-not (Test-Path -Path $xmlPath)) {
            throw "Le fichier XML n'a pas Ã©tÃ© crÃ©Ã©"
        }
        
        $xmlContent = Get-Content -Path $xmlPath -Raw
        
        if (-not $xmlContent.Contains("<roadmap")) {
            throw "L'Ã©lÃ©ment racine est incorrect"
        }
        
        if (-not $xmlContent.Contains("<section id=")) {
            throw "La section est incorrecte"
        }
        
        Write-Host "  Fichier XML gÃ©nÃ©rÃ©: $xmlPath"
    }
    
    # Test 3: Validation XML
    Test-Case -Name "Validation XML" -Test {
        $xmlPath = Join-Path -Path $examplesPath -ChildPath "example-roadmap.xml"
        
        $result = Test-XmlFile -XmlPath $xmlPath
        
        if (-not $result.IsValid) {
            throw "Le fichier XML n'est pas valide"
        }
        
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "validation-report.html"
        $report = Get-XmlValidationReport -ValidationResult $result -AsHtml
        $report | Out-File -FilePath $reportPath -Encoding UTF8
        
        Write-Host "  Rapport de validation gÃ©nÃ©rÃ©: $reportPath"
    }
    
    # Test 4: Analyse de structure XML
    Test-Case -Name "Analyse de structure XML" -Test {
        $xmlPath = Join-Path -Path $examplesPath -ChildPath "example-roadmap.xml"
        
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "structure-report.html"
        Get-XmlStructureReportFromFile -XmlPath $xmlPath -OutputPath $reportPath -AsHtml
        
        if (-not (Test-Path -Path $reportPath)) {
            throw "Le rapport de structure n'a pas Ã©tÃ© crÃ©Ã©"
        }
        
        Write-Host "  Rapport de structure gÃ©nÃ©rÃ©: $reportPath"
    }
    
    # Test 5: Conversion XML vers HTML
    Test-Case -Name "Conversion XML vers HTML" -Test {
        $xmlPath = Join-Path -Path $examplesPath -ChildPath "example-roadmap.xml"
        $htmlPath = Join-Path -Path $testOutputPath -ChildPath "example-roadmap-from-xml.html"
        
        $xmlDoc = Import-XmlFile -FilePath $xmlPath
        $htmlDoc = ConvertFrom-XmlToHtml -XmlDocument $xmlDoc
        Export-HtmlFile -HtmlDocument $htmlDoc -FilePath $htmlPath
        
        if (-not (Test-Path -Path $htmlPath)) {
            throw "Le fichier HTML n'a pas Ã©tÃ© crÃ©Ã©"
        }
        
        $htmlContent = Get-Content -Path $htmlPath -Raw
        
        if (-not $htmlContent.Contains("<html")) {
            throw "L'Ã©lÃ©ment racine est incorrect"
        }
        
        Write-Host "  Fichier HTML gÃ©nÃ©rÃ©: $htmlPath"
    }
    
    # Test 6: Conversion HTML vers XML
    Test-Case -Name "Conversion HTML vers XML" -Test {
        $htmlPath = Join-Path -Path $examplesPath -ChildPath "example-roadmap.html"
        $xmlPath = Join-Path -Path $testOutputPath -ChildPath "example-roadmap-from-html.xml"
        
        $htmlDoc = Import-HtmlFile -FilePath $htmlPath
        $xmlDoc = ConvertFrom-HtmlToXml -HtmlDocument $htmlDoc
        $xmlDoc.Save($xmlPath)
        
        if (-not (Test-Path -Path $xmlPath)) {
            throw "Le fichier XML n'a pas Ã©tÃ© crÃ©Ã©"
        }
        
        $xmlContent = Get-Content -Path $xmlPath -Raw
        
        if (-not $xmlContent.Contains("<html")) {
            throw "L'Ã©lÃ©ment racine est incorrect"
        }
        
        Write-Host "  Fichier XML gÃ©nÃ©rÃ©: $xmlPath"
    }
    
    # Test 7: Extraction de texte HTML
    Test-Case -Name "Extraction de texte HTML" -Test {
        $htmlPath = Join-Path -Path $examplesPath -ChildPath "example-roadmap.html"
        $textPath = Join-Path -Path $testOutputPath -ChildPath "example-roadmap-text.txt"
        
        $htmlDoc = Import-HtmlFile -FilePath $htmlPath
        $text = ConvertTo-PlainText -HtmlDocument $htmlDoc
        $text | Out-File -FilePath $textPath -Encoding UTF8
        
        if (-not (Test-Path -Path $textPath)) {
            throw "Le fichier texte n'a pas Ã©tÃ© crÃ©Ã©"
        }
        
        $textContent = Get-Content -Path $textPath -Raw
        
        if (-not $textContent.Contains("Exemple de Roadmap")) {
            throw "Le texte extrait est incorrect"
        }
        
        Write-Host "  Fichier texte gÃ©nÃ©rÃ©: $textPath"
    }
    
    # Test 8: IntÃ©gration avec Format-Converters
    Test-Case -Name "IntÃ©gration avec Format-Converters" -Test {
        $integrationPath = Join-Path -Path $formatConvertersPath -ChildPath "Integrations\XML_HTML"
        
        if (-not (Test-Path -Path $integrationPath)) {
            throw "Le dossier d'intÃ©gration n'existe pas"
        }
        
        $integrationFile = Join-Path -Path $integrationPath -ChildPath "XML_HTML_Integration.ps1"
        
        if (-not (Test-Path -Path $integrationFile)) {
            throw "Le fichier d'intÃ©gration n'existe pas"
        }
        
        # VÃ©rifier que le fichier d'intÃ©gration contient les fonctions nÃ©cessaires
        $integrationContent = Get-Content -Path $integrationFile -Raw
        
        if (-not $integrationContent.Contains("Register-XmlHtmlConverters")) {
            throw "La fonction Register-XmlHtmlConverters est manquante"
        }
        
        Write-Host "  IntÃ©gration avec Format-Converters vÃ©rifiÃ©e"
    }
    
    # Test 9: IntÃ©gration avec l'interface utilisateur
    Test-Case -Name "IntÃ©gration avec l'interface utilisateur" -Test {
        $uiPath = Join-Path -Path (Split-Path -Parent $parentPath) -ChildPath "UI\XML_HTML"
        
        if (-not (Test-Path -Path $uiPath)) {
            throw "Le dossier d'intÃ©gration UI n'existe pas"
        }
        
        $uiIntegrationFile = Join-Path -Path $uiPath -ChildPath "XML_HTML_UI_Integration.ps1"
        
        if (-not (Test-Path -Path $uiIntegrationFile)) {
            throw "Le fichier d'intÃ©gration UI n'existe pas"
        }
        
        # VÃ©rifier que le fichier d'intÃ©gration UI contient les fonctions nÃ©cessaires
        $uiIntegrationContent = Get-Content -Path $uiIntegrationFile -Raw
        
        if (-not $uiIntegrationContent.Contains("Register-XmlHtmlFormatsInUI")) {
            throw "La fonction Register-XmlHtmlFormatsInUI est manquante"
        }
        
        Write-Host "  IntÃ©gration avec l'interface utilisateur vÃ©rifiÃ©e"
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

# ExÃ©cuter les tests d'intÃ©gration
Write-Host "ExÃ©cution des tests d'intÃ©gration..." -ForegroundColor Yellow
$results = Invoke-IntegrationTests

# Afficher le chemin des fichiers de sortie
Write-Host "Les fichiers de sortie des tests sont disponibles dans: $testOutputPath" -ForegroundColor Cyan

# Retourner les rÃ©sultats
return $results
