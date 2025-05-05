@{
    # Version du module
    ModuleVersion = '1.0.0'
    
    # Auteur du module
    Author = 'Process Manager Team'
    
    # Description du module
    Description = 'Module d''extraction d''informations pour le Process Manager'
    
    # Module PowerShell requis
    PowerShellVersion = '5.1'
    
    # Modules Ã  importer en tant que modules imbriquÃ©s
    NestedModules = @('InformationExtractor.psm1')
    
    # Fonctions Ã  exporter
    FunctionsToExport = @(
        'Get-ManagerInformation',
        'Get-AllManagersInformation',
        'Get-ManagersStatistics',
        'Get-ManagerDependencyGraph'
    )
    
    # Variables Ã  exporter
    VariablesToExport = @()
    
    # Alias Ã  exporter
    AliasesToExport = @()
    
    # Informations privÃ©es
    PrivateData = @{
        PSData = @{
            # Tags appliquÃ©s Ã  ce module
            Tags = @('ProcessManager', 'Information', 'Extraction')
            
            # URL du projet
            ProjectUri = ''
            
            # URL de la licence
            LicenseUri = ''
            
            # Notes de publication
            ReleaseNotes = 'Version initiale du module d''extraction d''informations pour le Process Manager'
        }
    }
}
