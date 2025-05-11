# FileDetection.ps1
# Script implémentant la détection de nouveaux fichiers pour l'indexation incrémentale
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$signatureComparisonPath = Join-Path -Path $scriptPath -ChildPath "SignatureComparison.ps1"

if (Test-Path -Path $signatureComparisonPath) {
    . $signatureComparisonPath
} else {
    Write-Error "Le fichier SignatureComparison.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une signature de fichier
class FileSignature {
    # Chemin du fichier
    [string]$FilePath
    
    # Horodatage de dernière modification
    [DateTime]$LastModified
    
    # Taille du fichier en octets
    [long]$Size
    
    # Empreinte MD5 du fichier
    [string]$MD5Hash
    
    # Constructeur par défaut
    FileSignature() {
        $this.FilePath = ""
        $this.LastModified = [DateTime]::MinValue
        $this.Size = 0
        $this.MD5Hash = ""
    }
    
    # Constructeur avec chemin de fichier
    FileSignature([string]$filePath) {
        $this.FilePath = $filePath
        
        if (Test-Path -Path $filePath -PathType Leaf) {
            $fileInfo = Get-Item -Path $filePath
            $this.LastModified = $fileInfo.LastWriteTime
            $this.Size = $fileInfo.Length
            $this.MD5Hash = ""
        } else {
            $this.LastModified = [DateTime]::MinValue
            $this.Size = 0
            $this.MD5Hash = ""
        }
    }
    
    # Méthode pour calculer l'empreinte MD5
    [void] CalculateMD5Hash() {
        if (-not (Test-Path -Path $this.FilePath -PathType Leaf)) {
            $this.MD5Hash = ""
            return
        }
        
        try {
            $md5 = [System.Security.Cryptography.MD5]::Create()
            $stream = [System.IO.File]::OpenRead($this.FilePath)
            $hashBytes = $md5.ComputeHash($stream)
            $stream.Close()
            
            $this.MD5Hash = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
        } catch {
            Write-Error "Erreur lors du calcul de l'empreinte MD5 pour $($this.FilePath): $_"
            $this.MD5Hash = ""
        }
    }
    
    # Méthode pour mettre à jour les informations du fichier
    [void] Update() {
        if (Test-Path -Path $this.FilePath -PathType Leaf) {
            $fileInfo = Get-Item -Path $this.FilePath
            $this.LastModified = $fileInfo.LastWriteTime
            $this.Size = $fileInfo.Length
        } else {
            $this.LastModified = [DateTime]::MinValue
            $this.Size = 0
            $this.MD5Hash = ""
        }
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            file_path = $this.FilePath
            last_modified = $this.LastModified.ToString("o")
            size = $this.Size
            md5_hash = $this.MD5Hash
        }
    }
    
    # Méthode pour créer à partir d'une hashtable
    static [FileSignature] FromHashtable([hashtable]$data) {
        $signature = [FileSignature]::new()
        
        if ($data.ContainsKey("file_path")) {
            $signature.FilePath = $data.file_path
        }
        
        if ($data.ContainsKey("last_modified")) {
            $signature.LastModified = [DateTime]::Parse($data.last_modified)
        }
        
        if ($data.ContainsKey("size")) {
            $signature.Size = $data.size
        }
        
        if ($data.ContainsKey("md5_hash")) {
            $signature.MD5Hash = $data.md5_hash
        }
        
        return $signature
    }
}

# Classe pour représenter un détecteur de fichiers
class FileDetector {
    # Répertoire racine à surveiller
    [string]$RootDirectory
    
    # Filtres d'inclusion
    [string[]]$IncludeFilters
    
    # Filtres d'exclusion
    [string[]]$ExcludeFilters
    
    # Dictionnaire des signatures de fichiers
    [System.Collections.Generic.Dictionary[string, FileSignature]]$FileSignatures
    
    # Gestionnaire de suivi des modifications
    [ChangeTrackingManager]$ChangeTracker
    
    # Chemin du fichier de signatures
    [string]$SignaturesFilePath
    
    # Constructeur par défaut
    FileDetector() {
        $this.RootDirectory = ""
        $this.IncludeFilters = @("*")
        $this.ExcludeFilters = @()
        $this.FileSignatures = [System.Collections.Generic.Dictionary[string, FileSignature]]::new()
        $this.ChangeTracker = $null
        $this.SignaturesFilePath = Join-Path -Path $env:TEMP -ChildPath "file_signatures.json"
    }
    
    # Constructeur avec répertoire racine
    FileDetector([string]$rootDirectory) {
        $this.RootDirectory = $rootDirectory
        $this.IncludeFilters = @("*")
        $this.ExcludeFilters = @()
        $this.FileSignatures = [System.Collections.Generic.Dictionary[string, FileSignature]]::new()
        $this.ChangeTracker = $null
        $this.SignaturesFilePath = Join-Path -Path $env:TEMP -ChildPath "file_signatures.json"
    }
    
    # Constructeur complet
    FileDetector([string]$rootDirectory, [string[]]$includeFilters, [string[]]$excludeFilters, [string]$signaturesFilePath, [ChangeTrackingManager]$changeTracker) {
        $this.RootDirectory = $rootDirectory
        $this.IncludeFilters = $includeFilters
        $this.ExcludeFilters = $excludeFilters
        $this.FileSignatures = [System.Collections.Generic.Dictionary[string, FileSignature]]::new()
        $this.ChangeTracker = $changeTracker
        $this.SignaturesFilePath = $signaturesFilePath
        
        # Charger les signatures existantes s'il existe
        $this.LoadSignatures()
    }
    
    # Méthode pour charger les signatures
    [bool] LoadSignatures() {
        if (-not (Test-Path -Path $this.SignaturesFilePath)) {
            return $false
        }
        
        try {
            $json = Get-Content -Path $this.SignaturesFilePath -Raw
            $data = ConvertFrom-Json -InputObject $json -AsHashtable
            
            foreach ($filePath in $data.Keys) {
                $signatureData = $data[$filePath]
                $signature = [FileSignature]::FromHashtable($signatureData)
                $this.FileSignatures[$filePath] = $signature
            }
            
            return $true
        } catch {
            Write-Error "Erreur lors du chargement des signatures de fichiers: $_"
            return $false
        }
    }
    
    # Méthode pour sauvegarder les signatures
    [bool] SaveSignatures() {
        try {
            $data = @{}
            
            foreach ($filePath in $this.FileSignatures.Keys) {
                $signature = $this.FileSignatures[$filePath]
                $data[$filePath] = $signature.ToHashtable()
            }
            
            $json = ConvertTo-Json -InputObject $data -Depth 10
            $json | Out-File -FilePath $this.SignaturesFilePath -Encoding UTF8
            
            return $true
        } catch {
            Write-Error "Erreur lors de la sauvegarde des signatures de fichiers: $_"
            return $false
        }
    }
    
    # Méthode pour scanner les fichiers
    [hashtable] ScanFiles() {
        $result = @{
            new_files = [System.Collections.Generic.List[string]]::new()
            modified_files = [System.Collections.Generic.List[string]]::new()
            deleted_files = [System.Collections.Generic.List[string]]::new()
            unchanged_files = [System.Collections.Generic.List[string]]::new()
            total_files = 0
        }
        
        # Vérifier si le répertoire racine existe
        if (-not (Test-Path -Path $this.RootDirectory -PathType Container)) {
            Write-Error "Le répertoire racine $($this.RootDirectory) n'existe pas."
            return $result
        }
        
        # Obtenir la liste des fichiers actuels
        $currentFiles = @()
        
        foreach ($includeFilter in $this.IncludeFilters) {
            $files = Get-ChildItem -Path $this.RootDirectory -Filter $includeFilter -File -Recurse
            $currentFiles += $files
        }
        
        # Appliquer les filtres d'exclusion
        foreach ($excludeFilter in $this.ExcludeFilters) {
            $currentFiles = $currentFiles | Where-Object { $_.FullName -notlike $excludeFilter }
        }
        
        $result.total_files = $currentFiles.Count
        
        # Créer une copie des clés pour éviter les erreurs de modification pendant l'itération
        $knownFilePaths = $this.FileSignatures.Keys.Clone()
        
        # Marquer tous les fichiers connus comme potentiellement supprimés
        $potentiallyDeletedFiles = [System.Collections.Generic.HashSet[string]]::new($knownFilePaths)
        
        # Vérifier chaque fichier actuel
        foreach ($file in $currentFiles) {
            $filePath = $file.FullName
            
            # Retirer le fichier de la liste des fichiers potentiellement supprimés
            $potentiallyDeletedFiles.Remove($filePath)
            
            # Vérifier si le fichier est connu
            if ($this.FileSignatures.ContainsKey($filePath)) {
                # Récupérer la signature existante
                $signature = $this.FileSignatures[$filePath]
                
                # Vérifier si le fichier a été modifié
                if ($file.LastWriteTime -gt $signature.LastModified -or $file.Length -ne $signature.Size) {
                    # Mettre à jour la signature
                    $signature.Update()
                    
                    # Calculer l'empreinte MD5 si nécessaire
                    if ([string]::IsNullOrEmpty($signature.MD5Hash) -or $file.LastWriteTime -gt $signature.LastModified -or $file.Length -ne $signature.Size) {
                        $signature.CalculateMD5Hash()
                    }
                    
                    # Ajouter le fichier à la liste des fichiers modifiés
                    $result.modified_files.Add($filePath)
                    
                    # Enregistrer la modification si un gestionnaire de suivi est disponible
                    if ($null -ne $this.ChangeTracker) {
                        $this.ChangeTracker.TrackUpdate($filePath, "system", "file_detector")
                    }
                } else {
                    # Ajouter le fichier à la liste des fichiers inchangés
                    $result.unchanged_files.Add($filePath)
                }
            } else {
                # Créer une nouvelle signature
                $signature = [FileSignature]::new($filePath)
                $signature.CalculateMD5Hash()
                
                # Ajouter la signature au dictionnaire
                $this.FileSignatures[$filePath] = $signature
                
                # Ajouter le fichier à la liste des nouveaux fichiers
                $result.new_files.Add($filePath)
                
                # Enregistrer l'ajout si un gestionnaire de suivi est disponible
                if ($null -ne $this.ChangeTracker) {
                    $this.ChangeTracker.TrackAdd($filePath, "system", "file_detector")
                }
            }
        }
        
        # Traiter les fichiers supprimés
        foreach ($filePath in $potentiallyDeletedFiles) {
            # Supprimer la signature
            $this.FileSignatures.Remove($filePath)
            
            # Ajouter le fichier à la liste des fichiers supprimés
            $result.deleted_files.Add($filePath)
            
            # Enregistrer la suppression si un gestionnaire de suivi est disponible
            if ($null -ne $this.ChangeTracker) {
                $this.ChangeTracker.TrackDelete($filePath, "system", "file_detector")
            }
        }
        
        # Sauvegarder les signatures
        $this.SaveSignatures()
        
        return $result
    }
    
    # Méthode pour obtenir les statistiques du détecteur de fichiers
    [hashtable] GetStats() {
        return @{
            root_directory = $this.RootDirectory
            include_filters = $this.IncludeFilters
            exclude_filters = $this.ExcludeFilters
            known_files = $this.FileSignatures.Count
            signatures_file = $this.SignaturesFilePath
        }
    }
}

# Fonction pour créer un détecteur de fichiers
function New-FileDetector {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$RootDirectory,
        
        [Parameter(Mandatory = $false)]
        [string[]]$IncludeFilters = @("*"),
        
        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeFilters = @(),
        
        [Parameter(Mandatory = $false)]
        [string]$SignaturesFilePath = (Join-Path -Path $env:TEMP -ChildPath "file_signatures.json"),
        
        [Parameter(Mandatory = $false)]
        [ChangeTrackingManager]$ChangeTracker = $null
    )
    
    return [FileDetector]::new($RootDirectory, $IncludeFilters, $ExcludeFilters, $SignaturesFilePath, $ChangeTracker)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-FileDetector
