<#
.SYNOPSIS
    Ajoute automatiquement des blocs try/catch aux scripts PowerShell.
.DESCRIPTION
    Ce script ajoute automatiquement des blocs try/catch aux scripts PowerShell
    existants pour amÃ©liorer leur gestion d'erreurs.
.EXAMPLE
    . .\TryCatchAdder.ps1
    Add-TryCatchBlocks -Path "C:\path\to\script.ps1" -CreateBackup
#>

# Importer le module d'analyse de scripts
$analyzerPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "ScriptAnalyzer.ps1"
if (Test-Path -Path $analyzerPath) {
    . $analyzerPath
}
else {
    Write-Error "Le module d'analyse de scripts est requis mais introuvable Ã  l'emplacement: $analyzerPath"
    return
}

function Add-TryCatchBlocks {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddLogging,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    process {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-Error "Le fichier '$Path' n'existe pas."
            return $false
        }
        
        # Utiliser la fonction d'ajout de gestion d'erreurs du module d'analyse
        $result = Add-ErrorHandlingToScript -Path $Path -OutputPath $OutputPath -Backup:$CreateBackup -AddLogging:$AddLogging -WhatIf:$WhatIf
        
        return $result
    }
}

function Add-TryCatchToDirectory {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Filter = "*.ps1",
        
        [Parameter(Mandatory = $false)]
        [switch]$Recurse,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddLogging,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $Path -PathType Container)) {
        Write-Error "Le rÃ©pertoire '$Path' n'existe pas."
        return $null
    }
    
    # Obtenir la liste des fichiers Ã  traiter
    $files = Get-ChildItem -Path $Path -Filter $Filter -File -Recurse:$Recurse
    
    $results = @{
        TotalFiles = $files.Count
        ModifiedFiles = 0
        SkippedFiles = 0
        FailedFiles = 0
        Details = @()
    }
    
    foreach ($file in $files) {
        Write-Verbose "Traitement du fichier: $($file.FullName)"
        
        try {
            # Analyser le script pour voir s'il a besoin d'amÃ©liorations
            $analysis = Analyze-ScriptErrorHandling -Path $file.FullName
            
            if ($analysis.TotalIssues -eq 0) {
                Write-Verbose "Aucun problÃ¨me de gestion d'erreurs dÃ©tectÃ© dans le script: $($file.FullName)"
                $results.SkippedFiles++
                $results.Details += [PSCustomObject]@{
                    FilePath = $file.FullName
                    Status = "Skipped"
                    Reason = "No issues detected"
                }
                continue
            }
            
            # Ajouter des blocs try/catch
            $success = Add-TryCatchBlocks -Path $file.FullName -CreateBackup:$CreateBackup -AddLogging:$AddLogging -WhatIf:$WhatIf
            
            if ($success -and -not $WhatIf) {
                $results.ModifiedFiles++
                $results.Details += [PSCustomObject]@{
                    FilePath = $file.FullName
                    Status = "Modified"
                    IssuesFixed = $analysis.TotalIssues
                }
            }
            elseif ($WhatIf) {
                $results.Details += [PSCustomObject]@{
                    FilePath = $file.FullName
                    Status = "WhatIf"
                    PlannedModifications = ($success | Measure-Object).Count
                }
            }
            else {
                $results.FailedFiles++
                $results.Details += [PSCustomObject]@{
                    FilePath = $file.FullName
                    Status = "Failed"
                    Error = "Ã‰chec de l'ajout des blocs try/catch"
                }
            }
        }
        catch {
            $results.FailedFiles++
            $results.Details += [PSCustomObject]@{
                FilePath = $file.FullName
                Status = "Failed"
                Error = $_.Exception.Message
            }
        }
    }
    
    return [PSCustomObject]$results
}

function Add-MainTryCatchWrapper {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddLogging,
        
        [Parameter(Mandatory = $false)]
        [switch]$WhatIf
    )
    
    process {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            Write-Error "Le fichier '$Path' n'existe pas."
            return $false
        }
        
        # DÃ©terminer le chemin de sortie
        if ([string]::IsNullOrEmpty($OutputPath)) {
            $OutputPath = $Path
        }
        
        # CrÃ©er une sauvegarde si demandÃ©
        if ($CreateBackup) {
            $backupPath = "$Path.bak"
            Copy-Item -Path $Path -Destination $backupPath -Force
            Write-Verbose "Sauvegarde crÃ©Ã©e: $backupPath"
        }
        
        # Lire le contenu du script
        $content = Get-Content -Path $Path -Raw
        
        # VÃ©rifier si le script a dÃ©jÃ  un bloc try/catch principal
        if ($content -match '(?s)^try\s*{.*}\s*catch\s*{.*}(\s*finally\s*{.*})?$') {
            Write-Verbose "Le script a dÃ©jÃ  un bloc try/catch principal."
            return $true
        }
        
        # Ajouter une fonction de journalisation si demandÃ©
        $loggingFunction = ""
        if ($AddLogging -and -not ($content -match 'function\s+Write-Log')) {
            $loggingFunction = @"

# Fonction de journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true, Position = 0)]
        [string]`$Message,
        
        [Parameter(Mandatory = `$false)]
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]`$Level = "INFO",
        
        [Parameter(Mandatory = `$false)]
        [string]`$LogFilePath = "`$env:TEMP\$(Split-Path -Path $Path -Leaf).log"
    )
    
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logEntry = "``[`$timestamp``] [`$Level] `$Message"
    
    # Afficher dans la console
    switch (`$Level) {
        "INFO" { Write-Host `$logEntry -ForegroundColor White }
        "WARNING" { Write-Host `$logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host `$logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose `$logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        Add-Content -Path `$LogFilePath -Value `$logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}

"@
        }
        
        # Extraire les commentaires et les dÃ©clarations param au dÃ©but du script
        $header = ""
        if ($content -match '(?s)^(#[^\n]*\n)+') {
            $header = $matches[0]
            $content = $content.Substring($header.Length)
        }
        
        $param = ""
        if ($content -match '(?s)^(\s*param\s*\([^\)]+\))') {
            $param = $matches[0]
            $content = $content.Substring($param.Length)
        }
        
        # Construire le nouveau contenu
        $newContent = @"
$header
$param

# Configuration de la gestion d'erreurs
`$ErrorActionPreference = 'Stop'
`$Error.Clear()
$loggingFunction
try {
    # Script principal
$content
}
catch {
    $(if ($AddLogging) { "Write-Log -Level ERROR -Message `"Une erreur critique s'est produite: `$_`"" } else { "Write-Error `"Une erreur critique s'est produite: `$_`"" })
    exit 1
}
finally {
    # Nettoyage final
    $(if ($AddLogging) { "Write-Log -Level INFO -Message `"ExÃ©cution du script terminÃ©e.`"" } else { "Write-Verbose `"ExÃ©cution du script terminÃ©e.`"" })
}
"@
        
        # Appliquer les modifications si ce n'est pas un test
        if (-not $WhatIf) {
            Set-Content -Path $OutputPath -Value $newContent
            Write-Verbose "Bloc try/catch principal ajoutÃ© au script."
            return $true
        }
        else {
            # Afficher les modifications prÃ©vues
            Write-Host "Modifications prÃ©vues pour le script '$Path':"
            Write-Host "- Ajout d'un bloc try/catch principal"
            Write-Host "- Configuration de ErrorActionPreference Ã  'Stop'"
            if ($AddLogging) {
                Write-Host "- Ajout d'une fonction de journalisation"
            }
            
            return $true
        }
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Add-TryCatchBlocks, Add-TryCatchToDirectory, Add-MainTryCatchWrapper
