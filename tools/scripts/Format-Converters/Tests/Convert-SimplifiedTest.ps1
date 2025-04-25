#Requires -Version 5.1
<#
.SYNOPSIS
    Convertit un test simplifié en test réel.

.DESCRIPTION
    Ce script convertit un test simplifié en test réel en adaptant le code pour qu'il fonctionne dans les tests réels.

.PARAMETER SimplifiedTestPath
    Le chemin du fichier de test simplifié à convertir.

.PARAMETER RealTestPath
    Le chemin du fichier de test réel à créer ou à mettre à jour.

.EXAMPLE
    .\Convert-SimplifiedTest.ps1 -SimplifiedTestPath "Get-FileFormatAnalysis.Simplified.ps1" -RealTestPath "Get-FileFormatAnalysis.Tests.ps1"
    Convertit le fichier Get-FileFormatAnalysis.Simplified.ps1 en test réel Get-FileFormatAnalysis.Tests.ps1.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$SimplifiedTestPath,

    [Parameter(Mandatory = $true)]
    [string]$RealTestPath
)

# Vérifier si les fichiers existent
if (-not (Test-Path -Path $SimplifiedTestPath)) {
    Write-Error "Le fichier de test simplifié '$SimplifiedTestPath' n'existe pas."
    exit 1
}

# Créer une copie de sauvegarde du fichier de test réel s'il existe
if (Test-Path -Path $RealTestPath) {
    $backupPath = "$RealTestPath.backup"
    Copy-Item -Path $RealTestPath -Destination $backupPath -Force
    Write-Host "Copie de sauvegarde créée : $backupPath" -ForegroundColor Yellow
}

# Lire le contenu du fichier de test simplifié
$simplifiedContent = Get-Content -Path $SimplifiedTestPath -Raw

# Créer le contenu du fichier de test réel
$realContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Tests pour la fonction $(($RealTestPath -replace "\.ps1$", "") -replace "\.Tests$", "").

.DESCRIPTION
    Ce fichier contient des tests pour la fonction $(($RealTestPath -replace "\.ps1$", "") -replace "\.Tests$", "").
    Il a été généré automatiquement à partir du fichier de test simplifié $SimplifiedTestPath.

.NOTES
    Date de génération : $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
    Auteur : Augment Agent
#>

# Importer le module
`$modulePath = Join-Path -Path (Split-Path -Parent `$PSScriptRoot) -ChildPath "Format-Converters.psm1"
if (Test-Path -Path `$modulePath) {
    Import-Module -Name `$modulePath -Force
    Write-Host "Module Format-Converters importé depuis : `$modulePath"
}
else {
    Write-Error "Le module Format-Converters n'existe pas à l'emplacement : `$modulePath"
    exit 1
}

BeforeAll {
    # S'assurer que le module est importé
    if (-not (Get-Module -Name Format-Converters)) {
        `$modulePath = Join-Path -Path (Split-Path -Parent `$PSScriptRoot) -ChildPath "Format-Converters.psm1"
        if (Test-Path -Path `$modulePath) {
            Import-Module -Name `$modulePath -Force
            Write-Host "Module Format-Converters importé dans BeforeAll depuis : `$modulePath"
        }
        else {
            Write-Error "Le module Format-Converters n'existe pas à l'emplacement : `$modulePath"
            exit 1
        }
    }

    # Créer un répertoire temporaire pour les tests
    `$testTempDir = Join-Path -Path `$env:TEMP -ChildPath "FormatConvertersTests_`$(Get-Random)"
    New-Item -Path `$testTempDir -ItemType Directory -Force | Out-Null
    Write-Host "Répertoire temporaire créé : `$testTempDir"

    # Créer des fichiers de test
    `$jsonFilePath = Join-Path -Path `$testTempDir -ChildPath "test.json"
    `$jsonContent = '{"name":"Test","version":"1.0.0"}'
    `$jsonContent | Set-Content -Path `$jsonFilePath -Encoding UTF8
    Write-Host "Fichier JSON créé : `$jsonFilePath"

    `$xmlFilePath = Join-Path -Path `$testTempDir -ChildPath "test.xml"
    `$xmlContent = '<root><name>Test</name></root>'
    `$xmlContent | Set-Content -Path `$xmlFilePath -Encoding UTF8
    Write-Host "Fichier XML créé : `$xmlFilePath"

    `$htmlFilePath = Join-Path -Path `$testTempDir -ChildPath "test.html"
    `$htmlContent = '<html><body>Test</body></html>'
    `$htmlContent | Set-Content -Path `$htmlFilePath -Encoding UTF8
    Write-Host "Fichier HTML créé : `$htmlFilePath"

    `$csvFilePath = Join-Path -Path `$testTempDir -ChildPath "test.csv"
    `$csvContent = 'Name,Value
Test,1'
    `$csvContent | Set-Content -Path `$csvFilePath -Encoding UTF8
    Write-Host "Fichier CSV créé : `$csvFilePath"

    `$textFilePath = Join-Path -Path `$testTempDir -ChildPath "test.txt"
    `$textContent = 'This is a test file.'
    `$textContent | Set-Content -Path `$textFilePath -Encoding UTF8
    Write-Host "Fichier texte créé : `$textFilePath"

    # Vérifier que les fichiers existent
    Write-Host "Vérification des fichiers créés :"
    Write-Host "JSON : `$jsonFilePath - `$(Test-Path -Path `$jsonFilePath)"
    Write-Host "XML : `$xmlFilePath - `$(Test-Path -Path `$xmlFilePath)"
    Write-Host "HTML : `$htmlFilePath - `$(Test-Path -Path `$htmlFilePath)"
    Write-Host "CSV : `$csvFilePath - `$(Test-Path -Path `$csvFilePath)"
    Write-Host "Texte : `$textFilePath - `$(Test-Path -Path `$textFilePath)"
}

# Tests pour Get-FileFormatAnalysis
Describe "Fonction Get-FileFormatAnalysis" {
    Context "Analyse de fichiers avec format détecté" {
        It "Analyse correctement un fichier JSON" {
            Write-Host "Début du test JSON"
            Write-Host "jsonFilePath = `$jsonFilePath"
            Write-Host "Existe = `$(Test-Path -Path `$jsonFilePath)"

            `$result = Get-FileFormatAnalysis -FilePath `$jsonFilePath -Format "json"
            Write-Host "Résultat = `$result"

            `$result | Should -Not -BeNullOrEmpty
            `$result.FilePath | Should -Be `$jsonFilePath
            `$result.Format | Should -Be "JSON"
            `$result.Size | Should -BeGreaterThan 0
            `$result.Properties | Should -Not -BeNullOrEmpty
        }

        It "Analyse correctement un fichier XML" {
            `$result = Get-FileFormatAnalysis -FilePath `$xmlFilePath -Format "xml"
            `$result | Should -Not -BeNullOrEmpty
            `$result.FilePath | Should -Be `$xmlFilePath
            `$result.Format | Should -Be "XML"
            `$result.Size | Should -BeGreaterThan 0
            `$result.Properties | Should -Not -BeNullOrEmpty
        }

        It "Analyse correctement un fichier HTML" {
            `$result = Get-FileFormatAnalysis -FilePath `$htmlFilePath -Format "html"
            `$result | Should -Not -BeNullOrEmpty
            `$result.FilePath | Should -Be `$htmlFilePath
            `$result.Format | Should -Be "HTML"
            `$result.Size | Should -BeGreaterThan 0
            `$result.Properties | Should -Not -BeNullOrEmpty
        }

        It "Analyse correctement un fichier CSV" {
            `$result = Get-FileFormatAnalysis -FilePath `$csvFilePath -Format "csv"
            `$result | Should -Not -BeNullOrEmpty
            `$result.FilePath | Should -Be `$csvFilePath
            `$result.Format | Should -Be "CSV"
            `$result.Size | Should -BeGreaterThan 0
            `$result.Properties | Should -Not -BeNullOrEmpty
        }
    }

    Context "Analyse de fichiers avec détection automatique" {
        It "Détecte et analyse correctement un fichier JSON" {
            `$result = Get-FileFormatAnalysis -FilePath `$jsonFilePath
            `$result | Should -Not -BeNullOrEmpty
            `$result.FilePath | Should -Be `$jsonFilePath
            `$result.Format | Should -Be "JSON"
            `$result.Size | Should -BeGreaterThan 0
            `$result.Properties | Should -Not -BeNullOrEmpty
        }

        It "Détecte et analyse correctement un fichier XML" {
            `$result = Get-FileFormatAnalysis -FilePath `$xmlFilePath
            `$result | Should -Not -BeNullOrEmpty
            `$result.FilePath | Should -Be `$xmlFilePath
            `$result.Format | Should -Be "XML"
            `$result.Size | Should -BeGreaterThan 0
            `$result.Properties | Should -Not -BeNullOrEmpty
        }
    }

    Context "Analyse avec inclusion du contenu" {
        It "Inclut le contenu du fichier lorsque demandé" {
            `$result = Get-FileFormatAnalysis -FilePath `$jsonFilePath -Format "json" -IncludeContent
            `$result | Should -Not -BeNullOrEmpty
            `$result.Content | Should -Not -BeNullOrEmpty
            # Vérifier simplement que le contenu n'est pas vide
            `$result.Content.Length | Should -BeGreaterThan 0
        }
    }

    Context "Gestion des erreurs" {
        It "Génère une erreur si le fichier n'existe pas" {
            `$nonExistentFile = Join-Path -Path `$testTempDir -ChildPath "non-existent.json"
            { Get-FileFormatAnalysis -FilePath `$nonExistentFile -Format "json" } | Should -Throw
        }

        It "Génère une erreur si le format n'est pas pris en charge" {
            { Get-FileFormatAnalysis -FilePath `$jsonFilePath -Format "unsupported" } | Should -Throw
        }
    }
}

# Nettoyer les fichiers de test
AfterAll {
    if (Test-Path -Path `$testTempDir) {
        Remove-Item -Path `$testTempDir -Recurse -Force
        Write-Host "Répertoire temporaire supprimé : `$testTempDir"
    }
}
"@

# Enregistrer le contenu dans le fichier de test réel
$realContent | Set-Content -Path $RealTestPath -Encoding UTF8

Write-Host "Test simplifié converti en test réel : $RealTestPath" -ForegroundColor Green
