@{
    # Version du module
    ModuleVersion = '1.0.0'

    # ID utilisé pour identifier de manière unique ce module
    GUID = '9e8d6f2b-7c5e-4a3d-9b2c-8f1a0e7d6c5b'

    # Auteur de ce module
    Author = 'Augment Agent'

    # Société ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'

    # Copyright pour ce module
    Copyright = '(c) 2025 Augment Agent. Tous droits réservés.'

    # Description de la fonctionnalité fournie par ce module
    Description = 'Helpers pour les tests unitaires PowerShell.'

    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'

    # Modules qui doivent être importés dans l'environnement global avant l'importation de ce module
    RequiredModules = @('Pester')

    # Fonctions à exporter à partir de ce module
    FunctionsToExport = @(
        'Test-FileContent',
        'Test-JsonContent',
        'Test-XmlContent',
        'Test-CsvContent',
        'Test-ApiResponse',
        'Test-DatabaseQuery'
    )

    # Cmdlets à exporter à partir de ce module
    CmdletsToExport = @()

    # Variables à exporter à partir de ce module
    VariablesToExport = @()

    # Alias à exporter à partir de ce module
    AliasesToExport = @()

    # Données privées à transmettre au module spécifié dans RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags appliqués à ce module, qui aident à la découverte dans les galeries en ligne
            Tags = @('TestHelpers', 'PowerShell', 'Testing', 'Pester')

            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module TestHelpers.'
        }
    }
}
