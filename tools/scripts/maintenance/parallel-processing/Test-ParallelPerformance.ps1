<#
.SYNOPSIS
    Compare les performances de diffÃ©rentes mÃ©thodes de traitement parallÃ¨le.
.DESCRIPTION
    Ce script compare les performances de trois approches de traitement parallÃ¨le :
    1. Traitement sÃ©quentiel
    2. Jobs PowerShell
    3. Runspace Pools (via Invoke-OptimizedParallel)
.PARAMETER TestFileCount
    Le nombre de fichiers de test Ã  crÃ©er.
.PARAMETER TestIterations
    Le nombre d'itÃ©rations Ã  exÃ©cuter pour chaque mÃ©thode.
.PARAMETER ModulePath
    Chemin optionnel vers le module ParallelProcessing. Si non spÃ©cifiÃ©, utilise le module dans le mÃªme rÃ©pertoire.
.EXAMPLE
    .\Test-ParallelPerformance.ps1 -TestFileCount 20 -TestIterations 3
.EXAMPLE
    .\Test-ParallelPerformance.ps1 -ModulePath "C:\Modules\ParallelProcessing"
.NOTES
    Auteur: Augment Agent
    Version: 2.0
    CompatibilitÃ©: PowerShell 5.1 et supÃ©rieur
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [int]$TestFileCount = 10,

    [Parameter(Mandatory = $false)]
    [int]$TestIterations = 2,

    [Parameter(Mandatory = $false)]
    [string]$ModulePath = ""
)

# Importer la fonction Invoke-OptimizedParallel
$scriptPath = $PSScriptRoot
if ([string]::IsNullOrEmpty($ModulePath)) {
    $modulePath = Join-Path -Path $scriptPath -ChildPath "Invoke-OptimizedParallel-Simple.ps1"
    Write-Verbose "Utilisation du module local: $modulePath"
} else {
    $modulePath = Join-Path -Path $ModulePath -ChildPath "Invoke-OptimizedParallel-Simple.ps1"
    Write-Verbose "Utilisation du module spÃ©cifiÃ©: $modulePath"
}

if (Test-Path -Path $modulePath) {
    . $modulePath
    Write-Verbose "Module Invoke-OptimizedParallel chargÃ© avec succÃ¨s."
} else {
    Write-Error "Module Invoke-OptimizedParallel introuvable Ã  l'emplacement: $modulePath"
    exit 1
}

# CrÃ©er un rÃ©pertoire temporaire pour les fichiers de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "ParallelPerformanceTest_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null

Write-Host "CrÃ©ation de $TestFileCount fichiers de test dans $testDir..."

# CrÃ©er des fichiers de test avec du contenu alÃ©atoire
for ($i = 1; $i -le $TestFileCount; $i++) {
    $filePath = Join-Path -Path $testDir -ChildPath "TestFile$i.txt"

    # GÃ©nÃ©rer du contenu alÃ©atoire (entre 100 et 1000 lignes)
    $lineCount = Get-Random -Minimum 100 -Maximum 1000
    $content = ""

    for ($j = 1; $j -le $lineCount; $j++) {
        $content += "Ligne $j : " + [Guid]::NewGuid().ToString() + "`r`n"
    }

    Set-Content -Path $filePath -Value $content -Force
}

Write-Host "Fichiers de test crÃ©Ã©s avec succÃ¨s."

# Fonction pour tester le traitement sÃ©quentiel
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

        # Compter les lignes, mots et caractÃ¨res
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

    # CrÃ©er un job pour chaque fichier
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

            # Compter les lignes, mots et caractÃ¨res
            $result.LineCount = ($content -split "`r`n|\r|\n").Count
            $result.WordCount = ($content -split '\s+').Count
            $result.CharCount = $content.Length

            return [PSCustomObject]$result
        } -ArgumentList $file

        $jobs += $job
    }

    # Attendre que tous les jobs soient terminÃ©s
    $jobs | Wait-Job | Out-Null

    # RÃ©cupÃ©rer les rÃ©sultats
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

        # Compter les lignes, mots et caractÃ¨res
        $result.LineCount = ($content -split "`r`n|\r|\n").Count
        $result.WordCount = ($content -split '\s+').Count
        $result.CharCount = $content.Length

        return [PSCustomObject]$result
    }

    # Utiliser Invoke-OptimizedParallel pour traiter les fichiers
    $parallelResults = $files | Invoke-OptimizedParallel -ScriptBlock $scriptBlock -Verbose:$VerbosePreference

    # Extraire les rÃ©sultats rÃ©els des objets retournÃ©s (nouvelle structure)
    $results = $parallelResults | Where-Object { $_.Success } | ForEach-Object {
        # Ajouter la propriÃ©tÃ© FilePath qui est dans InputObject
        $result = $_.Result
        if ($result -and -not $result.PSObject.Properties.Name.Contains('FilePath')) {
            $result | Add-Member -MemberType NoteProperty -Name 'FilePath' -Value $_.InputObject -Force
        }
        $result
    }

    # Afficher les erreurs Ã©ventuelles
    $errors = $parallelResults | Where-Object { -not $_.Success }
    if ($errors.Count -gt 0) {
        Write-Warning "Des erreurs se sont produites lors du traitement parallÃ¨le:"
        foreach ($error in $errors) {
            Write-Warning "Erreur pour $($error.InputObject): $($error.ErrorRecord.Exception.Message)"
        }
    }

    return $results
}

# Obtenir la liste des fichiers de test
$testFiles = Get-ChildItem -Path $testDir -Filter "*.txt" | Select-Object -ExpandProperty FullName

# ExÃ©cuter les tests de performance
$results = @()

Write-Host "`nExÃ©cution des tests de performance..."

for ($i = 1; $i -le $TestIterations; $i++) {
    Write-Host "`nItÃ©ration $i de $TestIterations"

    # Test du traitement sÃ©quentiel
    Write-Host "Test du traitement sÃ©quentiel..."
    $startTime = Get-Date
    $sequentialResults = Test-SequentialProcessing -files $testFiles
    $endTime = Get-Date
    $sequentialDuration = ($endTime - $startTime).TotalSeconds

    $results += [PSCustomObject]@{
        Iteration = $i
        Method = "SÃ©quentiel"
        Duration = $sequentialDuration
        FilesProcessed = $sequentialResults.Count
        TotalLines = ($sequentialResults | Measure-Object -Property LineCount -Sum).Sum
        TotalChars = ($sequentialResults | Measure-Object -Property CharCount -Sum).Sum
    }

    Write-Host "Traitement sÃ©quentiel terminÃ© en $sequentialDuration secondes."

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

    Write-Host "Traitement avec Jobs PowerShell terminÃ© en $jobsDuration secondes."

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

    Write-Host "Traitement avec Runspace Pools terminÃ© en $runspaceDuration secondes."
}

# Calculer les moyennes
$averages = $results | Group-Object -Property Method | ForEach-Object {
    $method = $_.Name
    $avgDuration = ($_.Group | Measure-Object -Property Duration -Average).Average
    $speedup = ($results | Where-Object { $_.Method -eq "SÃ©quentiel" -and $_.Iteration -eq 1 }).Duration / $avgDuration

    [PSCustomObject]@{
        Method = $method
        AverageDuration = $avgDuration
        SpeedupFactor = $speedup
        FilesProcessed = $TestFileCount
        TotalLines = ($_.Group | Where-Object { $_.Iteration -eq 1 }).TotalLines
        TotalChars = ($_.Group | Where-Object { $_.Iteration -eq 1 }).TotalChars
    }
}

# Afficher les rÃ©sultats
Write-Host "`n--- RÃ©sultats des tests de performance ---"
Write-Host "Configuration du test : $TestFileCount fichiers, $TestIterations itÃ©rations"

$averages | Format-Table -Property Method, @{
    Label = "DurÃ©e moyenne (s)"
    Expression = { [math]::Round($_.AverageDuration, 2) }
}, @{
    Label = "AccÃ©lÃ©ration vs SÃ©quentiel"
    Expression = { [math]::Round($_.SpeedupFactor, 2) }
}, FilesProcessed, TotalLines, TotalChars

# Nettoyer les fichiers de test
Write-Host "`nNettoyage des fichiers de test..."
Remove-Item -Path $testDir -Recurse -Force

Write-Host "Test de performance terminÃ©."
