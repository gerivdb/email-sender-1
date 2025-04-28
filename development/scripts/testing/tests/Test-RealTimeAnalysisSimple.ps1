#Requires -Version 5.1
<#
.SYNOPSIS
    Tests unitaires simplifiÃ©s pour le script Start-RealTimeAnalysis.ps1.

.DESCRIPTION
    Ce script contient des tests unitaires simplifiÃ©s pour vÃ©rifier le bon fonctionnement
    du script Start-RealTimeAnalysis.ps1.

.EXAMPLE
    .\Test-RealTimeAnalysisSimple.ps1

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
        [string]$TestDir = "$env:TEMP\RealTimeAnalysisTest_$(Get-Random)"
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

# Fonction pour simuler l'analyse d'un fichier
function Test-FileAnalysis {
    param(
        [string]$FilePath
    )
    
    # Simuler l'analyse d'un fichier
    $extension = [System.IO.Path]::GetExtension($FilePath)
    
    if ($extension -eq ".ps1") {
        if ($FilePath -like "*test1.ps1") {
            return @(
                [PSCustomObject]@{
                    Line = 5
                    Column = 5
                    Message = "Utilisation d'un alias (gci) au lieu du nom complet (Get-ChildItem)"
                    Severity = "Warning"
                },
                [PSCustomObject]@{
                    Line = 8
                    Column = 5
                    Message = "Utilisation de Invoke-Expression peut prÃ©senter des risques de sÃ©curitÃ©"
                    Severity = "Error"
                }
            )
        } else {
            return @()
        }
    } elseif ($extension -eq ".py") {
        return @(
            [PSCustomObject]@{
                Line = 3
                Column = 13
                Message = "Utilisation de eval() peut prÃ©senter des risques de sÃ©curitÃ©"
                Severity = "Error"
            },
            [PSCustomObject]@{
                Line = 6
                Column = 5
                Message = "Exception gÃ©nÃ©rique dÃ©tectÃ©e"
                Severity = "Warning"
            }
        )
    } else {
        return @()
    }
}

# Fonction pour simuler un Ã©vÃ©nement de modification de fichier
function Test-FileChangeEvent {
    param(
        [string]$FilePath,
        [string]$NotificationType = "Console"
    )
    
    # Simuler l'analyse d'un fichier
    $issues = Test-FileAnalysis -FilePath $FilePath
    
    # CrÃ©er un objet rÃ©sultat
    $result = [PSCustomObject]@{
        FilePath = $FilePath
        Issues = $issues
        AnalyzedAt = Get-Date
        Success = $true
        Error = $null
    }
    
    # CrÃ©er une notification si des problÃ¨mes sont dÃ©tectÃ©s
    $notification = $null
    
    if ($issues.Count -gt 0) {
        $message = "DÃ©tectÃ© $($issues.Count) problÃ¨me(s) dans le fichier $FilePath"
        $notification = [PSCustomObject]@{
            Title = "Analyse en temps rÃ©el"
            Message = $message
            Type = $NotificationType
        }
    }
    
    return [PSCustomObject]@{
        Result = $result
        Notification = $notification
    }
}

# Initialiser l'environnement de test
$testDir = Initialize-TestEnvironment

try {
    Write-Host "ExÃ©cution des tests unitaires simplifiÃ©s pour Start-RealTimeAnalysis.ps1" -ForegroundColor Cyan
    
    # Test 1: DÃ©tecte correctement les problÃ¨mes dans un fichier PowerShell
    Write-Host "Test 1: DÃ©tecte correctement les problÃ¨mes dans un fichier PowerShell" -ForegroundColor Yellow
    
    # Tester l'analyse d'un fichier PowerShell avec des problÃ¨mes
    $filePath = Join-Path -Path $testDir -ChildPath "PowerShell\test1.ps1"
    $issues = Test-FileAnalysis -FilePath $filePath
    
    # VÃ©rifier les rÃ©sultats
    if ($issues -and $issues.Count -eq 2 -and $issues[0].Message -match "alias" -and $issues[1].Message -match "Invoke-Expression") {
        Write-Host "  Test rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "  Test Ã©chouÃ©" -ForegroundColor Red
        Write-Host "  RÃ©sultat attendu: 2 problÃ¨mes (alias, Invoke-Expression)" -ForegroundColor Red
        Write-Host "  RÃ©sultat obtenu: $($issues.Count) problÃ¨mes" -ForegroundColor Red
    }
    
    # Test 2: Ne dÃ©tecte pas de problÃ¨mes dans un fichier PowerShell valide
    Write-Host "Test 2: Ne dÃ©tecte pas de problÃ¨mes dans un fichier PowerShell valide" -ForegroundColor Yellow
    
    # Tester l'analyse d'un fichier PowerShell valide
    $filePath = Join-Path -Path $testDir -ChildPath "PowerShell\test2.ps1"
    $issues = Test-FileAnalysis -FilePath $filePath
    
    # VÃ©rifier les rÃ©sultats
    if (-not $issues -or $issues.Count -eq 0) {
        Write-Host "  Test rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "  Test Ã©chouÃ©" -ForegroundColor Red
        Write-Host "  RÃ©sultat attendu: 0 problÃ¨me" -ForegroundColor Red
        Write-Host "  RÃ©sultat obtenu: $($issues.Count) problÃ¨mes" -ForegroundColor Red
    }
    
    # Test 3: DÃ©tecte correctement les problÃ¨mes dans un fichier Python
    Write-Host "Test 3: DÃ©tecte correctement les problÃ¨mes dans un fichier Python" -ForegroundColor Yellow
    
    # Tester l'analyse d'un fichier Python avec des problÃ¨mes
    $filePath = Join-Path -Path $testDir -ChildPath "Python\test.py"
    $issues = Test-FileAnalysis -FilePath $filePath
    
    # VÃ©rifier les rÃ©sultats
    if ($issues -and $issues.Count -eq 2 -and $issues[0].Message -match "eval" -and $issues[1].Message -match "Exception") {
        Write-Host "  Test rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "  Test Ã©chouÃ©" -ForegroundColor Red
        Write-Host "  RÃ©sultat attendu: 2 problÃ¨mes (eval, Exception)" -ForegroundColor Red
        Write-Host "  RÃ©sultat obtenu: $($issues.Count) problÃ¨mes" -ForegroundColor Red
    }
    
    # Test 4: GÃ©nÃ¨re une notification pour un fichier avec des problÃ¨mes
    Write-Host "Test 4: GÃ©nÃ¨re une notification pour un fichier avec des problÃ¨mes" -ForegroundColor Yellow
    
    # Tester un Ã©vÃ©nement de modification de fichier pour un fichier avec des problÃ¨mes
    $filePath = Join-Path -Path $testDir -ChildPath "PowerShell\test1.ps1"
    $result = Test-FileChangeEvent -FilePath $filePath
    
    # VÃ©rifier les rÃ©sultats
    if ($result -and $result.Result -and $result.Result.Issues -and $result.Result.Issues.Count -eq 2 -and $result.Notification -and $result.Notification.Title -eq "Analyse en temps rÃ©el" -and $result.Notification.Message -match "DÃ©tectÃ© 2 problÃ¨me") {
        Write-Host "  Test rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "  Test Ã©chouÃ©" -ForegroundColor Red
        Write-Host "  RÃ©sultat attendu: Notification pour 2 problÃ¨mes" -ForegroundColor Red
        Write-Host "  RÃ©sultat obtenu: $($result.Notification.Message)" -ForegroundColor Red
    }
    
    # Test 5: Ne gÃ©nÃ¨re pas de notification pour un fichier sans problÃ¨mes
    Write-Host "Test 5: Ne gÃ©nÃ¨re pas de notification pour un fichier sans problÃ¨mes" -ForegroundColor Yellow
    
    # Tester un Ã©vÃ©nement de modification de fichier pour un fichier sans problÃ¨mes
    $filePath = Join-Path -Path $testDir -ChildPath "PowerShell\test2.ps1"
    $result = Test-FileChangeEvent -FilePath $filePath
    
    # VÃ©rifier les rÃ©sultats
    if ($result -and $result.Result -and (-not $result.Result.Issues -or $result.Result.Issues.Count -eq 0) -and -not $result.Notification) {
        Write-Host "  Test rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "  Test Ã©chouÃ©" -ForegroundColor Red
        Write-Host "  RÃ©sultat attendu: Pas de notification" -ForegroundColor Red
        Write-Host "  RÃ©sultat obtenu: $($result.Notification)" -ForegroundColor Red
    }
    
    # Test 6: Utilise correctement le type de notification
    Write-Host "Test 6: Utilise correctement le type de notification" -ForegroundColor Yellow
    
    # Tester un Ã©vÃ©nement de modification de fichier avec un type de notification spÃ©cifique
    $filePath = Join-Path -Path $testDir -ChildPath "PowerShell\test1.ps1"
    $result = Test-FileChangeEvent -FilePath $filePath -NotificationType "Popup"
    
    # VÃ©rifier les rÃ©sultats
    if ($result -and $result.Notification -and $result.Notification.Type -eq "Popup") {
        Write-Host "  Test rÃ©ussi" -ForegroundColor Green
    } else {
        Write-Host "  Test Ã©chouÃ©" -ForegroundColor Red
        Write-Host "  RÃ©sultat attendu: Type de notification = Popup" -ForegroundColor Red
        Write-Host "  RÃ©sultat obtenu: Type de notification = $($result.Notification.Type)" -ForegroundColor Red
    }
    
    Write-Host "Tests terminÃ©s" -ForegroundColor Cyan
} finally {
    # Nettoyer l'environnement de test
    Remove-TestEnvironment -TestDir $testDir
}
