#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour la fonction de dÃ©tection de format amÃ©liorÃ©e.

.DESCRIPTION
    Ce script contient des tests unitaires pour valider le bon fonctionnement
    de la fonction de dÃ©tection de format amÃ©liorÃ©e dÃ©veloppÃ©e dans le cadre de la
    section 2.1.2 de la roadmap.

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

# Importer le module Pester si disponible
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas disponible. Installation..."
    try {
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    }
    catch {
        Write-Error "Impossible d'installer le module Pester. Les tests ne peuvent pas Ãªtre exÃ©cutÃ©s."
        return
    }
}

# Chemin vers le script Ã  tester
$scriptPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\analysis\Improved-FormatDetection.ps1"

# Chemin vers le fichier de critÃ¨res de dÃ©tection
$criteriaPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\analysis\FormatDetectionCriteria.json"

# CrÃ©er le rÃ©pertoire de test si nÃ©cessaire
$testSamplesPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\format-detection\tests\format_samples"
if (-not (Test-Path -Path $testSamplesPath -PathType Container)) {
    New-Item -Path $testSamplesPath -ItemType Directory -Force | Out-Null
}

# Fonction pour crÃ©er des fichiers d'Ã©chantillon pour les tests
function New-FormatSampleFiles {
    param (
        [string]$TestDirectory
    )

    # Nettoyer le rÃ©pertoire de test
    Get-ChildItem -Path $TestDirectory -File | Remove-Item -Force

    # CrÃ©er un fichier XML
    $xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <element attribute="value">Text content</element>
    <element>
        <child>Child text</child>
    </element>
</root>
"@
    $xmlPath = Join-Path -Path $TestDirectory -ChildPath "sample.xml"
    Set-Content -Path $xmlPath -Value $xmlContent -Encoding UTF8

    # CrÃ©er un fichier JSON
    $jsonContent = @"
{
    "name": "John Doe",
    "age": 30,
    "address": {
        "street": "123 Main St",
        "city": "Anytown",
        "country": "USA"
    },
    "phoneNumbers": [
        "+1-555-123-4567",
        "+1-555-987-6543"
    ]
}
"@
    $jsonPath = Join-Path -Path $TestDirectory -ChildPath "sample.json"
    Set-Content -Path $jsonPath -Value $jsonContent -Encoding UTF8

    # CrÃ©er un fichier HTML
    $htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sample HTML</title>
    <style>
        body { font-family: Arial, sans-serif; }
    </style>
</head>
<body>
    <h1>Sample HTML Document</h1>
    <p>This is a paragraph.</p>
    <ul>
        <li>Item 1</li>
        <li>Item 2</li>
    </ul>
    <script>
        console.log("Hello, world!");
    </script>
</body>
</html>
"@
    $htmlPath = Join-Path -Path $TestDirectory -ChildPath "sample.html"
    Set-Content -Path $htmlPath -Value $htmlContent -Encoding UTF8

    # CrÃ©er un fichier CSS
    $cssContent = @"
/* Sample CSS file */
body {
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 20px;
    background-color: #f5f5f5;
}

h1 {
    color: #333;
    border-bottom: 1px solid #ccc;
    padding-bottom: 10px;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
    background-color: white;
    padding: 20px;
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
}
"@
    $cssPath = Join-Path -Path $TestDirectory -ChildPath "sample.css"
    Set-Content -Path $cssPath -Value $cssContent -Encoding UTF8

    # CrÃ©er un fichier JavaScript
    $jsContent = @"
// Sample JavaScript file
function greet(name) {
    return `Hello, ${name}!`;
}

class Person {
    constructor(name, age) {
        this.name = name;
        this.age = age;
    }

    sayHello() {
        console.log(greet(this.name));
    }
}

const person = new Person('John', 30);
person.sayHello();

// Event listener
document.addEventListener('DOMContentLoaded', () => {
    console.log('Document loaded');
});
"@
    $jsPath = Join-Path -Path $TestDirectory -ChildPath "sample.js"
    Set-Content -Path $jsPath -Value $jsContent -Encoding UTF8

    # CrÃ©er un fichier PowerShell
    $psContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Sample PowerShell script.
.DESCRIPTION
    This is a sample PowerShell script for testing format detection.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = `$true)]
    [string]`$InputPath,

    [Parameter()]
    [string]`$OutputPath = "output.txt"
)

function Invoke-File {
    param(
        [string]`$Path
    )

    if (-not (Test-Path -Path `$Path)) {
        Write-Error "File not found: `$Path"
        return `$false
    }

    try {
        `$content = Get-Content -Path `$Path -Raw
        return `$content
    }
    catch {
        Write-Error "Error processing file: `$_"
        return `$false
    }
}

# Main script
`$result = Invoke-File -Path `$InputPath
if (`$result -ne `$false) {
    Set-Content -Path `$OutputPath -Value `$result
    Write-Host "File processed successfully."
}
"@
    $psPath = Join-Path -Path $TestDirectory -ChildPath "sample.ps1"
    Set-Content -Path $psPath -Value $psContent -Encoding UTF8

    # CrÃ©er un fichier CSV
    $csvContent = @"
Name,Age,Email,Country
John Doe,30,john.doe@example.com,USA
Jane Smith,25,jane.smith@example.com,Canada
Bob Johnson,45,bob.johnson@example.com,UK
Alice Brown,35,alice.brown@example.com,Australia
"@
    $csvPath = Join-Path -Path $TestDirectory -ChildPath "sample.csv"
    Set-Content -Path $csvPath -Value $csvContent -Encoding UTF8

    # CrÃ©er un fichier INI
    $iniContent = @"
; Sample INI file
[General]
ApplicationName=Sample Application
Version=1.0.0
Language=en-US

[User]
Name=John Doe
Email=john.doe@example.com
Role=Administrator

[Settings]
Theme=Dark
AutoSave=true
Interval=30
"@
    $iniPath = Join-Path -Path $TestDirectory -ChildPath "sample.ini"
    Set-Content -Path $iniPath -Value $iniContent -Encoding UTF8

    # CrÃ©er un fichier YAML
    $yamlContent = @"
# Sample YAML file
version: '3'
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    environment:
      - NGINX_HOST=example.com
      - NGINX_PORT=80

  database:
    image: mysql:5.7
    volumes:
      - db_data:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=secret
      - MYSQL_DATABASE=myapp
      - MYSQL_USER=user
      - MYSQL_PASSWORD=password

volumes:
  db_data:
"@
    $yamlPath = Join-Path -Path $TestDirectory -ChildPath "sample.yaml"
    Set-Content -Path $yamlPath -Value $yamlContent -Encoding UTF8

    # CrÃ©er un fichier binaire (simulÃ©)
    $binaryPath = Join-Path -Path $TestDirectory -ChildPath "sample.bin"
    $binaryData = [byte[]]::new(256)
    for ($i = 0; $i -lt 256; $i++) {
        $binaryData[$i] = $i
    }
    [System.IO.File]::WriteAllBytes($binaryPath, $binaryData)

    # Retourner un dictionnaire des fichiers crÃ©Ã©s avec leurs formats attendus
    return @{
        $xmlPath = "XML"
        $jsonPath = "JSON"
        $htmlPath = "HTML"
        $cssPath = "CSS"
        $jsPath = "JAVASCRIPT"
        $psPath = "POWERSHELL"
        $csvPath = "CSV"
        $iniPath = "INI"
        $yamlPath = "YAML"
        $binaryPath = "BINARY"
    }
}

# CrÃ©er les fichiers d'Ã©chantillon
$expectedFormats = New-FormatSampleFiles -TestDirectory $testSamplesPath

# DÃ©marrer les tests Pester
Describe "Tests de dÃ©tection de format amÃ©liorÃ©e" {
    BeforeAll {
        # VÃ©rifier si le fichier de critÃ¨res existe
        if (-not (Test-Path -Path $criteriaPath -PathType Leaf)) {
            Write-Warning "Le fichier de critÃ¨res n'existe pas. ExÃ©cution du script de dÃ©finition des critÃ¨res..."
            $defineCriteriaPath = Join-Path -Path $PSScriptRoot -ChildPath "..\analysis\Define-FormatDetectionCriteria.ps1"
            if (Test-Path -Path $defineCriteriaPath -PathType Leaf) {
                & $defineCriteriaPath
            }
            else {
                Write-Error "Le script de dÃ©finition des critÃ¨res n'existe pas. Les tests ne peuvent pas Ãªtre exÃ©cutÃ©s."
                return
            }
        }

        # Charger le script Ã  tester
        . $scriptPath
    }

    Context "DÃ©tection par extension" {
        It "DÃ©tecte correctement le format XML" {
            $xmlPath = Join-Path -Path $testSamplesPath -ChildPath "sample.xml"
            $result = Detect-ImprovedFormat -FilePath $xmlPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "XML"
        }

        It "DÃ©tecte correctement le format JSON" {
            $jsonPath = Join-Path -Path $testSamplesPath -ChildPath "sample.json"
            $result = Detect-ImprovedFormat -FilePath $jsonPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "JSON"
        }

        It "DÃ©tecte correctement le format HTML" {
            $htmlPath = Join-Path -Path $testSamplesPath -ChildPath "sample.html"
            $result = Detect-ImprovedFormat -FilePath $htmlPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "HTML"
        }

        It "DÃ©tecte correctement le format CSS" {
            $cssPath = Join-Path -Path $testSamplesPath -ChildPath "sample.css"
            $result = Detect-ImprovedFormat -FilePath $cssPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "CSS"
        }

        It "DÃ©tecte correctement le format JavaScript" {
            $jsPath = Join-Path -Path $testSamplesPath -ChildPath "sample.js"
            $result = Detect-ImprovedFormat -FilePath $jsPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "JAVASCRIPT"
        }

        It "DÃ©tecte correctement le format PowerShell" {
            $psPath = Join-Path -Path $testSamplesPath -ChildPath "sample.ps1"
            $result = Detect-ImprovedFormat -FilePath $psPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "POWERSHELL"
        }

        It "DÃ©tecte correctement le format CSV" {
            $csvPath = Join-Path -Path $testSamplesPath -ChildPath "sample.csv"
            $result = Detect-ImprovedFormat -FilePath $csvPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "CSV"
        }

        It "DÃ©tecte correctement le format INI" {
            $iniPath = Join-Path -Path $testSamplesPath -ChildPath "sample.ini"
            $result = Detect-ImprovedFormat -FilePath $iniPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "INI"
        }

        It "DÃ©tecte correctement le format YAML" {
            $yamlPath = Join-Path -Path $testSamplesPath -ChildPath "sample.yaml"
            $result = Detect-ImprovedFormat -FilePath $yamlPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "YAML"
        }

        It "DÃ©tecte correctement le format binaire" {
            $binaryPath = Join-Path -Path $testSamplesPath -ChildPath "sample.bin"
            $result = Detect-ImprovedFormat -FilePath $binaryPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "BINARY"
        }
    }

    Context "DÃ©tection par contenu" {
        It "DÃ©tecte correctement le format XML mÃªme avec une extension incorrecte" {
            $xmlPath = Join-Path -Path $testSamplesPath -ChildPath "sample.xml"
            $xmlWrongExtPath = Join-Path -Path $testSamplesPath -ChildPath "xml_with_wrong_ext.txt"
            Copy-Item -Path $xmlPath -Destination $xmlWrongExtPath
            $result = Detect-ImprovedFormat -FilePath $xmlWrongExtPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "XML"
            Remove-Item -Path $xmlWrongExtPath -Force
        }

        It "DÃ©tecte correctement le format JSON mÃªme avec une extension incorrecte" {
            $jsonPath = Join-Path -Path $testSamplesPath -ChildPath "sample.json"
            $jsonWrongExtPath = Join-Path -Path $testSamplesPath -ChildPath "json_with_wrong_ext.txt"
            Copy-Item -Path $jsonPath -Destination $jsonWrongExtPath
            $result = Detect-ImprovedFormat -FilePath $jsonWrongExtPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "JSON"
            Remove-Item -Path $jsonWrongExtPath -Force
        }

        It "DÃ©tecte correctement le format HTML mÃªme avec une extension incorrecte" {
            $htmlPath = Join-Path -Path $testSamplesPath -ChildPath "sample.html"
            $htmlWrongExtPath = Join-Path -Path $testSamplesPath -ChildPath "html_with_wrong_ext.txt"
            Copy-Item -Path $htmlPath -Destination $htmlWrongExtPath
            $result = Detect-ImprovedFormat -FilePath $htmlWrongExtPath -DetectEncoding -DetailedOutput
            $result.DetectedFormat | Should -Be "HTML"
            Remove-Item -Path $htmlWrongExtPath -Force
        }
    }

    Context "DÃ©tection avec encodage" {
        It "DÃ©tecte correctement l'encodage UTF-8" {
            $xmlPath = Join-Path -Path $testSamplesPath -ChildPath "sample.xml"
            $result = Detect-ImprovedFormat -FilePath $xmlPath -DetectEncoding -DetailedOutput
            $result.Encoding | Should -Be "UTF-8"
        }
    }

    Context "Gestion des erreurs" {
        It "GÃ¨re correctement un fichier inexistant" {
            $nonExistentPath = Join-Path -Path $testSamplesPath -ChildPath "non_existent.txt"
            { Detect-ImprovedFormat -FilePath $nonExistentPath -DetectEncoding -DetailedOutput } | Should -Throw
        }
    }

    AfterAll {
        # Nettoyer les fichiers d'Ã©chantillon
        Get-ChildItem -Path $testSamplesPath -File | Remove-Item -Force
    }
}

