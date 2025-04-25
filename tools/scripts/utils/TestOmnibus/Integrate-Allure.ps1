<#
.SYNOPSIS
    Intègre TestOmnibus avec Allure.
.DESCRIPTION
    Ce script intègre TestOmnibus avec Allure en générant des rapports Allure
    et en les publiant sur un serveur Allure.
.PARAMETER TestPath
    Chemin vers les tests à exécuter.
.PARAMETER AllureServerUrl
    L'URL du serveur Allure (optionnel).
.PARAMETER AllureResultsPath
    Chemin où enregistrer les résultats Allure.
.PARAMETER AllureReportPath
    Chemin où générer le rapport Allure.
.PARAMETER OpenReport
    Ouvre le rapport Allure après sa génération.
.PARAMETER InstallAllure
    Installe Allure s'il n'est pas déjà installé.
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

# Vérifier que le chemin des tests existe
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

# Créer les répertoires de sortie s'ils n'existent pas
if (-not (Test-Path -Path $AllureResultsPath)) {
    New-Item -Path $AllureResultsPath -ItemType Directory -Force | Out-Null
}

if (-not (Test-Path -Path $AllureReportPath)) {
    New-Item -Path $AllureReportPath -ItemType Directory -Force | Out-Null
}

# Vérifier si Allure est installé
$allureInstalled = $false
try {
    $allureVersion = & allure --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $allureInstalled = $true
        Write-Host "Allure est installé: $allureVersion" -ForegroundColor Green
    }
}
catch {
    Write-Warning "Allure n'est pas installé."
}

# Installer Allure si demandé
if (-not $allureInstalled -and $InstallAllure) {
    Write-Host "Installation d'Allure..." -ForegroundColor Cyan
    
    # Vérifier si Chocolatey est installé
    $chocoInstalled = $false
    try {
        $chocoVersion = & choco --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            $chocoInstalled = $true
            Write-Host "Chocolatey est installé: $chocoVersion" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "Chocolatey n'est pas installé."
    }
    
    # Installer Chocolatey si nécessaire
    if (-not $chocoInstalled) {
        Write-Host "Installation de Chocolatey..." -ForegroundColor Cyan
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            
            $chocoInstalled = $true
            Write-Host "Chocolatey installé avec succès." -ForegroundColor Green
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
            
            # Vérifier si l'installation a réussi
            $allureVersion = & allure --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $allureInstalled = $true
                Write-Host "Allure installé avec succès: $allureVersion" -ForegroundColor Green
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

# Fonction pour convertir les résultats de TestOmnibus au format Allure
function Convert-TestOmnibusToAllure {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResultsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$AllureResultsPath
    )
    
    try {
        # Charger les résultats de TestOmnibus
        $results = Import-Clixml -Path $ResultsPath
        
        # Créer un identifiant unique pour cette exécution
        $executionId = [Guid]::NewGuid().ToString()
        
        # Créer le fichier environment.properties
        $environmentPath = Join-Path -Path $AllureResultsPath -ChildPath "environment.properties"
        @"
OS=Windows
PowerShell=$($PSVersionTable.PSVersion)
ExecutionId=$executionId
ExecutionDate=$(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@ | Out-File -FilePath $environmentPath -Encoding utf8 -Force
        
        # Créer un fichier de résultat pour chaque test
        foreach ($result in $results) {
            $testName = $result.Name
            $testPath = $result.Path
            $success = $result.Success
            $errorMessage = $result.ErrorMessage
            $duration = $result.Duration
            $startTime = $result.StartTime
            $endTime = $result.EndTime
            
            # Créer un identifiant unique pour ce test
            $testId = [Guid]::NewGuid().ToString()
            
            # Créer le fichier de résultat au format Allure
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
            
            # Ajouter les détails d'erreur si le test a échoué
            if (-not $success) {
                $allureResult.statusDetails = @{
                    known = $false
                    muted = $false
                    flaky = $false
                    message = $errorMessage
                    trace = ""
                }
            }
            
            # Enregistrer le résultat au format JSON
            $allureResult | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultPath -Encoding utf8 -Force
        }
        
        return $true
    }
    catch {
        Write-Error "Erreur lors de la conversion des résultats au format Allure: $_"
        return $false
    }
}

# Exécuter TestOmnibus
Write-Host "Exécution de TestOmnibus..." -ForegroundColor Cyan
$testOmnibusPath = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"

if (-not (Test-Path -Path $testOmnibusPath)) {
    Write-Error "TestOmnibus n'existe pas: $testOmnibusPath"
    return 1
}

# Exécuter TestOmnibus
$testOmnibusParams = @{
    Path = $TestPath
}

$result = & $testOmnibusPath @testOmnibusParams

# Vérifier si des résultats ont été générés
$resultsPath = Join-Path -Path (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results") -ChildPath "results.xml"
if (-not (Test-Path -Path $resultsPath)) {
    Write-Error "Aucun résultat n'a été généré par TestOmnibus."
    return 1
}

# Convertir les résultats au format Allure
Write-Host "Conversion des résultats au format Allure..." -ForegroundColor Cyan
$conversionSuccess = Convert-TestOmnibusToAllure -ResultsPath $resultsPath -AllureResultsPath $AllureResultsPath

if (-not $conversionSuccess) {
    Write-Error "Erreur lors de la conversion des résultats au format Allure."
    return 1
}

# Générer le rapport Allure si Allure est installé
if ($allureInstalled) {
    Write-Host "Génération du rapport Allure..." -ForegroundColor Cyan
    & allure generate $AllureResultsPath -o $AllureReportPath --clean
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Rapport Allure généré avec succès dans $AllureReportPath" -ForegroundColor Green
        
        # Ouvrir le rapport si demandé
        if ($OpenReport) {
            Write-Host "Ouverture du rapport Allure..." -ForegroundColor Cyan
            & allure open $AllureReportPath
        }
    }
    else {
        Write-Error "Erreur lors de la génération du rapport Allure."
        return 1
    }
}
else {
    Write-Warning "Allure n'est pas installé. Le rapport Allure n'a pas été généré."
    Write-Warning "Pour installer Allure, utilisez le paramètre -InstallAllure ou consultez https://docs.qameta.io/allure/"
}

# Publier le rapport sur un serveur Allure si une URL est fournie
if ($AllureServerUrl) {
    Write-Host "Publication du rapport Allure sur $AllureServerUrl..." -ForegroundColor Cyan
    
    if ($allureInstalled) {
        # Créer une archive des résultats Allure
        $archivePath = "allure-results.zip"
        Compress-Archive -Path "$AllureResultsPath\*" -DestinationPath $archivePath -Force
        
        try {
            # Envoyer l'archive au serveur Allure
            $response = Invoke-RestMethod -Uri "$AllureServerUrl/allure-docker-service/send-results" -Method Post -InFile $archivePath -ContentType "application/zip"
            
            if ($response.status -eq "OK") {
                Write-Host "Résultats publiés avec succès sur le serveur Allure." -ForegroundColor Green
                Write-Host "URL du rapport: $AllureServerUrl/allure-docker-service/latest-report" -ForegroundColor Cyan
            }
            else {
                Write-Error "Erreur lors de la publication des résultats sur le serveur Allure: $($response.message)"
                return 1
            }
        }
        catch {
            Write-Error "Erreur lors de la publication des résultats sur le serveur Allure: $_"
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
        Write-Warning "Allure n'est pas installé. Impossible de publier les résultats sur le serveur Allure."
    }
}

return 0
