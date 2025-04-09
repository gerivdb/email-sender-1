<#
.SYNOPSIS
    Standardise automatiquement les scripts selon les standards de codage dÃ©finis.
.DESCRIPTION
    Ce script corrige automatiquement les problÃ¨mes courants de conformitÃ© aux standards
    de codage dans les scripts PowerShell, Python, Batch et Shell.
.PARAMETER Path
    Chemin du fichier ou du dossier contenant les scripts Ã  standardiser. Par dÃ©faut: scripts
.PARAMETER ComplianceReportPath
    Chemin du rapport de conformitÃ© gÃ©nÃ©rÃ© par Test-ScriptCompliance-v2.ps1.
    Par dÃ©faut: scripts\manager\data\compliance_report.json
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport des modifications.
    Par dÃ©faut: scripts\manager\data\standardization_report.json
.PARAMETER ScriptType
    Type de script Ã  standardiser. Valeurs possibles: All, PowerShell, Python, Batch, Shell. Par dÃ©faut: All
.PARAMETER Rules
    Liste des rÃ¨gles Ã  appliquer. Par dÃ©faut: toutes les rÃ¨gles
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER ShowDetails
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Format-Script-v2.ps1 -Path "scripts\maintenance"
    Standardise tous les scripts dans le dossier scripts\maintenance.
.EXAMPLE
    .\Format-Script-v2.ps1 -Path "scripts\maintenance\script.ps1" -AutoApply
    Standardise automatiquement le script spÃ©cifiÃ©.

<#
.SYNOPSIS
    Standardise automatiquement les scripts selon les standards de codage dÃ©finis.
.DESCRIPTION
    Ce script corrige automatiquement les problÃ¨mes courants de conformitÃ© aux standards
    de codage dans les scripts PowerShell, Python, Batch et Shell.
.PARAMETER Path
    Chemin du fichier ou du dossier contenant les scripts Ã  standardiser. Par dÃ©faut: scripts
.PARAMETER ComplianceReportPath
    Chemin du rapport de conformitÃ© gÃ©nÃ©rÃ© par Test-ScriptCompliance-v2.ps1.
    Par dÃ©faut: scripts\manager\data\compliance_report.json
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport des modifications.
    Par dÃ©faut: scripts\manager\data\standardization_report.json
.PARAMETER ScriptType
    Type de script Ã  standardiser. Valeurs possibles: All, PowerShell, Python, Batch, Shell. Par dÃ©faut: All
.PARAMETER Rules
    Liste des rÃ¨gles Ã  appliquer. Par dÃ©faut: toutes les rÃ¨gles
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER ShowDetails
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Format-Script-v2.ps1 -Path "scripts\maintenance"
    Standardise tous les scripts dans le dossier scripts\maintenance.
.EXAMPLE
    .\Format-Script-v2.ps1 -Path "scripts\maintenance\script.ps1" -AutoApply
    Standardise automatiquement le script spÃ©cifiÃ©.
#>

param (
    [string]$Path = "scripts",
    [string]$ComplianceReportPath = "scripts\manager\data\compliance_report.json",
    [string]$OutputPath = "scripts\manager\data\standardization_report.json",
    [ValidateSet("All", "PowerShell", "Python", "Batch", "Shell")

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
try {
    # Script principal
]
    [string]$ScriptType = "All",
    [string[]]$Rules = @(),
    [switch]$AutoApply,
    [switch]$ShowDetails
)

# Fonction pour Ã©crire des messages de log
function Write-Log {
    param (
        [string]$Message,
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR", "TITLE")]
        [string]$Level = "INFO"
    )
    
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ColorMap = @{
        "INFO" = "White"
        "SUCCESS" = "Green"
        "WARNING" = "Yellow"
        "ERROR" = "Red"
        "TITLE" = "Cyan"
    }
    
    $Color = $ColorMap[$Level]
    $FormattedMessage = "[$TimeStamp] [$Level] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color
    
    # Ã‰crire dans un fichier de log
    $LogFile = "scripts\manager\data\standardization.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour obtenir tous les fichiers de script
function Get-ScriptFiles {
    param (
        [string]$Path,
        [string]$ScriptType
    )
    
    $ScriptExtensions = @{
        "PowerShell" = @("*.ps1", "*.psm1", "*.psd1")
        "Python" = @("*.py")
        "Batch" = @("*.cmd", "*.bat")
        "Shell" = @("*.sh")
    }
    
    $Files = @()
    
    # Si le chemin est un fichier, retourner ce fichier s'il correspond au type
    if (Test-Path -Path $Path -PathType Leaf) {
        $Extension = [System.IO.Path]::GetExtension($Path).ToLower()
        $FileType = switch ($Extension) {
            ".ps1" { "PowerShell" }
            ".psm1" { "PowerShell" }
            ".psd1" { "PowerShell" }
            ".py" { "Python" }
            ".cmd" { "Batch" }
            ".bat" { "Batch" }
            ".sh" { "Shell" }
            default { "Unknown" }
        }
        
        if ($ScriptType -eq "All" -or $ScriptType -eq $FileType) {
            $Files += Get-Item -Path $Path
        }
        
        return $Files
    }
    
    # Si le chemin est un dossier, rechercher les fichiers correspondants
    if ($ScriptType -eq "All") {
        foreach ($Type in $ScriptExtensions.Keys) {
            foreach ($Extension in $ScriptExtensions[$Type]) {
                $Files += Get-ChildItem -Path $Path -Filter $Extension -Recurse -File
            }
        }
    } else {
        foreach ($Extension in $ScriptExtensions[$ScriptType]) {
            $Files += Get-ChildItem -Path $Path -Filter $Extension -Recurse -File
        }
    }
    
    return $Files
}

# Fonction pour dÃ©terminer le type de script
function Get-ScriptType {
    param (
        [string]$FilePath
    )
    
    $Extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    
    switch ($Extension) {
        ".ps1" { return "PowerShell" }
        ".psm1" { return "PowerShell" }
        ".psd1" { return "PowerShell" }
        ".py" { return "Python" }
        ".cmd" { return "Batch" }
        ".bat" { return "Batch" }
        ".sh" { return "Shell" }
        default { return "Unknown" }
    }
}

# Fonction pour ajouter un en-tÃªte de script PowerShell
function Add-PowerShellHeader {
    param (
        [string]$FilePath,
        [string]$Content
    )
    
    $FileName = [System.IO.Path]::GetFileName($FilePath)
    $CurrentDate = Get-Date -Format "yyyy-MM-dd"
    
    $Header = @"
<#
.SYNOPSIS
    Description brÃ¨ve du script.
.DESCRIPTION
    Description dÃ©taillÃ©e du script.
.PARAMETER Param1
    Description du premier paramÃ¨tre.
.EXAMPLE
    .\$FileName -Param1 Value1
    Description de ce que fait cet exemple.
.NOTES
    Nom du fichier    : $FileName
    Auteur           : 
    Date de crÃ©ation  : $CurrentDate
    DerniÃ¨re modification : $CurrentDate
    Version          : 1.0
#>

"@
    
    # Si le script a dÃ©jÃ  un bloc param, ajouter l'en-tÃªte avant
    if ($Content -match "param\s*\(") {
        $NewContent = $Content -replace "param\s*\(", "$Header`r`nparam ("
    } else {
        $NewContent = "$Header`r`n$Content"
    }
    
    return $NewContent
}

# Fonction pour ajouter un en-tÃªte de script Python
function Add-PythonHeader {
    param (
        [string]$FilePath,
        [string]$Content
    )
    
    $FileName = [System.IO.Path]::GetFileName($FilePath)
    $CurrentDate = Get-Date -Format "yyyy-MM-dd"
    
    $Header = @"
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Nom du script : $FileName
Description : Description brÃ¨ve du script.
Auteur : 
Date de crÃ©ation : $CurrentDate
DerniÃ¨re modification : $CurrentDate
Version : 1.0

Exemples d'utilisation :
    python $FileName arg1 arg2
"""

"@
    
    # Ajouter l'en-tÃªte au dÃ©but du fichier
    $NewContent = "$Header`r`n$Content"
    
    return $NewContent
}

# Fonction pour ajouter un en-tÃªte de script Batch
function Add-BatchHeader {
    param (
        [string]$FilePath,
        [string]$Content
    )
    
    $FileName = [System.IO.Path]::GetFileName($FilePath)
    $CurrentDate = Get-Date -Format "yyyy-MM-dd"
    
    $Header = @"
@echo off
setlocal enabledelayedexpansion

::-----------------------------------------------------------------------------
:: Nom du script : $FileName
:: Description   : Description brÃ¨ve du script.
:: Auteur        : 
:: Date de crÃ©ation : $CurrentDate
:: DerniÃ¨re modification : $CurrentDate
:: Version       : 1.0
::
:: Utilisation   : $FileName [arg1] [arg2]
::-----------------------------------------------------------------------------

"@
    
    # Si le script commence dÃ©jÃ  par @echo off, remplacer cette ligne
    if ($Content -match "^@echo off") {
        $NewContent = $Content -replace "^@echo off", $Header
    } else {
        $NewContent = "$Header`r`n$Content"
    }
    
    return $NewContent
}

# Fonction pour ajouter un en-tÃªte de script Shell
function Add-ShellHeader {
    param (
        [string]$FilePath,
        [string]$Content
    )
    
    $FileName = [System.IO.Path]::GetFileName($FilePath)
    $CurrentDate = Get-Date -Format "yyyy-MM-dd"
    
    $Header = @"
#!/bin/bash
#-----------------------------------------------------------------------------
# Nom du script : $FileName
# Description   : Description brÃ¨ve du script.
# Auteur        : 
# Date de crÃ©ation : $CurrentDate
# DerniÃ¨re modification : $CurrentDate
# Version       : 1.0
#
# Utilisation   : ./$FileName [arg1] [arg2]
#-----------------------------------------------------------------------------

# ArrÃªter le script en cas d'erreur
set -e

"@
    
    # Si le script commence dÃ©jÃ  par un shebang, remplacer cette ligne
    if ($Content -match "^#!/bin/(ba)?sh") {
        $NewContent = $Content -replace "^#!/bin/(ba)?sh.*\n", $Header
    } else {
        $NewContent = "$Header`r`n$Content"
    }
    
    return $NewContent
}

# Fonction pour corriger les comparaisons avec $null
function Repair-NullComparisons {
    param (
        [string]$Content
    )
    
    $NewContent = $Content -replace "(\`$[A-Za-z0-9_]+)\s+-eq\s+\`$null", "`$null -eq `$1"
    
    return $NewContent
}

# Fonction pour corriger les concatÃ©nations de chemins
function Repair-PathConcatenations {
    param (
        [string]$Content
    )
    
    $RegexMatches = [regex]::Matches($Content, "(\`$[A-Za-z0-9_]+)\s*\+\s*(['""])\\([^'""]+)\\?([^'""]*)['""]")
    
    $NewContent = $Content
    
    foreach ($Match in $RegexMatches) {
        $Original = $Match.Value
        $Variable = $Match.Groups[1].Value
        $Quote = $Match.Groups[2].Value
        $Path1 = $Match.Groups[3].Value
        $Path2 = $Match.Groups[4].Value
        
        $Replacement = "Join-Path -Path $Variable -ChildPath $Quote$Path1\$Path2$Quote"
        $NewContent = $NewContent.Replace($Original, $Replacement)
    }
    
    return $NewContent
}

# Fonction pour ajouter if __name__ == "__main__" Ã  un script Python
function Add-PythonMainGuard {
    param (
        [string]$Content
    )
    
    if (-not ($Content -match 'if\s+__name__\s*==\s*[''"]__main__[''"]')) {
        $MainGuard = @"

def main():
    """Point d'entrÃ©e principal du script."""
    pass

if __name__ == "__main__":
    main()
"@
        
        $NewContent = "$Content`r`n$MainGuard"
    } else {
        $NewContent = $Content
    }
    
    return $NewContent
}

# Fonction pour remplacer les tabulations par des espaces
function Repair-Indentation {
    param (
        [string]$Content
    )
    
    $NewContent = $Content -replace "\t", "    "
    
    return $NewContent
}

# Fonction pour corriger l'encodage du fichier
function Repair-FileEncoding {
    param (
        [string]$FilePath,
        [string]$ScriptType
    )
    
    $Content = Get-Content -Path $FilePath -Raw
    
    switch ($ScriptType) {
        "PowerShell" {
            # Encoder en UTF-8 avec BOM
            [System.IO.File]::WriteAllText($FilePath, $Content, [System.Text.Encoding]::UTF8)
        }
        "Python" {
            # Encoder en UTF-8 sans BOM
            $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($FilePath, $Content, $Utf8NoBom)
        }
        "Shell" {
            # Encoder en UTF-8 sans BOM
            $Utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($FilePath, $Content, $Utf8NoBom)
        }
    }
}

# Fonction pour standardiser un script
function Format-ScriptContent {
    param (
        [string]$FilePath,
        [string[]]$Rules,
        [switch]$Apply
    )
    
    $ScriptType = Get-ScriptType -FilePath $FilePath
    
    if ($ScriptType -eq "Unknown") {
        Write-Log "Type de script inconnu: $FilePath" -Level "WARNING"
        return $null
    }
    
    $Content = Get-Content -Path $FilePath -Raw -Encoding UTF8
    $NewContent = $Content
    $Changes = @()
    
    # Appliquer les rÃ¨gles de standardisation
    if ($Rules.Count -eq 0 -or $Rules -contains "Header") {
        # Ajouter un en-tÃªte si nÃ©cessaire
        $HasHeader = switch ($ScriptType) {
            "PowerShell" { $Content -match "<#[\s\S]*?#>" }
            "Python" { $Content -match '"""[\s\S]*?"""' -or $Content -match "'''[\s\S]*?'''" }
            "Batch" { $Content -match "::[-]+\r?\n::([\s\S]*?)::[-]+" }
            "Shell" { $Content -match "#[-]+\n#([\s\S]*?)#[-]+" }
            default { $true }
        }
        
        if (-not $HasHeader) {
            $OldContent = $NewContent
            $NewContent = switch ($ScriptType) {
                "PowerShell" { Add-PowerShellHeader -FilePath $FilePath -Content $NewContent }
                "Python" { Add-PythonHeader -FilePath $FilePath -Content $NewContent }
                "Batch" { Add-BatchHeader -FilePath $FilePath -Content $NewContent }
                "Shell" { Add-ShellHeader -FilePath $FilePath -Content $NewContent }
                default { $NewContent }
            }
            
            if ($NewContent -ne $OldContent) {
                $Changes += [PSCustomObject]@{
                    Rule = "Header"
                    Description = "Ajout d'un en-tÃªte standard"
                }
            }
        }
    }
    
    if ($Rules.Count -eq 0 -or $Rules -contains "NullComparison") {
        # Corriger les comparaisons avec $null
        if ($ScriptType -eq "PowerShell") {
            $OldContent = $NewContent
            $NewContent = Repair-NullComparisons -Content $NewContent
            
            if ($NewContent -ne $OldContent) {
                $Changes += [PSCustomObject]@{
                    Rule = "NullComparison"
                    Description = "Correction des comparaisons avec `$null"
                }
            }
        }
    }
    
    if ($Rules.Count -eq 0 -or $Rules -contains "PathConcatenation") {
        # Corriger les concatÃ©nations de chemins
        if ($ScriptType -eq "PowerShell") {
            $OldContent = $NewContent
            $NewContent = Repair-PathConcatenations -Content $NewContent
            
            if ($NewContent -ne $OldContent) {
                $Changes += [PSCustomObject]@{
                    Rule = "PathConcatenation"
                    Description = "Remplacement des concatÃ©nations de chemins par Join-Path"
                }
            }
        }
    }
    
    if ($Rules.Count -eq 0 -or $Rules -contains "MainGuard") {
        # Ajouter if __name__ == "__main__" Ã  un script Python
        if ($ScriptType -eq "Python") {
            $OldContent = $NewContent
            $NewContent = Add-PythonMainGuard -Content $NewContent
            
            if ($NewContent -ne $OldContent) {
                $Changes += [PSCustomObject]@{
                    Rule = "MainGuard"
                    Description = "Ajout de la clause 'if __name__ == `"__main__`"'"
                }
            }
        }
    }
    
    if ($Rules.Count -eq 0 -or $Rules -contains "Indentation") {
        # Remplacer les tabulations par des espaces
        $OldContent = $NewContent
        $NewContent = Repair-Indentation -Content $NewContent
        
        if ($NewContent -ne $OldContent) {
            $Changes += [PSCustomObject]@{
                Rule = "Indentation"
                Description = "Remplacement des tabulations par des espaces"
            }
        }
    }
    
    # Appliquer les modifications
    if ($Apply -and $Changes.Count -gt 0) {
        Set-Content -Path $FilePath -Value $NewContent -Encoding UTF8
        
        # Corriger l'encodage si nÃ©cessaire
        if ($Rules.Count -eq 0 -or $Rules -contains "Encoding") {
            Repair-FileEncoding -FilePath $FilePath -ScriptType $ScriptType
            $Changes += [PSCustomObject]@{
                Rule = "Encoding"
                Description = "Correction de l'encodage du fichier"
            }
        }
    }
    
    $Result = [PSCustomObject]@{
        FilePath = $FilePath
        ScriptType = $ScriptType
        ChangeCount = $Changes.Count
        Changes = $Changes
        Applied = $Apply
    }
    
    return $Result
}

# Fonction principale
function Start-ScriptStandardization {
    param (
        [string]$Path,
        [string]$ComplianceReportPath,
        [string]$OutputPath,
        [string]$ScriptType,
        [string[]]$Rules,
        [switch]$AutoApply,
        [switch]$ShowDetails
    )
    
    Write-Log "DÃ©marrage de la standardisation des scripts..." -Level "TITLE"
    Write-Log "Chemin: $Path" -Level "INFO"
    Write-Log "Type de script: $ScriptType" -Level "INFO"
    Write-Log "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -Level "INFO"
    
    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $Path)) {
        Write-Log "Le chemin n'existe pas: $Path" -Level "ERROR"
        return
    }
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie crÃ©Ã©: $OutputDir" -Level "SUCCESS"
    }
    
    # Obtenir tous les fichiers de script
    $ScriptFiles = Get-ScriptFiles -Path $Path -ScriptType $ScriptType
    $TotalFiles = $ScriptFiles.Count
    Write-Log "Nombre de fichiers Ã  standardiser: $TotalFiles" -Level "INFO"
    
    # Initialiser les rÃ©sultats
    $Results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalFiles = $TotalFiles
        ScriptType = $ScriptType
        TotalChangeCount = 0
        AppliedChangeCount = 0
        ScriptResults = @()
    }
    
    # Standardiser chaque fichier
    $FileCounter = 0
    foreach ($File in $ScriptFiles) {
        $FileCounter++
        $Progress = [math]::Round(($FileCounter / $TotalFiles) * 100)
        Write-Progress -Activity "Standardisation des scripts" -Status "$FileCounter / $TotalFiles ($Progress%)" -PercentComplete $Progress
        
        if ($ShowDetails) {
            Write-Log "Standardisation du fichier: $($File.FullName)" -Level "INFO"
        }
        
        # Standardiser le script
        $ScriptResult = Format-ScriptContent -FilePath $File.FullName -Rules $Rules -Apply:$AutoApply
        
        if ($null -ne $ScriptResult) {
            $Results.ScriptResults += $ScriptResult
            $Results.TotalChangeCount += $ScriptResult.ChangeCount
            
            if ($ScriptResult.Applied) {
                $Results.AppliedChangeCount += $ScriptResult.ChangeCount
            }
            
            if ($ShowDetails -and $ScriptResult.ChangeCount -gt 0) {
                Write-Log "  Modifications: $($ScriptResult.ChangeCount)" -Level "INFO"
                foreach ($Change in $ScriptResult.Changes) {
                    Write-Log "    [$($Change.Rule)] $($Change.Description)" -Level "INFO"
                }
                
                if ($ScriptResult.Applied) {
                    Write-Log "  Modifications appliquÃ©es" -Level "SUCCESS"
                } else {
                    Write-Log "  Modifications simulÃ©es (non appliquÃ©es)" -Level "WARNING"
                }
            }
        }
    }
    
    Write-Progress -Activity "Standardisation des scripts" -Completed
    
    # Enregistrer les rÃ©sultats
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    # Afficher un rÃ©sumÃ©
    Write-Log "Standardisation terminÃ©e" -Level "SUCCESS"
    Write-Log "Nombre total de fichiers traitÃ©s: $TotalFiles" -Level "INFO"
    Write-Log "Nombre total de modifications: $($Results.TotalChangeCount)" -Level "INFO"
    
    if ($AutoApply) {
        Write-Log "Nombre de modifications appliquÃ©es: $($Results.AppliedChangeCount)" -Level "SUCCESS"
    } else {
        Write-Log "Pour appliquer les modifications, exÃ©cutez la commande avec -AutoApply" -Level "WARNING"
    }
    
    Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "SUCCESS"
    
    return $Results
}

# ExÃ©cuter la fonction principale
Start-ScriptStandardization -Path $Path -ComplianceReportPath $ComplianceReportPath -OutputPath $OutputPath -ScriptType $ScriptType -Rules $Rules -AutoApply:$AutoApply -ShowDetails:$ShowDetails

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "ExÃ©cution du script terminÃ©e."
}
