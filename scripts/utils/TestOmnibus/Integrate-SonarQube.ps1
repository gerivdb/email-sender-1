<#
.SYNOPSIS
    Intègre TestOmnibus avec SonarQube.
.DESCRIPTION
    Ce script intègre TestOmnibus avec SonarQube en générant des rapports au format
    compatible avec SonarQube et en les publiant sur un serveur SonarQube.
.PARAMETER TestPath
    Chemin vers les tests à exécuter.
.PARAMETER SourcePath
    Chemin vers les fichiers source à analyser.
.PARAMETER SonarQubeUrl
    L'URL du serveur SonarQube.
.PARAMETER SonarQubeToken
    Le token d'authentification SonarQube.
.PARAMETER ProjectKey
    La clé du projet SonarQube.
.PARAMETER ProjectName
    Le nom du projet SonarQube.
.PARAMETER OutputPath
    Chemin où enregistrer les résultats de l'analyse.
.PARAMETER SimulationMode
    Active le mode simulation (ne tente pas réellement de se connecter à SonarQube).
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

# Vérifier que les chemins existent
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

if (-not (Test-Path -Path $SourcePath)) {
    Write-Error "Le chemin des sources n'existe pas: $SourcePath"
    return 1
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

# Vérifier si SonarScanner est installé
$sonarScannerInstalled = $false
try {
    $sonarScannerVersion = & sonar-scanner --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        $sonarScannerInstalled = $true
        Write-Host "SonarScanner est installé: $sonarScannerVersion" -ForegroundColor Green
    }
}
catch {
    Write-Warning "SonarScanner n'est pas installé."
}

# Installer SonarScanner si nécessaire
if (-not $sonarScannerInstalled) {
    Write-Host "Installation de SonarScanner..." -ForegroundColor Cyan
    
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
            Write-Warning "Impossible d'installer SonarScanner. Veuillez l'installer manuellement."
        }
    }
    
    # Installer SonarScanner avec Chocolatey
    if ($chocoInstalled) {
        try {
            & choco install sonarscanner-msbuild-net46 -y
            
            # Vérifier si l'installation a réussi
            $sonarScannerVersion = & sonar-scanner --version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $sonarScannerInstalled = $true
                Write-Host "SonarScanner installé avec succès: $sonarScannerVersion" -ForegroundColor Green
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

# Fonction pour convertir les résultats de TestOmnibus au format SonarQube
function Convert-TestOmnibusToSonarQube {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResultsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )
    
    try {
        # Charger les résultats de TestOmnibus
        $results = Import-Clixml -Path $ResultsPath
        
        # Créer le document XML pour les résultats des tests
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDeclaration = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
        $xmlDoc.AppendChild($xmlDeclaration) | Out-Null
        
        # Créer l'élément racine
        $testExecutionsElement = $xmlDoc.CreateElement("testExecutions")
        $testExecutionsElement.SetAttribute("version", "1")
        $xmlDoc.AppendChild($testExecutionsElement) | Out-Null
        
        # Créer un élément pour le fichier de test
        $fileElement = $xmlDoc.CreateElement("file")
        $fileElement.SetAttribute("path", "TestOmnibus")
        $testExecutionsElement.AppendChild($fileElement) | Out-Null
        
        # Ajouter les résultats des tests
        foreach ($result in $results) {
            $testCaseElement = $xmlDoc.CreateElement("testCase")
            $testCaseElement.SetAttribute("name", $result.Name)
            $testCaseElement.SetAttribute("duration", [math]::Round($result.Duration / 1000, 3))
            
            # Ajouter les détails d'échec si le test a échoué
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
        Write-Error "Erreur lors de la conversion des résultats au format SonarQube: $_"
        return $null
    }
}

# Fonction pour créer le fichier de configuration SonarQube
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
        # Créer le fichier de configuration
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
        Write-Error "Erreur lors de la création du fichier de configuration SonarQube: $_"
        return $null
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

# Vérifier si un fichier de couverture a été généré
$coveragePath = Join-Path -Path (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\Results") -ChildPath "coverage.xml"
if (-not (Test-Path -Path $coveragePath)) {
    Write-Warning "Aucun fichier de couverture n'a été généré par TestOmnibus."
    $coveragePath = $null
}

# Convertir les résultats au format SonarQube
Write-Host "Conversion des résultats au format SonarQube..." -ForegroundColor Cyan
$sonarQubeTestResultsPath = Convert-TestOmnibusToSonarQube -ResultsPath $resultsPath -OutputPath $OutputPath

if (-not $sonarQubeTestResultsPath) {
    Write-Error "Erreur lors de la conversion des résultats au format SonarQube."
    return 1
}

Write-Host "Résultats SonarQube générés: $sonarQubeTestResultsPath" -ForegroundColor Green

# Créer le fichier de configuration SonarQube
Write-Host "Création du fichier de configuration SonarQube..." -ForegroundColor Cyan
$sonarQubeConfigPath = New-SonarQubeConfig -OutputPath $OutputPath -SonarQubeUrl $SonarQubeUrl -SonarQubeToken $SonarQubeToken -ProjectKey $ProjectKey -ProjectName $ProjectName -SourcePath $SourcePath -TestResultsPath $sonarQubeTestResultsPath -CoveragePath $coveragePath

if (-not $sonarQubeConfigPath) {
    Write-Error "Erreur lors de la création du fichier de configuration SonarQube."
    return 1
}

Write-Host "Fichier de configuration SonarQube créé: $sonarQubeConfigPath" -ForegroundColor Green

# Exécuter SonarScanner
Write-Host "Exécution de SonarScanner..." -ForegroundColor Cyan

try {
    # Vérifier si le mode simulation est activé
    if ($SimulationMode) {
        # Simuler l'exécution de SonarScanner
        Write-Host "Mode simulation activé. Aucune analyse SonarQube ne sera effectuée." -ForegroundColor Yellow
        Write-Host "La commande suivante serait exécutée:" -ForegroundColor Yellow
        Write-Host "sonar-scanner -Dproject.settings=$sonarQubeConfigPath" -ForegroundColor Yellow
        Write-Host "Simulation réussie." -ForegroundColor Green
    }
    else {
        # Exécuter SonarScanner
        if ($sonarScannerInstalled) {
            # Changer le répertoire courant pour l'exécution de SonarScanner
            $currentDirectory = Get-Location
            Set-Location -Path $OutputPath
            
            # Exécuter SonarScanner
            & sonar-scanner -Dproject.settings=$sonarQubeConfigPath
            
            # Restaurer le répertoire courant
            Set-Location -Path $currentDirectory
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Analyse SonarQube terminée avec succès." -ForegroundColor Green
                Write-Host "URL du projet: $SonarQubeUrl/dashboard?id=$ProjectKey" -ForegroundColor Cyan
            }
            else {
                Write-Error "Erreur lors de l'exécution de SonarScanner."
                return 1
            }
        }
        else {
            Write-Warning "SonarScanner n'est pas installé. Impossible d'exécuter l'analyse SonarQube."
        }
    }
}
catch {
    Write-Error "Erreur lors de l'exécution de SonarScanner: $_"
    return 1
}

return 0
