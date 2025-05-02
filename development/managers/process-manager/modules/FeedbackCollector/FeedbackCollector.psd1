@{
    # Version du module
    ModuleVersion = '1.0.0'
    
    # Auteur du module
    Author = 'Process Manager Team'
    
    # Description du module
    Description = 'Module de collecte et d''agrégation des messages de feedback pour le Process Manager'
    
    # Module PowerShell requis
    PowerShellVersion = '5.1'
    
    # Modules à importer en tant que modules imbriqués
    NestedModules = @('FeedbackCollector.psm1')
    
    # Fonctions à exporter
    FunctionsToExport = @(
        'Initialize-FeedbackCollector',
        'Add-MessageToCollection',
        'Invoke-CollectionRotation'
    )
    
    # Variables à exporter
    VariablesToExport = @()
    
    # Alias à exporter
    AliasesToExport = @()
    
    # Informations privées
    PrivateData = @{
        PSData = @{
            # Tags appliqués à ce module
            Tags = @('ProcessManager', 'Feedback', 'Collection', 'Aggregation')
            
            # URL du projet
            ProjectUri = ''
            
            # URL de la licence
            LicenseUri = ''
            
            # Notes de publication
            ReleaseNotes = 'Version initiale du module de collecte et d''agrégation des messages de feedback pour le Process Manager'
        }
    }
}
