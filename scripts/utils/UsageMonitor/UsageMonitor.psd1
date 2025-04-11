@{
    # Version du module
    ModuleVersion = '1.0'
    
    # ID utilisé pour identifier de manière unique ce module
    GUID = '8f7e5f3a-9b4e-4c1a-8d5a-7c8e5f3a9b4e'
    
    # Auteur de ce module
    Author = 'Augment Agent'
    
    # Société ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'
    
    # Déclaration de copyright pour ce module
    Copyright = '(c) 2025 Augment Agent. Tous droits réservés.'
    
    # Description de la fonctionnalité fournie par ce module
    Description = 'Module de monitoring et d''analyse comportementale pour les scripts PowerShell.'
    
    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'
    
    # Modules à importer comme modules imbriqués du module spécifié dans RootModule/ModuleToProcess
    NestedModules = @('UsageMonitor.psm1')
    
    # Fonctions à exporter à partir de ce module
    FunctionsToExport = @(
        'Initialize-UsageMonitor',
        'Start-ScriptUsageTracking',
        'Stop-ScriptUsageTracking',
        'Get-ScriptUsageStatistics',
        'Find-ScriptBottlenecks',
        'Save-UsageDatabase'
    )
    
    # Variables à exporter à partir de ce module
    VariablesToExport = @()
    
    # Alias à exporter à partir de ce module
    AliasesToExport = @()
    
    # Cmdlets à exporter à partir de ce module
    CmdletsToExport = @()
    
    # Informations privées
    PrivateData = @{
        PSData = @{
            # Tags appliqués à ce module
            Tags = @('Monitoring', 'Usage', 'Analytics', 'Performance')
            
            # URL vers la page d'accueil de ce projet
            ProjectUri = ''
            
            # URL vers une icône représentant ce module
            IconUri = ''
            
            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module UsageMonitor.'
        }
    }
}
