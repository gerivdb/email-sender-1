BeforeAll {
    # Importer le script à tester
    $global:scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\development\scripts\maintenance\encoding\Repair-EncodingIssues.ps1"

    # Créer un dossier temporaire pour les tests
    $testFolder = Join-Path -Path $TestDrive -ChildPath "EncodingRepairTests"
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

Describe "Repair-FileEncoding" {
    BeforeAll {
        # Définir la fonction à tester
        . $global:scriptPath
    }

    It "Corrige l'encodage d'un fichier sans BOM" {
        # Copier le fichier de test pour ne pas modifier l'original
        $sourceFile = Join-Path -Path $testFolder -ChildPath "NoBomWithIssues.ps1"
        $targetFile = Join-Path -Path $testFolder -ChildPath "NoBomWithIssues_ToFix.ps1"
        Copy-Item -Path $sourceFile -Destination $targetFile -Force

        # Vérifier l'encodage initial
        $initialEncoding = Test-FileEncoding -FilePath $targetFile
        $initialEncoding.HasBOM | Should -Be $false

        # Corriger l'encodage
        $result = Repair-FileEncoding -FilePath $targetFile
        $result | Should -Be $true

        # Vérifier l'encodage après correction
        $fixedEncoding = Test-FileEncoding -FilePath $targetFile
        $fixedEncoding.HasBOM | Should -Be $true
        $fixedEncoding.Encoding | Should -Be "UTF-8 with BOM"

        # Vérifier que le contenu est correct
        $content = Get-Content -Path $targetFile -Raw
        $content | Should -Match "Bonjour \$username, voici un texte accentué"
    }

    It "Corrige les références de variables dans un fichier avec BOM" {
        # Copier le fichier de test pour ne pas modifier l'original
        $sourceFile = Join-Path -Path $testFolder -ChildPath "BomWithIssues.ps1"
        $targetFile = Join-Path -Path $testFolder -ChildPath "BomWithIssues_ToFix.ps1"
        Copy-Item -Path $sourceFile -Destination $targetFile -Force

        # Vérifier l'encodage initial
        $initialEncoding = Test-FileEncoding -FilePath $targetFile
        $initialEncoding.HasBOM | Should -Be $true

        # Corriger les références de variables
        $result = Repair-FileEncoding -FilePath $targetFile
        $result | Should -Be $true

        # Vérifier que le contenu est correct
        $content = Get-Content -Path $targetFile -Raw
        $content | Should -Match "Bonjour ' \+ \$username \+ ', voici un texte accentué"
    }

    It "Ne modifie pas un fichier sans problèmes" {
        # Copier le fichier de test pour ne pas modifier l'original
        $sourceFile = Join-Path -Path $testFolder -ChildPath "NoIssues.ps1"
        $targetFile = Join-Path -Path $testFolder -ChildPath "NoIssues_ToCheck.ps1"
        Copy-Item -Path $sourceFile -Destination $targetFile -Force

        # Vérifier l'encodage initial
        $initialContent = Get-Content -Path $targetFile -Raw

        # Tenter de corriger le fichier
        $result = Repair-FileEncoding -FilePath $targetFile
        $result | Should -Be $false

        # Vérifier que le contenu n'a pas changé
        $finalContent = Get-Content -Path $targetFile -Raw
        $finalContent | Should -Be $initialContent
    }

    It "Gère correctement les fichiers inexistants" {
        { Repair-FileEncoding -FilePath "FichierInexistant.ps1" } | Should -Throw
    }
}

Describe "Start-EncodingRepair" {
    BeforeAll {
        # Définir la fonction à tester
        . $global:scriptPath
    }

    It "Corrige les problèmes dans un dossier" {
        # Créer une copie du dossier de test
        $testFolderCopy = Join-Path -Path $TestDrive -ChildPath "EncodingRepairTestsCopy"
        New-Item -Path $testFolderCopy -ItemType Directory -Force | Out-Null
        Copy-Item -Path "$testFolder\*" -Destination $testFolderCopy -Force

        # Exécuter la correction
        Start-EncodingRepair -Path $testFolderCopy

        # Vérifier que tous les fichiers ont été corrigés
        $files = Get-ChildItem -Path $testFolderCopy -Filter "*.ps1"
        foreach ($file in $files) {
            $encoding = Test-FileEncoding -FilePath $file.FullName
            $encoding.HasBOM | Should -Be $true
            $encoding.Encoding | Should -Be "UTF-8 with BOM"
        }
    }

    It "Gère correctement les chemins inexistants" {
        { Start-EncodingRepair -Path "DossierInexistant" } | Should -Throw
    }
}
