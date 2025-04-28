# Module de dÃ©tection des dÃ©pendances pour le Script Manager
# Ce module dÃ©tecte les dÃ©pendances entre les scripts
# Author: Script Manager
# Version: 1.0
# Tags: analysis, dependencies, scripts

function Get-ScriptDependencies {
    <#
    .SYNOPSIS
        DÃ©tecte les dÃ©pendances d'un script
    .DESCRIPTION
        Analyse le contenu d'un script pour dÃ©tecter les rÃ©fÃ©rences Ã  d'autres scripts ou modules
    .PARAMETER Content
        Contenu du script Ã  analyser
    .PARAMETER ScriptType
        Type de script (PowerShell, Python, Batch, Shell)
    .PARAMETER Path
        Chemin du script (utilisÃ© pour rÃ©soudre les chemins relatifs)
    .EXAMPLE
        Get-ScriptDependencies -Content $scriptContent -ScriptType "PowerShell" -Path "C:\Scripts\MyScript.ps1"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Content,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("PowerShell", "Python", "Batch", "Shell", "Unknown")]
        [string]$ScriptType,
        
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    
    # Initialiser le tableau des dÃ©pendances
    $Dependencies = @()
    
    # Obtenir le rÃ©pertoire du script
    $ScriptDirectory = Split-Path -Path $Path -Parent
    
    # Analyse spÃ©cifique au type de script
    switch ($ScriptType) {
        "PowerShell" {
            # DÃ©tecter les imports de modules
            $ModuleImports = [regex]::Matches($Content, "Import-Module\s+([a-zA-Z0-9_\.-]+)")
            foreach ($Import in $ModuleImports) {
                $ModuleName = $Import.Groups[1].Value.Trim()
                $Dependencies += [PSCustomObject]@{
                    Type = "Module"
                    Name = $ModuleName
                    Path = $null  # Le chemin sera rÃ©solu plus tard si possible
                    ImportType = "Import-Module"
                }
            }
            
            # DÃ©tecter les sources de scripts
            $ScriptSources = [regex]::Matches($Content, "\.\s+['`"]?(.*\.ps1)['`"]?")
            foreach ($Source in $ScriptSources) {
                $ScriptPath = $Source.Groups[1].Value.Trim()
                
                # RÃ©soudre le chemin relatif si possible
                $ResolvedPath = $null
                if (-not [System.IO.Path]::IsPathRooted($ScriptPath)) {
                    $ResolvedPath = Join-Path -Path $ScriptDirectory -ChildPath $ScriptPath
                    if (-not (Test-Path -Path $ResolvedPath)) {
                        $ResolvedPath = $null
                    }
                } elseif (Test-Path -Path $ScriptPath) {
                    $ResolvedPath = $ScriptPath
                }
                
                $Dependencies += [PSCustomObject]@{
                    Type = "Script"
                    Name = Split-Path -Path $ScriptPath -Leaf
                    Path = $ResolvedPath
                    ImportType = "Dot-Source"
                }
            }
            
            # DÃ©tecter les appels Ã  d'autres scripts
            $ScriptCalls = [regex]::Matches($Content, "&\s+['`"]?(.*\.ps1)['`"]?")
            foreach ($Call in $ScriptCalls) {
                $ScriptPath = $Call.Groups[1].Value.Trim()
                
                # RÃ©soudre le chemin relatif si possible
                $ResolvedPath = $null
                if (-not [System.IO.Path]::IsPathRooted($ScriptPath)) {
                    $ResolvedPath = Join-Path -Path $ScriptDirectory -ChildPath $ScriptPath
                    if (-not (Test-Path -Path $ResolvedPath)) {
                        $ResolvedPath = $null
                    }
                } elseif (Test-Path -Path $ScriptPath) {
                    $ResolvedPath = $ScriptPath
                }
                
                $Dependencies += [PSCustomObject]@{
                    Type = "Script"
                    Name = Split-Path -Path $ScriptPath -Leaf
                    Path = $ResolvedPath
                    ImportType = "Call"
                }
            }
        }
        "Python" {
            # DÃ©tecter les imports de modules
            $ModuleImports = [regex]::Matches($Content, "import\s+([a-zA-Z0-9_\.]+)")
            foreach ($Import in $ModuleImports) {
                $ModuleName = $Import.Groups[1].Value.Trim()
                $Dependencies += [PSCustomObject]@{
                    Type = "Module"
                    Name = $ModuleName
                    Path = $null
                    ImportType = "Import"
                }
            }
            
            # DÃ©tecter les imports from
            $FromImports = [regex]::Matches($Content, "from\s+([a-zA-Z0-9_\.]+)\s+import")
            foreach ($Import in $FromImports) {
                $ModuleName = $Import.Groups[1].Value.Trim()
                $Dependencies += [PSCustomObject]@{
                    Type = "Module"
                    Name = $ModuleName
                    Path = $null
                    ImportType = "From-Import"
                }
            }
            
            # DÃ©tecter les exÃ©cutions de scripts
            $ScriptExecs = [regex]::Matches($Content, "exec\(open\(['`"](.+\.py)['`"]\)")
            foreach ($Exec in $ScriptExecs) {
                $ScriptPath = $Exec.Groups[1].Value.Trim()
                
                # RÃ©soudre le chemin relatif si possible
                $ResolvedPath = $null
                if (-not [System.IO.Path]::IsPathRooted($ScriptPath)) {
                    $ResolvedPath = Join-Path -Path $ScriptDirectory -ChildPath $ScriptPath
                    if (-not (Test-Path -Path $ResolvedPath)) {
                        $ResolvedPath = $null
                    }
                } elseif (Test-Path -Path $ScriptPath) {
                    $ResolvedPath = $ScriptPath
                }
                
                $Dependencies += [PSCustomObject]@{
                    Type = "Script"
                    Name = Split-Path -Path $ScriptPath -Leaf
                    Path = $ResolvedPath
                    ImportType = "Exec"
                }
            }
        }
        "Batch" {
            # DÃ©tecter les appels Ã  d'autres scripts
            $ScriptCalls = [regex]::Matches($Content, "call\s+['`"]?(.*\.(bat|cmd))['`"]?")
            foreach ($Call in $ScriptCalls) {
                $ScriptPath = $Call.Groups[1].Value.Trim()
                
                # RÃ©soudre le chemin relatif si possible
                $ResolvedPath = $null
                if (-not [System.IO.Path]::IsPathRooted($ScriptPath)) {
                    $ResolvedPath = Join-Path -Path $ScriptDirectory -ChildPath $ScriptPath
                    if (-not (Test-Path -Path $ResolvedPath)) {
                        $ResolvedPath = $null
                    }
                } elseif (Test-Path -Path $ScriptPath) {
                    $ResolvedPath = $ScriptPath
                }
                
                $Dependencies += [PSCustomObject]@{
                    Type = "Script"
                    Name = Split-Path -Path $ScriptPath -Leaf
                    Path = $ResolvedPath
                    ImportType = "Call"
                }
            }
        }
        "Shell" {
            # DÃ©tecter les sources de scripts
            $ScriptSources = [regex]::Matches($Content, "source\s+['`"]?(.*\.sh)['`"]?|.\s+['`"]?(.*\.sh)['`"]?")
            foreach ($Source in $ScriptSources) {
                $ScriptPath = if ($Source.Groups[1].Value) { $Source.Groups[1].Value.Trim() } else { $Source.Groups[2].Value.Trim() }
                
                # RÃ©soudre le chemin relatif si possible
                $ResolvedPath = $null
                if (-not [System.IO.Path]::IsPathRooted($ScriptPath)) {
                    $ResolvedPath = Join-Path -Path $ScriptDirectory -ChildPath $ScriptPath
                    if (-not (Test-Path -Path $ResolvedPath)) {
                        $ResolvedPath = $null
                    }
                } elseif (Test-Path -Path $ScriptPath) {
                    $ResolvedPath = $ScriptPath
                }
                
                $Dependencies += [PSCustomObject]@{
                    Type = "Script"
                    Name = Split-Path -Path $ScriptPath -Leaf
                    Path = $ResolvedPath
                    ImportType = "Source"
                }
            }
        }
    }
    
    # Ã‰liminer les doublons
    $Dependencies = $Dependencies | Sort-Object -Property Name, Type -Unique
    
    return $Dependencies
}

# Exporter les fonctions
Export-ModuleMember -Function Get-ScriptDependencies
