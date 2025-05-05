BeforeAll {
    # Importer le script Ã  tester
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\maintenance\encoding\Detect-VariableReferencesInAccentedStrings.ps1"
    . $scriptPath
}

Describe "Detect-VariableReferencesInAccentedStrings" {
    BeforeAll {
        # CrÃ©er des fichiers temporaires pour les tests
        $testFolder = Join-Path -Path $TestDrive -ChildPath "TestFiles"
        New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
        
        # Fichier avec des rÃ©fÃ©rences de variables dans des chaÃ®nes accentuÃ©es (UTF-8 sans BOM)
        $fileWithIssuesPath = Join-Path -Path $testFolder -ChildPath "FileWithIssues.ps1"
        $fileWithIssuesContent = @'
# Ce fichier contient des rÃ©fÃ©rences de variables dans des chaÃ®nes accentuÃ©es
$message = "Bonjour Ã  tous les utilisateurs: $username"
Write-Host "OpÃ©ration terminÃ©e avec succÃ¨s: $rÃ©sultat"
$texte = "Voici une chaÃ®ne sans problÃ¨me"
'@
        [System.IO.File]::WriteAllText($fileWithIssuesPath, $fileWithIssuesContent, [System.Text.Encoding]::UTF8)
        
        # Fichier sans problÃ¨me (UTF-8 avec BOM)
        $fileWithoutIssuesPath = Join-Path -Path $testFolder -ChildPath "FileWithoutIssues.ps1"
        $fileWithoutIssuesContent = @'
# Ce fichier ne contient pas de rÃ©fÃ©rences de variables dans des chaÃ®nes accentuÃ©es
$message = "Bonjour a tous"
Write-Host "Le resultat est: $result"
$texte = "Voici une chaÃ®ne sans variable"
'@
        $utf8WithBom = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($fileWithoutIssuesPath, $fileWithoutIssuesContent, $utf8WithBom)
    }
    
    It "DÃ©tecte les rÃ©fÃ©rences de variables dans les chaÃ®nes accentuÃ©es" {
        $results = Find-VariableReferencesInAccentedStrings -FilePath (Join-Path -Path $testFolder -ChildPath "FileWithIssues.ps1")
        $results.Count | Should -BeGreaterThan 0
        $results[0].Variables | Should -Match '\$username'
        $results[1].Variables | Should -Match '\$rÃ©sultat'
        $results[0].Risk | Should -Be "Ã‰levÃ©"
    }
    
    It "Ne dÃ©tecte pas de problÃ¨mes dans les fichiers sans rÃ©fÃ©rences de variables dans des chaÃ®nes accentuÃ©es" {
        $results = Find-VariableReferencesInAccentedStrings -FilePath (Join-Path -Path $testFolder -ChildPath "FileWithoutIssues.ps1")
        $results.Count | Should -Be 0
    }
    
    It "GÃ¨re correctement les fichiers inexistants" {
        { Find-VariableReferencesInAccentedStrings -FilePath "FichierInexistant.ps1" } | Should -Throw
    }
}

Describe "Test-FileEncoding" {
    BeforeAll {
        # CrÃ©er des fichiers temporaires pour les tests d'encodage
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
    
    It "DÃ©tecte correctement l'encodage UTF-8 avec BOM" {
        $result = Test-FileEncoding -FilePath (Join-Path -Path $testFolder -ChildPath "UTF8WithBOM.txt")
        $result.Encoding | Should -Be "UTF-8 with BOM"
        $result.HasBOM | Should -Be $true
    }
    
    It "DÃ©tecte correctement l'encodage UTF-8 sans BOM" {
        $result = Test-FileEncoding -FilePath (Join-Path -Path $testFolder -ChildPath "UTF8WithoutBOM.txt")
        $result.Encoding | Should -Be "Unknown (possibly UTF-8 without BOM or ANSI)"
        $result.HasBOM | Should -Be $false
    }
    
    It "DÃ©tecte correctement l'encodage UTF-16 LE" {
        $result = Test-FileEncoding -FilePath (Join-Path -Path $testFolder -ChildPath "UTF16LE.txt")
        $result.Encoding | Should -Be "UTF-16 LE"
        $result.HasBOM | Should -Be $true
    }
}
