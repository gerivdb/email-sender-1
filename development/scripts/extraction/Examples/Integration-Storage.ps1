#Requires -Version 5.1
<#
.SYNOPSIS
Exemple d'intégration du module ExtractedInfoModuleV2 avec un système de stockage.

.DESCRIPTION
Ce script montre comment intégrer le module ExtractedInfoModuleV2 avec différents systèmes de stockage
pour persister et récupérer des objets d'information extraite.

.NOTES
Date de création : 2025-05-15
#>

# Importer les modules nécessaires
Import-Module ExtractedInfoModuleV2
# Note: Les modules de stockage sont fictifs et utilisés à des fins d'exemple
# Import-Module SqlServer
# Import-Module AzureStorage
# Import-Module MongoDB

#region Stockage dans une base de données SQL Server

# Fonction pour créer la structure de la base de données
function Initialize-SqlServerStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    Write-Verbose "Initialisation du stockage SQL Server"
    
    try {
        # Simuler la création de la structure de la base de données
        # Dans un cas réel, on utiliserait Invoke-Sqlcmd du module SqlServer
        <#
        $createTableQuery = @"
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExtractedInfo')
        BEGIN
            CREATE TABLE ExtractedInfo (
                Id UNIQUEIDENTIFIER PRIMARY KEY,
                Type NVARCHAR(100) NOT NULL,
                Source NVARCHAR(500) NOT NULL,
                Content NVARCHAR(MAX) NOT NULL,
                CreatedAt DATETIME NOT NULL DEFAULT GETDATE(),
                ModifiedAt DATETIME NOT NULL DEFAULT GETDATE()
            )
        END
        
        IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ExtractedInfoMetadata')
        BEGIN
            CREATE TABLE ExtractedInfoMetadata (
                Id UNIQUEIDENTIFIER PRIMARY KEY,
                InfoId UNIQUEIDENTIFIER NOT NULL,
                [Key] NVARCHAR(100) NOT NULL,
                Value NVARCHAR(MAX) NULL,
                FOREIGN KEY (InfoId) REFERENCES ExtractedInfo(Id) ON DELETE CASCADE
            )
        END
        "@
        
        Invoke-Sqlcmd -Query $createTableQuery -ConnectionString $ConnectionString
        #>
        
        Write-Verbose "Structure de la base de données créée avec succès"
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'initialisation du stockage SQL Server : $_"
        return $false
    }
}

# Fonction pour sauvegarder un objet d'information extraite dans SQL Server
function Save-ExtractedInfoToSqlServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,
        
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString
    )
    
    Write-Verbose "Sauvegarde de l'objet $($Info.Id) dans SQL Server"
    
    try {
        # Convertir l'objet en JSON pour le stockage
        $json = ConvertTo-Json -InputObject $Info -Depth 10 -Compress
        
        # Simuler l'insertion dans la base de données
        # Dans un cas réel, on utiliserait Invoke-Sqlcmd du module SqlServer
        <#
        $insertQuery = @"
        IF EXISTS (SELECT * FROM ExtractedInfo WHERE Id = '$($Info.Id)')
        BEGIN
            UPDATE ExtractedInfo
            SET Type = '$($Info._Type)',
                Source = '$($Info.Source)',
                Content = @Content,
                ModifiedAt = GETDATE()
            WHERE Id = '$($Info.Id)'
        END
        ELSE
        BEGIN
            INSERT INTO ExtractedInfo (Id, Type, Source, Content, CreatedAt, ModifiedAt)
            VALUES ('$($Info.Id)', '$($Info._Type)', '$($Info.Source)', @Content, GETDATE(), GETDATE())
        END
        "@
        
        $parameters = @{
            Content = $json
        }
        
        Invoke-Sqlcmd -Query $insertQuery -ConnectionString $ConnectionString -Parameters $parameters
        
        # Sauvegarder les métadonnées
        if ($Info.ContainsKey('Metadata') -and $null -ne $Info.Metadata) {
            # Supprimer les métadonnées existantes
            Invoke-Sqlcmd -Query "DELETE FROM ExtractedInfoMetadata WHERE InfoId = '$($Info.Id)'" -ConnectionString $ConnectionString
            
            # Insérer les nouvelles métadonnées
            foreach ($key in $Info.Metadata.Keys) {
                $value = if ($null -eq $Info.Metadata[$key]) { "NULL" } else { $Info.Metadata[$key].ToString() }
                
                $insertMetadataQuery = @"
                INSERT INTO ExtractedInfoMetadata (Id, InfoId, [Key], Value)
                VALUES (NEWID(), '$($Info.Id)', '$key', '$value')
                "@
                
                Invoke-Sqlcmd -Query $insertMetadataQuery -ConnectionString $ConnectionString
            }
        }
        #>
        
        Write-Verbose "Objet sauvegardé avec succès"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la sauvegarde de l'objet dans SQL Server : $_"
        return $false
    }
}

# Fonction pour récupérer un objet d'information extraite depuis SQL Server
function Get-ExtractedInfoFromSqlServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,
        
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString
    )
    
    Write-Verbose "Récupération de l'objet $Id depuis SQL Server"
    
    try {
        # Simuler la récupération depuis la base de données
        # Dans un cas réel, on utiliserait Invoke-Sqlcmd du module SqlServer
        <#
        $query = "SELECT Content FROM ExtractedInfo WHERE Id = '$Id'"
        $result = Invoke-Sqlcmd -Query $query -ConnectionString $ConnectionString
        
        if ($result.Count -eq 0) {
            Write-Warning "Aucun objet trouvé avec l'ID $Id"
            return $null
        }
        
        $content = $result[0].Content
        $info = ConvertFrom-Json -InputObject $content -AsHashtable
        #>
        
        # Simuler un objet récupéré
        $info = @{
            _Type = "TextExtractedInfo"
            Id = $Id
            Source = "database:example"
            Text = "Ceci est un exemple de texte récupéré depuis la base de données."
            Language = "fr"
            ConfidenceScore = 95
            ExtractedAt = Get-Date
            ProcessingState = "Processed"
            Metadata = @{
                StoredAt = Get-Date
                StorageSystem = "SQL Server"
            }
        }
        
        Write-Verbose "Objet récupéré avec succès"
        return $info
    }
    catch {
        Write-Error "Erreur lors de la récupération de l'objet depuis SQL Server : $_"
        return $null
    }
}

# Fonction pour rechercher des objets d'information extraite dans SQL Server
function Find-ExtractedInfoInSqlServer {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Type,
        
        [Parameter(Mandatory = $false)]
        [string]$Source,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$MetadataFilter,
        
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString
    )
    
    Write-Verbose "Recherche d'objets dans SQL Server"
    
    try {
        # Simuler la recherche dans la base de données
        # Dans un cas réel, on utiliserait Invoke-Sqlcmd du module SqlServer
        <#
        $whereClause = "1=1"
        
        if (-not [string]::IsNullOrEmpty($Type)) {
            $whereClause += " AND Type = '$Type'"
        }
        
        if (-not [string]::IsNullOrEmpty($Source)) {
            $whereClause += " AND Source LIKE '%$Source%'"
        }
        
        $query = "SELECT Id, Type, Source, CreatedAt FROM ExtractedInfo WHERE $whereClause"
        $results = Invoke-Sqlcmd -Query $query -ConnectionString $ConnectionString
        
        $ids = @()
        foreach ($row in $results) {
            $ids += $row.Id
        }
        
        # Filtrer par métadonnées si nécessaire
        if ($null -ne $MetadataFilter -and $MetadataFilter.Count -gt 0) {
            $filteredIds = @()
            
            foreach ($id in $ids) {
                $metadataQuery = "SELECT [Key], Value FROM ExtractedInfoMetadata WHERE InfoId = '$id'"
                $metadataResults = Invoke-Sqlcmd -Query $metadataQuery -ConnectionString $ConnectionString
                
                $metadata = @{}
                foreach ($row in $metadataResults) {
                    $metadata[$row.Key] = $row.Value
                }
                
                $match = $true
                foreach ($key in $MetadataFilter.Keys) {
                    if (-not $metadata.ContainsKey($key) -or $metadata[$key] -ne $MetadataFilter[$key]) {
                        $match = $false
                        break
                    }
                }
                
                if ($match) {
                    $filteredIds += $id
                }
            }
            
            $ids = $filteredIds
        }
        
        # Récupérer les objets complets
        $objects = @()
        foreach ($id in $ids) {
            $objects += Get-ExtractedInfoFromSqlServer -Id $id -ConnectionString $ConnectionString
        }
        #>
        
        # Simuler des résultats de recherche
        $objects = @(
            @{
                _Type = "TextExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                Source = "database:example1"
                Text = "Premier exemple de texte récupéré depuis la base de données."
                Language = "fr"
                ConfidenceScore = 95
                ExtractedAt = Get-Date
                ProcessingState = "Processed"
                Metadata = @{
                    StoredAt = Get-Date
                    StorageSystem = "SQL Server"
                }
            },
            @{
                _Type = "TextExtractedInfo"
                Id = [guid]::NewGuid().ToString()
                Source = "database:example2"
                Text = "Deuxième exemple de texte récupéré depuis la base de données."
                Language = "fr"
                ConfidenceScore = 90
                ExtractedAt = Get-Date
                ProcessingState = "Processed"
                Metadata = @{
                    StoredAt = Get-Date
                    StorageSystem = "SQL Server"
                }
            }
        )
        
        Write-Verbose "Recherche terminée, $($objects.Count) objets trouvés"
        return $objects
    }
    catch {
        Write-Error "Erreur lors de la recherche d'objets dans SQL Server : $_"
        return @()
    }
}
#endregion

#region Stockage dans Azure Blob Storage

# Fonction pour initialiser le stockage Azure Blob
function Initialize-AzureBlobStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory = $true)]
        [string]$ContainerName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    Write-Verbose "Initialisation du stockage Azure Blob"
    
    try {
        # Simuler la création du conteneur
        # Dans un cas réel, on utiliserait New-AzStorageContainer du module Az.Storage
        <#
        $storageAccount = New-Object -TypeName Microsoft.WindowsAzure.Storage.CloudStorageAccount -ArgumentList $ConnectionString
        $blobClient = $storageAccount.CreateCloudBlobClient()
        $container = $blobClient.GetContainerReference($ContainerName)
        
        if (-not $container.Exists() -or $Force) {
            $container.CreateIfNotExists()
            $container.SetPermissions([Microsoft.WindowsAzure.Storage.Blob.BlobContainerPublicAccessType]::Off)
        }
        #>
        
        Write-Verbose "Conteneur Azure Blob créé avec succès"
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'initialisation du stockage Azure Blob : $_"
        return $false
    }
}

# Fonction pour sauvegarder un objet d'information extraite dans Azure Blob
function Save-ExtractedInfoToAzureBlob {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,
        
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory = $true)]
        [string]$ContainerName
    )
    
    Write-Verbose "Sauvegarde de l'objet $($Info.Id) dans Azure Blob"
    
    try {
        # Convertir l'objet en JSON pour le stockage
        $json = ConvertTo-Json -InputObject $Info -Depth 10
        
        # Simuler l'upload vers Azure Blob
        # Dans un cas réel, on utiliserait Set-AzStorageBlobContent du module Az.Storage
        <#
        $storageAccount = New-Object -TypeName Microsoft.WindowsAzure.Storage.CloudStorageAccount -ArgumentList $ConnectionString
        $blobClient = $storageAccount.CreateCloudBlobClient()
        $container = $blobClient.GetContainerReference($ContainerName)
        
        $blobName = "$($Info._Type)/$($Info.Id).json"
        $blob = $container.GetBlockBlobReference($blobName)
        
        $tempFile = [System.IO.Path]::GetTempFileName()
        $json | Out-File -FilePath $tempFile -Encoding utf8
        
        $blob.UploadFromFile($tempFile, $null, $null, $null)
        Remove-Item -Path $tempFile -Force
        
        # Créer un blob d'index pour faciliter la recherche
        $indexData = @{
            Id = $Info.Id
            Type = $Info._Type
            Source = $Info.Source
            BlobName = $blobName
            CreatedAt = Get-Date
            Metadata = if ($Info.ContainsKey('Metadata')) { $Info.Metadata } else { @{} }
        }
        
        $indexJson = ConvertTo-Json -InputObject $indexData -Depth 5
        $indexBlobName = "index/$($Info.Id).json"
        $indexBlob = $container.GetBlockBlobReference($indexBlobName)
        
        $tempIndexFile = [System.IO.Path]::GetTempFileName()
        $indexJson | Out-File -FilePath $tempIndexFile -Encoding utf8
        
        $indexBlob.UploadFromFile($tempIndexFile, $null, $null, $null)
        Remove-Item -Path $tempIndexFile -Force
        #>
        
        Write-Verbose "Objet sauvegardé avec succès dans Azure Blob"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la sauvegarde de l'objet dans Azure Blob : $_"
        return $false
    }
}

# Fonction pour récupérer un objet d'information extraite depuis Azure Blob
function Get-ExtractedInfoFromAzureBlob {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,
        
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory = $true)]
        [string]$ContainerName
    )
    
    Write-Verbose "Récupération de l'objet $Id depuis Azure Blob"
    
    try {
        # Simuler la récupération depuis Azure Blob
        # Dans un cas réel, on utiliserait Get-AzStorageBlobContent du module Az.Storage
        <#
        $storageAccount = New-Object -TypeName Microsoft.WindowsAzure.Storage.CloudStorageAccount -ArgumentList $ConnectionString
        $blobClient = $storageAccount.CreateCloudBlobClient()
        $container = $blobClient.GetContainerReference($ContainerName)
        
        # Récupérer d'abord le blob d'index pour trouver le blob principal
        $indexBlobName = "index/$Id.json"
        $indexBlob = $container.GetBlockBlobReference($indexBlobName)
        
        if (-not $indexBlob.Exists()) {
            Write-Warning "Aucun objet trouvé avec l'ID $Id"
            return $null
        }
        
        $tempIndexFile = [System.IO.Path]::GetTempFileName()
        $indexBlob.DownloadToFile($tempIndexFile, [System.IO.FileMode]::Create)
        
        $indexData = Get-Content -Path $tempIndexFile -Raw | ConvertFrom-Json
        Remove-Item -Path $tempIndexFile -Force
        
        # Récupérer le blob principal
        $blobName = $indexData.BlobName
        $blob = $container.GetBlockBlobReference($blobName)
        
        $tempFile = [System.IO.Path]::GetTempFileName()
        $blob.DownloadToFile($tempFile, [System.IO.FileMode]::Create)
        
        $content = Get-Content -Path $tempFile -Raw
        Remove-Item -Path $tempFile -Force
        
        $info = ConvertFrom-Json -InputObject $content -AsHashtable
        #>
        
        # Simuler un objet récupéré
        $info = @{
            _Type = "TextExtractedInfo"
            Id = $Id
            Source = "azureblob:example"
            Text = "Ceci est un exemple de texte récupéré depuis Azure Blob Storage."
            Language = "fr"
            ConfidenceScore = 92
            ExtractedAt = Get-Date
            ProcessingState = "Processed"
            Metadata = @{
                StoredAt = Get-Date
                StorageSystem = "Azure Blob"
            }
        }
        
        Write-Verbose "Objet récupéré avec succès depuis Azure Blob"
        return $info
    }
    catch {
        Write-Error "Erreur lors de la récupération de l'objet depuis Azure Blob : $_"
        return $null
    }
}
#endregion

#region Stockage dans MongoDB

# Fonction pour initialiser le stockage MongoDB
function Initialize-MongoDBStorage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    Write-Verbose "Initialisation du stockage MongoDB"
    
    try {
        # Simuler la création de la collection
        # Dans un cas réel, on utiliserait le module MongoDB.Driver
        <#
        $client = New-Object -TypeName MongoDB.Driver.MongoClient -ArgumentList $ConnectionString
        $database = $client.GetDatabase($DatabaseName)
        
        # Vérifier si la collection existe
        $collections = $database.ListCollectionNames().ToList()
        
        if (-not $collections.Contains("ExtractedInfo") -or $Force) {
            $database.CreateCollection("ExtractedInfo")
            
            # Créer des index
            $collection = $database.GetCollection<BsonDocument>("ExtractedInfo")
            $collection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(Builders<BsonDocument>.IndexKeys.Ascending("_id")))
            $collection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(Builders<BsonDocument>.IndexKeys.Ascending("Type")))
            $collection.Indexes.CreateOne(new CreateIndexModel<BsonDocument>(Builders<BsonDocument>.IndexKeys.Ascending("Source")))
        }
        #>
        
        Write-Verbose "Collection MongoDB créée avec succès"
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'initialisation du stockage MongoDB : $_"
        return $false
    }
}

# Fonction pour sauvegarder un objet d'information extraite dans MongoDB
function Save-ExtractedInfoToMongoDB {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Info,
        
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName
    )
    
    Write-Verbose "Sauvegarde de l'objet $($Info.Id) dans MongoDB"
    
    try {
        # Simuler l'insertion dans MongoDB
        # Dans un cas réel, on utiliserait le module MongoDB.Driver
        <#
        $client = New-Object -TypeName MongoDB.Driver.MongoClient -ArgumentList $ConnectionString
        $database = $client.GetDatabase($DatabaseName)
        $collection = $database.GetCollection<BsonDocument>("ExtractedInfo")
        
        # Convertir l'objet en document BSON
        $document = new BsonDocument()
        $document.Add("_id", $Info.Id)
        $document.Add("Type", $Info._Type)
        $document.Add("Source", $Info.Source)
        $document.Add("Content", ConvertTo-Json -InputObject $Info -Depth 10)
        $document.Add("CreatedAt", [DateTime]::Now)
        $document.Add("ModifiedAt", [DateTime]::Now)
        
        # Ajouter les métadonnées
        if ($Info.ContainsKey('Metadata') -and $null -ne $Info.Metadata) {
            $metadataDoc = new BsonDocument()
            
            foreach ($key in $Info.Metadata.Keys) {
                $value = if ($null -eq $Info.Metadata[$key]) { BsonNull.Value } else { $Info.Metadata[$key].ToString() }
                $metadataDoc.Add($key, $value)
            }
            
            $document.Add("Metadata", $metadataDoc)
        }
        
        # Insérer ou mettre à jour le document
        $filter = Builders<BsonDocument>.Filter.Eq("_id", $Info.Id)
        $options = new ReplaceOptions { IsUpsert = true }
        $collection.ReplaceOne($filter, $document, $options)
        #>
        
        Write-Verbose "Objet sauvegardé avec succès dans MongoDB"
        return $true
    }
    catch {
        Write-Error "Erreur lors de la sauvegarde de l'objet dans MongoDB : $_"
        return $false
    }
}

# Fonction pour récupérer un objet d'information extraite depuis MongoDB
function Get-ExtractedInfoFromMongoDB {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Id,
        
        [Parameter(Mandatory = $true)]
        [string]$ConnectionString,
        
        [Parameter(Mandatory = $true)]
        [string]$DatabaseName
    )
    
    Write-Verbose "Récupération de l'objet $Id depuis MongoDB"
    
    try {
        # Simuler la récupération depuis MongoDB
        # Dans un cas réel, on utiliserait le module MongoDB.Driver
        <#
        $client = New-Object -TypeName MongoDB.Driver.MongoClient -ArgumentList $ConnectionString
        $database = $client.GetDatabase($DatabaseName)
        $collection = $database.GetCollection<BsonDocument>("ExtractedInfo")
        
        $filter = Builders<BsonDocument>.Filter.Eq("_id", $Id)
        $document = $collection.Find($filter).FirstOrDefault()
        
        if ($document -eq $null) {
            Write-Warning "Aucun objet trouvé avec l'ID $Id"
            return $null
        }
        
        $content = $document["Content"].AsString
        $info = ConvertFrom-Json -InputObject $content -AsHashtable
        #>
        
        # Simuler un objet récupéré
        $info = @{
            _Type = "TextExtractedInfo"
            Id = $Id
            Source = "mongodb:example"
            Text = "Ceci est un exemple de texte récupéré depuis MongoDB."
            Language = "fr"
            ConfidenceScore = 88
            ExtractedAt = Get-Date
            ProcessingState = "Processed"
            Metadata = @{
                StoredAt = Get-Date
                StorageSystem = "MongoDB"
            }
        }
        
        Write-Verbose "Objet récupéré avec succès depuis MongoDB"
        return $info
    }
    catch {
        Write-Error "Erreur lors de la récupération de l'objet depuis MongoDB : $_"
        return $null
    }
}
#endregion

# Exemple d'utilisation
function Example-StorageIntegration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [ValidateSet("SqlServer", "AzureBlob", "MongoDB")]
        [string]$StorageType = "SqlServer",
        
        [Parameter(Mandatory = $false)]
        [string]$ConnectionString = "Server=localhost;Database=ExtractedInfo;Trusted_Connection=True;",
        
        [Parameter(Mandatory = $false)]
        [string]$ContainerName = "extractedinfo",
        
        [Parameter(Mandatory = $false)]
        [string]$DatabaseName = "ExtractedInfo"
    )
    
    # Créer un objet d'information extraite
    $info = New-TextExtractedInfo -Source "example.txt" -Text "Ceci est un exemple de texte à stocker." -Language "fr"
    $info = Add-ExtractedInfoMetadata -Info $info -Metadata @{
        Author = "Utilisateur test"
        Category = "Exemple"
        Tags = @("test", "stockage", "exemple")
    }
    
    Write-Host "Objet créé avec l'ID : $($info.Id)"
    
    # Stocker l'objet selon le type de stockage choisi
    $stored = $false
    
    switch ($StorageType) {
        "SqlServer" {
            Initialize-SqlServerStorage -ConnectionString $ConnectionString
            $stored = Save-ExtractedInfoToSqlServer -Info $info -ConnectionString $ConnectionString
        }
        "AzureBlob" {
            Initialize-AzureBlobStorage -ConnectionString $ConnectionString -ContainerName $ContainerName
            $stored = Save-ExtractedInfoToAzureBlob -Info $info -ConnectionString $ConnectionString -ContainerName $ContainerName
        }
        "MongoDB" {
            Initialize-MongoDBStorage -ConnectionString $ConnectionString -DatabaseName $DatabaseName
            $stored = Save-ExtractedInfoToMongoDB -Info $info -ConnectionString $ConnectionString -DatabaseName $DatabaseName
        }
    }
    
    if ($stored) {
        Write-Host "Objet stocké avec succès dans $StorageType"
        
        # Récupérer l'objet
        $retrievedInfo = $null
        
        switch ($StorageType) {
            "SqlServer" {
                $retrievedInfo = Get-ExtractedInfoFromSqlServer -Id $info.Id -ConnectionString $ConnectionString
            }
            "AzureBlob" {
                $retrievedInfo = Get-ExtractedInfoFromAzureBlob -Id $info.Id -ConnectionString $ConnectionString -ContainerName $ContainerName
            }
            "MongoDB" {
                $retrievedInfo = Get-ExtractedInfoFromMongoDB -Id $info.Id -ConnectionString $ConnectionString -DatabaseName $DatabaseName
            }
        }
        
        if ($null -ne $retrievedInfo) {
            Write-Host "Objet récupéré avec succès depuis $StorageType"
            Write-Host "Texte récupéré : $($retrievedInfo.Text)"
            Write-Host "Métadonnées récupérées : $($retrievedInfo.Metadata | ConvertTo-Json -Compress)"
        }
    }
    
    return $info
}

# Exécuter l'exemple
# Example-StorageIntegration -StorageType "SqlServer"
