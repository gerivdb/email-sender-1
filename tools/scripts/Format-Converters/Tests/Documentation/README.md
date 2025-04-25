# Documentation des Tests Format-Converters

Ce document explique les différences entre les tests simplifiés et les tests réels du module Format-Converters, ainsi que les bonnes pratiques pour les utiliser.

## Structure des Tests

Le répertoire de tests contient deux types de fichiers de test :

1. **Tests Simplifiés** : Fichiers avec le suffixe `.Simplified.ps1`
   - Tests plus simples et plus faciles à comprendre
   - Utilisés pour le développement rapide et les tests initiaux
   - Contiennent moins de tests mais couvrent les fonctionnalités essentielles

2. **Tests Réels** : Fichiers avec le suffixe `.Tests.ps1`
   - Tests plus complets et plus robustes
   - Utilisés pour les tests de régression et l'intégration continue
   - Contiennent plus de tests et couvrent plus de cas de test

## Différences Principales

| Aspect | Tests Simplifiés | Tests Réels |
|--------|-----------------|-------------|
| Nombre de tests | 72 | 81 |
| Complexité | Faible | Moyenne |
| Temps d'exécution | Plus rapide | Plus lent |
| Couverture de code | Partielle | Complète |
| Importation du module | Implicite | Explicite |
| Variables | Globales | Locales dans BeforeAll |
| Nettoyage | Simple | Complet |

## Bonnes Pratiques

### Quand utiliser les tests simplifiés

- Pendant le développement initial d'une fonctionnalité
- Pour des tests rapides de validation
- Pour comprendre rapidement le comportement d'une fonction

### Quand utiliser les tests réels

- Pour les tests de régression
- Pour l'intégration continue
- Pour s'assurer que toutes les fonctionnalités sont correctement testées

### Conversion des tests simplifiés en tests réels

Pour convertir un test simplifié en test réel, utilisez le script `Convert-SimplifiedTest.ps1` :

```powershell
.\Convert-SimplifiedTest.ps1 -SimplifiedTestPath "MonTest.Simplified.ps1" -RealTestPath "MonTest.Tests.ps1"
```

### Exécution des tests

Pour exécuter les tests, utilisez le script `Bridge-Tests.ps1` :

```powershell
# Exécuter uniquement les tests simplifiés
.\Bridge-Tests.ps1 -Mode Simplified

# Exécuter uniquement les tests réels
.\Bridge-Tests.ps1 -Mode Real

# Exécuter les deux types de tests et comparer les résultats
.\Bridge-Tests.ps1 -Mode Compare

# Exécuter tous les tests sans comparaison
.\Bridge-Tests.ps1 -Mode All
```

## Structure d'un Test

### Structure d'un Test Simplifié

```powershell
# Créer un répertoire temporaire pour les tests
$global:testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConvertersTests_$(Get-Random)"
New-Item -Path $global:testTempDir -ItemType Directory -Force | Out-Null

# Créer des fichiers de test
$global:jsonFilePath = Join-Path -Path $global:testTempDir -ChildPath "test.json"
$global:jsonContent = '{"name":"Test","version":"1.0.0"}'
$global:jsonContent | Set-Content -Path $global:jsonFilePath -Encoding UTF8

# Tests
Describe "Fonction Get-FileFormatAnalysis" {
    Context "Analyse de fichiers avec format détecté" {
        It "Analyse correctement un fichier JSON" {
            $result = Get-FileFormatAnalysis -FilePath $global:jsonFilePath -Format "json"
            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $global:jsonFilePath
            $result.Format | Should -Be "JSON"
        }
    }
}

# Nettoyer les fichiers de test
AfterAll {
    if (Test-Path -Path $global:testTempDir) {
        Remove-Item -Path $global:testTempDir -Recurse -Force
    }
}
```

### Structure d'un Test Réel

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
    
    # Créer un répertoire temporaire pour les tests
    $testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConvertersTests_$(Get-Random)"
    New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null
    
    # Créer des fichiers de test
    $jsonFilePath = Join-Path -Path $testTempDir -ChildPath "test.json"
    $jsonContent = '{"name":"Test","version":"1.0.0"}'
    $jsonContent | Set-Content -Path $jsonFilePath -Encoding UTF8
}

# Tests
Describe "Fonction Get-FileFormatAnalysis" {
    Context "Analyse de fichiers avec format détecté" {
        It "Analyse correctement un fichier JSON" {
            $result = Get-FileFormatAnalysis -FilePath $jsonFilePath -Format "json"
            $result | Should -Not -BeNullOrEmpty
            $result.FilePath | Should -Be $jsonFilePath
            $result.Format | Should -Be "JSON"
        }
    }
}

# Nettoyer les fichiers de test
AfterAll {
    if (Test-Path -Path $testTempDir) {
        Remove-Item -Path $testTempDir -Recurse -Force
    }
}
```

## Dépannage

### Problèmes courants

1. **Le module n'est pas importé correctement**
   - Vérifiez que le chemin du module est correct
   - Assurez-vous que le module est importé avec l'option `-Force`

2. **Les variables ne sont pas accessibles**
   - Dans les tests simplifiés, utilisez des variables globales (`$global:maVariable`)
   - Dans les tests réels, utilisez des variables locales définies dans le bloc `BeforeAll`

3. **Les fichiers temporaires ne sont pas nettoyés**
   - Assurez-vous que le bloc `AfterAll` est correctement défini
   - Vérifiez que le répertoire temporaire est supprimé avec l'option `-Recurse -Force`

### Comment obtenir de l'aide

Si vous rencontrez des problèmes avec les tests, vous pouvez :

1. Consulter cette documentation
2. Exécuter les tests en mode verbose : `Invoke-Pester -Path .\MonTest.Tests.ps1 -Verbose`
3. Utiliser le script `Bridge-Tests.ps1` en mode Compare pour identifier les différences entre les tests simplifiés et les tests réels
