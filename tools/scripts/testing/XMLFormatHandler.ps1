# Module de gestion du format XML
# Ce script implémente les fonctionnalités de base pour le support du format XML

# Définition de l'interface IFormatHandler (pour référence)
# interface IFormatHandler {
#     [bool] CanHandle([string]$formatName)
#     [object] Parse([string]$content)
#     [object] Parse([System.IO.Stream]$stream)
#     [string] Generate([object]$data)
#     [void] WriteToFile([object]$data, [string]$filePath)
#     [object] ReadFromFile([string]$filePath)
# }

# Configuration
$XMLConfig = @{
    # Paramètres par défaut pour le parsing XML
    DefaultXmlSettings = @{
        IgnoreComments = $true
        IgnoreWhitespace = $true
        IgnoreProcessingInstructions = $true
        MaxCharactersInDocument = 10MB
        ProhibitDtd = $false  # Permet les DTD mais désactive les entités externes
    }
    
    # Paramètres par défaut pour la validation XML
    DefaultValidationSettings = @{
        EnableSchemaValidation = $false
        SchemaPath = $null
        ValidationEventHandler = $null
    }
    
    # Paramètres par défaut pour la génération XML
    DefaultGenerationSettings = @{
        Indent = $true
        IndentChars = "  "
        NewLineOnAttributes = $false
        OmitXmlDeclaration = $false
        Encoding = "UTF-8"
    }
}

# Classe XMLFormatHandler
class XMLFormatHandler {
    # Propriétés
    [hashtable]$XmlSettings
    [hashtable]$ValidationSettings
    [hashtable]$GenerationSettings
    
    # Constructeur par défaut
    XMLFormatHandler() {
        $this.XmlSettings = $XMLConfig.DefaultXmlSettings.Clone()
        $this.ValidationSettings = $XMLConfig.DefaultValidationSettings.Clone()
        $this.GenerationSettings = $XMLConfig.DefaultGenerationSettings.Clone()
    }
    
    # Constructeur avec paramètres
    XMLFormatHandler([hashtable]$xmlSettings, [hashtable]$validationSettings, [hashtable]$generationSettings) {
        $this.XmlSettings = $xmlSettings
        $this.ValidationSettings = $validationSettings
        $this.GenerationSettings = $generationSettings
    }
    
    # Méthode pour vérifier si ce handler peut gérer un format donné
    [bool] CanHandle([string]$formatName) {
        return $formatName -eq "xml" -or $formatName -eq "XML"
    }
    
    # Méthode pour parser une chaîne XML
    [object] Parse([string]$content) {
        try {
            # Créer un XmlReaderSettings avec les paramètres configurés
            $readerSettings = New-Object System.Xml.XmlReaderSettings
            $readerSettings.IgnoreComments = $this.XmlSettings.IgnoreComments
            $readerSettings.IgnoreWhitespace = $this.XmlSettings.IgnoreWhitespace
            $readerSettings.IgnoreProcessingInstructions = $this.XmlSettings.IgnoreProcessingInstructions
            $readerSettings.MaxCharactersInDocument = $this.XmlSettings.MaxCharactersInDocument
            $readerSettings.DtdProcessing = if ($this.XmlSettings.ProhibitDtd) { [System.Xml.DtdProcessing]::Prohibit } else { [System.Xml.DtdProcessing]::Parse }
            
            # Configurer la validation si activée
            if ($this.ValidationSettings.EnableSchemaValidation -and $this.ValidationSettings.SchemaPath) {
                $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
                $schema = New-Object System.Xml.Schema.XmlSchemaSet
                $schema.Add($null, $this.ValidationSettings.SchemaPath) | Out-Null
                $readerSettings.Schemas = $schema
                
                if ($this.ValidationSettings.ValidationEventHandler) {
                    $readerSettings.ValidationEventHandler = $this.ValidationSettings.ValidationEventHandler
                }
            }
            
            # Créer un StringReader pour la chaîne XML
            $stringReader = New-Object System.IO.StringReader($content)
            
            # Créer un XmlReader avec les paramètres configurés
            $xmlReader = [System.Xml.XmlReader]::Create($stringReader, $readerSettings)
            
            # Charger le document XML
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.Load($xmlReader)
            
            # Fermer le reader
            $xmlReader.Close()
            $stringReader.Close()
            
            return $xmlDoc
        }
        catch {
            Write-Error "Erreur lors du parsing XML: $_"
            throw
        }
    }
    
    # Méthode pour parser un flux XML
    [object] Parse([System.IO.Stream]$stream) {
        try {
            # Créer un XmlReaderSettings avec les paramètres configurés
            $readerSettings = New-Object System.Xml.XmlReaderSettings
            $readerSettings.IgnoreComments = $this.XmlSettings.IgnoreComments
            $readerSettings.IgnoreWhitespace = $this.XmlSettings.IgnoreWhitespace
            $readerSettings.IgnoreProcessingInstructions = $this.XmlSettings.IgnoreProcessingInstructions
            $readerSettings.MaxCharactersInDocument = $this.XmlSettings.MaxCharactersInDocument
            $readerSettings.DtdProcessing = if ($this.XmlSettings.ProhibitDtd) { [System.Xml.DtdProcessing]::Prohibit } else { [System.Xml.DtdProcessing]::Parse }
            
            # Configurer la validation si activée
            if ($this.ValidationSettings.EnableSchemaValidation -and $this.ValidationSettings.SchemaPath) {
                $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
                $schema = New-Object System.Xml.Schema.XmlSchemaSet
                $schema.Add($null, $this.ValidationSettings.SchemaPath) | Out-Null
                $readerSettings.Schemas = $schema
                
                if ($this.ValidationSettings.ValidationEventHandler) {
                    $readerSettings.ValidationEventHandler = $this.ValidationSettings.ValidationEventHandler
                }
            }
            
            # Créer un XmlReader avec les paramètres configurés
            $xmlReader = [System.Xml.XmlReader]::Create($stream, $readerSettings)
            
            # Charger le document XML
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.Load($xmlReader)
            
            # Fermer le reader
            $xmlReader.Close()
            
            return $xmlDoc
        }
        catch {
            Write-Error "Erreur lors du parsing XML depuis le flux: $_"
            throw
        }
    }
    
    # Méthode pour générer une chaîne XML à partir d'un objet
    [string] Generate([object]$data) {
        try {
            # Vérifier si l'objet est déjà un XmlDocument
            if ($data -is [System.Xml.XmlDocument]) {
                $xmlDoc = $data
            }
            # Sinon, convertir l'objet en XML
            else {
                $xmlDoc = New-Object System.Xml.XmlDocument
                $rootElement = $xmlDoc.CreateElement("root")
                $xmlDoc.AppendChild($rootElement) | Out-Null
                
                # Convertir l'objet en XML de manière récursive
                $this.ConvertObjectToXml($xmlDoc, $rootElement, $data)
            }
            
            # Créer un StringWriter pour stocker la sortie
            $stringWriter = New-Object System.IO.StringWriter
            
            # Créer un XmlWriterSettings avec les paramètres configurés
            $writerSettings = New-Object System.Xml.XmlWriterSettings
            $writerSettings.Indent = $this.GenerationSettings.Indent
            $writerSettings.IndentChars = $this.GenerationSettings.IndentChars
            $writerSettings.NewLineOnAttributes = $this.GenerationSettings.NewLineOnAttributes
            $writerSettings.OmitXmlDeclaration = $this.GenerationSettings.OmitXmlDeclaration
            $writerSettings.Encoding = [System.Text.Encoding]::GetEncoding($this.GenerationSettings.Encoding)
            
            # Créer un XmlWriter avec les paramètres configurés
            $xmlWriter = [System.Xml.XmlWriter]::Create($stringWriter, $writerSettings)
            
            # Écrire le document XML
            $xmlDoc.WriteTo($xmlWriter)
            
            # Fermer le writer
            $xmlWriter.Close()
            $stringWriter.Close()
            
            return $stringWriter.ToString()
        }
        catch {
            Write-Error "Erreur lors de la génération XML: $_"
            throw
        }
    }
    
    # Méthode pour écrire un objet XML dans un fichier
    [void] WriteToFile([object]$data, [string]$filePath) {
        try {
            # Vérifier si l'objet est déjà un XmlDocument
            if ($data -is [System.Xml.XmlDocument]) {
                $xmlDoc = $data
            }
            # Sinon, convertir l'objet en XML
            else {
                $xmlDoc = New-Object System.Xml.XmlDocument
                $rootElement = $xmlDoc.CreateElement("root")
                $xmlDoc.AppendChild($rootElement) | Out-Null
                
                # Convertir l'objet en XML de manière récursive
                $this.ConvertObjectToXml($xmlDoc, $rootElement, $data)
            }
            
            # Créer un XmlWriterSettings avec les paramètres configurés
            $writerSettings = New-Object System.Xml.XmlWriterSettings
            $writerSettings.Indent = $this.GenerationSettings.Indent
            $writerSettings.IndentChars = $this.GenerationSettings.IndentChars
            $writerSettings.NewLineOnAttributes = $this.GenerationSettings.NewLineOnAttributes
            $writerSettings.OmitXmlDeclaration = $this.GenerationSettings.OmitXmlDeclaration
            $writerSettings.Encoding = [System.Text.Encoding]::GetEncoding($this.GenerationSettings.Encoding)
            
            # Créer un XmlWriter avec les paramètres configurés
            $xmlWriter = [System.Xml.XmlWriter]::Create($filePath, $writerSettings)
            
            # Écrire le document XML
            $xmlDoc.WriteTo($xmlWriter)
            
            # Fermer le writer
            $xmlWriter.Close()
        }
        catch {
            Write-Error "Erreur lors de l'écriture du fichier XML: $_"
            throw
        }
    }
    
    # Méthode pour lire un fichier XML
    [object] ReadFromFile([string]$filePath) {
        try {
            # Vérifier si le fichier existe
            if (-not (Test-Path -Path $filePath)) {
                throw "Le fichier XML n'existe pas: $filePath"
            }
            
            # Créer un XmlReaderSettings avec les paramètres configurés
            $readerSettings = New-Object System.Xml.XmlReaderSettings
            $readerSettings.IgnoreComments = $this.XmlSettings.IgnoreComments
            $readerSettings.IgnoreWhitespace = $this.XmlSettings.IgnoreWhitespace
            $readerSettings.IgnoreProcessingInstructions = $this.XmlSettings.IgnoreProcessingInstructions
            $readerSettings.MaxCharactersInDocument = $this.XmlSettings.MaxCharactersInDocument
            $readerSettings.DtdProcessing = if ($this.XmlSettings.ProhibitDtd) { [System.Xml.DtdProcessing]::Prohibit } else { [System.Xml.DtdProcessing]::Parse }
            
            # Configurer la validation si activée
            if ($this.ValidationSettings.EnableSchemaValidation -and $this.ValidationSettings.SchemaPath) {
                $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
                $schema = New-Object System.Xml.Schema.XmlSchemaSet
                $schema.Add($null, $this.ValidationSettings.SchemaPath) | Out-Null
                $readerSettings.Schemas = $schema
                
                if ($this.ValidationSettings.ValidationEventHandler) {
                    $readerSettings.ValidationEventHandler = $this.ValidationSettings.ValidationEventHandler
                }
            }
            
            # Créer un XmlReader avec les paramètres configurés
            $xmlReader = [System.Xml.XmlReader]::Create($filePath, $readerSettings)
            
            # Charger le document XML
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.Load($xmlReader)
            
            # Fermer le reader
            $xmlReader.Close()
            
            return $xmlDoc
        }
        catch {
            Write-Error "Erreur lors de la lecture du fichier XML: $_"
            throw
        }
    }
    
    # Méthode privée pour convertir un objet en XML de manière récursive
    hidden [void] ConvertObjectToXml([System.Xml.XmlDocument]$xmlDoc, [System.Xml.XmlElement]$parentElement, [object]$data) {
        # Si l'objet est null, ajouter un attribut xsi:nil="true"
        if ($null -eq $data) {
            $nilAttribute = $xmlDoc.CreateAttribute("xsi", "nil", "http://www.w3.org/2001/XMLSchema-instance")
            $nilAttribute.Value = "true"
            $parentElement.Attributes.Append($nilAttribute) | Out-Null
            return
        }
        
        # Traiter différents types d'objets
        switch ($data.GetType().Name) {
            # Types simples
            { $_ -in @("String", "Int32", "Int64", "Double", "Decimal", "Boolean", "DateTime", "Guid") } {
                $parentElement.InnerText = $data.ToString()
            }
            
            # Hashtable ou PSCustomObject
            { $_ -in @("Hashtable", "PSCustomObject") } {
                $properties = if ($_ -eq "Hashtable") { $data.Keys } else { $data.PSObject.Properties.Name }
                
                foreach ($propName in $properties) {
                    $propValue = if ($_ -eq "Hashtable") { $data[$propName] } else { $data.$propName }
                    
                    # Créer un élément pour la propriété
                    $propElement = $xmlDoc.CreateElement($propName)
                    $parentElement.AppendChild($propElement) | Out-Null
                    
                    # Convertir la valeur de la propriété de manière récursive
                    $this.ConvertObjectToXml($xmlDoc, $propElement, $propValue)
                }
            }
            
            # Array ou Collection
            { $_ -match "Array|Collection|List" } {
                foreach ($item in $data) {
                    # Créer un élément pour l'item
                    $itemElement = $xmlDoc.CreateElement("item")
                    $parentElement.AppendChild($itemElement) | Out-Null
                    
                    # Convertir l'item de manière récursive
                    $this.ConvertObjectToXml($xmlDoc, $itemElement, $item)
                }
            }
            
            # Type par défaut
            default {
                # Essayer de traiter comme un objet avec des propriétés
                try {
                    foreach ($prop in $data.PSObject.Properties) {
                        # Créer un élément pour la propriété
                        $propElement = $xmlDoc.CreateElement($prop.Name)
                        $parentElement.AppendChild($propElement) | Out-Null
                        
                        # Convertir la valeur de la propriété de manière récursive
                        $this.ConvertObjectToXml($xmlDoc, $propElement, $prop.Value)
                    }
                }
                catch {
                    # Si tout échoue, convertir en chaîne
                    $parentElement.InnerText = $data.ToString()
                }
            }
        }
    }
}

# Fonction pour créer une nouvelle instance de XMLFormatHandler
function New-XMLFormatHandler {
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$XmlSettings,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ValidationSettings,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$GenerationSettings
    )
    
    # Utiliser les paramètres fournis ou les valeurs par défaut
    $xmlSettings = if ($XmlSettings) { $XmlSettings } else { $XMLConfig.DefaultXmlSettings.Clone() }
    $validationSettings = if ($ValidationSettings) { $ValidationSettings } else { $XMLConfig.DefaultValidationSettings.Clone() }
    $generationSettings = if ($GenerationSettings) { $GenerationSettings } else { $XMLConfig.DefaultGenerationSettings.Clone() }
    
    # Créer et retourner une nouvelle instance
    return [XMLFormatHandler]::new($xmlSettings, $validationSettings, $generationSettings)
}

# Fonction pour parser une chaîne XML
function ConvertFrom-Xml {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string]$XmlString,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$XmlSettings,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ValidationSettings
    )
    
    process {
        # Créer un handler XML
        $handler = New-XMLFormatHandler -XmlSettings $XmlSettings -ValidationSettings $ValidationSettings
        
        # Parser la chaîne XML
        return $handler.Parse($XmlString)
    }
}

# Fonction pour convertir un objet en XML
function ConvertTo-Xml {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$GenerationSettings
    )
    
    process {
        # Créer un handler XML
        $handler = New-XMLFormatHandler -GenerationSettings $GenerationSettings
        
        # Générer le XML
        return $handler.Generate($InputObject)
    }
}

# Fonction pour lire un fichier XML
function Import-XmlFile {
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$XmlSettings,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ValidationSettings
    )
    
    # Créer un handler XML
    $handler = New-XMLFormatHandler -XmlSettings $XmlSettings -ValidationSettings $ValidationSettings
    
    # Lire le fichier XML
    return $handler.ReadFromFile($FilePath)
}

# Fonction pour écrire un objet dans un fichier XML
function Export-XmlFile {
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [object]$InputObject,
        
        [Parameter(Mandatory = $true, Position = 1)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$GenerationSettings
    )
    
    process {
        # Créer un handler XML
        $handler = New-XMLFormatHandler -GenerationSettings $GenerationSettings
        
        # Écrire l'objet dans un fichier XML
        $handler.WriteToFile($InputObject, $FilePath)
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-XMLFormatHandler, ConvertFrom-Xml, ConvertTo-Xml, Import-XmlFile, Export-XmlFile
