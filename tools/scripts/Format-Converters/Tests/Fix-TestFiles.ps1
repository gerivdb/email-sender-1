#Requires -Version 5.1
<#
.SYNOPSIS
    Corrige les fichiers de test rÃ©els.

.DESCRIPTION
    Ce script corrige les problÃ¨mes courants dans les fichiers de test rÃ©els,
    notamment les problÃ¨mes de liaison de paramÃ¨tres.

.PARAMETER TestFile
    Le fichier de test Ã  corriger. Si non spÃ©cifiÃ©, tous les fichiers de test seront corrigÃ©s.

.EXAMPLE
    .\Fix-TestFiles.ps1
    Corrige tous les fichiers de test.

.EXAMPLE
    .\Fix-TestFiles.ps1 -TestFile "Get-FileFormatAnalysis.Tests.ps1"
    Corrige le fichier Get-FileFormatAnalysis.Tests.ps1.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TestFile
)

# Fonction pour rÃ©parer un fichier de test
function Repair-TestFile {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    Write-Host "Correction du fichier : $FilePath" -ForegroundColor Cyan

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw

    # CrÃ©er un rÃ©pertoire temporaire pour les tests
    $tempDirCode = @'
# CrÃ©er un rÃ©pertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConvertersTests_$(Get-Random)"
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null
Write-Verbose "RÃ©pertoire temporaire crÃ©Ã© : $testTempDir"

# Fonction pour crÃ©er des fichiers de test
function New-TestFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FileName,

        [Parameter(Mandatory = $false)]
        [string]$Content = "",

        [Parameter(Mandatory = $false)]
        [string]$Directory = $testTempDir
    )

    # CrÃ©er le rÃ©pertoire s'il n'existe pas
    if (-not (Test-Path -Path $Directory -PathType Container)) {
        New-Item -Path $Directory -ItemType Directory -Force | Out-Null
    }

    # CrÃ©er le chemin complet du fichier
    $filePath = Join-Path -Path $Directory -ChildPath $FileName

    # Ã‰crire le contenu dans le fichier
    $Content | Set-Content -Path $filePath -Encoding UTF8

    return $filePath
}
'@

    # Ajouter le code de crÃ©ation de rÃ©pertoire temporaire s'il n'existe pas dÃ©jÃ 
    if (-not ($content -match "\`$testTempDir\s*=\s*Join-Path")) {
        $importModuleMatch = [regex]::Match($content, "Import-Module.*\r?\n")
        if ($importModuleMatch.Success) {
            $insertPosition = $importModuleMatch.Index + $importModuleMatch.Length
            $content = $content.Insert($insertPosition, "`n$tempDirCode`n")
        }
        else {
            $content = "$tempDirCode`n`n$content"
        }
    }

    # Corriger les problÃ¨mes de liaison de paramÃ¨tres dans Get-FileFormatAnalysis.Tests.ps1
    if ($FilePath -like "*Get-FileFormatAnalysis.Tests.ps1") {
        # CrÃ©er des fichiers de test au dÃ©but du BeforeAll
        $beforeAllMatch = [regex]::Match($content, "BeforeAll\s*{")
        if ($beforeAllMatch.Success) {
            $insertPosition = $beforeAllMatch.Index + $beforeAllMatch.Length
            $testFilesCode = @'

        # CrÃ©er des fichiers de test
        $jsonFilePath = New-TestFile -FileName "test.json" -Content '{"name":"Test","version":"1.0.0"}'
        $xmlFilePath = New-TestFile -FileName "test.xml" -Content '<root><name>Test</name></root>'
        $htmlFilePath = New-TestFile -FileName "test.html" -Content '<html><body>Test</body></html>'
        $csvFilePath = New-TestFile -FileName "test.csv" -Content 'Name,Value\nTest,1'
'@
            $content = $content.Insert($insertPosition, $testFilesCode)
        }

        # Remplacer les variables vides par les chemins de fichiers crÃ©Ã©s
        $content = $content -replace '\$jsonPath(?!\w)', '$jsonFilePath'
        $content = $content -replace '\$xmlPath(?!\w)', '$xmlFilePath'
        $content = $content -replace '\$htmlPath(?!\w)', '$htmlFilePath'
        $content = $content -replace '\$csvPath(?!\w)', '$csvFilePath'
    }

    # Enregistrer les modifications
    $content | Set-Content -Path $FilePath -Encoding UTF8

    Write-Host "Fichier corrigÃ© : $FilePath" -ForegroundColor Green
}

# Obtenir les fichiers de test Ã  corriger
$testFiles = @()

if ($TestFile) {
    $testFilePath = Join-Path -Path $PSScriptRoot -ChildPath $TestFile
    if (Test-Path -Path $testFilePath -PathType Leaf) {
        $testFiles += $testFilePath
    }
    else {
        Write-Error "Le fichier de test '$TestFile' n'existe pas."
        exit 1
    }
}
else {
    $testFiles = Get-ChildItem -Path $PSScriptRoot -Filter "*.Tests.ps1" |
        Where-Object { $_.Name -notlike "*.Simplified.ps1" } |
        ForEach-Object { $_.FullName }
}

# RÃ©parer chaque fichier de test
foreach ($file in $testFiles) {
    Repair-TestFile -FilePath $file
}

Write-Host "`nLes fichiers de test ont Ã©tÃ© corrigÃ©s." -ForegroundColor Green
Write-Host "ExÃ©cutez les tests pour vÃ©rifier si les problÃ¨mes ont Ã©tÃ© rÃ©solus." -ForegroundColor Green
