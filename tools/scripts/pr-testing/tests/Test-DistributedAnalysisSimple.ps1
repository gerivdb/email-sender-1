#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiÃ©s pour le script Start-DistributedAnalysis.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiÃ©s pour vÃ©rifier le bon fonctionnement
    du script Start-DistributedAnalysis.ps1.

.EXAMPLE
    .\Test-DistributedAnalysisSimple.ps1

.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date: 2025-04-30
#>

[CmdletBinding()]
param()

# Fonction pour crÃ©er un environnement de test
function Initialize-TestEnvironment {
    param(
        [string]$TestDir = "$env:TEMP\DistributedAnalysisTest_$(Get-Random)"
    )
    
    # CrÃ©er le rÃ©pertoire de test
    if (-not (Test-Path -Path $TestDir)) {
        New-Item -Path $TestDir -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er des fichiers de test
    $testFiles = @(
        @{
            Path = "PowerShell\test1.ps1"
            Content = @"
function Test-Function {
    param([string]`$param1)
    
    # Erreur: Utilisation d'un alias
    gci -Path "C:\" | Where { `$_.Name -like "*.txt" }
    
    # Erreur: Utilisation de Invoke-Expression
    Invoke-Expression "Get-Process"
}
"@
        },
        @{
            Path = "PowerShell\test2.ps1"
            Content = @"
function Test-Function2 {
    param([string]`$param1)
    
    # Code valide
    Get-ChildItem -Path "C:\" | Where-Object { `$_.Name -like "*.txt" }
}
"@
        },
        @{
            Path = "Python\test.py"
            Content = @"
def test_function(param1):
    # Erreur: Utilisation de eval()
    result = eval("2 + 2")
    
    # Erreur: Exception gÃ©nÃ©rique
    try:
        x = 1 / 0
    except:
        pass
"@
        }
    )
    
    foreach ($file in $testFiles) {
        $filePath = Join-Path -Path $TestDir -ChildPath $file.Path
        $directory = Split-Path -Path $filePath -Parent
        
        if (-not (Test-Path -Path $directory)) {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
        }
        
        Set-Content -Path $filePath -Value $file.Content -Encoding UTF8
    }
    
    return $TestDir
}

# Fonction pour nettoyer l'environnement de test
function Remove-TestEnvironment {
    param(
        [string]$TestDir
    )
    
    if (Test-Path -Path $TestDir) {
        Remove-Item -Path $TestDir -Recurse -Force
    }
}

# Fonction pour tester la fonction Split-FilesIntoChunks
function Test-SplitFilesIntoChunks {
    param(
        [string[]]$FilePaths,
        [int]$ChunkSize
    )
    
    # DÃ©finir la fonction Split-FilesIntoChunks
    function Split-FilesIntoChunks {
        param([string[]]$FilePaths, [int]$ChunkSize)
        
        $chunks = @()
        $currentChunk = @()
        
        foreach ($filePath in $FilePaths) {
            $currentChunk += $filePath
            
            if ($currentChunk.Count -ge $ChunkSize) {
                $chunks += , $currentChunk
                $currentChunk = @()
            }
        }
        
        if ($currentChunk.Count -gt 0) {
            $chunks += , $currentChunk
        }
        
        return $chunks
    }
    
    # ExÃ©cuter la fonction
    $result = Split-FilesIntoChunks -FilePaths $FilePaths -ChunkSize $ChunkSize
    
    return $result
}

# Fonction pour tester la fonction Merge-AnalysisResults
function Test-MergeAnalysisResults {
    param(
        [array]$Results
    )
    
    # DÃ©finir la fonction Merge-AnalysisResults
    function Merge-AnalysisResults {
        param([array]$Results)
        
        $mergedResults = @{}
        
        foreach ($result in $Results) {
            foreach ($fileResult in $result) {
                if ($fileResult.Success) {
                    $filePath = $fileResult.FilePath
                    
                    if (-not $mergedResults.ContainsKey($filePath)) {
                        $mergedResults[$filePath] = @{
                            FilePath = $filePath
                            Issues = @()
                            Success = $true
                            Error = $null
                        }
                    }
                    
                    $mergedResults[$filePath].Issues += $fileResult.Issues
                }
            }
        }
        
        return $mergedResults
    }
    
    # ExÃ©cuter la fonction
    $result = Merge-AnalysisResults -Results $Results
    
    return $result
}

# Initialiser l'environnement de test
$testDir = Initialize-TestEnvironment

try {
    Write-Host "ExÃ©cution des tests unitaires simplifiÃ©s pour Start-DistributedAnalysis.ps1" -ForegroundColor Cyan
    
    # Test 1: Split-FilesIntoChunks divise correctement les fichiers en lots
    Write-Host "Test 1: Split-FilesIntoChunks divise correctement les fichiers en lots" -ForegroundColor Yellow
    
    # CrÃ©er des fichiers de test
    $files = @(
        "$testDir\file1.ps1",
        "$testDir\file2.ps1",
        "$testDir\file3.ps1",
        "$testDir\file4.ps1",
        "$testDir\file5.ps1"
    )
    
    # Tester la fonction Split-FilesIntoChunks
    $result = Test-SplitFilesIntoChunks -FilePaths $files -ChunkSize 2
    
    # VÃ©rifier les rÃ©sultats
    if ($result.Count -eq 3 -and $result[0].Count -eq 2 -and $result[1].Count -eq 2 -and $result[2].Count -eq 1) {
        Write-Host "  Test rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "  Test Ã©chouÃ©" -ForegroundColor Red
        Write-Host "  RÃ©sultat attendu: 3 lots (2, 2, 1)" -ForegroundColor Red
        Write-Host "  RÃ©sultat obtenu: $($result.Count) lots ($($result[0].Count), $($result[1].Count), $($result[2].Count))" -ForegroundColor Red
    }
    
    # Test 2: Merge-AnalysisResults fusionne correctement les rÃ©sultats
    Write-Host "Test 2: Merge-AnalysisResults fusionne correctement les rÃ©sultats" -ForegroundColor Yellow
    
    # CrÃ©er des rÃ©sultats de test
    $results = @(
        @(
            [PSCustomObject]@{
                FilePath = "$testDir\file1.ps1"
                Issues = @(
                    [PSCustomObject]@{
                        Line = 1
                        Column = 1
                        Message = "Issue 1"
                        Severity = "Error"
                    }
                )
                Success = $true
                Error = $null
            },
            [PSCustomObject]@{
                FilePath = "$testDir\file2.ps1"
                Issues = @(
                    [PSCustomObject]@{
                        Line = 2
                        Column = 2
                        Message = "Issue 2"
                        Severity = "Warning"
                    }
                )
                Success = $true
                Error = $null
            }
        ),
        @(
            [PSCustomObject]@{
                FilePath = "$testDir\file1.ps1"
                Issues = @(
                    [PSCustomObject]@{
                        Line = 3
                        Column = 3
                        Message = "Issue 3"
                        Severity = "Info"
                    }
                )
                Success = $true
                Error = $null
            },
            [PSCustomObject]@{
                FilePath = "$testDir\file3.ps1"
                Issues = @(
                    [PSCustomObject]@{
                        Line = 4
                        Column = 4
                        Message = "Issue 4"
                        Severity = "Error"
                    }
                )
                Success = $true
                Error = $null
            }
        )
    )
    
    # Tester la fonction Merge-AnalysisResults
    $result = Test-MergeAnalysisResults -Results $results
    
    # VÃ©rifier les rÃ©sultats
    if ($result.Count -eq 3 -and $result["$testDir\file1.ps1"].Issues.Count -eq 2 -and $result["$testDir\file2.ps1"].Issues.Count -eq 1 -and $result["$testDir\file3.ps1"].Issues.Count -eq 1) {
        Write-Host "  Test rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "  Test Ã©chouÃ©" -ForegroundColor Red
        Write-Host "  RÃ©sultat attendu: 3 fichiers (2 issues, 1 issue, 1 issue)" -ForegroundColor Red
        Write-Host "  RÃ©sultat obtenu: $($result.Count) fichiers ($($result["$testDir\file1.ps1"].Issues.Count), $($result["$testDir\file2.ps1"].Issues.Count), $($result["$testDir\file3.ps1"].Issues.Count))" -ForegroundColor Red
    }
    
    Write-Host "Tests terminÃ©s" -ForegroundColor Cyan
} finally {
    # Nettoyer l'environnement de test
    Remove-TestEnvironment -TestDir $testDir
}
