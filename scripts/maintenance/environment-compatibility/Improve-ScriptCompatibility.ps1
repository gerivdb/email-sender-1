<#
.SYNOPSIS
    Script pour améliorer la compatibilité des scripts PowerShell entre environnements.

.DESCRIPTION
    Ce script analyse les scripts PowerShell existants et les modifie pour améliorer
    leur compatibilité entre différents environnements (Windows, Linux, macOS).

.PARAMETER ScriptPath
    Le chemin du script ou du répertoire à analyser.

.PARAMETER Recurse
    Si spécifié, analyse récursivement les sous-répertoires.

.PARAMETER BackupFiles
    Si spécifié, crée une sauvegarde des fichiers avant de les modifier.

.PARAMETER WhatIf
    Si spécifié, affiche les modifications qui seraient apportées sans les appliquer.

.PARAMETER ReportOnly
    Si spécifié, génère uniquement un rapport sans modifier les fichiers.

.EXAMPLE
    .\Improve-ScriptCompatibility.ps1 -ScriptPath "C:\Scripts" -Recurse -BackupFiles

.EXAMPLE
    .\Improve-ScriptCompatibility.ps1 -ScriptPath "C:\Scripts\script.ps1" -WhatIf

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date création:  09/04/2025
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ScriptPath,
    
    [Parameter(Mandatory = $false)]
    [switch]$Recurse,
    
    [Parameter(Mandatory = $false)]
    [switch]$BackupFiles,
    
    [Parameter(Mandatory = $false)]
    [switch]$ReportOnly
)

# Importer le module EnvironmentManager
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "EnvironmentManager.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
}
else {
    Write-Error "Module EnvironmentManager non trouvé: $modulePath"
    exit 1
}

# Initialiser le module
Initialize-EnvironmentManager

# Fonction pour analyser un script
function Test-ScriptCompatibility {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath
    )
    
    if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
        Write-Error "Script non trouvé: $ScriptPath"
        return $null
    }
    
    $content = Get-Content -Path $ScriptPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) {
        Write-Error "Impossible de lire le script: $ScriptPath"
        return $null
    }
    
    $issues = @()
    
    # 1. Chemins codés en dur
    if ($content -match "([A-Z]:\\[^'`"]*\\[^'`"]*)" -or $content -match "([A-Z]:/[^'`"]*/[^'`"]*)") {
        $issues += "Chemins codés en dur"
    }
    
    # 2. Utilisation de séparateurs de chemin spécifiques à Windows
    if ($content -match "\\\\" -and -not $content -match "\\\\\\\\") {
        $issues += "Séparateurs de chemin spécifiques à Windows"
    }
    
    # 3. Commandes spécifiques à Windows
    if ($content -match "cmd\.exe|cmd /c|powershell\.exe|\.bat|\.cmd") {
        $issues += "Commandes spécifiques à Windows"
    }
    
    # 4. Utilisation de variables d'environnement spécifiques à Windows
    if ($content -match "\$env:USERPROFILE|\$env:APPDATA|\$env:ProgramFiles|\$env:SystemRoot") {
        $issues += "Variables d'environnement spécifiques à Windows"
    }
    
    # 5. Utilisation de fonctions spécifiques à PowerShell Windows
    if ($content -match "Get-WmiObject|Get-EventLog") {
        $issues += "Fonctions spécifiques à PowerShell Windows"
    }
    
    # Vérifier l'utilisation de fonctions de gestion de chemins
    $hasPathFunctions = $content -match "Join-Path|Split-Path|Test-Path.*-PathType|System\.IO\.Path|ConvertTo-CrossPlatformPath|Join-CrossPlatformPath"
    
    # Vérifier la présence de détection d'environnement
    $hasEnvironmentDetection = $content -match "Get-EnvironmentInfo|Test-EnvironmentCompatibility|\$IsWindows|\$IsLinux|\$IsMacOS"
    
    # Déterminer si le script est compatible
    $isCompatible = ($issues.Count -eq 0) -or $hasPathFunctions -or $hasEnvironmentDetection
    
    return [PSCustomObject]@{
        Path = $ScriptPath
        IsCompatible = $isCompatible
        Issues = $issues
        HasPathFunctions = $hasPathFunctions
        HasEnvironmentDetection = $hasEnvironmentDetection
    }
}

# Fonction pour améliorer la compatibilité d'un script
function Improve-Script {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$BackupFile
    )
    
    if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
        Write-Error "Script non trouvé: $ScriptPath"
        return $false
    }
    
    $content = Get-Content -Path $ScriptPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) {
        Write-Error "Impossible de lire le script: $ScriptPath"
        return $false
    }
    
    # Créer une sauvegarde si demandé
    if ($BackupFile) {
        $backupPath = "$ScriptPath.bak"
        if ($PSCmdlet.ShouldProcess($ScriptPath, "Créer une sauvegarde")) {
            Copy-Item -Path $ScriptPath -Destination $backupPath -Force
            Write-Verbose "Sauvegarde créée: $backupPath"
        }
    }
    
    # Modifications à apporter
    $modifiedContent = $content
    
    # 1. Ajouter l'importation du module EnvironmentManager si nécessaire
    if (-not ($modifiedContent -match "EnvironmentManager\.psm1")) {
        $importModule = @"
# Importer le module EnvironmentManager
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\maintenance\environment-compatibility\EnvironmentManager.psm1"
if (Test-Path -Path `$modulePath) {
    Import-Module `$modulePath -Force
}
else {
    Write-Warning "Module EnvironmentManager non trouvé: `$modulePath"
}

# Initialiser le module
if (Get-Command -Name Initialize-EnvironmentManager -ErrorAction SilentlyContinue) {
    Initialize-EnvironmentManager
}

"@
        
        # Trouver l'endroit où insérer l'importation du module
        if ($modifiedContent -match "^<#") {
            # Après le bloc de commentaires
            $endComment = $modifiedContent -match "#>"
            if ($endComment) {
                $endCommentIndex = $modifiedContent.IndexOf("#>") + 2
                $modifiedContent = $modifiedContent.Substring(0, $endCommentIndex) + "`n`n" + $importModule + $modifiedContent.Substring($endCommentIndex)
            }
            else {
                $modifiedContent = $importModule + $modifiedContent
            }
        }
        else {
            # Au début du fichier
            $modifiedContent = $importModule + $modifiedContent
        }
    }
    
    # 2. Standardiser les séparateurs de chemin
    $modifiedContent = $modifiedContent -replace "\\\\(?!\\\\)", [System.IO.Path]::DirectorySeparatorChar
    
    # 3. Remplacer les commandes spécifiques à Windows par des alternatives compatibles
    $modifiedContent = $modifiedContent -replace "cmd\.exe /c", "Invoke-CrossPlatformCommand -WindowsCommand 'cmd.exe /c' -UnixCommand 'bash -c'"
    $modifiedContent = $modifiedContent -replace "powershell\.exe", "pwsh"
    
    # 4. Remplacer les variables d'environnement spécifiques à Windows
    $modifiedContent = $modifiedContent -replace '\$env:USERPROFILE', 'if ($IsWindows) { $env:USERPROFILE } else { $HOME }'
    $modifiedContent = $modifiedContent -replace '\$env:APPDATA', 'if ($IsWindows) { $env:APPDATA } else { Join-Path -Path $HOME -ChildPath ".config" }'
    $modifiedContent = $modifiedContent -replace '\$env:ProgramFiles', 'if ($IsWindows) { $env:ProgramFiles } else { "/usr/local" }'
    $modifiedContent = $modifiedContent -replace '\$env:SystemRoot', 'if ($IsWindows) { $env:SystemRoot } else { "/" }'
    
    # 5. Remplacer les fonctions spécifiques à PowerShell Windows
    $modifiedContent = $modifiedContent -replace "Get-WmiObject", "Get-CimInstance"
    $modifiedContent = $modifiedContent -replace "Get-EventLog", "Get-WinEvent"
    
    # 6. Remplacer les chemins codés en dur par des chemins relatifs
    # Cette partie est plus complexe et nécessiterait une analyse plus approfondie du script
    
    # Écrire le contenu modifié dans le fichier
    if ($PSCmdlet.ShouldProcess($ScriptPath, "Améliorer la compatibilité")) {
        Set-Content -Path $ScriptPath -Value $modifiedContent -Force
        Write-Verbose "Script amélioré: $ScriptPath"
        return $true
    }
    
    return $false
}

# Fonction principale
function Start-ScriptCompatibilityImprovement {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        
        [Parameter(Mandatory = $false)]
        [switch]$BackupFiles,
        
        [Parameter(Mandatory = $false)]
        [switch]$ReportOnly
    )
    
    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le chemin spécifié n'existe pas: $ScriptPath"
        return
    }
    
    # Obtenir les scripts à analyser
    $scripts = if (Test-Path -Path $ScriptPath -PathType Leaf) {
        Get-Item -Path $ScriptPath
    }
    else {
        Get-ChildItem -Path $ScriptPath -Filter "*.ps1" -Recurse:$Recurse
    }
    
    # Initialiser les compteurs
    $totalScripts = $scripts.Count
    $compatibleScripts = 0
    $incompatibleScripts = 0
    $improvedScripts = 0
    
    # Créer un tableau pour stocker les résultats
    $results = @()
    
    # Analyser chaque script
    foreach ($script in $scripts) {
        Write-Host "Analyse du script: $($script.FullName)" -ForegroundColor Cyan
        
        # Analyser le script
        $compatibility = Test-ScriptCompatibility -ScriptPath $script.FullName
        
        if ($null -eq $compatibility) {
            Write-Warning "Impossible d'analyser le script: $($script.FullName)"
            continue
        }
        
        # Ajouter le résultat au tableau
        $results += $compatibility
        
        # Mettre à jour les compteurs
        if ($compatibility.IsCompatible) {
            $compatibleScripts++
            Write-Host "  Compatible: Oui" -ForegroundColor Green
        }
        else {
            $incompatibleScripts++
            Write-Host "  Compatible: Non" -ForegroundColor Red
            Write-Host "  Problèmes: $($compatibility.Issues -join ", ")" -ForegroundColor Yellow
            
            # Améliorer le script si demandé
            if (-not $ReportOnly) {
                $improved = Improve-Script -ScriptPath $script.FullName -BackupFile:$BackupFiles
                if ($improved) {
                    $improvedScripts++
                    Write-Host "  Amélioré: Oui" -ForegroundColor Green
                }
                else {
                    Write-Host "  Amélioré: Non" -ForegroundColor Yellow
                }
            }
        }
    }
    
    # Afficher un résumé
    Write-Host "`nRésumé:" -ForegroundColor Cyan
    Write-Host "  Scripts analysés: $totalScripts" -ForegroundColor White
    Write-Host "  Scripts compatibles: $compatibleScripts" -ForegroundColor Green
    Write-Host "  Scripts incompatibles: $incompatibleScripts" -ForegroundColor Red
    if (-not $ReportOnly) {
        Write-Host "  Scripts améliorés: $improvedScripts" -ForegroundColor Yellow
    }
    
    # Générer un rapport
    $reportPath = Join-Path -Path $PSScriptRoot -ChildPath "ScriptCompatibilityReport.csv"
    $results | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nRapport généré: $reportPath" -ForegroundColor Cyan
    
    return $results
}

# Exécuter la fonction principale
Start-ScriptCompatibilityImprovement -ScriptPath $ScriptPath -Recurse:$Recurse -BackupFiles:$BackupFiles -ReportOnly:$ReportOnly
