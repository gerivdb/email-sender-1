# Module manifest for module 'BandwidthSelection'
@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'BandwidthSelection.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = '7e7d4a4a-2a1a-3b1a-1c1a-2a1a3b1a1c1a'
    
    # Author of this module
    Author = 'Augment Code'
    
    # Company or vendor of this module
    CompanyName = 'Augment Code'
    
    # Copyright statement for this module
    Copyright = '(c) 2023 Augment Code. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Module for Bandwidth Selection in Kernel Density Estimation'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @('Get-OptimalBandwidth')
    
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
            Tags = @('Statistics', 'KernelDensity', 'Bandwidth')
            
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
