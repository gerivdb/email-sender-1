# Module d'analyse des dépendances pour le Script Manager
# Ce module détecte les dépendances entre les scripts
# Author: Script Manager
# Version: 1.0
# Tags: analysis, dependencies, scripts

function Find-ScriptDependencies {
    <#
    .SYNOPSIS
        Détecte les dépendances d'un script
    .DESCRIPTION
        Analyse un script pour détecter ses dépendances (imports, sources, etc.)
    .PARAMETER FilePath
        Chemin du fichier à analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .PARAMETER Verbose
        Affiche des informations détaillées pendant l'exécution
    .EXAMPLE
        Find-ScriptDependencies -FilePath "script.ps1" -ScriptType "PowerShell"
        Détecte les dépendances du script PowerShell "script.ps1"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$FilePath,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("PowerShell", "Python", "Batch", "Shell", "Unknown")]
        [string]$ScriptType,
        
        [switch]$Verbose
    )
    
    # Lire le contenu du fichier
    $Content = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
    
    if ([string]::IsNullOrEmpty($Content)) {
        return @()
    }
    
    # Initialiser le tableau des dépendances
    $Dependencies = @()
    
    # Détecter les dépendances selon le type de script
    switch ($ScriptType) {
        "PowerShell" {
            # Détecter les Import-Module
            $ImportMatches = [regex]::Matches($Content, "Import-Module\s+([a-zA-Z0-9_\.-]+)")
            foreach ($Match in $ImportMatches) {
                $Dependencies += [PSCustomObject]@{
                    Name = $Match.Groups[1].Value
                    Type = "Module"
                    Path = $null
                }
            }
            
            # Détecter les . (dot sourcing)
            $DotMatches = [regex]::Matches($Content, "\.\s+([a-zA-Z0-9_\.-\\\/]+)")
            foreach ($Match in $DotMatches) {
                $Path = $Match.Groups[1].Value
                $Dependencies += [PSCustomObject]@{
                    Name = [System.IO.Path]::GetFileName($Path)
                    Type = "Script"
                    Path = $Path
                }
            }
            
            # Détecter les using module
            $UsingMatches = [regex]::Matches($Content, "using\s+module\s+([a-zA-Z0-9_\.-]+)")
            foreach ($Match in $UsingMatches) {
                $Dependencies += [PSCustomObject]@{
                    Name = $Match.Groups[1].Value
                    Type = "Module"
                    Path = $null
                }
            }
        }
        "Python" {
            # Détecter les import
            $ImportMatches = [regex]::Matches($Content, "import\s+([a-zA-Z0-9_\.]+)")
            foreach ($Match in $ImportMatches) {
                $Dependencies += [PSCustomObject]@{
                    Name = $Match.Groups[1].Value
                    Type = "Module"
                    Path = $null
                }
            }
            
            # Détecter les from ... import
            $FromMatches = [regex]::Matches($Content, "from\s+([a-zA-Z0-9_\.]+)\s+import")
            foreach ($Match in $FromMatches) {
                $Dependencies += [PSCustomObject]@{
                    Name = $Match.Groups[1].Value
                    Type = "Module"
                    Path = $null
                }
            }
            
            # Détecter les exec(open(...))
            $ExecMatches = [regex]::Matches($Content, "exec\(open\(['\"]([^'\"]+)['\"]")
            foreach ($Match in $ExecMatches) {
                $Path = $Match.Groups[1].Value
                $Dependencies += [PSCustomObject]@{
                    Name = [System.IO.Path]::GetFileName($Path)
                    Type = "Script"
                    Path = $Path
                }
            }
        }
        "Batch" {
            # Détecter les call
            $CallMatches = [regex]::Matches($Content, "call\s+([a-zA-Z0-9_\.-\\\/]+)")
            foreach ($Match in $CallMatches) {
                $Path = $Match.Groups[1].Value
                $Dependencies += [PSCustomObject]@{
                    Name = [System.IO.Path]::GetFileName($Path)
                    Type = "Script"
                    Path = $Path
                }
            }
        }
        "Shell" {
            # Détecter les source
            $SourceMatches = [regex]::Matches($Content, "source\s+([a-zA-Z0-9_\.-\\\/]+)")
            foreach ($Match in $SourceMatches) {
                $Path = $Match.Groups[1].Value
                $Dependencies += [PSCustomObject]@{
                    Name = [System.IO.Path]::GetFileName($Path)
                    Type = "Script"
                    Path = $Path
                }
            }
            
            # Détecter les . (dot sourcing)
            $DotMatches = [regex]::Matches($Content, "\.\s+([a-zA-Z0-9_\.-\\\/]+)")
            foreach ($Match in $DotMatches) {
                $Path = $Match.Groups[1].Value
                $Dependencies += [PSCustomObject]@{
                    Name = [System.IO.Path]::GetFileName($Path)
                    Type = "Script"
                    Path = $Path
                }
            }
        }
    }
    
    # Éliminer les doublons
    $Dependencies = $Dependencies | Sort-Object -Property Name -Unique
    
    return $Dependencies
}

# Exporter les fonctions
Export-ModuleMember -Function Find-ScriptDependencies
