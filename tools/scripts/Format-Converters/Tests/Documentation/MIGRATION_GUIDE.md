# Guide de Migration des Tests Simplifiés vers les Tests Réels

Ce guide explique comment migrer des tests simplifiés vers des tests réels pour le module Format-Converters.

## Pourquoi Migrer ?

La migration des tests simplifiés vers des tests réels présente plusieurs avantages :

1. **Meilleure couverture de code** : Les tests réels couvrent plus de cas de test et de scénarios.
2. **Tests plus robustes** : Les tests réels sont plus résistants aux changements dans le code.
3. **Intégration continue** : Les tests réels sont plus adaptés à l'intégration continue.
4. **Documentation du code** : Les tests réels documentent mieux le comportement attendu du code.

## Processus de Migration

### Étape 1 : Utiliser le Script de Conversion

Le script `Convert-SimplifiedTest.ps1` automatise la conversion des tests simplifiés en tests réels :

```powershell
.\Convert-SimplifiedTest.ps1 -SimplifiedTestPath "MonTest.Simplified.ps1" -RealTestPath "MonTest.Tests.ps1"
```

Ce script :
- Lit le contenu du fichier de test simplifié
- Ajoute l'importation explicite du module
- Convertit les variables globales en variables locales
- Ajoute des blocs `BeforeAll` et `AfterAll` appropriés
- Enregistre le résultat dans le fichier de test réel

### Étape 2 : Vérifier les Tests Convertis

Après la conversion, vérifiez que les tests fonctionnent correctement :

```powershell
Invoke-Pester -Path .\MonTest.Tests.ps1 -Output Detailed
```

### Étape 3 : Ajouter des Tests Supplémentaires

Les tests réels devraient couvrir plus de cas de test que les tests simplifiés. Ajoutez des tests pour :

1. **Cas limites** : Valeurs nulles, vides, très grandes, très petites, etc.
2. **Cas d'erreur** : Entrées invalides, fichiers inexistants, etc.
3. **Cas spéciaux** : Formats de fichier ambigus, encodages différents, etc.

Exemple d'ajout de tests pour les cas limites :

```powershell
It "Gère correctement les fichiers vides" {
    $emptyFilePath = Join-Path -Path $testTempDir -ChildPath "empty.json"
    "" | Set-Content -Path $emptyFilePath -Encoding UTF8
    
    $result = Get-FileFormatAnalysis -FilePath $emptyFilePath -Format "json"
    $result | Should -Not -BeNullOrEmpty
    $result.Size | Should -Be 0
}
```

### Étape 4 : Améliorer la Documentation

Ajoutez des commentaires pour expliquer le but de chaque test et les comportements attendus :

```powershell
# Ce test vérifie que la fonction détecte correctement le format JSON
# même lorsque le fichier contient des caractères spéciaux
It "Détecte correctement le format JSON avec des caractères spéciaux" {
    $specialJsonPath = Join-Path -Path $testTempDir -ChildPath "special.json"
    '{"name":"Tést","version":"1.0.0"}' | Set-Content -Path $specialJsonPath -Encoding UTF8
    
    $result = Get-FileFormatAnalysis -FilePath $specialJsonPath
    $result.Format | Should -Be "JSON"
}
```

### Étape 5 : Optimiser les Tests

Optimisez les tests pour qu'ils s'exécutent plus rapidement et utilisent moins de ressources :

1. **Regroupez les tests similaires** dans le même contexte
2. **Réutilisez les fichiers de test** au lieu d'en créer de nouveaux pour chaque test
3. **Utilisez des mocks** pour éviter les opérations coûteuses

Exemple d'optimisation :

```powershell
Context "Analyse de différents formats de fichier" {
    # Créer tous les fichiers de test une seule fois
    BeforeAll {
        $formats = @{
            "json" = '{"name":"Test"}'
            "xml" = '<root><name>Test</name></root>'
            "html" = '<html><body>Test</body></html>'
            "csv" = 'Name,Value\nTest,1'
        }
        
        $testFiles = @{}
        foreach ($format in $formats.Keys) {
            $filePath = Join-Path -Path $testTempDir -ChildPath "test.$format"
            $formats[$format] | Set-Content -Path $filePath -Encoding UTF8
            $testFiles[$format] = $filePath
        }
    }
    
    # Tester chaque format
    It "Analyse correctement un fichier <format>" -TestCases @(
        @{ Format = "json"; ExpectedFormat = "JSON" }
        @{ Format = "xml"; ExpectedFormat = "XML" }
        @{ Format = "html"; ExpectedFormat = "HTML" }
        @{ Format = "csv"; ExpectedFormat = "CSV" }
    ) {
        param($Format, $ExpectedFormat)
        
        $filePath = $testFiles[$Format]
        $result = Get-FileFormatAnalysis -FilePath $filePath
        $result.Format | Should -Be $ExpectedFormat
    }
}
```

## Bonnes Pratiques pour les Tests Réels

### 1. Structure des Tests

Organisez vos tests selon la structure suivante :

```powershell
Describe "Nom de la fonction" {
    Context "Scénario spécifique" {
        It "Comportement attendu" {
            # Test
        }
    }
}
```

### 2. Nommage des Tests

Utilisez des noms descriptifs pour vos tests :

- **Describe** : Nom de la fonction ou du module testé
- **Context** : Scénario ou condition spécifique
- **It** : Comportement attendu, commençant par un verbe

### 3. Assertions

Utilisez les assertions Pester appropriées :

- `Should -Be` : Égalité stricte
- `Should -BeExactly` : Égalité stricte sensible à la casse
- `Should -Match` : Correspondance avec une expression régulière
- `Should -Contain` : Vérifier qu'une collection contient un élément
- `Should -Throw` : Vérifier qu'une expression lève une exception

### 4. Isolation des Tests

Assurez-vous que chaque test est isolé et ne dépend pas des autres tests :

- Créez des fichiers temporaires uniques pour chaque test
- Nettoyez les ressources après chaque test
- Évitez les variables globales

### 5. Tests Paramétrés

Utilisez des tests paramétrés pour tester plusieurs cas similaires :

```powershell
It "Détecte correctement le format <format>" -TestCases @(
    @{ Format = "json"; Content = '{"name":"Test"}'; ExpectedFormat = "JSON" }
    @{ Format = "xml"; Content = '<root><name>Test</name></root>'; ExpectedFormat = "XML" }
) {
    param($Format, $Content, $ExpectedFormat)
    
    $filePath = Join-Path -Path $testTempDir -ChildPath "test.$Format"
    $Content | Set-Content -Path $filePath -Encoding UTF8
    
    $result = Get-FileFormatAnalysis -FilePath $filePath
    $result.Format | Should -Be $ExpectedFormat
}
```

## Résolution des Problèmes Courants

### 1. Variables non définies

**Problème** : Les variables définies dans `BeforeAll` ne sont pas accessibles dans les tests.

**Solution** : Assurez-vous que les variables sont définies au bon niveau de portée :

```powershell
BeforeAll {
    # Variables accessibles dans tous les tests de ce Describe
    $script:testFiles = @{}
}

Context "Premier contexte" {
    BeforeAll {
        # Variables accessibles uniquement dans ce Context
        $contextVar = "Valeur"
    }
    
    It "Test" {
        # Accès aux variables
        $script:testFiles | Should -Not -BeNullOrEmpty
        $contextVar | Should -Be "Valeur"
    }
}
```

### 2. Importation du Module

**Problème** : Le module n'est pas correctement importé.

**Solution** : Importez le module de manière explicite au début du fichier et dans le bloc `BeforeAll` :

```powershell
# Importer le module
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module -Name $modulePath -Force
}

BeforeAll {
    # S'assurer que le module est importé
    if (-not (Get-Module -Name Format-Converters)) {
        $modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
        if (Test-Path -Path $modulePath) {
            Import-Module -Name $modulePath -Force
        }
    }
}
```

### 3. Nettoyage Incomplet

**Problème** : Les fichiers temporaires ne sont pas correctement nettoyés.

**Solution** : Utilisez `AfterAll` et `AfterEach` pour nettoyer les ressources :

```powershell
BeforeAll {
    $testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConvertersTests_$(Get-Random)"
    New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null
}

AfterEach {
    # Nettoyer les ressources après chaque test
    Get-ChildItem -Path $testTempDir -File | Remove-Item -Force
}

AfterAll {
    # Nettoyer le répertoire temporaire à la fin
    if (Test-Path -Path $testTempDir) {
        Remove-Item -Path $testTempDir -Recurse -Force
    }
}
```

## Conclusion

La migration des tests simplifiés vers des tests réels est une étape importante pour améliorer la qualité et la robustesse de votre code. En suivant ce guide, vous pourrez convertir vos tests existants et créer de nouveaux tests qui couvrent plus de cas et de scénarios.
