---
to: development/scripts/{{category}}/modules/{{name}}/{{name}}.psd1
---
@{
    # Version du module
    ModuleVersion = '1.0.0'

    # ID utilisé pour identifier de manière unique ce module
    GUID = '<%= h.uuid() %>'

    # Auteur de ce module
    Author = 'Augment Agent'

    # Société ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'

    # Copyright pour ce module
    Copyright = '(c) <%= h.year() %> Augment Agent. Tous droits réservés.'

    # Description de la fonctionnalité fournie par ce module
    Description = 'Module de test pour Hygen'

    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'

    # Nom du module hôte requis par ce module
    # PowerShellHostName = ''

    # Version minimale du module hôte PowerShell requise par ce module
    # PowerShellHostVersion = ''

    # Version minimale de .NET Framework requise par ce module
    # DotNetFrameworkVersion = ''

    # Version minimale de CLR (Common Language Runtime) requise par ce module
    # CLRVersion = ''

    # Architecture de processeur (None, X86, Amd64) requise par ce module
    # ProcessorArchitecture = ''

    # Modules qui doivent être importés dans l'environnement global avant l'importation de ce module
    # RequiredModules = @()

    # Assemblys qui doivent être chargés avant l'importation de ce module
    # RequiredAssemblies = @()

    # Fichiers de script (.ps1) exécutés dans l'environnement de l'appelant avant l'importation de ce module
    # ScriptsToProcess = @()

    # Fichiers de types (.ps1xml) à charger lors de l'importation de ce module
    # TypesToProcess = @()

    # Fichiers de format (.ps1xml) à charger lors de l'importation de ce module
    # FormatsToProcess = @()

    # Modules à importer comme modules imbriqués du module spécifié dans RootModule/ModuleToProcess
    # NestedModules = @()

    # Fonctions à exporter à partir de ce module
    FunctionsToExport = '*'

    # Cmdlets à exporter à partir de ce module
    CmdletsToExport = @()

    # Variables à exporter à partir de ce module
    VariablesToExport = @()

    # Alias à exporter à partir de ce module
    AliasesToExport = @()

    # Ressources DSC à exporter de ce module
    # DscResourcesToExport = @()

    # Liste de tous les modules empaquetés avec ce module
    # ModuleList = @()

    # Liste de tous les fichiers empaquetés avec ce module
    # FileList = @()

    # Données privées à transmettre au module spécifié dans RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags appliqués à ce module, qui aident à la découverte dans les galeries en ligne
            Tags = @('HygenTestModule', 'PowerShell', 'testing')

            # URL vers la licence de ce module
            # LicenseUri = ''

            # URL vers le site web principal de ce projet
            # ProjectUri = ''

            # URL vers une icône représentant ce module
            # IconUri = ''

            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module HygenTestModule.'
        }
    }

    # URI HelpInfo de ce module
    # HelpInfoURI = ''

    # Le préfixe par défaut des commandes exportées depuis ce module (remplace le préfixe DefaultCommandPrefix de ModuleManifest)
    # DefaultCommandPrefix = ''
}

