# DocumentUpdater.ps1
# Script implémentant la mise à jour des documents existants pour l'indexation incrémentale
# Version: 1.0
# Date: 2025-05-15

# Importer les modules nécessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$incrementalAdditionPath = Join-Path -Path $scriptPath -ChildPath "IncrementalAddition.ps1"

if (Test-Path -Path $incrementalAdditionPath) {
    . $incrementalAdditionPath
} else {
    Write-Error "Le fichier IncrementalAddition.ps1 est introuvable."
    exit 1
}

# Classe pour représenter une stratégie de mise à jour
class UpdateStrategy {
    # Type de stratégie (Replace, Merge, Patch)
    [string]$Type
    
    # Constructeur par défaut
    UpdateStrategy() {
        $this.Type = "Replace"
    }
    
    # Constructeur avec type
    UpdateStrategy([string]$type) {
        $this.Type = $type
    }
    
    # Méthode pour appliquer la mise à jour
    [IndexDocument] ApplyUpdate([IndexDocument]$existingDocument, [IndexDocument]$newDocument) {
        switch ($this.Type) {
            "Replace" {
                return $newDocument
            }
            "Merge" {
                return $this.MergeDocuments($existingDocument, $newDocument)
            }
            "Patch" {
                return $this.PatchDocument($existingDocument, $newDocument)
            }
            default {
                return $newDocument
            }
        }
    }
    
    # Méthode pour fusionner deux documents
    [IndexDocument] MergeDocuments([IndexDocument]$existingDocument, [IndexDocument]$newDocument) {
        # Créer un nouveau document avec l'ID existant
        $mergedDocument = [IndexDocument]::new($existingDocument.Id)
        
        # Copier les métadonnées existantes
        foreach ($key in $existingDocument.Metadata.Keys) {
            $mergedDocument.Metadata[$key] = $existingDocument.Metadata[$key]
        }
        
        # Mettre à jour les métadonnées avec les nouvelles valeurs
        foreach ($key in $newDocument.Metadata.Keys) {
            $mergedDocument.Metadata[$key] = $newDocument.Metadata[$key]
        }
        
        # Mettre à jour la date de modification
        $mergedDocument.Metadata.updated_at = (Get-Date).ToString("o")
        
        # Incrémenter la version
        if ($mergedDocument.Metadata.ContainsKey("version")) {
            $mergedDocument.Metadata.version = [int]$mergedDocument.Metadata.version + 1
        } else {
            $mergedDocument.Metadata.version = 1
        }
        
        # Fusionner le contenu
        # Commencer par copier le contenu existant
        foreach ($key in $existingDocument.Content.Keys) {
            $mergedDocument.Content[$key] = $existingDocument.Content[$key]
        }
        
        # Mettre à jour avec le nouveau contenu
        foreach ($key in $newDocument.Content.Keys) {
            $mergedDocument.Content[$key] = $newDocument.Content[$key]
        }
        
        return $mergedDocument
    }
    
    # Méthode pour appliquer un patch à un document
    [IndexDocument] PatchDocument([IndexDocument]$existingDocument, [IndexDocument]$newDocument) {
        # Créer une copie du document existant
        $patchedDocument = [IndexDocument]::new($existingDocument.Id)
        
        # Copier les métadonnées existantes
        foreach ($key in $existingDocument.Metadata.Keys) {
            $patchedDocument.Metadata[$key] = $existingDocument.Metadata[$key]
        }
        
        # Mettre à jour la date de modification
        $patchedDocument.Metadata.updated_at = (Get-Date).ToString("o")
        
        # Incrémenter la version
        if ($patchedDocument.Metadata.ContainsKey("version")) {
            $patchedDocument.Metadata.version = [int]$patchedDocument.Metadata.version + 1
        } else {
            $patchedDocument.Metadata.version = 1
        }
        
        # Copier le contenu existant
        foreach ($key in $existingDocument.Content.Keys) {
            $patchedDocument.Content[$key] = $existingDocument.Content[$key]
        }
        
        # Appliquer les modifications du nouveau document
        foreach ($key in $newDocument.Content.Keys) {
            # Si la valeur est null, supprimer la propriété
            if ($null -eq $newDocument.Content[$key]) {
                $patchedDocument.Content.Remove($key)
            } else {
                $patchedDocument.Content[$key] = $newDocument.Content[$key]
            }
        }
        
        return $patchedDocument
    }
}

# Classe pour représenter une stratégie de fusion
class MergeStrategy : UpdateStrategy {
    # Champs à ignorer lors de la fusion
    [string[]]$IgnoreFields
    
    # Constructeur par défaut
    MergeStrategy() : base("Merge") {
        $this.IgnoreFields = @()
    }
    
    # Constructeur avec champs à ignorer
    MergeStrategy([string[]]$ignoreFields) : base("Merge") {
        $this.IgnoreFields = $ignoreFields
    }
    
    # Méthode pour fusionner deux documents
    [IndexDocument] MergeDocuments([IndexDocument]$existingDocument, [IndexDocument]$newDocument) {
        # Créer un nouveau document avec l'ID existant
        $mergedDocument = [IndexDocument]::new($existingDocument.Id)
        
        # Copier les métadonnées existantes
        foreach ($key in $existingDocument.Metadata.Keys) {
            $mergedDocument.Metadata[$key] = $existingDocument.Metadata[$key]
        }
        
        # Mettre à jour les métadonnées avec les nouvelles valeurs
        foreach ($key in $newDocument.Metadata.Keys) {
            $mergedDocument.Metadata[$key] = $newDocument.Metadata[$key]
        }
        
        # Mettre à jour la date de modification
        $mergedDocument.Metadata.updated_at = (Get-Date).ToString("o")
        
        # Incrémenter la version
        if ($mergedDocument.Metadata.ContainsKey("version")) {
            $mergedDocument.Metadata.version = [int]$mergedDocument.Metadata.version + 1
        } else {
            $mergedDocument.Metadata.version = 1
        }
        
        # Fusionner le contenu
        # Commencer par copier le contenu existant
        foreach ($key in $existingDocument.Content.Keys) {
            $mergedDocument.Content[$key] = $existingDocument.Content[$key]
        }
        
        # Mettre à jour avec le nouveau contenu, en ignorant les champs spécifiés
        foreach ($key in $newDocument.Content.Keys) {
            if ($this.IgnoreFields -notcontains $key) {
                $mergedDocument.Content[$key] = $newDocument.Content[$key]
            }
        }
        
        return $mergedDocument
    }
}

# Classe pour représenter une stratégie de patch
class PatchStrategy : UpdateStrategy {
    # Champs à inclure dans le patch
    [string[]]$IncludeFields
    
    # Constructeur par défaut
    PatchStrategy() : base("Patch") {
        $this.IncludeFields = @()
    }
    
    # Constructeur avec champs à inclure
    PatchStrategy([string[]]$includeFields) : base("Patch") {
        $this.IncludeFields = $includeFields
    }
    
    # Méthode pour appliquer un patch à un document
    [IndexDocument] PatchDocument([IndexDocument]$existingDocument, [IndexDocument]$newDocument) {
        # Créer une copie du document existant
        $patchedDocument = [IndexDocument]::new($existingDocument.Id)
        
        # Copier les métadonnées existantes
        foreach ($key in $existingDocument.Metadata.Keys) {
            $patchedDocument.Metadata[$key] = $existingDocument.Metadata[$key]
        }
        
        # Mettre à jour la date de modification
        $patchedDocument.Metadata.updated_at = (Get-Date).ToString("o")
        
        # Incrémenter la version
        if ($patchedDocument.Metadata.ContainsKey("version")) {
            $patchedDocument.Metadata.version = [int]$patchedDocument.Metadata.version + 1
        } else {
            $patchedDocument.Metadata.version = 1
        }
        
        # Copier le contenu existant
        foreach ($key in $existingDocument.Content.Keys) {
            $patchedDocument.Content[$key] = $existingDocument.Content[$key]
        }
        
        # Appliquer les modifications du nouveau document, en incluant uniquement les champs spécifiés
        foreach ($key in $newDocument.Content.Keys) {
            if ($this.IncludeFields.Count -eq 0 -or $this.IncludeFields -contains $key) {
                # Si la valeur est null, supprimer la propriété
                if ($null -eq $newDocument.Content[$key]) {
                    $patchedDocument.Content.Remove($key)
                } else {
                    $patchedDocument.Content[$key] = $newDocument.Content[$key]
                }
            }
        }
        
        return $patchedDocument
    }
}

# Classe pour représenter un gestionnaire de mise à jour de documents
class DocumentUpdater {
    # Gestionnaire de segments
    [IndexSegmentManager]$SegmentManager
    
    # Gestionnaire de suivi des modifications
    [ChangeTrackingManager]$ChangeTracker
    
    # Stratégie de mise à jour par défaut
    [UpdateStrategy]$DefaultStrategy
    
    # Dictionnaire des stratégies de mise à jour par type de document
    [System.Collections.Generic.Dictionary[string, UpdateStrategy]]$StrategyByType
    
    # Constructeur par défaut
    DocumentUpdater() {
        $this.SegmentManager = $null
        $this.ChangeTracker = $null
        $this.DefaultStrategy = [UpdateStrategy]::new()
        $this.StrategyByType = [System.Collections.Generic.Dictionary[string, UpdateStrategy]]::new()
    }
    
    # Constructeur avec gestionnaire de segments
    DocumentUpdater([IndexSegmentManager]$segmentManager) {
        $this.SegmentManager = $segmentManager
        $this.ChangeTracker = $null
        $this.DefaultStrategy = [UpdateStrategy]::new()
        $this.StrategyByType = [System.Collections.Generic.Dictionary[string, UpdateStrategy]]::new()
    }
    
    # Constructeur complet
    DocumentUpdater([IndexSegmentManager]$segmentManager, [ChangeTrackingManager]$changeTracker, [UpdateStrategy]$defaultStrategy) {
        $this.SegmentManager = $segmentManager
        $this.ChangeTracker = $changeTracker
        $this.DefaultStrategy = $defaultStrategy
        $this.StrategyByType = [System.Collections.Generic.Dictionary[string, UpdateStrategy]]::new()
    }
    
    # Méthode pour définir une stratégie de mise à jour pour un type de document
    [void] SetStrategyForType([string]$documentType, [UpdateStrategy]$strategy) {
        $this.StrategyByType[$documentType] = $strategy
    }
    
    # Méthode pour obtenir la stratégie de mise à jour pour un document
    [UpdateStrategy] GetStrategyForDocument([IndexDocument]$document) {
        # Vérifier si le document a un type défini
        if ($document.Content.ContainsKey("type")) {
            $documentType = $document.Content["type"]
            
            # Vérifier si une stratégie est définie pour ce type
            if ($this.StrategyByType.ContainsKey($documentType)) {
                return $this.StrategyByType[$documentType]
            }
        }
        
        # Utiliser la stratégie par défaut
        return $this.DefaultStrategy
    }
    
    # Méthode pour mettre à jour un document
    [IndexDocument] UpdateDocument([IndexDocument]$newDocument) {
        # Vérifier si le gestionnaire de segments est défini
        if ($null -eq $this.SegmentManager) {
            Write-Error "Le gestionnaire de segments n'est pas défini."
            return $null
        }
        
        # Vérifier si le document existe
        $existingDocument = $this.SegmentManager.GetDocument($newDocument.Id)
        
        if ($null -eq $existingDocument) {
            # Le document n'existe pas, l'ajouter simplement
            $this.SegmentManager.AddDocument($newDocument)
            
            # Enregistrer l'ajout si un gestionnaire de suivi est disponible
            if ($null -ne $this.ChangeTracker) {
                $this.ChangeTracker.TrackAdd($newDocument.Id)
            }
            
            return $newDocument
        }
        
        # Obtenir la stratégie de mise à jour pour ce document
        $strategy = $this.GetStrategyForDocument($newDocument)
        
        # Appliquer la mise à jour
        $updatedDocument = $strategy.ApplyUpdate($existingDocument, $newDocument)
        
        # Mettre à jour le document dans l'index
        $this.SegmentManager.AddDocument($updatedDocument)
        
        # Enregistrer la mise à jour si un gestionnaire de suivi est disponible
        if ($null -ne $this.ChangeTracker) {
            $this.ChangeTracker.TrackUpdate($updatedDocument.Id)
        }
        
        return $updatedDocument
    }
    
    # Méthode pour mettre à jour plusieurs documents
    [hashtable] UpdateDocuments([IndexDocument[]]$documents) {
        $result = @{
            total = $documents.Count
            added = 0
            updated = 0
            errors = [System.Collections.Generic.List[string]]::new()
        }
        
        foreach ($document in $documents) {
            try {
                $existingDocument = $this.SegmentManager.GetDocument($document.Id)
                
                if ($null -eq $existingDocument) {
                    # Le document n'existe pas, l'ajouter simplement
                    $this.SegmentManager.AddDocument($document)
                    
                    # Enregistrer l'ajout si un gestionnaire de suivi est disponible
                    if ($null -ne $this.ChangeTracker) {
                        $this.ChangeTracker.TrackAdd($document.Id)
                    }
                    
                    $result.added++
                } else {
                    # Obtenir la stratégie de mise à jour pour ce document
                    $strategy = $this.GetStrategyForDocument($document)
                    
                    # Appliquer la mise à jour
                    $updatedDocument = $strategy.ApplyUpdate($existingDocument, $document)
                    
                    # Mettre à jour le document dans l'index
                    $this.SegmentManager.AddDocument($updatedDocument)
                    
                    # Enregistrer la mise à jour si un gestionnaire de suivi est disponible
                    if ($null -ne $this.ChangeTracker) {
                        $this.ChangeTracker.TrackUpdate($updatedDocument.Id)
                    }
                    
                    $result.updated++
                }
            } catch {
                $result.errors.Add("Erreur lors de la mise à jour du document $($document.Id): $_")
            }
        }
        
        return $result
    }
}

# Fonction pour créer une stratégie de mise à jour
function New-UpdateStrategy {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Replace", "Merge", "Patch")]
        [string]$Type = "Replace",
        
        [Parameter(Mandatory = $false)]
        [string[]]$Fields = @()
    )
    
    switch ($Type) {
        "Replace" {
            return [UpdateStrategy]::new()
        }
        "Merge" {
            return [MergeStrategy]::new($Fields)
        }
        "Patch" {
            return [PatchStrategy]::new($Fields)
        }
        default {
            return [UpdateStrategy]::new()
        }
    }
}

# Fonction pour créer un gestionnaire de mise à jour de documents
function New-DocumentUpdater {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [IndexSegmentManager]$SegmentManager,
        
        [Parameter(Mandatory = $false)]
        [ChangeTrackingManager]$ChangeTracker = $null,
        
        [Parameter(Mandatory = $false)]
        [UpdateStrategy]$DefaultStrategy = (New-UpdateStrategy)
    )
    
    return [DocumentUpdater]::new($SegmentManager, $ChangeTracker, $DefaultStrategy)
}

# Exporter les fonctions et classes
Export-ModuleMember -Function New-UpdateStrategy, New-DocumentUpdater
