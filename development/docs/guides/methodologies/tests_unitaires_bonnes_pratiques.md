# Guide des bonnes pratiques pour les tests unitaires

## Introduction

Les tests unitaires sont essentiels pour garantir la qualitÃ© du code et faciliter la maintenance. Ce guide prÃ©sente les bonnes pratiques Ã  suivre pour Ã©crire des tests unitaires efficaces et maintenables.

## Principes fondamentaux

### 1. Tests indÃ©pendants

Les tests doivent Ãªtre indÃ©pendants les uns des autres. Un test ne doit pas dÃ©pendre de l'exÃ©cution d'un autre test.

```powershell
# Mauvaise pratique

Describe "Tests dÃ©pendants" {
    It "Test 1" {
        $global:variable = "valeur"
        $global:variable | Should -Be "valeur"
    }
    
    It "Test 2" {
        $global:variable | Should -Be "valeur"
    }
}

# Bonne pratique

Describe "Tests indÃ©pendants" {
    It "Test 1" {
        $variable = "valeur"
        $variable | Should -Be "valeur"
    }
    
    It "Test 2" {
        $variable = "valeur"
        $variable | Should -Be "valeur"
    }
}
```plaintext
### 2. Tests isolÃ©s

Les tests doivent Ãªtre isolÃ©s de l'environnement extÃ©rieur. Utilisez des mocks pour simuler les dÃ©pendances externes.

```powershell
# Mauvaise pratique

function Get-FileContent {
    param($path)
    Get-Content -Path $path
}

Describe "Test non isolÃ©" {
    It "Lit le contenu d'un fichier" {
        $content = Get-FileContent -Path "C:\fichier.txt"
        $content | Should -Not -BeNullOrEmpty
    }
}

# Bonne pratique

function Get-FileContent {
    param($path)
    Get-Content -Path $path
}

Describe "Test isolÃ©" {
    It "Lit le contenu d'un fichier" {
        Mock Get-Content { return "Contenu simulÃ©" }
        $content = Get-FileContent -Path "C:\fichier.txt"
        $content | Should -Be "Contenu simulÃ©"
        Assert-MockCalled Get-Content -Times 1 -Exactly
    }
}
```plaintext
### 3. Tests dÃ©terministes

Les tests doivent toujours produire le mÃªme rÃ©sultat lorsqu'ils sont exÃ©cutÃ©s dans les mÃªmes conditions.

```powershell
# Mauvaise pratique

Describe "Test non dÃ©terministe" {
    It "GÃ©nÃ¨re un nombre alÃ©atoire" {
        $random = Get-Random -Minimum 1 -Maximum 10
        $random | Should -BeLessThan 10
    }
}

# Bonne pratique

Describe "Test dÃ©terministe" {
    It "GÃ©nÃ¨re un nombre alÃ©atoire" {
        Mock Get-Random { return 5 }
        $random = Get-Random -Minimum 1 -Maximum 10
        $random | Should -Be 5
    }
}
```plaintext
### 4. Tests rapides

Les tests doivent s'exÃ©cuter rapidement pour encourager leur exÃ©cution frÃ©quente.

```powershell
# Mauvaise pratique

Describe "Test lent" {
    It "Attend 5 secondes" {
        Start-Sleep -Seconds 5
        $true | Should -Be $true
    }
}

# Bonne pratique

Describe "Test rapide" {
    It "Simule une attente" {
        Mock Start-Sleep {}
        Start-Sleep -Seconds 5
        $true | Should -Be $true
        Assert-MockCalled Start-Sleep -Times 1 -Exactly
    }
}
```plaintext
### 5. Tests lisibles

Les tests doivent Ãªtre faciles Ã  lire et Ã  comprendre.

```powershell
# Mauvaise pratique

Describe "Test peu lisible" {
    It "t" {
        $x = 1; $y = 2; $z = $x + $y; $z | Should -Be 3
    }
}

# Bonne pratique

Describe "Test lisible" {
    It "Additionne deux nombres" {
        # Arrange

        $nombre1 = 1
        $nombre2 = 2
        
        # Act

        $resultat = $nombre1 + $nombre2
        
        # Assert

        $resultat | Should -Be 3
    }
}
```plaintext
## Structure des tests

### 1. Arrange-Act-Assert (AAA)

Structurez vos tests selon le pattern AAA :
- **Arrange** : PrÃ©parez les donnÃ©es et les conditions du test
- **Act** : ExÃ©cutez l'action Ã  tester
- **Assert** : VÃ©rifiez que le rÃ©sultat est conforme aux attentes

```powershell
Describe "Test avec pattern AAA" {
    It "Convertit une chaÃ®ne en majuscules" {
        # Arrange

        $chaine = "test"
        
        # Act

        $resultat = $chaine.ToUpper()
        
        # Assert

        $resultat | Should -Be "TEST"
    }
}
```plaintext
### 2. Given-When-Then (GWT)

Une alternative au pattern AAA est le pattern GWT :
- **Given** : Le contexte initial
- **When** : L'action dÃ©clenchÃ©e
- **Then** : Le rÃ©sultat attendu

```powershell
Describe "Test avec pattern GWT" {
    It "Convertit une chaÃ®ne en majuscules" {
        # Given

        $chaine = "test"
        
        # When

        $resultat = $chaine.ToUpper()
        
        # Then

        $resultat | Should -Be "TEST"
    }
}
```plaintext
### 3. Utilisation de Context et Describe

Utilisez `Describe` pour regrouper les tests liÃ©s Ã  une mÃªme fonction et `Context` pour regrouper les tests liÃ©s Ã  un mÃªme scÃ©nario.

```powershell
Describe "Get-ScriptCategory" {
    Context "Lorsque le nom du fichier contient 'analyze'" {
        It "Retourne 'analysis'" {
            Get-ScriptCategory -FileName "Analyze-Scripts.ps1" | Should -Be "analysis"
        }
    }
    
    Context "Lorsque le nom du fichier contient 'organize'" {
        It "Retourne 'organization'" {
            Get-ScriptCategory -FileName "Organize-Scripts.ps1" | Should -Be "organization"
        }
    }
}
```plaintext
## Techniques avancÃ©es

### 1. Tests paramÃ©trÃ©s

Utilisez des tests paramÃ©trÃ©s pour tester plusieurs cas avec un minimum de code.

```powershell
Describe "Tests paramÃ©trÃ©s" {
    $testCases = @(
        @{ FileName = "Analyze-Scripts.ps1"; ExpectedCategory = "analysis" }
        @{ FileName = "Organize-Scripts.ps1"; ExpectedCategory = "organization" }
        @{ FileName = "Show-ScriptInventory.ps1"; ExpectedCategory = "inventory" }
    )
    
    It "Retourne la catÃ©gorie '<ExpectedCategory>' pour le fichier '<FileName>'" -TestCases $testCases {
        param ($FileName, $ExpectedCategory)
        Get-ScriptCategory -FileName $FileName | Should -Be $ExpectedCategory
    }
}
```plaintext
### 2. Fixtures

Utilisez `BeforeAll`, `AfterAll`, `BeforeEach` et `AfterEach` pour prÃ©parer et nettoyer l'environnement de test.

```powershell
Describe "Tests avec fixtures" {
    BeforeAll {
        # PrÃ©paration globale avant tous les tests

        $script:tempFile = [System.IO.Path]::GetTempFileName()
        "Contenu initial" | Out-File -FilePath $script:tempFile -Encoding utf8
    }
    
    AfterAll {
        # Nettoyage global aprÃ¨s tous les tests

        Remove-Item -Path $script:tempFile -Force -ErrorAction SilentlyContinue
    }
    
    BeforeEach {
        # PrÃ©paration avant chaque test

        "Contenu initial" | Out-File -FilePath $script:tempFile -Encoding utf8
    }
    
    AfterEach {
        # Nettoyage aprÃ¨s chaque test

        # (rien Ã  faire ici dans cet exemple)

    }
    
    It "Lit le contenu du fichier" {
        $content = Get-Content -Path $script:tempFile -Raw
        $content | Should -Be "Contenu initial"
    }
    
    It "Modifie le contenu du fichier" {
        "Nouveau contenu" | Out-File -FilePath $script:tempFile -Encoding utf8
        $content = Get-Content -Path $script:tempFile -Raw
        $content | Should -Be "Nouveau contenu"
    }
}
```plaintext
### 3. Mocks avancÃ©s

Utilisez des mocks avancÃ©s pour simuler des comportements complexes.

```powershell
Describe "Mocks avancÃ©s" {
    It "Simule un comportement conditionnel" {
        Mock Get-Content {
            param($Path)
            if ($Path -eq "C:\fichier1.txt") {
                return "Contenu du fichier 1"
            }
            elseif ($Path -eq "C:\fichier2.txt") {
                return "Contenu du fichier 2"
            }
            else {
                throw "Fichier non trouvÃ©: $Path"
            }
        }
        
        $content1 = Get-Content -Path "C:\fichier1.txt"
        $content2 = Get-Content -Path "C:\fichier2.txt"
        
        $content1 | Should -Be "Contenu du fichier 1"
        $content2 | Should -Be "Contenu du fichier 2"
        
        { Get-Content -Path "C:\fichier3.txt" } | Should -Throw "Fichier non trouvÃ©: C:\fichier3.txt"
    }
}
```plaintext
### 4. Tests de mutation

Les tests de mutation modifient lÃ©gÃ¨rement le code source et vÃ©rifient si les tests dÃ©tectent ces modifications.

```powershell
# Exemple conceptuel de test de mutation

function Add-Numbers {
    param($a, $b)
    return $a + $b
}

# Test original

Describe "Add-Numbers" {
    It "Additionne deux nombres" {
        Add-Numbers -a 2 -b 3 | Should -Be 5
    }
}

# Mutation 1: Changer l'opÃ©rateur + en -

function Add-Numbers {
    param($a, $b)
    return $a - $b  # Mutation

}

# Le test devrait Ã©chouer avec cette mutation

# Mutation 2: Inverser les paramÃ¨tres

function Add-Numbers {
    param($a, $b)
    return $b + $a  # Mutation (sans effet dans ce cas)

}

# Le test devrait rÃ©ussir avec cette mutation (ce qui indique un test insuffisant)

```plaintext
## Bonnes pratiques spÃ©cifiques Ã  PowerShell

### 1. Utilisation de ShouldProcess

Testez correctement les fonctions qui utilisent `ShouldProcess`.

```powershell
function Remove-TempFile {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param($Path)
    
    if ($PSCmdlet.ShouldProcess($Path, "Supprimer")) {
        Remove-Item -Path $Path -Force
    }
}

Describe "Remove-TempFile" {
    It "Appelle ShouldProcess avec les bons paramÃ¨tres" {
        $tempFile = [System.IO.Path]::GetTempFileName()
        
        Mock Remove-Item {}
        Mock ShouldProcess { return $true } -ModuleName "MyModule"
        
        Remove-TempFile -Path $tempFile
        
        Assert-MockCalled Remove-Item -Times 1 -Exactly -ParameterFilter { $Path -eq $tempFile }
        Assert-MockCalled ShouldProcess -Times 1 -Exactly -ParameterFilter { $Target -eq $tempFile -and $Action -eq "Supprimer" } -ModuleName "MyModule"
    }
    
    It "Ne supprime pas le fichier si ShouldProcess retourne false" {
        $tempFile = [System.IO.Path]::GetTempFileName()
        
        Mock Remove-Item {}
        Mock ShouldProcess { return $false } -ModuleName "MyModule"
        
        Remove-TempFile -Path $tempFile
        
        Assert-MockCalled Remove-Item -Times 0 -Exactly
        Assert-MockCalled ShouldProcess -Times 1 -Exactly -ModuleName "MyModule"
    }
}
```plaintext
### 2. Tests de modules

Testez les modules PowerShell en utilisant `Import-Module` avec le paramÃ¨tre `-Force`.

```powershell
Describe "Tests de module" {
    BeforeAll {
        # Importer le module avec -Force pour s'assurer d'avoir la derniÃ¨re version

        Import-Module -Name "MyModule" -Force
    }
    
    It "Exporte la fonction Get-Something" {
        Get-Command -Module "MyModule" -Name "Get-Something" | Should -Not -BeNullOrEmpty
    }
    
    It "La fonction Get-Something retourne le rÃ©sultat attendu" {
        Get-Something -Param "Value" | Should -Be "Expected Result"
    }
}
```plaintext
## IntÃ©gration avec le processus de dÃ©veloppement

### 1. Tests automatisÃ©s

IntÃ©grez les tests dans le processus de dÃ©veloppement continu en utilisant des hooks Git pre-commit.

```powershell
# Exemple de hook pre-commit

#!/bin/sh

# Hook pre-commit pour exÃ©cuter les tests unitaires avant chaque commit

# Sauvegarder les fichiers modifiÃ©s

git stash -q --keep-index

# ExÃ©cuter les tests unitaires

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "development/scripts/mode-manager/testing/Run-SimplifiedTests.ps1"

# RÃ©cupÃ©rer le code de sortie

RESULT=$?

# Restaurer les fichiers modifiÃ©s

git stash pop -q

# Si les tests ont Ã©chouÃ©, annuler le commit

if [ $RESULT -ne 0 ]; then
    echo "Les tests unitaires ont Ã©chouÃ©. Le commit a Ã©tÃ© annulÃ©."
    exit 1
fi

# Si tout va bien, continuer avec le commit

exit 0
```plaintext
### 2. Tests pÃ©riodiques

Planifiez l'exÃ©cution pÃ©riodique des tests pour dÃ©tecter les rÃ©gressions.

```powershell
# Exemple de tÃ¢che planifiÃ©e

Register-ScheduledTask -TaskName "TestsQuotidiens" -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"D:\Scripts\Run-Tests.ps1`"") -Trigger (New-ScheduledTaskTrigger -Daily -At "22:00")
```plaintext
### 3. Rapports de tests

GÃ©nÃ©rez des rapports de tests pour suivre l'Ã©volution de la qualitÃ© du code.

```powershell
# Exemple de gÃ©nÃ©ration de rapport HTML

$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = ".\tests"
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = ".\reports\TestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

$testResults = Invoke-Pester -Configuration $pesterConfig

# Convertir le rapport XML en HTML

ConvertTo-Html -InputObject $testResults -Title "Rapport de tests" -Body "<h1>Rapport de tests</h1>" | Out-File -FilePath ".\reports\TestResults.html"
```plaintext
## Conclusion

Les tests unitaires sont un investissement qui paie sur le long terme. En suivant ces bonnes pratiques, vous amÃ©liorerez la qualitÃ© de votre code et faciliterez sa maintenance.

## Ressources supplÃ©mentaires

- [Documentation Pester](https://pester.dev/docs/quick-start)
- [Guide des mocks Pester](https://pester.dev/docs/usage/mocking)
- [Guide des assertions Pester](https://pester.dev/docs/usage/assertions)
- [Tests de mutation](https://en.wikipedia.org/wiki/Mutation_testing)
- [TDD (Test-Driven Development)](https://en.wikipedia.org/wiki/Test-driven_development)

