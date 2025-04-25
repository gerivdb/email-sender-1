#
# Generate-Documentation.ps1
#
# Script to generate documentation for the RoadmapParser module
#

# Get the script path
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path

# Get the module name
$moduleName = "RoadmapParser"

# Get the module path
$modulePath = $scriptPath

# Get the documentation directory
$docsPath = Join-Path -Path $modulePath -ChildPath "docs"

# Create the documentation directory if it doesn't exist
if (-not (Test-Path -Path $docsPath)) {
    New-Item -Path $docsPath -ItemType Directory -Force | Out-Null
}

# Import the module
Import-Module -Name "$modulePath\$moduleName.psd1" -Force

# Get the exported commands
$exportedCommands = Get-Command -Module $moduleName

# Generate the documentation
$moduleDocPath = Join-Path -Path $docsPath -ChildPath "$moduleName.md"
$moduleDoc = "# $moduleName Module`n`n"
$moduleDoc += "## Description`n`n"
$moduleDoc += "$((Get-Module -Name $moduleName).Description)`n`n"
$moduleDoc += "## Commands`n`n"
$moduleDoc += "The following commands are exported by this module:`n`n"
$moduleDoc += "| Name | Type | Synopsis |`n"
$moduleDoc += "| ---- | ---- | -------- |`n"

foreach ($command in $exportedCommands) {
    $help = Get-Help -Name $command.Name -Full
    $synopsis = $help.Synopsis -replace "`r`n", " " -replace "`n", " "
    $moduleDoc += "| $($command.Name) | $($command.CommandType) | $synopsis |`n"

    # Generate documentation for each command
    $commandDocPath = Join-Path -Path $docsPath -ChildPath "$($command.Name).md"
    $commandDoc = "# $($command.Name)`n`n"
    $commandDoc += "## SYNOPSIS`n`n"
    $commandDoc += "$($help.Synopsis)`n`n"
    $commandDoc += "## SYNTAX`n`n"
    $commandDoc += "``````powershell`n"
    $commandDoc += "$($help.Syntax.SyntaxItem | ForEach-Object { $_.ToString() } | Out-String)`n"
    $commandDoc += "``````n`n"
    $commandDoc += "## DESCRIPTION`n`n"
    $commandDoc += "$($help.Description.Text)`n`n"
    $commandDoc += "## PARAMETERS`n"

    foreach ($parameter in $help.Parameters.Parameter) {
        $commandDoc += "`n### -$($parameter.Name)`n`n"
        $commandDoc += "$($parameter.Description.Text)`n`n"
        $commandDoc += "```yaml`n"
        $commandDoc += "Type: $($parameter.Type.Name)`n"
        $commandDoc += "Parameter Sets: $($parameter.ParameterSetName)`n"
        $commandDoc += "Aliases: $($parameter.Aliases)`n`n"
        $commandDoc += "Required: $($parameter.Required)`n"
        $commandDoc += "Position: $($parameter.Position)`n"
        $commandDoc += "Default value: $($parameter.DefaultValue)`n"
        $commandDoc += "Accept pipeline input: $($parameter.PipelineInput)`n"
        $commandDoc += "Accept wildcard characters: $($parameter.Globbing)`n"
        $commandDoc += "```n"
    }

    $commandDoc += "`n## INPUTS`n`n"
    $commandDoc += "$($help.InputTypes.InputType.Type.Name)`n`n"
    $commandDoc += "## OUTPUTS`n`n"
    $commandDoc += "$($help.ReturnValues.ReturnValue.Type.Name)`n`n"
    $commandDoc += "## NOTES`n`n"
    $commandDoc += "$($help.AlertSet.Alert.Text)`n`n"
    $commandDoc += "## EXAMPLES`n"

    foreach ($example in $help.Examples.Example) {
        $commandDoc += "`n### $($example.Title)`n`n"
        $commandDoc += "```powershell`n"
        $commandDoc += "$($example.Code)`n"
        $commandDoc += "```n`n"
        $commandDoc += "$($example.Remarks.Text)`n"
    }

    $commandDoc | Out-File -FilePath $commandDocPath -Encoding utf8
    Write-Host "Generated documentation for $($command.Name)" -ForegroundColor Green
}

$moduleDoc | Out-File -FilePath $moduleDocPath -Encoding utf8
Write-Host "Generated module documentation" -ForegroundColor Green

# Generate the README.md file
$readmePath = Join-Path -Path $modulePath -ChildPath "README.md"
$readme = "# $moduleName`n`n"
$readme += "$((Get-Module -Name $moduleName).Description)`n`n"
$readme += "## Installation`n`n"
$readme += "1. Clone this repository`n"
$readme += "2. Run the Install-Module.ps1 script`n`n"
$readme += "```powershell`n"
$readme += ".\Install-Module.ps1`n"
$readme += "```n`n"
$readme += "## Usage`n`n"
$readme += "```powershell`n"
$readme += "Import-Module $moduleName`n"
$readme += "```n`n"
$readme += "## Commands`n`n"
$readme += "The following commands are exported by this module:`n`n"
$readme += "| Name | Type | Synopsis |`n"
$readme += "| ---- | ---- | -------- |`n"

foreach ($command in $exportedCommands) {
    $help = Get-Help -Name $command.Name -Full
    $synopsis = $help.Synopsis -replace "`r`n", " " -replace "`n", " "
    $readme += "| $($command.Name) | $($command.CommandType) | $synopsis |`n"
}

$readme += "`n## Documentation`n`n"
$readme += "See the [docs](docs) directory for detailed documentation.`n`n"
$readme += "## Uninstallation`n`n"
$readme += "Run the Uninstall-Module.ps1 script`n`n"
$readme += "```powershell`n"
$readme += ".\Uninstall-Module.ps1`n"
$readme += "```n"

$readme | Out-File -FilePath $readmePath -Encoding utf8
Write-Host "Generated README.md" -ForegroundColor Green
