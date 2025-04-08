# Script de test d'intégration
# Ce script teste l'intégration des convertisseurs XML et HTML

# Chemins des modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$examplesPath = Join-Path -Path $parentPath -ChildPath "Examples"
$formatConvertersPath = Join-Path -Path (Split-Path -Parent $parentPath) -ChildPath "Format-Converters"
$xmlSupportPath = Join-Path -Path $parentPath -ChildPath "XmlSupport.ps1"

# Créer le dossier de sortie des tests
$testOutputPath = Join-Path -Path $scriptPath -ChildPath "TestOutput"
if (-not (Test-Path -Path $testOutputPath)) {
    New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
}

# Importer le module XmlSupport
. $xmlSupportPath

# Fonction pour exécuter les tests d'intégration
function Invoke-IntegrationTests {
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
    
    # Test 1: Conversion XML vers Roadmap
    Test-Case -Name "Conversion XML vers Roadmap" -Test {
        $xmlPath = Join-Path -Path $examplesPath -ChildPath "example-roadmap.xml"
        $roadmapPath = Join-Path -Path $testOutputPath -ChildPath "example-roadmap.md"
        
        ConvertFrom-XmlFileToRoadmapFile -XmlPath $xmlPath -RoadmapPath $roadmapPath
        
        if (-not (Test-Path -Path $roadmapPath)) {
            throw "Le fichier Roadmap n'a pas été créé"
        }
        
        $roadmapContent = Get-Content -Path $roadmapPath -Raw
        
        if (-not $roadmapContent.Contains("# Exemple de Roadmap")) {
            throw "Le titre est incorrect"
        }
        
        if (-not $roadmapContent.Contains("## 1. Section d'exemple")) {
            throw "La section est incorrecte"
        }
        
        Write-Host "  Fichier Roadmap généré: $roadmapPath"
    }
    
    # Test 2: Conversion Roadmap vers XML
    Test-Case -Name "Conversion Roadmap vers XML" -Test {
        $roadmapPath = Join-Path -Path $testOutputPath -ChildPath "example-roadmap.md"
        $xmlPath = Join-Path -Path $testOutputPath -ChildPath "example-roadmap-from-md.xml"
        
        ConvertFrom-RoadmapFileToXmlFile -RoadmapPath $roadmapPath -XmlPath $xmlPath
        
        if (-not (Test-Path -Path $xmlPath)) {
            throw "Le fichier XML n'a pas été créé"
        }
        
        $xmlContent = Get-Content -Path $xmlPath -Raw
        
        if (-not $xmlContent.Contains("<roadmap")) {
            throw "L'élément racine est incorrect"
        }
        
        if (-not $xmlContent.Contains("<section id=")) {
            throw "La section est incorrecte"
        }
        
        Write-Host "  Fichier XML généré: $xmlPath"
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
        
        Write-Host "  Rapport de validation généré: $reportPath"
    }
    
    # Test 4: Analyse de structure XML
    Test-Case -Name "Analyse de structure XML" -Test {
        $xmlPath = Join-Path -Path $examplesPath -ChildPath "example-roadmap.xml"
        
        $reportPath = Join-Path -Path $testOutputPath -ChildPath "structure-report.html"
        Get-XmlStructureReportFromFile -XmlPath $xmlPath -OutputPath $reportPath -AsHtml
        
        if (-not (Test-Path -Path $reportPath)) {
            throw "Le rapport de structure n'a pas été créé"
        }
        
        Write-Host "  Rapport de structure généré: $reportPath"
    }
    
    # Test 5: Conversion XML vers HTML
    Test-Case -Name "Conversion XML vers HTML" -Test {
        $xmlPath = Join-Path -Path $examplesPath -ChildPath "example-roadmap.xml"
        $htmlPath = Join-Path -Path $testOutputPath -ChildPath "example-roadmap-from-xml.html"
        
        $xmlDoc = Import-XmlFile -FilePath $xmlPath
        $htmlDoc = ConvertFrom-XmlToHtml -XmlDocument $xmlDoc
        Export-HtmlFile -HtmlDocument $htmlDoc -FilePath $htmlPath
        
        if (-not (Test-Path -Path $htmlPath)) {
            throw "Le fichier HTML n'a pas été créé"
        }
        
        $htmlContent = Get-Content -Path $htmlPath -Raw
        
        if (-not $htmlContent.Contains("<html")) {
            throw "L'élément racine est incorrect"
        }
        
        Write-Host "  Fichier HTML généré: $htmlPath"
    }
    
    # Test 6: Conversion HTML vers XML
    Test-Case -Name "Conversion HTML vers XML" -Test {
        $htmlPath = Join-Path -Path $examplesPath -ChildPath "example-roadmap.html"
        $xmlPath = Join-Path -Path $testOutputPath -ChildPath "example-roadmap-from-html.xml"
        
        $htmlDoc = Import-HtmlFile -FilePath $htmlPath
        $xmlDoc = ConvertFrom-HtmlToXml -HtmlDocument $htmlDoc
        $xmlDoc.Save($xmlPath)
        
        if (-not (Test-Path -Path $xmlPath)) {
            throw "Le fichier XML n'a pas été créé"
        }
        
        $xmlContent = Get-Content -Path $xmlPath -Raw
        
        if (-not $xmlContent.Contains("<html")) {
            throw "L'élément racine est incorrect"
        }
        
        Write-Host "  Fichier XML généré: $xmlPath"
    }
    
    # Test 7: Extraction de texte HTML
    Test-Case -Name "Extraction de texte HTML" -Test {
        $htmlPath = Join-Path -Path $examplesPath -ChildPath "example-roadmap.html"
        $textPath = Join-Path -Path $testOutputPath -ChildPath "example-roadmap-text.txt"
        
        $htmlDoc = Import-HtmlFile -FilePath $htmlPath
        $text = ConvertTo-PlainText -HtmlDocument $htmlDoc
        $text | Out-File -FilePath $textPath -Encoding UTF8
        
        if (-not (Test-Path -Path $textPath)) {
            throw "Le fichier texte n'a pas été créé"
        }
        
        $textContent = Get-Content -Path $textPath -Raw
        
        if (-not $textContent.Contains("Exemple de Roadmap")) {
            throw "Le texte extrait est incorrect"
        }
        
        Write-Host "  Fichier texte généré: $textPath"
    }
    
    # Test 8: Intégration avec Format-Converters
    Test-Case -Name "Intégration avec Format-Converters" -Test {
        $integrationPath = Join-Path -Path $formatConvertersPath -ChildPath "Integrations\XML_HTML"
        
        if (-not (Test-Path -Path $integrationPath)) {
            throw "Le dossier d'intégration n'existe pas"
        }
        
        $integrationFile = Join-Path -Path $integrationPath -ChildPath "XML_HTML_Integration.ps1"
        
        if (-not (Test-Path -Path $integrationFile)) {
            throw "Le fichier d'intégration n'existe pas"
        }
        
        # Vérifier que le fichier d'intégration contient les fonctions nécessaires
        $integrationContent = Get-Content -Path $integrationFile -Raw
        
        if (-not $integrationContent.Contains("Register-XmlHtmlConverters")) {
            throw "La fonction Register-XmlHtmlConverters est manquante"
        }
        
        Write-Host "  Intégration avec Format-Converters vérifiée"
    }
    
    # Test 9: Intégration avec l'interface utilisateur
    Test-Case -Name "Intégration avec l'interface utilisateur" -Test {
        $uiPath = Join-Path -Path (Split-Path -Parent $parentPath) -ChildPath "UI\XML_HTML"
        
        if (-not (Test-Path -Path $uiPath)) {
            throw "Le dossier d'intégration UI n'existe pas"
        }
        
        $uiIntegrationFile = Join-Path -Path $uiPath -ChildPath "XML_HTML_UI_Integration.ps1"
        
        if (-not (Test-Path -Path $uiIntegrationFile)) {
            throw "Le fichier d'intégration UI n'existe pas"
        }
        
        # Vérifier que le fichier d'intégration UI contient les fonctions nécessaires
        $uiIntegrationContent = Get-Content -Path $uiIntegrationFile -Raw
        
        if (-not $uiIntegrationContent.Contains("Register-XmlHtmlFormatsInUI")) {
            throw "La fonction Register-XmlHtmlFormatsInUI est manquante"
        }
        
        Write-Host "  Intégration avec l'interface utilisateur vérifiée"
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

# Exécuter les tests d'intégration
Write-Host "Exécution des tests d'intégration..." -ForegroundColor Yellow
$results = Invoke-IntegrationTests

# Afficher le chemin des fichiers de sortie
Write-Host "Les fichiers de sortie des tests sont disponibles dans: $testOutputPath" -ForegroundColor Cyan

# Retourner les résultats
return $results
