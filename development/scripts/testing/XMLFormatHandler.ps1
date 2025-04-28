# Module de gestion du format XML
# Ce script implÃ©mente les fonctionnalitÃ©s de base pour le support du format XML

# DÃ©finition de l'interface IFormatHandler (pour rÃ©fÃ©rence)
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
    # ParamÃ¨tres par dÃ©faut pour le parsing XML
    DefaultXmlSettings = @{
        IgnoreComments = $true
        IgnoreWhitespace = $true
        IgnoreProcessingInstructions = $true
        MaxCharactersInDocument = 10MB
        ProhibitDtd = $false  # Permet les DTD mais dÃ©sactive les entitÃ©s externes
    }
    
    # ParamÃ¨tres par dÃ©faut pour la validation XML
    DefaultValidationSettings = @{
        EnableSchemaValidation = $false
        SchemaPath = $null
        ValidationEventHandler = $null
    }
    
    # ParamÃ¨tres par dÃ©faut pour la gÃ©nÃ©ration XML
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
    # PropriÃ©tÃ©s
    [hashtable]$XmlSettings
    [hashtable]$ValidationSettings
    [hashtable]$GenerationSettings
    
    # Constructeur par dÃ©faut
    XMLFormatHandler() {
        $this.XmlSettings = $XMLConfig.DefaultXmlSettings.Clone()
        $this.ValidationSettings = $XMLConfig.DefaultValidationSettings.Clone()
        $this.GenerationSettings = $XMLConfig.DefaultGenerationSettings.Clone()
    }
    
    # Constructeur avec paramÃ¨tres
    XMLFormatHandler([hashtable]$xmlSettings, [hashtable]$validationSettings, [hashtable]$generationSettings) {
        $this.XmlSettings = $xmlSettings
        $this.ValidationSettings = $validationSettings
        $this.GenerationSettings = $generationSettings
    }
    
    # MÃ©thode pour vÃ©rifier si ce handler peut gÃ©rer un format donnÃ©
    [bool] CanHandle([string]$formatName) {
        return $formatName -eq "xml" -or $formatName -eq "XML"
    }
    
    # MÃ©thode pour parser une chaÃ®ne XML
    [object] Parse([string]$content) {
        try {
            # CrÃ©er un XmlReaderSettings avec les paramÃ¨tres configurÃ©s
            $readerSettings = New-Object System.Xml.XmlReaderSettings
            $readerSettings.IgnoreComments = $this.XmlSettings.IgnoreComments
            $readerSettings.IgnoreWhitespace = $this.XmlSettings.IgnoreWhitespace
            $readerSettings.IgnoreProcessingInstructions = $this.XmlSettings.IgnoreProcessingInstructions
            $readerSettings.MaxCharactersInDocument = $this.XmlSettings.MaxCharactersInDocument
            $readerSettings.DtdProcessing = if ($this.XmlSettings.ProhibitDtd) { [System.Xml.DtdProcessing]::Prohibit } else { [System.Xml.DtdProcessing]::Parse }
            
            # Configurer la validation si activÃ©e
            if ($this.ValidationSettings.EnableSchemaValidation -and $this.ValidationSettings.SchemaPath) {
                $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
                $schema = New-Object System.Xml.Schema.XmlSchemaSet
                $schema.Add($null, $this.ValidationSettings.SchemaPath) | Out-Null
                $readerSettings.Schemas = $schema
                
                if ($this.ValidationSettings.ValidationEventHandler) {
                    $readerSettings.ValidationEventHandler = $this.ValidationSettings.ValidationEventHandler
                }
            }
            
            # CrÃ©er un StringReader pour la chaÃ®ne XML
            $stringReader = New-Object System.IO.StringReader($content)
            
            # CrÃ©er un XmlReader avec les paramÃ¨tres configurÃ©s
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
    
    # MÃ©thode pour parser un flux XML
    [object] Parse([System.IO.Stream]$stream) {
        try {
            # CrÃ©er un XmlReaderSettings avec les paramÃ¨tres configurÃ©s
            $readerSettings = New-Object System.Xml.XmlReaderSettings
            $readerSettings.IgnoreComments = $this.XmlSettings.IgnoreComments
            $readerSettings.IgnoreWhitespace = $this.XmlSettings.IgnoreWhitespace
            $readerSettings.IgnoreProcessingInstructions = $this.XmlSettings.IgnoreProcessingInstructions
            $readerSettings.MaxCharactersInDocument = $this.XmlSettings.MaxCharactersInDocument
            $readerSettings.DtdProcessing = if ($this.XmlSettings.ProhibitDtd) { [System.Xml.DtdProcessing]::Prohibit } else { [System.Xml.DtdProcessing]::Parse }
            
            # Configurer la validation si activÃ©e
            if ($this.ValidationSettings.EnableSchemaValidation -and $this.ValidationSettings.SchemaPath) {
                $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
                $schema = New-Object System.Xml.Schema.XmlSchemaSet
                $schema.Add($null, $this.ValidationSettings.SchemaPath) | Out-Null
                $readerSettings.Schemas = $schema
                
                if ($this.ValidationSettings.ValidationEventHandler) {
                    $readerSettings.ValidationEventHandler = $this.ValidationSettings.ValidationEventHandler
                }
            }
            
            # CrÃ©er un XmlReader avec les paramÃ¨tres configurÃ©s
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
    
    # MÃ©thode pour gÃ©nÃ©rer une chaÃ®ne XML Ã  partir d'un objet
    [string] Generate([object]$data) {
        try {
            # VÃ©rifier si l'objet est dÃ©jÃ  un XmlDocument
            if ($data -is [System.Xml.XmlDocument]) {
                $xmlDoc = $data
            }
            # Sinon, convertir l'objet en XML
            else {
                $xmlDoc = New-Object System.Xml.XmlDocument
                $rootElement = $xmlDoc.CreateElement("root")
                $xmlDoc.AppendChild($rootElement) | Out-Null
                
                # Convertir l'objet en XML de maniÃ¨re rÃ©cursive
                $this.ConvertObjectToXml($xmlDoc, $rootElement, $data)
            }
            
            # CrÃ©er un StringWriter pour stocker la sortie
            $stringWriter = New-Object System.IO.StringWriter
            
            # CrÃ©er un XmlWriterSettings avec les paramÃ¨tres configurÃ©s
            $writerSettings = New-Object System.Xml.XmlWriterSettings
            $writerSettings.Indent = $this.GenerationSettings.Indent
            $writerSettings.IndentChars = $this.GenerationSettings.IndentChars
            $writerSettings.NewLineOnAttributes = $this.GenerationSettings.NewLineOnAttributes
            $writerSettings.OmitXmlDeclaration = $this.GenerationSettings.OmitXmlDeclaration
            $writerSettings.Encoding = [System.Text.Encoding]::GetEncoding($this.GenerationSettings.Encoding)
            
            # CrÃ©er un XmlWriter avec les paramÃ¨tres configurÃ©s
            $xmlWriter = [System.Xml.XmlWriter]::Create($stringWriter, $writerSettings)
            
            # Ã‰crire le document XML
            $xmlDoc.WriteTo($xmlWriter)
            
            # Fermer le writer
            $xmlWriter.Close()
            $stringWriter.Close()
            
            return $stringWriter.ToString()
        }
        catch {
            Write-Error "Erreur lors de la gÃ©nÃ©ration XML: $_"
            throw
        }
    }
    
    # MÃ©thode pour Ã©crire un objet XML dans un fichier
    [void] WriteToFile([object]$data, [string]$filePath) {
        try {
            # VÃ©rifier si l'objet est dÃ©jÃ  un XmlDocument
            if ($data -is [System.Xml.XmlDocument]) {
                $xmlDoc = $data
            }
            # Sinon, convertir l'objet en XML
            else {
                $xmlDoc = New-Object System.Xml.XmlDocument
                $rootElement = $xmlDoc.CreateElement("root")
                $xmlDoc.AppendChild($rootElement) | Out-Null
                
                # Convertir l'objet en XML de maniÃ¨re rÃ©cursive
                $this.ConvertObjectToXml($xmlDoc, $rootElement, $data)
            }
            
            # CrÃ©er un XmlWriterSettings avec les paramÃ¨tres configurÃ©s
            $writerSettings = New-Object System.Xml.XmlWriterSettings
            $writerSettings.Indent = $this.GenerationSettings.Indent
            $writerSettings.IndentChars = $this.GenerationSettings.IndentChars
            $writerSettings.NewLineOnAttributes = $this.GenerationSettings.NewLineOnAttributes
            $writerSettings.OmitXmlDeclaration = $this.GenerationSettings.OmitXmlDeclaration
            $writerSettings.Encoding = [System.Text.Encoding]::GetEncoding($this.GenerationSettings.Encoding)
            
            # CrÃ©er un XmlWriter avec les paramÃ¨tres configurÃ©s
            $xmlWriter = [System.Xml.XmlWriter]::Create($filePath, $writerSettings)
            
            # Ã‰crire le document XML
            $xmlDoc.WriteTo($xmlWriter)
            
            # Fermer le writer
            $xmlWriter.Close()
        }
        catch {
            Write-Error "Erreur lors de l'Ã©criture du fichier XML: $_"
            throw
        }
    }
    
    # MÃ©thode pour lire un fichier XML
    [object] ReadFromFile([string]$filePath) {
        try {
            # VÃ©rifier si le fichier existe
            if (-not (Test-Path -Path $filePath)) {
                throw "Le fichier XML n'existe pas: $filePath"
            }
            
            # CrÃ©er un XmlReaderSettings avec les paramÃ¨tres configurÃ©s
            $readerSettings = New-Object System.Xml.XmlReaderSettings
            $readerSettings.IgnoreComments = $this.XmlSettings.IgnoreComments
            $readerSettings.IgnoreWhitespace = $this.XmlSettings.IgnoreWhitespace
            $readerSettings.IgnoreProcessingInstructions = $this.XmlSettings.IgnoreProcessingInstructions
            $readerSettings.MaxCharactersInDocument = $this.XmlSettings.MaxCharactersInDocument
            $readerSettings.DtdProcessing = if ($this.XmlSettings.ProhibitDtd) { [System.Xml.DtdProcessing]::Prohibit } else { [System.Xml.DtdProcessing]::Parse }
            
            # Configurer la validation si activÃ©e
            if ($this.ValidationSettings.EnableSchemaValidation -and $this.ValidationSettings.SchemaPath) {
                $readerSettings.ValidationType = [System.Xml.ValidationType]::Schema
                $schema = New-Object System.Xml.Schema.XmlSchemaSet
                $schema.Add($null, $this.ValidationSettings.SchemaPath) | Out-Null
                $readerSettings.Schemas = $schema
                
                if ($this.ValidationSettings.ValidationEventHandler) {
                    $readerSettings.ValidationEventHandler = $this.ValidationSettings.ValidationEventHandler
                }
            }
            
            # CrÃ©er un XmlReader avec les paramÃ¨tres configurÃ©s
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
    
    # MÃ©thode privÃ©e pour convertir un objet en XML de maniÃ¨re rÃ©cursive
    hidden [void] ConvertObjectToXml([System.Xml.XmlDocument]$xmlDoc, [System.Xml.XmlElement]$parentElement, [object]$data) {
        # Si l'objet est null, ajouter un attribut xsi:nil="true"
        if ($null -eq $data) {
            $nilAttribute = $xmlDoc.CreateAttribute("xsi", "nil", "http://www.w3.org/2001/XMLSchema-instance")
            $nilAttribute.Value = "true"
            $parentElement.Attributes.Append($nilAttribute) | Out-Null
            return
        }
        
        # Traiter diffÃ©rents types d'objets
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
                    
                    # CrÃ©er un Ã©lÃ©ment pour la propriÃ©tÃ©
                    $propElement = $xmlDoc.CreateElement($propName)
                    $parentElement.AppendChild($propElement) | Out-Null
                    
                    # Convertir la valeur de la propriÃ©tÃ© de maniÃ¨re rÃ©cursive
                    $this.ConvertObjectToXml($xmlDoc, $propElement, $propValue)
                }
            }
            
            # Array ou Collection
            { $_ -match "Array|Collection|List" } {
                foreach ($item in $data) {
                    # CrÃ©er un Ã©lÃ©ment pour l'item
                    $itemElement = $xmlDoc.CreateElement("item")
                    $parentElement.AppendChild($itemElement) | Out-Null
                    
                    # Convertir l'item de maniÃ¨re rÃ©cursive
                    $this.ConvertObjectToXml($xmlDoc, $itemElement, $item)
                }
            }
            
            # Type par dÃ©faut
            default {
                # Essayer de traiter comme un objet avec des propriÃ©tÃ©s
                try {
                    foreach ($prop in $data.PSObject.Properties) {
                        # CrÃ©er un Ã©lÃ©ment pour la propriÃ©tÃ©
                        $propElement = $xmlDoc.CreateElement($prop.Name)
                        $parentElement.AppendChild($propElement) | Out-Null
                        
                        # Convertir la valeur de la propriÃ©tÃ© de maniÃ¨re rÃ©cursive
                        $this.ConvertObjectToXml($xmlDoc, $propElement, $prop.Value)
                    }
                }
                catch {
                    # Si tout Ã©choue, convertir en chaÃ®ne
                    $parentElement.InnerText = $data.ToString()
                }
            }
        }
    }
}

# Fonction pour crÃ©er une nouvelle instance de XMLFormatHandler
function New-XMLFormatHandler {
    param (
        [Parameter(Mandatory = $false)]
        [hashtable]$XmlSettings,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$ValidationSettings,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$GenerationSettings
    )
    
    # Utiliser les paramÃ¨tres fournis ou les valeurs par dÃ©faut
    $xmlSettings = if ($XmlSettings) { $XmlSettings } else { $XMLConfig.DefaultXmlSettings.Clone() }
    $validationSettings = if ($ValidationSettings) { $ValidationSettings } else { $XMLConfig.DefaultValidationSettings.Clone() }
    $generationSettings = if ($GenerationSettings) { $GenerationSettings } else { $XMLConfig.DefaultGenerationSettings.Clone() }
    
    # CrÃ©er et retourner une nouvelle instance
    return [XMLFormatHandler]::new($xmlSettings, $validationSettings, $generationSettings)
}

# Fonction pour parser une chaÃ®ne XML
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
        # CrÃ©er un handler XML
        $handler = New-XMLFormatHandler -XmlSettings $XmlSettings -ValidationSettings $ValidationSettings
        
        # Parser la chaÃ®ne XML
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
        # CrÃ©er un handler XML
        $handler = New-XMLFormatHandler -GenerationSettings $GenerationSettings
        
        # GÃ©nÃ©rer le XML
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
    
    # CrÃ©er un handler XML
    $handler = New-XMLFormatHandler -XmlSettings $XmlSettings -ValidationSettings $ValidationSettings
    
    # Lire le fichier XML
    return $handler.ReadFromFile($FilePath)
}

# Fonction pour Ã©crire un objet dans un fichier XML
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
        # CrÃ©er un handler XML
        $handler = New-XMLFormatHandler -GenerationSettings $GenerationSettings
        
        # Ã‰crire l'objet dans un fichier XML
        $handler.WriteToFile($InputObject, $FilePath)
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-XMLFormatHandler, ConvertFrom-Xml, ConvertTo-Xml, Import-XmlFile, Export-XmlFile
