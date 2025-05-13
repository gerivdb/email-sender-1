@{
    # Version du module
    ModuleVersion = '1.0.0'

    # ID utilisé pour identifier de manière unique ce module
    GUID = '8f7c5e1a-9b4d-4e5f-8c6d-7a8b9c0d1e2f'

    # Auteur de ce module
    Author = 'Augment Agent'

    # Société ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'

    # Copyright pour ce module
    Copyright = '(c) 2025 Augment Agent. Tous droits réservés.'

    # Description de la fonctionnalité fournie par ce module
    Description = 'Framework de test minimal pour les tests unitaires PowerShell.'

    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'

    # Modules qui doivent être importés dans l'environnement global avant l'importation de ce module
    RequiredModules = @('Pester')

    # Fonctions à exporter à partir de ce module
    FunctionsToExport = @(
        'Invoke-TestSetup',
        'New-TestEnvironment',
        'Invoke-TestCleanup'
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
            Tags = @('TestFramework', 'PowerShell', 'Testing', 'Pester')

            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module TestFramework.'
        }
    }
}
