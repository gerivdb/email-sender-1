@{
    # Version du module
    ModuleVersion = '1.0.0'
    
    # ID utilisÃ© pour identifier de maniÃ¨re unique ce module
    GUID = '8f7c5e1a-9b4d-4f1c-8e5a-6b7c8d9f0e1a'
    
    # Auteur de ce module
    Author = 'EMAIL_SENDER_1 Team'
    
    # SociÃ©tÃ© ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'
    
    # DÃ©claration de copyright pour ce module
    Copyright = '(c) 2023 EMAIL_SENDER_1. Tous droits rÃ©servÃ©s.'
    
    # Description de la fonctionnalitÃ© fournie par ce module
    Description = 'Module pour l''extraction des mÃ©tadonnÃ©es de configuration.'
    
    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'
    
    # Modules Ã  importer comme modules imbriquÃ©s du module spÃ©cifiÃ© dans RootModule/ModuleToProcess
    NestedModules = @()
    
    # Fonctions Ã  exporter Ã  partir de ce module, pour de meilleures performances, n'utilisez pas de caractÃ¨res gÃ©nÃ©riques et ne supprimez pas l'entrÃ©e, utilisez une liste vide si vous n'avez rien Ã  exporter.
    FunctionsToExport = @(
        'Get-ConfigurationFormat',
        'Get-ConfigurationStructure',
        'Get-ConfigurationOptions',
        'Get-ConfigurationDependencies',
        'Get-ConfigurationConstraints'
    )
    
    # Cmdlets Ã  exporter Ã  partir de ce module, pour de meilleures performances, n'utilisez pas de caractÃ¨res gÃ©nÃ©riques et ne supprimez pas l'entrÃ©e, utilisez une liste vide si vous n'avez rien Ã  exporter.
    CmdletsToExport = @()
    
    # Variables Ã  exporter Ã  partir de ce module
    VariablesToExport = @()
    
    # Alias Ã  exporter Ã  partir de ce module, pour de meilleures performances, n'utilisez pas de caractÃ¨res gÃ©nÃ©riques et ne supprimez pas l'entrÃ©e, utilisez une liste vide si vous n'avez rien Ã  exporter.
    AliasesToExport = @()
    
    # Ressources DSC Ã  exporter de ce module
    DscResourcesToExport = @()
    
    # Liste de tous les modules empaquetÃ©s avec ce module
    ModuleList = @()
    
    # Liste de tous les fichiers empaquetÃ©s avec ce module
    FileList = @()
    
    # DonnÃ©es privÃ©es Ã  transmettre au module spÃ©cifiÃ© dans RootModule/ModuleToProcess. Cela peut Ã©galement inclure une table de hachage PSData avec des mÃ©tadonnÃ©es de module supplÃ©mentaires utilisÃ©es par PowerShell.
    PrivateData = @{
        PSData = @{
            # Des balises ont Ã©tÃ© appliquÃ©es Ã  ce module. Elles facilitent la dÃ©couverte des modules dans les galeries en ligne.
            Tags = @('Configuration', 'Metadata', 'Analysis')
            
            # URL vers la licence de ce module.
            LicenseUri = ''
            
            # URL vers le site web principal de ce projet.
            ProjectUri = ''
            
            # URL vers une icÃ´ne reprÃ©sentant ce module.
            IconUri = ''
            
            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module ConfigurationMetadataExtractor.'
        }
    }
    
    # URI HelpInfo de ce module
    HelpInfoURI = ''
    
    # Le prÃ©fixe par dÃ©faut des commandes a Ã©tÃ© exportÃ© Ã  partir de ce module. Remplacez le prÃ©fixe par dÃ©faut Ã  l'aide d'Import-Module -Prefix.
    DefaultCommandPrefix = ''
}
