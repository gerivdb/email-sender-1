@{
    RootModule = 'PowerShellFunctionValidator.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a1b2c3d4-e5f6-7890-1234-56789abcdef0'
    Author = 'PowerShell Function Validator Team'
    CompanyName = 'EMAIL_SENDER_1 Project'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'PowerShell function name validator with automatic correction capabilities'
    PowerShellVersion = '5.1'
    
    RequiredModules = @('PowerShellVerbMapping')
    
    FunctionsToExport = @(
        'Test-PowerShellFunctionNames',
        'Repair-PowerShellFunctionNames',
        'Find-PowerShellFiles',
        'Invoke-BulkFunctionValidation',
        'Get-ValidationSummary',
        'Get-ValidationRecommendations'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('PowerShell', 'Validation', 'Testing', 'CodeQuality', 'Functions')
            ProjectUri = ''
            ReleaseNotes = 'Initial release of PowerShell function validator module'
        }
    }
}
