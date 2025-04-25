<#
.SYNOPSIS
    Fusionne les scripts similaires pour éliminer les duplications.
.DESCRIPTION
    Ce script utilise le rapport généré par Find-CodeDuplication.ps1 pour fusionner
    les scripts similaires et éliminer les duplications de code. Il crée des fonctions
    réutilisables pour le code dupliqué et met à jour les références.
.PARAMETER InputPath
    Chemin du fichier de rapport généré par Find-CodeDuplication.ps1.
    Par défaut: scripts\manager\data\duplication_report.json
.PARAMETER OutputPath
    Chemin du fichier de sortie pour le rapport des fusions.
    Par défaut: scripts\manager\data\merge_report.json
.PARAMETER LibraryPath
    Chemin du dossier où seront créées les bibliothèques de fonctions.
    Par défaut: scripts\common\lib
.PARAMETER MinimumDuplicationCount
    Nombre minimum de duplications pour créer une fonction réutilisable. Par défaut: 2
.PARAMETER AutoApply
    Applique automatiquement les modifications sans demander de confirmation.
.PARAMETER ShowDetails
    Affiche des informations détaillées pendant l'exécution.
.EXAMPLE
    .\Merge-SimilarScripts.ps1
    Analyse le rapport et propose des fusions pour les scripts similaires.
.EXAMPLE
    .\Merge-SimilarScripts.ps1 -AutoApply
    Analyse le rapport et applique automatiquement les fusions.
#>

param (
    [string]$InputPath = "scripts\manager\data\duplication_report.json",
    [string]$OutputPath = "scripts\manager\data\merge_report.json",
    [string]$LibraryPath = "scripts\common\lib",
    [int]$MinimumDuplicationCount = 2,
    [switch]$AutoApply,
    [switch]$ShowDetails
)

# Fonction pour écrire des messages de log
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
    
    # Écrire dans un fichier de log
    $LogFile = "scripts\manager\data\script_merge.log"
    Add-Content -Path $LogFile -Value $FormattedMessage -ErrorAction SilentlyContinue
}

# Fonction pour déterminer le type de script
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

# Fonction pour générer un nom de fonction à partir d'un bloc de code
function Get-FunctionName {
    param (
        [string]$BlockText,
        [string]$ScriptType,
        [int]$Index
    )
    
    # Extraire les mots clés du bloc de code
    $Keywords = $BlockText -split "\W+" | Where-Object { $_ -match "^[a-zA-Z][a-zA-Z0-9_]*$" -and $_.Length -gt 3 }
    
    # Filtrer les mots-clés réservés selon le type de script
    $ReservedKeywords = switch ($ScriptType) {
        "PowerShell" { @("function", "param", "begin", "process", "end", "if", "else", "elseif", "switch", "for", "foreach", "while", "do", "until", "break", "continue", "return", "throw", "try", "catch", "finally") }
        "Python" { @("def", "class", "if", "else", "elif", "for", "while", "try", "except", "finally", "with", "import", "from", "as", "return", "yield", "break", "continue", "pass", "raise", "global", "nonlocal") }
        "Batch" { @("echo", "set", "setlocal", "endlocal", "call", "goto", "if", "else", "for", "in", "do", "rem") }
        "Shell" { @("function", "if", "then", "else", "elif", "fi", "for", "while", "until", "do", "done", "case", "esac", "echo", "read", "exit", "return", "break", "continue", "shift") }
        default { @() }
    }
    
    $FilteredKeywords = $Keywords | Where-Object { $ReservedKeywords -notcontains $_ }
    
    # Générer un nom de fonction à partir des mots-clés
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

# Fonction pour créer une fonction à partir d'un bloc de code
function New-FunctionFromBlock {
    param (
        [string]$BlockText,
        [string]$FunctionName,
        [string]$ScriptType
    )
    
    # Créer la fonction selon le type de script
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
    Fonction extraite pour éliminer la duplication de code.
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

# Fonction pour créer un appel de fonction
function New-FunctionCall {
    param (
        [string]$FunctionName,
        [string]$ScriptType,
        [string]$LibraryPath
    )
    
    # Créer l'appel de fonction selon le type de script
    $Call = switch ($ScriptType) {
        "PowerShell" {
            $RelativePath = "$LibraryPath\$FunctionName.ps1"
@"
# Appel de fonction extraite pour éliminer la duplication
. "$RelativePath"
$FunctionName
"@
        }
        "Python" {
            $RelativePath = "$LibraryPath/$($FunctionName).py"
            $ImportName = [System.IO.Path]::GetFileNameWithoutExtension($RelativePath).Replace("-", "_")
@"
# Appel de fonction extraite pour éliminer la duplication
from $ImportName import $FunctionName
$FunctionName()
"@
        }
        "Batch" {
            $RelativePath = "$LibraryPath\$FunctionName.cmd"
@"
:: Appel de fonction extraite pour éliminer la duplication
call "$RelativePath"
"@
        }
        "Shell" {
            $RelativePath = "$LibraryPath/$FunctionName.sh"
@"
# Appel de fonction extraite pour éliminer la duplication
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

# Fonction pour créer une bibliothèque de fonctions
function New-FunctionLibrary {
    param (
        [string]$FunctionName,
        [string]$FunctionBody,
        [string]$ScriptType,
        [string]$LibraryPath,
        [switch]$Apply
    )
    
    # Déterminer l'extension du fichier selon le type de script
    $Extension = switch ($ScriptType) {
        "PowerShell" { ".ps1" }
        "Python" { ".py" }
        "Batch" { ".cmd" }
        "Shell" { ".sh" }
        default { ".txt" }
    }
    
    # Créer le chemin complet du fichier
    $FilePath = Join-Path -Path $LibraryPath -ChildPath "$FunctionName$Extension"
    
    # Créer le contenu du fichier selon le type de script
    $Content = switch ($ScriptType) {
        "PowerShell" {
@"
<#
.SYNOPSIS
    Fonction extraite pour éliminer la duplication de code.
.DESCRIPTION
    Cette fonction a été créée automatiquement pour éliminer la duplication de code
    détectée dans plusieurs scripts.
.NOTES
    Généré automatiquement par Merge-SimilarScripts.ps1
    Date de création: $(Get-Date -Format "yyyy-MM-dd")
#>

$FunctionBody
"@
        }
        "Python" {
@"
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Fonction extraite pour éliminer la duplication de code.

Cette fonction a été créée automatiquement pour éliminer la duplication de code
détectée dans plusieurs scripts.

Généré automatiquement par Merge-SimilarScripts.ps1
Date de création: $(Get-Date -Format "yyyy-MM-dd")
"""

$FunctionBody
"@
        }
        "Batch" {
@"
@echo off
::-----------------------------------------------------------------------------
:: Nom du script : $FunctionName$Extension
:: Description   : Fonction extraite pour éliminer la duplication de code.
:: Généré automatiquement par Merge-SimilarScripts.ps1
:: Date de création : $(Get-Date -Format "yyyy-MM-dd")
::-----------------------------------------------------------------------------

$FunctionBody
"@
        }
        "Shell" {
@"
#!/bin/bash
#-----------------------------------------------------------------------------
# Nom du script : $FunctionName$Extension
# Description   : Fonction extraite pour éliminer la duplication de code.
# Généré automatiquement par Merge-SimilarScripts.ps1
# Date de création : $(Get-Date -Format "yyyy-MM-dd")
#-----------------------------------------------------------------------------

$FunctionBody
"@
        }
        default { $FunctionBody }
    }
    
    # Créer le fichier si demandé
    if ($Apply) {
        # Créer le dossier s'il n'existe pas
        if (-not (Test-Path -Path $LibraryPath)) {
            New-Item -ItemType Directory -Path $LibraryPath -Force | Out-Null
            Write-Log "Dossier de bibliothèque créé: $LibraryPath" -Level "SUCCESS"
        }
        
        # Créer le fichier
        Set-Content -Path $FilePath -Value $Content
        Write-Log "Bibliothèque de fonctions créée: $FilePath" -Level "SUCCESS"
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
        
        # Appliquer les modifications si demandé
        if ($Apply) {
            Set-Content -Path $FilePath -Value $NewContent
            Write-Log "Script mis à jour: $FilePath" -Level "SUCCESS"
        }
        
        return $true
    } catch {
        Write-Log "Erreur lors de la mise à jour du script $FilePath : $_" -Level "ERROR"
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
        
        # Vérifier s'il y a suffisamment de duplications
        if ($UniqueOccurrences.Count -ge $MinimumDuplicationCount) {
            # Déterminer le type de script à partir du premier fichier
            $ScriptType = Get-ScriptType -FilePath $UniqueOccurrences[0].FilePath
            
            if ($ScriptType -eq "Unknown") {
                Write-Log "Type de script inconnu pour $($UniqueOccurrences[0].FilePath)" -Level "WARNING"
                continue
            }
            
            # Générer un nom de fonction
            $FunctionName = Get-FunctionName -BlockText $Group.BlockText -ScriptType $ScriptType -Index $Index
            
            # Créer la fonction
            $Function = New-FunctionFromBlock -BlockText $Group.BlockText -FunctionName $FunctionName -ScriptType $ScriptType
            
            # Créer l'appel de fonction
            $FunctionCallInfo = New-FunctionCall -FunctionName $FunctionName -ScriptType $ScriptType -LibraryPath $LibraryPath
            
            # Créer la bibliothèque de fonctions
            $Library = New-FunctionLibrary -FunctionName $FunctionName -FunctionBody $Function -ScriptType $ScriptType -LibraryPath $LibraryPath -Apply:$Apply
            
            # Mettre à jour les scripts
            $UpdatedFiles = @()
            foreach ($Occurrence in $UniqueOccurrences) {
                $Updated = Update-ScriptWithFunctionCall -FilePath $Occurrence.FilePath -BlockText $Group.BlockText -FunctionCall $FunctionCallInfo.Call -Apply:$Apply
                
                if ($Updated) {
                    $UpdatedFiles += $Occurrence.FilePath
                }
            }
            
            # Ajouter le résultat
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
    
    Write-Log "Démarrage de la fusion des scripts similaires..." -Level "TITLE"
    Write-Log "Fichier d'entrée: $InputPath" -Level "INFO"
    Write-Log "Dossier de bibliothèque: $LibraryPath" -Level "INFO"
    Write-Log "Nombre minimum de duplications: $MinimumDuplicationCount" -Level "INFO"
    Write-Log "Mode: $(if ($AutoApply) { 'Application automatique' } else { 'Simulation' })" -Level "INFO"
    
    # Vérifier si le fichier d'entrée existe
    if (-not (Test-Path -Path $InputPath)) {
        Write-Log "Le fichier d'entrée n'existe pas: $InputPath" -Level "ERROR"
        Write-Log "Exécutez d'abord Find-CodeDuplication.ps1 pour générer le rapport." -Level "ERROR"
        return
    }
    
    # Créer le dossier de sortie s'il n'existe pas
    $OutputDir = Split-Path -Path $OutputPath -Parent
    if (-not (Test-Path -Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Log "Dossier de sortie créé: $OutputDir" -Level "SUCCESS"
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
    
    # Enregistrer les résultats
    $Results = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        TotalMerges = $MergeResults.Count
        MinimumDuplicationCount = $MinimumDuplicationCount
        Applied = $AutoApply
        MergeResults = $MergeResults
    }
    
    $Results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
    
    # Afficher un résumé
    Write-Log "Fusion terminée" -Level "SUCCESS"
    Write-Log "Nombre total de fusions: $($Results.TotalMerges)" -Level "INFO"
    
    if ($AutoApply) {
        Write-Log "Fusions appliquées" -Level "SUCCESS"
    } else {
        Write-Log "Pour appliquer les fusions, exécutez la commande avec -AutoApply" -Level "WARNING"
    }
    
    Write-Log "Résultats enregistrés dans: $OutputPath" -Level "SUCCESS"
    
    return $Results
}

# Exécuter la fonction principale
Start-ScriptMerge -InputPath $InputPath -OutputPath $OutputPath -LibraryPath $LibraryPath -MinimumDuplicationCount $MinimumDuplicationCount -AutoApply:$AutoApply -ShowDetails:$ShowDetails
