# Script pour vérifier la compatibilité de Wait-ForCompletedRunspace avec PowerShell 5.1
# Ce script analyse le code de Wait-ForCompletedRunspace pour vérifier sa compatibilité avec PowerShell 5.1

# Paramètres
param(
    [switch]$Verbose
)

# Fonction pour afficher les messages
function Write-TestMessage {
    param(
        [string]$Message,
        [string]$Type = "Info"
    )

    $color = switch ($Type) {
        "Info" { "White" }
        "Success" { "Green" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Header" { "Cyan" }
        default { "White" }
    }

    Write-Host $Message -ForegroundColor $color
}

# Fonction pour extraire le code de Wait-ForCompletedRunspace
function Get-FunctionCode {
    param(
        [string]$ModulePath,
        [string]$FunctionName
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $ModulePath)) {
        Write-TestMessage "Le fichier $ModulePath n'existe pas." -Type "Error"
        return $null
    }

    # Lire le contenu du module
    $moduleContent = Get-Content -Path $ModulePath -Raw

    # Extraire le code de la fonction
    $pattern = "function\s+$FunctionName\s*\{[\s\S]*?^}"
    $matches = [regex]::Matches($moduleContent, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)
    
    if ($matches.Count -gt 0) {
        return $matches[0].Value
    } else {
        Write-TestMessage "Fonction $FunctionName non trouvée dans le module." -Type "Error"
        return $null
    }
}

# Fonction pour analyser la compatibilité du code
function Test-FunctionCompatibility {
    param(
        [string]$FunctionCode
    )

    if ([string]::IsNullOrEmpty($FunctionCode)) {
        Write-TestMessage "Code de fonction vide." -Type "Error"
        return $false
    }

    # Vérifier les fonctionnalités spécifiques à PowerShell 7.x
    $ps7Features = @(
        'ForEach-Object\s+-Parallel',
        '-ThrottleLimit',
        'using\s+namespace',
        '\$\w+\s*=\s*\$null\s*\?\?\s*',
        '\$\w+\s*\?\.\w+',
        '\$\w+\s*\?\[\w+\]'
    )
    
    # Vérifier les fonctionnalités compatibles avec PowerShell 5.1
    $ps51Features = @(
        '\[System\.Collections\.Generic\.List',
        '\[System\.Collections\.Concurrent\.ConcurrentDictionary',
        '\[System\.Threading\.Thread\]',
        '\[System\.Threading\.Tasks\.Task\]',
        'System\.Threading\.Monitor',
        'RunspacePool'
    )
    
    # Vérifier si des fonctionnalités incompatibles sont utilisées
    $ps7FeaturesFound = @()
    foreach ($feature in $ps7Features) {
        if ($FunctionCode -match $feature) {
            $ps7FeaturesFound += $feature
        }
    }
    
    $ps51FeaturesFound = @()
    foreach ($feature in $ps51Features) {
        if ($FunctionCode -match $feature) {
            $ps51FeaturesFound += $feature
        }
    }

    # Afficher les résultats
    Write-TestMessage "Analyse de compatibilité de la fonction:" -Type "Header"
    
    if ($ps7FeaturesFound.Count -gt 0) {
        Write-TestMessage "Fonctionnalités spécifiques à PowerShell 7.x trouvées:" -Type "Warning"
        foreach ($feature in $ps7FeaturesFound) {
            Write-TestMessage "  - $feature" -Type "Warning"
        }
        $ps7Compatible = $false
    } else {
        Write-TestMessage "Aucune fonctionnalité spécifique à PowerShell 7.x trouvée." -Type "Success"
        $ps7Compatible = $true
    }
    
    if ($ps51FeaturesFound.Count -gt 0) {
        Write-TestMessage "Fonctionnalités compatibles avec PowerShell 5.1 trouvées:" -Type "Success"
        foreach ($feature in $ps51FeaturesFound) {
            Write-TestMessage "  - $feature" -Type "Success"
        }
        $ps51Compatible = $true
    } else {
        Write-TestMessage "Aucune fonctionnalité compatible avec PowerShell 5.1 trouvée." -Type "Warning"
        $ps51Compatible = $false
    }

    # Retourner le résultat
    return @{
        PS51Compatible = $ps51Compatible
        PS7Compatible = $ps7Compatible
        PS7FeaturesFound = $ps7FeaturesFound
        PS51FeaturesFound = $ps51FeaturesFound
    }
}

# Chemin du module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"

# Afficher les informations sur le système
Write-TestMessage "Vérification de la compatibilité de Wait-ForCompletedRunspace avec PowerShell 5.1" -Type "Header"
Write-TestMessage "Version de PowerShell: $($PSVersionTable.PSVersion)" -Type "Info"
Write-TestMessage "Fichier module: $modulePath" -Type "Info"

# Extraire le code de Wait-ForCompletedRunspace
$functionCode = Get-FunctionCode -ModulePath $modulePath -FunctionName "Wait-ForCompletedRunspace"

if ($functionCode) {
    # Analyser la compatibilité du code
    $compatibilityResult = Test-FunctionCompatibility -FunctionCode $functionCode
    
    # Afficher le résumé
    Write-TestMessage "`nRésumé de la compatibilité:" -Type "Header"
    Write-TestMessage "Compatible avec PowerShell 5.1: $(if ($compatibilityResult.PS51Compatible) { 'Oui ✅' } else { 'Non ❌' })" -Type $(if ($compatibilityResult.PS51Compatible) { "Success" } else { "Error" })
    Write-TestMessage "Compatible avec PowerShell 7.x: $(if ($compatibilityResult.PS7Compatible) { 'Oui ✅' } else { 'Non ❌' })" -Type $(if ($compatibilityResult.PS7Compatible) { "Success" } else { "Error" })
    
    # Retourner le résultat global
    $overallResult = $compatibilityResult.PS51Compatible
    Write-TestMessage "`nRésultat global: $(if ($overallResult) { 'Compatible avec PowerShell 5.1 ✅' } else { 'Incompatible avec PowerShell 5.1 ❌' })" -Type $(if ($overallResult) { "Success" } else { "Error" })
    
    return @{
        OverallResult = $overallResult
        PS51Compatible = $compatibilityResult.PS51Compatible
        PS7Compatible = $compatibilityResult.PS7Compatible
        PS7FeaturesFound = $compatibilityResult.PS7FeaturesFound
        PS51FeaturesFound = $compatibilityResult.PS51FeaturesFound
    }
} else {
    Write-TestMessage "`nImpossible d'extraire le code de Wait-ForCompletedRunspace." -Type "Error"
    return @{
        OverallResult = $false
        PS51Compatible = $false
        PS7Compatible = $false
        PS7FeaturesFound = @()
        PS51FeaturesFound = @()
    }
}
