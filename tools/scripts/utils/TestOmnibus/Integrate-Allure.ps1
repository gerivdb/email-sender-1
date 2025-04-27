<#
.SYNOPSIS
    IntÃ¨gre TestOmnibus avec Allure.
.DESCRIPTION
    Ce script intÃ¨gre TestOmnibus avec Allure en gÃ©nÃ©rant des rapports Allure
    et en les publiant sur un serveur Allure.
.PARAMETER TestPath
    Chemin vers les tests Ã  exÃ©cuter.
.PARAMETER AllureServerUrl
    L'URL du serveur Allure (optionnel).
.PARAMETER AllureResultsPath
    Chemin oÃ¹ enregistrer les rÃ©sultats Allure.
.PARAMETER AllureReportPath
    Chemin oÃ¹ gÃ©nÃ©rer le rapport Allure.
.PARAMETER OpenReport
    Ouvre le rapport Allure aprÃ¨s sa gÃ©nÃ©ration.
.PARAMETER InstallAllure
    Installe Allure s'il n'est pas dÃ©jÃ  installÃ©.
.EXAMPLE
    .\Integrate-Allure.ps1 -TestPath "D:\Tests" -OpenReport
.EXAMPLE
    .\Integrate-Allure.ps1 -TestPath "D:\Tests" -AllureServerUrl "http://allure.example.com" -InstallAllure
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TestPath,
    
    [Parameter(Mandatory = $false)]
    [string]$AllureServerUrl,
    
    [Parameter(Mandatory = $false)]
    [string]$AllureResultsPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\allure-results"),
    
    [Parameter(Mandatory = $false)]
    [string]$AllureReportPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\allure-report"),
    
    [Parameter(Mandatory = $false)]
    [switch]$OpenReport,
    
    [Parameter(Mandatory = $false)]
    [switch]$InstallAllure
)

# VÃ©rifier que le chemin des tests existe
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

# CrÃ©er les rÃ©pertoires de sortie s'ils n'existent pas
if (-not (Test-Path -Path $AllureResultsPath)) {
    New-Item -Path $AllureResultsPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $AllureReportPath)) {
    New-Item -Path $AllureReportPath -ItemType Directory -Force | Out-Null
}

# VÃ©rifier si Allure est installÃ©
$allureInstalled = $false
try {
    $allureVersion = & allure --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $allureInstalled = $true
        Write-Host "Allure est installÃ©: $allureVersion" -ForegroundColor Green
    }
}
catch {
    Write-Warning "Allure n'est pas installÃ©."
}

# Installer Allure si demandÃ©
if (-not $allureInstalled -and $InstallAllure) {
    Write-Host "Installation d'Allure..." -ForegroundColor Cyan
    
    # VÃ©rifier si Chocolatey est installÃ©
    $chocoInstalled = $false
    try {
        $chocoVersion = & choco --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $chocoInstalled = $true
            Write-Host "Chocolatey est installÃ©: $chocoVersion" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Chocolatey n'est pas installÃ©."
    }
    
    # Installer Chocolatey si nÃ©cessaire
    if (-not $chocoInstalled) {
        Write-Host "Installation de Chocolatey..." -ForegroundColor Cyan
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            
            $chocoInstalled = $true
            Write-Host "Chocolatey installÃ© avec succÃ¨s." -ForegroundColor Green
        }
        catch {
            Write-Error "Erreur lors de l'installation de Chocolatey: $_"
            Write-Warning "Impossible d'installer Allure. Veuillez l'installer manuellement."
        }
    }
    
    # Installer Allure avec Chocolatey
    if ($chocoInstalled) {
        try {
            & choco install allure -y
            
            # VÃ©rifier si l'installation a rÃ©ussi
            $allureVersion = & allure --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $allureInstalled = $true
                Write-Host "Allure installÃ© avec succÃ¨s: $allureVersion" -ForegroundColor Green
            }
            else {
                Write-Warning "Erreur lors de l'installation d'Allure."
            }
        }
        catch {
            Write-Error "Erreur lors de l'installation d'Allure: $_"
        }
    }
}

# Fonction pour convertir les rÃ©sultats de TestOmnibus au format Allure
function Convert-TestOmnibusToAllure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResultsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$AllureResultsPath
    )
    
    try {
        # Charger les rÃ©sultats de TestOmnibus
        $results = Import-Clixml -Path $ResultsPath
        
        # CrÃ©er un identifiant unique pour cette exÃ©cution
        $executionId = [Guid]::NewGuid().ToString()
        
        # CrÃ©er le fichier environment.properties
        $environmentPath = Join-Path -Path $AllureResultsPath -ChildPath "environment.properties"
        @"
OS=Windows
PowerShell=$($PSVersionTable.PSVersion)
ExecutionId=$executionId
ExecutionDate=$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@ | Out-File -FilePath $environmentPath -Encoding utf8 -Force
        
        # CrÃ©er un fichier de rÃ©sultat pour chaque test
        foreach ($result in $results) {
            $testName = $result.Name
            $testPath = $result.Path
            $success = $result.Success
            $errorMessage = $result.ErrorMessage
            $duration = $result.Duration
            $startTime = $result.StartTime
            $endTime = $result.EndTime
            
            # CrÃ©er un identifiant unique pour ce test
            $testId = [Guid]::NewGuid().ToString()
            
            # CrÃ©er le fichier de rÃ©sultat au format Allure
            $resultPath = Join-Path -Path $AllureResultsPath -ChildPath "$testId-result.json"
            
            $allureResult = @{
                uuid = $testId
                historyId = [Guid]::NewGuid().ToString()
                name = $testName
                fullName = $testPath
                status = if ($success) { "passed" } else { "failed" }
                stage = "finished"
                start = [long]([DateTime]::Parse($startTime) - [DateTime]::Parse("1970-01-01")).TotalMilliseconds
                stop = [long]([DateTime]::Parse($endTime) - [DateTime]::Parse("1970-01-01")).TotalMilliseconds
                labels = @(
                    @{
                        name = "suite"
                        value = "TestOmnibus"
                    },
                    @{
                        name = "framework"
                        value = "TestOmnibus"
                    },
                    @{
                        name = "language"
                        value = "PowerShell"
                    }
                )
                steps = @()
                parameters = @()
                links = @()
            }
            
            # Ajouter les dÃ©tails d'erreur si le test a Ã©chouÃ©
            if (-not $success) {
                $allureResult.statusDetails = @{
                    known = $false
                    muted = $false
                    flaky = $false
                    message = $errorMessage
                    trace = ""
                }
            }
            
            # Enregistrer le rÃ©sultat au format JSON
            $allureResult | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultPath -Encoding utf8 -Force
        }
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de la conversion des rÃ©sultats au format Allure: $_"
        return $false
    }
}

# ExÃ©cuter TestOmnibus
Write-Host "ExÃ©cution de TestOmnibus..." -ForegroundColor Cyan
$testOmnibusPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"

if (-not (Test-Path -Path $testOmnibusPath)) {
    Write-Error "TestOmnibus n'existe pas: $testOmnibusPath"
    return 1
}

# ExÃ©cuter TestOmnibus
$testOmnibusParams = @{
    Path = $TestPath
}

$result = & $testOmnibusPath @testOmnibusParams

# VÃ©rifier si des rÃ©sultats ont Ã©tÃ© gÃ©nÃ©rÃ©s
$resultsPath = Join-Path -Path (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results") -ChildPath "results.xml"
if (-not (Test-Path -Path $resultsPath)) {
    Write-Error "Aucun rÃ©sultat n'a Ã©tÃ© gÃ©nÃ©rÃ© par TestOmnibus."
    return 1
}

# Convertir les rÃ©sultats au format Allure
Write-Host "Conversion des rÃ©sultats au format Allure..." -ForegroundColor Cyan
$conversionSuccess = Convert-TestOmnibusToAllure -ResultsPath $resultsPath -AllureResultsPath $AllureResultsPath

if (-not $conversionSuccess) {
    Write-Error "Erreur lors de la conversion des rÃ©sultats au format Allure."
    return 1
}

# GÃ©nÃ©rer le rapport Allure si Allure est installÃ©
if ($allureInstalled) {
    Write-Host "GÃ©nÃ©ration du rapport Allure..." -ForegroundColor Cyan
    & allure generate $AllureResultsPath -o $AllureReportPath --clean
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Rapport Allure gÃ©nÃ©rÃ© avec succÃ¨s dans $AllureReportPath" -ForegroundColor Green
        
        # Ouvrir le rapport si demandÃ©
        if ($OpenReport) {
            Write-Host "Ouverture du rapport Allure..." -ForegroundColor Cyan
            & allure open $AllureReportPath
        }
    }
    else {
        Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport Allure."
        return 1
    }
}
else {
    Write-Warning "Allure n'est pas installÃ©. Le rapport Allure n'a pas Ã©tÃ© gÃ©nÃ©rÃ©."
    Write-Warning "Pour installer Allure, utilisez le paramÃ¨tre -InstallAllure ou consultez https://docs.qameta.io/allure/"
}

# Publier le rapport sur un serveur Allure si une URL est fournie
if ($AllureServerUrl) {
    Write-Host "Publication du rapport Allure sur $AllureServerUrl..." -ForegroundColor Cyan
    
    if ($allureInstalled) {
        # CrÃ©er une archive des rÃ©sultats Allure
        $archivePath = "allure-results.zip"
        Compress-Archive -Path "$AllureResultsPath\*" -DestinationPath $archivePath -Force
        
        try {
            # Envoyer l'archive au serveur Allure
            $response = Invoke-RestMethod -Uri "$AllureServerUrl/allure-docker-service/send-results" -Method Post -InFile $archivePath -ContentType "application/zip"
            
            if ($response.status -eq "OK") {
                Write-Host "RÃ©sultats publiÃ©s avec succÃ¨s sur le serveur Allure." -ForegroundColor Green
                Write-Host "URL du rapport: $AllureServerUrl/allure-docker-service/latest-report" -ForegroundColor Cyan
            }
            else {
                Write-Error "Erreur lors de la publication des rÃ©sultats sur le serveur Allure: $($response.message)"
                return 1
            }
        }
        catch {
            Write-Error "Erreur lors de la publication des rÃ©sultats sur le serveur Allure: $_"
            return 1
        }
        finally {
            # Supprimer l'archive temporaire
            if (Test-Path $archivePath) {
                Remove-Item $archivePath -Force
            }
        }
    }
    else {
        Write-Warning "Allure n'est pas installÃ©. Impossible de publier les rÃ©sultats sur le serveur Allure."
    }
}

return 0
