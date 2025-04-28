# Guide des bonnes pratiques pour les tests unitaires

## Introduction

Les tests unitaires sont essentiels pour garantir la qualité du code et faciliter la maintenance. Ce guide présente les bonnes pratiques à suivre pour écrire des tests unitaires efficaces et maintenables.

## Principes fondamentaux

### 1. Tests indépendants

Les tests doivent être indépendants les uns des autres. Un test ne doit pas dépendre de l'exécution d'un autre test.

```powershell
# Mauvaise pratique
Describe "Tests dépendants" {
    It "Test 1" {
        $global:variable = "valeur"
        $global:variable | Should -Be "valeur"
    }
    
    It "Test 2" {
        $global:variable | Should -Be "valeur"
    }
}

# Bonne pratique
Describe "Tests indépendants" {
    It "Test 1" {
        $variable = "valeur"
        $variable | Should -Be "valeur"
    }
    
    It "Test 2" {
        $variable = "valeur"
        $variable | Should -Be "valeur"
    }
}
```

### 2. Tests isolés

Les tests doivent être isolés de l'environnement extérieur. Utilisez des mocks pour simuler les dépendances externes.

```powershell
# Mauvaise pratique
function Get-FileContent {
    param($path)
    Get-Content -Path $path
}

Describe "Test non isolé" {
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

Describe "Test isolé" {
    It "Lit le contenu d'un fichier" {
        Mock Get-Content { return "Contenu simulé" }
        $content = Get-FileContent -Path "C:\fichier.txt"
        $content | Should -Be "Contenu simulé"
        Assert-MockCalled Get-Content -Times 1 -Exactly
    }
}
```

### 3. Tests déterministes

Les tests doivent toujours produire le même résultat lorsqu'ils sont exécutés dans les mêmes conditions.

```powershell
# Mauvaise pratique
Describe "Test non déterministe" {
    It "Génère un nombre aléatoire" {
        $random = Get-Random -Minimum 1 -Maximum 10
        $random | Should -BeLessThan 10
    }
}

# Bonne pratique
Describe "Test déterministe" {
    It "Génère un nombre aléatoire" {
        Mock Get-Random { return 5 }
        $random = Get-Random -Minimum 1 -Maximum 10
        $random | Should -Be 5
    }
}
```

### 4. Tests rapides

Les tests doivent s'exécuter rapidement pour encourager leur exécution fréquente.

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
```

### 5. Tests lisibles

Les tests doivent être faciles à lire et à comprendre.

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
```

## Structure des tests

### 1. Arrange-Act-Assert (AAA)

Structurez vos tests selon le pattern AAA :
- **Arrange** : Préparez les données et les conditions du test
- **Act** : Exécutez l'action à tester
- **Assert** : Vérifiez que le résultat est conforme aux attentes

```powershell
Describe "Test avec pattern AAA" {
    It "Convertit une chaîne en majuscules" {
        # Arrange
        $chaine = "test"
        
        # Act
        $resultat = $chaine.ToUpper()
        
        # Assert
        $resultat | Should -Be "TEST"
    }
}
```

### 2. Given-When-Then (GWT)

Une alternative au pattern AAA est le pattern GWT :
- **Given** : Le contexte initial
- **When** : L'action déclenchée
- **Then** : Le résultat attendu

```powershell
Describe "Test avec pattern GWT" {
    It "Convertit une chaîne en majuscules" {
        # Given
        $chaine = "test"
        
        # When
        $resultat = $chaine.ToUpper()
        
        # Then
        $resultat | Should -Be "TEST"
    }
}
```

### 3. Utilisation de Context et Describe

Utilisez `Describe` pour regrouper les tests liés à une même fonction et `Context` pour regrouper les tests liés à un même scénario.

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
```

## Techniques avancées

### 1. Tests paramétrés

Utilisez des tests paramétrés pour tester plusieurs cas avec un minimum de code.

```powershell
Describe "Tests paramétrés" {
    $testCases = @(
        @{ FileName = "Analyze-Scripts.ps1"; ExpectedCategory = "analysis" }
        @{ FileName = "Organize-Scripts.ps1"; ExpectedCategory = "organization" }
        @{ FileName = "Show-ScriptInventory.ps1"; ExpectedCategory = "inventory" }
    )
    
    It "Retourne la catégorie '<ExpectedCategory>' pour le fichier '<FileName>'" -TestCases $testCases {
        param ($FileName, $ExpectedCategory)
        Get-ScriptCategory -FileName $FileName | Should -Be $ExpectedCategory
    }
}
```

### 2. Fixtures

Utilisez `BeforeAll`, `AfterAll`, `BeforeEach` et `AfterEach` pour préparer et nettoyer l'environnement de test.

```powershell
Describe "Tests avec fixtures" {
    BeforeAll {
        # Préparation globale avant tous les tests
        $script:tempFile = [System.IO.Path]::GetTempFileName()
        "Contenu initial" | Out-File -FilePath $script:tempFile -Encoding utf8
    }
    
    AfterAll {
        # Nettoyage global après tous les tests
        Remove-Item -Path $script:tempFile -Force -ErrorAction SilentlyContinue
    }
    
    BeforeEach {
        # Préparation avant chaque test
        "Contenu initial" | Out-File -FilePath $script:tempFile -Encoding utf8
    }
    
    AfterEach {
        # Nettoyage après chaque test
        # (rien à faire ici dans cet exemple)
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
```

### 3. Mocks avancés

Utilisez des mocks avancés pour simuler des comportements complexes.

```powershell
Describe "Mocks avancés" {
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
                throw "Fichier non trouvé: $Path"
            }
        }
        
        $content1 = Get-Content -Path "C:\fichier1.txt"
        $content2 = Get-Content -Path "C:\fichier2.txt"
        
        $content1 | Should -Be "Contenu du fichier 1"
        $content2 | Should -Be "Contenu du fichier 2"
        
        { Get-Content -Path "C:\fichier3.txt" } | Should -Throw "Fichier non trouvé: C:\fichier3.txt"
    }
}
```

### 4. Tests de mutation

Les tests de mutation modifient légèrement le code source et vérifient si les tests détectent ces modifications.

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

# Mutation 1: Changer l'opérateur + en -
function Add-Numbers {
    param($a, $b)
    return $a - $b  # Mutation
}

# Le test devrait échouer avec cette mutation

# Mutation 2: Inverser les paramètres
function Add-Numbers {
    param($a, $b)
    return $b + $a  # Mutation (sans effet dans ce cas)
}

# Le test devrait réussir avec cette mutation (ce qui indique un test insuffisant)
```

## Bonnes pratiques spécifiques à PowerShell

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
    It "Appelle ShouldProcess avec les bons paramètres" {
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
```

### 2. Tests de modules

Testez les modules PowerShell en utilisant `Import-Module` avec le paramètre `-Force`.

```powershell
Describe "Tests de module" {
    BeforeAll {
        # Importer le module avec -Force pour s'assurer d'avoir la dernière version
        Import-Module -Name "MyModule" -Force
    }
    
    It "Exporte la fonction Get-Something" {
        Get-Command -Module "MyModule" -Name "Get-Something" | Should -Not -BeNullOrEmpty
    }
    
    It "La fonction Get-Something retourne le résultat attendu" {
        Get-Something -Param "Value" | Should -Be "Expected Result"
    }
}
```

## Intégration avec le processus de développement

### 1. Tests automatisés

Intégrez les tests dans le processus de développement continu en utilisant des hooks Git pre-commit.

```powershell
# Exemple de hook pre-commit
#!/bin/sh
# Hook pre-commit pour exécuter les tests unitaires avant chaque commit

# Sauvegarder les fichiers modifiés
git stash -q --keep-index

# Exécuter les tests unitaires
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "development/scripts/manager/testing/Run-SimplifiedTests.ps1"

# Récupérer le code de sortie
RESULT=$?

# Restaurer les fichiers modifiés
git stash pop -q

# Si les tests ont échoué, annuler le commit
if [ $RESULT -ne 0 ]; then
    echo "Les tests unitaires ont échoué. Le commit a été annulé."
    exit 1
fi

# Si tout va bien, continuer avec le commit
exit 0
```

### 2. Tests périodiques

Planifiez l'exécution périodique des tests pour détecter les régressions.

```powershell
# Exemple de tâche planifiée
Register-ScheduledTask -TaskName "TestsQuotidiens" -Action (New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"D:\Scripts\Run-Tests.ps1`"") -Trigger (New-ScheduledTaskTrigger -Daily -At "22:00")
```

### 3. Rapports de tests

Générez des rapports de tests pour suivre l'évolution de la qualité du code.

```powershell
# Exemple de génération de rapport HTML
$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = ".\tests"
$pesterConfig.Output.Verbosity = "Detailed"
$pesterConfig.TestResult.Enabled = $true
$pesterConfig.TestResult.OutputPath = ".\reports\TestResults.xml"
$pesterConfig.TestResult.OutputFormat = "NUnitXml"

$testResults = Invoke-Pester -Configuration $pesterConfig

# Convertir le rapport XML en HTML
ConvertTo-Html -InputObject $testResults -Title "Rapport de tests" -Body "<h1>Rapport de tests</h1>" | Out-File -FilePath ".\reports\TestResults.html"
```

## Conclusion

Les tests unitaires sont un investissement qui paie sur le long terme. En suivant ces bonnes pratiques, vous améliorerez la qualité de votre code et faciliterez sa maintenance.

## Ressources supplémentaires

- [Documentation Pester](https://pester.dev/docs/quick-start)
- [Guide des mocks Pester](https://pester.dev/docs/usage/mocking)
- [Guide des assertions Pester](https://pester.dev/docs/usage/assertions)
- [Tests de mutation](https://en.wikipedia.org/wiki/Mutation_testing)
- [TDD (Test-Driven Development)](https://en.wikipedia.org/wiki/Test-driven_development)
