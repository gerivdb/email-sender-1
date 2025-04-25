#Requires -Version 5.1
<#
.SYNOPSIS
    Intègre TestOmnibus avec Jenkins.
.DESCRIPTION
    Ce script intègre TestOmnibus avec Jenkins en générant des rapports JUnit
    et en les publiant sur un serveur Jenkins.
.PARAMETER TestDirectory
    Le répertoire contenant les tests Python.
.PARAMETER JenkinsUrl
    L'URL du serveur Jenkins.
.PARAMETER JenkinsJob
    Le nom du job Jenkins.
.PARAMETER JenkinsToken
    Le token d'authentification Jenkins.
.PARAMETER JenkinsUser
    Le nom d'utilisateur Jenkins.
.PARAMETER SimulationMode
    Active le mode simulation (ne tente pas réellement de se connecter à Jenkins).
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

# Définir le répertoire des rapports Jenkins
$jenkinsDir = "jenkins-results"

# Exécuter TestOmnibus avec l'option Jenkins
Write-Host "Exécution de TestOmnibus avec génération de rapports JUnit..." -ForegroundColor Cyan
$testOmnibusScript = Join-Path -Path $PSScriptRoot -ChildPath "Invoke-TestOmnibus.ps1"
& $testOmnibusScript -TestDirectory $TestDirectory -GenerateJenkinsReport -JenkinsDirectory $jenkinsDir -Analyze -GenerateReport

# Vérifier si des rapports JUnit ont été générés
$jenkinsFiles = Get-ChildItem -Path $jenkinsDir -Filter "*.xml" -ErrorAction SilentlyContinue

if ($jenkinsFiles.Count -eq 0) {
    Write-Error "Aucun rapport JUnit n'a été généré. Impossible de publier les résultats sur Jenkins."
    return 1
}

# Créer une archive des rapports JUnit
$archivePath = "jenkins-results.zip"
Compress-Archive -Path "$jenkinsDir\*" -DestinationPath $archivePath -Force

# Publier les résultats sur Jenkins
Write-Host "Publication des résultats sur Jenkins..." -ForegroundColor Cyan

try {
    # Vérifier si le mode simulation est activé
    if ($SimulationMode) {
        # Simuler l'envoi à Jenkins
        Write-Host "Mode simulation activé. Aucune connexion réelle à Jenkins ne sera effectuée." -ForegroundColor Yellow
        Write-Host "Les résultats seraient envoyés à $JenkinsUrl/job/$JenkinsJob/build" -ForegroundColor Yellow
        Write-Host "Simulation réussie." -ForegroundColor Green
    } else {
        # Construire l'URL de l'API Jenkins
        $apiUrl = "$JenkinsUrl/job/$JenkinsJob/build"

        # Créer les informations d'authentification
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $JenkinsUser, $JenkinsToken)))

        # Créer les en-têtes de la requête
        $headers = @{
            Authorization = "Basic $base64AuthInfo"
        }

        # Envoyer la requête à Jenkins
        # Utiliser la variable de retour pour éviter l'avertissement
        $jenkinsResponse = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Post -InFile $archivePath -ContentType "application/zip"

        # Afficher des informations sur la réponse si nécessaire
        if ($jenkinsResponse) {
            Write-Verbose "Réponse de Jenkins: $jenkinsResponse"
        }

        Write-Host "Résultats publiés avec succès sur Jenkins." -ForegroundColor Green
    }

    Write-Host "URL du job: $JenkinsUrl/job/$JenkinsJob" -ForegroundColor Cyan
} catch {
    Write-Error "Erreur lors de la publication des résultats sur Jenkins: $_"
    return 1
} finally {
    # Supprimer l'archive temporaire
    if (Test-Path $archivePath) {
        Remove-Item $archivePath -Force
    }
}

return 0
