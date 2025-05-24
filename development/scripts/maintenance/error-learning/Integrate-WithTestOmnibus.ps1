#Requires -Version 5.1
<#
.SYNOPSIS
    IntÃ¨gre le systÃ¨me d'analyse des patterns d'erreurs inÃ©dits avec TestOmnibus.
.DESCRIPTION
    Ce script intÃ¨gre le systÃ¨me d'analyse des patterns d'erreurs inÃ©dits avec TestOmnibus
    pour centraliser l'analyse des erreurs et amÃ©liorer la dÃ©tection des patterns inÃ©dits.
.PARAMETER TestOmnibusPath
    Chemin vers le rÃ©pertoire de TestOmnibus.
.PARAMETER ErrorDatabasePath
    Chemin vers la base de donnÃ©es d'erreurs.
.PARAMETER ReportPath
    Chemin oÃ¹ enregistrer le rapport d'intÃ©gration.
.EXAMPLE
    .\Integrate-WithTestOmnibus.ps1 -TestOmnibusPath "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\scripts\testing\TestOmnibus"
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TestOmnibusPath,
    
    [Parameter(Mandatory = $false)]
    [string]$ErrorDatabasePath = (Join-Path -Path $PSScriptRoot -ChildPath "error_database.json"),
    
    [Parameter(Mandatory = $false)]
    [string]$ReportPath = (Join-Path -Path $PSScriptRoot -ChildPath "integration_report.md")
)

# Importer le module d'analyse des patterns d'erreur
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorPatternAnalyzer.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module ErrorPatternAnalyzer non trouvÃ©: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# VÃ©rifier que le rÃ©pertoire TestOmnibus existe
if (-not (Test-Path -Path $TestOmnibusPath -PathType Container)) {
    Write-Error "RÃ©pertoire TestOmnibus non trouvÃ©: $TestOmnibusPath"
    exit 1
}

# Fonction pour extraire les erreurs des logs de TestOmnibus
function Get-TestOmnibusErrors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestOmnibusPath
    )
    
    # Rechercher les fichiers de log de TestOmnibus
    $logFiles = Get-ChildItem -Path $TestOmnibusPath -Recurse -Include "*.log", "test_results_*.xml", "error_*.json" -File
    
    Write-Host "Nombre de fichiers de log trouvÃ©s: $($logFiles.Count)" -ForegroundColor Yellow
    
    $errors = @()
    
    foreach ($logFile in $logFiles) {
        Write-Verbose "Analyse du fichier: $($logFile.FullName)"
        
        # Traiter diffÃ©rents types de fichiers
        switch -Regex ($logFile.Extension) {
            "\.log$" {
                # Extraire les erreurs des fichiers de log
                $logContent = Get-Content -Path $logFile.FullName -Raw
                
                # Rechercher les erreurs dans le log
                $errorPattern = '(?ms)Exception\s*:\s*([^\r\n]+).*?at\s+([^\r\n]+)'
                $matches = [regex]::Matches($logContent, $errorPattern)
                
                foreach ($match in $matches) {
                    $exceptionMessage = $match.Groups[1].Value.Trim()
                    $stackTrace = $match.Groups[2].Value.Trim()
                    
                    $errors += @{
                        Source = $logFile.FullName
                        Message = $exceptionMessage
                        StackTrace = $stackTrace
                        Timestamp = $logFile.LastWriteTime
                    }
                }
            }
            "\.xml$" {
                # Extraire les erreurs des fichiers XML de rÃ©sultats de test
                try {
                    $xmlContent = [xml](Get-Content -Path $logFile.FullName -Raw)
                    
                    # Rechercher les tests en Ã©chec
                    $failedTests = $xmlContent.SelectNodes("//test-case[@result='Failed']")
                    
                    foreach ($failedTest in $failedTests) {
                        $failureMessage = $failedTest.failure.message
                        $stackTrace = $failedTest.failure.'stack-trace'
                        
                        $errors += @{
                            Source = $logFile.FullName
                            Message = $failureMessage
                            StackTrace = $stackTrace
                            Timestamp = [DateTime]::Parse($failedTest.time)
                            TestName = $failedTest.name
                        }
                    }
                }
                catch {
                    Write-Warning "Erreur lors de l'analyse du fichier XML: $($logFile.FullName). $_"
                }
            }
            "\.json$" {
                # Extraire les erreurs des fichiers JSON
                try {
                    $jsonContent = Get-Content -Path $logFile.FullName -Raw | ConvertFrom-Json
                    
                    # Traiter diffÃ©rentes structures JSON
                    if ($jsonContent.errors) {
                        foreach ($error in $jsonContent.errors) {
                            $errors += @{
                                Source = $logFile.FullName
                                Message = $error.message
                                StackTrace = $error.stackTrace
                                Timestamp = if ($error.timestamp) { [DateTime]::Parse($error.timestamp) } else { $logFile.LastWriteTime }
                                TestName = $error.testName
                            }
                        }
                    }
                    elseif ($jsonContent.testResults) {
                        foreach ($result in $jsonContent.testResults | Where-Object { $_.status -eq "Failed" }) {
                            $errors += @{
                                Source = $logFile.FullName
                                Message = $result.errorMessage
                                StackTrace = $result.stackTrace
                                Timestamp = if ($result.timestamp) { [DateTime]::Parse($result.timestamp) } else { $logFile.LastWriteTime }
                                TestName = $result.testName
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "Erreur lors de l'analyse du fichier JSON: $($logFile.FullName). $_"
                }
            }
        }
    }
    
    Write-Host "Nombre d'erreurs extraites: $($errors.Count)" -ForegroundColor Green
    
    return $errors
}

# Fonction pour analyser les erreurs et les ajouter Ã  la base de donnÃ©es
function Add-TestOmnibusErrors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$Errors
    )
    
    $patternIds = @()
    
    foreach ($error in $Errors) {
        # CrÃ©er un objet ErrorRecord
        $exception = New-Object System.Exception $error.Message
        $errorRecord = New-Object System.Management.Automation.ErrorRecord(
            $exception,
            "TestOmnibusError",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            $null
        )
        
        # Ajouter des informations supplÃ©mentaires
        $errorRecord.PSObject.Properties.Add(
            (New-Object System.Management.Automation.PSNoteProperty "ScriptStackTrace", $error.StackTrace)
        )
        
        if ($error.TestName) {
            $errorRecord.PSObject.Properties.Add(
                (New-Object System.Management.Automation.PSNoteProperty "TestName", $error.TestName)
            )
        }
        
        # Ajouter l'erreur Ã  la base de donnÃ©es
        $patternId = Add-ErrorRecord -ErrorRecord $errorRecord -Source $error.Source -Context "TestOmnibus"
        
        $patternIds += $patternId
    }
    
    return $patternIds
}

# Fonction pour crÃ©er un hook d'intÃ©gration avec TestOmnibus
function New-TestOmnibusHook {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestOmnibusPath
    )
    
    $hookPath = Join-Path -Path $TestOmnibusPath -ChildPath "hooks\ErrorPatternAnalyzer.ps1"
    
    # CrÃ©er le rÃ©pertoire hooks s'il n'existe pas
    $hooksDir = Join-Path -Path $TestOmnibusPath -ChildPath "hooks"
    if (-not (Test-Path -Path $hooksDir -PathType Container)) {
        New-Item -Path $hooksDir -ItemType Directory -Force | Out-Null
    }
    
    # CrÃ©er le script de hook
    $hookContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Hook d'intÃ©gration entre TestOmnibus et le systÃ¨me d'analyse des patterns d'erreurs inÃ©dits.
.DESCRIPTION
    Ce script est exÃ©cutÃ© automatiquement par TestOmnibus aprÃ¨s chaque exÃ©cution de tests
    pour analyser les erreurs et les ajouter Ã  la base de donnÃ©es des patterns d'erreurs.
#>

# Importer le module d'analyse des patterns d'erreur
`$modulePath = "$modulePath"
Import-Module `$modulePath -Force

# Fonction pour traiter les erreurs de test
function Invoke-TestErrors {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [array]`$TestResults
    )
    
    `$errors = @()
    
    foreach (`$result in `$TestResults | Where-Object { `$_.Status -eq "Failed" }) {
        # CrÃ©er un objet d'erreur
        `$error = @{
            Source = "TestOmnibus"
            Message = `$result.ErrorMessage
            StackTrace = `$result.StackTrace
            Timestamp = Get-Date
            TestName = `$result.TestName
        }
        
        `$errors += `$error
    }
    
    # Analyser les erreurs
    foreach (`$error in `$errors) {
        # CrÃ©er un objet ErrorRecord
        `$exception = New-Object System.Exception `$error.Message
        `$errorRecord = New-Object System.Management.Automation.ErrorRecord(
            `$exception,
            "TestOmnibusError",
            [System.Management.Automation.ErrorCategory]::NotSpecified,
            `$null
        )
        
        # Ajouter des informations supplÃ©mentaires
        `$errorRecord.PSObject.Properties.Add(
            (New-Object System.Management.Automation.PSNoteProperty "ScriptStackTrace", `$error.StackTrace)
        )
        
        if (`$error.TestName) {
            `$errorRecord.PSObject.Properties.Add(
                (New-Object System.Management.Automation.PSNoteProperty "TestName", `$error.TestName)
            )
        }
        
        # Ajouter l'erreur Ã  la base de donnÃ©es
        `$patternId = Add-ErrorRecord -ErrorRecord `$errorRecord -Source `$error.Source -Context "TestOmnibus"
        
        Write-Verbose "Erreur analysÃ©e: `$(`$error.Message) (Pattern: `$patternId)"
    }
    
    # GÃ©nÃ©rer un rapport si des erreurs ont Ã©tÃ© trouvÃ©es
    if (`$errors.Count -gt 0) {
        `$reportPath = Join-Path -Path `$PSScriptRoot -ChildPath "..\reports\error_patterns_`$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
        New-ErrorPatternReport -OutputPath `$reportPath -OnlyInedited
        
        Write-Host "Rapport d'analyse des patterns d'erreur gÃ©nÃ©rÃ©: `$reportPath" -ForegroundColor Green
    }
}

# Exporter la fonction pour TestOmnibus
Export-ModuleMember -function Invoke-TestErrors
"@
    
    $hookContent | Out-File -FilePath $hookPath -Encoding utf8
    
    Write-Host "Hook d'intÃ©gration crÃ©Ã©: $hookPath" -ForegroundColor Green
    
    return $hookPath
}

# Fonction pour crÃ©er un rapport d'intÃ©gration
function New-IntegrationReport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [array]$PatternIds,
        
        [Parameter(Mandatory = $true)]
        [string]$ReportPath
    )
    
    # Obtenir les patterns uniques
    $uniquePatternIds = $PatternIds | Select-Object -Unique
    
    # Obtenir les dÃ©tails des patterns
    $patterns = @()
    
    foreach ($patternId in $uniquePatternIds) {
        $pattern = Get-ErrorPattern -PatternId $patternId -IncludeExamples
        
        if ($pattern) {
            $patterns += $pattern
        }
    }
    
    # CrÃ©er le rapport
    $report = @"
# Rapport d'intÃ©gration avec TestOmnibus
*GÃ©nÃ©rÃ© le $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")*

## RÃ©sumÃ©
- Nombre total d'erreurs analysÃ©es: $($PatternIds.Count)
- Nombre de patterns uniques: $($uniquePatternIds.Count)
- Patterns inÃ©dits: $($patterns | Where-Object { $_.IsInedited } | Measure-Object | Select-Object -ExpandProperty Count)

## Patterns d'erreur dÃ©tectÃ©s
$(foreach ($pattern in $patterns) {
    $patternText = "### $($pattern.Name)`n"
    $patternText += "- **Description**: $($pattern.Description)`n"
    $patternText += "- **Occurrences**: $($pattern.Occurrences)`n"
    $patternText += "- **InÃ©dit**: $($pattern.IsInedited)`n"
    $patternText += "- **Statut de validation**: $($pattern.ValidationStatus)`n`n"
    
    if ($pattern.Examples.Count -gt 0) {
        $patternText += "#### Exemple d'erreur:`n"
        $patternText += "````n"
        $patternText += "$($pattern.Examples[0].Message)`n"
        $patternText += "````n`n"
    }
    
    $patternText
})

## IntÃ©gration avec TestOmnibus
Un hook d'intÃ©gration a Ã©tÃ© crÃ©Ã© pour TestOmnibus. Ce hook permet d'analyser automatiquement les erreurs de test et de les ajouter Ã  la base de donnÃ©es des patterns d'erreurs.

### FonctionnalitÃ©s
- Analyse automatique des erreurs aprÃ¨s chaque exÃ©cution de tests
- DÃ©tection des patterns d'erreurs inÃ©dits
- GÃ©nÃ©ration de rapports d'analyse

### Avantages
- AmÃ©lioration de la dÃ©tection des erreurs
- RÃ©duction du temps de dÃ©bogage
- Identification proactive des problÃ¨mes potentiels
"@
    
    $report | Out-File -FilePath $ReportPath -Encoding utf8
    
    Write-Host "Rapport d'intÃ©gration gÃ©nÃ©rÃ©: $ReportPath" -ForegroundColor Green
    
    return $ReportPath
}

# ExÃ©cution principale
Write-Host "IntÃ©gration du systÃ¨me d'analyse des patterns d'erreurs inÃ©dits avec TestOmnibus" -ForegroundColor Cyan

# Extraire les erreurs des logs de TestOmnibus
$errors = Get-TestOmnibusErrors -TestOmnibusPath $TestOmnibusPath

# Analyser les erreurs et les ajouter Ã  la base de donnÃ©es
$patternIds = Add-TestOmnibusErrors -Errors $errors

# CrÃ©er un hook d'intÃ©gration avec TestOmnibus
$hookPath = New-TestOmnibusHook -TestOmnibusPath $TestOmnibusPath

# CrÃ©er un rapport d'intÃ©gration
$reportPath = New-IntegrationReport -PatternIds $patternIds -ReportPath $ReportPath

Write-Host "IntÃ©gration terminÃ©e avec succÃ¨s." -ForegroundColor Green
Write-Host "Rapport d'intÃ©gration: $ReportPath" -ForegroundColor Green
Write-Host "Hook d'intÃ©gration: $hookPath" -ForegroundColor Green

