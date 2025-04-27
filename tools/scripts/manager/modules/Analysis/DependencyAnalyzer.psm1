# Module d'analyse des dÃ©pendances pour le Script Manager
# Ce module dÃ©tecte les dÃ©pendances entre les scripts
# Author: Script Manager
# Version: 1.0
# Tags: analysis, dependencies, scripts

function Find-ScriptDependencies {
    <#
    .SYNOPSIS
        DÃ©tecte les dÃ©pendances d'un script
    .DESCRIPTION
        Analyse un script pour dÃ©tecter ses dÃ©pendances (imports, sources, etc.)
    .PARAMETER FilePath
        Chemin du fichier Ã  analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .PARAMETER Verbose
        Affiche des informations dÃ©taillÃ©es pendant l'exÃ©cution
    .EXAMPLE
        Find-ScriptDependencies -FilePath "script.ps1" -ScriptType "PowerShell"
        DÃ©tecte les dÃ©pendances du script PowerShell "script.ps1"
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
    
    # Initialiser le tableau des dÃ©pendances
    $Dependencies = @()
    
    # DÃ©tecter les dÃ©pendances selon le type de script
    switch ($ScriptType) {
        "PowerShell" {
            # DÃ©tecter les Import-Module
            $ImportMatches = [regex]::Matches($Content, "Import-Module\s+([a-zA-Z0-9_\.-]+)")
            foreach ($Match in $ImportMatches) {
                $Dependencies += [PSCustomObject]@{
                    Name = $Match.Groups[1].Value
                    Type = "Module"
                    Path = $null
                }
            }
            
            # DÃ©tecter les . (dot sourcing)
            $DotMatches = [regex]::Matches($Content, "\.\s+([a-zA-Z0-9_\.-\\\/]+)")
            foreach ($Match in $DotMatches) {
                $Path = $Match.Groups[1].Value
                $Dependencies += [PSCustomObject]@{
                    Name = [System.IO.Path]::GetFileName($Path)
                    Type = "Script"
                    Path = $Path
                }
            }
            
            # DÃ©tecter les using module
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
            # DÃ©tecter les import
            $ImportMatches = [regex]::Matches($Content, "import\s+([a-zA-Z0-9_\.]+)")
            foreach ($Match in $ImportMatches) {
                $Dependencies += [PSCustomObject]@{
                    Name = $Match.Groups[1].Value
                    Type = "Module"
                    Path = $null
                }
            }
            
            # DÃ©tecter les from ... import
            $FromMatches = [regex]::Matches($Content, "from\s+([a-zA-Z0-9_\.]+)\s+import")
            foreach ($Match in $FromMatches) {
                $Dependencies += [PSCustomObject]@{
                    Name = $Match.Groups[1].Value
                    Type = "Module"
                    Path = $null
                }
            }
            
            # DÃ©tecter les exec(open(...))
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
            # DÃ©tecter les call
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
            # DÃ©tecter les source
            $SourceMatches = [regex]::Matches($Content, "source\s+([a-zA-Z0-9_\.-\\\/]+)")
            foreach ($Match in $SourceMatches) {
                $Path = $Match.Groups[1].Value
                $Dependencies += [PSCustomObject]@{
                    Name = [System.IO.Path]::GetFileName($Path)
                    Type = "Script"
                    Path = $Path
                }
            }
            
            # DÃ©tecter les . (dot sourcing)
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
    
    # Ã‰liminer les doublons
    $Dependencies = $Dependencies | Sort-Object -Property Name -Unique
    
    return $Dependencies
}

# Exporter les fonctions
Export-ModuleMember -Function Find-ScriptDependencies
