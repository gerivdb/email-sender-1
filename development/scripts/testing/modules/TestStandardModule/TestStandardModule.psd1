@{
    # Version du module
    ModuleVersion = '1.0.0'
    
    # ID utilisé pour identifier de manière unique ce module
    GUID = '12345678-1234-1234-1234-123456789012'
    
    # Auteur de ce module
    Author = 'Test User'
    
    # Société ou fournisseur de ce module
    CompanyName = 'EMAIL_SENDER_1'
    
    # Copyright pour ce module
    Copyright = '(c) 2025 Test User. Tous droits réservés.'
    
    # Description de la fonctionnalité fournie par ce module
    Description = 'Module PowerShell standard pour les tests'
    
    # Version minimale du moteur PowerShell requise par ce module
    PowerShellVersion = '5.1'
    
    # Fonctions à exporter à partir de ce module
    FunctionsToExport = '*'
    
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
            Tags = @('TestStandardModule', 'PowerShell', 'testing')
            
            # Notes de publication de ce module
            ReleaseNotes = 'Version initiale du module TestStandardModule.'
        }
    }
}
