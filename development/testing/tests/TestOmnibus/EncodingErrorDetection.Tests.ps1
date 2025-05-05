BeforeAll {
    # Importer le script Ã  tester
    $global:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\maintenance\encoding\Detect-VariableReferences.ps1"
    
    # CrÃ©er un dossier temporaire pour les tests
    $testFolder = Join-Path -Path $TestDrive -ChildPath "EncodingTests"
    New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
    
    # CrÃ©er des fichiers de test avec diffÃ©rents encodages et problÃ¨mes
    
    # 1. Fichier sans BOM avec variables dans des chaÃ®nes accentuÃ©es
    $fileNoBomWithIssuesPath = Join-Path -Path $testFolder -ChildPath "NoBomWithIssues.ps1"
    $fileNoBomWithIssuesContent = @'
# Fichier sans BOM avec variables dans des chaÃ®nes accentuÃ©es
$message = "Bonjour $username, voici un texte accentuÃ©"
Write-Host "Le rÃ©sultat est: $result"
'@
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($fileNoBomWithIssuesPath, $fileNoBomWithIssuesContent, $utf8NoBom)
    
    # 2. Fichier avec BOM avec variables dans des chaÃ®nes accentuÃ©es
    $fileBomWithIssuesPath = Join-Path -Path $testFolder -ChildPath "BomWithIssues.ps1"
    $fileBomWithIssuesContent = @'
# Fichier avec BOM avec variables dans des chaÃ®nes accentuÃ©es
$message = "Bonjour $username, voici un texte accentuÃ©"
Write-Host "Le rÃ©sultat est: $result"
'@
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($fileBomWithIssuesPath, $fileBomWithIssuesContent, $utf8WithBom)
    
    # 3. Fichier sans problÃ¨mes (pas de caractÃ¨res accentuÃ©s)
    $fileNoIssuesPath = Join-Path -Path $testFolder -ChildPath "NoIssues.ps1"
    $fileNoIssuesContent = @'
# Fichier sans problemes
$message = "Hello $username, no accents here"
Write-Host "The result is: $result"
'@
    [System.IO.File]::WriteAllText($fileNoIssuesPath, $fileNoIssuesContent, $utf8WithBom)
    
    # 4. Fichier avec caractÃ¨res accentuÃ©s mais sans variables
    $fileAccentsNoVarsPath = Join-Path -Path $testFolder -ChildPath "AccentsNoVars.ps1"
    $fileAccentsNoVarsContent = @'
# Fichier avec caractÃ¨res accentuÃ©s mais sans variables
$message = "Voici des caractÃ¨res accentuÃ©s"
Write-Host "RÃ©sultat sans variable"
'@
    [System.IO.File]::WriteAllText($fileAccentsNoVarsPath, $fileAccentsNoVarsContent, $utf8NoBom)
}

Describe "Test-FileEncoding" {
    BeforeAll {
        # DÃ©finir la fonction Ã  tester
        . $global:scriptPath
    }
    
    It "DÃ©tecte correctement l'encodage UTF-8 avec BOM" {
        $filePath = Join-Path -Path $testFolder -ChildPath "BomWithIssues.ps1"
        $result = Test-FileEncoding -FilePath $filePath
        $result.Encoding | Should -Be "UTF-8 with BOM"
        $result.HasBOM | Should -Be $true
    }
    
    It "DÃ©tecte correctement l'encodage sans BOM" {
        $filePath = Join-Path -Path $testFolder -ChildPath "NoBomWithIssues.ps1"
        $result = Test-FileEncoding -FilePath $filePath
        $result.Encoding | Should -Be "Unknown (possibly UTF-8 without BOM or ANSI)"
        $result.HasBOM | Should -Be $false
    }
    
    It "GÃ¨re correctement les fichiers inexistants" {
        { Test-FileEncoding -FilePath "FichierInexistant.ps1" } | Should -Throw
    }
}

Describe "Find-VariableReferences" {
    BeforeAll {
        # DÃ©finir la fonction Ã  tester
        . $global:scriptPath
    }
    
    It "DÃ©tecte les rÃ©fÃ©rences de variables dans les chaÃ®nes accentuÃ©es (sans BOM)" {
        $filePath = Join-Path -Path $testFolder -ChildPath "NoBomWithIssues.ps1"
        $result = Find-VariableReferences -FilePath $filePath
        $result.Count | Should -BeGreaterThan 0
        $result[0].Risk | Should -Be "Eleve"
    }
    
    It "DÃ©tecte les rÃ©fÃ©rences de variables dans les chaÃ®nes accentuÃ©es (avec BOM)" {
        $filePath = Join-Path -Path $testFolder -ChildPath "BomWithIssues.ps1"
        $result = Find-VariableReferences -FilePath $filePath
        $result.Count | Should -BeGreaterThan 0
        $result[0].Risk | Should -Be "Faible"
    }
    
    It "Ne dÃ©tecte pas de problÃ¨mes dans les fichiers sans caractÃ¨res accentuÃ©s" {
        $filePath = Join-Path -Path $testFolder -ChildPath "NoIssues.ps1"
        $result = Find-VariableReferences -FilePath $filePath
        $result.Count | Should -Be 0
    }
    
    It "Ne dÃ©tecte pas de problÃ¨mes dans les fichiers avec caractÃ¨res accentuÃ©s mais sans variables" {
        $filePath = Join-Path -Path $testFolder -ChildPath "AccentsNoVars.ps1"
        $result = Find-VariableReferences -FilePath $filePath
        $result.Count | Should -Be 0
    }
    
    It "GÃ¨re correctement les fichiers inexistants" {
        { Find-VariableReferences -FilePath "FichierInexistant.ps1" } | Should -Throw
    }
}

Describe "Start-Detection" {
    BeforeAll {
        # DÃ©finir la fonction Ã  tester
        . $global:scriptPath
    }
    
    It "DÃ©tecte les problÃ¨mes dans un dossier" {
        $result = Start-Detection -Path $testFolder
        $result.Count | Should -BeGreaterThan 0
    }
    
    It "GÃ¨re correctement les chemins inexistants" {
        { Start-Detection -Path "DossierInexistant" } | Should -Throw
    }
}
