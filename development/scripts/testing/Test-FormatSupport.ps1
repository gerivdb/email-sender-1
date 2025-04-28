# Script de test pour le support des formats XML et HTML

# Importer les modules
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$implementationPath = Join-Path -Path $scriptPath -ChildPath "..\Implementation"
$xmlHandlerPath = Join-Path -Path $implementationPath -ChildPath "XMLFormatHandler.ps1"
$htmlHandlerPath = Join-Path -Path $implementationPath -ChildPath "HTMLFormatHandler.ps1"
$formatConverterPath = Join-Path -Path $implementationPath -ChildPath "FormatConverter.ps1"

# CrÃ©er le dossier de sortie des tests
$testOutputPath = Join-Path -Path $scriptPath -ChildPath "Output"
if (-not (Test-Path -Path $testOutputPath)) {
    New-Item -Path $testOutputPath -ItemType Directory -Force | Out-Null
}

# Importer les modules
Write-Host "Importation des modules..."
. $xmlHandlerPath
. $htmlHandlerPath
. $formatConverterPath

# Fonction pour exÃ©cuter les tests
function Invoke-FormatSupportTests {
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
    
    # Test 1: Parsing XML
    Test-Case -Name "Parsing XML" -Test {
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
        
        if (-not ($xmlDoc -is [System.Xml.XmlDocument])) {
            throw "Le rÃ©sultat n'est pas un XmlDocument"
        }
        
        $persons = $xmlDoc.SelectNodes("//person")
        if ($persons.Count -ne 2) {
            throw "Le nombre de personnes est incorrect: $($persons.Count)"
        }
        
        $firstPerson = $persons[0]
        if ($firstPerson.GetAttribute("id") -ne "1" -or $firstPerson.SelectSingleNode("name").InnerText -ne "John Doe") {
            throw "Les donnÃ©es de la premiÃ¨re personne sont incorrectes"
        }
    }
    
    # Test 2: GÃ©nÃ©ration XML
    Test-Case -Name "GÃ©nÃ©ration XML" -Test {
        $data = @{
            person = @(
                @{
                    id = 1
                    name = "John Doe"
                    age = 30
                    email = "john.doe@example.com"
                },
                @{
                    id = 2
                    name = "Jane Smith"
                    age = 25
                    email = "jane.smith@example.com"
                }
            )
        }
        
        $xmlString = ConvertTo-Xml -InputObject $data
        $outputPath = Join-Path -Path $testOutputPath -ChildPath "test_generation.xml"
        $xmlString | Out-File -FilePath $outputPath -Encoding UTF8
        
        if (-not (Test-Path -Path $outputPath)) {
            throw "Le fichier XML n'a pas Ã©tÃ© crÃ©Ã©"
        }
        
        $content = Get-Content -Path $outputPath -Raw
        if (-not $content.Contains("<person>") -or -not $content.Contains("<name>John Doe</name>")) {
            throw "Le contenu XML gÃ©nÃ©rÃ© est incorrect"
        }
    }
    
    # Test 3: Parsing HTML
    Test-Case -Name "Parsing HTML" -Test {
        $htmlString = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test Page</title>
</head>
<body>
    <h1>Hello World</h1>
    <p>This is a <strong>test</strong> page.</p>
    <ul>
        <li>Item 1</li>
        <li>Item 2</li>
        <li>Item 3</li>
    </ul>
</body>
</html>
"@
        
        # VÃ©rifier si HtmlAgilityPack est disponible
        if (-not (Test-HtmlAgilityPackAvailable)) {
            Write-Host "  Installation de HtmlAgilityPack..." -ForegroundColor Yellow
            Install-HtmlAgilityPack
        }
        
        $htmlDoc = ConvertFrom-Html -HtmlString $htmlString
        
        if (-not ($htmlDoc -is [HtmlAgilityPack.HtmlDocument])) {
            throw "Le rÃ©sultat n'est pas un HtmlDocument"
        }
        
        $h1 = $htmlDoc.DocumentNode.SelectSingleNode("//h1")
        if ($h1.InnerText -ne "Hello World") {
            throw "Le contenu H1 est incorrect: $($h1.InnerText)"
        }
        
        $listItems = $htmlDoc.DocumentNode.SelectNodes("//li")
        if ($listItems.Count -ne 3) {
            throw "Le nombre d'Ã©lÃ©ments de liste est incorrect: $($listItems.Count)"
        }
    }
    
    # Test 4: Sanitisation HTML
    Test-Case -Name "Sanitisation HTML" -Test {
        $htmlString = @"
<!DOCTYPE html>
<html>
<body>
    <h1>Test Sanitization</h1>
    <p>This is a <strong>test</strong> page.</p>
    <script>alert('XSS Attack');</script>
    <a href="javascript:alert('XSS')">Malicious Link</a>
    <a href="https://example.com">Safe Link</a>
    <iframe src="https://malicious.com"></iframe>
</body>
</html>
"@
        
        $htmlDoc = ConvertFrom-Html -HtmlString $htmlString -Sanitize
        
        # VÃ©rifier que les Ã©lÃ©ments dangereux ont Ã©tÃ© supprimÃ©s
        $script = $htmlDoc.DocumentNode.SelectSingleNode("//script")
        if ($script -ne $null) {
            throw "L'Ã©lÃ©ment script n'a pas Ã©tÃ© supprimÃ©"
        }
        
        $iframe = $htmlDoc.DocumentNode.SelectSingleNode("//iframe")
        if ($iframe -ne $null) {
            throw "L'Ã©lÃ©ment iframe n'a pas Ã©tÃ© supprimÃ©"
        }
        
        # VÃ©rifier que les liens malveillants ont Ã©tÃ© nettoyÃ©s
        $maliciousLink = $htmlDoc.DocumentNode.SelectSingleNode("//a[@href='javascript:alert(\'XSS\')']")
        if ($maliciousLink -ne $null) {
            throw "Le lien malveillant n'a pas Ã©tÃ© nettoyÃ©"
        }
        
        # VÃ©rifier que les liens sÃ»rs sont conservÃ©s
        $safeLink = $htmlDoc.DocumentNode.SelectSingleNode("//a[@href='https://example.com']")
        if ($safeLink -eq $null) {
            throw "Le lien sÃ»r a Ã©tÃ© supprimÃ©"
        }
    }
    
    # Test 5: Conversion XML vers HTML
    Test-Case -Name "Conversion XML vers HTML" -Test {
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
            throw "Le rÃ©sultat n'est pas un HtmlDocument"
        }
        
        $outputPath = Join-Path -Path $testOutputPath -ChildPath "xml_to_html.html"
        Export-HtmlFile -HtmlDocument $htmlDoc -FilePath $outputPath
        
        if (-not (Test-Path -Path $outputPath)) {
            throw "Le fichier HTML n'a pas Ã©tÃ© crÃ©Ã©"
        }
        
        $content = Get-Content -Path $outputPath -Raw
        if (-not $content.Contains("John Doe") -or -not $content.Contains("Jane Smith")) {
            throw "Le contenu HTML gÃ©nÃ©rÃ© est incorrect"
        }
    }
    
    # Test 6: Conversion HTML vers XML
    Test-Case -Name "Conversion HTML vers XML" -Test {
        $htmlString = @"
<!DOCTYPE html>
<html>
<head>
    <title>Test Page</title>
</head>
<body>
    <h1>Hello World</h1>
    <p>This is a <strong>test</strong> page.</p>
    <ul>
        <li>Item 1</li>
        <li>Item 2</li>
        <li>Item 3</li>
    </ul>
</body>
</html>
"@
        
        $htmlDoc = ConvertFrom-Html -HtmlString $htmlString
        $xmlDoc = ConvertFrom-HtmlToXml -HtmlDocument $htmlDoc
        
        if (-not ($xmlDoc -is [System.Xml.XmlDocument])) {
            throw "Le rÃ©sultat n'est pas un XmlDocument"
        }
        
        $outputPath = Join-Path -Path $testOutputPath -ChildPath "html_to_xml.xml"
        $xmlDoc.Save($outputPath)
        
        if (-not (Test-Path -Path $outputPath)) {
            throw "Le fichier XML n'a pas Ã©tÃ© crÃ©Ã©"
        }
        
        $content = Get-Content -Path $outputPath -Raw
        if (-not $content.Contains("<h1>Hello World</h1>") -or -not $content.Contains("<li>Item 1</li>")) {
            throw "Le contenu XML gÃ©nÃ©rÃ© est incorrect"
        }
    }
    
    # Test 7: Conversion XML vers JSON
    Test-Case -Name "Conversion XML vers JSON" -Test {
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
        $json = ConvertFrom-XmlToJson -XmlDocument $xmlDoc
        
        if (-not ($json -is [string])) {
            throw "Le rÃ©sultat n'est pas une chaÃ®ne JSON"
        }
        
        $outputPath = Join-Path -Path $testOutputPath -ChildPath "xml_to_json.json"
        $json | Out-File -FilePath $outputPath -Encoding UTF8
        
        if (-not (Test-Path -Path $outputPath)) {
            throw "Le fichier JSON n'a pas Ã©tÃ© crÃ©Ã©"
        }
        
        $content = Get-Content -Path $outputPath -Raw
        if (-not $content.Contains('"name": "John Doe"') -or -not $content.Contains('"age": "30"')) {
            throw "Le contenu JSON gÃ©nÃ©rÃ© est incorrect"
        }
    }
    
    # Test 8: Conversion JSON vers XML
    Test-Case -Name "Conversion JSON vers XML" -Test {
        $jsonString = @"
{
  "root": {
    "person": [
      {
        "@id": "1",
        "name": "John Doe",
        "age": 30,
        "email": "john.doe@example.com"
      },
      {
        "@id": "2",
        "name": "Jane Smith",
        "age": 25,
        "email": "jane.smith@example.com"
      }
    ]
  }
}
"@
        
        $xmlDoc = ConvertFrom-JsonToXml -JsonString $jsonString
        
        if (-not ($xmlDoc -is [System.Xml.XmlDocument])) {
            throw "Le rÃ©sultat n'est pas un XmlDocument"
        }
        
        $outputPath = Join-Path -Path $testOutputPath -ChildPath "json_to_xml.xml"
        $xmlDoc.Save($outputPath)
        
        if (-not (Test-Path -Path $outputPath)) {
            throw "Le fichier XML n'a pas Ã©tÃ© crÃ©Ã©"
        }
        
        $content = Get-Content -Path $outputPath -Raw
        if (-not $content.Contains("<name>John Doe</name>") -or -not $content.Contains("<age>30</age>")) {
            throw "Le contenu XML gÃ©nÃ©rÃ© est incorrect"
        }
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
Write-Host "ExÃ©cution des tests de support des formats XML et HTML..." -ForegroundColor Yellow
$results = Invoke-FormatSupportTests

# Afficher le chemin des fichiers de sortie
Write-Host "Les fichiers de sortie des tests sont disponibles dans: $testOutputPath" -ForegroundColor Cyan

# Retourner les rÃ©sultats
return $results
