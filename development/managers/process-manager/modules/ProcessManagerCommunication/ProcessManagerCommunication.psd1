@{
    # Version du module
    ModuleVersion = '1.0.0'
    
    # Auteur du module
    Author = 'Process Manager Team'
    
    # Description du module
    Description = 'Module de communication avec le Process Manager'
    
    # Module PowerShell requis
    PowerShellVersion = '5.1'
    
    # Modules à importer en tant que modules imbriqués
    NestedModules = @('ProcessManagerCommunication.psm1')
    
    # Fonctions à exporter
    FunctionsToExport = @(
        'Initialize-ProcessManagerCommunication',
        'Send-ProcessManagerCommand',
        'Close-ProcessManagerCommunication',
        'Send-ProcessManagerNotification',
        'Subscribe-ProcessManagerNotifications',
        'Unsubscribe-ProcessManagerNotifications'
    )
    
    # Variables à exporter
    VariablesToExport = @()
    
    # Alias à exporter
    AliasesToExport = @()
    
    # Informations privées
    PrivateData = @{
        PSData = @{
            # Tags appliqués à ce module
            Tags = @('ProcessManager', 'Communication', 'IPC')
            
            # URL du projet
            ProjectUri = ''
            
            # URL de la licence
            LicenseUri = ''
            
            # Notes de publication
            ReleaseNotes = 'Version initiale du module de communication avec le Process Manager'
        }
    }
}
