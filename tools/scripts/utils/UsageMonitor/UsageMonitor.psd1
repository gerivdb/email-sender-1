@{
    # Version du module
    ModuleVersion = '1.0'
    
    # ID utilisÃ© pour identifier de maniÃ¨re unique ce module
    GUID = '8f7e5f3a-9b4e-4c1a-8d5a-7c8e5f3a9b4e'
    
    # Auteur de ce module
    Author = 'Augment Agent'
    
    # SociÃ©tÃ© ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'
    
    # DÃ©claration de copyright pour ce module
    Copyright = '(c) 2025 Augment Agent. Tous droits rÃ©servÃ©s.'
    
    # Description de la fonctionnalitÃ© fournie par ce module
    Description = 'Module de monitoring et d''analyse comportementale pour les scripts PowerShell.'
    
    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'
    
    # Modules Ã  importer comme modules imbriquÃ©s du module spÃ©cifiÃ© dans RootModule/ModuleToProcess
    NestedModules = @('UsageMonitor.psm1')
    
    # Fonctions Ã  exporter Ã  partir de ce module
    FunctionsToExport = @(
        'Initialize-UsageMonitor',
        'Start-ScriptUsageTracking',
        'Stop-ScriptUsageTracking',
        'Get-ScriptUsageStatistics',
        'Find-ScriptBottlenecks',
        'Save-UsageDatabase'
    )
    
    # Variables Ã  exporter Ã  partir de ce module
    VariablesToExport = @()
    
    # Alias Ã  exporter Ã  partir de ce module
    AliasesToExport = @()
    
    # Cmdlets Ã  exporter Ã  partir de ce module
    CmdletsToExport = @()
    
    # Informations privÃ©es
    PrivateData = @{
        PSData = @{
            # Tags appliquÃ©s Ã  ce module
            Tags = @('Monitoring', 'Usage', 'Analytics', 'Performance')
            
            # URL vers la page d'accueil de ce projet
            ProjectUri = ''
            
            # URL vers une icÃ´ne reprÃ©sentant ce module
            IconUri = ''
            
            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module UsageMonitor.'
        }
    }
}
