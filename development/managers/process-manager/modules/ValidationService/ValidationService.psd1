@{
    # Version du module
    ModuleVersion = '1.0.0'

    # ID utilisÃ© pour identifier de maniÃ¨re unique ce module
    GUID = '34567890-3456-3456-3456-345678901234'

    # Auteur de ce module
    Author = 'EMAIL_SENDER_1'

    # SociÃ©tÃ© ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'

    # DÃ©claration de copyright pour ce module
    Copyright = '(c) 2025 EMAIL_SENDER_1. Tous droits rÃ©servÃ©s.'

    # Description de la fonctionnalitÃ© fournie par ce module
    Description = 'Module de service de validation pour le Process Manager.'

    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'

    # Modules Ã  importer comme modules imbriquÃ©s du module spÃ©cifiÃ© dans RootModule/ModuleToProcess
    NestedModules = @()

    # Fonctions Ã  exporter Ã  partir de ce module, pour de meilleures performances, n'utilisez pas de caractÃ¨res gÃ©nÃ©riques et ne supprimez pas l'entrÃ©e, utilisez une table vide si vous n'avez pas de fonctions Ã  exposer
    FunctionsToExport = @(
        'Test-ManagerValidity',
        'Test-ManagerInterface',
        'Test-ManagerFunctionality'
    )

    # Cmdlets Ã  exporter Ã  partir de ce module, pour de meilleures performances, n'utilisez pas de caractÃ¨res gÃ©nÃ©riques et ne supprimez pas l'entrÃ©e, utilisez une table vide si vous n'avez pas de cmdlets Ã  exposer
    CmdletsToExport = @()

    # Variables Ã  exporter Ã  partir de ce module
    VariablesToExport = @()

    # Alias Ã  exporter Ã  partir de ce module, pour de meilleures performances, n'utilisez pas de caractÃ¨res gÃ©nÃ©riques et ne supprimez pas l'entrÃ©e, utilisez une table vide si vous n'avez pas d'alias Ã  exposer
    AliasesToExport = @()

    # Ressources DSC Ã  exporter de ce module
    DscResourcesToExport = @()

    # Liste de tous les modules empaquetÃ©s avec ce module
    ModuleList = @()

    # Liste de tous les fichiers empaquetÃ©s avec ce module
    FileList = @(
        'ValidationService.psm1',
        'ValidationService.psd1'
    )

    # DonnÃ©es privÃ©es Ã  transmettre au module spÃ©cifiÃ© dans RootModule/ModuleToProcess. Cela peut Ã©galement inclure une table de hachage PSData avec des mÃ©tadonnÃ©es de module supplÃ©mentaires utilisÃ©es par PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags appliquÃ©s Ã  ce module. Ils aident Ã  la dÃ©couverte des modules dans les galeries en ligne.
            Tags = @('ProcessManager', 'Validation', 'Manager')

            # URL vers la licence de ce module.
            LicenseUri = ''

            # URL vers le site web principal de ce projet.
            ProjectUri = ''

            # URL vers une icÃ´ne reprÃ©sentant ce module.
            IconUri = ''

            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module ValidationService.'
        }
    }
}
