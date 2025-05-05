@{
    # Version du module
    ModuleVersion = '1.0.0'
    
    # Auteur du module
    Author = 'Process Manager Team'
    
    # Description du module
    Description = 'Module de gestion des retours d''information pour le Process Manager'
    
    # Module PowerShell requis
    PowerShellVersion = '5.1'
    
    # Modules Ã  importer en tant que modules imbriquÃ©s
    NestedModules = @('FeedbackManager.psm1')
    
    # Fonctions Ã  exporter
    FunctionsToExport = @()
    
    # Variables Ã  exporter
    VariablesToExport = @()
    
    # Alias Ã  exporter
    AliasesToExport = @()
    
    # Informations privÃ©es
    PrivateData = @{
        PSData = @{
            # Tags appliquÃ©s Ã  ce module
            Tags = @('ProcessManager', 'Feedback', 'Logging')
            
            # URL du projet
            ProjectUri = ''
            
            # URL de la licence
            LicenseUri = ''
            
            # Notes de publication
            ReleaseNotes = 'Version initiale du module de gestion des retours d''information pour le Process Manager'
        }
    }
}
