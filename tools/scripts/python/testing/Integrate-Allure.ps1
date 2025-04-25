#Requires -Version 5.1
<#
.SYNOPSIS
    Intègre TestOmnibus avec Allure.
.DESCRIPTION
    Ce script intègre TestOmnibus avec Allure en générant des rapports Allure
    et en les publiant sur un serveur Allure.
.PARAMETER TestDirectory
    Le répertoire contenant les tests Python.
.PARAMETER AllureServerUrl
    L'URL du serveur Allure (optionnel).
.PARAMETER OpenReport
    Ouvre le rapport Allure après sa génération.
.PARAMETER InstallAllure
    Installe Allure s'il n'est pas déjà installé.
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

# Vérifier si Allure est installé
$allureInstalled = $false
try {
    $allureVersion = & allure --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $allureInstalled = $true
        Write-Host "Allure est installé: $allureVersion" -ForegroundColor Green
    }
} catch {
    $allureInstalled = $false
}

# Installer Allure si nécessaire
if (-not $allureInstalled -and $InstallAllure) {
    Write-Host "Installation d'Allure..." -ForegroundColor Cyan
    
    # Vérifier si Scoop est installé
    $scoopInstalled = $false
    try {
        $scoopVersion = & scoop --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $scoopInstalled = $true
        }
    } catch {
        $scoopInstalled = $false
    }
    
    # Installer Scoop si nécessaire
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
            Write-Host "Allure a été installé avec succès." -ForegroundColor Green
        } else {
            Write-Error "Impossible d'installer Allure avec Scoop."
            Write-Host "Veuillez installer Allure manuellement: https://docs.qameta.io/allure/" -ForegroundColor Red
            return 1
        }
    }
}

# Vérifier si le module allure-pytest est installé
$allurePytestInstalled = $false
try {
    $pipList = & python -m pip list 2>&1
    if ($pipList -match "allure-pytest") {
        $allurePytestInstalled = $true
        Write-Host "Le module allure-pytest est installé." -ForegroundColor Green
    } else {
        Write-Host "Installation du module allure-pytest..." -ForegroundColor Yellow
        & python -m pip install allure-pytest
        
        if ($LASTEXITCODE -eq 0) {
            $allurePytestInstalled = $true
            Write-Host "Le module allure-pytest a été installé avec succès." -ForegroundColor Green
        } else {
            Write-Error "Impossible d'installer le module allure-pytest."
            return 1
        }
    }
} catch {
    Write-Error "Erreur lors de la vérification du module allure-pytest: $_"
    return 1
}

# Définir le répertoire des résultats Allure
$allureDir = "allure-results"

# Exécuter TestOmnibus avec l'option Allure
Write-Host "Exécution de TestOmnibus avec génération de rapports Allure..." -ForegroundColor Cyan
$testOmnibusScript = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"
& $testOmnibusScript -TestDirectory $TestDirectory -GenerateAllureReport -AllureDirectory $allureDir -Analyze -GenerateReport

# Vérifier si des résultats Allure ont été générés
if (-not (Test-Path -Path $allureDir) -or (Get-ChildItem -Path $allureDir).Count -eq 0) {
    Write-Error "Aucun résultat Allure n'a été généré."
    return 1
}

# Générer le rapport Allure
$allureReportDir = "allure-report"
if ($allureInstalled) {
    Write-Host "Génération du rapport Allure..." -ForegroundColor Cyan
    & allure generate $allureDir -o $allureReportDir --clean
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Rapport Allure généré avec succès dans $allureReportDir" -ForegroundColor Green
        
        # Ouvrir le rapport si demandé
        if ($OpenReport) {
            Write-Host "Ouverture du rapport Allure..." -ForegroundColor Cyan
            & allure open $allureReportDir
        }
    } else {
        Write-Error "Erreur lors de la génération du rapport Allure."
        return 1
    }
} else {
    Write-Warning "Allure n'est pas installé. Le rapport Allure n'a pas été généré."
    Write-Warning "Pour installer Allure, utilisez le paramètre -InstallAllure ou consultez https://docs.qameta.io/allure/"
}

# Publier le rapport sur un serveur Allure si une URL est fournie
if ($AllureServerUrl) {
    Write-Host "Publication du rapport Allure sur $AllureServerUrl..." -ForegroundColor Cyan
    
    if ($allureInstalled) {
        # Créer une archive des résultats Allure
        $archivePath = "allure-results.zip"
        Compress-Archive -Path "$allureDir\*" -DestinationPath $archivePath -Force
        
        try {
            # Envoyer l'archive au serveur Allure
            $response = Invoke-RestMethod -Uri "$AllureServerUrl/allure-docker-service/send-results" -Method Post -InFile $archivePath -ContentType "application/zip"
            
            if ($response.status -eq "OK") {
                Write-Host "Résultats publiés avec succès sur le serveur Allure." -ForegroundColor Green
                Write-Host "URL du rapport: $AllureServerUrl/allure-docker-service/latest-report" -ForegroundColor Cyan
            } else {
                Write-Error "Erreur lors de la publication des résultats sur le serveur Allure: $($response.message)"
                return 1
            }
        } catch {
            Write-Error "Erreur lors de la publication des résultats sur le serveur Allure: $_"
            return 1
        } finally {
            # Supprimer l'archive temporaire
            if (Test-Path $archivePath) {
                Remove-Item $archivePath -Force
            }
        }
    } else {
        Write-Error "Allure n'est pas installé. Impossible de publier les résultats sur le serveur Allure."
        return 1
    }
}

return 0
