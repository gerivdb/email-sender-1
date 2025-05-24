<#
.SYNOPSIS
    Script pour amÃ©liorer la compatibilitÃ© des scripts PowerShell entre environnements.

.DESCRIPTION
    Ce script analyse les scripts PowerShell existants et les modifie pour amÃ©liorer
    leur compatibilitÃ© entre diffÃ©rents environnements (Windows, Linux, macOS).

.PARAMETER ScriptPath
    Le chemin du script ou du rÃ©pertoire Ã  analyser.

.PARAMETER Recurse
    Si spÃ©cifiÃ©, analyse rÃ©cursivement les sous-rÃ©pertoires.

.PARAMETER BackupFiles
    Si spÃ©cifiÃ©, crÃ©e une sauvegarde des fichiers avant de les modifier.

.PARAMETER WhatIf
    Si spÃ©cifiÃ©, affiche les modifications qui seraient apportÃ©es sans les appliquer.

.PARAMETER ReportOnly
    Si spÃ©cifiÃ©, gÃ©nÃ¨re uniquement un rapport sans modifier les fichiers.

.EXAMPLE
    .\Improve-ScriptCompatibility.ps1 -ScriptPath "C:\Scripts" -Recurse -BackupFiles

.EXAMPLE
    .\Improve-ScriptCompatibility.ps1 -ScriptPath "C:\Scripts\script.ps1" -WhatIf

.NOTES
    Version:        1.0
    Auteur:         Augment Agent
    Date crÃ©ation:  09/04/2025
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
    Write-Error "Module EnvironmentManager non trouvÃ©: $modulePath"
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
        Write-Error "Script non trouvÃ©: $ScriptPath"
        return $null
    }
    
    $content = Get-Content -Path $ScriptPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) {
        Write-Error "Impossible de lire le script: $ScriptPath"
        return $null
    }
    
    $issues = @()
    
    # 1. Chemins codÃ©s en dur
    if ($content -match "([A-Z]:\\[^'`"]*\\[^'`"]*)" -or $content -match "([A-Z]:/[^'`"]*/[^'`"]*)") {
        $issues += "Chemins codÃ©s en dur"
    }
    
    # 2. Utilisation de sÃ©parateurs de chemin spÃ©cifiques Ã  Windows
    if ($content -match "\\\\" -and -not $content -match "\\\\\\\\") {
        $issues += "SÃ©parateurs de chemin spÃ©cifiques Ã  Windows"
    }
    
    # 3. Commandes spÃ©cifiques Ã  Windows
    if ($content -match "cmd\.exe|cmd /c|powershell\.exe|\.bat|\.cmd") {
        $issues += "Commandes spÃ©cifiques Ã  Windows"
    }
    
    # 4. Utilisation de variables d'environnement spÃ©cifiques Ã  Windows
    if ($content -match "\$env:USERPROFILE|\$env:APPDATA|\$env:ProgramFiles|\$env:SystemRoot") {
        $issues += "Variables d'environnement spÃ©cifiques Ã  Windows"
    }
    
    # 5. Utilisation de fonctions spÃ©cifiques Ã  PowerShell Windows
    if ($content -match "Get-WmiObject|Get-EventLog") {
        $issues += "Fonctions spÃ©cifiques Ã  PowerShell Windows"
    }
    
    # VÃ©rifier l'utilisation de fonctions de gestion de chemins
    $hasPathFunctions = $content -match "Join-Path|Split-Path|Test-Path.*-PathType|System\.IO\.Path|ConvertTo-CrossPlatformPath|Join-CrossPlatformPath"
    
    # VÃ©rifier la prÃ©sence de dÃ©tection d'environnement
    $hasEnvironmentDetection = $content -match "Get-EnvironmentInfo|Test-EnvironmentCompatibility|\$IsWindows|\$IsLinux|\$IsMacOS"
    
    # DÃ©terminer si le script est compatible
    $isCompatible = ($issues.Count -eq 0) -or $hasPathFunctions -or $hasEnvironmentDetection
    
    return [PSCustomObject]@{
        Path = $ScriptPath
        IsCompatible = $isCompatible
        Issues = $issues
        HasPathFunctions = $hasPathFunctions
        HasEnvironmentDetection = $hasEnvironmentDetection
    }
}

# Fonction pour amÃ©liorer la compatibilitÃ© d'un script
function Update-Script {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$BackupFile
    )
    
    if (-not (Test-Path -Path $ScriptPath -PathType Leaf)) {
        Write-Error "Script non trouvÃ©: $ScriptPath"
        return $false
    }
    
    $content = Get-Content -Path $ScriptPath -Raw -ErrorAction SilentlyContinue
    if ($null -eq $content) {
        Write-Error "Impossible de lire le script: $ScriptPath"
        return $false
    }
    
    # CrÃ©er une sauvegarde si demandÃ©
    if ($BackupFile) {
        $backupPath = "$ScriptPath.bak"
        if ($PSCmdlet.ShouldProcess($ScriptPath, "CrÃ©er une sauvegarde")) {
            Copy-Item -Path $ScriptPath -Destination $backupPath -Force
            Write-Verbose "Sauvegarde crÃ©Ã©e: $backupPath"
        }
    }
    
    # Modifications Ã  apporter
    $modifiedContent = $content
    
    # 1. Ajouter l'importation du module EnvironmentManager si nÃ©cessaire
    if (-not ($modifiedContent -match "EnvironmentManager\.psm1")) {
        $importModule = @"
# Importer le module EnvironmentManager
`$modulePath = Join-Path -Path `$PSScriptRoot -ChildPath "..\..\maintenance\environment-compatibility\EnvironmentManager.psm1"
if (Test-Path -Path `$modulePath) {
    Import-Module `$modulePath -Force
}
else {
    Write-Warning "Module EnvironmentManager non trouvÃ©: `$modulePath"
}

# Initialiser le module
if (Get-Command -Name Initialize-EnvironmentManager -ErrorAction SilentlyContinue) {
    Initialize-EnvironmentManager
}

"@
        
        # Trouver l'endroit oÃ¹ insÃ©rer l'importation du module
        if ($modifiedContent -match "^<#") {
            # AprÃ¨s le bloc de commentaires
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
            # Au dÃ©but du fichier
            $modifiedContent = $importModule + $modifiedContent
        }
    }
    
    # 2. Standardiser les sÃ©parateurs de chemin
    $modifiedContent = $modifiedContent -replace "\\\\(?!\\\\)", [System.IO.Path]::DirectorySeparatorChar
    
    # 3. Remplacer les commandes spÃ©cifiques Ã  Windows par des alternatives compatibles
    $modifiedContent = $modifiedContent -replace "cmd\.exe /c", "Invoke-CrossPlatformCommand -WindowsCommand 'cmd.exe /c' -UnixCommand 'bash -c'"
    $modifiedContent = $modifiedContent -replace "powershell\.exe", "pwsh"
    
    # 4. Remplacer les variables d'environnement spÃ©cifiques Ã  Windows
    $modifiedContent = $modifiedContent -replace '\$env:USERPROFILE', 'if ($IsWindows) { $env:USERPROFILE } else { $HOME }'
    $modifiedContent = $modifiedContent -replace '\$env:APPDATA', 'if ($IsWindows) { $env:APPDATA } else { Join-Path -Path $HOME -ChildPath ".config" }'
    $modifiedContent = $modifiedContent -replace '\$env:ProgramFiles', 'if ($IsWindows) { $env:ProgramFiles } else { "/usr/local" }'
    $modifiedContent = $modifiedContent -replace '\$env:SystemRoot', 'if ($IsWindows) { $env:SystemRoot } else { "/" }'
    
    # 5. Remplacer les fonctions spÃ©cifiques Ã  PowerShell Windows
    $modifiedContent = $modifiedContent -replace "Get-WmiObject", "Get-CimInstance"
    $modifiedContent = $modifiedContent -replace "Get-EventLog", "Get-WinEvent"
    
    # 6. Remplacer les chemins codÃ©s en dur par des chemins relatifs
    # Cette partie est plus complexe et nÃ©cessiterait une analyse plus approfondie du script
    
    # Ã‰crire le contenu modifiÃ© dans le fichier
    if ($PSCmdlet.ShouldProcess($ScriptPath, "AmÃ©liorer la compatibilitÃ©")) {
        Set-Content -Path $ScriptPath -Value $modifiedContent -Force
        Write-Verbose "Script amÃ©liorÃ©: $ScriptPath"
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
    
    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $ScriptPath)) {
        Write-Error "Le chemin spÃ©cifiÃ© n'existe pas: $ScriptPath"
        return
    }
    
    # Obtenir les scripts Ã  analyser
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
    
    # CrÃ©er un tableau pour stocker les rÃ©sultats
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
        
        # Ajouter le rÃ©sultat au tableau
        $results += $compatibility
        
        # Mettre Ã  jour les compteurs
        if ($compatibility.IsCompatible) {
            $compatibleScripts++
            Write-Host "  Compatible: Oui" -ForegroundColor Green
        }
        else {
            $incompatibleScripts++
            Write-Host "  Compatible: Non" -ForegroundColor Red
            Write-Host "  ProblÃ¨mes: $($compatibility.Issues -join ", ")" -ForegroundColor Yellow
            
            # AmÃ©liorer le script si demandÃ©
            if (-not $ReportOnly) {
                $improved = Update-Script -ScriptPath $script.FullName -BackupFile:$BackupFiles
                if ($improved) {
                    $improvedScripts++
                    Write-Host "  AmÃ©liorÃ©: Oui" -ForegroundColor Green
                }
                else {
                    Write-Host "  AmÃ©liorÃ©: Non" -ForegroundColor Yellow
                }
            }
        }
    }
    
    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ©:" -ForegroundColor Cyan
    Write-Host "  Scripts analysÃ©s: $totalScripts" -ForegroundColor White
    Write-Host "  Scripts compatibles: $compatibleScripts" -ForegroundColor Green
    Write-Host "  Scripts incompatibles: $incompatibleScripts" -ForegroundColor Red
    if (-not $ReportOnly) {
        Write-Host "  Scripts amÃ©liorÃ©s: $improvedScripts" -ForegroundColor Yellow
    }
    
    # GÃ©nÃ©rer un rapport
    $reportPath = Join-Path -Path $PSScriptRoot -ChildPath "ScriptCompatibilityReport.csv"
    $results | Export-Csv -Path $reportPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nRapport gÃ©nÃ©rÃ©: $reportPath" -ForegroundColor Cyan
    
    return $results
}

# ExÃ©cuter la fonction principale
Start-ScriptCompatibilityImprovement -ScriptPath $ScriptPath -Recurse:$Recurse -BackupFiles:$BackupFiles -ReportOnly:$ReportOnly

