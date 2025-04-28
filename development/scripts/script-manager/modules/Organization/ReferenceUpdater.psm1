# Module de mise Ã  jour des rÃ©fÃ©rences pour le Script Manager
# Ce module met Ã  jour les rÃ©fÃ©rences entre scripts aprÃ¨s dÃ©placement
# Author: Script Manager
# Version: 1.0
# Tags: organization, scripts, references

function Update-References {
    <#
    .SYNOPSIS
        Met Ã  jour les rÃ©fÃ©rences aprÃ¨s le dÃ©placement d'un script
    .DESCRIPTION
        Recherche et met Ã  jour les rÃ©fÃ©rences au script dÃ©placÃ© dans les autres scripts
    .PARAMETER Script
        Objet script qui a Ã©tÃ© dÃ©placÃ©
    .PARAMETER OldPath
        Ancien chemin du script
    .PARAMETER NewPath
        Nouveau chemin du script
    .EXAMPLE
        Update-References -Script $script -OldPath "scripts/old/script.ps1" -NewPath "scripts/new/script.ps1"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Script,
        
        [Parameter(Mandatory=$true)]
        [string]$OldPath,
        
        [Parameter(Mandatory=$true)]
        [string]$NewPath
    )
    
    # Initialiser le compteur de rÃ©fÃ©rences mises Ã  jour
    $UpdatedReferences = 0
    
    # Obtenir le nom du script
    $ScriptName = Split-Path -Path $OldPath -Leaf
    
    # DÃ©terminer les chemins relatifs
    $OldRelativePath = $OldPath
    $NewRelativePath = $NewPath
    
    # Rechercher les scripts qui pourraient rÃ©fÃ©rencer ce script
    $PotentialReferencers = Get-ChildItem -Path "scripts" -Recurse -File | Where-Object {
        $_.Extension -in ".ps1", ".py", ".cmd", ".bat", ".sh"
    }
    
    foreach ($Referencer in $PotentialReferencers) {
        # Ignorer le script lui-mÃªme
        if ($Referencer.FullName -eq $NewPath) {
            continue
        }
        
        # Lire le contenu du script
        $Content = Get-Content -Path $Referencer.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($null -eq $Content) {
            continue
        }
        
        # DÃ©terminer le type de script
        $ScriptType = switch ($Referencer.Extension) {
            ".ps1" { "PowerShell" }
            ".py"  { "Python" }
            ".cmd" { "Batch" }
            ".bat" { "Batch" }
            ".sh"  { "Shell" }
            default { "Unknown" }
        }
        
        # Calculer le chemin relatif entre le rÃ©fÃ©renceur et le script dÃ©placÃ©
        $ReferencerDir = Split-Path -Path $Referencer.FullName -Parent
        $OldRelativeToReferencer = Get-RelativePath -From $ReferencerDir -To $OldPath
        $NewRelativeToReferencer = Get-RelativePath -From $ReferencerDir -To $NewPath
        
        # Rechercher et remplacer les rÃ©fÃ©rences
        $UpdatedContent = $Content
        $Updated = $false
        
        switch ($ScriptType) {
            "PowerShell" {
                # Rechercher les rÃ©fÃ©rences de type dot-sourcing
                $DotSourcePattern = "(\.\s+['`"]?)$([regex]::Escape($OldRelativeToReferencer))(['`"]?)"
                if ($Content -match $DotSourcePattern) {
                    $UpdatedContent = $UpdatedContent -replace $DotSourcePattern, "`$1$NewRelativeToReferencer`$2"
                    $Updated = $true
                }
                
                # Rechercher les rÃ©fÃ©rences de type appel
                $CallPattern = "(&\s+['`"]?)$([regex]::Escape($OldRelativeToReferencer))(['`"]?)"
                if ($Content -match $CallPattern) {
                    $UpdatedContent = $UpdatedContent -replace $CallPattern, "`$1$NewRelativeToReferencer`$2"
                    $Updated = $true
                }
            }
            "Python" {
                # Rechercher les rÃ©fÃ©rences de type exec
                $ExecPattern = "(exec\(open\(['`"]?)$([regex]::Escape($OldRelativeToReferencer))(['`"]?\))"
                if ($Content -match $ExecPattern) {
                    $UpdatedContent = $UpdatedContent -replace $ExecPattern, "`$1$NewRelativeToReferencer`$2"
                    $Updated = $true
                }
            }
            "Batch" {
                # Rechercher les rÃ©fÃ©rences de type call
                $CallPattern = "(call\s+['`"]?)$([regex]::Escape($OldRelativeToReferencer))(['`"]?)"
                if ($Content -match $CallPattern) {
                    $UpdatedContent = $UpdatedContent -replace $CallPattern, "`$1$NewRelativeToReferencer`$2"
                    $Updated = $true
                }
            }
            "Shell" {
                # Rechercher les rÃ©fÃ©rences de type source
                $SourcePattern = "(source\s+['`"]?)$([regex]::Escape($OldRelativeToReferencer))(['`"]?)"
                if ($Content -match $SourcePattern) {
                    $UpdatedContent = $UpdatedContent -replace $SourcePattern, "`$1$NewRelativeToReferencer`$2"
                    $Updated = $true
                }
                
                # Rechercher les rÃ©fÃ©rences de type dot
                $DotPattern = "(\.\s+['`"]?)$([regex]::Escape($OldRelativeToReferencer))(['`"]?)"
                if ($Content -match $DotPattern) {
                    $UpdatedContent = $UpdatedContent -replace $DotPattern, "`$1$NewRelativeToReferencer`$2"
                    $Updated = $true
                }
            }
        }
        
        # Si des rÃ©fÃ©rences ont Ã©tÃ© mises Ã  jour, enregistrer le fichier
        if ($Updated) {
            Set-Content -Path $Referencer.FullName -Value $UpdatedContent
            $UpdatedReferences++
            Write-Host "  RÃ©fÃ©rences mises Ã  jour dans: $($Referencer.FullName)" -ForegroundColor Green
        }
    }
    
    Write-Host "  $UpdatedReferences rÃ©fÃ©rences mises Ã  jour" -ForegroundColor Cyan
    
    return $UpdatedReferences
}

function Get-RelativePath {
    <#
    .SYNOPSIS
        Calcule le chemin relatif entre deux chemins
    .DESCRIPTION
        Calcule le chemin relatif du chemin cible par rapport au chemin source
    .PARAMETER From
        Chemin source
    .PARAMETER To
        Chemin cible
    .EXAMPLE
        Get-RelativePath -From "C:\Scripts\A" -To "C:\Scripts\B\script.ps1"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$From,
        
        [Parameter(Mandatory=$true)]
        [string]$To
    )
    
    # Convertir les chemins en objets System.Uri
    $FromUri = New-Object System.Uri($From)
    $ToUri = New-Object System.Uri($To)
    
    # Calculer le chemin relatif
    $RelativeUri = $FromUri.MakeRelativeUri($ToUri)
    $RelativePath = [System.Uri]::UnescapeDataString($RelativeUri.ToString())
    
    # Remplacer les sÃ©parateurs de chemin
    $RelativePath = $RelativePath -replace '/', [System.IO.Path]::DirectorySeparatorChar
    
    return $RelativePath
}

# Exporter les fonctions
Export-ModuleMember -Function Update-References, Get-RelativePath
