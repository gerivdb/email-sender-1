#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires pour le module FileSecurityUtils.ps1.
.DESCRIPTION
    Ce script contient des tests unitaires pour le module FileSecurityUtils.ps1.
.NOTES
    Version: 1.0.0
    Auteur: EMAIL_SENDER_1 Team
    Date de création: 2025-06-06
#>

# Importer Pester
if (-not (Get-Module -Name Pester -ListAvailable)) {
    Write-Warning "Le module Pester n'est pas installé. Installation en cours..."
    Install-Module -Name Pester -Force -SkipPublisherCheck
}

Import-Module Pester -Force

# Chemins des modules à tester
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$modulesPath = Join-Path -Path $projectRoot -ChildPath "modules"
$securityUtilsPath = Join-Path -Path $modulesPath -ChildPath "FileSecurityUtils.ps1"
$unifiedSegmenterPath = Join-Path -Path $modulesPath -ChildPath "UnifiedSegmenter.ps1"

# Créer un répertoire temporaire pour les tests
$testTempDir = Join-Path -Path $env:TEMP -ChildPath "FileSecurityUtilsTests"
if (Test-Path -Path $testTempDir) {
    Remove-Item -Path $testTempDir -Recurse -Force
}
New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers de test
$validJsonPath = Join-Path -Path $testTempDir -ChildPath "valid.json"
$validCsvPath = Join-Path -Path $testTempDir -ChildPath "valid.csv"
$invalidJsonPath = Join-Path -Path $testTempDir -ChildPath "invalid.json"
$suspiciousFilePath = Join-Path -Path $testTempDir -ChildPath "suspicious.json"
$executableFilePath = Join-Path -Path $testTempDir -ChildPath "executable.txt"
$largeFilePath = Join-Path -Path $testTempDir -ChildPath "large.json"

# Créer un fichier JSON valide
$validJsonContent = @{
    "name" = "Example Object"
    "items" = @(
        @{ "id" = 1; "value" = "Item 1"; "description" = "Description 1" },
        @{ "id" = 2; "value" = "Item 2"; "description" = "Description 2" },
        @{ "id" = 3; "value" = "Item 3"; "description" = "Description 3" }
    )
} | ConvertTo-Json -Depth 10
Set-Content -Path $validJsonPath -Value $validJsonContent -Encoding UTF8

# Créer un fichier CSV valide
$validCsvContent = @"
id,name,value,description
1,Item 1,Value 1,"Description 1"
2,Item 2,Value 2,"Description 2"
3,Item 3,Value 3,"Description 3"
"@
Set-Content -Path $validCsvPath -Value $validCsvContent -Encoding UTF8

# Créer un fichier JSON invalide
$invalidJsonContent = @"
{
    "name": "Invalid JSON",
    "items": [
        {"id": 1, "value": "Item 1"},
        {"id": 2, "value": "Item 2"},
        {"id": 3, "value": "Item 3"
    ]
}
"@
Set-Content -Path $invalidJsonPath -Value $invalidJsonContent -Encoding UTF8

# Créer un fichier avec du contenu suspect
$suspiciousContent = @"
{
    "name": "Suspicious Content",
    "script": "Invoke-Expression 'Get-Process'",
    "items": [
        {"id": 1, "value": "Item 1"},
        {"id": 2, "value": "Item 2"},
        {"id": 3, "value": "Item 3"}
    ]
}
"@
Set-Content -Path $suspiciousFilePath -Value $suspiciousContent -Encoding UTF8

# Créer un fichier avec du contenu exécutable
$executableContent = @"
<script>
    alert('Hello, World!');
</script>

SELECT * FROM users WHERE username = 'admin';

function runCommand() {
    var cmd = 'cmd.exe /c dir';
    eval(cmd);
}
"@
Set-Content -Path $executableFilePath -Value $executableContent -Encoding UTF8

# Créer un fichier volumineux
$largeJsonContent = @{
    "array" = (1..10000 | ForEach-Object { @{ "id" = $_; "value" = "Value $_" } })
} | ConvertTo-Json -Depth 10
Set-Content -Path $largeFilePath -Value $largeJsonContent -Encoding UTF8

# Définir les tests
Describe "Tests du module FileSecurityUtils" {
    BeforeAll {
        # Importer les modules
        . $securityUtilsPath
        . $unifiedSegmenterPath
        
        # Initialiser le segmenteur unifié
        $initResult = Initialize-UnifiedSegmenter
        $initResult | Should -Be $true
    }
    
    Context "Tests de la fonction Test-SecurePath" {
        It "Valide correctement un chemin valide" {
            $result = Test-SecurePath -Path $validJsonPath -AllowRelativePaths
            $result | Should -Be $true
        }
        
        It "Rejette un chemin avec une extension bloquée" {
            $result = Test-SecurePath -Path "C:\temp\script.ps1" -AllowRelativePaths
            $result | Should -Be $false
        }
        
        It "Valide correctement un chemin avec une extension autorisée" {
            $result = Test-SecurePath -Path $validJsonPath -AllowedExtensions @(".json", ".csv", ".yaml")
            $result | Should -Be $true
        }
        
        It "Rejette un chemin avec une extension non autorisée" {
            $result = Test-SecurePath -Path $validCsvPath -AllowedExtensions @(".json", ".yaml")
            $result | Should -Be $false
        }
        
        It "Rejette un chemin vide" {
            { Test-SecurePath -Path "" } | Should -Throw
        }
        
        It "Rejette un chemin avec des caractères invalides" {
            { Test-SecurePath -Path "C:\temp\invalid<>|.txt" } | Should -Throw
        }
        
        It "Rejette un chemin relatif si AllowRelativePaths n'est pas spécifié" {
            $result = Test-SecurePath -Path "temp\file.txt"
            $result | Should -Be $false
        }
    }
    
    Context "Tests de la fonction Test-SecureContent" {
        It "Valide correctement un contenu sûr" {
            $result = Test-SecureContent -FilePath $validJsonPath
            $result | Should -Be $true
        }
        
        It "Rejette un contenu suspect" {
            $result = Test-SecureContent -FilePath $suspiciousFilePath -CheckForExecutableContent
            $result | Should -Be $false
        }
        
        It "Rejette un contenu exécutable" {
            $result = Test-SecureContent -FilePath $executableFilePath -CheckForExecutableContent
            $result | Should -Be $false
        }
        
        It "Rejette un fichier trop volumineux" {
            $result = Test-SecureContent -FilePath $largeFilePath -MaxFileSizeKB 1
            $result | Should -Be $false
        }
        
        It "Valide correctement un fichier volumineux si la taille maximale est suffisante" {
            $fileSize = (Get-Item -Path $largeFilePath).Length / 1KB
            $result = Test-SecureContent -FilePath $largeFilePath -MaxFileSizeKB ($fileSize + 1)
            $result | Should -Be $true
        }
        
        It "Rejette un fichier inexistant" {
            { Test-SecureContent -FilePath "C:\temp\nonexistent.txt" } | Should -Throw
        }
    }
    
    Context "Tests de la fonction Test-FileSecurely" {
        It "Valide correctement un fichier JSON valide" {
            $result = Test-FileSecurely -FilePath $validJsonPath -Format "JSON"
            $result | Should -Be $true
        }
        
        It "Rejette un fichier JSON invalide" {
            $result = Test-FileSecurely -FilePath $invalidJsonPath -Format "JSON"
            $result | Should -Be $false
        }
        
        It "Valide correctement un fichier CSV valide" {
            $result = Test-FileSecurely -FilePath $validCsvPath -Format "CSV"
            $result | Should -Be $true
        }
        
        It "Rejette un fichier avec du contenu suspect" {
            $result = Test-FileSecurely -FilePath $suspiciousFilePath -Format "JSON" -CheckForExecutableContent
            $result | Should -Be $false
        }
        
        It "Rejette un fichier trop volumineux" {
            $result = Test-FileSecurely -FilePath $largeFilePath -Format "JSON" -MaxFileSizeKB 1
            $result | Should -Be $false
        }
        
        It "Détecte automatiquement le format du fichier" {
            $result = Test-FileSecurely -FilePath $validJsonPath -Format "AUTO"
            $result | Should -Be $true
        }
        
        It "Rejette un fichier inexistant" {
            { Test-FileSecurely -FilePath "C:\temp\nonexistent.txt" } | Should -Throw
        }
    }
    
    Context "Tests d'intégration" {
        It "Intègre correctement avec le module UnifiedSegmenter" {
            # Créer une fonction de test
            function Test-Integration {
                param (
                    [Parameter(Mandatory = $true)]
                    [string]$FilePath,
                    
                    [Parameter(Mandatory = $false)]
                    [string]$Format = "AUTO"
                )
                
                # Valider le fichier de manière sécurisée
                $isSecureFile = Test-FileSecurely -FilePath $FilePath -Format $Format
                
                if (-not $isSecureFile) {
                    return $false
                }
                
                # Obtenir le format du fichier
                if ($Format -eq "AUTO") {
                    $Format = Get-FileFormat -FilePath $FilePath
                }
                
                # Valider le fichier selon son format
                $isValid = Test-FileValidity -FilePath $FilePath -Format $Format
                
                return $isValid
            }
            
            # Tester l'intégration
            $result = Test-Integration -FilePath $validJsonPath
            $result | Should -Be $true
            
            $result = Test-Integration -FilePath $invalidJsonPath
            $result | Should -Be $false
        }
    }
    
    AfterAll {
        # Nettoyer les fichiers de test
        if (Test-Path -Path $testTempDir) {
            Remove-Item -Path $testTempDir -Recurse -Force
        }
    }
}
