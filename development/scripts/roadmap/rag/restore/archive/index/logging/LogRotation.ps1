# LogRotation.ps1
# Script implémentant la rotation des journaux d'indexation
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexLogFormatPath = Join-Path -Path $scriptPath -ChildPath "IndexLogFormat.ps1"

if (Test-Path -Path $indexLogFormatPath) {
    . $indexLogFormatPath
} else {
    Write-Error "Le fichier IndexLogFormat.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une politique de rotation des journaux
class LogRotationPolicy {
    # Taille maximale d'un fichier de journal (en octets)
    [long]$MaxFileSize
    
    # Nombre maximal de fichiers de journal à conserver
    [int]$MaxFiles
    
    # Intervalle de rotation (en jours)
    [int]$RotationInterval
    
    # Constructeur par défaut
    LogRotationPolicy() {
        $this.MaxFileSize = 10MB     # 10 Mo
        $this.MaxFiles = 10          # 10 fichiers
        $this.RotationInterval = 1   # 1 jour
    }
    
    # Constructeur avec paramètres
    LogRotationPolicy([long]$maxFileSize, [int]$maxFiles, [int]$rotationInterval) {
        $this.MaxFileSize = $maxFileSize
        $this.MaxFiles = $maxFiles
        $this.RotationInterval = $rotationInterval
    }
    
    # Méthode pour vérifier si un fichier doit être roté
    [bool] ShouldRotate([string]$filePath) {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $filePath -PathType Leaf)) {
            return $false
        }
        
        # Obtenir les informations sur le fichier
        $fileInfo = Get-Item -Path $filePath
        
        # Vérifier si le fichier dépasse la taille maximale
        if ($fileInfo.Length -ge $this.MaxFileSize) {
            return $true
        }
        
        # Vérifier si le fichier est plus ancien que l'intervalle de rotation
        $cutoffDate = (Get-Date).AddDays(-$this.RotationInterval)
        if ($fileInfo.LastWriteTime -lt $cutoffDate) {
            return $true
        }
        
        return $false
    }
}

# Classe pour représenter un gestionnaire de rotation des journaux
class LogRotationManager {
    # Politique de rotation
    [LogRotationPolicy]$Policy
    
    # Répertoire des journaux
    [string]$LogDirectory
    
    # Format des fichiers de journal
    [string]$LogFileFormat
    
    # Constructeur par défaut
    LogRotationManager() {
        $this.Policy = [LogRotationPolicy]::new()
        $this.LogDirectory = Join-Path -Path $env:TEMP -ChildPath "IndexLogs"
        $this.LogFileFormat = "index_log_{0}.log"
    }
    
    # Constructeur avec politique
    LogRotationManager([LogRotationPolicy]$policy) {
        $this.Policy = $policy
        $this.LogDirectory = Join-Path -Path $env:TEMP -ChildPath "IndexLogs"
        $this.LogFileFormat = "index_log_{0}.log"
    }
    
    # Constructeur complet
    LogRotationManager([LogRotationPolicy]$policy, [string]$logDirectory, [string]$logFileFormat) {
        $this.Policy = $policy
        $this.LogDirectory = $logDirectory
        $this.LogFileFormat = $logFileFormat
        
        # Créer le répertoire des journaux s'il n'existe pas
        if (-not (Test-Path -Path $this.LogDirectory -PathType Container)) {
            New-Item -Path $this.LogDirectory -ItemType Directory -Force | Out-Null
        }
    }
    
    # Méthode pour obtenir le chemin du fichier de journal actif
    [string] GetActiveLogFilePath() {
        return Join-Path -Path $this.LogDirectory -ChildPath ($this.LogFileFormat -f "current")
    }
    
    # Méthode pour obtenir le chemin d'un fichier de journal archivé
    [string] GetArchivedLogFilePath([DateTime]$timestamp) {
        $dateStr = $timestamp.ToString("yyyyMMdd_HHmmss")
        return Join-Path -Path $this.LogDirectory -ChildPath ($this.LogFileFormat -f $dateStr)
    }
    
    # Méthode pour vérifier si une rotation est nécessaire
    [bool] CheckRotation() {
        $activeLogFilePath = $this.GetActiveLogFilePath()
        return $this.Policy.ShouldRotate($activeLogFilePath)
    }
    
    # Méthode pour effectuer une rotation
    [bool] RotateLog() {
        $activeLogFilePath = $this.GetActiveLogFilePath()
        
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $activeLogFilePath -PathType Leaf)) {
            return $false
        }
        
        try {
            # Créer un nouveau nom de fichier pour le journal archivé
            $archivedLogFilePath = $this.GetArchivedLogFilePath((Get-Date))
            
            # Déplacer le fichier actif vers le fichier archivé
            Move-Item -Path $activeLogFilePath -Destination $archivedLogFilePath -Force
            
            # Nettoyer les anciens fichiers de journal
            $this.CleanupOldLogs()
            
            return $true
        } catch {
            Write-Error "Erreur lors de la rotation du journal: $_"
            return $false
        }
    }
    
    # Méthode pour nettoyer les anciens fichiers de journal
    [int] CleanupOldLogs() {
        # Obtenir tous les fichiers de journal archivés
        $logFiles = Get-ChildItem -Path $this.LogDirectory -Filter ($this.LogFileFormat -f "*") |
            Where-Object { $_.Name -ne ($this.LogFileFormat -f "current") } |
            Sort-Object -Property LastWriteTime -Descending
        
        # Vérifier si le nombre de fichiers dépasse le maximum
        if ($logFiles.Count -le $this.Policy.MaxFiles) {
            return 0
        }
        
        # Supprimer les fichiers excédentaires
        $filesToDelete = $logFiles | Select-Object -Skip $this.Policy.MaxFiles
        
        foreach ($file in $filesToDelete) {
            Remove-Item -Path $file.FullName -Force
        }
        
        return $filesToDelete.Count
    }
    
    # Méthode pour écrire une entrée de journal
    [void] WriteLogEntry([IndexLogEntry]$entry, [string]$format = "Text") {
        $activeLogFilePath = $this.GetActiveLogFilePath()
        
        # Vérifier si une rotation est nécessaire
        if ($this.CheckRotation()) {
            $this.RotateLog()
        }
        
        # Formater l'entrée
        $formatter = [IndexLogFormatter]::new($format)
        $formattedEntry = $formatter.FormatEntry($entry)
        
        # Écrire l'entrée dans le fichier
        Add-Content -Path $activeLogFilePath -Value $formattedEntry -Encoding UTF8
    }
    
    # Méthode pour écrire un journal complet
    [void] WriteLog([IndexLog]$log, [string]$format = "Text") {
        $activeLogFilePath = $this.GetActiveLogFilePath()
        
        # Vérifier si une rotation est nécessaire
        if ($this.CheckRotation()) {
            $this.RotateLog()
        }
        
        # Formater le journal
        $formatter = [IndexLogFormatter]::new($format)
        $formattedLog = $formatter.FormatLog($log)
        
        # Écrire le journal dans le fichier
        Add-Content -Path $activeLogFilePath -Value $formattedLog -Encoding UTF8
    }
    
    # Méthode pour lire un fichier de journal
    [IndexLog] ReadLogFile([string]$filePath, [string]$format = "Text") {
        # Vérifier si le fichier existe
        if (-not (Test-Path -Path $filePath -PathType Leaf)) {
            Write-Error "Le fichier de journal $filePath n'existe pas."
            return [IndexLog]::new()
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $filePath -Raw
        
        # Créer un nouveau journal
        $log = [IndexLog]::new()
        
        # Analyser le contenu selon le format
        switch ($format) {
            "JSON" {
                $log = [IndexLog]::FromJson($content)
            }
            "CSV" {
                $lines = $content -split "`n"
                $header = $lines[0]
                $dataLines = $lines | Select-Object -Skip 1
                
                foreach ($line in $dataLines) {
                    $fields = $line -split ","
                    
                    if ($fields.Count -ge 6) {
                        $id = $fields[0]
                        $timestamp = [DateTime]::Parse($fields[1])
                        $level = $fields[2]
                        $category = $fields[3]
                        $message = $fields[4]
                        $dataJson = $fields[5]
                        
                        $data = @{}
                        if (-not [string]::IsNullOrEmpty($dataJson)) {
                            $dataObj = ConvertFrom-Json -InputObject $dataJson
                            foreach ($prop in $dataObj.PSObject.Properties) {
                                $data[$prop.Name] = $prop.Value
                            }
                        }
                        
                        $entry = [IndexLogEntry]::new($level, $category, $message, $data)
                        $entry.Id = $id
                        $entry.Timestamp = $timestamp
                        
                        $log.AddEntry($entry)
                    }
                }
            }
            "Text" {
                $lines = $content -split "`n"
                
                foreach ($line in $lines) {
                    if (-not [string]::IsNullOrEmpty($line)) {
                        # Analyser la ligne de texte
                        if ($line -match '^\[(.*?)\] \[(.*?)\] \[(.*?)\] (.*)$') {
                            $timestamp = [DateTime]::Parse($matches[1])
                            $level = $matches[2]
                            $category = $matches[3]
                            $message = $matches[4]
                            
                            $entry = [IndexLogEntry]::new($level, $category, $message)
                            $entry.Timestamp = $timestamp
                            
                            $log.AddEntry($entry)
                        }
                    }
                }
            }
        }
        
        return $log
    }
    
    # Méthode pour lire le journal actif
    [IndexLog] ReadActiveLog([string]$format = "Text") {
        $activeLogFilePath = $this.GetActiveLogFilePath()
        return $this.ReadLogFile($activeLogFilePath, $format)
    }
    
    # Méthode pour obtenir la liste des fichiers de journal
    [string[]] GetLogFiles() {
        $logFiles = Get-ChildItem -Path $this.LogDirectory -Filter ($this.LogFileFormat -f "*") |
            Sort-Object -Property LastWriteTime -Descending |
            Select-Object -ExpandProperty FullName
        
        return $logFiles
    }
}

# Fonction pour créer une politique de rotation des journaux
function New-LogRotationPolicy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [long]$MaxFileSize = 10MB,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxFiles = 10,
        
        [Parameter(Mandatory = $false)]
        [int]$RotationInterval = 1
    )
    
    return [LogRotationPolicy]::new($MaxFileSize, $MaxFiles, $RotationInterval)
}

# Fonction pour créer un gestionnaire de rotation des journaux
function New-LogRotationManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [LogRotationPolicy]$Policy = (New-LogRotationPolicy),
        
        [Parameter(Mandatory = $false)]
        [string]$LogDirectory = (Join-Path -Path $env:TEMP -ChildPath "IndexLogs"),
        
        [Parameter(Mandatory = $false)]
        [string]$LogFileFormat = "index_log_{0}.log"
    )
    
    return [LogRotationManager]::new($Policy, $LogDirectory, $LogFileFormat)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-LogRotationPolicy, New-LogRotationManager
