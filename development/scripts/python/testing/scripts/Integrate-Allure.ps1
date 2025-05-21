#Requires -Version 5.1
<#
.SYNOPSIS
    IntÃƒÂ¨gre TestOmnibus avec Allure.
.DESCRIPTION
    Ce script intÃƒÂ¨gre TestOmnibus avec Allure en gÃƒÂ©nÃƒÂ©rant des rapports Allure
    et en les publiant sur un serveur Allure.
.PARAMETER TestDirectory
    Le rÃƒÂ©pertoire contenant les tests Python.
.PARAMETER AllureServerUrl
    L'URL du serveur Allure (optionnel).
.PARAMETER OpenReport
    Ouvre le rapport Allure aprÃƒÂ¨s sa gÃƒÂ©nÃƒÂ©ration.
.PARAMETER InstallAllure
    Installe Allure s'il n'est pas dÃƒÂ©jÃƒÂ  installÃƒÂ©.
.EXAMPLE
    .\Integrate-Allure.ps1 -TestDirectory "development/testing/tests/python" -OpenReport
.EXAMPLE
    .\Integrate-Allure.ps1 -TestDirectory "development/testing/tests/python" -AllureServerUrl "http://allure.example.com" -InstallAllure
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TestDirectory,
    
    [Parameter()]
    [string]$AllureServerUrl,
    
    [Parameter()]
    [switch]$OpenReport,
    
    [Parameter()]
    [switch]$InstallAllure
)

# VÃƒÂ©rifier si Allure est installÃƒÂ©
$allureInstalled = $false
try {
    $allureVersion = & allure --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $allureInstalled = $true
        Write-Host "Allure est installÃƒÂ©: $allureVersion" -ForegroundColor Green
    }
} catch {
    $allureInstalled = $false
}

# Installer Allure si nÃƒÂ©cessaire
if (-not $allureInstalled -and $InstallAllure) {
    Write-Host "Installation d'Allure..." -ForegroundColor Cyan
    
    # VÃƒÂ©rifier si Scoop est installÃƒÂ©
    $scoopInstalled = $false
    try {
        $scoopVersion = & scoop --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $scoopInstalled = $true
        }
    } catch {
        $scoopInstalled = $false
    }
    
    # Installer Scoop si nÃƒÂ©cessaire
    if (-not $scoopInstalled) {
        Write-Host "Installation de Scoop..." -ForegroundColor Yellow
        try {
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
            $scoopInstalled = $true
        } catch {
            Write-Error "Impossible d'installer Scoop: $_"
            Write-Host "Veuillez installer Allure manuellement: https://docs.qameta.io/allure/" -ForegroundColor Red
            return 1
        }
    }
    
    # Installer Allure avec Scoop
    if ($scoopInstalled) {
        Write-Host "Installation d'Allure avec Scoop..." -ForegroundColor Yellow
        & scoop install allure
        
        if ($LASTEXITCODE -eq 0) {
            $allureInstalled = $true
            Write-Host "Allure a ÃƒÂ©tÃƒÂ© installÃƒÂ© avec succÃƒÂ¨s." -ForegroundColor Green
        } else {
            Write-Error "Impossible d'installer Allure avec Scoop."
            Write-Host "Veuillez installer Allure manuellement: https://docs.qameta.io/allure/" -ForegroundColor Red
            return 1
        }
    }
}

# VÃƒÂ©rifier si le module allure-pytest est installÃƒÂ©
$allurePytestInstalled = $false
try {
    $pipList = & python -m pip list 2>&1
    if ($pipList -match "allure-pytest") {
        $allurePytestInstalled = $true
        Write-Host "Le module allure-pytest est installÃƒÂ©." -ForegroundColor Green
    } else {
        Write-Host "Installation du module allure-pytest..." -ForegroundColor Yellow
        & python -m pip install allure-pytest
        
        if ($LASTEXITCODE -eq 0) {
            $allurePytestInstalled = $true
            Write-Host "Le module allure-pytest a ÃƒÂ©tÃƒÂ© installÃƒÂ© avec succÃƒÂ¨s." -ForegroundColor Green
        } else {
            Write-Error "Impossible d'installer le module allure-pytest."
            return 1
        }
    }
} catch {
    Write-Error "Erreur lors de la vÃƒÂ©rification du module allure-pytest: $_"
    return 1
}

# DÃƒÂ©finir le rÃƒÂ©pertoire des rÃƒÂ©sultats Allure
$allureDir = "allure-results"

# ExÃƒÂ©cuter TestOmnibus avec l'option Allure
Write-Host "ExÃƒÂ©cution de TestOmnibus avec gÃƒÂ©nÃƒÂ©ration de rapports Allure..." -ForegroundColor Cyan
$testOmnibusScript = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"
& $testOmnibusScript -TestDirectory $TestDirectory -GenerateAllureReport -AllureDirectory $allureDir -Analyze -GenerateReport

# VÃƒÂ©rifier si des rÃƒÂ©sultats Allure ont ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ©s
if (-not (Test-Path -Path $allureDir) -or (Get-ChildItem -Path $allureDir).Count -eq 0) {
    Write-Error "Aucun rÃƒÂ©sultat Allure n'a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ©."
    return 1
}

# GÃƒÂ©nÃƒÂ©rer le rapport Allure
$allureReportDir = "allure-report"
if ($allureInstalled) {
    Write-Host "GÃƒÂ©nÃƒÂ©ration du rapport Allure..." -ForegroundColor Cyan
    & allure generate $allureDir -o $allureReportDir --clean
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Rapport Allure gÃƒÂ©nÃƒÂ©rÃƒÂ© avec succÃƒÂ¨s dans $allureReportDir" -ForegroundColor Green
        
        # Ouvrir le rapport si demandÃƒÂ©
        if ($OpenReport) {
            Write-Host "Ouverture du rapport Allure..." -ForegroundColor Cyan
            & allure open $allureReportDir
        }
    } else {
        Write-Error "Erreur lors de la gÃƒÂ©nÃƒÂ©ration du rapport Allure."
        return 1
    }
} else {
    Write-Warning "Allure n'est pas installÃƒÂ©. Le rapport Allure n'a pas ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ©."
    Write-Warning "Pour installer Allure, utilisez le paramÃƒÂ¨tre -InstallAllure ou consultez https://docs.qameta.io/allure/"
}

# Publier le rapport sur un serveur Allure si une URL est fournie
if ($AllureServerUrl) {
    Write-Host "Publication du rapport Allure sur $AllureServerUrl..." -ForegroundColor Cyan
    
    if ($allureInstalled) {
        # CrÃƒÂ©er une archive des rÃƒÂ©sultats Allure
        $archivePath = "allure-results.zip"
        Compress-Archive -Path "$allureDir\*" -DestinationPath $archivePath -Force
        
        try {
            # Envoyer l'archive au serveur Allure
            $response = Invoke-RestMethod -Uri "$AllureServerUrl/allure-docker-service/send-results" -Method Post -InFile $archivePath -ContentType "application/zip"
            
            if ($response.status -eq "OK") {
                Write-Host "RÃƒÂ©sultats publiÃƒÂ©s avec succÃƒÂ¨s sur le serveur Allure." -ForegroundColor Green
                Write-Host "URL du rapport: $AllureServerUrl/allure-docker-service/latest-report" -ForegroundColor Cyan
            } else {
                Write-Error "Erreur lors de la publication des rÃƒÂ©sultats sur le serveur Allure: $($response.message)"
                return 1
            }
        } catch {
            Write-Error "Erreur lors de la publication des rÃƒÂ©sultats sur le serveur Allure: $_"
            return 1
        } finally {
            # Supprimer l'archive temporaire
            if (Test-Path $archivePath) {
                Remove-Item $archivePath -Force
            }
        }
    } else {
        Write-Error "Allure n'est pas installÃƒÂ©. Impossible de publier les rÃƒÂ©sultats sur le serveur Allure."
        return 1
    }
}

return 0
