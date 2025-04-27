<#
.SYNOPSIS
    ImplÃ©mente la Phase 6 de la roadmap : correctifs prioritaires pour la gestion d'erreurs et la compatibilitÃ©.

.DESCRIPTION
    Ce script implÃ©mente les correctifs prioritaires de la Phase 6 de la roadmap, notamment :
    - AmÃ©lioration de la gestion d'erreurs dans les scripts existants
    - RÃ©solution des problÃ¨mes de compatibilitÃ© entre environnements

.PARAMETER ScriptsDirectory
    Le rÃ©pertoire contenant les scripts Ã  analyser et Ã  corriger.

.PARAMETER CreateBackup
    Indique s'il faut crÃ©er une sauvegarde des fichiers avant de les modifier.

.PARAMETER LogFilePath
    Le chemin du fichier journal pour enregistrer les actions effectuÃ©es.

.EXAMPLE
    .\Start-Phase6.ps1 -ScriptsDirectory "..\..\scripts" -CreateBackup -LogFilePath "phase6_implementation.log"

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 09/04/2025
    Version: 1.0
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScriptsDirectory = (Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "scripts"),
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateBackup,
    
    [Parameter(Mandatory = $false)]
    [string]$LogFilePath = (Join-Path -Path $PSScriptRoot -ChildPath "phase6_implementation.log")
)

# Importer les modules nÃ©cessaires
$modulesPath = Join-Path -Path $PSScriptRoot -ChildPath "modules"
if (-not (Test-Path -Path $modulesPath -PathType Container)) {
    New-Item -Path $modulesPath -ItemType Directory -Force | Out-Null
}

# Chemins des scripts utilitaires
$tryCatchAdderPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "journal\TryCatchAdder.ps1"
$scriptAnalyzerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "journal\ScriptAnalyzer.ps1"
$centralizedLoggerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "journal\CentralizedLogger.ps1"
$retryLogicPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "journal\RetryLogic.ps1"
$pathStandardizerPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "utils\automation\PathStandardizer.ps1"
$osCommandWrappersPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "workflow\testing\OSCommandWrappers.ps1"
$environmentCompatibilityTestPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "testing\EnvironmentCompatibilityTest.ps1"

# VÃ©rifier et importer les scripts utilitaires
$utilityScripts = @{
    "TryCatchAdder" = $tryCatchAdderPath
    "ScriptAnalyzer" = $scriptAnalyzerPath
    "CentralizedLogger" = $centralizedLoggerPath
    "RetryLogic" = $retryLogicPath
    "PathStandardizer" = $pathStandardizerPath
    "OSCommandWrappers" = $osCommandWrappersPath
    "EnvironmentCompatibilityTest" = $environmentCompatibilityTestPath
}

$missingScripts = @()
foreach ($scriptName in $utilityScripts.Keys) {
    $scriptPath = $utilityScripts[$scriptName]
    if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
        $missingScripts += "$scriptName ($scriptPath)"
    }
}

if ($missingScripts.Count -gt 0) {
    Write-Warning "Les scripts utilitaires suivants sont manquants :"
    foreach ($script in $missingScripts) {
        Write-Warning "  - $script"
    }
    
    $continue = Read-Host "Voulez-vous continuer malgrÃ© les scripts manquants ? (O/N)"
    if ($continue -ne "O" -and $continue -ne "o") {
        Write-Host "OpÃ©ration annulÃ©e par l'utilisateur."
        return
    }
}

# Importer les scripts utilitaires disponibles
foreach ($scriptName in $utilityScripts.Keys) {
    $scriptPath = $utilityScripts[$scriptName]
    if (Test-Path -Path $scriptPath -PathType Leaf) {
        try {
            . $scriptPath
            Write-Verbose "Script $scriptName importÃ© avec succÃ¨s."
        }
        catch {
            Write-Warning "Erreur lors de l'importation du script $scriptName : $_"
        }
    }
}

# Initialiser le logger
if (Test-Path -Path $centralizedLoggerPath -PathType Leaf) {
    try {
        Initialize-Logger -LogFilePath $LogFilePath -LogLevel Info -IncludeTimestamp -IncludeSource -LogToConsole -LogToFile
        Write-LogInfo "Phase 6 : ImplÃ©mentation des correctifs prioritaires dÃ©marrÃ©e"
    }
    catch {
        Write-Warning "Erreur lors de l'initialisation du logger : $_"
        # Fallback Ã  une fonction de journalisation simple
        function Write-Log {
            param (
                [string]$Message,
                [string]$Level = "INFO"
            )
            
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [$Level] $Message"
            
            Write-Host $logEntry
            Add-Content -Path $LogFilePath -Value $logEntry -ErrorAction SilentlyContinue
        }
        
        # DÃ©finir des alias pour les fonctions de journalisation
        Set-Alias -Name Write-LogInfo -Value Write-Log -Scope Script
        Set-Alias -Name Write-LogWarning -Value Write-Log -Scope Script
        Set-Alias -Name Write-LogError -Value Write-Log -Scope Script
        
        Write-Log "Phase 6 : ImplÃ©mentation des correctifs prioritaires dÃ©marrÃ©e"
    }
}
else {
    # Fonction de journalisation simple
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "INFO"
        )
        
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logEntry = "[$timestamp] [$Level] $Message"
        
        Write-Host $logEntry
        Add-Content -Path $LogFilePath -Value $logEntry -ErrorAction SilentlyContinue
    }
    
    # DÃ©finir des alias pour les fonctions de journalisation
    Set-Alias -Name Write-LogInfo -Value Write-Log -Scope Script
    Set-Alias -Name Write-LogWarning -Value Write-Log -Scope Script
    Set-Alias -Name Write-LogError -Value Write-Log -Scope Script
    
    Write-Log "Phase 6 : ImplÃ©mentation des correctifs prioritaires dÃ©marrÃ©e"
}

# Fonction pour analyser les scripts et identifier ceux qui nÃ©cessitent des amÃ©liorations
function Find-ScriptsNeedingImprovements {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Directory,
        
        [Parameter(Mandatory = $false)]
        [string[]]$FileExtensions = @(".ps1", ".psm1")
    )
    
    Write-LogInfo "Recherche des scripts nÃ©cessitant des amÃ©liorations dans $Directory"
    
    $results = @{
        ErrorHandling = @()
        Compatibility = @()
    }
    
    # RÃ©cupÃ©rer tous les scripts PowerShell dans le rÃ©pertoire
    $scripts = Get-ChildItem -Path $Directory -Recurse -File | Where-Object { $FileExtensions -contains $_.Extension }
    Write-LogInfo "Nombre de scripts trouvÃ©s : $($scripts.Count)"
    
    foreach ($script in $scripts) {
        Write-Verbose "Analyse du script : $($script.FullName)"
        
        # Lire le contenu du script
        $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($null -eq $content) {
            Write-LogWarning "Impossible de lire le contenu du script : $($script.FullName)"
            continue
        }
        
        # VÃ©rifier la gestion d'erreurs
        $needsErrorHandling = -not ($content -match "try\s*{" -and $content -match "catch\s*{") -and
                             ($content -match "Remove-Item|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Rename-Item|Invoke-WebRequest|Invoke-RestMethod|Start-Process|Stop-Process")
        
        # VÃ©rifier la compatibilitÃ© entre environnements
        $needsCompatibility = $content -match "\\\\|C:\\|D:\\|\.exe|\.bat|\.cmd" -and
                             -not ($content -match "Join-Path|Split-Path|Test-Path.*-PathType|System\.IO\.Path")
        
        # Ajouter le script aux rÃ©sultats si nÃ©cessaire
        if ($needsErrorHandling) {
            $results.ErrorHandling += $script.FullName
        }
        
        if ($needsCompatibility) {
            $results.Compatibility += $script.FullName
        }
    }
    
    return $results
}

# Fonction pour amÃ©liorer la gestion d'erreurs dans les scripts
function Update-ErrorHandling {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ScriptPaths,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddLogging
    )
    
    Write-LogInfo "AmÃ©lioration de la gestion d'erreurs pour $($ScriptPaths.Count) scripts"
    
    $results = @{
        Succeeded = 0
        Failed = 0
        Details = @()
    }
    
    foreach ($scriptPath in $ScriptPaths) {
        Write-Verbose "Traitement du script : $scriptPath"
        
        if ($PSCmdlet.ShouldProcess($scriptPath, "AmÃ©liorer la gestion d'erreurs")) {
            try {
                # Utiliser TryCatchAdder.ps1 si disponible
                if (Test-Path -Path $tryCatchAdderPath -PathType Leaf) {
                    $success = Add-TryCatchBlocks -Path $scriptPath -CreateBackup:$CreateBackup -AddLogging:$AddLogging
                    
                    if ($success) {
                        Write-LogInfo "Gestion d'erreurs amÃ©liorÃ©e pour : $scriptPath"
                        $results.Succeeded++
                        $results.Details += [PSCustomObject]@{
                            Path = $scriptPath
                            Status = "Success"
                            Message = "Gestion d'erreurs amÃ©liorÃ©e"
                        }
                    }
                    else {
                        Write-LogWarning "Ã‰chec de l'amÃ©lioration de la gestion d'erreurs pour : $scriptPath"
                        $results.Failed++
                        $results.Details += [PSCustomObject]@{
                            Path = $scriptPath
                            Status = "Failed"
                            Message = "Ã‰chec de l'amÃ©lioration de la gestion d'erreurs"
                        }
                    }
                }
                else {
                    # ImplÃ©mentation manuelle si TryCatchAdder.ps1 n'est pas disponible
                    $content = Get-Content -Path $scriptPath -Raw
                    
                    # CrÃ©er une sauvegarde si demandÃ©
                    if ($CreateBackup) {
                        $backupPath = "$scriptPath.bak"
                        Copy-Item -Path $scriptPath -Destination $backupPath -Force
                        Write-Verbose "Sauvegarde crÃ©Ã©e : $backupPath"
                    }
                    
                    # Ajouter ErrorActionPreference = 'Stop' au dÃ©but du script
                    if (-not ($content -match '\$ErrorActionPreference\s*=\s*[''"]Stop[''"]')) {
                        $content = "`$ErrorActionPreference = 'Stop'`n`n$content"
                    }
                    
                    # Entourer le script principal d'un bloc try/catch
                    if (-not ($content -match "try\s*{" -and $content -match "catch\s*{")) {
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
                        $loggingFunction = if ($AddLogging) {
                            @"
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
        [string]`$LogFilePath = "`$PSScriptRoot\logs\`$(Get-Date -Format 'yyyy-MM-dd').log"
    )
    
    # CrÃ©er le dossier de logs si nÃ©cessaire
    `$logDir = Split-Path -Path `$LogFilePath -Parent
    if (-not (Test-Path -Path `$logDir -PathType Container)) {
        New-Item -Path `$logDir -ItemType Directory -Force | Out-Null
    }
    
    # Formater le message de log
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
                        } else { "" }
                        
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
                        
                        # Enregistrer le nouveau contenu
                        Set-Content -Path $scriptPath -Value $newContent
                        
                        Write-LogInfo "Gestion d'erreurs amÃ©liorÃ©e pour : $scriptPath"
                        $results.Succeeded++
                        $results.Details += [PSCustomObject]@{
                            Path = $scriptPath
                            Status = "Success"
                            Message = "Gestion d'erreurs amÃ©liorÃ©e manuellement"
                        }
                    }
                    else {
                        Write-LogInfo "Le script possÃ¨de dÃ©jÃ  une gestion d'erreurs : $scriptPath"
                        $results.Succeeded++
                        $results.Details += [PSCustomObject]@{
                            Path = $scriptPath
                            Status = "Skipped"
                            Message = "Le script possÃ¨de dÃ©jÃ  une gestion d'erreurs"
                        }
                    }
                }
            }
            catch {
                Write-LogError "Erreur lors de l'amÃ©lioration de la gestion d'erreurs pour $scriptPath : $_"
                $results.Failed++
                $results.Details += [PSCustomObject]@{
                    Path = $scriptPath
                    Status = "Error"
                    Message = "Erreur : $_"
                }
            }
        }
    }
    
    return $results
}

# Fonction pour amÃ©liorer la compatibilitÃ© entre environnements
function Update-EnvironmentCompatibility {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ScriptPaths,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup
    )
    
    Write-LogInfo "AmÃ©lioration de la compatibilitÃ© entre environnements pour $($ScriptPaths.Count) scripts"
    
    $results = @{
        Succeeded = 0
        Failed = 0
        Details = @()
    }
    
    foreach ($scriptPath in $ScriptPaths) {
        Write-Verbose "Traitement du script : $scriptPath"
        
        if ($PSCmdlet.ShouldProcess($scriptPath, "AmÃ©liorer la compatibilitÃ© entre environnements")) {
            try {
                # Utiliser PathStandardizer.ps1 si disponible
                if (Test-Path -Path $pathStandardizerPath -PathType Leaf) {
                    # ImplÃ©menter l'appel Ã  PathStandardizer.ps1
                    # Cette partie dÃ©pend de l'implÃ©mentation spÃ©cifique de PathStandardizer.ps1
                    Write-Verbose "Utilisation de PathStandardizer.ps1 pour $scriptPath"
                }
                
                # ImplÃ©mentation manuelle
                $content = Get-Content -Path $scriptPath -Raw
                
                # CrÃ©er une sauvegarde si demandÃ©
                if ($CreateBackup) {
                    $backupPath = "$scriptPath.bak"
                    Copy-Item -Path $scriptPath -Destination $backupPath -Force
                    Write-Verbose "Sauvegarde crÃ©Ã©e : $backupPath"
                }
                
                # Remplacer les chemins absolus par des chemins relatifs
                $newContent = $content
                
                # Remplacer les concatÃ©nations de chemins par Join-Path
                $newContent = [regex]::Replace($newContent, '([''"][^''"\r\n]*[''"])\s*\+\s*[''"][\\\/]?([^''"\r\n]*)[''"]', '(Join-Path -Path $1 -ChildPath "$2")')
                
                # Remplacer les chemins absolus Windows par des chemins relatifs
                $newContent = [regex]::Replace($newContent, '([''"])[A-Za-z]:\\([^''"\r\n]*)(["''])', '$1$2$3')
                
                # Ajouter une fonction d'environnement si elle n'existe pas dÃ©jÃ 
                if (-not ($newContent -match "function Get-ScriptEnvironment" -or $newContent -match "function Test-Environment")) {
                    $environmentFunction = @"

# Fonction pour dÃ©tecter l'environnement d'exÃ©cution
function Get-ScriptEnvironment {
    [CmdletBinding()]
    param()
    
    `$environment = [PSCustomObject]@{
        IsWindows = `$false
        IsLinux = `$false
        IsMacOS = `$false
        PSVersion = `$PSVersionTable.PSVersion
        PathSeparator = [System.IO.Path]::DirectorySeparatorChar
    }
    
    # DÃ©tecter le systÃ¨me d'exploitation
    if (`$PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell Core (6+)
        `$environment.IsWindows = `$IsWindows
        `$environment.IsLinux = `$IsLinux
        `$environment.IsMacOS = `$IsMacOS
    }
    else {
        # Windows PowerShell
        `$environment.IsWindows = `$true
    }
    
    return `$environment
}

# Fonction pour normaliser les chemins selon l'environnement
function Get-NormalizedPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = `$true)]
        [string]`$Path
    )
    
    # Obtenir l'environnement
    `$env = Get-ScriptEnvironment
    
    # Normaliser les sÃ©parateurs de chemin
    `$normalizedPath = `$Path.Replace('\', `$env.PathSeparator).Replace('/', `$env.PathSeparator)
    
    return `$normalizedPath
}

"@
                    
                    # Ajouter la fonction au dÃ©but du script aprÃ¨s les commentaires et les dÃ©clarations param
                    $header = ""
                    if ($newContent -match '(?s)^(#[^\n]*\n)+') {
                        $header = $matches[0]
                        $newContent = $newContent.Substring($header.Length)
                    }
                    
                    $param = ""
                    if ($newContent -match '(?s)^(\s*param\s*\([^\)]+\))') {
                        $param = $matches[0]
                        $newContent = $newContent.Substring($param.Length)
                    }
                    
                    $newContent = "$header$param$environmentFunction$newContent"
                }
                
                # Enregistrer le nouveau contenu
                Set-Content -Path $scriptPath -Value $newContent
                
                Write-LogInfo "CompatibilitÃ© entre environnements amÃ©liorÃ©e pour : $scriptPath"
                $results.Succeeded++
                $results.Details += [PSCustomObject]@{
                    Path = $scriptPath
                    Status = "Success"
                    Message = "CompatibilitÃ© entre environnements amÃ©liorÃ©e"
                }
            }
            catch {
                Write-LogError "Erreur lors de l'amÃ©lioration de la compatibilitÃ© entre environnements pour $scriptPath : $_"
                $results.Failed++
                $results.Details += [PSCustomObject]@{
                    Path = $scriptPath
                    Status = "Error"
                    Message = "Erreur : $_"
                }
            }
        }
    }
    
    return $results
}

# Fonction principale
function Start-Phase6 {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptsDirectory,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup,
        
        [Parameter(Mandatory = $false)]
        [switch]$AddLogging
    )
    
    Write-LogInfo "DÃ©marrage de l'implÃ©mentation de la Phase 6"
    Write-LogInfo "RÃ©pertoire des scripts : $ScriptsDirectory"
    
    # VÃ©rifier si le rÃ©pertoire des scripts existe
    if (-not (Test-Path -Path $ScriptsDirectory -PathType Container)) {
        Write-LogError "Le rÃ©pertoire des scripts n'existe pas : $ScriptsDirectory"
        return $false
    }
    
    # Trouver les scripts nÃ©cessitant des amÃ©liorations
    $scriptsNeedingImprovements = Find-ScriptsNeedingImprovements -Directory $ScriptsDirectory
    
    Write-LogInfo "Nombre de scripts nÃ©cessitant une amÃ©lioration de la gestion d'erreurs : $($scriptsNeedingImprovements.ErrorHandling.Count)"
    Write-LogInfo "Nombre de scripts nÃ©cessitant une amÃ©lioration de la compatibilitÃ© entre environnements : $($scriptsNeedingImprovements.Compatibility.Count)"
    
    # AmÃ©liorer la gestion d'erreurs
    if ($scriptsNeedingImprovements.ErrorHandling.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess("$($scriptsNeedingImprovements.ErrorHandling.Count) scripts", "AmÃ©liorer la gestion d'erreurs")) {
            $errorHandlingResults = Update-ErrorHandling -ScriptPaths $scriptsNeedingImprovements.ErrorHandling -CreateBackup:$CreateBackup -AddLogging:$AddLogging
            Write-LogInfo "AmÃ©lioration de la gestion d'erreurs terminÃ©e : $($errorHandlingResults.Succeeded) rÃ©ussites, $($errorHandlingResults.Failed) Ã©checs"
        }
    }
    else {
        Write-LogInfo "Aucun script ne nÃ©cessite d'amÃ©lioration de la gestion d'erreurs"
    }
    
    # AmÃ©liorer la compatibilitÃ© entre environnements
    if ($scriptsNeedingImprovements.Compatibility.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess("$($scriptsNeedingImprovements.Compatibility.Count) scripts", "AmÃ©liorer la compatibilitÃ© entre environnements")) {
            $compatibilityResults = Update-EnvironmentCompatibility -ScriptPaths $scriptsNeedingImprovements.Compatibility -CreateBackup:$CreateBackup
            Write-LogInfo "AmÃ©lioration de la compatibilitÃ© entre environnements terminÃ©e : $($compatibilityResults.Succeeded) rÃ©ussites, $($compatibilityResults.Failed) Ã©checs"
        }
    }
    else {
        Write-LogInfo "Aucun script ne nÃ©cessite d'amÃ©lioration de la compatibilitÃ© entre environnements"
    }
    
    # GÃ©nÃ©rer un rapport
    $report = [PSCustomObject]@{
        Date = Get-Date
        ScriptsDirectory = $ScriptsDirectory
        ErrorHandling = @{
            Total = $scriptsNeedingImprovements.ErrorHandling.Count
            Succeeded = if ($scriptsNeedingImprovements.ErrorHandling.Count -gt 0) { $errorHandlingResults.Succeeded } else { 0 }
            Failed = if ($scriptsNeedingImprovements.ErrorHandling.Count -gt 0) { $errorHandlingResults.Failed } else { 0 }
            Details = if ($scriptsNeedingImprovements.ErrorHandling.Count -gt 0) { $errorHandlingResults.Details } else { @() }
        }
        Compatibility = @{
            Total = $scriptsNeedingImprovements.Compatibility.Count
            Succeeded = if ($scriptsNeedingImprovements.Compatibility.Count -gt 0) { $compatibilityResults.Succeeded } else { 0 }
            Failed = if ($scriptsNeedingImprovements.Compatibility.Count -gt 0) { $compatibilityResults.Failed } else { 0 }
            Details = if ($scriptsNeedingImprovements.Compatibility.Count -gt 0) { $compatibilityResults.Details } else { @() }
        }
    }
    
    # Enregistrer le rapport
    $reportPath = Join-Path -Path $PSScriptRoot -ChildPath "phase6_report.json"
    $report | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath
    Write-LogInfo "Rapport enregistrÃ© : $reportPath"
    
    Write-LogInfo "ImplÃ©mentation de la Phase 6 terminÃ©e"
    
    return $report
}

# ExÃ©cuter la fonction principale
$result = Start-Phase6 -ScriptsDirectory $ScriptsDirectory -CreateBackup:$CreateBackup -AddLogging:$true

# Fermer le logger
if (Test-Path -Path $centralizedLoggerPath -PathType Leaf) {
    try {
        Close-Logger
    }
    catch {
        Write-Warning "Erreur lors de la fermeture du logger : $_"
    }
}

# Afficher un rÃ©sumÃ©
Write-Host "`nRÃ©sumÃ© de l'implÃ©mentation de la Phase 6 :" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Gestion d'erreurs :" -ForegroundColor Yellow
Write-Host "  - Scripts analysÃ©s : $($result.ErrorHandling.Total)" -ForegroundColor White
Write-Host "  - AmÃ©liorations rÃ©ussies : $($result.ErrorHandling.Succeeded)" -ForegroundColor Green
Write-Host "  - Ã‰checs : $($result.ErrorHandling.Failed)" -ForegroundColor Red

Write-Host "`nCompatibilitÃ© entre environnements :" -ForegroundColor Yellow
Write-Host "  - Scripts analysÃ©s : $($result.Compatibility.Total)" -ForegroundColor White
Write-Host "  - AmÃ©liorations rÃ©ussies : $($result.Compatibility.Succeeded)" -ForegroundColor Green
Write-Host "  - Ã‰checs : $($result.Compatibility.Failed)" -ForegroundColor Red

Write-Host "`nRapport dÃ©taillÃ© : $reportPath" -ForegroundColor Cyan
Write-Host "Journal : $LogFilePath" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
