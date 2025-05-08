# Module manifest for module 'KernelDensity2D'
@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'KernelDensity2D.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = '8f8e5b5a-3b1a-4c1a-9c1a-3b1a4c1a9c1a'
    
    # Author of this module
    Author = 'Augment Code'
    
    # Company or vendor of this module
    CompanyName = 'Augment Code'
    
    # Copyright statement for this module
    Copyright = '(c) 2023 Augment Code. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Module for 2D Kernel Density Estimation'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @('Get-KernelDensity2D')
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Statistics', 'KernelDensity', '2D')
            
            # A URL to the license for this module.
            LicenseUri = ''
            
            # A URL to the main website for this project.
            ProjectUri = ''
            
            # A URL to an icon representing this module.
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release'
        }
    }
}
