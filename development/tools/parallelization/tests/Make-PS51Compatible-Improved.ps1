# Script amélioré pour rendre le module UnifiedParallel compatible avec PowerShell 5.1
# Ce script crée une version du module compatible avec PowerShell 5.1

# Paramètres
param(
    [switch]$Verbose,
    [switch]$NoBackup,
    [switch]$Force
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

# Fonction pour créer une version compatible avec PowerShell 5.1
function New-PS51CompatibleModule {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [switch]$NoBackup,
        [switch]$Force
    )

    # Vérifier si le fichier source existe
    if (-not (Test-Path -Path $SourcePath)) {
        Write-TestMessage "Le fichier source $SourcePath n'existe pas." -Type "Error"
        return $false
    }

    # Vérifier si le fichier de destination existe déjà
    if ((Test-Path -Path $DestinationPath) -and -not $Force) {
        Write-TestMessage "Le fichier de destination $DestinationPath existe déjà. Utilisez -Force pour l'écraser." -Type "Error"
        return $false
    }

    # Créer une sauvegarde si demandé
    if (-not $NoBackup) {
        $backupPath = "$SourcePath.bak"
        Copy-Item -Path $SourcePath -Destination $backupPath -Force
        Write-TestMessage "Sauvegarde créée: $backupPath" -Type "Info"
    }

    # Lire le contenu du module
    $moduleContent = Get-Content -Path $SourcePath -Raw

    # Définir les remplacements à effectuer
    $replacements = @(
        # Remplacer ForEach-Object -Parallel par une implémentation compatible avec PS 5.1
        @{
            Pattern = '(ForEach-Object)\s+(-Parallel)'
            Replacement = '# $1 $2 (remplacé pour compatibilité PS 5.1)
            # Utiliser une implémentation compatible avec PS 5.1
            ForEach-Object'
            IsRegex = $true
        },
        # Remplacer ThrottleLimit par une implémentation compatible avec PS 5.1
        @{
            Pattern = '(-ThrottleLimit)\s+(\d+)'
            Replacement = '# $1 $2 (remplacé pour compatibilité PS 5.1)'
            IsRegex = $true
        },
        # Remplacer using namespace par une implémentation compatible avec PS 5.1
        @{
            Pattern = '(using\s+namespace\s+System\.Collections\.Concurrent)'
            Replacement = '# $1 (remplacé pour compatibilité PS 5.1)'
            IsRegex = $true
        },
        # Remplacer l'opérateur de chaînage nul (?.)
        @{
            Pattern = '(\$\w+)\s*\?\.\s*(\w+)'
            Replacement = 'if ($1 -ne $null) { $1.$2 } else { $null }'
            IsRegex = $true
        },
        # Remplacer l'opérateur de coalescence nulle (??)
        @{
            Pattern = '(\$\w+)\s*\?\?\s*(\$\w+|\d+|"[^"]*"|''[^'']*''|\[[^\]]*\]|\{[^\}]*\})'
            Replacement = 'if ($1 -ne $null) { $1 } else { $2 }'
            IsRegex = $true
        }
    )

    # Appliquer les remplacements
    foreach ($replacement in $replacements) {
        if ($replacement.IsRegex) {
            $moduleContent = [regex]::Replace($moduleContent, $replacement.Pattern, $replacement.Replacement)
        } else {
            $moduleContent = $moduleContent -replace [regex]::Escape($replacement.Pattern), $replacement.Replacement
        }
    }

    # Ajouter un commentaire indiquant que c'est une version compatible avec PS 5.1
    $header = @"
# Module UnifiedParallel - Version compatible avec PowerShell 5.1
# Généré automatiquement par Make-PS51Compatible-Improved.ps1
# Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Cette version a été modifiée pour être compatible avec PowerShell 5.1

"@

    $moduleContent = $header + $moduleContent

    # Écrire le contenu dans le fichier de destination
    $moduleContent | Out-File -FilePath $DestinationPath -Encoding utf8 -Force

    Write-TestMessage "Version compatible avec PowerShell 5.1 créée: $DestinationPath" -Type "Success"
    return $true
}

# Fonction pour tester la compatibilité du module
function Test-ModuleCompatibility {
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
        'ForEach-Object\s+-Parallel',
        '-ThrottleLimit\s+\d+',
        'using\s+namespace\s+System\.Collections\.Concurrent',
        '\$\w+\s*\?\.\s*\w+',
        '\$\w+\s*\?\?\s*'
    )
    
    # Vérifier si des fonctionnalités incompatibles sont utilisées
    $ps7FeaturesFound = @()
    foreach ($feature in $ps7Features) {
        if ($moduleContent -match $feature) {
            $ps7FeaturesFound += $feature
        }
    }

    # Afficher les résultats
    Write-TestMessage "Analyse de compatibilité du module:" -Type "Header"
    
    if ($ps7FeaturesFound.Count -gt 0) {
        Write-TestMessage "Fonctionnalités spécifiques à PowerShell 7.x trouvées:" -Type "Warning"
        foreach ($feature in $ps7FeaturesFound) {
            Write-TestMessage "  - $feature" -Type "Warning"
        }
        return $false
    } else {
        Write-TestMessage "Aucune fonctionnalité spécifique à PowerShell 7.x trouvée." -Type "Success"
        return $true
    }
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

# Fonction pour tester la compatibilité de Wait-ForCompletedRunspace
function Test-WaitForCompletedRunspaceCompatibility {
    param(
        [string]$ModulePath
    )

    # Extraire le code de Wait-ForCompletedRunspace
    $functionCode = Get-FunctionCode -ModulePath $ModulePath -FunctionName "Wait-ForCompletedRunspace"
    
    if (-not $functionCode) {
        return $false
    }

    # Vérifier les fonctionnalités spécifiques à PowerShell 7.x
    $ps7Features = @(
        'ForEach-Object\s+-Parallel',
        '-ThrottleLimit\s+\d+',
        'using\s+namespace\s+System\.Collections\.Concurrent',
        '\$\w+\s*\?\.\s*\w+',
        '\$\w+\s*\?\?\s*'
    )
    
    # Vérifier si des fonctionnalités incompatibles sont utilisées
    $ps7FeaturesFound = @()
    foreach ($feature in $ps7Features) {
        if ($functionCode -match $feature) {
            $ps7FeaturesFound += $feature
        }
    }

    # Afficher les résultats
    Write-TestMessage "Analyse de compatibilité de Wait-ForCompletedRunspace:" -Type "Header"
    
    if ($ps7FeaturesFound.Count -gt 0) {
        Write-TestMessage "Fonctionnalités spécifiques à PowerShell 7.x trouvées:" -Type "Warning"
        foreach ($feature in $ps7FeaturesFound) {
            Write-TestMessage "  - $feature" -Type "Warning"
        }
        return $false
    } else {
        Write-TestMessage "Aucune fonctionnalité spécifique à PowerShell 7.x trouvée." -Type "Success"
        return $true
    }
}

# Chemins des fichiers
$sourcePath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.psm1"
$destinationPath = Join-Path -Path $PSScriptRoot -ChildPath "..\UnifiedParallel.PS51.psm1"

# Afficher les informations sur le système
Write-TestMessage "Création d'une version du module UnifiedParallel compatible avec PowerShell 5.1" -Type "Header"
Write-TestMessage "Version de PowerShell: $($PSVersionTable.PSVersion)" -Type "Info"
Write-TestMessage "Fichier source: $sourcePath" -Type "Info"
Write-TestMessage "Fichier destination: $destinationPath" -Type "Info"

# Tester la compatibilité de Wait-ForCompletedRunspace
$waitCompatible = Test-WaitForCompletedRunspaceCompatibility -ModulePath $sourcePath

if ($waitCompatible) {
    Write-TestMessage "`nLa fonction Wait-ForCompletedRunspace est déjà compatible avec PowerShell 5.1." -Type "Success"
} else {
    Write-TestMessage "`nLa fonction Wait-ForCompletedRunspace n'est pas compatible avec PowerShell 5.1." -Type "Warning"
}

# Créer une version compatible avec PowerShell 5.1
$result = New-PS51CompatibleModule -SourcePath $sourcePath -DestinationPath $destinationPath -NoBackup:$NoBackup -Force:$Force

if ($result) {
    # Tester la compatibilité du module
    $compatibilityResult = Test-ModuleCompatibility -ModulePath $destinationPath
    
    if ($compatibilityResult) {
        Write-TestMessage "`nLe module est maintenant compatible avec PowerShell 5.1." -Type "Success"
    } else {
        Write-TestMessage "`nLe module contient encore des fonctionnalités incompatibles avec PowerShell 5.1." -Type "Error"
    }
} else {
    Write-TestMessage "`nÉchec de la création d'une version compatible avec PowerShell 5.1." -Type "Error"
}

# Retourner le résultat
return @{
    Success = $result -and $compatibilityResult
    WaitForCompletedRunspaceCompatible = $waitCompatible
    SourcePath = $sourcePath
    DestinationPath = $destinationPath
}
