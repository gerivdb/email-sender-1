@{
    # Version du module
    ModuleVersion = '1.0.0'
    
    # ID utilisÃ© pour identifier de maniÃ¨re unique ce module
    GUID = '8f7e5d3a-9b4c-4e1d-8f5a-7c3d9e2b0f5a'
    
    # Auteur de ce module
    Author = 'EMAIL_SENDER_1 Team'
    
    # Description de la fonctionnalitÃ© fournie par ce module
    Description = 'Module pour la gestion des informations extraites'
    
    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'
    
    # Modules Ã  importer en tant que modules imbriquÃ©s
    NestedModules = @('ExtractedInfoModule.psm1')
    
    # Fonctions Ã  exporter Ã  partir de ce module
    FunctionsToExport = @(
        # Fonctions de crÃ©ation
        'New-BaseExtractedInfo',
        'New-ExtractedInfoCollection',
        'New-SerializableExtractedInfo',
        'New-ValidationRule',
        'New-ValidatableExtractedInfo',
        'New-TextExtractedInfo',
        'New-StructuredDataExtractedInfo',
        'New-MediaExtractedInfo',
        
        # Fonctions de conversion
        'ConvertTo-Json',
        'ConvertTo-Xml',
        'ConvertTo-Csv',
        'ConvertTo-Yaml',
        'ConvertFrom-Json',
        'ConvertFrom-Xml',
        'ConvertFrom-Csv',
        'ConvertFrom-Yaml',
        'Convert-Format',
        
        # Fonctions de conversion entre types
        'ConvertTo-TextInfo',
        'ConvertTo-StructuredDataInfo',
        'ConvertTo-MediaInfo',
        'Convert-TextToStructuredData',
        'Convert-StructuredDataToText',
        'Convert-MediaToStructuredData',
        'Convert-StructuredDataToMedia',
        'Convert-TextToMedia',
        'Convert-MediaToText',
        
        # Fonctions de collection
        'Add-ExtractedInfo',
        'Remove-ExtractedInfo',
        'Get-ExtractedInfo',
        'Get-ExtractedInfoStatistics',
        'Export-ExtractedInfoCollection',
        'Import-ExtractedInfoCollection'
    )
    
    # Alias Ã  exporter Ã  partir de ce module
    AliasesToExport = @(
        'nei',
        'tic',
        'sdi',
        'mei'
    )
    
    # Variables privÃ©es Ã  exporter Ã  partir de ce module
    PrivateData = @{
        PSData = @{
            # Tags utilisÃ©s pour dÃ©couvrir ce module
            Tags = @('Extraction', 'Information', 'Data', 'Conversion')
            
            # URL vers la licence de ce module
            LicenseUri = ''
            
            # URL vers le site web principal de ce projet
            ProjectUri = ''
            
            # URL vers une icÃ´ne reprÃ©sentant ce module
            IconUri = ''
            
            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module ExtractedInfo'
        }
    }
}
