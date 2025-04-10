# Guide de tests de performance

Ce guide explique comment créer et exécuter des tests de performance pour l'architecture hybride PowerShell-Python. Il fournit des exemples et des bonnes pratiques pour mesurer et comparer les performances des différentes implémentations.

## Types de tests de performance

### 1. Tests de comparaison

Ces tests comparent les performances de différentes implémentations d'une même fonctionnalité. Ils permettent de mesurer l'amélioration apportée par une optimisation.

### 2. Tests de charge

Ces tests mesurent les performances d'une fonction avec différentes tailles de données. Ils permettent de vérifier la scalabilité de l'implémentation.

### 3. Tests de parallélisme

Ces tests mesurent les performances du traitement parallèle par rapport au traitement séquentiel. Ils permettent de vérifier l'efficacité de la parallélisation.

### 4. Tests de ressources

Ces tests mesurent l'utilisation des ressources système (CPU, mémoire) par une fonction. Ils permettent de vérifier l'efficacité de l'implémentation en termes de ressources.

## Création de tests de performance

### Structure d'un test de performance

Un test de performance est structuré comme un test unitaire Pester, mais avec des mesures de performance :

```powershell
Describe "Tests de performance" {
    Context "Ma fonctionnalité" {
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
            # Définir la fonction à tester
            $myFunction = {
                # Code à mesurer
            }
            
            # Mesurer les performances
            $avgTime = Measure-Performance -ScriptBlock $myFunction -Iterations 5
            
            # Afficher les résultats
            Write-Host "Temps moyen : $avgTime ms"
            
            # Vérifier que les performances sont acceptables
            $avgTime | Should -BeLessThan 100
        }
    }
}
```

### Mesure précise des performances

Pour obtenir des mesures précises, suivez ces bonnes pratiques :

1. **Préchauffage** : Exécutez la fonction une ou plusieurs fois avant de commencer les mesures pour éviter les biais de démarrage à froid.

```powershell
# Préchauffage
& $ScriptBlock
```

2. **Répétition** : Exécutez la fonction plusieurs fois et calculez la moyenne pour obtenir des résultats plus fiables.

```powershell
$times = @()
for ($i = 0; $i -lt $Iterations; $i++) {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    & $ScriptBlock
    $stopwatch.Stop()
    $times += $stopwatch.Elapsed.TotalMilliseconds
}
$avgTime = ($times | Measure-Object -Average).Average
```

3. **Nettoyage de la mémoire** : Nettoyez la mémoire avant chaque mesure pour éviter les interférences.

```powershell
[System.GC]::Collect()
```

4. **Isolation** : Isolez la fonction à tester des autres fonctions pour mesurer uniquement les performances de la fonction cible.

5. **Environnement stable** : Exécutez les tests dans un environnement stable pour éviter les interférences externes.

### Comparaison de performances

Pour comparer les performances de différentes implémentations, utilisez la fonction `Compare-Implementations` :

```powershell
function Compare-Implementations {
    param (
        [string]$Name,
        [scriptblock]$Implementation1,
        [scriptblock]$Implementation2,
        [hashtable]$Parameters = @{},
        [int]$Iterations = 5
    )
    
    # Mesurer les performances de la première implémentation
    $result1 = Measure-FunctionPerformance -Name "$Name (Implémentation 1)" -ScriptBlock $Implementation1 -Parameters $Parameters -Iterations $Iterations
    
    # Mesurer les performances de la seconde implémentation
    $result2 = Measure-FunctionPerformance -Name "$Name (Implémentation 2)" -ScriptBlock $Implementation2 -Parameters $Parameters -Iterations $Iterations
    
    # Calculer l'amélioration en pourcentage
    $timeImprovement = ($result1.AverageExecutionTimeMs - $result2.AverageExecutionTimeMs) / $result1.AverageExecutionTimeMs * 100
    
    return [PSCustomObject]@{
        Name = $Name
        Result1 = $result1
        Result2 = $result2
        TimeImprovementPercent = $timeImprovement
    }
}
```

Exemple d'utilisation :

```powershell
$implementation1 = {
    param($data)
    # Implémentation 1
    return $data | Sort-Object -Property Value
}

$implementation2 = {
    param($data)
    # Implémentation 2
    return $data | Select-Object Id, Name, Value | Sort-Object -Property Value
}

$comparison = Compare-Implementations -Name "Tri de données" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ data = $testData } -Iterations 5

Write-Host "Amélioration : $($comparison.TimeImprovementPercent) %"
```

### Tests de charge

Pour mesurer les performances avec différentes tailles de données, utilisez la fonction `Measure-ScalabilityPerformance` :

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
        # Générer les données de test
        $data = New-LargeDataArray -Size $size
        
        # Mesurer les performances
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        for ($i = 1; $i -le $Iterations; $i++) {
            & $ScriptBlock -data $data | Out-Null
        }
        
        $stopwatch.Stop()
        $executionTime = $stopwatch.Elapsed.TotalMilliseconds / $Iterations
        
        # Enregistrer les résultats
        $results += [PSCustomObject]@{
            Size = $size
            ExecutionTimeMs = $executionTime
            ItemsPerMs = $size / $executionTime
        }
    }
    
    return $results
}
```

Exemple d'utilisation :

```powershell
$dataSizes = @(100, 1000, 10000)

$sortFunction = {
    param($data)
    return $data | Sort-Object -Property Value
}

$results = Measure-ScalabilityPerformance -Name "Tri" -ScriptBlock $sortFunction -DataSizes $dataSizes -Iterations 3

foreach ($result in $results) {
    Write-Host "Taille: $($result.Size) éléments, Temps: $($result.ExecutionTimeMs) ms, Débit: $($result.ItemsPerMs) éléments/ms"
}
```

## Exécution des tests de performance

### Exécution de tous les tests

Pour exécuter tous les tests de performance, utilisez le script `Run-AllTests.ps1` :

```powershell
.\Run-AllTests.ps1
```

### Exécution d'un test spécifique

Pour exécuter un test de performance spécifique, utilisez Invoke-Pester avec le paramètre `-Path` :

```powershell
Invoke-Pester -Path ".\PerformanceBenchmark.Tests.ps1"
```

### Exécution avec génération de rapport

Pour exécuter les tests de performance et générer un rapport, utilisez le paramètre `-GenerateReport` :

```powershell
.\Run-AllTests.ps1 -GenerateReport $true -OutputPath "C:\TestResults"
```

## Interprétation des résultats

### Temps d'exécution

Le temps d'exécution est la métrique principale pour mesurer les performances. Plus le temps d'exécution est court, meilleures sont les performances.

### Amélioration en pourcentage

L'amélioration en pourcentage indique l'amélioration relative des performances entre deux implémentations. Une valeur positive indique que la seconde implémentation est plus rapide que la première.

### Débit

Le débit (éléments/ms) indique le nombre d'éléments traités par milliseconde. Plus le débit est élevé, meilleures sont les performances.

### Utilisation des ressources

L'utilisation des ressources (CPU, mémoire) indique l'efficacité de l'implémentation en termes de ressources. Une utilisation plus faible des ressources est généralement préférable.

## Bonnes pratiques pour les tests de performance

1. **Répétabilité** : Les tests de performance doivent être répétables pour obtenir des résultats fiables.

2. **Isolation** : Isolez les tests de performance des autres tests pour éviter les interférences.

3. **Précision** : Utilisez des mesures précises pour obtenir des résultats fiables.

4. **Comparaison** : Comparez les performances de différentes implémentations pour mesurer l'amélioration.

5. **Scalabilité** : Testez les performances avec différentes tailles de données pour vérifier la scalabilité.

6. **Documentation** : Documentez les résultats des tests de performance pour référence future.

7. **Automatisation** : Automatisez les tests de performance pour les exécuter régulièrement.

8. **Seuils** : Définissez des seuils de performance pour détecter les régressions.

## Exemples de tests de performance

### Exemple 1 : Comparaison de performances

```powershell
Describe "Tests de performance" {
    Context "Tri de données" {
        BeforeAll {
            # Générer des données de test
            $testData = 1..1000 | ForEach-Object { [PSCustomObject]@{ Value = Get-Random } }
            
            # Définir les implémentations à comparer
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
            # Comparer les implémentations
            $comparison = Compare-Implementations -Name "Tri" -Implementation1 $implementation1 -Implementation2 $implementation2 -Parameters @{ data = $testData } -Iterations 5
            
            # Afficher les résultats
            Write-Host "Temps moyen (Implémentation 1): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (Implémentation 2): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "Amélioration: $($comparison.TimeImprovementPercent) %"
            
            # Vérifier que l'implémentation 2 est plus rapide
            $comparison.TimeImprovementPercent | Should -BeGreaterThan 0
        }
    }
}
```

### Exemple 2 : Test de charge

```powershell
Describe "Tests de performance" {
    Context "Scalabilité du tri" {
        BeforeAll {
            # Définir les tailles de données à tester
            $dataSizes = @(100, 1000, 10000)
            
            # Définir la fonction à tester
            $sortFunction = {
                param($data)
                return $data | Sort-Object -Property Value
            }
        }
        
        It "Mesure la scalabilité du tri" {
            # Mesurer les performances avec différentes tailles de données
            $results = Measure-ScalabilityPerformance -Name "Tri" -ScriptBlock $sortFunction -DataSizes $dataSizes -Iterations 3
            
            # Afficher les résultats
            foreach ($result in $results) {
                Write-Host "Taille: $($result.Size) éléments, Temps: $($result.ExecutionTimeMs) ms, Débit: $($result.ItemsPerMs) éléments/ms"
            }
            
            # Vérifier que le débit diminue avec l'augmentation de la taille des données
            $smallSizeItemsPerMs = $results[0].ItemsPerMs
            $largeSizeItemsPerMs = $results[-1].ItemsPerMs
            
            $largeSizeItemsPerMs | Should -BeLessThan $smallSizeItemsPerMs
        }
    }
}
```

### Exemple 3 : Test de parallélisme

```powershell
Describe "Tests de performance" {
    Context "Traitement parallèle" {
        BeforeAll {
            # Générer des données de test
            $testFiles = New-TestFiles -OutputPath $testRootDir -FileCount 20
            
            # Définir les implémentations à comparer
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
        
        It "Compare les performances du traitement séquentiel et parallèle" -Skip:($PSVersionTable.PSVersion.Major -lt 7) {
            # Comparer les implémentations
            $comparison = Compare-Implementations -Name "Traitement de fichiers" -Implementation1 $sequentialImplementation -Implementation2 $parallelImplementation -Parameters @{ files = $testFiles } -Iterations 3
            
            # Afficher les résultats
            Write-Host "Temps moyen (Séquentiel): $($comparison.Result1.AverageExecutionTimeMs) ms"
            Write-Host "Temps moyen (Parallèle): $($comparison.Result2.AverageExecutionTimeMs) ms"
            Write-Host "Amélioration: $($comparison.TimeImprovementPercent) %"
            
            # Vérifier que le traitement parallèle est plus rapide
            $comparison.TimeImprovementPercent | Should -BeGreaterThan 10
        }
    }
}
```

## Conclusion

Les tests de performance sont essentiels pour mesurer et améliorer les performances des scripts. En suivant les bonnes pratiques et en utilisant les outils appropriés, vous pouvez créer des tests de performance fiables et précis qui vous aideront à optimiser vos scripts.
