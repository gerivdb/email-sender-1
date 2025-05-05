<#
.SYNOPSIS
    ImplÃƒÂ©mente la Phase 6 de la roadmap : correctifs prioritaires pour la gestion d'erreurs et la compatibilitÃƒÂ©.

.DESCRIPTION
    Ce script implÃƒÂ©mente les correctifs prioritaires de la Phase 6 de la roadmap, notamment :
    - AmÃƒÂ©lioration de la gestion d'erreurs dans les scripts existants
    - RÃƒÂ©solution des problÃƒÂ¨mes de compatibilitÃƒÂ© entre environnements

.PARAMETER ScriptsDirectory
    Le rÃƒÂ©pertoire contenant les scripts ÃƒÂ  analyser et ÃƒÂ  corriger.

.PARAMETER CreateBackup
    Indique s'il faut crÃƒÂ©er une sauvegarde des fichiers avant de les modifier.

.PARAMETER LogFilePath
    Le chemin du fichier journal pour enregistrer les actions effectuÃƒÂ©es.

.EXAMPLE
    .\Start-Phase6.ps1 -ScriptsDirectory "..\..\development\scripts" -CreateBackup -LogFilePath "phase6_implementation.log"

.NOTES
    Auteur: SystÃƒÂ¨me d'analyse d'erreurs
    Date de crÃƒÂ©ation: 09/04/2025
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

# Importer les modules nÃƒÂ©cessaires
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

# VÃƒÂ©rifier et importer les scripts utilitaires
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
    
    $continue = Read-Host "Voulez-vous continuer malgrÃƒÂ© les scripts manquants ? (O/N)"
    if ($continue -ne "O" -and $continue -ne "o") {
        Write-Host "OpÃƒÂ©ration annulÃƒÂ©e par l'utilisateur."
        return
    }
}

# Importer les scripts utilitaires disponibles
foreach ($scriptName in $utilityScripts.Keys) {
    $scriptPath = $utilityScripts[$scriptName]
    if (Test-Path -Path $scriptPath -PathType Leaf) {
        try {
            . $scriptPath
            Write-Verbose "Script $scriptName importÃƒÂ© avec succÃƒÂ¨s."
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
        Write-LogInfo "Phase 6 : ImplÃƒÂ©mentation des correctifs prioritaires dÃƒÂ©marrÃƒÂ©e"
    }
    catch {
        Write-Warning "Erreur lors de l'initialisation du logger : $_"
        # Fallback ÃƒÂ  une fonction de journalisation simple
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
        
        # DÃƒÂ©finir des alias pour les fonctions de journalisation
        Set-Alias -Name Write-LogInfo -Value Write-Log -Scope Script
        Set-Alias -Name Write-LogWarning -Value Write-Log -Scope Script
        Set-Alias -Name Write-LogError -Value Write-Log -Scope Script
        
        Write-Log "Phase 6 : ImplÃƒÂ©mentation des correctifs prioritaires dÃƒÂ©marrÃƒÂ©e"
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
    
    # DÃƒÂ©finir des alias pour les fonctions de journalisation
    Set-Alias -Name Write-LogInfo -Value Write-Log -Scope Script
    Set-Alias -Name Write-LogWarning -Value Write-Log -Scope Script
    Set-Alias -Name Write-LogError -Value Write-Log -Scope Script
    
    Write-Log "Phase 6 : ImplÃƒÂ©mentation des correctifs prioritaires dÃƒÂ©marrÃƒÂ©e"
}

# Fonction pour analyser les scripts et identifier ceux qui nÃƒÂ©cessitent des amÃƒÂ©liorations
function Find-ScriptsNeedingImprovements {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Directory,
        
        [Parameter(Mandatory = $false)]
        [string[]]$FileExtensions = @(".ps1", ".psm1")
    )
    
    Write-LogInfo "Recherche des scripts nÃƒÂ©cessitant des amÃƒÂ©liorations dans $Directory"
    
    $results = @{
        ErrorHandling = @()
        Compatibility = @()
    }
    
    # RÃƒÂ©cupÃƒÂ©rer tous les scripts PowerShell dans le rÃƒÂ©pertoire
    $scripts = Get-ChildItem -Path $Directory -Recurse -File | Where-Object { $FileExtensions -contains $_.Extension }
    Write-LogInfo "Nombre de scripts trouvÃƒÂ©s : $($scripts.Count)"
    
    foreach ($script in $scripts) {
        Write-Verbose "Analyse du script : $($script.FullName)"
        
        # Lire le contenu du script
        $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($null -eq $content) {
            Write-LogWarning "Impossible de lire le contenu du script : $($script.FullName)"
            continue
        }
        
        # VÃƒÂ©rifier la gestion d'erreurs
        $needsErrorHandling = -not ($content -match "try\s*{" -and $content -match "catch\s*{") -and
                             ($content -match "Remove-Item|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Rename-Item|Invoke-WebRequest|Invoke-RestMethod|Start-Process|Stop-Process")
        
        # VÃƒÂ©rifier la compatibilitÃƒÂ© entre environnements
        $needsCompatibility = $content -match "\\\\|C:\\|D:\\|\.exe|\.bat|\.cmd" -and
                             -not ($content -match "Join-Path|Split-Path|Test-Path.*-PathType|System\.IO\.Path")
        
        # Ajouter le script aux rÃƒÂ©sultats si nÃƒÂ©cessaire
        if ($needsErrorHandling) {
            $results.ErrorHandling += $script.FullName
        }
        
        if ($needsCompatibility) {
            $results.Compatibility += $script.FullName
        }
    }
    
    return $results
}

# Fonction pour amÃƒÂ©liorer la gestion d'erreurs dans les scripts
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
    
    Write-LogInfo "AmÃƒÂ©lioration de la gestion d'erreurs pour $($ScriptPaths.Count) scripts"
    
    $results = @{
        Succeeded = 0
        Failed = 0
        Details = @()
    }
    
    foreach ($scriptPath in $ScriptPaths) {
        Write-Verbose "Traitement du script : $scriptPath"
        
        if ($PSCmdlet.ShouldProcess($scriptPath, "AmÃƒÂ©liorer la gestion d'erreurs")) {
            try {
                # Utiliser TryCatchAdder.ps1 si disponible
                if (Test-Path -Path $tryCatchAdderPath -PathType Leaf) {
                    $success = Add-TryCatchBlocks -Path $scriptPath -CreateBackup:$CreateBackup -AddLogging:$AddLogging
                    
                    if ($success) {
                        Write-LogInfo "Gestion d'erreurs amÃƒÂ©liorÃƒÂ©e pour : $scriptPath"
                        $results.Succeeded++
                        $results.Details += [PSCustomObject]@{
                            Path = $scriptPath
                            Status = "Success"
                            Message = "Gestion d'erreurs amÃƒÂ©liorÃƒÂ©e"
                        }
                    }
                    else {
                        Write-LogWarning "Ãƒâ€°chec de l'amÃƒÂ©lioration de la gestion d'erreurs pour : $scriptPath"
                        $results.Failed++
                        $results.Details += [PSCustomObject]@{
                            Path = $scriptPath
                            Status = "Failed"
                            Message = "Ãƒâ€°chec de l'amÃƒÂ©lioration de la gestion d'erreurs"
                        }
                    }
                }
                else {
                    # ImplÃƒÂ©mentation manuelle si TryCatchAdder.ps1 n'est pas disponible
                    $content = Get-Content -Path $scriptPath -Raw
                    
                    # CrÃƒÂ©er une sauvegarde si demandÃƒÂ©
                    if ($CreateBackup) {
                        $backupPath = "$scriptPath.bak"
                        Copy-Item -Path $scriptPath -Destination $backupPath -Force
                        Write-Verbose "Sauvegarde crÃƒÂ©ÃƒÂ©e : $backupPath"
                    }
                    
                    # Ajouter ErrorActionPreference = 'Stop' au dÃƒÂ©but du script
                    if (-not ($content -match '\$ErrorActionPreference\s*=\s*[''"]Stop[''"]')) {
                        $content = "`$ErrorActionPreference = 'Stop'`n`n$content"
                    }
                    
                    # Entourer le script principal d'un bloc try/catch
                    if (-not ($content -match "try\s*{" -and $content -match "catch\s*{")) {
                        # Extraire les commentaires et les dÃƒÂ©clarations param au dÃƒÂ©but du script
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
    
    # CrÃƒÂ©er le dossier de logs si nÃƒÂ©cessaire
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
    
    # Ãƒâ€°crire dans le fichier journal
    try {
        Add-Content -Path `$LogFilePath -Value `$logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'ÃƒÂ©criture dans le journal
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
    $(if ($AddLogging) { "Write-Log -Level INFO -Message `"ExÃƒÂ©cution du script terminÃƒÂ©e.`"" } else { "Write-Verbose `"ExÃƒÂ©cution du script terminÃƒÂ©e.`"" })
}
"@
                        
                        # Enregistrer le nouveau contenu
                        Set-Content -Path $scriptPath -Value $newContent
                        
                        Write-LogInfo "Gestion d'erreurs amÃƒÂ©liorÃƒÂ©e pour : $scriptPath"
                        $results.Succeeded++
                        $results.Details += [PSCustomObject]@{
                            Path = $scriptPath
                            Status = "Success"
                            Message = "Gestion d'erreurs amÃƒÂ©liorÃƒÂ©e manuellement"
                        }
                    }
                    else {
                        Write-LogInfo "Le script possÃƒÂ¨de dÃƒÂ©jÃƒÂ  une gestion d'erreurs : $scriptPath"
                        $results.Succeeded++
                        $results.Details += [PSCustomObject]@{
                            Path = $scriptPath
                            Status = "Skipped"
                            Message = "Le script possÃƒÂ¨de dÃƒÂ©jÃƒÂ  une gestion d'erreurs"
                        }
                    }
                }
            }
            catch {
                Write-LogError "Erreur lors de l'amÃƒÂ©lioration de la gestion d'erreurs pour $scriptPath : $_"
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

# Fonction pour amÃƒÂ©liorer la compatibilitÃƒÂ© entre environnements
function Update-EnvironmentCompatibility {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ScriptPaths,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup
    )
    
    Write-LogInfo "AmÃƒÂ©lioration de la compatibilitÃƒÂ© entre environnements pour $($ScriptPaths.Count) scripts"
    
    $results = @{
        Succeeded = 0
        Failed = 0
        Details = @()
    }
    
    foreach ($scriptPath in $ScriptPaths) {
        Write-Verbose "Traitement du script : $scriptPath"
        
        if ($PSCmdlet.ShouldProcess($scriptPath, "AmÃƒÂ©liorer la compatibilitÃƒÂ© entre environnements")) {
            try {
                # Utiliser PathStandardizer.ps1 si disponible
                if (Test-Path -Path $pathStandardizerPath -PathType Leaf) {
                    # ImplÃƒÂ©menter l'appel ÃƒÂ  PathStandardizer.ps1
                    # Cette partie dÃƒÂ©pend de l'implÃƒÂ©mentation spÃƒÂ©cifique de PathStandardizer.ps1
                    Write-Verbose "Utilisation de PathStandardizer.ps1 pour $scriptPath"
                }
                
                # ImplÃƒÂ©mentation manuelle
                $content = Get-Content -Path $scriptPath -Raw
                
                # CrÃƒÂ©er une sauvegarde si demandÃƒÂ©
                if ($CreateBackup) {
                    $backupPath = "$scriptPath.bak"
                    Copy-Item -Path $scriptPath -Destination $backupPath -Force
                    Write-Verbose "Sauvegarde crÃƒÂ©ÃƒÂ©e : $backupPath"
                }
                
                # Remplacer les chemins absolus par des chemins relatifs
                $newContent = $content
                
                # Remplacer les concatÃƒÂ©nations de chemins par Join-Path
                $newContent = [regex]::Replace($newContent, '([''"][^''"\r\n]*[''"])\s*\+\s*[''"][\\\/]?([^''"\r\n]*)[''"]', '(Join-Path -Path $1 -ChildPath "$2")')
                
                # Remplacer les chemins absolus Windows par des chemins relatifs
                $newContent = [regex]::Replace($newContent, '([''"])[A-Za-z]:\\([^''"\r\n]*)(["''])', '$1$2$3')
                
                # Ajouter une fonction d'environnement si elle n'existe pas dÃƒÂ©jÃƒÂ 
                if (-not ($newContent -match "function Get-ScriptEnvironment" -or $newContent -match "function Test-Environment")) {
                    $environmentFunction = @"

# Fonction pour dÃƒÂ©tecter l'environnement d'exÃƒÂ©cution
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
    
    # DÃƒÂ©tecter le systÃƒÂ¨me d'exploitation
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
    
    # Normaliser les sÃƒÂ©parateurs de chemin
    `$normalizedPath = `$Path.Replace('\', `$env.PathSeparator).Replace('/', `$env.PathSeparator)
    
    return `$normalizedPath
}

"@
                    
                    # Ajouter la fonction au dÃƒÂ©but du script aprÃƒÂ¨s les commentaires et les dÃƒÂ©clarations param
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
                
                Write-LogInfo "CompatibilitÃƒÂ© entre environnements amÃƒÂ©liorÃƒÂ©e pour : $scriptPath"
                $results.Succeeded++
                $results.Details += [PSCustomObject]@{
                    Path = $scriptPath
                    Status = "Success"
                    Message = "CompatibilitÃƒÂ© entre environnements amÃƒÂ©liorÃƒÂ©e"
                }
            }
            catch {
                Write-LogError "Erreur lors de l'amÃƒÂ©lioration de la compatibilitÃƒÂ© entre environnements pour $scriptPath : $_"
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
    
    Write-LogInfo "DÃƒÂ©marrage de l'implÃƒÂ©mentation de la Phase 6"
    Write-LogInfo "RÃƒÂ©pertoire des scripts : $ScriptsDirectory"
    
    # VÃƒÂ©rifier si le rÃƒÂ©pertoire des scripts existe
    if (-not (Test-Path -Path $ScriptsDirectory -PathType Container)) {
        Write-LogError "Le rÃƒÂ©pertoire des scripts n'existe pas : $ScriptsDirectory"
        return $false
    }
    
    # Trouver les scripts nÃƒÂ©cessitant des amÃƒÂ©liorations
    $scriptsNeedingImprovements = Find-ScriptsNeedingImprovements -Directory $ScriptsDirectory
    
    Write-LogInfo "Nombre de scripts nÃƒÂ©cessitant une amÃƒÂ©lioration de la gestion d'erreurs : $($scriptsNeedingImprovements.ErrorHandling.Count)"
    Write-LogInfo "Nombre de scripts nÃƒÂ©cessitant une amÃƒÂ©lioration de la compatibilitÃƒÂ© entre environnements : $($scriptsNeedingImprovements.Compatibility.Count)"
    
    # AmÃƒÂ©liorer la gestion d'erreurs
    if ($scriptsNeedingImprovements.ErrorHandling.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess("$($scriptsNeedingImprovements.ErrorHandling.Count) scripts", "AmÃƒÂ©liorer la gestion d'erreurs")) {
            $errorHandlingResults = Update-ErrorHandling -ScriptPaths $scriptsNeedingImprovements.ErrorHandling -CreateBackup:$CreateBackup -AddLogging:$AddLogging
            Write-LogInfo "AmÃƒÂ©lioration de la gestion d'erreurs terminÃƒÂ©e : $($errorHandlingResults.Succeeded) rÃƒÂ©ussites, $($errorHandlingResults.Failed) ÃƒÂ©checs"
        }
    }
    else {
        Write-LogInfo "Aucun script ne nÃƒÂ©cessite d'amÃƒÂ©lioration de la gestion d'erreurs"
    }
    
    # AmÃƒÂ©liorer la compatibilitÃƒÂ© entre environnements
    if ($scriptsNeedingImprovements.Compatibility.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess("$($scriptsNeedingImprovements.Compatibility.Count) scripts", "AmÃƒÂ©liorer la compatibilitÃƒÂ© entre environnements")) {
            $compatibilityResults = Update-EnvironmentCompatibility -ScriptPaths $scriptsNeedingImprovements.Compatibility -CreateBackup:$CreateBackup
            Write-LogInfo "AmÃƒÂ©lioration de la compatibilitÃƒÂ© entre environnements terminÃƒÂ©e : $($compatibilityResults.Succeeded) rÃƒÂ©ussites, $($compatibilityResults.Failed) ÃƒÂ©checs"
        }
    }
    else {
        Write-LogInfo "Aucun script ne nÃƒÂ©cessite d'amÃƒÂ©lioration de la compatibilitÃƒÂ© entre environnements"
    }
    
    # GÃƒÂ©nÃƒÂ©rer un rapport
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
    Write-LogInfo "Rapport enregistrÃƒÂ© : $reportPath"
    
    Write-LogInfo "ImplÃƒÂ©mentation de la Phase 6 terminÃƒÂ©e"
    
    return $report
}

# ExÃƒÂ©cuter la fonction principale
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

# Afficher un rÃƒÂ©sumÃƒÂ©
Write-Host "`nRÃƒÂ©sumÃƒÂ© de l'implÃƒÂ©mentation de la Phase 6 :" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Gestion d'erreurs :" -ForegroundColor Yellow
Write-Host "  - Scripts analysÃƒÂ©s : $($result.ErrorHandling.Total)" -ForegroundColor White
Write-Host "  - AmÃƒÂ©liorations rÃƒÂ©ussies : $($result.ErrorHandling.Succeeded)" -ForegroundColor Green
Write-Host "  - Ãƒâ€°checs : $($result.ErrorHandling.Failed)" -ForegroundColor Red

Write-Host "`nCompatibilitÃƒÂ© entre environnements :" -ForegroundColor Yellow
Write-Host "  - Scripts analysÃƒÂ©s : $($result.Compatibility.Total)" -ForegroundColor White
Write-Host "  - AmÃƒÂ©liorations rÃƒÂ©ussies : $($result.Compatibility.Succeeded)" -ForegroundColor Green
Write-Host "  - Ãƒâ€°checs : $($result.Compatibility.Failed)" -ForegroundColor Red

Write-Host "`nRapport dÃƒÂ©taillÃƒÂ© : $reportPath" -ForegroundColor Cyan
Write-Host "Journal : $LogFilePath" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
