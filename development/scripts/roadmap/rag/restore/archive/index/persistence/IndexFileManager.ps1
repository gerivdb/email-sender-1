# IndexFileManager.ps1
# Script implémentant la gestion des fichiers d'index
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$serializationPath = Join-Path -Path $scriptPath -ChildPath "IndexSerialization.ps1"

if (Test-Path -Path $serializationPath) {
    . $serializationPath
} else {
    Write-Error "Le fichier IndexSerialization.ps1 est introuvable."
    exit 1
}

# Classe pour gérer les fichiers d'index
class IndexFileManager {
    # Répertoire racine pour les fichiers d'index
    [string]$RootDirectory
    
    # Sérialiseur utilisé pour les opérations de sérialisation/désérialisation
    [IndexSerializer]$Serializer
    
    # Verrous de fichiers actifs
    [System.Collections.Generic.Dictionary[string, object]]$FileLocks
    
    # Constructeur par défaut
    IndexFileManager() {
        $this.RootDirectory = Join-Path -Path $env:TEMP -ChildPath "IndexFiles"
        $this.Serializer = [IndexSerializer]::new()
        $this.FileLocks = [System.Collections.Generic.Dictionary[string, object]]::new()
        
        # Créer le répertoire racine s'il n'existe pas
        if (-not (Test-Path -Path $this.RootDirectory)) {
            New-Item -Path $this.RootDirectory -ItemType Directory -Force | Out-Null
        }
    }
    
    # Constructeur avec répertoire racine
    IndexFileManager([string]$rootDirectory) {
        $this.RootDirectory = $rootDirectory
        $this.Serializer = [IndexSerializer]::new()
        $this.FileLocks = [System.Collections.Generic.Dictionary[string, object]]::new()
        
        # Créer le répertoire racine s'il n'existe pas
        if (-not (Test-Path -Path $this.RootDirectory)) {
            New-Item -Path $this.RootDirectory -ItemType Directory -Force | Out-Null
        }
    }
    
    # Constructeur complet
    IndexFileManager([string]$rootDirectory, [IndexSerializer]$serializer) {
        $this.RootDirectory = $rootDirectory
        $this.Serializer = $serializer
        $this.FileLocks = [System.Collections.Generic.Dictionary[string, object]]::new()
        
        # Créer le répertoire racine s'il n'existe pas
        if (-not (Test-Path -Path $this.RootDirectory)) {
            New-Item -Path $this.RootDirectory -ItemType Directory -Force | Out-Null
        }
    }
    
    # Méthode pour obtenir le chemin d'un fichier de document
    [string] GetDocumentFilePath([string]$documentId) {
        $documentsDir = Join-Path -Path $this.RootDirectory -ChildPath "documents"
        
        if (-not (Test-Path -Path $documentsDir)) {
            New-Item -Path $documentsDir -ItemType Directory -Force | Out-Null
        }
        
        # Créer une structure de répertoires basée sur les premiers caractères de l'ID
        # pour éviter d'avoir trop de fichiers dans un seul répertoire
        $prefix = $documentId.Substring(0, [Math]::Min(2, $documentId.Length))
        $subDir = Join-Path -Path $documentsDir -ChildPath $prefix
        
        if (-not (Test-Path -Path $subDir)) {
            New-Item -Path $subDir -ItemType Directory -Force | Out-Null
        }
        
        return Join-Path -Path $subDir -ChildPath "$documentId.idx"
    }
    
    # Méthode pour obtenir le chemin d'un fichier de segment
    [string] GetSegmentFilePath([string]$segmentId) {
        $segmentsDir = Join-Path -Path $this.RootDirectory -ChildPath "segments"
        
        if (-not (Test-Path -Path $segmentsDir)) {
            New-Item -Path $segmentsDir -ItemType Directory -Force | Out-Null
        }
        
        return Join-Path -Path $segmentsDir -ChildPath "$segmentId.seg"
    }
    
    # Méthode pour obtenir le chemin du fichier de métadonnées de l'index
    [string] GetIndexMetadataFilePath() {
        return Join-Path -Path $this.RootDirectory -ChildPath "index.meta"
    }
    
    # Méthode pour sauvegarder un document
    [bool] SaveDocument([IndexDocument]$document) {
        $filePath = $this.GetDocumentFilePath($document.Id)
        
        try {
            # Acquérir un verrou pour le fichier
            $lockObj = $this.AcquireFileLock($filePath)
            
            # Sérialiser le document
            $data = $this.Serializer.SerializeDocument($document)
            
            # Sauvegarder les données dans le fichier
            [System.IO.File]::WriteAllBytes($filePath, $data)
            
            # Libérer le verrou
            $this.ReleaseFileLock($filePath)
            
            return $true
        } catch {
            Write-Error "Erreur lors de la sauvegarde du document $($document.Id): $_"
            
            # Libérer le verrou en cas d'erreur
            $this.ReleaseFileLock($filePath)
            
            return $false
        }
    }
    
    # Méthode pour charger un document
    [IndexDocument] LoadDocument([string]$documentId) {
        $filePath = $this.GetDocumentFilePath($documentId)
        
        if (-not (Test-Path -Path $filePath)) {
            Write-Error "Le document $documentId n'existe pas."
            return $null
        }
        
        try {
            # Acquérir un verrou pour le fichier
            $lockObj = $this.AcquireFileLock($filePath)
            
            # Charger les données du fichier
            $data = [System.IO.File]::ReadAllBytes($filePath)
            
            # Désérialiser le document
            $document = $this.Serializer.DeserializeDocument($data)
            
            # Libérer le verrou
            $this.ReleaseFileLock($filePath)
            
            return $document
        } catch {
            Write-Error "Erreur lors du chargement du document $documentId: $_"
            
            # Libérer le verrou en cas d'erreur
            $this.ReleaseFileLock($filePath)
            
            return $null
        }
    }
    
    # Méthode pour supprimer un document
    [bool] DeleteDocument([string]$documentId) {
        $filePath = $this.GetDocumentFilePath($documentId)
        
        if (-not (Test-Path -Path $filePath)) {
            # Le document n'existe pas, considérer comme supprimé
            return $true
        }
        
        try {
            # Acquérir un verrou pour le fichier
            $lockObj = $this.AcquireFileLock($filePath)
            
            # Supprimer le fichier
            Remove-Item -Path $filePath -Force
            
            # Libérer le verrou
            $this.ReleaseFileLock($filePath)
            
            return $true
        } catch {
            Write-Error "Erreur lors de la suppression du document $documentId: $_"
            
            # Libérer le verrou en cas d'erreur
            $this.ReleaseFileLock($filePath)
            
            return $false
        }
    }
    
    # Méthode pour sauvegarder un segment
    [bool] SaveSegment([IndexSegment]$segment) {
        $filePath = $this.GetSegmentFilePath($segment.Id)
        
        try {
            # Acquérir un verrou pour le fichier
            $lockObj = $this.AcquireFileLock($filePath)
            
            # Sérialiser le segment
            $data = $this.Serializer.SerializeSegment($segment)
            
            # Sauvegarder les données dans le fichier
            [System.IO.File]::WriteAllBytes($filePath, $data)
            
            # Libérer le verrou
            $this.ReleaseFileLock($filePath)
            
            return $true
        } catch {
            Write-Error "Erreur lors de la sauvegarde du segment $($segment.Id): $_"
            
            # Libérer le verrou en cas d'erreur
            $this.ReleaseFileLock($filePath)
            
            return $false
        }
    }
    
    # Méthode pour charger un segment
    [IndexSegment] LoadSegment([string]$segmentId) {
        $filePath = $this.GetSegmentFilePath($segmentId)
        
        if (-not (Test-Path -Path $filePath)) {
            Write-Error "Le segment $segmentId n'existe pas."
            return $null
        }
        
        try {
            # Acquérir un verrou pour le fichier
            $lockObj = $this.AcquireFileLock($filePath)
            
            # Charger les données du fichier
            $data = [System.IO.File]::ReadAllBytes($filePath)
            
            # Désérialiser le segment
            $segment = $this.Serializer.DeserializeSegment($data)
            
            # Libérer le verrou
            $this.ReleaseFileLock($filePath)
            
            return $segment
        } catch {
            Write-Error "Erreur lors du chargement du segment $segmentId: $_"
            
            # Libérer le verrou en cas d'erreur
            $this.ReleaseFileLock($filePath)
            
            return $null
        }
    }
    
    # Méthode pour supprimer un segment
    [bool] DeleteSegment([string]$segmentId) {
        $filePath = $this.GetSegmentFilePath($segmentId)
        
        if (-not (Test-Path -Path $filePath)) {
            # Le segment n'existe pas, considérer comme supprimé
            return $true
        }
        
        try {
            # Acquérir un verrou pour le fichier
            $lockObj = $this.AcquireFileLock($filePath)
            
            # Supprimer le fichier
            Remove-Item -Path $filePath -Force
            
            # Libérer le verrou
            $this.ReleaseFileLock($filePath)
            
            return $true
        } catch {
            Write-Error "Erreur lors de la suppression du segment $segmentId: $_"
            
            # Libérer le verrou en cas d'erreur
            $this.ReleaseFileLock($filePath)
            
            return $false
        }
    }
    
    # Méthode pour sauvegarder les métadonnées de l'index
    [bool] SaveIndexMetadata([hashtable]$metadata) {
        $filePath = $this.GetIndexMetadataFilePath()
        
        try {
            # Acquérir un verrou pour le fichier
            $lockObj = $this.AcquireFileLock($filePath)
            
            # Convertir les métadonnées en JSON
            $json = ConvertTo-Json -InputObject $metadata -Depth 10 -Compress
            
            # Convertir en bytes
            $data = [System.Text.Encoding]::UTF8.GetBytes($json)
            
            # Appliquer la compression et le chiffrement
            $data = $this.Serializer.CompressData($data)
            $data = $this.Serializer.EncryptData($data)
            
            # Sauvegarder les données dans le fichier
            [System.IO.File]::WriteAllBytes($filePath, $data)
            
            # Libérer le verrou
            $this.ReleaseFileLock($filePath)
            
            return $true
        } catch {
            Write-Error "Erreur lors de la sauvegarde des métadonnées de l'index: $_"
            
            # Libérer le verrou en cas d'erreur
            $this.ReleaseFileLock($filePath)
            
            return $false
        }
    }
    
    # Méthode pour charger les métadonnées de l'index
    [hashtable] LoadIndexMetadata() {
        $filePath = $this.GetIndexMetadataFilePath()
        
        if (-not (Test-Path -Path $filePath)) {
            # Retourner des métadonnées par défaut
            return @{
                created_at = (Get-Date).ToString("o")
                updated_at = (Get-Date).ToString("o")
                document_count = 0
                segment_count = 0
                version = "1.0"
            }
        }
        
        try {
            # Acquérir un verrou pour le fichier
            $lockObj = $this.AcquireFileLock($filePath)
            
            # Charger les données du fichier
            $data = [System.IO.File]::ReadAllBytes($filePath)
            
            # Déchiffrer et décompresser les données
            $data = $this.Serializer.DecryptData($data)
            $data = $this.Serializer.DecompressData($data)
            
            # Convertir en JSON
            $json = [System.Text.Encoding]::UTF8.GetString($data)
            
            # Convertir en hashtable
            $metadata = ConvertFrom-Json -InputObject $json -AsHashtable
            
            # Libérer le verrou
            $this.ReleaseFileLock($filePath)
            
            return $metadata
        } catch {
            Write-Error "Erreur lors du chargement des métadonnées de l'index: $_"
            
            # Libérer le verrou en cas d'erreur
            $this.ReleaseFileLock($filePath)
            
            # Retourner des métadonnées par défaut
            return @{
                created_at = (Get-Date).ToString("o")
                updated_at = (Get-Date).ToString("o")
                document_count = 0
                segment_count = 0
                version = "1.0"
                error = $_.ToString()
            }
        }
    }
    
    # Méthode pour obtenir la liste des segments
    [string[]] GetSegmentIds() {
        $segmentsDir = Join-Path -Path $this.RootDirectory -ChildPath "segments"
        
        if (-not (Test-Path -Path $segmentsDir)) {
            return @()
        }
        
        $segmentFiles = Get-ChildItem -Path $segmentsDir -Filter "*.seg"
        $segmentIds = $segmentFiles | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) }
        
        return $segmentIds
    }
    
    # Méthode pour obtenir la liste des documents
    [string[]] GetDocumentIds() {
        $documentsDir = Join-Path -Path $this.RootDirectory -ChildPath "documents"
        
        if (-not (Test-Path -Path $documentsDir)) {
            return @()
        }
        
        $documentFiles = Get-ChildItem -Path $documentsDir -Filter "*.idx" -Recurse
        $documentIds = $documentFiles | ForEach-Object { [System.IO.Path]::GetFileNameWithoutExtension($_.Name) }
        
        return $documentIds
    }
    
    # Méthode pour acquérir un verrou de fichier
    [object] AcquireFileLock([string]$filePath) {
        if (-not $this.FileLocks.ContainsKey($filePath)) {
            $this.FileLocks[$filePath] = New-Object object
        }
        
        $lockObj = $this.FileLocks[$filePath]
        
        # Acquérir le verrou
        [System.Threading.Monitor]::Enter($lockObj)
        
        return $lockObj
    }
    
    # Méthode pour libérer un verrou de fichier
    [void] ReleaseFileLock([string]$filePath) {
        if ($this.FileLocks.ContainsKey($filePath)) {
            $lockObj = $this.FileLocks[$filePath]
            
            # Libérer le verrou
            [System.Threading.Monitor]::Exit($lockObj)
        }
    }
}

# Fonction pour créer un gestionnaire de fichiers d'index
function New-IndexFileManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$RootDirectory = (Join-Path -Path $env:TEMP -ChildPath "IndexFiles"),
        
        [Parameter(Mandatory = $false)]
        [IndexSerializer]$Serializer = [IndexSerializer]::new()
    )
    
    return [IndexFileManager]::new($RootDirectory, $Serializer)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-IndexFileManager
