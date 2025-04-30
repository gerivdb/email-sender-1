@{
    # Version du module
    ModuleVersion = '1.0.0'

    # ID utilisé pour identifier de manière unique ce module
    GUID = '45678901-4567-4567-4567-456789012345'

    # Auteur de ce module
    Author = 'EMAIL_SENDER_1'

    # Société ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'

    # Déclaration de copyright pour ce module
    Copyright = '(c) 2025 EMAIL_SENDER_1. Tous droits réservés.'

    # Description de la fonctionnalité fournie par ce module
    Description = 'Module de résolution de dépendances pour le Process Manager.'

    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'

    # Modules à importer comme modules imbriqués du module spécifié dans RootModule/ModuleToProcess
    NestedModules = @()

    # Fonctions à exporter à partir de ce module, pour de meilleures performances, n'utilisez pas de caractères génériques et ne supprimez pas l'entrée, utilisez une table vide si vous n'avez pas de fonctions à exposer
    FunctionsToExport = @(
        'Get-ManagerDependencies',
        'Test-DependenciesAvailability',
        'Resolve-DependencyConflicts',
        'Get-ManagerLoadOrder'
    )

    # Cmdlets à exporter à partir de ce module, pour de meilleures performances, n'utilisez pas de caractères génériques et ne supprimez pas l'entrée, utilisez une table vide si vous n'avez pas de cmdlets à exposer
    CmdletsToExport = @()

    # Variables à exporter à partir de ce module
    VariablesToExport = @()

    # Alias à exporter à partir de ce module, pour de meilleures performances, n'utilisez pas de caractères génériques et ne supprimez pas l'entrée, utilisez une table vide si vous n'avez pas d'alias à exposer
    AliasesToExport = @()

    # Ressources DSC à exporter de ce module
    DscResourcesToExport = @()

    # Liste de tous les modules empaquetés avec ce module
    ModuleList = @()

    # Liste de tous les fichiers empaquetés avec ce module
    FileList = @(
        'DependencyResolver.psm1',
        'DependencyResolver.psd1'
    )

    # Données privées à transmettre au module spécifié dans RootModule/ModuleToProcess. Cela peut également inclure une table de hachage PSData avec des métadonnées de module supplémentaires utilisées par PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags appliqués à ce module. Ils aident à la découverte des modules dans les galeries en ligne.
            Tags = @('ProcessManager', 'Dependency', 'Resolver')

            # URL vers la licence de ce module.
            LicenseUri = ''

            # URL vers le site web principal de ce projet.
            ProjectUri = ''

            # URL vers une icône représentant ce module.
            IconUri = ''

            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module DependencyResolver.'
        }
    }
}
