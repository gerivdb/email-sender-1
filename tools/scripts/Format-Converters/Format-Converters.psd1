@{
    # Version du module
    ModuleVersion = '2.0.0'
    
    # ID utilisé pour identifier de manière unique ce module
    GUID = '8f7c5e1a-6b4d-4c7e-9f2a-8d5e8b7e3d2a'
    
    # Auteur de ce module
    Author = 'Augment Agent'
    
    # Société ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'
    
    # Déclaration de copyright pour ce module
    Copyright = '(c) 2025 EMAIL_SENDER_1. Tous droits réservés.'
    
    # Description de la fonctionnalité fournie par ce module
    Description = 'Module pour la détection et la conversion de formats de fichiers.'
    
    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'
    
    # Modules à importer en tant que modules imbriqués du module spécifié dans RootModule/ModuleToProcess
    NestedModules = @()
    
    # Fonctions à exporter à partir de ce module, pour de meilleures performances, n'utilisez pas de caractères génériques et ne supprimez pas l'entrée, utilisez une liste vide si vous n'avez aucune fonction à exporter.
    FunctionsToExport = @(
        'Register-FormatConverter',
        'Get-RegisteredConverters',
        'Detect-FileFormat',
        'Convert-FileFormat',
        'Analyze-FileFormat'
    )
    
    # Cmdlets à exporter à partir de ce module, pour de meilleures performances, n'utilisez pas de caractères génériques et ne supprimez pas l'entrée, utilisez une liste vide si vous n'avez aucune cmdlet à exporter.
    CmdletsToExport = @()
    
    # Variables à exporter à partir de ce module
    VariablesToExport = @()
    
    # Alias à exporter à partir de ce module, pour de meilleures performances, n'utilisez pas de caractères génériques et ne supprimez pas l'entrée, utilisez une liste vide si vous n'avez aucun alias à exporter.
    AliasesToExport = @()
    
    # Informations privées à transmettre au module spécifié dans RootModule/ModuleToProcess. Cela peut également contenir une table de hachage PSData avec des métadonnées de module supplémentaires utilisées par PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags appliqués à ce module. Ils aident à la découverte de modules dans les galeries en ligne.
            Tags = @('Format', 'Conversion', 'Detection', 'Utility')
            
            # URL vers la licence de ce module.
            LicenseUri = ''
            
            # URL vers le site web principal de ce projet.
            ProjectUri = ''
            
            # URL vers une icône représentant ce module.
            IconUri = ''
            
            # Notes de publication de ce module
            ReleaseNotes = 'Version 2.0.0 - Ajout de la détection améliorée de format avec gestion des cas ambigus.'
        }
    }
}
