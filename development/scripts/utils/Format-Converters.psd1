@{
    # Version du module
    ModuleVersion = '2.0.0'
    
    # ID utilisÃ© pour identifier de maniÃ¨re unique ce module
    GUID = '8f7c5e1a-6b4d-4c7e-9f2a-8d5e8b7e3d2a'
    
    # Auteur de ce module
    Author = 'Augment Agent'
    
    # SociÃ©tÃ© ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'
    
    # DÃ©claration de copyright pour ce module
    Copyright = '(c) 2025 EMAIL_SENDER_1. Tous droits rÃ©servÃ©s.'
    
    # Description de la fonctionnalitÃ© fournie par ce module
    Description = 'Module pour la dÃ©tection et la conversion de formats de fichiers.'
    
    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'
    
    # Modules Ã  importer en tant que modules imbriquÃ©s du module spÃ©cifiÃ© dans RootModule/ModuleToProcess
    NestedModules = @()
    
    # Fonctions Ã  exporter Ã  partir de ce module, pour de meilleures performances, n'utilisez pas de caractÃ¨res gÃ©nÃ©riques et ne supprimez pas l'entrÃ©e, utilisez une liste vide si vous n'avez aucune fonction Ã  exporter.
    FunctionsToExport = @(
        'Register-FormatConverter',
        'Get-RegisteredConverters',
        'Detect-FileFormat',
        'Convert-FileFormat',
        'Analyze-FileFormat'
    )
    
    # Cmdlets Ã  exporter Ã  partir de ce module, pour de meilleures performances, n'utilisez pas de caractÃ¨res gÃ©nÃ©riques et ne supprimez pas l'entrÃ©e, utilisez une liste vide si vous n'avez aucune cmdlet Ã  exporter.
    CmdletsToExport = @()
    
    # Variables Ã  exporter Ã  partir de ce module
    VariablesToExport = @()
    
    # Alias Ã  exporter Ã  partir de ce module, pour de meilleures performances, n'utilisez pas de caractÃ¨res gÃ©nÃ©riques et ne supprimez pas l'entrÃ©e, utilisez une liste vide si vous n'avez aucun alias Ã  exporter.
    AliasesToExport = @()
    
    # Informations privÃ©es Ã  transmettre au module spÃ©cifiÃ© dans RootModule/ModuleToProcess. Cela peut Ã©galement contenir une table de hachage PSData avec des mÃ©tadonnÃ©es de module supplÃ©mentaires utilisÃ©es par PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags appliquÃ©s Ã  ce module. Ils aident Ã  la dÃ©couverte de modules dans les galeries en ligne.
            Tags = @('Format', 'Conversion', 'Detection', 'Utility')
            
            # URL vers la licence de ce module.
            LicenseUri = ''
            
            # URL vers le site web principal de ce projet.
            ProjectUri = ''
            
            # URL vers une icÃ´ne reprÃ©sentant ce module.
            IconUri = ''
            
            # Notes de publication de ce module
            ReleaseNotes = 'Version 2.0.0 - Ajout de la dÃ©tection amÃ©liorÃ©e de format avec gestion des cas ambigus.'
        }
    }
}
