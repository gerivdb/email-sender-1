# Bonnes Pratiques pour les Tests Pester

Ce guide prÃ©sente les bonnes pratiques pour Ã©crire des tests Pester efficaces et maintenables pour le module Format-Converters.

## Principes Fondamentaux

### 1. Tests IndÃ©pendants

Chaque test doit Ãªtre indÃ©pendant des autres tests. Un test ne doit pas dÃ©pendre de l'Ã©tat laissÃ© par un autre test.

```powershell
# Mauvaise pratique
Describe "Tests dÃ©pendants" {
    It "Premier test" {
        $global:result = Get-FileFormatAnalysis -FilePath "test.json"
        $global:result | Should -Not -BeNullOrEmpty
    }
    
    It "DeuxiÃ¨me test" {
        # DÃ©pend du premier test
        $global:result.Format | Should -Be "JSON"
    }
}

# Bonne pratique
Describe "Tests indÃ©pendants" {
    It "Premier test" {
        $result = Get-FileFormatAnalysis -FilePath "test.json"
        $result | Should -Not -BeNullOrEmpty
    }
    
    It "DeuxiÃ¨me test" {
        $result = Get-FileFormatAnalysis -FilePath "test.json"
        $result.Format | Should -Be "JSON"
    }
}
```

### 2. Un Seul Concept par Test

Chaque test doit vÃ©rifier un seul concept ou comportement.

```powershell
# Mauvaise pratique
It "Analyse un fichier JSON et vÃ©rifie plusieurs propriÃ©tÃ©s" {
    $result = Get-FileFormatAnalysis -FilePath "test.json"
    $result | Should -Not -BeNullOrEmpty
    $result.FilePath | Should -Be "test.json"
    $result.Format | Should -Be "JSON"
    $result.Size | Should -BeGreaterThan 0
    $result.Properties | Should -Not -BeNullOrEmpty
}

# Bonne pratique
Context "Analyse d'un fichier JSON" {
    BeforeEach {
        $result = Get-FileFormatAnalysis -FilePath "test.json"
    }
    
    It "Retourne un rÃ©sultat non vide" {
        $result | Should -Not -BeNullOrEmpty
    }
    
    It "Retourne le bon chemin de fichier" {
        $result.FilePath | Should -Be "test.json"
    }
    
    It "DÃ©tecte correctement le format JSON" {
        $result.Format | Should -Be "JSON"
    }
    
    It "Retourne une taille de fichier valide" {
        $result.Size | Should -BeGreaterThan 0
    }
    
    It "Inclut les propriÃ©tÃ©s du fichier" {
        $result.Properties | Should -Not -BeNullOrEmpty
    }
}
```

### 3. Nommage Descriptif

Utilisez des noms descriptifs pour vos tests qui expliquent clairement ce qui est testÃ©.

```powershell
# Mauvaise pratique
It "Test 1" {
    # ...
}

# Bonne pratique
It "DÃ©tecte correctement le format JSON d'un fichier valide" {
    # ...
}
```

### 4. Organisation HiÃ©rarchique

Organisez vos tests de maniÃ¨re hiÃ©rarchique avec `Describe`, `Context` et `It`.

```powershell
Describe "Fonction Get-FileFormatAnalysis" {
    Context "Analyse de fichiers avec format spÃ©cifiÃ©" {
        It "Analyse correctement un fichier JSON" {
            # ...
        }
        
        It "Analyse correctement un fichier XML" {
            # ...
        }
    }
    
    Context "Analyse de fichiers avec dÃ©tection automatique" {
        It "DÃ©tecte et analyse correctement un fichier JSON" {
            # ...
        }
        
        It "DÃ©tecte et analyse correctement un fichier XML" {
            # ...
        }
    }
}
```

## Structure des Tests

### 1. Configuration et Nettoyage

Utilisez `BeforeAll`, `BeforeEach`, `AfterEach` et `AfterAll` pour configurer et nettoyer l'environnement de test.

```powershell
Describe "Tests avec configuration et nettoyage" {
    BeforeAll {
        # ExÃ©cutÃ© une fois avant tous les tests
        $script:testTempDir = Join-Path -Path $env:TEMP -ChildPath "TestDir_$(Get-Random)"
        New-Item -Path $script:testTempDir -ItemType Directory -Force | Out-Null
    }
    
    BeforeEach {
        # ExÃ©cutÃ© avant chaque test
        $testFilePath = Join-Path -Path $script:testTempDir -ChildPath "test.json"
        '{"name":"Test"}' | Set-Content -Path $testFilePath -Encoding UTF8
    }
    
    It "Test 1" {
        # ...
    }
    
    It "Test 2" {
        # ...
    }
    
    AfterEach {
        # ExÃ©cutÃ© aprÃ¨s chaque test
        Get-ChildItem -Path $script:testTempDir -File | Remove-Item -Force
    }
    
    AfterAll {
        # ExÃ©cutÃ© une fois aprÃ¨s tous les tests
        if (Test-Path -Path $script:testTempDir) {
            Remove-Item -Path $script:testTempDir -Recurse -Force
        }
    }
}
```

### 2. Tests ParamÃ©trÃ©s

Utilisez des tests paramÃ©trÃ©s pour tester plusieurs cas similaires.

```powershell
It "DÃ©tecte correctement le format <format>" -TestCases @(
    @{ Format = "json"; Content = '{"name":"Test"}'; ExpectedFormat = "JSON" }
    @{ Format = "xml"; Content = '<root><name>Test</name></root>'; ExpectedFormat = "XML" }
    @{ Format = "html"; Content = '<html><body>Test</body></html>'; ExpectedFormat = "HTML" }
    @{ Format = "csv"; Content = 'Name,Value\nTest,1'; ExpectedFormat = "CSV" }
) {
    param($Format, $Content, $ExpectedFormat)
    
    $filePath = Join-Path -Path $testTempDir -ChildPath "test.$Format"
    $Content | Set-Content -Path $filePath -Encoding UTF8
    
    $result = Get-FileFormatAnalysis -FilePath $filePath
    $result.Format | Should -Be $ExpectedFormat
}
```

### 3. Mocks

Utilisez des mocks pour isoler le code testÃ© et simuler des comportements spÃ©cifiques.

```powershell
Describe "Tests avec mocks" {
    It "GÃ¨re correctement les erreurs de lecture de fichier" {
        # Mocker la fonction Get-Content pour qu'elle lÃ¨ve une exception
        Mock Get-Content { throw "Erreur de lecture" }
        
        # VÃ©rifier que la fonction gÃ¨re correctement l'erreur
        { Get-FileFormatAnalysis -FilePath "test.json" } | Should -Throw "Impossible de lire le fichier"
    }
}
```

## Assertions

### 1. Assertions de Base

Utilisez les assertions de base pour vÃ©rifier les valeurs et les comportements.

```powershell
# Ã‰galitÃ©
$result.Format | Should -Be "JSON"

# Ã‰galitÃ© sensible Ã  la casse
$result.Format | Should -BeExactly "JSON"

# VÃ©rifier qu'une valeur est vraie
$result.IsValid | Should -BeTrue

# VÃ©rifier qu'une valeur est fausse
$result.HasErrors | Should -BeFalse

# VÃ©rifier qu'une valeur est nulle
$result.Errors | Should -BeNullOrEmpty

# VÃ©rifier qu'une valeur n'est pas nulle
$result.Properties | Should -Not -BeNullOrEmpty
```

### 2. Assertions de Collection

Utilisez les assertions de collection pour vÃ©rifier les tableaux et les listes.

```powershell
# VÃ©rifier qu'une collection contient un Ã©lÃ©ment
$result.SupportedFormats | Should -Contain "JSON"

# VÃ©rifier qu'une collection ne contient pas un Ã©lÃ©ment
$result.SupportedFormats | Should -Not -Contain "INVALID"

# VÃ©rifier qu'une collection est vide
$result.Errors | Should -BeNullOrEmpty

# VÃ©rifier qu'une collection a un nombre spÃ©cifique d'Ã©lÃ©ments
$result.Properties.Count | Should -Be 3
```

### 3. Assertions d'Exception

Utilisez les assertions d'exception pour vÃ©rifier que le code lÃ¨ve des exceptions.

```powershell
# VÃ©rifier qu'une expression lÃ¨ve une exception
{ Get-FileFormatAnalysis -FilePath "nonexistent.json" } | Should -Throw

# VÃ©rifier qu'une expression lÃ¨ve une exception spÃ©cifique
{ Get-FileFormatAnalysis -FilePath "nonexistent.json" } | Should -Throw "Le fichier n'existe pas"

# VÃ©rifier qu'une expression ne lÃ¨ve pas d'exception
{ Get-FileFormatAnalysis -FilePath "test.json" } | Should -Not -Throw
```

### 4. Assertions de Type

Utilisez les assertions de type pour vÃ©rifier le type des objets.

```powershell
# VÃ©rifier le type d'un objet
$result | Should -BeOfType [PSCustomObject]

# VÃ©rifier qu'un objet a une propriÃ©tÃ©
$result | Should -Have-Property "Format"

# VÃ©rifier qu'un objet a une mÃ©thode
$result | Should -Have-Method "ToString"
```

## Bonnes Pratiques AvancÃ©es

### 1. Tests de Performance

Utilisez `Measure-Command` pour mesurer les performances.

```powershell
It "Analyse un fichier JSON en moins de 100ms" {
    $filePath = Join-Path -Path $testTempDir -ChildPath "test.json"
    '{"name":"Test"}' | Set-Content -Path $filePath -Encoding UTF8
    
    $duration = Measure-Command {
        Get-FileFormatAnalysis -FilePath $filePath
    }
    
    $duration.TotalMilliseconds | Should -BeLessThan 100
}
```

### 2. Tests d'IntÃ©gration

Testez l'interaction entre plusieurs fonctions.

```powershell
Describe "Tests d'intÃ©gration" {
    It "Convertit correctement un fichier JSON en XML" {
        $jsonPath = Join-Path -Path $testTempDir -ChildPath "test.json"
        $xmlPath = Join-Path -Path $testTempDir -ChildPath "test.xml"
        
        '{"name":"Test"}' | Set-Content -Path $jsonPath -Encoding UTF8
        
        # Tester l'intÃ©gration de plusieurs fonctions
        $format = Get-FileFormatAnalysis -FilePath $jsonPath
        $format.Format | Should -Be "JSON"
        
        Convert-FileFormat -SourcePath $jsonPath -TargetPath $xmlPath -TargetFormat "XML"
        Test-Path -Path $xmlPath | Should -BeTrue
        
        $xmlContent = Get-Content -Path $xmlPath -Raw
        $xmlContent | Should -Match "<name>Test</name>"
    }
}
```

### 3. Tests de Couverture

Utilisez l'option `-CodeCoverage` de Pester pour mesurer la couverture de code.

```powershell
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
$results = Invoke-Pester -Path .\development\testing\tests -CodeCoverage $modulePath -PassThru

$results.CodeCoverage.NumberOfCommandsExecuted
$results.CodeCoverage.NumberOfCommandsAnalyzed
$results.CodeCoverage.CoveragePercent
```

### 4. Tests de RÃ©gression

CrÃ©ez des tests spÃ©cifiques pour les bugs corrigÃ©s.

```powershell
Describe "Tests de rÃ©gression" {
    It "Corrige le bug #123 - DÃ©tection incorrecte des fichiers XML vides" {
        $xmlPath = Join-Path -Path $testTempDir -ChildPath "empty.xml"
        "" | Set-Content -Path $xmlPath -Encoding UTF8
        
        $result = Get-FileFormatAnalysis -FilePath $xmlPath
        $result.Format | Should -Be "UNKNOWN"  # Avant le correctif, cela retournait "XML"
    }
}
```

## Conclusion

En suivant ces bonnes pratiques, vous pourrez crÃ©er des tests Pester efficaces, maintenables et robustes pour le module Format-Converters. Des tests bien conÃ§us vous aideront Ã  dÃ©tecter les problÃ¨mes plus tÃ´t, Ã  documenter le comportement attendu du code et Ã  faciliter les modifications futures.
