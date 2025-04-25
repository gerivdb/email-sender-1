# Module manifest for module 'RoadmapParser3'
@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'RoadmapParser3.psm1'
    
    # Version number of this module.
    ModuleVersion = '0.1.0'
    
    # ID used to uniquely identify this module
    GUID = '8c7f9e3d-4a5b-3e7c-8a9a-e7d2f8b7c4d4'
    
    # Author of this module
    Author = 'Roadmap Parser Team'
    
    # Company or vendor of this module
    CompanyName = 'EMAIL_SENDER_1'
    
    # Copyright statement for this module
    Copyright = '(c) 2023. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Module avancé pour parser, manipuler et générer des roadmaps en format markdown'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        # Fonctions de parsing du markdown
        'ConvertFrom-MarkdownToRoadmapTree',
        'Parse-MarkdownTask',
        'Get-MarkdownTaskIndentation',
        'Extract-MarkdownTaskStatus',
        'Extract-MarkdownTaskId',
        'Extract-MarkdownTaskTitle',
        'Extract-MarkdownTaskDescription',
        
        # Fonctions de manipulation de l'arbre
        'New-RoadmapTree',
        'New-RoadmapTask',
        'Add-RoadmapTask',
        'Remove-RoadmapTask',
        'Get-RoadmapTask',
        'Set-RoadmapTaskStatus',
        'Add-RoadmapTaskDependency',
        'Remove-RoadmapTaskDependency',
        'Get-RoadmapTaskDependencies',
        'Get-RoadmapTaskDependents',
        
        # Fonctions d'export et de génération
        'Export-RoadmapTreeToJson',
        'Export-RoadmapTreeToMarkdown',
        'ConvertTo-MarkdownTask',
        'ConvertTo-JsonTask',
        'Import-RoadmapTreeFromJson',
        'Generate-RoadmapReport',
        'Generate-RoadmapStatistics',
        'Generate-RoadmapVisualization',
        
        # Fonctions utilitaires et helpers
        'Test-RoadmapTreeValidity',
        'Test-RoadmapTaskValidity',
        'Find-RoadmapTaskCycles',
        'Get-RoadmapTaskPath',
        'Get-RoadmapTaskLevel',
        'Get-RoadmapTaskChildren',
        'Get-RoadmapTaskParents',
        'Get-RoadmapTasksByStatus',
        'Get-RoadmapTasksByFilter',
        'Get-RoadmapTasksBySearch',
        
        # Fonctions de configuration de la journalisation
        'Set-RoadmapLogLevel',
        'Set-RoadmapLogFile',
        'Set-RoadmapLogToConsole'
    )
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = '*'
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Roadmap', 'Markdown', 'Parser', 'Model', 'Task', 'Project', 'Management')
            
            # A URL to the license for this module.
            # LicenseUri = ''
            
            # A URL to the main website for this project.
            # ProjectUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of RoadmapParser3 module with advanced features'
        }
    }
}
