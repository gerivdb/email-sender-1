<#
.SYNOPSIS
    IntÃ¨gre TestOmnibus avec Jenkins.
.DESCRIPTION
    Ce script intÃ¨gre TestOmnibus avec Jenkins en gÃ©nÃ©rant des rapports JUnit
    et en les publiant sur un serveur Jenkins.
.PARAMETER TestPath
    Chemin vers les tests Ã  exÃ©cuter.
.PARAMETER JenkinsUrl
    L'URL du serveur Jenkins.
.PARAMETER JenkinsJob
    Le nom du job Jenkins.
.PARAMETER JenkinsToken
    Le token d'authentification Jenkins.
.PARAMETER JenkinsUser
    Le nom d'utilisateur Jenkins.
.PARAMETER JenkinsResultsPath
    Chemin oÃ¹ enregistrer les rÃ©sultats Jenkins.
.PARAMETER SimulationMode
    Active le mode simulation (ne tente pas rÃ©ellement de se connecter Ã  Jenkins).
.EXAMPLE
    .\Integrate-Jenkins.ps1 -TestPath "D:\Tests" -JenkinsUrl "http://jenkins.example.com" -JenkinsJob "testomnibus" -JenkinsToken "token" -JenkinsUser "user"
.EXAMPLE
    .\Integrate-Jenkins.ps1 -TestPath "D:\Tests" -JenkinsUrl "http://jenkins.example.com" -JenkinsJob "testomnibus" -JenkinsToken "token" -JenkinsUser "user" -SimulationMode
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
    [string]$JenkinsUrl,
    
    [Parameter(Mandatory = $true)]
    [string]$JenkinsJob,
    
    [Parameter(Mandatory = $true)]
    [string]$JenkinsToken,
    
    [Parameter(Mandatory = $true)]
    [string]$JenkinsUser,
    
    [Parameter(Mandatory = $false)]
    [string]$JenkinsResultsPath = (Join-Path -Path $env:TEMP -ChildPath "TestOmnibus\jenkins-results"),
    
    [Parameter(Mandatory = $false)]
    [switch]$SimulationMode
)

# VÃ©rifier que le chemin des tests existe
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

# CrÃ©er le rÃ©pertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $JenkinsResultsPath)) {
    New-Item -Path $JenkinsResultsPath -ItemType Directory -Force | Out-Null
}

# Fonction pour convertir les rÃ©sultats de TestOmnibus au format JUnit
function Convert-TestOmnibusToJUnit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResultsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$JenkinsResultsPath
    )
    
    try {
        # Charger les rÃ©sultats de TestOmnibus
        $results = Import-Clixml -Path $ResultsPath
        
        # CrÃ©er le document XML
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDeclaration = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
        $xmlDoc.AppendChild($xmlDeclaration) | Out-Null
        
        # CrÃ©er l'Ã©lÃ©ment racine
        $testSuiteElement = $xmlDoc.CreateElement("testsuite")
        $testSuiteElement.SetAttribute("name", "TestOmnibus")
        $testSuiteElement.SetAttribute("tests", $results.Count)
        $testSuiteElement.SetAttribute("failures", ($results | Where-Object { -not $_.Success }).Count)
        $testSuiteElement.SetAttribute("errors", "0")
        $testSuiteElement.SetAttribute("skipped", "0")
        $testSuiteElement.SetAttribute("timestamp", (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"))
        $testSuiteElement.SetAttribute("time", [math]::Round(($results | Measure-Object -Property Duration -Sum).Sum / 1000, 3))
        $xmlDoc.AppendChild($testSuiteElement) | Out-Null
        
        # Ajouter les rÃ©sultats des tests
        foreach ($result in $results) {
            $testCaseElement = $xmlDoc.CreateElement("testcase")
            $testCaseElement.SetAttribute("name", $result.Name)
            $testCaseElement.SetAttribute("classname", "TestOmnibus")
            $testCaseElement.SetAttribute("time", [math]::Round($result.Duration / 1000, 3))
            
            # Ajouter les dÃ©tails d'Ã©chec si le test a Ã©chouÃ©
            if (-not $result.Success) {
                $failureElement = $xmlDoc.CreateElement("failure")
                $failureElement.SetAttribute("message", $result.ErrorMessage)
                $failureElement.SetAttribute("type", "AssertionError")
                $failureElement.InnerText = $result.ErrorMessage
                $testCaseElement.AppendChild($failureElement) | Out-Null
            }
            
            $testSuiteElement.AppendChild($testCaseElement) | Out-Null
        }
        
        # Enregistrer le document XML
        $junitPath = Join-Path -Path $JenkinsResultsPath -ChildPath "junit-results.xml"
        $xmlDoc.Save($junitPath)
        
        return $junitPath
    }
    catch {
        Write-Error "Erreur lors de la conversion des rÃ©sultats au format JUnit: $_"
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

# Convertir les rÃ©sultats au format JUnit
Write-Host "Conversion des rÃ©sultats au format JUnit..." -ForegroundColor Cyan
$junitPath = Convert-TestOmnibusToJUnit -ResultsPath $resultsPath -JenkinsResultsPath $JenkinsResultsPath

if (-not $junitPath) {
    Write-Error "Erreur lors de la conversion des rÃ©sultats au format JUnit."
    return 1
}

Write-Host "RÃ©sultats JUnit gÃ©nÃ©rÃ©s: $junitPath" -ForegroundColor Green

# Publier les rÃ©sultats sur Jenkins
Write-Host "Publication des rÃ©sultats sur Jenkins..." -ForegroundColor Cyan

try {
    # VÃ©rifier si le mode simulation est activÃ©
    if ($SimulationMode) {
        # Simuler l'envoi Ã  Jenkins
        Write-Host "Mode simulation activÃ©. Aucune connexion rÃ©elle Ã  Jenkins ne sera effectuÃ©e." -ForegroundColor Yellow
        Write-Host "Les rÃ©sultats seraient envoyÃ©s Ã  $JenkinsUrl/job/$JenkinsJob/build" -ForegroundColor Yellow
        Write-Host "Simulation rÃ©ussie." -ForegroundColor Green
    }
    else {
        # CrÃ©er une archive des rÃ©sultats JUnit
        $archivePath = Join-Path -Path $env:TEMP -ChildPath "jenkins-results.zip"
        Compress-Archive -Path "$JenkinsResultsPath\*" -DestinationPath $archivePath -Force
        
        # Construire l'URL de l'API Jenkins
        $apiUrl = "$JenkinsUrl/job/$JenkinsJob/build"
        
        # CrÃ©er les informations d'authentification
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $JenkinsUser, $JenkinsToken)))
        
        # CrÃ©er les en-tÃªtes de la requÃªte
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }
        
        # Envoyer la requÃªte Ã  Jenkins
        $jenkinsResponse = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Post -InFile $archivePath -ContentType "application/zip"
        
        # Afficher des informations sur la rÃ©ponse si nÃ©cessaire
        if ($jenkinsResponse) {
            Write-Verbose "RÃ©ponse de Jenkins: $jenkinsResponse"
        }
        
        Write-Host "RÃ©sultats publiÃ©s avec succÃ¨s sur Jenkins." -ForegroundColor Green
        
        # Supprimer l'archive temporaire
        if (Test-Path $archivePath) {
            Remove-Item $archivePath -Force
        }
    }
    
    Write-Host "URL du job: $JenkinsUrl/job/$JenkinsJob" -ForegroundColor Cyan
}
catch {
    Write-Error "Erreur lors de la publication des rÃ©sultats sur Jenkins: $_"
    return 1
}

return 0
