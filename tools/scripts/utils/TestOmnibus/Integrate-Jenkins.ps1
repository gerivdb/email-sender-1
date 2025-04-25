<#
.SYNOPSIS
    Intègre TestOmnibus avec Jenkins.
.DESCRIPTION
    Ce script intègre TestOmnibus avec Jenkins en générant des rapports JUnit
    et en les publiant sur un serveur Jenkins.
.PARAMETER TestPath
    Chemin vers les tests à exécuter.
.PARAMETER JenkinsUrl
    L'URL du serveur Jenkins.
.PARAMETER JenkinsJob
    Le nom du job Jenkins.
.PARAMETER JenkinsToken
    Le token d'authentification Jenkins.
.PARAMETER JenkinsUser
    Le nom d'utilisateur Jenkins.
.PARAMETER JenkinsResultsPath
    Chemin où enregistrer les résultats Jenkins.
.PARAMETER SimulationMode
    Active le mode simulation (ne tente pas réellement de se connecter à Jenkins).
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

# Vérifier que le chemin des tests existe
if (-not (Test-Path -Path $TestPath)) {
    Write-Error "Le chemin des tests n'existe pas: $TestPath"
    return 1
}

# Créer le répertoire de sortie s'il n'existe pas
if (-not (Test-Path -Path $JenkinsResultsPath)) {
    New-Item -Path $JenkinsResultsPath -ItemType Directory -Force | Out-Null
}

# Fonction pour convertir les résultats de TestOmnibus au format JUnit
function Convert-TestOmnibusToJUnit {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ResultsPath,
        
        [Parameter(Mandatory = $true)]
        [string]$JenkinsResultsPath
    )
    
    try {
        # Charger les résultats de TestOmnibus
        $results = Import-Clixml -Path $ResultsPath
        
        # Créer le document XML
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDeclaration = $xmlDoc.CreateXmlDeclaration("1.0", "UTF-8", $null)
        $xmlDoc.AppendChild($xmlDeclaration) | Out-Null
        
        # Créer l'élément racine
        $testSuiteElement = $xmlDoc.CreateElement("testsuite")
        $testSuiteElement.SetAttribute("name", "TestOmnibus")
        $testSuiteElement.SetAttribute("tests", $results.Count)
        $testSuiteElement.SetAttribute("failures", ($results | Where-Object { -not $_.Success }).Count)
        $testSuiteElement.SetAttribute("errors", "0")
        $testSuiteElement.SetAttribute("skipped", "0")
        $testSuiteElement.SetAttribute("timestamp", (Get-Date -Format "yyyy-MM-ddTHH:mm:ss"))
        $testSuiteElement.SetAttribute("time", [math]::Round(($results | Measure-Object -Property Duration -Sum).Sum / 1000, 3))
        $xmlDoc.AppendChild($testSuiteElement) | Out-Null
        
        # Ajouter les résultats des tests
        foreach ($result in $results) {
            $testCaseElement = $xmlDoc.CreateElement("testcase")
            $testCaseElement.SetAttribute("name", $result.Name)
            $testCaseElement.SetAttribute("classname", "TestOmnibus")
            $testCaseElement.SetAttribute("time", [math]::Round($result.Duration / 1000, 3))
            
            # Ajouter les détails d'échec si le test a échoué
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
        Write-Error "Erreur lors de la conversion des résultats au format JUnit: $_"
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

# Convertir les résultats au format JUnit
Write-Host "Conversion des résultats au format JUnit..." -ForegroundColor Cyan
$junitPath = Convert-TestOmnibusToJUnit -ResultsPath $resultsPath -JenkinsResultsPath $JenkinsResultsPath

if (-not $junitPath) {
    Write-Error "Erreur lors de la conversion des résultats au format JUnit."
    return 1
}

Write-Host "Résultats JUnit générés: $junitPath" -ForegroundColor Green

# Publier les résultats sur Jenkins
Write-Host "Publication des résultats sur Jenkins..." -ForegroundColor Cyan

try {
    # Vérifier si le mode simulation est activé
    if ($SimulationMode) {
        # Simuler l'envoi à Jenkins
        Write-Host "Mode simulation activé. Aucune connexion réelle à Jenkins ne sera effectuée." -ForegroundColor Yellow
        Write-Host "Les résultats seraient envoyés à $JenkinsUrl/job/$JenkinsJob/build" -ForegroundColor Yellow
        Write-Host "Simulation réussie." -ForegroundColor Green
    }
    else {
        # Créer une archive des résultats JUnit
        $archivePath = Join-Path -Path $env:TEMP -ChildPath "jenkins-results.zip"
        Compress-Archive -Path "$JenkinsResultsPath\*" -DestinationPath $archivePath -Force
        
        # Construire l'URL de l'API Jenkins
        $apiUrl = "$JenkinsUrl/job/$JenkinsJob/build"
        
        # Créer les informations d'authentification
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $JenkinsUser, $JenkinsToken)))
        
        # Créer les en-têtes de la requête
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }
        
        # Envoyer la requête à Jenkins
        $jenkinsResponse = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Post -InFile $archivePath -ContentType "application/zip"
        
        # Afficher des informations sur la réponse si nécessaire
        if ($jenkinsResponse) {
            Write-Verbose "Réponse de Jenkins: $jenkinsResponse"
        }
        
        Write-Host "Résultats publiés avec succès sur Jenkins." -ForegroundColor Green
        
        # Supprimer l'archive temporaire
        if (Test-Path $archivePath) {
            Remove-Item $archivePath -Force
        }
    }
    
    Write-Host "URL du job: $JenkinsUrl/job/$JenkinsJob" -ForegroundColor Cyan
}
catch {
    Write-Error "Erreur lors de la publication des résultats sur Jenkins: $_"
    return 1
}

return 0
