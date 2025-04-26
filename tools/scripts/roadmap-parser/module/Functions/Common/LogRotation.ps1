<#
.SYNOPSIS
    Fonctions de rotation des fichiers de journal pour le module RoadmapParser.

.DESCRIPTION
    Ce fichier contient des fonctions pour gérer la rotation des fichiers de journal
    dans le module RoadmapParser, permettant de limiter la taille des fichiers et
    de conserver un historique.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2025-04-26
#>

<#
.SYNOPSIS
    Effectue la rotation d'un fichier de journal.

.DESCRIPTION
    Cette fonction effectue la rotation d'un fichier de journal en renommant les fichiers existants
    et en créant un nouveau fichier vide.

.PARAMETER LogFile
    Le chemin du fichier de journal à faire tourner.

.PARAMETER MaxLogFiles
    Le nombre maximum de fichiers de journal à conserver.

.PARAMETER Compress
    Indique si les anciens fichiers de journal doivent être compressés.

.EXAMPLE
    Invoke-LogRotation -LogFile "C:\Logs\roadmap-parser.log" -MaxLogFiles 5

.NOTES
    Cette fonction est appelée automatiquement par les fonctions de journalisation
    lorsque la taille maximale d'un fichier est atteinte.
#>
function Invoke-LogRotation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [int]$MaxLogFiles = 5,

        [Parameter(Mandatory = $false)]
        [switch]$Compress
    )

    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path -Path $LogFile)) {
            Write-Warning "Le fichier de journal n'existe pas: $LogFile"
            return $false
        }

        # Obtenir le répertoire et le nom de base du fichier
        $logDir = Split-Path -Path $LogFile -Parent
        $logBaseName = Split-Path -Path $LogFile -Leaf
        $logBaseNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($logBaseName)
        $logExt = [System.IO.Path]::GetExtension($logBaseName)

        # Supprimer le fichier le plus ancien si nécessaire
        $oldestLogFile = Join-Path -Path $logDir -ChildPath "$logBaseNameWithoutExt.$MaxLogFiles$logExt"
        if (Test-Path -Path $oldestLogFile) {
            Remove-Item -Path $oldestLogFile -Force
        }

        # Faire tourner les fichiers existants
        for ($i = $MaxLogFiles - 1; $i -ge 1; $i--) {
            $currentLogFile = Join-Path -Path $logDir -ChildPath "$logBaseNameWithoutExt.$i$logExt"
            $nextLogFile = Join-Path -Path $logDir -ChildPath "$logBaseNameWithoutExt.$($i+1)$logExt"

            if (Test-Path -Path $currentLogFile) {
                if ($Compress -and $i -lt ($MaxLogFiles - 1)) {
                    # Compresser le fichier si demandé
                    $compressedFile = "$nextLogFile.zip"
                    Compress-Archive -Path $currentLogFile -DestinationPath $compressedFile -Force
                    Remove-Item -Path $currentLogFile -Force
                } else {
                    # Sinon, simplement renommer
                    Move-Item -Path $currentLogFile -Destination $nextLogFile -Force
                }
            }
        }

        # Renommer le fichier actuel
        $newLogFile = Join-Path -Path $logDir -ChildPath "$logBaseNameWithoutExt.1$logExt"
        Move-Item -Path $LogFile -Destination $newLogFile -Force

        # Créer un nouveau fichier vide
        $header = "=== Nouveau fichier de journal créé après rotation le $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ==="
        Set-Content -Path $LogFile -Value $header -Encoding UTF8

        return $true
    }
    catch {
        Write-Warning "Erreur lors de la rotation du fichier de journal: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Nettoie les anciens fichiers de journal.

.DESCRIPTION
    Cette fonction supprime les fichiers de journal plus anciens qu'une date spécifiée.

.PARAMETER LogDirectory
    Le répertoire contenant les fichiers de journal.

.PARAMETER Pattern
    Le modèle de nom de fichier à rechercher.

.PARAMETER MaxAgeDays
    L'âge maximum des fichiers en jours.

.EXAMPLE
    Clear-OldLogFiles -LogDirectory "C:\Logs" -Pattern "roadmap-parser*.log" -MaxAgeDays 30

.NOTES
    Cette fonction est utile pour les tâches de maintenance périodiques.
#>
function Clear-OldLogFiles {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogDirectory,

        [Parameter(Mandatory = $false)]
        [string]$Pattern = "*.log",

        [Parameter(Mandatory = $false)]
        [int]$MaxAgeDays = 30
    )

    try {
        # Vérifier que le répertoire existe
        if (-not (Test-Path -Path $LogDirectory -PathType Container)) {
            Write-Warning "Le répertoire de journaux n'existe pas: $LogDirectory"
            return $false
        }

        # Calculer la date limite
        $cutoffDate = (Get-Date).AddDays(-$MaxAgeDays)

        # Trouver et supprimer les fichiers plus anciens que la date limite
        $oldFiles = Get-ChildItem -Path $LogDirectory -Filter $Pattern | Where-Object { $_.LastWriteTime -lt $cutoffDate }

        if ($oldFiles.Count -eq 0) {
            Write-Verbose "Aucun fichier de journal plus ancien que $MaxAgeDays jours trouvé."
            return $true
        }

        foreach ($file in $oldFiles) {
            Remove-Item -Path $file.FullName -Force
            Write-Verbose "Fichier de journal supprimé: $($file.FullName)"
        }

        Write-Verbose "$($oldFiles.Count) fichiers de journal supprimés."
        return $true
    }
    catch {
        Write-Warning "Erreur lors du nettoyage des anciens fichiers de journal: $($_.Exception.Message)"
        return $false
    }
}

<#
.SYNOPSIS
    Compresse les fichiers de journal.

.DESCRIPTION
    Cette fonction compresse les fichiers de journal pour économiser de l'espace disque.

.PARAMETER LogFile
    Le chemin du fichier de journal à compresser.

.PARAMETER ArchiveDirectory
    Le répertoire où stocker les archives.

.PARAMETER DeleteOriginal
    Indique si le fichier original doit être supprimé après compression.

.EXAMPLE
    Compress-LogFile -LogFile "C:\Logs\roadmap-parser.1.log" -ArchiveDirectory "C:\Logs\Archives"

.NOTES
    Cette fonction nécessite PowerShell 5.0 ou supérieur pour utiliser Compress-Archive.
#>
function Compress-LogFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$LogFile,

        [Parameter(Mandatory = $false)]
        [string]$ArchiveDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$DeleteOriginal
    )

    try {
        # Vérifier que le fichier existe
        if (-not (Test-Path -Path $LogFile)) {
            Write-Warning "Le fichier de journal n'existe pas: $LogFile"
            return $false
        }

        # Déterminer le répertoire d'archive
        if (-not $ArchiveDirectory) {
            $ArchiveDirectory = Split-Path -Path $LogFile -Parent
        }

        # Créer le répertoire d'archive si nécessaire
        if (-not (Test-Path -Path $ArchiveDirectory -PathType Container)) {
            New-Item -Path $ArchiveDirectory -ItemType Directory -Force | Out-Null
        }

        # Générer le nom de l'archive
        $logBaseName = Split-Path -Path $LogFile -Leaf
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $archiveFile = Join-Path -Path $ArchiveDirectory -ChildPath "$logBaseName-$timestamp.zip"

        # Compresser le fichier
        Compress-Archive -Path $LogFile -DestinationPath $archiveFile -Force

        # Supprimer l'original si demandé
        if ($DeleteOriginal) {
            Remove-Item -Path $LogFile -Force
        }

        Write-Verbose "Fichier de journal compressé: $LogFile -> $archiveFile"
        return $true
    }
    catch {
        Write-Warning "Erreur lors de la compression du fichier de journal: $($_.Exception.Message)"
        return $false
    }
}

# Note: Les fonctions sont exportées lors de l'importation du module
# Invoke-LogRotation, Clear-OldLogFiles, Compress-LogFile
