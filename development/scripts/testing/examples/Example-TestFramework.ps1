#Requires -Version 5.1
<#
.SYNOPSIS
    Exemple d'utilisation du framework de test.
.DESCRIPTION
    Ce script montre comment utiliser le framework de test pour écrire des tests unitaires.
.EXAMPLE
    .\Example-TestFramework.ps1
.NOTES
    Version: 1.0.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

# Importer le module TestFramework
$modulePath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "modules\TestFramework\TestFramework.psm1"
Import-Module $modulePath -Force

# Créer un module de test
$moduleContent = @"
#Requires -Version 5.1
<#
.SYNOPSIS
    Module de test pour l'exemple.
.DESCRIPTION
    Ce module contient des fonctions de test pour l'exemple.
#>

function Get-ExampleData {
    <#
    .SYNOPSIS
        Récupère des données d'exemple.
    .DESCRIPTION
        Récupère des données d'exemple à partir d'un fichier ou d'une API.
    .PARAMETER Path
        Chemin du fichier de données.
    .PARAMETER ApiUrl
        URL de l'API pour récupérer les données.
    .EXAMPLE
        Get-ExampleData -Path "data.json"
    .EXAMPLE
        Get-ExampleData -ApiUrl "https://api.example.com/data"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = "File")]
        [string]$Path,

        [Parameter(Mandatory = $true, ParameterSetName = "Api")]
        [string]$ApiUrl
    )

    if ($PSCmdlet.ParameterSetName -eq "File") {
        if (-not (Test-Path -Path $Path)) {
            throw "Le fichier '$Path' n'existe pas."
        }

        $content = Get-Content -Path $Path -Raw
        return $content | ConvertFrom-Json
    }
    else {
        $response = Invoke-RestMethod -Uri $ApiUrl -Method Get
        return $response
    }
}

function Process-ExampleData {
    <#
    .SYNOPSIS
        Traite des données d'exemple.
    .DESCRIPTION
        Traite des données d'exemple et retourne un résultat.
    .PARAMETER Data
        Données à traiter.
    .EXAMPLE
        Process-ExampleData -Data $data
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Data
    )

    $result = @{
        Count = 0
        Items = @()
        Summary = ""
    }

    if ($Data.items) {
        $result.Count = $Data.items.Count
        $result.Items = $Data.items | Where-Object { $_.active -eq $true }
        $result.Summary = "Processed $($result.Count) items, $($result.Items.Count) active."
    }

    return [PSCustomObject]$result
}

function Save-ExampleResult {
    <#
    .SYNOPSIS
        Sauvegarde un résultat d'exemple.
    .DESCRIPTION
        Sauvegarde un résultat d'exemple dans un fichier.
    .PARAMETER Result
        Résultat à sauvegarder.
    .PARAMETER OutputPath
        Chemin du fichier de sortie.
    .EXAMPLE
        Save-ExampleResult -Result $result -OutputPath "result.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Result,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $Result | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding utf8
    return $OutputPath
}

Export-ModuleMember -Function Get-ExampleData, Process-ExampleData, Save-ExampleResult
"@

# Créer un environnement de test
$env = New-TestEnvironment -TestName "ExampleTest" -Files @{
    "ExampleModule.psm1" = $moduleContent
    "data.json"          = '{"items": [{"id": 1, "name": "Item 1", "active": true}, {"id": 2, "name": "Item 2", "active": false}, {"id": 3, "name": "Item 3", "active": true}]}'
}

# Importer le module de test
$modulePath = Join-Path -Path $env.Path -ChildPath "ExampleModule.psm1"
$testSetup = Invoke-TestSetup -ModuleName "ExampleModule" -ModulePath $modulePath -Force

# Vérifier que les fonctions sont disponibles
$functionCheck = Test-FunctionAvailability -FunctionName "Get-ExampleData", "Process-ExampleData", "Save-ExampleResult"
foreach ($function in $functionCheck.Keys) {
    if ($functionCheck[$function].Available) {
        Write-Host "Fonction '$function' disponible." -ForegroundColor Green
    } else {
        Write-Host "Fonction '$function' non disponible : $($functionCheck[$function].Error)" -ForegroundColor Red
    }
}

# Créer des mocks pour les tests
New-TestMock -CommandName "Invoke-RestMethod" -ParameterFilter { $Uri -eq "https://api.example.com/data" } -MockScript {
    return [PSCustomObject]@{
        items = @(
            [PSCustomObject]@{ id = 1; name = "API Item 1"; active = $true },
            [PSCustomObject]@{ id = 2; name = "API Item 2"; active = $false },
            [PSCustomObject]@{ id = 3; name = "API Item 3"; active = $true }
        )
    }
}

# Tester la fonction Get-ExampleData avec un fichier
$dataPath = Join-Path -Path $env.Path -ChildPath "data.json"
$fileData = Get-ExampleData -Path $dataPath
Write-Host "Données du fichier : $($fileData.items.Count) éléments" -ForegroundColor Cyan

# Tester la fonction Get-ExampleData avec une API
$apiData = Get-ExampleData -ApiUrl "https://api.example.com/data"
Write-Host "Données de l'API : $($apiData.items.Count) éléments" -ForegroundColor Cyan

# Tester la fonction Process-ExampleData
$processedFileData = Process-ExampleData -Data $fileData
Write-Host "Résultat du traitement des données du fichier : $($processedFileData.Summary)" -ForegroundColor Cyan

$processedApiData = Process-ExampleData -Data $apiData
Write-Host "Résultat du traitement des données de l'API : $($processedApiData.Summary)" -ForegroundColor Cyan

# Tester la fonction Save-ExampleResult
$outputPath = Join-Path -Path $env.Path -ChildPath "result.json"
$savedPath = Save-ExampleResult -Result $processedFileData -OutputPath $outputPath
Write-Host "Résultat sauvegardé dans : $savedPath" -ForegroundColor Cyan

# Nettoyer l'environnement
Invoke-TestCleanup -ModuleName "ExampleModule"
$env.Cleanup()

Write-Host "Test terminé avec succès." -ForegroundColor Green
