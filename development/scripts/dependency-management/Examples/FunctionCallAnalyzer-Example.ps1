# Exemple d'utilisation du module FunctionCallAnalyzer

# Importer le module
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "FunctionCallAnalyzer.psm1"
Import-Module -Name $modulePath -Force

# DÃ©finir le chemin du script Ã  analyser
# Remplacer par le chemin d'un script rÃ©el
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "SampleScript.ps1"

# CrÃ©er un script d'exemple si le fichier n'existe pas
if (-not (Test-Path -Path $scriptPath)) {
    $sampleScript = @'
function Get-UserInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeGroups
    )
    
    Write-Verbose "RÃ©cupÃ©ration des informations pour l'utilisateur: $Username"
    
    $user = Get-User -Identity $Username
    $result = [PSCustomObject]@{
        Username = $user.SamAccountName
        DisplayName = $user.DisplayName
        Email = $user.EmailAddress
        Enabled = $user.Enabled
    }
    
    if ($IncludeGroups) {
        $groups = Get-UserGroups -Username $Username
        $result | Add-Member -MemberType NoteProperty -Name "Groups" -Value $groups
    }
    
    return $result
}

function Get-User {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Identity
    )
    
    Write-Verbose "RÃ©cupÃ©ration de l'utilisateur: $Identity"
    
    # Simulation de rÃ©cupÃ©ration d'utilisateur
    return [PSCustomObject]@{
        SamAccountName = $Identity
        DisplayName = "Utilisateur $Identity"
        EmailAddress = "$Identity@example.com"
        Enabled = $true
    }
}

function Get-UserGroups {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username
    )
    
    Write-Verbose "RÃ©cupÃ©ration des groupes pour l'utilisateur: $Username"
    
    # Simulation de rÃ©cupÃ©ration de groupes
    return @(
        "Utilisateurs",
        "DÃ©veloppeurs",
        "AccÃ¨s VPN"
    )
}

function Remove-UserAccess {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username
    )
    
    Write-Verbose "Suppression des accÃ¨s pour l'utilisateur: $Username"
    
    # Cette fonction n'est pas appelÃ©e dans ce script
}

# Appel de fonction en dehors d'une fonction
$userInfo = Get-UserInfo -Username "jdoe" -IncludeGroups
Write-Output $userInfo
'@
    
    Set-Content -Path $scriptPath -Value $sampleScript
    Write-Host "Script d'exemple crÃ©Ã©: $scriptPath"
}

# 1. Analyser les appels de fonction
Write-Host "`n=== Analyse des appels de fonction ===" -ForegroundColor Cyan
$functionCalls = Get-FunctionCallAnalysis -ScriptPath $scriptPath
Write-Host "Appels de fonction dÃ©tectÃ©s: $($functionCalls.Count)"
$functionCalls | Format-Table -Property Name, Line, Column, Parameters

# 2. Analyser les dÃ©finitions de fonction
Write-Host "`n=== Analyse des dÃ©finitions de fonction ===" -ForegroundColor Cyan
$functionDefinitions = Get-FunctionDefinitionAnalysis -ScriptPath $scriptPath -IncludeParameters
Write-Host "Fonctions dÃ©finies: $($functionDefinitions.Count)"
$functionDefinitions | Format-Table -Property Name, Line, EndLine

# Afficher les paramÃ¨tres de chaque fonction
foreach ($function in $functionDefinitions) {
    Write-Host "`nParamÃ¨tres de la fonction $($function.Name):" -ForegroundColor Yellow
    $function.Parameters | Format-Table -Property Name, Type, Mandatory
}

# 3. Comparer les dÃ©finitions et les appels
Write-Host "`n=== Comparaison des dÃ©finitions et des appels ===" -ForegroundColor Cyan
$comparison = Compare-FunctionDefinitionsAndCalls -ScriptPath $scriptPath -IncludeParameters
Write-Host "Fonctions dÃ©finies mais non appelÃ©es: $($comparison.DefinedButNotCalled.Count)"
$comparison.DefinedButNotCalled | Format-Table -Property Name, Line

# 4. CrÃ©er un graphe de dÃ©pendances
Write-Host "`n=== Graphe de dÃ©pendances de fonctions ===" -ForegroundColor Cyan
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "Output"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

# Exporter le graphe dans diffÃ©rents formats
$textOutputPath = Join-Path -Path $outputDir -ChildPath "FunctionDependencies.txt"
$jsonOutputPath = Join-Path -Path $outputDir -ChildPath "FunctionDependencies.json"
$dotOutputPath = Join-Path -Path $outputDir -ChildPath "FunctionDependencies.dot"
$htmlOutputPath = Join-Path -Path $outputDir -ChildPath "FunctionDependencies.html"

$graph = New-FunctionDependencyGraph -ScriptPath $scriptPath -OutputPath $textOutputPath -OutputFormat "Text"
New-FunctionDependencyGraph -ScriptPath $scriptPath -OutputPath $jsonOutputPath -OutputFormat "JSON"
New-FunctionDependencyGraph -ScriptPath $scriptPath -OutputPath $dotOutputPath -OutputFormat "DOT"
New-FunctionDependencyGraph -ScriptPath $scriptPath -OutputPath $htmlOutputPath -OutputFormat "HTML"

Write-Host "Graphe de dÃ©pendances exportÃ© dans les formats suivants:"
Write-Host "- Texte: $textOutputPath"
Write-Host "- JSON: $jsonOutputPath"
Write-Host "- DOT: $dotOutputPath"
Write-Host "- HTML: $htmlOutputPath"

# Afficher le graphe de dÃ©pendances
Write-Host "`nGraphe de dÃ©pendances:" -ForegroundColor Yellow
foreach ($function in $graph.Graph.Keys | Sort-Object) {
    Write-Host "$function dÃ©pend de: $($graph.Graph[$function] -join ', ')"
}
