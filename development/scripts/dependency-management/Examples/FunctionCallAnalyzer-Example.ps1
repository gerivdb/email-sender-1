# Exemple d'utilisation du module FunctionCallAnalyzer

# Importer le module
$moduleRoot = Split-Path -Parent $PSScriptRoot
$modulePath = Join-Path -Path $moduleRoot -ChildPath "FunctionCallAnalyzer.psm1"
Import-Module -Name $modulePath -Force

# Définir le chemin du script à analyser
# Remplacer par le chemin d'un script réel
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "SampleScript.ps1"

# Créer un script d'exemple si le fichier n'existe pas
if (-not (Test-Path -Path $scriptPath)) {
    $sampleScript = @'
function Get-UserInfo {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeGroups
    )
    
    Write-Verbose "Récupération des informations pour l'utilisateur: $Username"
    
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
    
    Write-Verbose "Récupération de l'utilisateur: $Identity"
    
    # Simulation de récupération d'utilisateur
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
    
    Write-Verbose "Récupération des groupes pour l'utilisateur: $Username"
    
    # Simulation de récupération de groupes
    return @(
        "Utilisateurs",
        "Développeurs",
        "Accès VPN"
    )
}

function Remove-UserAccess {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Username
    )
    
    Write-Verbose "Suppression des accès pour l'utilisateur: $Username"
    
    # Cette fonction n'est pas appelée dans ce script
}

# Appel de fonction en dehors d'une fonction
$userInfo = Get-UserInfo -Username "jdoe" -IncludeGroups
Write-Output $userInfo
'@
    
    Set-Content -Path $scriptPath -Value $sampleScript
    Write-Host "Script d'exemple créé: $scriptPath"
}

# 1. Analyser les appels de fonction
Write-Host "`n=== Analyse des appels de fonction ===" -ForegroundColor Cyan
$functionCalls = Get-FunctionCallAnalysis -ScriptPath $scriptPath
Write-Host "Appels de fonction détectés: $($functionCalls.Count)"
$functionCalls | Format-Table -Property Name, Line, Column, Parameters

# 2. Analyser les définitions de fonction
Write-Host "`n=== Analyse des définitions de fonction ===" -ForegroundColor Cyan
$functionDefinitions = Get-FunctionDefinitionAnalysis -ScriptPath $scriptPath -IncludeParameters
Write-Host "Fonctions définies: $($functionDefinitions.Count)"
$functionDefinitions | Format-Table -Property Name, Line, EndLine

# Afficher les paramètres de chaque fonction
foreach ($function in $functionDefinitions) {
    Write-Host "`nParamètres de la fonction $($function.Name):" -ForegroundColor Yellow
    $function.Parameters | Format-Table -Property Name, Type, Mandatory
}

# 3. Comparer les définitions et les appels
Write-Host "`n=== Comparaison des définitions et des appels ===" -ForegroundColor Cyan
$comparison = Compare-FunctionDefinitionsAndCalls -ScriptPath $scriptPath -IncludeParameters
Write-Host "Fonctions définies mais non appelées: $($comparison.DefinedButNotCalled.Count)"
$comparison.DefinedButNotCalled | Format-Table -Property Name, Line

# 4. Créer un graphe de dépendances
Write-Host "`n=== Graphe de dépendances de fonctions ===" -ForegroundColor Cyan
$outputDir = Join-Path -Path $PSScriptRoot -ChildPath "Output"
if (-not (Test-Path -Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory | Out-Null
}

# Exporter le graphe dans différents formats
$textOutputPath = Join-Path -Path $outputDir -ChildPath "FunctionDependencies.txt"
$jsonOutputPath = Join-Path -Path $outputDir -ChildPath "FunctionDependencies.json"
$dotOutputPath = Join-Path -Path $outputDir -ChildPath "FunctionDependencies.dot"
$htmlOutputPath = Join-Path -Path $outputDir -ChildPath "FunctionDependencies.html"

$graph = New-FunctionDependencyGraph -ScriptPath $scriptPath -OutputPath $textOutputPath -OutputFormat "Text"
New-FunctionDependencyGraph -ScriptPath $scriptPath -OutputPath $jsonOutputPath -OutputFormat "JSON"
New-FunctionDependencyGraph -ScriptPath $scriptPath -OutputPath $dotOutputPath -OutputFormat "DOT"
New-FunctionDependencyGraph -ScriptPath $scriptPath -OutputPath $htmlOutputPath -OutputFormat "HTML"

Write-Host "Graphe de dépendances exporté dans les formats suivants:"
Write-Host "- Texte: $textOutputPath"
Write-Host "- JSON: $jsonOutputPath"
Write-Host "- DOT: $dotOutputPath"
Write-Host "- HTML: $htmlOutputPath"

# Afficher le graphe de dépendances
Write-Host "`nGraphe de dépendances:" -ForegroundColor Yellow
foreach ($function in $graph.Graph.Keys | Sort-Object) {
    Write-Host "$function dépend de: $($graph.Graph[$function] -join ', ')"
}
