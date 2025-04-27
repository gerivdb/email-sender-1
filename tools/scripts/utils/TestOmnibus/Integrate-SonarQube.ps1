<#
.SYNOPSIS
    IntÃ¨gre TestOmnibus avec SonarQube.
.DESCRIPTION
    Ce script intÃ¨gre TestOmnibus avec SonarQube en gÃ©nÃ©rant des rapports au format
    compatible avec SonarQube et en les publiant sur un serveur SonarQube.
.PARAMETER TestPath
    Chemin vers les tests Ã  exÃ©cuter.
.PARAMETER SourcePath
    Chemin vers les fichiers source Ã  analyser.
.PARAMETER SonarQubeUrl
    L'URL du serveur SonarQube.
.PARAMETER SonarQubeToken
    Le token d'authentification SonarQube.
.PARAMETER ProjectKey
    La clÃ© du projet SonarQube.
.PARAMETER ProjectName
    Le nom du projet SonarQube.
.PARAMETER OutputPath
    Chemin oÃ¹ enregistrer les rÃ©sultats de l'analyse.
.PARAMETER SimulationMode
    Active le mode simulation (ne tente pas rÃ©ellement de se connecter Ã  SonarQube).
.EXAMPLE
    .\Integrate-SonarQube.ps1 -TestPath "D:\Tests" -SourcePath "D:\Source" -SonarQubeUrl "http://sonarqube.example.com" -SonarQubeToken "token" -ProjectKey "testomnibus" -ProjectName "TestOmnibus"
.EXAMPLE
    .\Integrate-SonarQube.ps1 -TestPath "D:\Tests" -SourcePath "D:\Source" -SonarQubeUrl "http://sonarqube.example.com" -SonarQubeToken "token" -ProjectKey "testomnibus" -ProjectName "TestOmnibus" -SimulationMode
.NOTES
    Auteur: Augment Agent
    Date: 2025-04-12
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$TestPath,
    
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    
    [Parameter(Mandatory = $true)]
    [string]$SonarQubeUrl,
    
    [Parameter(Mandatory = $true)]
    [string]$SonarQubeToken,
    
    [Parameter(Mandatory = $true)]
    [string]$ProjectKey,
    
    [Parameter(Mandatory = $true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\SonarQube"),
    
    [Parameter(Mandatory = $false)]
    [switch]$SimulationMode
)

# VÃ©rifier que les chemins existent
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

if (-not (Test-Path -Path $SourcePath)) {
    Write-Error "Le chemin des sources n'existe pas: $SourcePath"
    return 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# VÃ©rifier si SonarScanner est installÃ©
$sonarScannerInstalled = $false
try {
    $sonarScannerVersion = & sonar-scanner --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $sonarScannerInstalled = $true
        Write-Host "SonarScanner est installÃ©: $sonarScannerVersion" -ForegroundColor Green
    }
}
catch {
    Write-Warning "SonarScanner n'est pas installÃ©."
}

# Installer SonarScanner si nÃ©cessaire
if (-not $sonarScannerInstalled) {
    Write-Host "Installation de SonarScanner..." -ForegroundColor Cyan
    
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
            Write-Warning "Impossible d'installer SonarScanner. Veuillez l'installer manuellement."
        }
    }
    
    # Installer SonarScanner avec Chocolatey
    if ($chocoInstalled) {
        try {
            & choco install sonarscanner-msbuild-net46 -y
            
            # VÃ©rifier si l'installation a rÃ©ussi
            $sonarScannerVersion = & sonar-scanner --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $sonarScannerInstalled = $true
                Write-Host "SonarScanner installÃ© avec succÃ¨s: $sonarScannerVersion" -ForegroundColor Green
            }
            else {
                Write-Warning "Erreur lors de l'installation de SonarScanner."
            }
        }
        catch {
            Write-Error "Erreur lors de l'installation de SonarScanner: $_"
        }
    }
}

# Fonction pour convertir les rÃ©sultats de TestOmnibus au format SonarQube
function Convert-TestOmnibusToSonarQube {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResultsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    try {
        # Charger les rÃ©sultats de TestOmnibus
        $results = Import-Clixml -Path $ResultsPath
        
        # CrÃ©er le document XML pour les rÃ©sultats des tests
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDeclaration = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
        $xmlDoc.AppendChild($xmlDeclaration) | Out-Null
        
        # CrÃ©er l'Ã©lÃ©ment racine
        $testExecutionsElement = $xmlDoc.CreateElement("testExecutions")
        $testExecutionsElement.SetAttribute("version", "1")
        $xmlDoc.AppendChild($testExecutionsElement) | Out-Null
        
        # CrÃ©er un Ã©lÃ©ment pour le fichier de test
        $fileElement = $xmlDoc.CreateElement("file")
        $fileElement.SetAttribute("path", "TestOmnibus")
        $testExecutionsElement.AppendChild($fileElement) | Out-Null
        
        # Ajouter les rÃ©sultats des tests
        foreach ($result in $results) {
            $testCaseElement = $xmlDoc.CreateElement("testCase")
            $testCaseElement.SetAttribute("name", $result.Name)
            $testCaseElement.SetAttribute("duration", [math]::Round($result.Duration / 1000, 3))
            
            # Ajouter les dÃ©tails d'Ã©chec si le test a Ã©chouÃ©
            if (-not $result.Success) {
                $failureElement = $xmlDoc.CreateElement("failure")
                $failureElement.SetAttribute("message", $result.ErrorMessage)
                $testCaseElement.AppendChild($failureElement) | Out-Null
            }
            
            $fileElement.AppendChild($testCaseElement) | Out-Null
        }
        
        # Enregistrer le document XML
        $testResultsPath = Join-Path -Path $OutputPath -ChildPath "test-results.xml"
        $xmlDoc.Save($testResultsPath)
        
        return $testResultsPath
    }
    catch {
        Write-Error "Erreur lors de la conversion des rÃ©sultats au format SonarQube: $_"
        return $null
    }
}

# Fonction pour crÃ©er le fichier de configuration SonarQube
function New-SonarQubeConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $true)]
        [string]$SonarQubeUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$SonarQubeToken,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectKey,
        
        [Parameter(Mandatory = $true)]
        [string]$ProjectName,
        
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,
        
        [Parameter(Mandatory = $true)]
        [string]$TestResultsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$CoveragePath
    )
    
    try {
        # CrÃ©er le fichier de configuration
        $configPath = Join-Path -Path $OutputPath -ChildPath "sonar-project.properties"
        
        $configContent = @"
# Configuration SonarQube pour TestOmnibus
sonar.projectKey=$ProjectKey
sonar.projectName=$ProjectName
sonar.projectVersion=1.0

# Sources
sonar.sources=$SourcePath
sonar.sourceEncoding=UTF-8

# Tests
sonar.tests=$TestPath
sonar.testExecutionReportPaths=$TestResultsPath
sonar.powershell.coverage.reportPaths=$CoveragePath

# Serveur SonarQube
sonar.host.url=$SonarQubeUrl
sonar.login=$SonarQubeToken
"@
        
        # Enregistrer le fichier de configuration
        $configContent | Out-File -FilePath $configPath -Encoding utf8 -Force
        
        return $configPath
    }
    catch {
        Write-Error "Erreur lors de la crÃ©ation du fichier de configuration SonarQube: $_"
        return $null
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

# VÃ©rifier si un fichier de couverture a Ã©tÃ© gÃ©nÃ©rÃ©
$coveragePath = Join-Path -Path (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results") -ChildPath "coverage.xml"
if (-not (Test-Path -Path $coveragePath)) {
    Write-Warning "Aucun fichier de couverture n'a Ã©tÃ© gÃ©nÃ©rÃ© par TestOmnibus."
    $coveragePath = $null
}

# Convertir les rÃ©sultats au format SonarQube
Write-Host "Conversion des rÃ©sultats au format SonarQube..." -ForegroundColor Cyan
$sonarQubeTestResultsPath = Convert-TestOmnibusToSonarQube -ResultsPath $resultsPath -OutputPath $OutputPath

if (-not $sonarQubeTestResultsPath) {
    Write-Error "Erreur lors de la conversion des rÃ©sultats au format SonarQube."
    return 1
}

Write-Host "RÃ©sultats SonarQube gÃ©nÃ©rÃ©s: $sonarQubeTestResultsPath" -ForegroundColor Green

# CrÃ©er le fichier de configuration SonarQube
Write-Host "CrÃ©ation du fichier de configuration SonarQube..." -ForegroundColor Cyan
$sonarQubeConfigPath = New-SonarQubeConfig -OutputPath $OutputPath -SonarQubeUrl $SonarQubeUrl -SonarQubeToken $SonarQubeToken -ProjectKey $ProjectKey -ProjectName $ProjectName -SourcePath $SourcePath -TestResultsPath $sonarQubeTestResultsPath -CoveragePath $coveragePath

if (-not $sonarQubeConfigPath) {
    Write-Error "Erreur lors de la crÃ©ation du fichier de configuration SonarQube."
    return 1
}

Write-Host "Fichier de configuration SonarQube crÃ©Ã©: $sonarQubeConfigPath" -ForegroundColor Green

# ExÃ©cuter SonarScanner
Write-Host "ExÃ©cution de SonarScanner..." -ForegroundColor Cyan

try {
    # VÃ©rifier si le mode simulation est activÃ©
    if ($SimulationMode) {
        # Simuler l'exÃ©cution de SonarScanner
        Write-Host "Mode simulation activÃ©. Aucune analyse SonarQube ne sera effectuÃ©e." -ForegroundColor Yellow
        Write-Host "La commande suivante serait exÃ©cutÃ©e:" -ForegroundColor Yellow
        Write-Host "sonar-scanner -Dproject.settings=$sonarQubeConfigPath" -ForegroundColor Yellow
        Write-Host "Simulation rÃ©ussie." -ForegroundColor Green
    }
    else {
        # ExÃ©cuter SonarScanner
        if ($sonarScannerInstalled) {
            # Changer le rÃ©pertoire courant pour l'exÃ©cution de SonarScanner
            $currentDirectory = Get-Location
            Set-Location -Path $OutputPath
            
            # ExÃ©cuter SonarScanner
            & sonar-scanner -Dproject.settings=$sonarQubeConfigPath
            
            # Restaurer le rÃ©pertoire courant
            Set-Location -Path $currentDirectory
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Analyse SonarQube terminÃ©e avec succÃ¨s." -ForegroundColor Green
                Write-Host "URL du projet: $SonarQubeUrl/dashboard?id=$ProjectKey" -ForegroundColor Cyan
            }
            else {
                Write-Error "Erreur lors de l'exÃ©cution de SonarScanner."
                return 1
            }
        }
        else {
            Write-Warning "SonarScanner n'est pas installÃ©. Impossible d'exÃ©cuter l'analyse SonarQube."
        }
    }
}
catch {
    Write-Error "Erreur lors de l'exÃ©cution de SonarScanner: $_"
    return 1
}

return 0
