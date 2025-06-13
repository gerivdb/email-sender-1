# Documentation des Tests Format-Converters

Ce document explique les diffÃ©rences entre les tests simplifiÃ©s et les tests rÃ©els du module Format-Converters, ainsi que les bonnes pratiques pour les utiliser.

## Structure des Tests

Le rÃ©pertoire de tests contient deux types de fichiers de test :

1. **Tests SimplifiÃ©s** : Fichiers avec le suffixe `.Simplified.ps1`
   - Tests plus simples et plus faciles Ã  comprendre
   - UtilisÃ©s pour le dÃ©veloppement rapide et les tests initiaux
   - Contiennent moins de tests mais couvrent les fonctionnalitÃ©s essentielles

2. **Tests RÃ©els** : Fichiers avec le suffixe `.Tests.ps1`
   - Tests plus complets et plus robustes
   - UtilisÃ©s pour les tests de rÃ©gression et l'intÃ©gration continue
   - Contiennent plus de tests et couvrent plus de cas de test

## DiffÃ©rences Principales

| Aspect | Tests SimplifiÃ©s | Tests RÃ©els |
|--------|-----------------|-------------|
| Nombre de tests | 72 | 81 |
| ComplexitÃ© | Faible | Moyenne |
| Temps d'exÃ©cution | Plus rapide | Plus lent |
| Couverture de code | Partielle | ComplÃ¨te |
| Importation du module | Implicite | Explicite |
| Variables | Globales | Locales dans BeforeAll |
| Nettoyage | Simple | Complet |

## Bonnes Pratiques

### Quand utiliser les tests simplifiÃ©s

- Pendant le dÃ©veloppement initial d'une fonctionnalitÃ©
- Pour des tests rapides de validation
- Pour comprendre rapidement le comportement d'une fonction

### Quand utiliser les tests rÃ©els

- Pour les tests de rÃ©gression
- Pour l'intÃ©gration continue
- Pour s'assurer que toutes les fonctionnalitÃ©s sont correctement testÃ©es

### Conversion des tests simplifiÃ©s en tests rÃ©els

Pour convertir un test simplifiÃ© en test rÃ©el, utilisez le script `Convert-SimplifiedTest.ps1` :

```powershell
.\Convert-SimplifiedTest.ps1 -SimplifiedTestPath "MonTest.Simplified.ps1" -RealTestPath "MonTest.Tests.ps1"
```plaintext
### ExÃ©cution des tests

Pour exÃ©cuter les tests, utilisez le script `Bridge-Tests.ps1` :

```powershell
# ExÃ©cuter uniquement les tests simplifiÃ©s

.\Bridge-Tests.ps1 -Mode Simplified

# ExÃ©cuter uniquement les tests rÃ©els

.\Bridge-Tests.ps1 -Mode Real

# ExÃ©cuter les deux types de tests et comparer les rÃ©sultats

.\Bridge-Tests.ps1 -Mode Compare

# ExÃ©cuter tous les tests sans comparaison

.\Bridge-Tests.ps1 -Mode All
```plaintext
## Structure d'un Test

### Structure d'un Test SimplifiÃ©

```powershell
# CrÃ©er un rÃ©pertoire temporaire pour les tests

$global:testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConvertersTests_$(Get-Random)"
New-Item -Path $global:testTempDir -ItemType Directory -Force | Out-Null

# CrÃ©er des fichiers de test

$global:jsonFilePath = Join-Path -Path $global:testTempDir -ChildPath "test.json"
$global:jsonContent = '{"name":"Test","version":"1.0.0"}'
$global:jsonContent | Set-Content -Path $global:jsonFilePath -Encoding UTF8

# Tests

Describe "Fonction Get-FileFormatAnalysis" {
    Context "Analyse de fichiers avec format dÃ©tectÃ©" {
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
```plaintext
### Structure d'un Test RÃ©el

```powershell
# Importer le module

$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module -Name $modulePath -Force
}

BeforeAll {
    # S'assurer que le module est importÃ©

    if (-not (Get-Module -Name Format-Converters)) {
        $modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "Format-Converters.psm1"
        if (Test-Path -Path $modulePath) {
            Import-Module -Name $modulePath -Force
        }
    }
    
    # CrÃ©er un rÃ©pertoire temporaire pour les tests

    $testTempDir = Join-Path -Path $env:TEMP -ChildPath "FormatConvertersTests_$(Get-Random)"
    New-Item -Path $testTempDir -ItemType Directory -Force | Out-Null
    
    # CrÃ©er des fichiers de test

    $jsonFilePath = Join-Path -Path $testTempDir -ChildPath "test.json"
    $jsonContent = '{"name":"Test","version":"1.0.0"}'
    $jsonContent | Set-Content -Path $jsonFilePath -Encoding UTF8
}

# Tests

Describe "Fonction Get-FileFormatAnalysis" {
    Context "Analyse de fichiers avec format dÃ©tectÃ©" {
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
```plaintext
## DÃ©pannage

### ProblÃ¨mes courants

1. **Le module n'est pas importÃ© correctement**
   - VÃ©rifiez que le chemin du module est correct
   - Assurez-vous que le module est importÃ© avec l'option `-Force`

2. **Les variables ne sont pas accessibles**
   - Dans les tests simplifiÃ©s, utilisez des variables globales (`$global:maVariable`)
   - Dans les tests rÃ©els, utilisez des variables locales dÃ©finies dans le bloc `BeforeAll`

3. **Les fichiers temporaires ne sont pas nettoyÃ©s**
   - Assurez-vous que le bloc `AfterAll` est correctement dÃ©fini
   - VÃ©rifiez que le rÃ©pertoire temporaire est supprimÃ© avec l'option `-Recurse -Force`

### Comment obtenir de l'aide

Si vous rencontrez des problÃ¨mes avec les tests, vous pouvez :

1. Consulter cette documentation
2. ExÃ©cuter les tests en mode verbose : `Invoke-Pester -Path .\MonTest.Tests.ps1 -Verbose`
3. Utiliser le script `Bridge-Tests.ps1` en mode Compare pour identifier les diffÃ©rences entre les tests simplifiÃ©s et les tests rÃ©els
