@{
    # Version du module
    ModuleVersion = '1.0.0'
    
    # ID utilisé pour identifier de manière unique ce module
    GUID = '8f7c5e1a-9b4d-4f1c-8e5a-6b7c8d9f0e1a'
    
    # Auteur de ce module
    Author = 'EMAIL_SENDER_1 Team'
    
    # Société ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'
    
    # Déclaration de copyright pour ce module
    Copyright = '(c) 2023 EMAIL_SENDER_1. Tous droits réservés.'
    
    # Description de la fonctionnalité fournie par ce module
    Description = 'Module pour l''extraction des métadonnées de configuration.'
    
    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'
    
    # Modules à importer comme modules imbriqués du module spécifié dans RootModule/ModuleToProcess
    NestedModules = @()
    
    # Fonctions à exporter à partir de ce module, pour de meilleures performances, n'utilisez pas de caractères génériques et ne supprimez pas l'entrée, utilisez une liste vide si vous n'avez rien à exporter.
    FunctionsToExport = @(
        'Get-ConfigurationFormat',
        'Get-ConfigurationStructure',
        'Get-ConfigurationOptions',
        'Get-ConfigurationDependencies',
        'Get-ConfigurationConstraints'
    )
    
    # Cmdlets à exporter à partir de ce module, pour de meilleures performances, n'utilisez pas de caractères génériques et ne supprimez pas l'entrée, utilisez une liste vide si vous n'avez rien à exporter.
    CmdletsToExport = @()
    
    # Variables à exporter à partir de ce module
    VariablesToExport = @()
    
    # Alias à exporter à partir de ce module, pour de meilleures performances, n'utilisez pas de caractères génériques et ne supprimez pas l'entrée, utilisez une liste vide si vous n'avez rien à exporter.
    AliasesToExport = @()
    
    # Ressources DSC à exporter de ce module
    DscResourcesToExport = @()
    
    # Liste de tous les modules empaquetés avec ce module
    ModuleList = @()
    
    # Liste de tous les fichiers empaquetés avec ce module
    FileList = @()
    
    # Données privées à transmettre au module spécifié dans RootModule/ModuleToProcess. Cela peut également inclure une table de hachage PSData avec des métadonnées de module supplémentaires utilisées par PowerShell.
    PrivateData = @{
        PSData = @{
            # Des balises ont été appliquées à ce module. Elles facilitent la découverte des modules dans les galeries en ligne.
            Tags = @('Configuration', 'Metadata', 'Analysis')
            
            # URL vers la licence de ce module.
            LicenseUri = ''
            
            # URL vers le site web principal de ce projet.
            ProjectUri = ''
            
            # URL vers une icône représentant ce module.
            IconUri = ''
            
            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module ConfigurationMetadataExtractor.'
        }
    }
    
    # URI HelpInfo de ce module
    HelpInfoURI = ''
    
    # Le préfixe par défaut des commandes a été exporté à partir de ce module. Remplacez le préfixe par défaut à l'aide d'Import-Module -Prefix.
    DefaultCommandPrefix = ''
}
