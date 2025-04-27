#Requires -Version 5.1
<#
.SYNOPSIS
    IntÃ¨gre TestOmnibus avec Allure.
.DESCRIPTION
    Ce script intÃ¨gre TestOmnibus avec Allure en gÃ©nÃ©rant des rapports Allure
    et en les publiant sur un serveur Allure.
.PARAMETER TestDirectory
    Le rÃ©pertoire contenant les tests Python.
.PARAMETER AllureServerUrl
    L'URL du serveur Allure (optionnel).
.PARAMETER OpenReport
    Ouvre le rapport Allure aprÃ¨s sa gÃ©nÃ©ration.
.PARAMETER InstallAllure
    Installe Allure s'il n'est pas dÃ©jÃ  installÃ©.
.EXAMPLE
    .\Integrate-Allure.ps1 -TestDirectory "tests/python" -OpenReport
.EXAMPLE
    .\Integrate-Allure.ps1 -TestDirectory "tests/python" -AllureServerUrl "http://allure.example.com" -InstallAllure
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

# VÃ©rifier si Allure est installÃ©
$allureInstalled = $false
try {
    $allureVersion = & allure --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $allureInstalled = $true
        Write-Host "Allure est installÃ©: $allureVersion" -ForegroundColor Green
    }
} catch {
    $allureInstalled = $false
}

# Installer Allure si nÃ©cessaire
if (-not $allureInstalled -and $InstallAllure) {
    Write-Host "Installation d'Allure..." -ForegroundColor Cyan
    
    # VÃ©rifier si Scoop est installÃ©
    $scoopInstalled = $false
    try {
        $scoopVersion = & scoop --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $scoopInstalled = $true
        }
    } catch {
        $scoopInstalled = $false
    }
    
    # Installer Scoop si nÃ©cessaire
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
            Write-Host "Allure a Ã©tÃ© installÃ© avec succÃ¨s." -ForegroundColor Green
        } else {
            Write-Error "Impossible d'installer Allure avec Scoop."
            Write-Host "Veuillez installer Allure manuellement: https://docs.qameta.io/allure/" -ForegroundColor Red
            return 1
        }
    }
}

# VÃ©rifier si le module allure-pytest est installÃ©
$allurePytestInstalled = $false
try {
    $pipList = & python -m pip list 2>&1
    if ($pipList -match "allure-pytest") {
        $allurePytestInstalled = $true
        Write-Host "Le module allure-pytest est installÃ©." -ForegroundColor Green
    } else {
        Write-Host "Installation du module allure-pytest..." -ForegroundColor Yellow
        & python -m pip install allure-pytest
        
        if ($LASTEXITCODE -eq 0) {
            $allurePytestInstalled = $true
            Write-Host "Le module allure-pytest a Ã©tÃ© installÃ© avec succÃ¨s." -ForegroundColor Green
        } else {
            Write-Error "Impossible d'installer le module allure-pytest."
            return 1
        }
    }
} catch {
    Write-Error "Erreur lors de la vÃ©rification du module allure-pytest: $_"
    return 1
}

# DÃ©finir le rÃ©pertoire des rÃ©sultats Allure
$allureDir = "allure-results"

# ExÃ©cuter TestOmnibus avec l'option Allure
Write-Host "ExÃ©cution de TestOmnibus avec gÃ©nÃ©ration de rapports Allure..." -ForegroundColor Cyan
$testOmnibusScript = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"
& $testOmnibusScript -TestDirectory $TestDirectory -GenerateAllureReport -AllureDirectory $allureDir -Analyze -GenerateReport

# VÃ©rifier si des rÃ©sultats Allure ont Ã©tÃ© gÃ©nÃ©rÃ©s
if (-not (Test-Path -Path $allureDir) -or (Get-ChildItem -Path $allureDir).Count -eq 0) {
    Write-Error "Aucun rÃ©sultat Allure n'a Ã©tÃ© gÃ©nÃ©rÃ©."
    return 1
}

# GÃ©nÃ©rer le rapport Allure
$allureReportDir = "allure-report"
if ($allureInstalled) {
    Write-Host "GÃ©nÃ©ration du rapport Allure..." -ForegroundColor Cyan
    & allure generate $allureDir -o $allureReportDir --clean
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Rapport Allure gÃ©nÃ©rÃ© avec succÃ¨s dans $allureReportDir" -ForegroundColor Green
        
        # Ouvrir le rapport si demandÃ©
        if ($OpenReport) {
            Write-Host "Ouverture du rapport Allure..." -ForegroundColor Cyan
            & allure open $allureReportDir
        }
    } else {
        Write-Error "Erreur lors de la gÃ©nÃ©ration du rapport Allure."
        return 1
    }
} else {
    Write-Warning "Allure n'est pas installÃ©. Le rapport Allure n'a pas Ã©tÃ© gÃ©nÃ©rÃ©."
    Write-Warning "Pour installer Allure, utilisez le paramÃ¨tre -InstallAllure ou consultez https://docs.qameta.io/allure/"
}

# Publier le rapport sur un serveur Allure si une URL est fournie
if ($AllureServerUrl) {
    Write-Host "Publication du rapport Allure sur $AllureServerUrl..." -ForegroundColor Cyan
    
    if ($allureInstalled) {
        # CrÃ©er une archive des rÃ©sultats Allure
        $archivePath = "allure-results.zip"
        Compress-Archive -Path "$allureDir\*" -DestinationPath $archivePath -Force
        
        try {
            # Envoyer l'archive au serveur Allure
            $response = Invoke-RestMethod -Uri "$AllureServerUrl/allure-docker-service/send-results" -Method Post -InFile $archivePath -ContentType "application/zip"
            
            if ($response.status -eq "OK") {
                Write-Host "RÃ©sultats publiÃ©s avec succÃ¨s sur le serveur Allure." -ForegroundColor Green
                Write-Host "URL du rapport: $AllureServerUrl/allure-docker-service/latest-report" -ForegroundColor Cyan
            } else {
                Write-Error "Erreur lors de la publication des rÃ©sultats sur le serveur Allure: $($response.message)"
                return 1
            }
        } catch {
            Write-Error "Erreur lors de la publication des rÃ©sultats sur le serveur Allure: $_"
            return 1
        } finally {
            # Supprimer l'archive temporaire
            if (Test-Path $archivePath) {
                Remove-Item $archivePath -Force
            }
        }
    } else {
        Write-Error "Allure n'est pas installÃ©. Impossible de publier les rÃ©sultats sur le serveur Allure."
        return 1
    }
}

return 0
