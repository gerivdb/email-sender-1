# Module manifest for module 'RoadmapModel'
@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'RoadmapModel2.psm1'
    
    # Version number of this module.
    ModuleVersion = '0.1.0'
    
    # ID used to uniquely identify this module
    GUID = '9b8f7e2d-5c6b-4e8e-9a3a-f8d2e9b7c5d5'
    
    # Author of this module
    Author = 'Roadmap Model Team'
    
    # Company or vendor of this module
    CompanyName = 'EMAIL_SENDER_1'
    
    # Copyright statement for this module
    Copyright = '(c) 2023. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Module pour reprÃ©senter le modÃ¨le objet de la roadmap'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'New-RoadmapTree',
        'New-RoadmapTask',
        'Import-RoadmapTreeFromJson',
        'Export-RoadmapTreeToJson',
        'Export-RoadmapTreeToMarkdown',
        'ConvertFrom-MarkdownToRoadmapTree'
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
            Tags = @('Roadmap', 'Markdown', 'Parser', 'Model')
            
            # A URL to the license for this module.
            # LicenseUri = ''
            
            # A URL to the main website for this project.
            # ProjectUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of RoadmapModel module'
        }
    }
}
