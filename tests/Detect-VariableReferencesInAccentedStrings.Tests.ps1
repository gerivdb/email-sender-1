BeforeAll {
    # Importer le script à tester
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\scripts\maintenance\encoding\Detect-VariableReferencesInAccentedStrings.ps1"
    . $scriptPath
}

Describe "Detect-VariableReferencesInAccentedStrings" {
    BeforeAll {
        # Créer des fichiers temporaires pour les tests
        $testFolder = Join-Path -Path $TestDrive -ChildPath "TestFiles"
        New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
        
        # Fichier avec des références de variables dans des chaînes accentuées (UTF-8 sans BOM)
        $fileWithIssuesPath = Join-Path -Path $testFolder -ChildPath "FileWithIssues.ps1"
        $fileWithIssuesContent = @'
# Ce fichier contient des références de variables dans des chaînes accentuées
$message = "Bonjour à tous les utilisateurs: $username"
Write-Host "Opération terminée avec succès: $résultat"
$texte = "Voici une chaîne sans problème"
'@
        [System.IO.File]::WriteAllText($fileWithIssuesPath, $fileWithIssuesContent, [System.Text.Encoding]::UTF8)
        
        # Fichier sans problème (UTF-8 avec BOM)
        $fileWithoutIssuesPath = Join-Path -Path $testFolder -ChildPath "FileWithoutIssues.ps1"
        $fileWithoutIssuesContent = @'
# Ce fichier ne contient pas de références de variables dans des chaînes accentuées
$message = "Bonjour a tous"
Write-Host "Le resultat est: $result"
$texte = "Voici une chaîne sans variable"
'@
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($fileWithoutIssuesPath, $fileWithoutIssuesContent, $utf8WithBom)
    }
    
    It "Détecte les références de variables dans les chaînes accentuées" {
        $results = Find-VariableReferencesInAccentedStrings -FilePath (Join-Path -Path $testFolder -ChildPath "FileWithIssues.ps1")
        $results.Count | Should -BeGreaterThan 0
        $results[0].Variables | Should -Match '\$username'
        $results[1].Variables | Should -Match '\$résultat'
        $results[0].Risk | Should -Be "Élevé"
    }
    
    It "Ne détecte pas de problèmes dans les fichiers sans références de variables dans des chaînes accentuées" {
        $results = Find-VariableReferencesInAccentedStrings -FilePath (Join-Path -Path $testFolder -ChildPath "FileWithoutIssues.ps1")
        $results.Count | Should -Be 0
    }
    
    It "Gère correctement les fichiers inexistants" {
        { Find-VariableReferencesInAccentedStrings -FilePath "FichierInexistant.ps1" } | Should -Throw
    }
}

Describe "Test-FileEncoding" {
    BeforeAll {
        # Créer des fichiers temporaires pour les tests d'encodage
        $testFolder = Join-Path -Path $TestDrive -ChildPath "EncodingTests"
        New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
        
        # Fichier UTF-8 avec BOM
        $utf8WithBomPath = Join-Path -Path $testFolder -ChildPath "UTF8WithBOM.txt"
        $utf8WithBomEncoding = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($utf8WithBomPath, "Test UTF-8 with BOM", $utf8WithBomEncoding)
        
        # Fichier UTF-8 sans BOM
        $utf8WithoutBomPath = Join-Path -Path $testFolder -ChildPath "UTF8WithoutBOM.txt"
        $utf8WithoutBomEncoding = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($utf8WithoutBomPath, "Test UTF-8 without BOM", $utf8WithoutBomEncoding)
        
        # Fichier UTF-16 LE
        $utf16LEPath = Join-Path -Path $testFolder -ChildPath "UTF16LE.txt"
        [System.IO.File]::WriteAllText($utf16LEPath, "Test UTF-16 LE", [System.Text.Encoding]::Unicode)
    }
    
    It "Détecte correctement l'encodage UTF-8 avec BOM" {
        $result = Test-FileEncoding -FilePath (Join-Path -Path $testFolder -ChildPath "UTF8WithBOM.txt")
        $result.Encoding | Should -Be "UTF-8 with BOM"
        $result.HasBOM | Should -Be $true
    }
    
    It "Détecte correctement l'encodage UTF-8 sans BOM" {
        $result = Test-FileEncoding -FilePath (Join-Path -Path $testFolder -ChildPath "UTF8WithoutBOM.txt")
        $result.Encoding | Should -Be "Unknown (possibly UTF-8 without BOM or ANSI)"
        $result.HasBOM | Should -Be $false
    }
    
    It "Détecte correctement l'encodage UTF-16 LE" {
        $result = Test-FileEncoding -FilePath (Join-Path -Path $testFolder -ChildPath "UTF16LE.txt")
        $result.Encoding | Should -Be "UTF-16 LE"
        $result.HasBOM | Should -Be $true
    }
}
