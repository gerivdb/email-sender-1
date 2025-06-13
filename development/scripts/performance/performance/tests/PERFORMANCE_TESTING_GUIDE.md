# Guide de tests de performance - Test AutoHotkey

Ce guide explique comment crÃ©er et exÃ©cuter des tests de performance pour l'architecture hybride PowerShell-Python. Il fournit des exemples et des bonnes pratiques pour mesurer et comparer les performances des diffÃ©rentes implÃ©mentations.

## Types de tests de performance

### 1. Tests de comparaison

Ces tests comparent les performances de diffÃ©rentes implÃ©mentations d'une mÃªme fonctionnalitÃ©. Ils permettent de mesurer l'amÃ©lioration apportÃ©e par une optimisation.

### 2. Tests de charge

Ces tests mesurent les performances d'une fonction avec diffÃ©rentes tailles de donnÃ©es. Ils permettent de vÃ©rifier la scalabilitÃ© de l'implÃ©mentation.

### 3. Tests de parallÃ©lisme

Ces tests mesurent les performances du traitement parallÃ¨le par rapport au traitement sÃ©quentiel. Ils permettent de vÃ©rifier l'efficacitÃ© de la parallÃ©lisation.

### 4. Tests de ressources

Ces tests mesurent l'utilisation des ressources systÃ¨me (CPU, mÃ©moire) par une fonction. Ils permettent de vÃ©rifier l'efficacitÃ© de l'implÃ©mentation en termes de ressources.

## CrÃ©ation de tests de performance

### Structure d'un test de performance

Un test de performance est structurÃ© comme un test unitaire Pester, mais avec des mesures de performance :

```powershell
Describe "Tests de performance" {
    Context "Ma fonctionnalitÃ©" {
        BeforeAll {
            # Initialisation

            function Measure-Performance {
                param (
                    [scriptblock]$ScriptBlock,
                    [int]$Iterations = 5
                )

                $times = @()

                for ($i = 0; $i -lt $Iterations; $i++) {
                    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
                    & $ScriptBlock
                    $stopwatch.Stop()
                    $times += $stopwatch.Elapsed.TotalMilliseconds
                }

                return ($times | Measure-Object -Average).Average
            }
        }

        It "Mesure les performances de ma fonction" {
            # DÃ©finir la fonction Ã  tester

            $myFunction = {
                # Code Ã  mesurer

            }

            # Mesurer les performances

            $avgTime = Measure-Performance -ScriptBlock $myFunction -Iterations 5

            # Afficher les rÃ©sultats

            Write-Host "Temps moyen : $avgTime ms"

            # VÃ©rifier que les performances sont acceptables

            $avgTime | Should -BeLessThan 100
        }
    }
}
```plaintext
### Mesure prÃ©cise des performances

Pour obtenir des mesures prÃ©cises, suivez ces bonnes pratiques :

1. **PrÃ©chauffage** : ExÃ©cutez la fonction une ou plusieurs fois avant de commencer les mesures pour Ã©viter les biais de dÃ©marrage Ã  froid.

```powershell
# PrÃ©chauffage

& $ScriptBlock
```plaintext
2. **RÃ©pÃ©tition** : ExÃ©cutez la fonction plusieurs fois et calculez la moyenne pour obtenir des rÃ©sultats plus fiables.

```powershell
$times = @()
for ($i = 0; $i -lt $Iterations; $i++) {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    & $ScriptBlock
    $stopwatch.Stop()
    $times += $stopwatch.Elapsed.TotalMilliseconds
}
$avgTime = ($times | Measure-Object -Average).Average
```plaintext
3. **Nettoyage de la mÃ©moire** : Nettoyez la mÃ©moire avant chaque mesure pour Ã©viter les interfÃ©rences.

```powershell
[System.GC]::Collect()
```plaintext
4. **Isolation** : Isolez la fonction Ã  tester des autres fonctions pour mesurer uniquement les performances de la fonction cible.

5. **Environnement stable** : ExÃ©cutez les tests dans un environnement stable pour Ã©viter les interfÃ©rences externes.

### Comparaison de performances

Pour comparer les performances de diffÃ©rentes implÃ©mentations, utilisez la fonction `Compare-Implementations` :

```powershell
function Compare-Implementations {
    param (
        [string]$Name,
        [scriptblock]$Implementation1,
        [scriptblock]$Implementation2,
        [hashtable]$Parameters = @{},
        [int]$Iterations = 5
    )

    # Mesurer les performances de la premiÃ¨re implÃ©mentation

    $result1 = Measure-FunctionPerformance -Name "$Name (ImplÃ©mentation 1)" -ScriptBlock $Implementation1 -Parameters $Parameters -Iterations $Iterations

    # Mesurer les performances de la seconde implÃ©mentation

    $result2 = Measure-FunctionPerformance -Name "$Name (ImplÃ©mentation 2)" -ScriptBlock $Implementation2 -Parameters $Parameters -Iterations $Iterations

    # Calculer l'amÃ©lioration en pourcentage

    $timeImprovement = ($result1.AverageExecutionTimeMs - $result2.AverageExecutionTimeMs) / $result1.AverageExecutionTimeMs * 100

    return [PSCustomObject]@{
        Name = $Name
        Result1 = $result1
        Result2 = $result2
        TimeImprovementPercent = $timeImprovement
    }
}
```plaintext
Exemple d'utilisation :

```powershell
$implementation1 = {
    param($data)
    # ImplÃ©mentation 1

    return $data | Sort-Object -Property Value
}

$implementation2 = {
    param($data)
    # ImplÃ©mentation 2

    return $data | Select-Object Id, Name, Value | Sort-Object -Property Value
}

$comparison = Compare-Implementations -Name "Tri de donnÃ©es" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ data = $testData } -Iterations 5

Write-Host "AmÃ©lioration : $($comparison.TimeImprovementPercent) %"
```plaintext
### Tests de charge

Pour mesurer les performances avec diffÃ©rentes tailles de donnÃ©es, utilisez la fonction `Measure-ScalabilityPerformance` :

```powershell
function Measure-ScalabilityPerformance {
    param (
        [string]$Name,
        [scriptblock]$ScriptBlock,
        [int[]]$DataSizes,
        [int]$Iterations = 3
    )

    $results = @()

    foreach ($size in $DataSizes) {
        # GÃ©nÃ©rer les donnÃ©es de test

        $data = New-LargeDataArray -Size $size

        # Mesurer les performances

        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        for ($i = 1; $i -le $Iterations; $i++) {
            & $ScriptBlock -data $data | Out-Null
        }

        $stopwatch.Stop()
        $executionTime = $stopwatch.Elapsed.TotalMilliseconds / $Iterations

        # Enregistrer les rÃ©sultats

        $results += [PSCustomObject]@{
            Size = $size
            ExecutionTimeMs = $executionTime
            ItemsPerMs = $size / $executionTime
        }
    }

    return $results
}
```plaintext
Exemple d'utilisation :

```powershell
$dataSizes = @(100, 1000, 10000)

$sortFunction = {
    param($data)
    return $data | Sort-Object -Property Value
}

$results = Measure-ScalabilityPerformance -Name "Tri" -ScriptBlock $sortFunction -DataSizes $dataSizes -Iterations 3

foreach ($result in $results) {
    Write-Host "Taille: $($result.Size) Ã©lÃ©ments, Temps: $($result.ExecutionTimeMs) ms, DÃ©bit: $($result.ItemsPerMs) Ã©lÃ©ments/ms"
}
```plaintext
## ExÃ©cution des tests de performance

### ExÃ©cution de tous les tests

Pour exÃ©cuter tous les tests de performance, utilisez le script `Run-AllTests.ps1` :

```powershell
.\Run-AllTests.ps1
```plaintext
### ExÃ©cution d'un test spÃ©cifique

Pour exÃ©cuter un test de performance spÃ©cifique, utilisez Invoke-Pester avec le paramÃ¨tre `-Path` :

```powershell
Invoke-Pester -Path ".\PerformanceBenchmark.Tests.ps1"
```plaintext
### ExÃ©cution avec gÃ©nÃ©ration de rapport

Pour exÃ©cuter les tests de performance et gÃ©nÃ©rer un rapport, utilisez le paramÃ¨tre `-GenerateReport` :

```powershell
.\Run-AllTests.ps1 -GenerateReport $true -OutputPath "C:\TestResults"
```plaintext
## InterprÃ©tation des rÃ©sultats

### Temps d'exÃ©cution

Le temps d'exÃ©cution est la mÃ©trique principale pour mesurer les performances. Plus le temps d'exÃ©cution est court, meilleures sont les performances.

### AmÃ©lioration en pourcentage

L'amÃ©lioration en pourcentage indique l'amÃ©lioration relative des performances entre deux implÃ©mentations. Une valeur positive indique que la seconde implÃ©mentation est plus rapide que la premiÃ¨re.

### DÃ©bit

Le dÃ©bit (Ã©lÃ©ments/ms) indique le nombre d'Ã©lÃ©ments traitÃ©s par milliseconde. Plus le dÃ©bit est Ã©levÃ©, meilleures sont les performances.

### Utilisation des ressources

L'utilisation des ressources (CPU, mÃ©moire) indique l'efficacitÃ© de l'implÃ©mentation en termes de ressources. Une utilisation plus faible des ressources est gÃ©nÃ©ralement prÃ©fÃ©rable.

## Bonnes pratiques pour les tests de performance

1. **RÃ©pÃ©tabilitÃ©** : Les tests de performance doivent Ãªtre rÃ©pÃ©tables pour obtenir des rÃ©sultats fiables.

2. **Isolation** : Isolez les tests de performance des autres tests pour Ã©viter les interfÃ©rences.

3. **PrÃ©cision** : Utilisez des mesures prÃ©cises pour obtenir des rÃ©sultats fiables.

4. **Comparaison** : Comparez les performances de diffÃ©rentes implÃ©mentations pour mesurer l'amÃ©lioration.

5. **ScalabilitÃ©** : Testez les performances avec diffÃ©rentes tailles de donnÃ©es pour vÃ©rifier la scalabilitÃ©.

6. **Documentation** : Documentez les rÃ©sultats des tests de performance pour rÃ©fÃ©rence future.

7. **Automatisation** : Automatisez les tests de performance pour les exÃ©cuter rÃ©guliÃ¨rement.

8. **Seuils** : DÃ©finissez des seuils de performance pour dÃ©tecter les rÃ©gressions.

## Exemples de tests de performance

### Exemple 1 : Comparaison de performances

```powershell
Describe "Tests de performance" {
    Context "Tri de donnÃ©es" {
        BeforeAll {
            # GÃ©nÃ©rer des donnÃ©es de test

            $testData = 1..1000 | ForEach-Object { [PSCustomObject]@{ Value = Get-Random } }

            # DÃ©finir les implÃ©mentations Ã  comparer

            $implementation1 = {
                param($data)
                return $data | Sort-Object -Property Value
            }

            $implementation2 = {
                param($data)
                return $data | Select-Object Value | Sort-Object -Property Value
            }
        }

        It "Compare les performances du tri" {
            # Comparer les implÃ©mentations

            $comparison = Compare-Implementations -Name "Tri" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ data = $testData } -Iterations 5

            # Afficher les rÃ©sultats

            Write-Host "Temps moyen (ImplÃ©mentation 1): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (ImplÃ©mentation 2): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "AmÃ©lioration: $($comparison.TimeImprovementPercent) %"

            # VÃ©rifier que l'implÃ©mentation 2 est plus rapide

            $comparison.TimeImprovementPercent | Should -BeGreaterThan 0
        }
    }
}
```plaintext
### Exemple 2 : Test de charge

```powershell
Describe "Tests de performance" {
    Context "ScalabilitÃ© du tri" {
        BeforeAll {
            # DÃ©finir les tailles de donnÃ©es Ã  tester

            $dataSizes = @(100, 1000, 10000)

            # DÃ©finir la fonction Ã  tester

            $sortFunction = {
                param($data)
                return $data | Sort-Object -Property Value
            }
        }

        It "Mesure la scalabilitÃ© du tri" {
            # Mesurer les performances avec diffÃ©rentes tailles de donnÃ©es

            $results = Measure-ScalabilityPerformance -Name "Tri" -ScriptBlock $sortFunction -DataSizes $dataSizes -Iterations 3

            # Afficher les rÃ©sultats

            foreach ($result in $results) {
                Write-Host "Taille: $($result.Size) Ã©lÃ©ments, Temps: $($result.ExecutionTimeMs) ms, DÃ©bit: $($result.ItemsPerMs) Ã©lÃ©ments/ms"
            }

            # VÃ©rifier que le dÃ©bit diminue avec l'augmentation de la taille des donnÃ©es

            $smallSizeItemsPerMs = $results[0].ItemsPerMs
            $largeSizeItemsPerMs = $results[-1].ItemsPerMs

            $largeSizeItemsPerMs | Should -BeLessThan $smallSizeItemsPerMs
        }
    }
}
```plaintext
### Exemple 3 : Test de parallÃ©lisme

```powershell
Describe "Tests de performance" {
    Context "Traitement parallÃ¨le" {
        BeforeAll {
            # GÃ©nÃ©rer des donnÃ©es de test

            $testFiles = New-TestFiles -OutputPath $testRootDir -FileCount 20

            # DÃ©finir les implÃ©mentations Ã  comparer

            $sequentialImplementation = {
                param($files)
                $results = @()
                foreach ($file in $files) {
                    $content = Get-Content -Path $file -Raw
                    $size = (Get-Item -Path $file).Length
                    $results += [PSCustomObject]@{
                        File = $file
                        Size = $size
                        Lines = ($content -split "`n").Count
                    }
                }
                return $results
            }

            $parallelImplementation = {
                param($files)
                $results = $files | ForEach-Object -Parallel {
                    $file = $_
                    $content = Get-Content -Path $file -Raw
                    $size = (Get-Item -Path $file).Length
                    [PSCustomObject]@{
                        File = $file
                        Size = $size
                        Lines = ($content -split "`n").Count
                    }
                } -ThrottleLimit 5
                return $results
            }
        }

        It "Compare les performances du traitement sÃ©quentiel et parallÃ¨le" -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
            # Comparer les implÃ©mentations

            $comparison = Compare-Implementations -Name "Traitement de fichiers" -Implementation1 $sequentialImplementation -Implementation2 $parallelImplementation -Parameters @{ files = $testFiles } -Iterations 3

            # Afficher les rÃ©sultats

            Write-Host "Temps moyen (SÃ©quentiel): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (ParallÃ¨le): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "AmÃ©lioration: $($comparison.TimeImprovementPercent) %"

            # VÃ©rifier que le traitement parallÃ¨le est plus rapide

            $comparison.TimeImprovementPercent | Should -BeGreaterThan 10
        }
    }
}
```plaintext
## Conclusion

Les tests de performance sont essentiels pour mesurer et amÃ©liorer les performances des scripts. En suivant les bonnes pratiques et en utilisant les outils appropriÃ©s, vous pouvez crÃ©er des tests de performance fiables et prÃ©cis qui vous aideront Ã  optimiser vos scripts.
