<#
.SYNOPSIS
    Compare les performances de différentes méthodes de traitement parallèle.
.DESCRIPTION
    Ce script compare les performances de trois approches de traitement parallèle :
    1. Traitement séquentiel
    2. Jobs PowerShell
    3. Runspace Pools (via Invoke-OptimizedParallel)
.PARAMETER TestFileCount
    Le nombre de fichiers de test à créer.
.PARAMETER TestIterations
    Le nombre d'itérations à exécuter pour chaque méthode.
.EXAMPLE
    .\Test-ParallelPerformance.ps1 -TestFileCount 20 -TestIterations 3
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Compatibilité: PowerShell 5.1 et supérieur
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$TestFileCount = 10,
    
    [Parameter(Mandatory = $false)]
    [int]$TestIterations = 2
)

# Importer la fonction Invoke-OptimizedParallel
$scriptPath = $PSScriptRoot
$modulePath = Join-Path -Path $scriptPath -ChildPath "Invoke-OptimizedParallel.ps1"
. $modulePath

# Créer un répertoire temporaire pour les fichiers de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "ParallelPerformanceTest_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

Write-Host "Création de $TestFileCount fichiers de test dans $testDir..."

# Créer des fichiers de test avec du contenu aléatoire
for ($i = 1; $i -le $TestFileCount; $i++) {
    $filePath = Join-Path -Path $testDir -ChildPath "TestFile$i.txt"
    
    # Générer du contenu aléatoire (entre 100 et 1000 lignes)
    $lineCount = Get-Random -Minimum 100 -Maximum 1000
    $content = ""
    
    for ($j = 1; $j -le $lineCount; $j++) {
        $content += "Ligne $j : " + [Guid]::NewGuid().ToString() + "`r`n"
    }
    
    Set-Content -Path $filePath -Value $content -Force
}

Write-Host "Fichiers de test créés avec succès."

# Fonction pour tester le traitement séquentiel
function Test-SequentialProcessing {
    param($files)
    
    $results = @()
    
    foreach ($file in $files) {
        $result = @{
            FilePath = $file
            LineCount = 0
            WordCount = 0
            CharCount = 0
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $file -Raw
        
        # Compter les lignes, mots et caractères
        $result.LineCount = ($content -split "`r`n|\r|\n").Count
        $result.WordCount = ($content -split '\s+').Count
        $result.CharCount = $content.Length
        
        $results += [PSCustomObject]$result
    }
    
    return $results
}

# Fonction pour tester le traitement avec Jobs PowerShell
function Test-JobsProcessing {
    param($files)
    
    $jobs = @()
    
    # Créer un job pour chaque fichier
    foreach ($file in $files) {
        $job = Start-Job -ScriptBlock {
            param($filePath)
            
            $result = @{
                FilePath = $filePath
                LineCount = 0
                WordCount = 0
                CharCount = 0
            }
            
            # Lire le contenu du fichier
            $content = Get-Content -Path $filePath -Raw
            
            # Compter les lignes, mots et caractères
            $result.LineCount = ($content -split "`r`n|\r|\n").Count
            $result.WordCount = ($content -split '\s+').Count
            $result.CharCount = $content.Length
            
            return [PSCustomObject]$result
        } -ArgumentList $file
        
        $jobs += $job
    }
    
    # Attendre que tous les jobs soient terminés
    $jobs | Wait-Job | Out-Null
    
    # Récupérer les résultats
    $results = $jobs | Receive-Job
    
    # Nettoyer les jobs
    $jobs | Remove-Job
    
    return $results
}

# Fonction pour tester le traitement avec Invoke-OptimizedParallel
function Test-RunspacePoolProcessing {
    param($files)
    
    $scriptBlock = {
        param($filePath)
        
        $result = @{
            FilePath = $filePath
            LineCount = 0
            WordCount = 0
            CharCount = 0
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $filePath -Raw
        
        # Compter les lignes, mots et caractères
        $result.LineCount = ($content -split "`r`n|\r|\n").Count
        $result.WordCount = ($content -split '\s+').Count
        $result.CharCount = $content.Length
        
        return [PSCustomObject]$result
    }
    
    # Utiliser Invoke-OptimizedParallel pour traiter les fichiers
    $results = $files | Invoke-OptimizedParallel -ScriptBlock $scriptBlock
    
    return $results
}

# Obtenir la liste des fichiers de test
$testFiles = Get-ChildItem -Path $testDir -Filter "*.txt" | Select-Object -ExpandProperty FullName

# Exécuter les tests de performance
$results = @()

Write-Host "`nExécution des tests de performance..."

for ($i = 1; $i -le $TestIterations; $i++) {
    Write-Host "`nItération $i de $TestIterations"
    
    # Test du traitement séquentiel
    Write-Host "Test du traitement séquentiel..."
    $startTime = Get-Date
    $sequentialResults = Test-SequentialProcessing -files $testFiles
    $endTime = Get-Date
    $sequentialDuration = ($endTime - $startTime).TotalSeconds
    
    $results += [PSCustomObject]@{
        Iteration = $i
        Method = "Séquentiel"
        Duration = $sequentialDuration
        FilesProcessed = $sequentialResults.Count
        TotalLines = ($sequentialResults | Measure-Object -Property LineCount -Sum).Sum
        TotalChars = ($sequentialResults | Measure-Object -Property CharCount -Sum).Sum
    }
    
    Write-Host "Traitement séquentiel terminé en $sequentialDuration secondes."
    
    # Test du traitement avec Jobs PowerShell
    Write-Host "Test du traitement avec Jobs PowerShell..."
    $startTime = Get-Date
    $jobsResults = Test-JobsProcessing -files $testFiles
    $endTime = Get-Date
    $jobsDuration = ($endTime - $startTime).TotalSeconds
    
    $results += [PSCustomObject]@{
        Iteration = $i
        Method = "Jobs PowerShell"
        Duration = $jobsDuration
        FilesProcessed = $jobsResults.Count
        TotalLines = ($jobsResults | Measure-Object -Property LineCount -Sum).Sum
        TotalChars = ($jobsResults | Measure-Object -Property CharCount -Sum).Sum
    }
    
    Write-Host "Traitement avec Jobs PowerShell terminé en $jobsDuration secondes."
    
    # Test du traitement avec Invoke-OptimizedParallel
    Write-Host "Test du traitement avec Runspace Pools..."
    $startTime = Get-Date
    $runspaceResults = Test-RunspacePoolProcessing -files $testFiles
    $endTime = Get-Date
    $runspaceDuration = ($endTime - $startTime).TotalSeconds
    
    $results += [PSCustomObject]@{
        Iteration = $i
        Method = "Runspace Pools"
        Duration = $runspaceDuration
        FilesProcessed = $runspaceResults.Count
        TotalLines = ($runspaceResults | Measure-Object -Property LineCount -Sum).Sum
        TotalChars = ($runspaceResults | Measure-Object -Property CharCount -Sum).Sum
    }
    
    Write-Host "Traitement avec Runspace Pools terminé en $runspaceDuration secondes."
}

# Calculer les moyennes
$averages = $results | Group-Object -Property Method | ForEach-Object {
    $method = $_.Name
    $avgDuration = ($_.Group | Measure-Object -Property Duration -Average).Average
    $speedup = ($results | Where-Object { $_.Method -eq "Séquentiel" -and $_.Iteration -eq 1 }).Duration / $avgDuration
    
    [PSCustomObject]@{
        Method = $method
        AverageDuration = $avgDuration
        SpeedupFactor = $speedup
        FilesProcessed = $TestFileCount
        TotalLines = ($_.Group | Where-Object { $_.Iteration -eq 1 }).TotalLines
        TotalChars = ($_.Group | Where-Object { $_.Iteration -eq 1 }).TotalChars
    }
}

# Afficher les résultats
Write-Host "`n--- Résultats des tests de performance ---"
Write-Host "Configuration du test : $TestFileCount fichiers, $TestIterations itérations"

$averages | Format-Table -Property Method, @{
    Label = "Durée moyenne (s)"
    Expression = { [math]::Round($_.AverageDuration, 2) }
}, @{
    Label = "Accélération vs Séquentiel"
    Expression = { [math]::Round($_.SpeedupFactor, 2) }
}, FilesProcessed, TotalLines, TotalChars

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..."
Remove-Item -Path $testDir -Recurse -Force

Write-Host "Test de performance terminé."
