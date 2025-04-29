<#
.SYNOPSIS
    Fusionne les scripts similaires pour Ã©liminer les duplications.
.DESCRIPTION
    Ce script utilise le rapport gÃ©nÃ©rÃ© par Find-CodeDuplication.ps1 pour fusionner
    les scripts similaires et Ã©liminer les duplications de code. Il crÃ©e des fonctions
    rÃ©utilisables pour le code dupliquÃ© et met Ã  jour les rÃ©fÃ©rences.
.PARAMETER InputPath
    Chemin du fichier de rapport gÃ©nÃ©rÃ© par Find-CodeDuplication.ps1.
    Par dÃ©faut: scripts\\mode-manager\data\duplication_report.json
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport des fusions.
    Par dÃ©faut: scripts\\mode-manager\data\merge_report.json
.PARAMETER LibraryPath
    Chemin du dossier oÃ¹ seront crÃ©Ã©es les bibliothÃ¨ques de fonctions.
    Par dÃ©faut: scripts\common\lib
.PARAMETER MinimumDuplicationCount
    Nombre minimum de duplications pour crÃ©er une fonction rÃ©utilisable. Par dÃ©faut: 2
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER ShowDetails
    Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution.
.EXAMPLE
    .\Merge-SimilarScripts.ps1
    Analyse le rapport et propose des fusions pour les scripts similaires.
.EXAMPLE
    .\Merge-SimilarScripts.ps1 -AutoApply
    Analyse le rapport et applique automatiquement les fusions.
#>

param (
    [string]$InputPath = "scripts\\mode-manager\data\duplication_report.json",
    [string]$OutputPath = "scripts\\mode-manager\data\merge_report.json",
    [string]$LibraryPath = "scripts\common\lib",
    [int]$MinimumDuplicationCount = 2,
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
    $LogFile = "scripts\\mode-manager\data\script_merge.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
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

# Fonction pour gÃ©nÃ©rer un nom de fonction Ã  partir d'un bloc de code
function Get-FunctionName {
    param (
        [string]$BlockText,
        [string]$ScriptType,
        [int]$Index
    )
    
    # Extraire les mots clÃ©s du bloc de code
    $Keywords = $BlockText -split "\W+" | Where-Object { $_ -match "^[a-zA-Z][a-zA-Z0-9_]*$" -and $_.Length -gt 3 }
    
    # Filtrer les mots-clÃ©s rÃ©servÃ©s selon le type de script
    $ReservedKeywords = switch ($ScriptType) {
        "PowerShell" { @("function", "param", "begin", "process", "end", "if", "else", "elseif", "switch", "for", "foreach", "while", "do", "until", "break", "continue", "return", "throw", "try", "catch", "finally") }
        "Python" { @("def", "class", "if", "else", "elif", "for", "while", "try", "except", "finally", "with", "import", "from", "as", "return", "yield", "break", "continue", "pass", "raise", "global", "nonlocal") }
        "Batch" { @("echo", "set", "setlocal", "endlocal", "call", "goto", "if", "else", "for", "in", "do", "rem") }
        "Shell" { @("function", "if", "then", "else", "elif", "fi", "for", "while", "until", "do", "done", "case", "esac", "echo", "read", "exit", "return", "break", "continue", "shift") }
        default { @() }
    }
    
    $FilteredKeywords = $Keywords | Where-Object { $ReservedKeywords -notcontains $_ }
    
    # GÃ©nÃ©rer un nom de fonction Ã  partir des mots-clÃ©s
    if ($FilteredKeywords.Count -gt 0) {
        $BaseName = ($FilteredKeywords | Select-Object -First 3) -join ""
    } else {
        $BaseName = "CommonFunction"
    }
    
    # Formater le nom selon le type de script
    $FunctionName = switch ($ScriptType) {
        "PowerShell" { "Invoke-$BaseName$Index" }
        "Python" { ($BaseName + $Index).ToLower() }
        "Batch" { "call_$($BaseName.ToLower())_$Index" }
        "Shell" { ($BaseName + $Index).ToLower() }
        default { "function_$($BaseName.ToLower())_$Index" }
    }
    
    return $FunctionName
}

# Fonction pour crÃ©er une fonction Ã  partir d'un bloc de code
function New-FunctionFromBlock {
    param (
        [string]$BlockText,
        [string]$FunctionName,
        [string]$ScriptType
    )
    
    # CrÃ©er la fonction selon le type de script
    $Function = switch ($ScriptType) {
        "PowerShell" {
@"
function $FunctionName {
    [CmdletBinding()]
    param ()
    
$BlockText
}
"@
        }
        "Python" {
@"
def $FunctionName():
    """
    Fonction extraite pour Ã©liminer la duplication de code.
    """
$BlockText
"@
        }
        "Batch" {
@"
:$FunctionName
$BlockText
goto :eof
"@
        }
        "Shell" {
@"
$FunctionName() {
$BlockText
}
"@
        }
        default { $null }
    }
    
    return $Function
}

# Fonction pour crÃ©er un appel de fonction
function New-FunctionCall {
    param (
        [string]$FunctionName,
        [string]$ScriptType,
        [string]$LibraryPath
    )
    
    # CrÃ©er l'appel de fonction selon le type de script
    $Call = switch ($ScriptType) {
        "PowerShell" {
            $RelativePath = "$LibraryPath\$FunctionName.ps1"
@"
# Appel de fonction extraite pour Ã©liminer la duplication
. "$RelativePath"
$FunctionName
"@
        }
        "Python" {
            $RelativePath = "$LibraryPath/$($FunctionName).py"
            $ImportName = [System.IO.Path]::GetFileNameWithoutExtension($RelativePath).Replace("-", "_")
@"
# Appel de fonction extraite pour Ã©liminer la duplication
from $ImportName import $FunctionName
$FunctionName()
"@
        }
        "Batch" {
            $RelativePath = "$LibraryPath\$FunctionName.cmd"
@"
:: Appel de fonction extraite pour Ã©liminer la duplication
call "$RelativePath"
"@
        }
        "Shell" {
            $RelativePath = "$LibraryPath/$FunctionName.sh"
@"
# Appel de fonction extraite pour Ã©liminer la duplication
source "$RelativePath"
$FunctionName
"@
        }
        default { $null }
    }
    
    return @{
        Call = $Call
        LibraryPath = $RelativePath
    }
}

# Fonction pour crÃ©er une bibliothÃ¨que de fonctions
function New-FunctionLibrary {
    param (
        [string]$FunctionName,
        [string]$FunctionBody,
        [string]$ScriptType,
        [string]$LibraryPath,
        [switch]$Apply
    )
    
    # DÃ©terminer l'extension du fichier selon le type de script
    $Extension = switch ($ScriptType) {
        "PowerShell" { ".ps1" }
        "Python" { ".py" }
        "Batch" { ".cmd" }
        "Shell" { ".sh" }
        default { ".txt" }
    }
    
    # CrÃ©er le chemin complet du fichier
    $FilePath = Join-Path -Path $LibraryPath -ChildPath "$FunctionName$Extension"
    
    # CrÃ©er le contenu du fichier selon le type de script
    $Content = switch ($ScriptType) {
        "PowerShell" {
@"
<#
.SYNOPSIS
    Fonction extraite pour Ã©liminer la duplication de code.
.DESCRIPTION
    Cette fonction a Ã©tÃ© crÃ©Ã©e automatiquement pour Ã©liminer la duplication de code
    dÃ©tectÃ©e dans plusieurs scripts.
.NOTES
    GÃ©nÃ©rÃ© automatiquement par Merge-SimilarScripts.ps1
    Date de crÃ©ation: $(Get-Date -Format "yyyy-MM-dd")
#>

$FunctionBody
"@
        }
        "Python" {
@"
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fonction extraite pour Ã©liminer la duplication de code.

Cette fonction a Ã©tÃ© crÃ©Ã©e automatiquement pour Ã©liminer la duplication de code
dÃ©tectÃ©e dans plusieurs scripts.

GÃ©nÃ©rÃ© automatiquement par Merge-SimilarScripts.ps1
Date de crÃ©ation: $(Get-Date -Format "yyyy-MM-dd")
"""

$FunctionBody
"@
        }
        "Batch" {
@"
@echo off
::-----------------------------------------------------------------------------
:: Nom du script : $FunctionName$Extension
:: Description   : Fonction extraite pour Ã©liminer la duplication de code.
:: GÃ©nÃ©rÃ© automatiquement par Merge-SimilarScripts.ps1
:: Date de crÃ©ation : $(Get-Date -Format "yyyy-MM-dd")
::-----------------------------------------------------------------------------

$FunctionBody
"@
        }
        "Shell" {
@"
#!/bin/bash
#-----------------------------------------------------------------------------
# Nom du script : $FunctionName$Extension
# Description   : Fonction extraite pour Ã©liminer la duplication de code.
# GÃ©nÃ©rÃ© automatiquement par Merge-SimilarScripts.ps1
# Date de crÃ©ation : $(Get-Date -Format "yyyy-MM-dd")
#-----------------------------------------------------------------------------

$FunctionBody
"@
        }
        default { $FunctionBody }
    }
    
    # CrÃ©er le fichier si demandÃ©
    if ($Apply) {
        # CrÃ©er le dossier s'il n'existe pas
        if (-not (Test-Path -Path $LibraryPath)) {
            New-Item -ItemType Directory -Path $LibraryPath -Force | Out-Null
            Write-Log "Dossier de bibliothÃ¨que crÃ©Ã©: $LibraryPath" -Level "SUCCESS"
        }
        
        # CrÃ©er le fichier
        Set-Content -Path $FilePath -Value $Content
        Write-Log "BibliothÃ¨que de fonctions crÃ©Ã©e: $FilePath" -Level "SUCCESS"
    }
    
    return @{
        FilePath = $FilePath
        Content = $Content
    }
}

# Fonction pour remplacer un bloc de code par un appel de fonction
function Update-ScriptWithFunctionCall {
    param (
        [string]$FilePath,
        [string]$BlockText,
        [string]$FunctionCall,
        [switch]$Apply
    )
    
    try {
        # Lire le contenu du fichier
        $Content = Get-Content -Path $FilePath -Raw -ErrorAction Stop
        
        # Remplacer le bloc de code par l'appel de fonction
        $NewContent = $Content.Replace($BlockText, $FunctionCall)
        
        # Appliquer les modifications si demandÃ©
        if ($Apply) {
            Set-Content -Path $FilePath -Value $NewContent
            Write-Log "Script mis Ã  jour: $FilePath" -Level "SUCCESS"
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors de la mise Ã  jour du script $FilePath : $_" -Level "ERROR"
        return $false
    }
}

# Fonction pour fusionner les duplications
function Merge-Duplications {
    param (
        [array]$Duplications,
        [string]$LibraryPath,
        [int]$MinimumDuplicationCount,
        [switch]$Apply
    )
    
    $Results = @()
    
    # Regrouper les duplications par contenu
    $GroupedDuplications = @{}
    
    foreach ($Duplication in $Duplications) {
        if ($Duplication.Type -eq "Exact") {
            $Key = $Duplication.Block1.Hash
            
            if (-not $GroupedDuplications.ContainsKey($Key)) {
                $GroupedDuplications[$Key] = @{
                    BlockText = $Duplication.Block1.Text
                    Occurrences = @()
                }
            }
            
            $GroupedDuplications[$Key].Occurrences += @{
                FilePath = $Duplication.File1
                Block = $Duplication.Block1
            }
            
            $GroupedDuplications[$Key].Occurrences += @{
                FilePath = $Duplication.File2
                Block = $Duplication.Block2
            }
        }
    }
    
    # Traiter chaque groupe de duplications
    $Index = 1
    foreach ($Key in $GroupedDuplications.Keys) {
        $Group = $GroupedDuplications[$Key]
        
        # Filtrer les occurrences uniques
        $UniqueOccurrences = @()
        $SeenFiles = @{}
        
        foreach ($Occurrence in $Group.Occurrences) {
            if (-not $SeenFiles.ContainsKey($Occurrence.FilePath)) {
                $SeenFiles[$Occurrence.FilePath] = $true
                $UniqueOccurrences += $Occurrence
            }
        }
        
        # VÃ©rifier s'il y a suffisamment de duplications
        if ($UniqueOccurrences.Count -ge $MinimumDuplicationCount) {
            # DÃ©terminer le type de script Ã  partir du premier fichier
            $ScriptType = Get-ScriptType -FilePath $UniqueOccurrences[0].FilePath
            
            if ($ScriptType -eq "Unknown") {
                Write-Log "Type de script inconnu pour $($UniqueOccurrences[0].FilePath)" -Level "WARNING"
                continue
            }
            
            # GÃ©nÃ©rer un nom de fonction
            $FunctionName = Get-FunctionName -BlockText $Group.BlockText -ScriptType $ScriptType -Index $Index
            
            # CrÃ©er la fonction
            $Function = New-FunctionFromBlock -BlockText $Group.BlockText -FunctionName $FunctionName -ScriptType $ScriptType
            
            # CrÃ©er l'appel de fonction
            $FunctionCallInfo = New-FunctionCall -FunctionName $FunctionName -ScriptType $ScriptType -LibraryPath $LibraryPath
            
            # CrÃ©er la bibliothÃ¨que de fonctions
            $Library = New-FunctionLibrary -FunctionName $FunctionName -FunctionBody $Function -ScriptType $ScriptType -LibraryPath $LibraryPath -Apply:$Apply
            
            # Mettre Ã  jour les scripts
            $UpdatedFiles = @()
            foreach ($Occurrence in $UniqueOccurrences) {
                $Updated = Update-ScriptWithFunctionCall -FilePath $Occurrence.FilePath -BlockText $Group.BlockText -FunctionCall $FunctionCallInfo.Call -Apply:$Apply
                
                if ($Updated) {
                    $UpdatedFiles += $Occurrence.FilePath
                }
            }
            
            # Ajouter le rÃ©sultat
            $Results += [PSCustomObject]@{
                FunctionName = $FunctionName
                ScriptType = $ScriptType
                LibraryPath = $Library.FilePath
                DuplicationCount = $UniqueOccurrences.Count
                UpdatedFiles = $UpdatedFiles
                Applied = $Apply
            }
            
            $Index++
        }
    }
    
    return $Results
}

# Fonction principale
function Start-ScriptMerge {
    param (
        [string]$InputPath,
        [string]$OutputPath,
        [string]$LibraryPath,
        [int]$MinimumDuplicationCount,
        [switch]$AutoApply,
        [switch]$ShowDetails
    )
    
    Write-Log "DÃ©marrage de la fusion des scripts similaires..." -Level "TITLE"
    Write-Log "Fichier d'entrÃ©e: $InputPath" -Level "INFO"
    Write-Log "Dossier de bibliothÃ¨que: $LibraryPath" -Level "INFO"
    Write-Log "Nombre minimum de duplications: $MinimumDuplicationCount" -Level "INFO"
    Write-Log "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -Level "INFO"
    
    # VÃ©rifier si le fichier d'entrÃ©e existe
    if (-not (Test-Path -Path $InputPath)) {
        Write-Log "Le fichier d'entrÃ©e n'existe pas: $InputPath" -Level "ERROR"
        Write-Log "ExÃ©cutez d'abord Find-CodeDuplication.ps1 pour gÃ©nÃ©rer le rapport." -Level "ERROR"
        return
    }
    
    # CrÃ©er le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie crÃ©Ã©: $OutputDir" -Level "SUCCESS"
    }
    
    # Charger le rapport
    try {
        $Report = Get-Content -Path $InputPath -Raw | ConvertFrom-Json
    } catch {
        Write-Log "Erreur lors du chargement du rapport: $_" -Level "ERROR"
        return
    }
    
    # Fusionner les duplications entre fichiers
    Write-Log "Fusion des duplications entre fichiers..." -Level "INFO"
    $MergeResults = Merge-Duplications -Duplications $Report.InterFileDuplications -LibraryPath $LibraryPath -MinimumDuplicationCount $MinimumDuplicationCount -Apply:$AutoApply
    
    # Enregistrer les rÃ©sultats
    $Results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalMerges = $MergeResults.Count
        MinimumDuplicationCount = $MinimumDuplicationCount
        Applied = $AutoApply
        MergeResults = $MergeResults
    }
    
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    # Afficher un rÃ©sumÃ©
    Write-Log "Fusion terminÃ©e" -Level "SUCCESS"
    Write-Log "Nombre total de fusions: $($Results.TotalMerges)" -Level "INFO"
    
    if ($AutoApply) {
        Write-Log "Fusions appliquÃ©es" -Level "SUCCESS"
    } else {
        Write-Log "Pour appliquer les fusions, exÃ©cutez la commande avec -AutoApply" -Level "WARNING"
    }
    
    Write-Log "RÃ©sultats enregistrÃ©s dans: $OutputPath" -Level "SUCCESS"
    
    return $Results
}

# ExÃ©cuter la fonction principale
Start-ScriptMerge -InputPath $InputPath -OutputPath $OutputPath -LibraryPath $LibraryPath -MinimumDuplicationCount $MinimumDuplicationCount -AutoApply:$AutoApply -ShowDetails:$ShowDetails

