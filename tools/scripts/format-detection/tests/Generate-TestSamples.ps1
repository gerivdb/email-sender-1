#Requires -Version 5.1
<#
.SYNOPSIS
    Génère des fichiers d'échantillon pour les tests de détection de format.

.DESCRIPTION
    Ce script génère des fichiers d'échantillon pour les tests de détection de format,
    y compris des fichiers de différents formats et encodages.

.PARAMETER OutputDirectory
    Le répertoire où les fichiers d'échantillon seront enregistrés.
    Par défaut, utilise le répertoire 'samples' dans le répertoire du script.

.PARAMETER Force
    Indique si les fichiers existants doivent être remplacés.

.EXAMPLE
    .\Generate-TestSamples.ps1 -OutputDirectory "D:\Samples" -Force

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-11
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputDirectory = (Join-Path -Path $PSScriptRoot -ChildPath "samples"),
    
    [Parameter()]
    [switch]$Force
)

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputDirectory -PathType Container)) {
    New-Item -Path $OutputDirectory -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire de sortie créé : $OutputDirectory" -ForegroundColor Green
}

# Créer les sous-répertoires pour les différents types d'échantillons
$formatSamplesDir = Join-Path -Path $OutputDirectory -ChildPath "formats"
$encodingSamplesDir = Join-Path -Path $OutputDirectory -ChildPath "encodings"

if (-not (Test-Path -Path $formatSamplesDir -PathType Container)) {
    New-Item -Path $formatSamplesDir -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $encodingSamplesDir -PathType Container)) {
    New-Item -Path $encodingSamplesDir -ItemType Directory -Force | Out-Null
}

# Fonction pour créer un fichier d'échantillon
function New-SampleFile {
    param(
        [string]$FilePath,
        [string]$Content,
        [System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8,
        [switch]$Force
    )
    
    if ((Test-Path -Path $FilePath) -and -not $Force) {
        Write-Verbose "Le fichier $FilePath existe déjà. Utilisez -Force pour le remplacer."
        return
    }
    
    try {
        [System.IO.File]::WriteAllText($FilePath, $Content, $Encoding)
        Write-Host "Fichier créé : $FilePath" -ForegroundColor Green
    }
    catch {
        Write-Error "Erreur lors de la création du fichier $FilePath : $_"
    }
}

# Fonction pour créer un fichier binaire d'échantillon
function New-BinarySampleFile {
    param(
        [string]$FilePath,
        [byte[]]$Content,
        [switch]$Force
    )
    
    if ((Test-Path -Path $FilePath) -and -not $Force) {
        Write-Verbose "Le fichier $FilePath existe déjà. Utilisez -Force pour le remplacer."
        return
    }
    
    try {
        [System.IO.File]::WriteAllBytes($FilePath, $Content)
        Write-Host "Fichier binaire créé : $FilePath" -ForegroundColor Green
    }
    catch {
        Write-Error "Erreur lors de la création du fichier binaire $FilePath : $_"
    }
}

# Générer des fichiers d'échantillon pour les tests de format

# 1. Fichier texte
$textContent = @"
Ceci est un fichier texte simple.
Il contient plusieurs lignes de texte.
Ce fichier est utilisé pour tester la détection de format.
"@
$textPath = Join-Path -Path $formatSamplesDir -ChildPath "sample.txt"
New-SampleFile -FilePath $textPath -Content $textContent -Force:$Force

# 2. Fichier XML
$xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<root>
    <element attribute="value">Text content</element>
    <element>
        <child>Child text</child>
    </element>
</root>
"@
$xmlPath = Join-Path -Path $formatSamplesDir -ChildPath "sample.xml"
New-SampleFile -FilePath $xmlPath -Content $xmlContent -Force:$Force

# 3. Fichier JSON
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
$jsonPath = Join-Path -Path $formatSamplesDir -ChildPath "sample.json"
New-SampleFile -FilePath $jsonPath -Content $jsonContent -Force:$Force

# 4. Fichier HTML
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
$htmlPath = Join-Path -Path $formatSamplesDir -ChildPath "sample.html"
New-SampleFile -FilePath $htmlPath -Content $htmlContent -Force:$Force

# 5. Fichier CSS
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
$cssPath = Join-Path -Path $formatSamplesDir -ChildPath "sample.css"
New-SampleFile -FilePath $cssPath -Content $cssContent -Force:$Force

# 6. Fichier JavaScript
$jsContent = @"
// Sample JavaScript file
function greet(name) {
    return `Hello, \${name}!`;
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
$jsPath = Join-Path -Path $formatSamplesDir -ChildPath "sample.js"
New-SampleFile -FilePath $jsPath -Content $jsContent -Force:$Force

# 7. Fichier PowerShell
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

function Process-File {
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
`$result = Process-File -Path `$InputPath
if (`$result -ne `$false) {
    Set-Content -Path `$OutputPath -Value `$result
    Write-Host "File processed successfully."
}
"@
$psPath = Join-Path -Path $formatSamplesDir -ChildPath "sample.ps1"
New-SampleFile -FilePath $psPath -Content $psContent -Force:$Force

# 8. Fichier CSV
$csvContent = @"
Name,Age,Email,Country
John Doe,30,john.doe@example.com,USA
Jane Smith,25,jane.smith@example.com,Canada
Bob Johnson,45,bob.johnson@example.com,UK
Alice Brown,35,alice.brown@example.com,Australia
"@
$csvPath = Join-Path -Path $formatSamplesDir -ChildPath "sample.csv"
New-SampleFile -FilePath $csvPath -Content $csvContent -Force:$Force

# 9. Fichier INI
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
$iniPath = Join-Path -Path $formatSamplesDir -ChildPath "sample.ini"
New-SampleFile -FilePath $iniPath -Content $iniContent -Force:$Force

# 10. Fichier YAML
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
$yamlPath = Join-Path -Path $formatSamplesDir -ChildPath "sample.yaml"
New-SampleFile -FilePath $yamlPath -Content $yamlContent -Force:$Force

# 11. Fichier binaire
$binaryData = [byte[]]::new(256)
for ($i = 0; $i -lt 256; $i++) {
    $binaryData[$i] = $i
}
$binaryPath = Join-Path -Path $formatSamplesDir -ChildPath "sample.bin"
New-BinarySampleFile -FilePath $binaryPath -Content $binaryData -Force:$Force

# Générer des fichiers d'échantillon pour les tests d'encodage

# Contenu multilingue pour les tests d'encodage
$multilingualContent = @"
=== Test de détection d'encodage ===

== Texte latin (ASCII) ==
The quick brown fox jumps over the lazy dog.
0123456789 !@#$%^&*()_+-=[]{}|;':",./<>?

== Texte français (Latin-1) ==
Voici un texte en français avec des accents : éèêëàâäôöùûüÿç
Les œufs et les bœufs sont dans le pré.

== Texte allemand (Latin-1) ==
Falsches Üben von Xylophonmusik quält jeden größeren Zwerg.
Die Königin und der König leben in einem Schloß.

== Texte grec (UTF-8) ==
Ξεσκεπάζω την ψυχοφθόρα βδελυγμία.
Καλημέρα, πώς είστε σήμερα;

== Texte russe (UTF-8) ==
Съешь же ещё этих мягких французских булок, да выпей чаю.
Широкая электрификация южных губерний даст мощный толчок подъёму сельского хозяйства.

== Texte japonais (UTF-8) ==
いろはにほへと ちりぬるを わかよたれそ つねならむ
私は日本語を勉強しています。

== Texte chinois (UTF-8) ==
我能吞下玻璃而不伤身体。
你好，世界！

== Texte arabe (UTF-8) ==
أنا قادر على أكل الزجاج و هذا لا يؤلمني.
مرحبا بالعالم!

== Texte hébreu (UTF-8) ==
אני יכול לאכול זכוכית וזה לא מזיק לי.
שלום עולם!

== Texte emoji (UTF-8) ==
😀 😃 😄 😁 😆 😅 😂 🤣 🥲 ☺️ 😊 😇 🙂 🙃 😉 😌 😍 🥰 😘 😗 😙 😚 😋 😛 😝 😜
🐶 🐱 🐭 🐹 🐰 🦊 🐻 🐼 🐻‍❄️ 🐨 🐯 🦁 🐮 🐷 🐽 🐸 🐵 🙈 🙉 🙊 🐒 🐔 🐧 🐦 🐤 🐣
"@

# 1. Fichier ASCII
$asciiContent = "This is a simple ASCII text file."
$asciiPath = Join-Path -Path $encodingSamplesDir -ChildPath "ascii.txt"
New-SampleFile -FilePath $asciiPath -Content $asciiContent -Encoding ([System.Text.ASCIIEncoding]::new()) -Force:$Force

# 2. Fichier UTF-8 sans BOM
$utf8Path = Join-Path -Path $encodingSamplesDir -ChildPath "utf8.txt"
New-SampleFile -FilePath $utf8Path -Content $multilingualContent -Encoding ([System.Text.UTF8Encoding]::new($false)) -Force:$Force

# 3. Fichier UTF-8 avec BOM
$utf8BomPath = Join-Path -Path $encodingSamplesDir -ChildPath "utf8-bom.txt"
New-SampleFile -FilePath $utf8BomPath -Content $multilingualContent -Encoding ([System.Text.UTF8Encoding]::new($true)) -Force:$Force

# 4. Fichier UTF-16LE sans BOM
$utf16LEPath = Join-Path -Path $encodingSamplesDir -ChildPath "utf16le.txt"
New-SampleFile -FilePath $utf16LEPath -Content $multilingualContent -Encoding ([System.Text.UnicodeEncoding]::new($false, $false)) -Force:$Force

# 5. Fichier UTF-16LE avec BOM
$utf16LEBomPath = Join-Path -Path $encodingSamplesDir -ChildPath "utf16le-bom.txt"
New-SampleFile -FilePath $utf16LEBomPath -Content $multilingualContent -Encoding ([System.Text.UnicodeEncoding]::new($false, $true)) -Force:$Force

# 6. Fichier UTF-16BE sans BOM
$utf16BEPath = Join-Path -Path $encodingSamplesDir -ChildPath "utf16be.txt"
New-SampleFile -FilePath $utf16BEPath -Content $multilingualContent -Encoding ([System.Text.UnicodeEncoding]::new($true, $false)) -Force:$Force

# 7. Fichier UTF-16BE avec BOM
$utf16BEBomPath = Join-Path -Path $encodingSamplesDir -ChildPath "utf16be-bom.txt"
New-SampleFile -FilePath $utf16BEBomPath -Content $multilingualContent -Encoding ([System.Text.UnicodeEncoding]::new($true, $true)) -Force:$Force

# 8. Fichier Windows-1252
$windows1252Path = Join-Path -Path $encodingSamplesDir -ChildPath "windows1252.txt"
New-SampleFile -FilePath $windows1252Path -Content $multilingualContent -Encoding ([System.Text.Encoding]::GetEncoding(1252)) -Force:$Force

# 9. Fichier avec des octets nuls (simulant UTF-16)
$nullBytesData = [byte[]]::new(256)
for ($i = 0; $i -lt 256; $i += 2) {
    $nullBytesData[$i] = 65 + ($i % 26)  # Lettres majuscules
    $nullBytesData[$i + 1] = 0  # Octets nuls
}
$nullBytesPath = Join-Path -Path $encodingSamplesDir -ChildPath "null_bytes.bin"
New-BinarySampleFile -FilePath $nullBytesPath -Content $nullBytesData -Force:$Force

# Créer un fichier JSON avec les formats attendus
$expectedFormats = @{}

# Formats pour les fichiers d'échantillon de format
$expectedFormats[$textPath] = "TEXT"
$expectedFormats[$xmlPath] = "XML"
$expectedFormats[$jsonPath] = "JSON"
$expectedFormats[$htmlPath] = "HTML"
$expectedFormats[$cssPath] = "CSS"
$expectedFormats[$jsPath] = "JAVASCRIPT"
$expectedFormats[$psPath] = "POWERSHELL"
$expectedFormats[$csvPath] = "CSV"
$expectedFormats[$iniPath] = "INI"
$expectedFormats[$yamlPath] = "YAML"
$expectedFormats[$binaryPath] = "BINARY"

# Encodages pour les fichiers d'échantillon d'encodage
$expectedEncodings = @{}
$expectedEncodings[$asciiPath] = "ASCII"
$expectedEncodings[$utf8Path] = "UTF-8"
$expectedEncodings[$utf8BomPath] = "UTF-8-BOM"
$expectedEncodings[$utf16LEPath] = "UTF-16LE"
$expectedEncodings[$utf16LEBomPath] = "UTF-16LE"
$expectedEncodings[$utf16BEPath] = "UTF-16BE"
$expectedEncodings[$utf16BEBomPath] = "UTF-16BE"
$expectedEncodings[$windows1252Path] = "Windows-1252"
$expectedEncodings[$nullBytesPath] = "UTF-16LE"

# Enregistrer les formats attendus au format JSON
$expectedFormatsPath = Join-Path -Path $OutputDirectory -ChildPath "ExpectedFormats.json"
$expectedFormats | ConvertTo-Json | Out-File -FilePath $expectedFormatsPath -Encoding utf8
Write-Host "Fichier de formats attendus créé : $expectedFormatsPath" -ForegroundColor Green

# Enregistrer les encodages attendus au format JSON
$expectedEncodingsPath = Join-Path -Path $OutputDirectory -ChildPath "ExpectedEncodings.json"
$expectedEncodings | ConvertTo-Json | Out-File -FilePath $expectedEncodingsPath -Encoding utf8
Write-Host "Fichier d'encodages attendus créé : $expectedEncodingsPath" -ForegroundColor Green

Write-Host "`nGénération des fichiers d'échantillon terminée." -ForegroundColor Cyan
Write-Host "Nombre total de fichiers créés : $($expectedFormats.Count + $expectedEncodings.Count)" -ForegroundColor Cyan
