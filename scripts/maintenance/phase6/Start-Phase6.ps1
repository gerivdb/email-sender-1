<#
.SYNOPSIS
    Implémente la Phase 6 de la roadmap : correctifs prioritaires pour la gestion d'erreurs et la compatibilité.

.DESCRIPTION
    Ce script implémente les correctifs prioritaires de la Phase 6 de la roadmap, notamment :
    - Amélioration de la gestion d'erreurs dans les scripts existants
    - Résolution des problèmes de compatibilité entre environnements

.PARAMETER ScriptsDirectory
    Le répertoire contenant les scripts à analyser et à corriger.

.PARAMETER CreateBackup
    Indique s'il faut créer une sauvegarde des fichiers avant de les modifier.

.PARAMETER LogFilePath
    Le chemin du fichier journal pour enregistrer les actions effectuées.

.EXAMPLE
    .\Start-Phase6.ps1 -ScriptsDirectory "..\..\scripts" -CreateBackup -LogFilePath "phase6_implementation.log"

.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 09/04/2025
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

# Importer les modules nécessaires
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

# Vérifier et importer les scripts utilitaires
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
    
    $continue = Read-Host "Voulez-vous continuer malgré les scripts manquants ? (O/N)"
    if ($continue -ne "O" -and $continue -ne "o") {
        Write-Host "Opération annulée par l'utilisateur."
        return
    }
}

# Importer les scripts utilitaires disponibles
foreach ($scriptName in $utilityScripts.Keys) {
    $scriptPath = $utilityScripts[$scriptName]
    if (Test-Path -Path $scriptPath -PathType Leaf) {
        try {
            . $scriptPath
            Write-Verbose "Script $scriptName importé avec succès."
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
        Write-LogInfo "Phase 6 : Implémentation des correctifs prioritaires démarrée"
    }
    catch {
        Write-Warning "Erreur lors de l'initialisation du logger : $_"
        # Fallback à une fonction de journalisation simple
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
        
        # Définir des alias pour les fonctions de journalisation
        Set-Alias -Name Write-LogInfo -Value Write-Log -Scope Script
        Set-Alias -Name Write-LogWarning -Value Write-Log -Scope Script
        Set-Alias -Name Write-LogError -Value Write-Log -Scope Script
        
        Write-Log "Phase 6 : Implémentation des correctifs prioritaires démarrée"
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
    
    # Définir des alias pour les fonctions de journalisation
    Set-Alias -Name Write-LogInfo -Value Write-Log -Scope Script
    Set-Alias -Name Write-LogWarning -Value Write-Log -Scope Script
    Set-Alias -Name Write-LogError -Value Write-Log -Scope Script
    
    Write-Log "Phase 6 : Implémentation des correctifs prioritaires démarrée"
}

# Fonction pour analyser les scripts et identifier ceux qui nécessitent des améliorations
function Find-ScriptsNeedingImprovements {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Directory,
        
        [Parameter(Mandatory = $false)]
        [string[]]$FileExtensions = @(".ps1", ".psm1")
    )
    
    Write-LogInfo "Recherche des scripts nécessitant des améliorations dans $Directory"
    
    $results = @{
        ErrorHandling = @()
        Compatibility = @()
    }
    
    # Récupérer tous les scripts PowerShell dans le répertoire
    $scripts = Get-ChildItem -Path $Directory -Recurse -File | Where-Object { $FileExtensions -contains $_.Extension }
    Write-LogInfo "Nombre de scripts trouvés : $($scripts.Count)"
    
    foreach ($script in $scripts) {
        Write-Verbose "Analyse du script : $($script.FullName)"
        
        # Lire le contenu du script
        $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue
        
        if ($null -eq $content) {
            Write-LogWarning "Impossible de lire le contenu du script : $($script.FullName)"
            continue
        }
        
        # Vérifier la gestion d'erreurs
        $needsErrorHandling = -not ($content -match "try\s*{" -and $content -match "catch\s*{") -and
                             ($content -match "Remove-Item|Set-Content|Add-Content|New-Item|Copy-Item|Move-Item|Rename-Item|Invoke-WebRequest|Invoke-RestMethod|Start-Process|Stop-Process")
        
        # Vérifier la compatibilité entre environnements
        $needsCompatibility = $content -match "\\\\|C:\\|D:\\|\.exe|\.bat|\.cmd" -and
                             -not ($content -match "Join-Path|Split-Path|Test-Path.*-PathType|System\.IO\.Path")
        
        # Ajouter le script aux résultats si nécessaire
        if ($needsErrorHandling) {
            $results.ErrorHandling += $script.FullName
        }
        
        if ($needsCompatibility) {
            $results.Compatibility += $script.FullName
        }
    }
    
    return $results
}

# Fonction pour améliorer la gestion d'erreurs dans les scripts
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
    
    Write-LogInfo "Amélioration de la gestion d'erreurs pour $($ScriptPaths.Count) scripts"
    
    $results = @{
        Succeeded = 0
        Failed = 0
        Details = @()
    }
    
    foreach ($scriptPath in $ScriptPaths) {
        Write-Verbose "Traitement du script : $scriptPath"
        
        if ($PSCmdlet.ShouldProcess($scriptPath, "Améliorer la gestion d'erreurs")) {
            try {
                # Utiliser TryCatchAdder.ps1 si disponible
                if (Test-Path -Path $tryCatchAdderPath -PathType Leaf) {
                    $success = Add-TryCatchBlocks -Path $scriptPath -CreateBackup:$CreateBackup -AddLogging:$AddLogging
                    
                    if ($success) {
                        Write-LogInfo "Gestion d'erreurs améliorée pour : $scriptPath"
                        $results.Succeeded++
                        $results.Details += [PSCustomObject]@{
                            Path = $scriptPath
                            Status = "Success"
                            Message = "Gestion d'erreurs améliorée"
                        }
                    }
                    else {
                        Write-LogWarning "Échec de l'amélioration de la gestion d'erreurs pour : $scriptPath"
                        $results.Failed++
                        $results.Details += [PSCustomObject]@{
                            Path = $scriptPath
                            Status = "Failed"
                            Message = "Échec de l'amélioration de la gestion d'erreurs"
                        }
                    }
                }
                else {
                    # Implémentation manuelle si TryCatchAdder.ps1 n'est pas disponible
                    $content = Get-Content -Path $scriptPath -Raw
                    
                    # Créer une sauvegarde si demandé
                    if ($CreateBackup) {
                        $backupPath = "$scriptPath.bak"
                        Copy-Item -Path $scriptPath -Destination $backupPath -Force
                        Write-Verbose "Sauvegarde créée : $backupPath"
                    }
                    
                    # Ajouter ErrorActionPreference = 'Stop' au début du script
                    if (-not ($content -match '\$ErrorActionPreference\s*=\s*[''"]Stop[''"]')) {
                        $content = "`$ErrorActionPreference = 'Stop'`n`n$content"
                    }
                    
                    # Entourer le script principal d'un bloc try/catch
                    if (-not ($content -match "try\s*{" -and $content -match "catch\s*{")) {
                        # Extraire les commentaires et les déclarations param au début du script
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
    
    # Créer le dossier de logs si nécessaire
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
    
    # Écrire dans le fichier journal
    try {
        Add-Content -Path `$LogFilePath -Value `$logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'écriture dans le journal
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
    $(if ($AddLogging) { "Write-Log -Level INFO -Message `"Exécution du script terminée.`"" } else { "Write-Verbose `"Exécution du script terminée.`"" })
}
"@
                        
                        # Enregistrer le nouveau contenu
                        Set-Content -Path $scriptPath -Value $newContent
                        
                        Write-LogInfo "Gestion d'erreurs améliorée pour : $scriptPath"
                        $results.Succeeded++
                        $results.Details += [PSCustomObject]@{
                            Path = $scriptPath
                            Status = "Success"
                            Message = "Gestion d'erreurs améliorée manuellement"
                        }
                    }
                    else {
                        Write-LogInfo "Le script possède déjà une gestion d'erreurs : $scriptPath"
                        $results.Succeeded++
                        $results.Details += [PSCustomObject]@{
                            Path = $scriptPath
                            Status = "Skipped"
                            Message = "Le script possède déjà une gestion d'erreurs"
                        }
                    }
                }
            }
            catch {
                Write-LogError "Erreur lors de l'amélioration de la gestion d'erreurs pour $scriptPath : $_"
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

# Fonction pour améliorer la compatibilité entre environnements
function Update-EnvironmentCompatibility {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string[]]$ScriptPaths,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateBackup
    )
    
    Write-LogInfo "Amélioration de la compatibilité entre environnements pour $($ScriptPaths.Count) scripts"
    
    $results = @{
        Succeeded = 0
        Failed = 0
        Details = @()
    }
    
    foreach ($scriptPath in $ScriptPaths) {
        Write-Verbose "Traitement du script : $scriptPath"
        
        if ($PSCmdlet.ShouldProcess($scriptPath, "Améliorer la compatibilité entre environnements")) {
            try {
                # Utiliser PathStandardizer.ps1 si disponible
                if (Test-Path -Path $pathStandardizerPath -PathType Leaf) {
                    # Implémenter l'appel à PathStandardizer.ps1
                    # Cette partie dépend de l'implémentation spécifique de PathStandardizer.ps1
                    Write-Verbose "Utilisation de PathStandardizer.ps1 pour $scriptPath"
                }
                
                # Implémentation manuelle
                $content = Get-Content -Path $scriptPath -Raw
                
                # Créer une sauvegarde si demandé
                if ($CreateBackup) {
                    $backupPath = "$scriptPath.bak"
                    Copy-Item -Path $scriptPath -Destination $backupPath -Force
                    Write-Verbose "Sauvegarde créée : $backupPath"
                }
                
                # Remplacer les chemins absolus par des chemins relatifs
                $newContent = $content
                
                # Remplacer les concaténations de chemins par Join-Path
                $newContent = [regex]::Replace($newContent, '([''"][^''"\r\n]*[''"])\s*\+\s*[''"][\\\/]?([^''"\r\n]*)[''"]', '(Join-Path -Path $1 -ChildPath "$2")')
                
                # Remplacer les chemins absolus Windows par des chemins relatifs
                $newContent = [regex]::Replace($newContent, '([''"])[A-Za-z]:\\([^''"\r\n]*)(["''])', '$1$2$3')
                
                # Ajouter une fonction d'environnement si elle n'existe pas déjà
                if (-not ($newContent -match "function Get-ScriptEnvironment" -or $newContent -match "function Test-Environment")) {
                    $environmentFunction = @"

# Fonction pour détecter l'environnement d'exécution
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
    
    # Détecter le système d'exploitation
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
    
    # Normaliser les séparateurs de chemin
    `$normalizedPath = `$Path.Replace('\', `$env.PathSeparator).Replace('/', `$env.PathSeparator)
    
    return `$normalizedPath
}

"@
                    
                    # Ajouter la fonction au début du script après les commentaires et les déclarations param
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
                
                Write-LogInfo "Compatibilité entre environnements améliorée pour : $scriptPath"
                $results.Succeeded++
                $results.Details += [PSCustomObject]@{
                    Path = $scriptPath
                    Status = "Success"
                    Message = "Compatibilité entre environnements améliorée"
                }
            }
            catch {
                Write-LogError "Erreur lors de l'amélioration de la compatibilité entre environnements pour $scriptPath : $_"
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
    
    Write-LogInfo "Démarrage de l'implémentation de la Phase 6"
    Write-LogInfo "Répertoire des scripts : $ScriptsDirectory"
    
    # Vérifier si le répertoire des scripts existe
    if (-not (Test-Path -Path $ScriptsDirectory -PathType Container)) {
        Write-LogError "Le répertoire des scripts n'existe pas : $ScriptsDirectory"
        return $false
    }
    
    # Trouver les scripts nécessitant des améliorations
    $scriptsNeedingImprovements = Find-ScriptsNeedingImprovements -Directory $ScriptsDirectory
    
    Write-LogInfo "Nombre de scripts nécessitant une amélioration de la gestion d'erreurs : $($scriptsNeedingImprovements.ErrorHandling.Count)"
    Write-LogInfo "Nombre de scripts nécessitant une amélioration de la compatibilité entre environnements : $($scriptsNeedingImprovements.Compatibility.Count)"
    
    # Améliorer la gestion d'erreurs
    if ($scriptsNeedingImprovements.ErrorHandling.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess("$($scriptsNeedingImprovements.ErrorHandling.Count) scripts", "Améliorer la gestion d'erreurs")) {
            $errorHandlingResults = Update-ErrorHandling -ScriptPaths $scriptsNeedingImprovements.ErrorHandling -CreateBackup:$CreateBackup -AddLogging:$AddLogging
            Write-LogInfo "Amélioration de la gestion d'erreurs terminée : $($errorHandlingResults.Succeeded) réussites, $($errorHandlingResults.Failed) échecs"
        }
    }
    else {
        Write-LogInfo "Aucun script ne nécessite d'amélioration de la gestion d'erreurs"
    }
    
    # Améliorer la compatibilité entre environnements
    if ($scriptsNeedingImprovements.Compatibility.Count -gt 0) {
        if ($PSCmdlet.ShouldProcess("$($scriptsNeedingImprovements.Compatibility.Count) scripts", "Améliorer la compatibilité entre environnements")) {
            $compatibilityResults = Update-EnvironmentCompatibility -ScriptPaths $scriptsNeedingImprovements.Compatibility -CreateBackup:$CreateBackup
            Write-LogInfo "Amélioration de la compatibilité entre environnements terminée : $($compatibilityResults.Succeeded) réussites, $($compatibilityResults.Failed) échecs"
        }
    }
    else {
        Write-LogInfo "Aucun script ne nécessite d'amélioration de la compatibilité entre environnements"
    }
    
    # Générer un rapport
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
    Write-LogInfo "Rapport enregistré : $reportPath"
    
    Write-LogInfo "Implémentation de la Phase 6 terminée"
    
    return $report
}

# Exécuter la fonction principale
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

# Afficher un résumé
Write-Host "`nRésumé de l'implémentation de la Phase 6 :" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
Write-Host "Gestion d'erreurs :" -ForegroundColor Yellow
Write-Host "  - Scripts analysés : $($result.ErrorHandling.Total)" -ForegroundColor White
Write-Host "  - Améliorations réussies : $($result.ErrorHandling.Succeeded)" -ForegroundColor Green
Write-Host "  - Échecs : $($result.ErrorHandling.Failed)" -ForegroundColor Red

Write-Host "`nCompatibilité entre environnements :" -ForegroundColor Yellow
Write-Host "  - Scripts analysés : $($result.Compatibility.Total)" -ForegroundColor White
Write-Host "  - Améliorations réussies : $($result.Compatibility.Succeeded)" -ForegroundColor Green
Write-Host "  - Échecs : $($result.Compatibility.Failed)" -ForegroundColor Red

Write-Host "`nRapport détaillé : $reportPath" -ForegroundColor Cyan
Write-Host "Journal : $LogFilePath" -ForegroundColor Cyan
Write-Host "----------------------------------------" -ForegroundColor Cyan
