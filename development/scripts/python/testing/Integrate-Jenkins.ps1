#Requires -Version 5.1
<#
.SYNOPSIS
    IntÃƒÂ¨gre TestOmnibus avec Jenkins.
.DESCRIPTION
    Ce script intÃƒÂ¨gre TestOmnibus avec Jenkins en gÃƒÂ©nÃƒÂ©rant des rapports JUnit
    et en les publiant sur un serveur Jenkins.
.PARAMETER TestDirectory
    Le rÃƒÂ©pertoire contenant les tests Python.
.PARAMETER JenkinsUrl
    L'URL du serveur Jenkins.
.PARAMETER JenkinsJob
    Le nom du job Jenkins.
.PARAMETER JenkinsToken
    Le token d'authentification Jenkins.
.PARAMETER JenkinsUser
    Le nom d'utilisateur Jenkins.
.PARAMETER SimulationMode
    Active le mode simulation (ne tente pas rÃƒÂ©ellement de se connecter ÃƒÂ  Jenkins).
.EXAMPLE
    .\Integrate-Jenkins.ps1 -TestDirectory "development/testing/tests/python" -JenkinsUrl "http://jenkins.example.com" -JenkinsJob "python-tests" -JenkinsToken "token" -JenkinsUser "user"
.EXAMPLE
    .\Integrate-Jenkins.ps1 -TestDirectory "development/testing/tests/python" -JenkinsUrl "http://jenkins.example.com" -JenkinsJob "python-tests" -JenkinsToken "token" -JenkinsUser "user" -SimulationMode
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TestDirectory,

    [Parameter(Mandatory = $true)]
    [string]$JenkinsUrl,

    [Parameter(Mandatory = $true)]
    [string]$JenkinsJob,

    [Parameter(Mandatory = $true)]
    [string]$JenkinsToken,

    [Parameter(Mandatory = $true)]
    [string]$JenkinsUser,

    [Parameter()]
    [switch]$SimulationMode
)

# DÃƒÂ©finir le rÃƒÂ©pertoire des rapports Jenkins
$jenkinsDir = "jenkins-results"

# ExÃƒÂ©cuter TestOmnibus avec l'option Jenkins
Write-Host "ExÃƒÂ©cution de TestOmnibus avec gÃƒÂ©nÃƒÂ©ration de rapports JUnit..." -ForegroundColor Cyan
$testOmnibusScript = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"
& $testOmnibusScript -TestDirectory $TestDirectory -GenerateJenkinsReport -JenkinsDirectory $jenkinsDir -Analyze -GenerateReport

# VÃƒÂ©rifier si des rapports JUnit ont ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ©s
$jenkinsFiles = Get-ChildItem -Path $jenkinsDir -Filter "*.xml" -ErrorAction SilentlyContinue

if ($jenkinsFiles.Count -eq 0) {
    Write-Error "Aucun rapport JUnit n'a ÃƒÂ©tÃƒÂ© gÃƒÂ©nÃƒÂ©rÃƒÂ©. Impossible de publier les rÃƒÂ©sultats sur Jenkins."
    return 1
}

# CrÃƒÂ©er une archive des rapports JUnit
$archivePath = "jenkins-results.zip"
Compress-Archive -Path "$jenkinsDir\*" -DestinationPath $archivePath -Force

# Publier les rÃƒÂ©sultats sur Jenkins
Write-Host "Publication des rÃƒÂ©sultats sur Jenkins..." -ForegroundColor Cyan

try {
    # VÃƒÂ©rifier si le mode simulation est activÃƒÂ©
    if ($SimulationMode) {
        # Simuler l'envoi ÃƒÂ  Jenkins
        Write-Host "Mode simulation activÃƒÂ©. Aucune connexion rÃƒÂ©elle ÃƒÂ  Jenkins ne sera effectuÃƒÂ©e." -ForegroundColor Yellow
        Write-Host "Les rÃƒÂ©sultats seraient envoyÃƒÂ©s ÃƒÂ  $JenkinsUrl/job/$JenkinsJob/build" -ForegroundColor Yellow
        Write-Host "Simulation rÃƒÂ©ussie." -ForegroundColor Green
    } else {
        # Construire l'URL de l'API Jenkins
        $apiUrl = "$JenkinsUrl/job/$JenkinsJob/build"

        # CrÃƒÂ©er les informations d'authentification
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $JenkinsUser, $JenkinsToken)))

        # CrÃƒÂ©er les en-tÃƒÂªtes de la requÃƒÂªte
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }

        # Envoyer la requÃƒÂªte ÃƒÂ  Jenkins
        # Utiliser la variable de retour pour ÃƒÂ©viter l'avertissement
        $jenkinsResponse = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Post -InFile $archivePath -ContentType "application/zip"

        # Afficher des informations sur la rÃƒÂ©ponse si nÃƒÂ©cessaire
        if ($jenkinsResponse) {
            Write-Verbose "RÃƒÂ©ponse de Jenkins: $jenkinsResponse"
        }

        Write-Host "RÃƒÂ©sultats publiÃƒÂ©s avec succÃƒÂ¨s sur Jenkins." -ForegroundColor Green
    }

    Write-Host "URL du job: $JenkinsUrl/job/$JenkinsJob" -ForegroundColor Cyan
} catch {
    Write-Error "Erreur lors de la publication des rÃƒÂ©sultats sur Jenkins: $_"
    return 1
} finally {
    # Supprimer l'archive temporaire
    if (Test-Path $archivePath) {
        Remove-Item $archivePath -Force
    }
}

return 0
