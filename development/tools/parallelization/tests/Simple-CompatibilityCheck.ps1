# Script simple pour vérifier la compatibilité de Wait-ForCompletedRunspace avec différentes versions de PowerShell
# Ce script analyse le code source pour identifier les fonctionnalités spécifiques à certaines versions de PowerShell

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

# Fonction pour analyser le code source
function Test-CodeCompatibility {
    param(
        [string]$ModulePath
    )

    # Vérifier si le fichier existe
    if (-not (Test-Path -Path $ModulePath)) {
        Write-TestMessage "Le fichier $ModulePath n'existe pas." -Type "Error"
        return $false
    }

    # Lire le contenu du module
    $moduleContent = Get-Content -Path $ModulePath -Raw

    # Vérifier les fonctionnalités spécifiques à PowerShell 7.x
    $ps7Features = @(
        'ForEach-Object -Parallel',
        'ThrottleLimit',
        'using namespace System.Collections.Concurrent'
    )
    
    # Vérifier les fonctionnalités compatibles avec PowerShell 5.1
    $ps51Features = @(
        '[System.Collections.Generic.List',
        '[System.Collections.Concurrent.ConcurrentDictionary',
        '[System.Threading.Thread]',
        '[System.Threading.Tasks.Task]'
    )
    
    # Vérifier si des fonctionnalités incompatibles sont utilisées
    $ps7FeaturesFound = $ps7Features | Where-Object { $moduleContent -match [regex]::Escape($_) }
    $ps51FeaturesFound = $ps51Features | Where-Object { $moduleContent -match [regex]::Escape($_) }

    # Afficher les résultats
    Write-TestMessage "Analyse de compatibilité du code source:" -Type "Header"
    
    if ($ps7FeaturesFound) {
        Write-TestMessage "Fonctionnalités spécifiques à PowerShell 7.x trouvées:" -Type "Warning"
        foreach ($feature in $ps7FeaturesFound) {
            Write-TestMessage "  - $feature" -Type "Warning"
        }
        $ps7Compatible = $false
    } else {
        Write-TestMessage "Aucune fonctionnalité spécifique à PowerShell 7.x trouvée." -Type "Success"
        $ps7Compatible = $true
    }
    
    if ($ps51FeaturesFound) {
        Write-TestMessage "Fonctionnalités compatibles avec PowerShell 5.1 trouvées:" -Type "Success"
        foreach ($feature in $ps51FeaturesFound) {
            Write-TestMessage "  - $feature" -Type "Success"
        }
        $ps51Compatible = $true
    } else {
        Write-TestMessage "Aucune fonctionnalité compatible avec PowerShell 5.1 trouvée." -Type "Warning"
        $ps51Compatible = $false
    }

    # Vérifier les fonctions spécifiques
    $waitForCompletedRunspaceContent = $moduleContent -match "function Wait-ForCompletedRunspace[\s\S]*?}"
    
    if ($waitForCompletedRunspaceContent) {
        Write-TestMessage "`nAnalyse de Wait-ForCompletedRunspace:" -Type "Header"
        
        # Vérifier les fonctionnalités spécifiques dans Wait-ForCompletedRunspace
        $waitPs7FeaturesFound = $ps7Features | Where-Object { $waitForCompletedRunspaceContent -match [regex]::Escape($_) }
        
        if ($waitPs7FeaturesFound) {
            Write-TestMessage "Fonctionnalités spécifiques à PowerShell 7.x trouvées dans Wait-ForCompletedRunspace:" -Type "Warning"
            foreach ($feature in $waitPs7FeaturesFound) {
                Write-TestMessage "  - $feature" -Type "Warning"
            }
            $waitPs7Compatible = $false
        } else {
            Write-TestMessage "Aucune fonctionnalité spécifique à PowerShell 7.x trouvée dans Wait-ForCompletedRunspace." -Type "Success"
            $waitPs7Compatible = $true
        }
    } else {
        Write-TestMessage "Fonction Wait-ForCompletedRunspace non trouvée dans le module." -Type "Error"
        $waitPs7Compatible = $false
    }

    # Retourner le résultat global
    return @{
        PS51Compatible = $ps51Compatible
        PS7Compatible = $ps7Compatible
        WaitPS7Compatible = $waitPs7Compatible
        PS7FeaturesFound = $ps7FeaturesFound
        PS51FeaturesFound = $ps51FeaturesFound
    }
}

# Fonction pour vérifier la version de PowerShell
function Test-PowerShellVersion {
    # Afficher la version de PowerShell
    $psVersion = $PSVersionTable.PSVersion
    Write-TestMessage "Version de PowerShell: $psVersion" -Type "Info"
    
    # Vérifier si c'est PowerShell Core (7.x) ou Windows PowerShell (5.1)
    if ($psVersion.Major -ge 6) {
        Write-TestMessage "PowerShell Core (7.x) détecté." -Type "Info"
        $isPSCore = $true
    } else {
        Write-TestMessage "Windows PowerShell (5.1) détecté." -Type "Info"
        $isPSCore = $false
    }
    
    return @{
        Version = $psVersion
        IsPSCore = $isPSCore
    }
}

# Chemin du module
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"

# Afficher les informations sur le système
Write-TestMessage "Vérification de la compatibilité de Wait-ForCompletedRunspace" -Type "Header"
$psInfo = Test-PowerShellVersion

# Analyser le code source
$codeCompatibility = Test-CodeCompatibility -ModulePath $modulePath

# Afficher le résumé
Write-TestMessage "`nRésumé de la compatibilité:" -Type "Header"
Write-TestMessage "Compatible avec PowerShell 5.1: $(if ($codeCompatibility.PS51Compatible) { 'Oui ✅' } else { 'Non ❌' })" -Type $(if ($codeCompatibility.PS51Compatible) { "Success" } else { "Error" })
Write-TestMessage "Compatible avec PowerShell 7.x: $(if ($codeCompatibility.PS7Compatible) { 'Oui ✅' } else { 'Non ❌' })" -Type $(if ($codeCompatibility.PS7Compatible) { "Success" } else { "Error" })
Write-TestMessage "Wait-ForCompletedRunspace compatible avec PowerShell 5.1: $(if ($codeCompatibility.WaitPS7Compatible) { 'Oui ✅' } else { 'Non ❌' })" -Type $(if ($codeCompatibility.WaitPS7Compatible) { "Success" } else { "Error" })

# Retourner le résultat global
$overallResult = $codeCompatibility.PS51Compatible -and $codeCompatibility.PS7Compatible -and $codeCompatibility.WaitPS7Compatible
Write-TestMessage "`nRésultat global: $(if ($overallResult) { 'Compatible avec toutes les versions ✅' } else { 'Incompatible avec certaines versions ❌' })" -Type $(if ($overallResult) { "Success" } else { "Error" })

return @{
    OverallResult = $overallResult
    PS51Compatible = $codeCompatibility.PS51Compatible
    PS7Compatible = $codeCompatibility.PS7Compatible
    WaitPS7Compatible = $codeCompatibility.WaitPS7Compatible
    PS7FeaturesFound = $codeCompatibility.PS7FeaturesFound
    PS51FeaturesFound = $codeCompatibility.PS51FeaturesFound
    PSVersion = $psInfo.Version
    IsPSCore = $psInfo.IsPSCore
}
