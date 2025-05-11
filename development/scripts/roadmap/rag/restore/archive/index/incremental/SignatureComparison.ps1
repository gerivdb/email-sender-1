# SignatureComparison.ps1
# Script implémentant la comparaison de signatures pour détecter les changements
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$changeTrackingPath = Join-Path -Path $scriptPath -ChildPath "ChangeTracking.ps1"

if (Test-Path -Path $changeTrackingPath) {
    . $changeTrackingPath
} else {
    Write-Error "Le fichier ChangeTracking.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une signature de document
class DocumentSignature {
    # ID du document
    [string]$DocumentId
    
    # Horodatage de création de la signature
    [DateTime]$Timestamp
    
    # Empreinte MD5 du document
    [string]$MD5Hash
    
    # Empreinte SHA256 du document
    [string]$SHA256Hash
    
    # Taille du document en octets
    [long]$Size
    
    # Nombre de champs
    [int]$FieldCount
    
    # Somme de contrôle des noms de champs
    [string]$FieldNamesChecksum
    
    # Somme de contrôle des valeurs de champs
    [string]$FieldValuesChecksum
    
    # Constructeur par défaut
    DocumentSignature() {
        $this.DocumentId = ""
        $this.Timestamp = Get-Date
        $this.MD5Hash = ""
        $this.SHA256Hash = ""
        $this.Size = 0
        $this.FieldCount = 0
        $this.FieldNamesChecksum = ""
        $this.FieldValuesChecksum = ""
    }
    
    # Constructeur avec ID de document
    DocumentSignature([string]$documentId) {
        $this.DocumentId = $documentId
        $this.Timestamp = Get-Date
        $this.MD5Hash = ""
        $this.SHA256Hash = ""
        $this.Size = 0
        $this.FieldCount = 0
        $this.FieldNamesChecksum = ""
        $this.FieldValuesChecksum = ""
    }
    
    # Méthode pour convertir en hashtable
    [hashtable] ToHashtable() {
        return @{
            document_id = $this.DocumentId
            timestamp = $this.Timestamp.ToString("o")
            md5_hash = $this.MD5Hash
            sha256_hash = $this.SHA256Hash
            size = $this.Size
            field_count = $this.FieldCount
            field_names_checksum = $this.FieldNamesChecksum
            field_values_checksum = $this.FieldValuesChecksum
        }
    }
    
    # Méthode pour créer à partir d'une hashtable
    static [DocumentSignature] FromHashtable([hashtable]$data) {
        $signature = [DocumentSignature]::new()
        
        if ($data.ContainsKey("document_id")) {
            $signature.DocumentId = $data.document_id
        }
        
        if ($data.ContainsKey("timestamp")) {
            $signature.Timestamp = [DateTime]::Parse($data.timestamp)
        }
        
        if ($data.ContainsKey("md5_hash")) {
            $signature.MD5Hash = $data.md5_hash
        }
        
        if ($data.ContainsKey("sha256_hash")) {
            $signature.SHA256Hash = $data.sha256_hash
        }
        
        if ($data.ContainsKey("size")) {
            $signature.Size = $data.size
        }
        
        if ($data.ContainsKey("field_count")) {
            $signature.FieldCount = $data.field_count
        }
        
        if ($data.ContainsKey("field_names_checksum")) {
            $signature.FieldNamesChecksum = $data.field_names_checksum
        }
        
        if ($data.ContainsKey("field_values_checksum")) {
            $signature.FieldValuesChecksum = $data.field_values_checksum
        }
        
        return $signature
    }
}

# Classe pour représenter un générateur de signatures
class SignatureGenerator {
    # Constructeur par défaut
    SignatureGenerator() {
    }
    
    # Méthode pour générer une signature à partir d'un document
    [DocumentSignature] GenerateSignature([IndexDocument]$document) {
        $signature = [DocumentSignature]::new($document.Id)
        
        # Convertir le document en JSON pour calculer les empreintes
        $json = $document.ToJson()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        
        # Calculer l'empreinte MD5
        $md5 = [System.Security.Cryptography.MD5]::Create()
        $md5Bytes = $md5.ComputeHash($bytes)
        $signature.MD5Hash = [BitConverter]::ToString($md5Bytes).Replace("-", "").ToLower()
        
        # Calculer l'empreinte SHA256
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $sha256Bytes = $sha256.ComputeHash($bytes)
        $signature.SHA256Hash = [BitConverter]::ToString($sha256Bytes).Replace("-", "").ToLower()
        
        # Calculer la taille
        $signature.Size = $bytes.Length
        
        # Calculer le nombre de champs
        $signature.FieldCount = $document.Content.Count
        
        # Calculer la somme de contrôle des noms de champs
        $fieldNames = $document.Content.Keys | Sort-Object
        $fieldNamesString = $fieldNames -join "|"
        $fieldNamesBytes = [System.Text.Encoding]::UTF8.GetBytes($fieldNamesString)
        $fieldNamesMD5 = [System.Security.Cryptography.MD5]::Create()
        $fieldNamesMD5Bytes = $fieldNamesMD5.ComputeHash($fieldNamesBytes)
        $signature.FieldNamesChecksum = [BitConverter]::ToString($fieldNamesMD5Bytes).Replace("-", "").ToLower()
        
        # Calculer la somme de contrôle des valeurs de champs
        $fieldValues = foreach ($key in $fieldNames) {
            $value = $document.Content[$key]
            if ($null -ne $value) {
                $value.ToString()
            } else {
                "null"
            }
        }
        $fieldValuesString = $fieldValues -join "|"
        $fieldValuesBytes = [System.Text.Encoding]::UTF8.GetBytes($fieldValuesString)
        $fieldValuesMD5 = [System.Security.Cryptography.MD5]::Create()
        $fieldValuesMD5Bytes = $fieldValuesMD5.ComputeHash($fieldValuesBytes)
        $signature.FieldValuesChecksum = [BitConverter]::ToString($fieldValuesMD5Bytes).Replace("-", "").ToLower()
        
        return $signature
    }
}

# Classe pour représenter un comparateur de signatures
class SignatureComparator {
    # Constructeur par défaut
    SignatureComparator() {
    }
    
    # Méthode pour comparer deux signatures
    [hashtable] CompareSignatures([DocumentSignature]$signature1, [DocumentSignature]$signature2) {
        $result = @{
            is_identical = $false
            differences = [System.Collections.Generic.List[string]]::new()
            similarity_score = 0.0
        }
        
        # Vérifier si les documents ont le même ID
        if ($signature1.DocumentId -ne $signature2.DocumentId) {
            $result.differences.Add("DocumentId")
            return $result
        }
        
        # Comparer les empreintes MD5
        if ($signature1.MD5Hash -ne $signature2.MD5Hash) {
            $result.differences.Add("MD5Hash")
        }
        
        # Comparer les empreintes SHA256
        if ($signature1.SHA256Hash -ne $signature2.SHA256Hash) {
            $result.differences.Add("SHA256Hash")
        }
        
        # Comparer les tailles
        if ($signature1.Size -ne $signature2.Size) {
            $result.differences.Add("Size")
        }
        
        # Comparer le nombre de champs
        if ($signature1.FieldCount -ne $signature2.FieldCount) {
            $result.differences.Add("FieldCount")
        }
        
        # Comparer la somme de contrôle des noms de champs
        if ($signature1.FieldNamesChecksum -ne $signature2.FieldNamesChecksum) {
            $result.differences.Add("FieldNames")
        }
        
        # Comparer la somme de contrôle des valeurs de champs
        if ($signature1.FieldValuesChecksum -ne $signature2.FieldValuesChecksum) {
            $result.differences.Add("FieldValues")
        }
        
        # Calculer le score de similarité
        $totalChecks = 6  # MD5, SHA256, Size, FieldCount, FieldNames, FieldValues
        $matchingChecks = $totalChecks - $result.differences.Count
        $result.similarity_score = $matchingChecks / $totalChecks
        
        # Déterminer si les signatures sont identiques
        $result.is_identical = $result.differences.Count -eq 0
        
        return $result
    }
}

# Classe pour représenter un gestionnaire de signatures
class SignatureManager {
    # Dictionnaire des signatures
    [System.Collections.Generic.Dictionary[string, DocumentSignature]]$Signatures
    
    # Générateur de signatures
    [SignatureGenerator]$Generator
    
    # Comparateur de signatures
    [SignatureComparator]$Comparator
    
    # Gestionnaire de suivi des modifications
    [ChangeTrackingManager]$ChangeTracker
    
    # Chemin du fichier de signatures
    [string]$SignaturesFilePath
    
    # Constructeur par défaut
    SignatureManager() {
        $this.Signatures = [System.Collections.Generic.Dictionary[string, DocumentSignature]]::new()
        $this.Generator = [SignatureGenerator]::new()
        $this.Comparator = [SignatureComparator]::new()
        $this.ChangeTracker = $null
        $this.SignaturesFilePath = Join-Path -Path $env:TEMP -ChildPath "document_signatures.json"
    }
    
    # Constructeur avec chemin de fichier
    SignatureManager([string]$signaturesFilePath) {
        $this.Signatures = [System.Collections.Generic.Dictionary[string, DocumentSignature]]::new()
        $this.Generator = [SignatureGenerator]::new()
        $this.Comparator = [SignatureComparator]::new()
        $this.ChangeTracker = $null
        $this.SignaturesFilePath = $signaturesFilePath
        
        # Charger les signatures existantes s'il existe
        $this.LoadSignatures()
    }
    
    # Constructeur complet
    SignatureManager([string]$signaturesFilePath, [ChangeTrackingManager]$changeTracker) {
        $this.Signatures = [System.Collections.Generic.Dictionary[string, DocumentSignature]]::new()
        $this.Generator = [SignatureGenerator]::new()
        $this.Comparator = [SignatureComparator]::new()
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
            
            foreach ($documentId in $data.Keys) {
                $signatureData = $data[$documentId]
                $signature = [DocumentSignature]::FromHashtable($signatureData)
                $this.Signatures[$documentId] = $signature
            }
            
            return $true
        } catch {
            Write-Error "Erreur lors du chargement des signatures: $_"
            return $false
        }
    }
    
    # Méthode pour sauvegarder les signatures
    [bool] SaveSignatures() {
        try {
            $data = @{}
            
            foreach ($documentId in $this.Signatures.Keys) {
                $signature = $this.Signatures[$documentId]
                $data[$documentId] = $signature.ToHashtable()
            }
            
            $json = ConvertTo-Json -InputObject $data -Depth 10
            $json | Out-File -FilePath $this.SignaturesFilePath -Encoding UTF8
            
            return $true
        } catch {
            Write-Error "Erreur lors de la sauvegarde des signatures: $_"
            return $false
        }
    }
    
    # Méthode pour générer et stocker la signature d'un document
    [DocumentSignature] GenerateAndStoreSignature([IndexDocument]$document) {
        $signature = $this.Generator.GenerateSignature($document)
        $this.Signatures[$document.Id] = $signature
        return $signature
    }
    
    # Méthode pour vérifier si un document a changé
    [hashtable] CheckDocumentChanged([IndexDocument]$document) {
        $result = @{
            document_id = $document.Id
            has_changed = $true
            is_new = $false
            comparison = $null
        }
        
        # Vérifier si le document existe déjà
        if (-not $this.Signatures.ContainsKey($document.Id)) {
            $result.is_new = $true
            
            # Générer et stocker la signature
            $this.GenerateAndStoreSignature($document)
            
            # Enregistrer l'ajout si un gestionnaire de suivi est disponible
            if ($null -ne $this.ChangeTracker) {
                $this.ChangeTracker.TrackAdd($document.Id)
            }
            
            return $result
        }
        
        # Récupérer la signature existante
        $existingSignature = $this.Signatures[$document.Id]
        
        # Générer une nouvelle signature
        $newSignature = $this.Generator.GenerateSignature($document)
        
        # Comparer les signatures
        $comparison = $this.Comparator.CompareSignatures($existingSignature, $newSignature)
        $result.comparison = $comparison
        $result.has_changed = -not $comparison.is_identical
        
        # Si le document a changé, mettre à jour la signature et enregistrer la modification
        if ($result.has_changed) {
            $this.Signatures[$document.Id] = $newSignature
            
            # Enregistrer la mise à jour si un gestionnaire de suivi est disponible
            if ($null -ne $this.ChangeTracker) {
                $entry = $this.ChangeTracker.TrackUpdate($document.Id)
                
                # Ajouter les différences comme métadonnées
                foreach ($diff in $comparison.differences) {
                    $entry.AddMetadata("diff_$diff", $true)
                }
            }
        }
        
        return $result
    }
    
    # Méthode pour vérifier si un document a été supprimé
    [bool] CheckDocumentDeleted([string]$documentId) {
        # Vérifier si le document existe dans les signatures
        if (-not $this.Signatures.ContainsKey($documentId)) {
            return $false
        }
        
        # Supprimer la signature
        $this.Signatures.Remove($documentId)
        
        # Enregistrer la suppression si un gestionnaire de suivi est disponible
        if ($null -ne $this.ChangeTracker) {
            $this.ChangeTracker.TrackDelete($documentId)
        }
        
        return $true
    }
    
    # Méthode pour obtenir les statistiques des signatures
    [hashtable] GetStats() {
        return @{
            total_signatures = $this.Signatures.Count
            oldest_signature = if ($this.Signatures.Count -gt 0) {
                ($this.Signatures.Values | Sort-Object -Property Timestamp | Select-Object -First 1).Timestamp
            } else {
                $null
            }
            newest_signature = if ($this.Signatures.Count -gt 0) {
                ($this.Signatures.Values | Sort-Object -Property Timestamp -Descending | Select-Object -First 1).Timestamp
            } else {
                $null
            }
        }
    }
}

# Fonction pour créer un gestionnaire de signatures
function New-SignatureManager {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$SignaturesFilePath = (Join-Path -Path $env:TEMP -ChildPath "document_signatures.json"),
        
        [Parameter(Mandatory = $false)]
        [ChangeTrackingManager]$ChangeTracker = $null
    )
    
    return [SignatureManager]::new($SignaturesFilePath, $ChangeTracker)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-SignatureManager
