BeforeAll {
    # Importer le script à tester
    $global:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\development\scripts\maintenance\encoding\Detect-VariableReferences.ps1"
    
    # Créer un dossier temporaire pour les tests
    $testFolder = Join-Path -Path $TestDrive -ChildPath "EncodingTests"
    New-Item -Path $testFolder -ItemType Directory -Force | Out-Null
    
    # Créer des fichiers de test avec différents encodages et problèmes
    
    # 1. Fichier sans BOM avec variables dans des chaînes accentuées
    $fileNoBomWithIssuesPath = Join-Path -Path $testFolder -ChildPath "NoBomWithIssues.ps1"
    $fileNoBomWithIssuesContent = @'
# Fichier sans BOM avec variables dans des chaînes accentuées
$message = "Bonjour $username, voici un texte accentué"
Write-Host "Le résultat est: $result"
'@
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($fileNoBomWithIssuesPath, $fileNoBomWithIssuesContent, $utf8NoBom)
    
    # 2. Fichier avec BOM avec variables dans des chaînes accentuées
    $fileBomWithIssuesPath = Join-Path -Path $testFolder -ChildPath "BomWithIssues.ps1"
    $fileBomWithIssuesContent = @'
# Fichier avec BOM avec variables dans des chaînes accentuées
$message = "Bonjour $username, voici un texte accentué"
Write-Host "Le résultat est: $result"
'@
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($fileBomWithIssuesPath, $fileBomWithIssuesContent, $utf8WithBom)
    
    # 3. Fichier sans problèmes (pas de caractères accentués)
    $fileNoIssuesPath = Join-Path -Path $testFolder -ChildPath "NoIssues.ps1"
    $fileNoIssuesContent = @'
# Fichier sans problemes
$message = "Hello $username, no accents here"
Write-Host "The result is: $result"
'@
    [System.IO.File]::WriteAllText($fileNoIssuesPath, $fileNoIssuesContent, $utf8WithBom)
    
    # 4. Fichier avec caractères accentués mais sans variables
    $fileAccentsNoVarsPath = Join-Path -Path $testFolder -ChildPath "AccentsNoVars.ps1"
    $fileAccentsNoVarsContent = @'
# Fichier avec caractères accentués mais sans variables
$message = "Voici des caractères accentués"
Write-Host "Résultat sans variable"
'@
    [System.IO.File]::WriteAllText($fileAccentsNoVarsPath, $fileAccentsNoVarsContent, $utf8NoBom)
}

Describe "Test-FileEncoding" {
    BeforeAll {
        # Définir la fonction à tester
        . $global:scriptPath
    }
    
    It "Détecte correctement l'encodage UTF-8 avec BOM" {
        $filePath = Join-Path -Path $testFolder -ChildPath "BomWithIssues.ps1"
        $result = Test-FileEncoding -FilePath $filePath
        $result.Encoding | Should -Be "UTF-8 with BOM"
        $result.HasBOM | Should -Be $true
    }
    
    It "Détecte correctement l'encodage sans BOM" {
        $filePath = Join-Path -Path $testFolder -ChildPath "NoBomWithIssues.ps1"
        $result = Test-FileEncoding -FilePath $filePath
        $result.Encoding | Should -Be "Unknown (possibly UTF-8 without BOM or ANSI)"
        $result.HasBOM | Should -Be $false
    }
    
    It "Gère correctement les fichiers inexistants" {
        { Test-FileEncoding -FilePath "FichierInexistant.ps1" } | Should -Throw
    }
}

Describe "Find-VariableReferences" {
    BeforeAll {
        # Définir la fonction à tester
        . $global:scriptPath
    }
    
    It "Détecte les références de variables dans les chaînes accentuées (sans BOM)" {
        $filePath = Join-Path -Path $testFolder -ChildPath "NoBomWithIssues.ps1"
        $result = Find-VariableReferences -FilePath $filePath
        $result.Count | Should -BeGreaterThan 0
        $result[0].Risk | Should -Be "Eleve"
    }
    
    It "Détecte les références de variables dans les chaînes accentuées (avec BOM)" {
        $filePath = Join-Path -Path $testFolder -ChildPath "BomWithIssues.ps1"
        $result = Find-VariableReferences -FilePath $filePath
        $result.Count | Should -BeGreaterThan 0
        $result[0].Risk | Should -Be "Faible"
    }
    
    It "Ne détecte pas de problèmes dans les fichiers sans caractères accentués" {
        $filePath = Join-Path -Path $testFolder -ChildPath "NoIssues.ps1"
        $result = Find-VariableReferences -FilePath $filePath
        $result.Count | Should -Be 0
    }
    
    It "Ne détecte pas de problèmes dans les fichiers avec caractères accentués mais sans variables" {
        $filePath = Join-Path -Path $testFolder -ChildPath "AccentsNoVars.ps1"
        $result = Find-VariableReferences -FilePath $filePath
        $result.Count | Should -Be 0
    }
    
    It "Gère correctement les fichiers inexistants" {
        { Find-VariableReferences -FilePath "FichierInexistant.ps1" } | Should -Throw
    }
}

Describe "Start-Detection" {
    BeforeAll {
        # Définir la fonction à tester
        . $global:scriptPath
    }
    
    It "Détecte les problèmes dans un dossier" {
        $result = Start-Detection -Path $testFolder
        $result.Count | Should -BeGreaterThan 0
    }
    
    It "Gère correctement les chemins inexistants" {
        { Start-Detection -Path "DossierInexistant" } | Should -Throw
    }
}
