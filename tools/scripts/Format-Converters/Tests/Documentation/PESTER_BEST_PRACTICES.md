# Bonnes Pratiques pour les Tests Pester

Ce guide présente les bonnes pratiques pour écrire des tests Pester efficaces et maintenables pour le module Format-Converters.

## Principes Fondamentaux

### 1. Tests Indépendants

Chaque test doit être indépendant des autres tests. Un test ne doit pas dépendre de l'état laissé par un autre test.

```powershell
# Mauvaise pratique
Describe "Tests dépendants" {
    It "Premier test" {
        $global:result = Get-FileFormatAnalysis -FilePath "test.json"
        $global:result | Should -Not -BeNullOrEmpty
    }
    
    It "Deuxième test" {
        # Dépend du premier test
        $global:result.Format | Should -Be "JSON"
    }
}

# Bonne pratique
Describe "Tests indépendants" {
    It "Premier test" {
        $result = Get-FileFormatAnalysis -FilePath "test.json"
        $result | Should -Not -BeNullOrEmpty
    }
    
    It "Deuxième test" {
        $result = Get-FileFormatAnalysis -FilePath "test.json"
        $result.Format | Should -Be "JSON"
    }
}
```

### 2. Un Seul Concept par Test

Chaque test doit vérifier un seul concept ou comportement.

```powershell
# Mauvaise pratique
It "Analyse un fichier JSON et vérifie plusieurs propriétés" {
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
    
    It "Retourne un résultat non vide" {
        $result | Should -Not -BeNullOrEmpty
    }
    
    It "Retourne le bon chemin de fichier" {
        $result.FilePath | Should -Be "test.json"
    }
    
    It "Détecte correctement le format JSON" {
        $result.Format | Should -Be "JSON"
    }
    
    It "Retourne une taille de fichier valide" {
        $result.Size | Should -BeGreaterThan 0
    }
    
    It "Inclut les propriétés du fichier" {
        $result.Properties | Should -Not -BeNullOrEmpty
    }
}
```

### 3. Nommage Descriptif

Utilisez des noms descriptifs pour vos tests qui expliquent clairement ce qui est testé.

```powershell
# Mauvaise pratique
It "Test 1" {
    # ...
}

# Bonne pratique
It "Détecte correctement le format JSON d'un fichier valide" {
    # ...
}
```

### 4. Organisation Hiérarchique

Organisez vos tests de manière hiérarchique avec `Describe`, `Context` et `It`.

```powershell
Describe "Fonction Get-FileFormatAnalysis" {
    Context "Analyse de fichiers avec format spécifié" {
        It "Analyse correctement un fichier JSON" {
            # ...
        }
        
        It "Analyse correctement un fichier XML" {
            # ...
        }
    }
    
    Context "Analyse de fichiers avec détection automatique" {
        It "Détecte et analyse correctement un fichier JSON" {
            # ...
        }
        
        It "Détecte et analyse correctement un fichier XML" {
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
        # Exécuté une fois avant tous les tests
        $script:testTempDir = Join-Path -Path $env:TEMP -ChildPath "TestDir_$(Get-Random)"
        New-Item -Path $script:testTempDir -ItemType Directory -Force | Out-Null
    }
    
    BeforeEach {
        # Exécuté avant chaque test
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
        # Exécuté après chaque test
        Get-ChildItem -Path $script:testTempDir -File | Remove-Item -Force
    }
    
    AfterAll {
        # Exécuté une fois après tous les tests
        if (Test-Path -Path $script:testTempDir) {
            Remove-Item -Path $script:testTempDir -Recurse -Force
        }
    }
}
```

### 2. Tests Paramétrés

Utilisez des tests paramétrés pour tester plusieurs cas similaires.

```powershell
It "Détecte correctement le format <format>" -TestCases @(
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

Utilisez des mocks pour isoler le code testé et simuler des comportements spécifiques.

```powershell
Describe "Tests avec mocks" {
    It "Gère correctement les erreurs de lecture de fichier" {
        # Mocker la fonction Get-Content pour qu'elle lève une exception
        Mock Get-Content { throw "Erreur de lecture" }
        
        # Vérifier que la fonction gère correctement l'erreur
        { Get-FileFormatAnalysis -FilePath "test.json" } | Should -Throw "Impossible de lire le fichier"
    }
}
```

## Assertions

### 1. Assertions de Base

Utilisez les assertions de base pour vérifier les valeurs et les comportements.

```powershell
# Égalité
$result.Format | Should -Be "JSON"

# Égalité sensible à la casse
$result.Format | Should -BeExactly "JSON"

# Vérifier qu'une valeur est vraie
$result.IsValid | Should -BeTrue

# Vérifier qu'une valeur est fausse
$result.HasErrors | Should -BeFalse

# Vérifier qu'une valeur est nulle
$result.Errors | Should -BeNullOrEmpty

# Vérifier qu'une valeur n'est pas nulle
$result.Properties | Should -Not -BeNullOrEmpty
```

### 2. Assertions de Collection

Utilisez les assertions de collection pour vérifier les tableaux et les listes.

```powershell
# Vérifier qu'une collection contient un élément
$result.SupportedFormats | Should -Contain "JSON"

# Vérifier qu'une collection ne contient pas un élément
$result.SupportedFormats | Should -Not -Contain "INVALID"

# Vérifier qu'une collection est vide
$result.Errors | Should -BeNullOrEmpty

# Vérifier qu'une collection a un nombre spécifique d'éléments
$result.Properties.Count | Should -Be 3
```

### 3. Assertions d'Exception

Utilisez les assertions d'exception pour vérifier que le code lève des exceptions.

```powershell
# Vérifier qu'une expression lève une exception
{ Get-FileFormatAnalysis -FilePath "nonexistent.json" } | Should -Throw

# Vérifier qu'une expression lève une exception spécifique
{ Get-FileFormatAnalysis -FilePath "nonexistent.json" } | Should -Throw "Le fichier n'existe pas"

# Vérifier qu'une expression ne lève pas d'exception
{ Get-FileFormatAnalysis -FilePath "test.json" } | Should -Not -Throw
```

### 4. Assertions de Type

Utilisez les assertions de type pour vérifier le type des objets.

```powershell
# Vérifier le type d'un objet
$result | Should -BeOfType [PSCustomObject]

# Vérifier qu'un objet a une propriété
$result | Should -Have-Property "Format"

# Vérifier qu'un objet a une méthode
$result | Should -Have-Method "ToString"
```

## Bonnes Pratiques Avancées

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

### 2. Tests d'Intégration

Testez l'interaction entre plusieurs fonctions.

```powershell
Describe "Tests d'intégration" {
    It "Convertit correctement un fichier JSON en XML" {
        $jsonPath = Join-Path -Path $testTempDir -ChildPath "test.json"
        $xmlPath = Join-Path -Path $testTempDir -ChildPath "test.xml"
        
        '{"name":"Test"}' | Set-Content -Path $jsonPath -Encoding UTF8
        
        # Tester l'intégration de plusieurs fonctions
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
$results = Invoke-Pester -Path .\Tests -CodeCoverage $modulePath -PassThru

$results.CodeCoverage.NumberOfCommandsExecuted
$results.CodeCoverage.NumberOfCommandsAnalyzed
$results.CodeCoverage.CoveragePercent
```

### 4. Tests de Régression

Créez des tests spécifiques pour les bugs corrigés.

```powershell
Describe "Tests de régression" {
    It "Corrige le bug #123 - Détection incorrecte des fichiers XML vides" {
        $xmlPath = Join-Path -Path $testTempDir -ChildPath "empty.xml"
        "" | Set-Content -Path $xmlPath -Encoding UTF8
        
        $result = Get-FileFormatAnalysis -FilePath $xmlPath
        $result.Format | Should -Be "UNKNOWN"  # Avant le correctif, cela retournait "XML"
    }
}
```

## Conclusion

En suivant ces bonnes pratiques, vous pourrez créer des tests Pester efficaces, maintenables et robustes pour le module Format-Converters. Des tests bien conçus vous aideront à détecter les problèmes plus tôt, à documenter le comportement attendu du code et à faciliter les modifications futures.
