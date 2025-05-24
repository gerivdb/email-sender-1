@{
    RootModule = 'PowerShellVerbMapping.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'f8a1b2c3-d4e5-f678-9012-3456789abcde'
    Author = 'PowerShell Function Validator Team'
    CompanyName = 'EMAIL_SENDER_1 Project'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'PowerShell verb mapping module for function name validation and correction'
    PowerShellVersion = '5.1'
    
    FunctionsToExport = @(
        'Get-ApprovedVerbs',
        'Get-VerbMappings',
        'Test-VerbApproved',
        'Get-VerbSuggestion',
        'Add-VerbMapping',
        'Get-VerbMappingStatistics'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('PowerShell', 'Validation', 'BestPractices', 'Functions', 'Verbs')
            ProjectUri = ''
            ReleaseNotes = 'Initial release of PowerShell verb mapping module'
        }
    }
}
