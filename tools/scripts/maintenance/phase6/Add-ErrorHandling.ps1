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
    
    # Créer le répertoire de logs si nécessaire
    $logDir = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path -Path $logDir -PathType Container)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    Add-Content -Path $LogFilePath -Value $logEntry -Encoding UTF8
}

# Fonction pour identifier les scripts nécessitant une gestion d'erreurs
function Find-ScriptsNeedingErrorHandling {
    param (
        [string]$Directory
    )
    
    Write-Log "Recherche des scripts nécessitant une gestion d'erreurs dans $Directory"
    
    $results = @()
    
    # Récupérer tous les scripts PowerShell dans le répertoire
    $scripts = Get-ChildItem -Path $Directory -Recurse -File -Filter "*.ps1" | Where-Object { -not $_.FullName.Contains(".bak") }
    Write-Log "Nombre de scripts trouvés : $($scripts.Count)"
    
    foreach ($script in $scripts) {
        Write-Verbose "Analyse du script : $($script.FullName)"
        
        # Lire le contenu du script
        $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($null -eq $content) {
            Write-Log "Impossible de lire le contenu du script : $($script.FullName)" -Level "WARNING"
            continue
        }
        
        # Vérifier la gestion d'erreurs
        $hasTryCatch = $content -match "try\s*{" -and $content -match "catch\s*{"
        $hasErrorActionPreference = $content -match "\`$ErrorActionPreference\s*=\s*['""]Stop['""]"
        
        # Vérifier la présence de commandes critiques
        $hasCriticalCommands = $content -match "Remove-Item|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Rename-Item|Invoke-WebRequest|Invoke-RestMethod|Start-Process|Stop-Process"
        
        # Si le script n'a pas de gestion d'erreurs mais contient des commandes critiques
        if ((-not $hasTryCatch) -and (-not $hasErrorActionPreference) -and $hasCriticalCommands) {
            $results += $script.FullName
        }
    }
    
    return $results
}

# Fonction pour ajouter des blocs try/catch à un script
function Add-TryCatchBlocks {
    param (
        [string]$Path,
        [switch]$CreateBackup,
        [switch]$AddLogging
    )
    
    Write-Verbose "Ajout de blocs try/catch à $Path"
    
    # Créer une sauvegarde si demandé
    if ($CreateBackup) {
        $backupPath = "$Path.bak"
        Copy-Item -Path $Path -Destination $backupPath -Force
        Write-Verbose "Sauvegarde créée : $backupPath"
    }
    
    # Lire le contenu du script
    $content = Get-Content -Path $Path -Raw
    
    # Extraire les paramètres et l'en-tête du script
    $paramMatch = [regex]::Match($content, "(?s)^.*?param\s*\((.*?)\)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $param = if ($paramMatch.Success) { $paramMatch.Value } else { "" }
    
    # Extraire le contenu principal du script (après les paramètres)
    $mainContent = if ($paramMatch.Success) { $content.Substring($paramMatch.Length) } else { $content }
    
    # Extraire l'en-tête du script (commentaires et déclarations)
    $headerMatch = [regex]::Match($content, "(?s)^(.*?)(?:param|function|#>)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $header = if ($headerMatch.Success) { $headerMatch.Groups[1].Value } else { "" }
    
    # Fonction de journalisation à ajouter si demandé
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
    
    # Écrire dans le fichier journal
    try {
        `$logDir = Split-Path -Path `$PSScriptRoot -Parent
        `$logPath = Join-Path -Path `$logDir -ChildPath "logs\`$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # Créer le répertoire de logs si nécessaire
        `$logDirPath = Split-Path -Path `$logPath -Parent
        if (-not (Test-Path -Path `$logDirPath -PathType Container)) {
            New-Item -Path `$logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path `$logPath -Value `$logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'écriture dans le journal
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
    $(if ($AddLogging) { "Write-Log -Level INFO -Message `"Exécution du script terminée.`"" } else { "Write-Verbose `"Exécution du script terminée.`"" })
}
"@
    
    # Écrire le nouveau contenu dans le fichier
    Set-Content -Path $Path -Value $newContent -Encoding UTF8
    
    return $true
}

# Fonction principale
function Start-ErrorHandlingImplementation {
    Write-Log "Démarrage de l'implémentation de la gestion d'erreurs"
    
    # Trouver les scripts nécessitant une gestion d'erreurs
    $scriptsNeedingErrorHandling = Find-ScriptsNeedingErrorHandling -Directory $ScriptsDirectory
    
    Write-Log "Nombre de scripts nécessitant une gestion d'erreurs : $($scriptsNeedingErrorHandling.Count)"
    
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
                Write-Log "Gestion d'erreurs ajoutée avec succès à : $scriptPath" -Level "INFO"
                $results.Succeeded++
                $results.Details += [PSCustomObject]@{
                    Path = $scriptPath
                    Status = "Success"
                    Message = "Gestion d'erreurs ajoutée avec succès"
                }
            }
            else {
                Write-Log "Échec de l'ajout de la gestion d'erreurs à : $scriptPath" -Level "ERROR"
                $results.Failed++
                $results.Details += [PSCustomObject]@{
                    Path = $scriptPath
                    Status = "Failed"
                    Message = "Échec de l'ajout de la gestion d'erreurs"
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
    
    # Générer un rapport
    $reportPath = Join-Path -Path (Split-Path -Parent $LogFilePath) -ChildPath "error_handling_report.json"
    $results | ConvertTo-Json -Depth 3 | Set-Content -Path $reportPath -Encoding UTF8
    
    Write-Log "Rapport généré : $reportPath"
    
    # Afficher un résumé
    Write-Host "`nRésumé de l'implémentation de la gestion d'erreurs :" -ForegroundColor Cyan
    Write-Host "----------------------------------------" -ForegroundColor Cyan
    Write-Host "Scripts analysés : $($results.Total)" -ForegroundColor White
    Write-Host "Améliorations réussies : $($results.Succeeded)" -ForegroundColor Green
    Write-Host "Échecs : $($results.Failed)" -ForegroundColor Red
    
    return $results
}

# Exécuter la fonction principale
Start-ErrorHandlingImplementation
