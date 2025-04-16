#Requires -Version 5.1
# Note: Get-CimInstance pour CommandLine peut nécessiter des privilèges élevés dans certains cas

<#
.SYNOPSIS
    Vérifie l'état d'exécution des serveurs MCP sur la machine locale.

.DESCRIPTION
    Ce script identifie si des serveurs MCP définis (basés sur des motifs dans leur ligne de commande)
    sont actuellement en cours d'exécution sur le système local. Il utilise Get-CimInstance pour une
    récupération d'informations plus moderne et robuste.

    Le script fournit :
    - Une sortie console colorée indiquant le statut de chaque serveur.
    - Un résumé final de l'état de tous les serveurs surveillés.
    - Une journalisation détaillée via le flux Verbose (-Verbose).
    - La possibilité d'enregistrer les logs dans un fichier (-LogFile).
    - Une structure de données pour définir facilement les serveurs à surveiller.
    - Une gestion des erreurs améliorée.

.PARAMETER ServerDefinitions
    Un tableau de Hashtables définissant les serveurs à vérifier.
    Chaque Hashtable doit contenir les clés 'Name' (nom convivial) et 'Pattern' (motif Regex à rechercher dans la ligne de commande).
    Par défaut, utilise une liste prédéfinie de serveurs MCP.

.PARAMETER LogFile
    Chemin facultatif vers un fichier où enregistrer les messages de log.
    Si spécifié, les logs seront ajoutés à ce fichier en plus d'être affichés (selon -Verbose).

.EXAMPLE
    .\check-mcp-servers-v2-noadmin.ps1
    # Exécute la vérification avec les serveurs MCP par défaut.

.EXAMPLE
    .\check-mcp-servers-v2-noadmin.ps1 -Verbose
    # Exécute la vérification avec une sortie détaillée dans la console.

.EXAMPLE
    .\check-mcp-servers-v2-noadmin.ps1 -LogFile "logs\mcp_check.log" -Verbose
    # Exécute la vérification, enregistre les logs détaillés dans un fichier et les affiche en console.

.NOTES
    Auteur: Augment Agent (Amélioré par IA Claude)
    Version: 2.0
    Date: 2025-04-27
#>

[CmdletBinding(SupportsShouldProcess = $false)] # Supports -Verbose, pas d'action modifiant le système
param(
    [Parameter(Mandatory = $false)]
    [array]$ServerDefinitions = @(
        @{ Name = "MCP Filesystem"; Pattern = "server-filesystem"; IsRunning = $false; ProcessInfo = $null }
        @{ Name = "MCP GitHub"; Pattern = "server-github"; IsRunning = $false; ProcessInfo = $null }
        @{ Name = "MCP GCP"; Pattern = "gcp-mcp"; IsRunning = $false; ProcessInfo = $null }
        @{ Name = "MCP Supergateway"; Pattern = "supergateway"; IsRunning = $false; ProcessInfo = $null }
        @{ Name = "MCP Augment"; Pattern = "augment-mcp"; IsRunning = $false; ProcessInfo = $null }
        @{ Name = "MCP GDrive"; Pattern = "gdrive-mcp"; IsRunning = $false; ProcessInfo = $null }
        @{ Name = "MCP Augment Standard"; Pattern = "n8n-nodes-mcp"; IsRunning = $false; ProcessInfo = $null }
        @{ Name = "MCP Augment Gateway"; Pattern = "gateway"; IsRunning = $false; ProcessInfo = $null } # Attention: motif très générique 'gateway'
        @{ Name = "MCP Augment Notion"; Pattern = "notion"; IsRunning = $false; ProcessInfo = $null } # Attention: motif très générique 'notion'
        @{ Name = "MCP Augment Git Ingest"; Pattern = "git-ingest"; IsRunning = $false; ProcessInfo = $null }
        @{ Name = "MCP Augment GitHub"; Pattern = "mcp-github"; IsRunning = $false; ProcessInfo = $null }
        # Ajouter d'autres serveurs ici si nécessaire
    ),

    [Parameter(Mandatory = $false)]
    [string]$LogFile
)

#region Global Variables & Setup
$script:StartTime = Get-Date
$script:AbsoluteLogFilePath = $null

# Valider et préparer le chemin du fichier log si fourni
if ($PSBoundParameters.ContainsKey('LogFile')) {
    try {
        $logDir = Split-Path -Path $LogFile -Parent
        if (-not (Test-Path -Path $logDir -PathType Container)) {
            Write-Verbose "Création du répertoire pour le fichier log: $logDir"
            New-Item -Path $logDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
        }

        $script:AbsoluteLogFilePath = $LogFile
        # Écrit une ligne de démarrage dans le log (ou crée/vide le fichier)
        "[$($script:StartTime.ToString('yyyy-MM-dd HH:mm:ss'))] [INFO] Début de la vérification des serveurs MCP." | Add-Content -Path $script:AbsoluteLogFilePath -Encoding UTF8
    } catch {
        Write-Warning "Impossible de préparer le fichier log '$LogFile'. La journalisation fichier sera désactivée. Erreur: $($_.Exception.Message)"
        $script:AbsoluteLogFilePath = $null
    }
}
#endregion Global Variables & Setup

#region Helper Functions
# Fonction de journalisation améliorée (utilise les flux PS et fichier optionnel)
function Write-LogInternal {
    param(
        [Parameter(Mandatory = $true)] [string]$Message,
        [Parameter(Mandatory = $false)] [ValidateSet("INFO", "VERBOSE", "WARNING", "ERROR", "SUCCESS", "TITLE", "SUMMARY")] $Level = "INFO",
        [Parameter(Mandatory = $false)] [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [Parameter(Mandatory = $false)] [ConsoleColor]$ForegroundColor = $Host.UI.RawUI.ForegroundColor # Garde la couleur actuelle par défaut
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logPrefix = "[$timestamp] [$Level]"
    $logEntry = "$logPrefix $Message"

    if ($ErrorRecord) {
        $logEntry += "`n$logPrefix $($ErrorRecord | Out-String)" # Ajoute l'erreur complète indentée
    }

    # Écrire dans le fichier log si activé
    if ($script:AbsoluteLogFilePath) {
        try {
            Add-Content -Path $script:AbsoluteLogFilePath -Value $logEntry -Encoding UTF8 -ErrorAction Stop
        } catch {
            # Tenter une seule fois d'avertir sur l'échec d'écriture
            Write-Warning "Échec de l'écriture dans le fichier log '$script:AbsoluteLogFilePath': $($_.Exception.Message). Désactivation de la journalisation fichier."
            $script:AbsoluteLogFilePath = $null
        }
    }

    # Afficher dans la console en utilisant les flux appropriés
    switch ($Level) {
        "VERBOSE" { Write-Verbose $logEntry } # Visible uniquement avec -Verbose
        "WARNING" { Write-Warning $Message }  # Flux Warning (préfixe 'WARNING:' ajouté par PS)
        "ERROR" {
            # Écrit l'erreur sur le flux d'erreur, qui est plus structuré
            $exception = New-Object System.Exception($Message, $($ErrorRecord.Exception))
            $errorRecord = New-Object System.Management.Automation.ErrorRecord($exception, "ScriptError", [System.Management.Automation.ErrorCategory]::NotSpecified, $null)
            $PSCmdlet.WriteError($errorRecord)
        }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "TITLE" { Write-Host "`n" + ("=" * 60) -ForegroundColor Cyan; Write-Host $Message -ForegroundColor Cyan; Write-Host ("=" * 60) -ForegroundColor Cyan }
        "SUMMARY" { Write-Host $logEntry -ForegroundColor $ForegroundColor } # Utilisé pour le résumé final
        default { Write-Host $logEntry -ForegroundColor $ForegroundColor } # INFO et autres
    }
}

# Fonction pour récupérer les processus avec leur ligne de commande via CIM
function Get-ProcessesWithCommandLineCim {
    Write-LogInternal -Level VERBOSE -Message "Tentative de récupération des processus via Get-CimInstance Win32_Process..."
    $processes = @()

    try {
        # Sélectionne seulement les propriétés nécessaires pour la performance
        $processes = Get-CimInstance -ClassName Win32_Process -Property ProcessId, Name, CommandLine -ErrorAction Stop | Where-Object { -not ([string]::IsNullOrWhiteSpace($_.CommandLine)) }
        Write-LogInternal -Level VERBOSE -Message "Succès: $($processes.Count) processus récupérés avec ligne de commande non vide."
    } catch [System.UnauthorizedAccessException] {
        Write-LogInternal -Level WARNING -Message "Erreur d'autorisation lors de la récupération des processus. Certains processus peuvent ne pas être visibles sans privilèges administrateur."
        # Essayer une méthode alternative avec tasklist
        Write-LogInternal -Level INFO -Message "Tentative de récupération des processus via tasklist..."
        try {
            $tasklistOutput = tasklist /v /fo csv | ConvertFrom-Csv
            Write-LogInternal -Level INFO -Message "Récupération via tasklist réussie: $($tasklistOutput.Count) processus récupérés."

            # Convertir la sortie de tasklist en objets similaires à ceux de Get-CimInstance
            foreach ($task in $tasklistOutput) {
                $processObj = New-Object PSObject
                $processObj | Add-Member -MemberType NoteProperty -Name "ProcessId" -Value $task."PID"
                $processObj | Add-Member -MemberType NoteProperty -Name "Name" -Value $task."Image Name"
                $processObj | Add-Member -MemberType NoteProperty -Name "CommandLine" -Value $task."Window Title" # Utiliser Window Title comme approximation
                $processes += $processObj
            }
        } catch {
            Write-LogInternal -Level ERROR -Message "Échec de la récupération des processus via tasklist: $($_.Exception.Message)" -ErrorRecord $_
        }
    } catch {
        Write-LogInternal -Level ERROR -Message "Erreur inattendue lors de la récupération des processus via Get-CimInstance: $($_.Exception.Message)" -ErrorRecord $_
        # Essayer une méthode alternative avec tasklist comme ci-dessus
        Write-LogInternal -Level INFO -Message "Tentative de récupération des processus via tasklist..."
        try {
            $tasklistOutput = tasklist /v /fo csv | ConvertFrom-Csv
            Write-LogInternal -Level INFO -Message "Récupération via tasklist réussie: $($tasklistOutput.Count) processus récupérés."

            # Convertir la sortie de tasklist en objets similaires à ceux de Get-CimInstance
            foreach ($task in $tasklistOutput) {
                $processObj = New-Object PSObject
                $processObj | Add-Member -MemberType NoteProperty -Name "ProcessId" -Value $task."PID"
                $processObj | Add-Member -MemberType NoteProperty -Name "Name" -Value $task."Image Name"
                $processObj | Add-Member -MemberType NoteProperty -Name "CommandLine" -Value $task."Window Title" # Utiliser Window Title comme approximation
                $processes += $processObj
            }
        } catch {
            Write-LogInternal -Level ERROR -Message "Échec de la récupération des processus via tasklist: $($_.Exception.Message)" -ErrorRecord $_
        }
    }

    return $processes
}
#endregion Helper Functions

#region Main Logic
# Afficher le titre
Write-LogInternal -Level TITLE -Message "      VÉRIFICATION DE L'ÉTAT DES SERVEURS MCP       "

# Étape 1: Récupérer tous les processus avec leur ligne de commande (une seule fois)
$allProcessesCim = Get-ProcessesWithCommandLineCim
if ($null -eq $allProcessesCim -or $allProcessesCim.Count -eq 0) {
    Write-LogInternal -Level ERROR -Message "Impossible de continuer sans la liste des processus."
    exit 1 # Quitter explicitement
}

# Étape 2: Itérer sur les processus et vérifier les correspondances
Write-LogInternal -Level INFO -Message "Analyse des $($allProcessesCim.Count) processus pour identifier les serveurs MCP définis..."
$progressCount = 0
$totalProcesses = $allProcessesCim.Count

foreach ($process in $allProcessesCim) {
    $progressCount++
    Write-Progress -Activity "Analyse des processus" -Status "Processus $progressCount / $totalProcesses" -PercentComplete (($progressCount / $totalProcesses) * 100)

    # Optimisation: Si tous les serveurs ont été trouvés, on peut arrêter de chercher
    if (($ServerDefinitions | Where-Object { -not $_.IsRunning }).Count -eq 0) {
        Write-LogInternal -Level VERBOSE -Message "Tous les serveurs définis ont été trouvés. Arrêt anticipé de l'analyse des processus."
        break
    }

    $commandLine = $process.CommandLine
    if ([string]::IsNullOrWhiteSpace($commandLine)) {
        continue # Ignorer les processus sans ligne de commande
    }

    # Boucle sur chaque définition de serveur *qui n'a pas encore été trouvée*
    foreach ($serverDef in ($ServerDefinitions | Where-Object { -not $_.IsRunning })) {
        try {
            # Utiliser -match pour la correspondance regex
            if ($commandLine -match $serverDef.Pattern) {
                Write-LogInternal -Level VERBOSE -Message "Correspondance trouvée pour '$($serverDef.Name)' (Motif: '$($serverDef.Pattern)') -> PID: $($process.ProcessId), Cmd: '$commandLine'"
                $serverDef.IsRunning = $true
                $serverDef.ProcessInfo = $process # Stocker l'info du processus trouvé
            }
        } catch {
            Write-LogInternal -Level WARNING -Message "Erreur lors de la vérification du motif '$($serverDef.Pattern)' pour le processus PID $($process.ProcessId): $($_.Exception.Message)" -ErrorRecord $_
        }
    }
}

Write-Progress -Activity "Analyse des processus" -Completed

# Étape 3: Afficher les résultats individuels et construire le résumé
Write-LogInternal -Level INFO -Message "Résultats de la vérification :"
foreach ($serverDef in $ServerDefinitions) {
    if ($serverDef.IsRunning) {
        Write-LogInternal -Level SUCCESS -Message "Serveur '$($serverDef.Name)' -> EN COURS D'EXÉCUTION (PID: $($serverDef.ProcessInfo.ProcessId))"
    } else {
        Write-LogInternal -Level WARNING -Message "Serveur '$($serverDef.Name)' -> ARRÊTÉ ou non trouvé"
    }
}

# Étape 4: Afficher le résumé final
Write-LogInternal -Level TITLE -Message "                  RÉSUMÉ DES SERVEURS MCP                "
$allRunning = $true
foreach ($server in $ServerDefinitions) {
    $statusText = if ($server.IsRunning) { "EN COURS D'EXÉCUTION" } else { "ARRÊTÉ" }
    $statusColor = if ($server.IsRunning) { "Green" } else { "Red" }
    if (-not $server.IsRunning) { $allRunning = $false }

    # Formatage aligné (ajuster le padding si nécessaire)
    $namePadded = $server.Name.PadRight(30) # Ajuster 30 selon le nom le plus long
    Write-LogInternal -Level SUMMARY -Message "- $namePadded : $statusText" -ForegroundColor $statusColor
}

Write-Host "" # Ligne vide après le résumé
if (-not $allRunning) {
    Write-LogInternal -Level WARNING -Message "Certains serveurs MCP ne sont pas en cours d'exécution."
    Write-LogInternal -Level INFO -Message "Pour démarrer les serveurs MCP, vous pouvez utiliser le script 'start-all-mcp-servers.cmd'." -ForegroundColor Yellow
} else {
    Write-LogInternal -Level SUCCESS -Message "Tous les serveurs MCP surveillés sont en cours d'exécution."
}

$script:EndTime = Get-Date
$duration = $script:EndTime - $script:StartTime
Write-LogInternal -Level VERBOSE -Message "Fin de la vérification. Durée totale: $($duration.ToString('g'))"
#endregion Main Logic
