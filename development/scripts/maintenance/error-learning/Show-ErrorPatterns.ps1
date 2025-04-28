#Requires -Version 5.1
<#
.SYNOPSIS
    Affiche les patterns d'erreurs inÃ©dits dans une interface utilisateur simple.
.DESCRIPTION
    Ce script affiche les patterns d'erreurs inÃ©dits dans une interface utilisateur simple,
    permettant de les visualiser, les valider et les explorer.
.PARAMETER DatabasePath
    Chemin vers la base de donnÃ©es d'erreurs.
.PARAMETER OnlyInedited
    Ne montrer que les patterns d'erreurs inÃ©dits.
.EXAMPLE
    .\Show-ErrorPatterns.ps1 -OnlyInedited
.NOTES
    Auteur: Augment Agent
    Version: 1.0
    Date: 2025-04-15
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$DatabasePath = (Join-Path -Path $PSScriptRoot -ChildPath "error_database.json"),
    
    [Parameter(Mandatory = $false)]
    [switch]$OnlyInedited
)

# Importer le module d'analyse des patterns d'erreur
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "ErrorPatternAnalyzer.psm1"

if (-not (Test-Path -Path $modulePath)) {
    Write-Error "Module ErrorPatternAnalyzer non trouvÃ©: $modulePath"
    exit 1
}

Import-Module $modulePath -Force

# Fonction pour afficher un pattern d'erreur
function Show-ErrorPatternDetails {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [PSObject]$Pattern
    )
    
    Clear-Host
    Write-Host "=== $($Pattern.Name) ===" -ForegroundColor Cyan
    Write-Host "ID: $($Pattern.Id)"
    Write-Host "Description: $($Pattern.Description)"
    Write-Host "PremiÃ¨re occurrence: $($Pattern.FirstOccurrence)"
    Write-Host "DerniÃ¨re occurrence: $($Pattern.LastOccurrence)"
    Write-Host "Occurrences: $($Pattern.Occurrences)"
    Write-Host "InÃ©dit: $($Pattern.IsInedited)"
    Write-Host "Statut de validation: $($Pattern.ValidationStatus)"
    Write-Host ""
    
    Write-Host "CaractÃ©ristiques:" -ForegroundColor Yellow
    Write-Host "  Type d'exception: $($Pattern.Features.ExceptionType)"
    Write-Host "  ID d'erreur: $($Pattern.Features.ErrorId)"
    Write-Host "  Contexte: $($Pattern.Features.ScriptContext)"
    Write-Host "  Pattern de message: $($Pattern.Features.MessagePattern)"
    Write-Host "  Pattern de ligne: $($Pattern.Features.LinePattern)"
    Write-Host ""
    
    if ($Pattern.Examples.Count -gt 0) {
        Write-Host "Exemples d'erreurs:" -ForegroundColor Yellow
        
        for ($i = 0; $i -lt [Math]::Min($Pattern.Examples.Count, 3); $i++) {
            $example = $Pattern.Examples[$i]
            
            Write-Host "Exemple $($i + 1):" -ForegroundColor Green
            Write-Host "  Message: $($example.Message)"
            Write-Host "  Script: $($example.ScriptName):$($example.ScriptLineNumber)"
            Write-Host "  Ligne: $($example.Line)"
            Write-Host "  Timestamp: $($example.Timestamp)"
            Write-Host ""
        }
    }
    
    if ($Pattern.RelatedPatterns.Count -gt 0) {
        Write-Host "Patterns liÃ©s:" -ForegroundColor Yellow
        
        foreach ($relatedPattern in $Pattern.RelatedPatterns) {
            $related = Get-ErrorPattern -PatternId $relatedPattern.PatternId
            
            if ($related) {
                Write-Host "  $($related.Name) ($($relatedPattern.Relationship), SimilaritÃ©: $([Math]::Round($relatedPattern.Similarity * 100, 2))%)"
            }
        }
        
        Write-Host ""
    }
    
    Write-Host "Actions:" -ForegroundColor Magenta
    Write-Host "  [V] Valider le pattern"
    Write-Host "  [I] Invalider le pattern"
    Write-Host "  [D] Marquer comme doublon"
    Write-Host "  [E] Modifier la description"
    Write-Host "  [N] Modifier le nom"
    Write-Host "  [T] Basculer le statut 'inÃ©dit'"
    Write-Host "  [R] Retour Ã  la liste"
    Write-Host ""
    
    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character.ToString().ToUpper()
    
    switch ($key) {
        "V" {
            Confirm-ErrorPattern -PatternId $Pattern.Id -ValidationStatus "Valid"
            Write-Host "Pattern validÃ©." -ForegroundColor Green
            Start-Sleep -Seconds 1
        }
        "I" {
            Confirm-ErrorPattern -PatternId $Pattern.Id -ValidationStatus "Invalid"
            Write-Host "Pattern invalidÃ©." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
        "D" {
            Confirm-ErrorPattern -PatternId $Pattern.Id -ValidationStatus "Duplicate"
            Write-Host "Pattern marquÃ© comme doublon." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
        "E" {
            $description = Read-Host "Nouvelle description"
            if ($description) {
                Confirm-ErrorPattern -PatternId $Pattern.Id -ValidationStatus $Pattern.ValidationStatus -Description $description
                Write-Host "Description mise Ã  jour." -ForegroundColor Green
                Start-Sleep -Seconds 1
            }
        }
        "N" {
            $name = Read-Host "Nouveau nom"
            if ($name) {
                Confirm-ErrorPattern -PatternId $Pattern.Id -ValidationStatus $Pattern.ValidationStatus -Name $name
                Write-Host "Nom mis Ã  jour." -ForegroundColor Green
                Start-Sleep -Seconds 1
            }
        }
        "T" {
            Confirm-ErrorPattern -PatternId $Pattern.Id -ValidationStatus $Pattern.ValidationStatus -IsInedited:(-not $Pattern.IsInedited)
            Write-Host "Statut 'inÃ©dit' basculÃ©." -ForegroundColor Green
            Start-Sleep -Seconds 1
        }
        "R" {
            return
        }
        default {
            Write-Host "Action non reconnue." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
    
    # RafraÃ®chir le pattern
    $refreshedPattern = Get-ErrorPattern -PatternId $Pattern.Id -IncludeExamples
    Show-ErrorPatternDetails -Pattern $refreshedPattern
}

# Fonction pour afficher la liste des patterns d'erreur
function Show-ErrorPatternList {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [switch]$OnlyInedited
    )
    
    $patterns = Get-ErrorPattern -IncludeExamples
    
    if ($OnlyInedited) {
        $patterns = $patterns | Where-Object { $_.IsInedited }
    }
    
    if ($patterns.Count -eq 0) {
        Clear-Host
        Write-Host "Aucun pattern d'erreur trouvÃ©." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Appuyez sur une touche pour quitter..."
        $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        return
    }
    
    $selectedIndex = 0
    $pageSize = 10
    $pageIndex = 0
    
    $continue = $true
    
    while ($continue) {
        Clear-Host
        Write-Host "=== Patterns d'erreur ===" -ForegroundColor Cyan
        Write-Host "Utilisez les flÃ¨ches haut/bas pour naviguer, EntrÃ©e pour sÃ©lectionner, Q pour quitter."
        Write-Host "Page $($pageIndex + 1)/$([Math]::Ceiling($patterns.Count / $pageSize))" -ForegroundColor Gray
        Write-Host ""
        
        $startIndex = $pageIndex * $pageSize
        $endIndex = [Math]::Min($startIndex + $pageSize - 1, $patterns.Count - 1)
        
        for ($i = $startIndex; $i -le $endIndex; $i++) {
            $pattern = $patterns[$i]
            $selected = $i -eq $selectedIndex
            
            $statusColor = switch ($pattern.ValidationStatus) {
                "Valid" { "Green" }
                "Invalid" { "Red" }
                "Duplicate" { "Yellow" }
                default { "Gray" }
            }
            
            $prefix = if ($selected) { ">" } else { " " }
            $ineditedMark = if ($pattern.IsInedited) { "[!]" } else { "   " }
            
            Write-Host "$prefix $ineditedMark $($pattern.Name.PadRight(30)) | $($pattern.Occurrences.ToString().PadLeft(3)) | " -NoNewline
            Write-Host $pattern.ValidationStatus -ForegroundColor $statusColor
        }
        
        $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        
        switch ($key.VirtualKeyCode) {
            38 {  # FlÃ¨che haut
                $selectedIndex = [Math]::Max($selectedIndex - 1, 0)
                
                if ($selectedIndex -lt $startIndex) {
                    $pageIndex = [Math]::Max($pageIndex - 1, 0)
                }
            }
            40 {  # FlÃ¨che bas
                $selectedIndex = [Math]::Min($selectedIndex + 1, $patterns.Count - 1)
                
                if ($selectedIndex -gt $endIndex) {
                    $pageIndex = [Math]::Min($pageIndex + 1, [Math]::Ceiling($patterns.Count / $pageSize) - 1)
                }
            }
            33 {  # Page Up
                $pageIndex = [Math]::Max($pageIndex - 1, 0)
                $selectedIndex = $pageIndex * $pageSize
            }
            34 {  # Page Down
                $pageIndex = [Math]::Min($pageIndex + 1, [Math]::Ceiling($patterns.Count / $pageSize) - 1)
                $selectedIndex = $pageIndex * $pageSize
            }
            13 {  # EntrÃ©e
                Show-ErrorPatternDetails -Pattern $patterns[$selectedIndex]
            }
            81 {  # Q
                $continue = $false
            }
        }
    }
}

# ExÃ©cution principale
Show-ErrorPatternList -OnlyInedited:$OnlyInedited
