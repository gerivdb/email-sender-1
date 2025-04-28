# Script pour ajouter la gestion d'erreurs aux scripts PowerShell
# Ce script ajoute des blocs try/catch aux scripts PowerShell qui n'en ont pas

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScriptsDirectory = (Join-Path -Path (Get-Location) -ChildPath "scripts"),
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateBackup,
    
    [Parameter(Mandatory = $false)]
    [switch]$AddLogging,
    
    [Parameter(Mandatory = $false)]
    [string]$LogFilePath = (Join-Path -Path (Get-Location) -ChildPath "logs\error_handling.log")
)

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Write-Host $logEntry
    
    # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
    $logDir = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path -Path $logDir -PathType Container)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    Add-Content -Path $LogFilePath -Value $logEntry -Encoding UTF8
}

# Fonction pour identifier les scripts nÃ©cessitant une gestion d'erreurs
function Find-ScriptsNeedingErrorHandling {
    param (
        [string]$Directory
    )
    
    Write-Log "Recherche des scripts nÃ©cessitant une gestion d'erreurs dans $Directory"
    
    $results = @()
    
    # RÃ©cupÃ©rer tous les scripts PowerShell dans le rÃ©pertoire
    $scripts = Get-ChildItem -Path $Directory -Recurse -File -Filter "*.ps1" | Where-Object { -not $_.FullName.Contains(".bak") }
    Write-Log "Nombre de scripts trouvÃ©s : $($scripts.Count)"
    
    foreach ($script in $scripts) {
        Write-Verbose "Analyse du script : $($script.FullName)"
        
        # Lire le contenu du script
        $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($null -eq $content) {
            Write-Log "Impossible de lire le contenu du script : $($script.FullName)" -Level "WARNING"
            continue
        }
        
        # VÃ©rifier la gestion d'erreurs
        $hasTryCatch = $content -match "try\s*{" -and $content -match "catch\s*{"
        $hasErrorActionPreference = $content -match "\`$ErrorActionPreference\s*=\s*['""]Stop['""]"
        
        # VÃ©rifier la prÃ©sence de commandes critiques
        $hasCriticalCommands = $content -match "Remove-Item|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Rename-Item|Invoke-WebRequest|Invoke-RestMethod|Start-Process|Stop-Process"
        
        # Si le script n'a pas de gestion d'erreurs mais contient des commandes critiques
        if ((-not $hasTryCatch) -and (-not $hasErrorActionPreference) -and $hasCriticalCommands) {
            $results += $script.FullName
        }
    }
    
    return $results
}

# Fonction pour ajouter des blocs try/catch Ã  un script
function Add-TryCatchBlocks {
    param (
        [string]$Path,
        [switch]$CreateBackup,
        [switch]$AddLogging
    )
    
    Write-Verbose "Ajout de blocs try/catch Ã  $Path"
    
    # CrÃ©er une sauvegarde si demandÃ©
    if ($CreateBackup) {
        $backupPath = "$Path.bak"
        Copy-Item -Path $Path -Destination $backupPath -Force
        Write-Verbose "Sauvegarde crÃ©Ã©e : $backupPath"
    }
    
    # Lire le contenu du script
    $content = Get-Content -Path $Path -Raw
    
    # Extraire les paramÃ¨tres et l'en-tÃªte du script
    $paramMatch = [regex]::Match($content, "(?s)^.*?param\s*\((.*?)\)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $param = if ($paramMatch.Success) { $paramMatch.Value } else { "" }
    
    # Extraire le contenu principal du script (aprÃ¨s les paramÃ¨tres)
    $mainContent = if ($paramMatch.Success) { $content.Substring($paramMatch.Length) } else { $content }
    
    # Extraire l'en-tÃªte du script (commentaires et dÃ©clarations)
    $headerMatch = [regex]::Match($content, "(?s)^(.*?)(?:param|function|#>)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $header = if ($headerMatch.Success) { $headerMatch.Groups[1].Value } else { "" }
    
    # Fonction de journalisation Ã  ajouter si demandÃ©
    $loggingFunction = if ($AddLogging) {
        @"
# Fonction de journalisation
function Write-Log {
    param (
        [string]`$Message,
        [string]`$Level = "INFO"
    )
    
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$logEntry = "[`$timestamp] [`$Level] `$Message"
    
    # Afficher dans la console
    switch (`$Level) {
        "INFO" { Write-Host `$logEntry -ForegroundColor White }
        "WARNING" { Write-Host `$logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host `$logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose `$logEntry }
    }
    
    # Ã‰crire dans le fichier journal
    try {
        `$logDir = Split-Path -Path `$PSScriptRoot -Parent
        `$logPath = Join-Path -Path `$logDir -ChildPath "logs\`$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # CrÃ©er le rÃ©pertoire de logs si nÃ©cessaire
        `$logDirPath = Split-Path -Path `$logPath -Parent
        if (-not (Test-Path -Path `$logDirPath -PathType Container)) {
            New-Item -Path `$logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path `$logPath -Value `$logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'Ã©criture dans le journal
    }
}
"@
    } else { "" }
    
    # Nouveau contenu avec gestion d'erreurs
    $newContent = @"
$header
$param

# Configuration de la gestion d'erreurs
`$ErrorActionPreference = 'Stop'
`$Error.Clear()
$loggingFunction
try {
    # Script principal
$mainContent
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
    
    # Ã‰crire le nouveau contenu dans le fichier
    Set-Content -Path $Path -Value $newContent -Encoding UTF8
    
    return $true
}

# Fonction principale
function Start-ErrorHandlingImplementation {
    Write-Log "DÃ©marrage de l'implÃ©mentation de la gestion d'erreurs"
    
    # Trouver les scripts nÃ©cessitant une gestion d'erreurs
    $scriptsNeedingErrorHandling = Find-ScriptsNeedingErrorHandling -Directory $ScriptsDirectory
    
    Write-Log "Nombre de scripts nÃ©cessitant une gestion d'erreurs : $($scriptsNeedingErrorHandling.Count)"
    
    $results = @{
        Total = $scriptsNeedingErrorHandling.Count
        Succeeded = 0
        Failed = 0
        Details = @()
    }
    
    # Ajouter des blocs try/catch aux scripts
    foreach ($scriptPath in $scriptsNeedingErrorHandling) {
        Write-Log "Traitement du script : $scriptPath"
        
        try {
            $success = Add-TryCatchBlocks -Path $scriptPath -CreateBackup:$CreateBackup -AddLogging:$AddLogging
            
            if ($success) {
                Write-Log "Gestion d'erreurs ajoutÃ©e avec succÃ¨s Ã  : $scriptPath" -Level "INFO"
                $results.Succeeded++
                $results.Details += [PSCustomObject]@{
                    Path = $scriptPath
                    Status = "Success"
                    Message = "Gestion d'erreurs ajoutÃ©e avec succÃ¨s"
                }
            }
            else {
                Write-Log "Ã‰chec de l'ajout de la gestion d'erreurs Ã  : $scriptPath" -Level "ERROR"
                $results.Failed++
                $results.Details += [PSCustomObject]@{
                    Path = $scriptPath
                    Status = "Failed"
                    Message = "Ã‰chec de l'ajout de la gestion d'erreurs"
                }
            }
        }
        catch {
            Write-Log "Erreur lors du traitement du script $scriptPath : $_" -Level "ERROR"
            $results.Failed++
            $results.Details += [PSCustomObject]@{
                Path = $scriptPath
                Status = "Failed"
                Message = "Erreur : $_"
            }
        }
    }
    
    # GÃ©nÃ©rer un rapport
    $reportPath = Join-Path -Path (Split-Path -Parent $LogFilePath) -ChildPath "error_handling_report.json"
    $results | ConvertTo-Json -Depth 3 | Set-Content -Path $reportPath -Encoding UTF8
    
    Write-Log "Rapport gÃ©nÃ©rÃ© : $reportPath"
    
    # Afficher un rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© de l'implÃ©mentation de la gestion d'erreurs :" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Scripts analysÃ©s : $($results.Total)" -ForegroundColor White
    Write-Host "AmÃ©liorations rÃ©ussies : $($results.Succeeded)" -ForegroundColor Green
    Write-Host "Ã‰checs : $($results.Failed)" -ForegroundColor Red
    
    return $results
}

# ExÃ©cuter la fonction principale
Start-ErrorHandlingImplementation
