#Requires -Version 5.1
<#
.SYNOPSIS
    IntÃ¨gre TestOmnibus avec Jenkins.
.DESCRIPTION
    Ce script intÃ¨gre TestOmnibus avec Jenkins en gÃ©nÃ©rant des rapports JUnit
    et en les publiant sur un serveur Jenkins.
.PARAMETER TestDirectory
    Le rÃ©pertoire contenant les tests Python.
.PARAMETER JenkinsUrl
    L'URL du serveur Jenkins.
.PARAMETER JenkinsJob
    Le nom du job Jenkins.
.PARAMETER JenkinsToken
    Le token d'authentification Jenkins.
.PARAMETER JenkinsUser
    Le nom d'utilisateur Jenkins.
.PARAMETER SimulationMode
    Active le mode simulation (ne tente pas rÃ©ellement de se connecter Ã  Jenkins).
.EXAMPLE
    .\Integrate-Jenkins.ps1 -TestDirectory "tests/python" -JenkinsUrl "http://jenkins.example.com" -JenkinsJob "python-tests" -JenkinsToken "token" -JenkinsUser "user"
.EXAMPLE
    .\Integrate-Jenkins.ps1 -TestDirectory "tests/python" -JenkinsUrl "http://jenkins.example.com" -JenkinsJob "python-tests" -JenkinsToken "token" -JenkinsUser "user" -SimulationMode
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

# DÃ©finir le rÃ©pertoire des rapports Jenkins
$jenkinsDir = "jenkins-results"

# ExÃ©cuter TestOmnibus avec l'option Jenkins
Write-Host "ExÃ©cution de TestOmnibus avec gÃ©nÃ©ration de rapports JUnit..." -ForegroundColor Cyan
$testOmnibusScript = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"
& $testOmnibusScript -TestDirectory $TestDirectory -GenerateJenkinsReport -JenkinsDirectory $jenkinsDir -Analyze -GenerateReport

# VÃ©rifier si des rapports JUnit ont Ã©tÃ© gÃ©nÃ©rÃ©s
$jenkinsFiles = Get-ChildItem -Path $jenkinsDir -Filter "*.xml" -ErrorAction SilentlyContinue

if ($jenkinsFiles.Count -eq 0) {
    Write-Error "Aucun rapport JUnit n'a Ã©tÃ© gÃ©nÃ©rÃ©. Impossible de publier les rÃ©sultats sur Jenkins."
    return 1
}

# CrÃ©er une archive des rapports JUnit
$archivePath = "jenkins-results.zip"
Compress-Archive -Path "$jenkinsDir\*" -DestinationPath $archivePath -Force

# Publier les rÃ©sultats sur Jenkins
Write-Host "Publication des rÃ©sultats sur Jenkins..." -ForegroundColor Cyan

try {
    # VÃ©rifier si le mode simulation est activÃ©
    if ($SimulationMode) {
        # Simuler l'envoi Ã  Jenkins
        Write-Host "Mode simulation activÃ©. Aucune connexion rÃ©elle Ã  Jenkins ne sera effectuÃ©e." -ForegroundColor Yellow
        Write-Host "Les rÃ©sultats seraient envoyÃ©s Ã  $JenkinsUrl/job/$JenkinsJob/build" -ForegroundColor Yellow
        Write-Host "Simulation rÃ©ussie." -ForegroundColor Green
    } else {
        # Construire l'URL de l'API Jenkins
        $apiUrl = "$JenkinsUrl/job/$JenkinsJob/build"

        # CrÃ©er les informations d'authentification
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $JenkinsUser, $JenkinsToken)))

        # CrÃ©er les en-tÃªtes de la requÃªte
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }

        # Envoyer la requÃªte Ã  Jenkins
        # Utiliser la variable de retour pour Ã©viter l'avertissement
        $jenkinsResponse = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Post -InFile $archivePath -ContentType "application/zip"

        # Afficher des informations sur la rÃ©ponse si nÃ©cessaire
        if ($jenkinsResponse) {
            Write-Verbose "RÃ©ponse de Jenkins: $jenkinsResponse"
        }

        Write-Host "RÃ©sultats publiÃ©s avec succÃ¨s sur Jenkins." -ForegroundColor Green
    }

    Write-Host "URL du job: $JenkinsUrl/job/$JenkinsJob" -ForegroundColor Cyan
} catch {
    Write-Error "Erreur lors de la publication des rÃ©sultats sur Jenkins: $_"
    return 1
} finally {
    # Supprimer l'archive temporaire
    if (Test-Path $archivePath) {
        Remove-Item $archivePath -Force
    }
}

return 0
