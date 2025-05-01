# Module manifest for module 'AstNavigator'
@{
    # Script module or binary module file associated with this manifest.
    RootModule        = 'AstNavigator.psm1'

    # Version number of this module.
    ModuleVersion     = '0.1.0'

    # ID used to uniquely identify this module
    GUID              = '8f7a3e2d-5b4c-4a9d-8e7f-1c2d3e4f5a6b'

    # Author of this module
    Author            = 'AST Navigator Team'

    # Company or vendor of this module
    CompanyName       = 'EMAIL_SENDER_1'

    # Copyright statement for this module
    Copyright         = '(c) 2023. All rights reserved.'

    # Description of the functionality provided by this module
    Description       = 'Module pour la navigation et l''analyse des arbres syntaxiques PowerShell (AST)'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        'Invoke-AstTraversalDFS',
        'Invoke-AstTraversalDFS-Simple',
        'Invoke-AstTraversalDFS-Recursive',
        'Invoke-AstTraversalDFS-Enhanced',
        'Invoke-AstTraversalBFS',
        'Invoke-AstTraversalSafe',
        'Find-AstNode',
        'Find-AstNodeByType',
        'Get-AstNodeParent',
        'Get-AstNodeSiblings',
        'Get-AstNodePath',
        'Get-AstNodeDepth',
        'Test-AstNodeIsDescendant',
        'Get-AstNodeComplexity',
        'ConvertTo-AstNodePath'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport   = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData       = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('AST', 'PowerShell', 'Parser', 'Analysis', 'Navigation')

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            # ProjectUri = ''

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''
        }
    }
}
