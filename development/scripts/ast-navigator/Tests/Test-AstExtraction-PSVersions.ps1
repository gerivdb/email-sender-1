<#
.SYNOPSIS
    Tests de compatibilitÃ© des fonctions d'extraction AST avec diffÃ©rentes versions de PowerShell.

.DESCRIPTION
    Ce script teste la compatibilitÃ© des fonctions d'extraction AST (Get-AstFunctions, Get-AstParameters, 
    Get-AstVariables, Get-AstCommands) avec diffÃ©rentes versions de PowerShell.
    
    Note: Ce script doit Ãªtre exÃ©cutÃ© sur un systÃ¨me oÃ¹ plusieurs versions de PowerShell sont installÃ©es.
    Il utilise PowerShell 5.1 (Windows PowerShell) et PowerShell 7+ (PowerShell Core) si disponibles.

.NOTES
    Auteur: AST Navigator Team
    Version: 1.0
    Date de crÃ©ation: 2023-12-15
#>

# Importer les fonctions Ã  tester
. "$PSScriptRoot\..\Public\Get-AstFunctions.ps1"
. "$PSScriptRoot\..\Public\Get-AstParameters.ps1"
. "$PSScriptRoot\..\Public\Get-AstVariables.ps1"
. "$PSScriptRoot\..\Public\Get-AstCommands.ps1"

# Fonction pour vÃ©rifier une condition
function Assert-Condition {
    param (
        [Parameter(Mandatory = $true)]
        [bool]$Condition,
        
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [switch]$Critical
    )
    
    if ($Condition) {
        Write-Host "  [PASSED] $Message" -ForegroundColor Green
        return $true
    } else {
        if ($Critical) {
            Write-Host "  [FAILED] $Message (CRITIQUE)" -ForegroundColor Red
        } else {
            Write-Host "  [FAILED] $Message" -ForegroundColor Red
        }
        return $false
    }
}

# Fonction pour exÃ©cuter les tests de compatibilitÃ©
function Test-PSVersionCompatibility {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptContent,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipPS7Test
    )
    
    # Obtenir la version actuelle de PowerShell
    $currentPSVersion = $PSVersionTable.PSVersion
    Write-Host "Version PowerShell actuelle: $($currentPSVersion.Major).$($currentPSVersion.Minor).$($currentPSVersion.Patch)" -ForegroundColor Cyan
    
    # Tester avec la version actuelle
    Write-Host "`n=== Test avec PowerShell $($currentPSVersion.Major).$($currentPSVersion.Minor) ===" -ForegroundColor Cyan
    
    # Analyser le code avec l'AST
    $tokens = $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($ScriptContent, [ref]$tokens, [ref]$errors)
    
    # VÃ©rifier que l'analyse AST s'est bien dÃ©roulÃ©e
    if (-not (Assert-Condition -Condition ($null -ne $ast) -Message "L'AST a Ã©tÃ© crÃ©Ã© avec succÃ¨s" -Critical)) {
        Write-Host "  Erreurs d'analyse: $errors" -ForegroundColor Red
        return $false
    }
    
    # Test 1: Extraction des fonctions
    Write-Host "`n  Test 1: Extraction des fonctions" -ForegroundColor Yellow
    try {
        $functions = Get-AstFunctions -Ast $ast
        $functionsSuccess = Assert-Condition -Condition ($null -ne $functions) -Message "Les fonctions ont Ã©tÃ© extraites avec succÃ¨s"
        
        if ($functionsSuccess -and $functions.Count -gt 0) {
            Write-Host "    Fonctions trouvÃ©es: $($functions.Count)" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "  [ERREUR] Extraction des fonctions: $_" -ForegroundColor Red
    }
    
    # Test 2: Extraction des paramÃ¨tres
    Write-Host "`n  Test 2: Extraction des paramÃ¨tres" -ForegroundColor Yellow
    try {
        $scriptParams = Get-AstParameters -Ast $ast
        $scriptParamsSuccess = Assert-Condition -Condition ($null -ne $scriptParams) -Message "Les paramÃ¨tres du script ont Ã©tÃ© extraits avec succÃ¨s"
        
        if ($scriptParamsSuccess -and $scriptParams.Count -gt 0) {
            Write-Host "    ParamÃ¨tres du script trouvÃ©s: $($scriptParams.Count)" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "  [ERREUR] Extraction des paramÃ¨tres: $_" -ForegroundColor Red
    }
    
    # Test 3: Extraction des variables
    Write-Host "`n  Test 3: Extraction des variables" -ForegroundColor Yellow
    try {
        $variables = Get-AstVariables -Ast $ast
        $variablesSuccess = Assert-Condition -Condition ($null -ne $variables) -Message "Les variables ont Ã©tÃ© extraites avec succÃ¨s"
        
        if ($variablesSuccess -and $variables.Count -gt 0) {
            Write-Host "    Variables trouvÃ©es: $($variables.Count)" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "  [ERREUR] Extraction des variables: $_" -ForegroundColor Red
    }
    
    # Test 4: Extraction des commandes
    Write-Host "`n  Test 4: Extraction des commandes" -ForegroundColor Yellow
    try {
        $commands = Get-AstCommands -Ast $ast
        $commandsSuccess = Assert-Condition -Condition ($null -ne $commands) -Message "Les commandes ont Ã©tÃ© extraites avec succÃ¨s"
        
        if ($commandsSuccess -and $commands.Count -gt 0) {
            Write-Host "    Commandes trouvÃ©es: $($commands.Count)" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "  [ERREUR] Extraction des commandes: $_" -ForegroundColor Red
    }
    
    # Si PowerShell 7 est disponible et que le test n'est pas ignorÃ©, tester avec PowerShell 7
    if (-not $SkipPS7Test) {
        $pwsh = Get-Command -Name pwsh -ErrorAction SilentlyContinue
        if ($pwsh) {
            Write-Host "`n=== Test avec PowerShell 7+ ===" -ForegroundColor Cyan
            
            # CrÃ©er un fichier temporaire pour le script de test
            $tempScriptPath = [System.IO.Path]::GetTempFileName() + ".ps1"
            $tempResultPath = [System.IO.Path]::GetTempFileName() + ".txt"
            
            try {
                # CrÃ©er le script de test
                $testScript = @"
# Importer les fonctions Ã  tester
. "$PSScriptRoot\..\Public\Get-AstFunctions.ps1"
. "$PSScriptRoot\..\Public\Get-AstParameters.ps1"
. "$PSScriptRoot\..\Public\Get-AstVariables.ps1"
. "$PSScriptRoot\..\Public\Get-AstCommands.ps1"

# Script Ã  analyser
`$scriptContent = @'
$ScriptContent
'@

# Analyser le code avec l'AST
`$tokens = `$errors = `$null
`$ast = [System.Management.Automation.Language.Parser]::ParseInput(`$scriptContent, [ref]`$tokens, [ref]`$errors)

# RÃ©sultats
`$results = [PSCustomObject]@{
    PSVersion = `$PSVersionTable.PSVersion.ToString()
    AstCreated = `$null -ne `$ast
    Functions = `$null
    Parameters = `$null
    Variables = `$null
    Commands = `$null
    Errors = `$errors
}

# Test 1: Extraction des fonctions
try {
    `$functions = Get-AstFunctions -Ast `$ast
    `$results.Functions = @{
        Success = `$true
        Count = `$functions.Count
        Names = `$functions | ForEach-Object { `$_.Name }
    }
}
catch {
    `$results.Functions = @{
        Success = `$false
        Error = `$_.Exception.Message
    }
}

# Test 2: Extraction des paramÃ¨tres
try {
    `$scriptParams = Get-AstParameters -Ast `$ast
    `$results.Parameters = @{
        Success = `$true
        Count = `$scriptParams.Count
        Names = `$scriptParams | ForEach-Object { `$_.Name }
    }
}
catch {
    `$results.Parameters = @{
        Success = `$false
        Error = `$_.Exception.Message
    }
}

# Test 3: Extraction des variables
try {
    `$variables = Get-AstVariables -Ast `$ast
    `$results.Variables = @{
        Success = `$true
        Count = `$variables.Count
        Names = `$variables | Select-Object -First 10 | ForEach-Object { `$_.Name }
    }
}
catch {
    `$results.Variables = @{
        Success = `$false
        Error = `$_.Exception.Message
    }
}

# Test 4: Extraction des commandes
try {
    `$commands = Get-AstCommands -Ast `$ast
    `$results.Commands = @{
        Success = `$true
        Count = `$commands.Count
        Names = `$commands | Select-Object -First 10 | ForEach-Object { `$_.Name }
    }
}
catch {
    `$results.Commands = @{
        Success = `$false
        Error = `$_.Exception.Message
    }
}

# Exporter les rÃ©sultats
`$results | ConvertTo-Json -Depth 5 | Out-File -FilePath "$tempResultPath"
"@
                
                # Ã‰crire le script de test dans le fichier temporaire
                Set-Content -Path $tempScriptPath -Value $testScript
                
                # ExÃ©cuter le script avec PowerShell 7
                $pwshProcess = Start-Process -FilePath $pwsh.Source -ArgumentList "-File `"$tempScriptPath`"" -NoNewWindow -Wait -PassThru
                
                if ($pwshProcess.ExitCode -eq 0) {
                    # Lire les rÃ©sultats
                    $results = Get-Content -Path $tempResultPath -Raw | ConvertFrom-Json
                    
                    Write-Host "  Version PowerShell: $($results.PSVersion)" -ForegroundColor Cyan
                    
                    # Afficher les rÃ©sultats
                    Assert-Condition -Condition $results.AstCreated -Message "L'AST a Ã©tÃ© crÃ©Ã© avec succÃ¨s"
                    
                    Write-Host "`n  Test 1: Extraction des fonctions" -ForegroundColor Yellow
                    if ($results.Functions.Success) {
                        Assert-Condition -Condition $true -Message "Les fonctions ont Ã©tÃ© extraites avec succÃ¨s"
                        Write-Host "    Fonctions trouvÃ©es: $($results.Functions.Count)" -ForegroundColor Cyan
                    }
                    else {
                        Assert-Condition -Condition $false -Message "Erreur lors de l'extraction des fonctions: $($results.Functions.Error)"
                    }
                    
                    Write-Host "`n  Test 2: Extraction des paramÃ¨tres" -ForegroundColor Yellow
                    if ($results.Parameters.Success) {
                        Assert-Condition -Condition $true -Message "Les paramÃ¨tres ont Ã©tÃ© extraits avec succÃ¨s"
                        Write-Host "    ParamÃ¨tres trouvÃ©s: $($results.Parameters.Count)" -ForegroundColor Cyan
                    }
                    else {
                        Assert-Condition -Condition $false -Message "Erreur lors de l'extraction des paramÃ¨tres: $($results.Parameters.Error)"
                    }
                    
                    Write-Host "`n  Test 3: Extraction des variables" -ForegroundColor Yellow
                    if ($results.Variables.Success) {
                        Assert-Condition -Condition $true -Message "Les variables ont Ã©tÃ© extraites avec succÃ¨s"
                        Write-Host "    Variables trouvÃ©es: $($results.Variables.Count)" -ForegroundColor Cyan
                    }
                    else {
                        Assert-Condition -Condition $false -Message "Erreur lors de l'extraction des variables: $($results.Variables.Error)"
                    }
                    
                    Write-Host "`n  Test 4: Extraction des commandes" -ForegroundColor Yellow
                    if ($results.Commands.Success) {
                        Assert-Condition -Condition $true -Message "Les commandes ont Ã©tÃ© extraites avec succÃ¨s"
                        Write-Host "    Commandes trouvÃ©es: $($results.Commands.Count)" -ForegroundColor Cyan
                    }
                    else {
                        Assert-Condition -Condition $false -Message "Erreur lors de l'extraction des commandes: $($results.Commands.Error)"
                    }
                }
                else {
                    Write-Host "  [ERREUR] L'exÃ©cution du script avec PowerShell 7 a Ã©chouÃ© avec le code de sortie $($pwshProcess.ExitCode)" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "  [ERREUR] Erreur lors du test avec PowerShell 7: $_" -ForegroundColor Red
            }
            finally {
                # Supprimer les fichiers temporaires
                if (Test-Path -Path $tempScriptPath) {
                    Remove-Item -Path $tempScriptPath -Force
                }
                if (Test-Path -Path $tempResultPath) {
                    Remove-Item -Path $tempResultPath -Force
                }
            }
        }
        else {
            Write-Host "`n  [INFO] PowerShell 7 (pwsh) n'est pas disponible sur ce systÃ¨me. Test ignorÃ©." -ForegroundColor Yellow
        }
    }
    
    # Si Windows PowerShell est disponible et que nous sommes sur PowerShell 7, tester avec Windows PowerShell
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        $powershell = Get-Command -Name powershell -ErrorAction SilentlyContinue
        if ($powershell) {
            Write-Host "`n=== Test avec Windows PowerShell 5.1 ===" -ForegroundColor Cyan
            
            # CrÃ©er un fichier temporaire pour le script de test
            $tempScriptPath = [System.IO.Path]::GetTempFileName() + ".ps1"
            $tempResultPath = [System.IO.Path]::GetTempFileName() + ".txt"
            
            try {
                # CrÃ©er le script de test (similaire Ã  celui pour PowerShell 7)
                $testScript = @"
# Importer les fonctions Ã  tester
. "$PSScriptRoot\..\Public\Get-AstFunctions.ps1"
. "$PSScriptRoot\..\Public\Get-AstParameters.ps1"
. "$PSScriptRoot\..\Public\Get-AstVariables.ps1"
. "$PSScriptRoot\..\Public\Get-AstCommands.ps1"

# Script Ã  analyser
`$scriptContent = @'
$ScriptContent
'@

# Analyser le code avec l'AST
`$tokens = `$errors = `$null
`$ast = [System.Management.Automation.Language.Parser]::ParseInput(`$scriptContent, [ref]`$tokens, [ref]`$errors)

# RÃ©sultats
`$results = [PSCustomObject]@{
    PSVersion = `$PSVersionTable.PSVersion.ToString()
    AstCreated = `$null -ne `$ast
    Functions = `$null
    Parameters = `$null
    Variables = `$null
    Commands = `$null
    Errors = `$errors
}

# Test 1: Extraction des fonctions
try {
    `$functions = Get-AstFunctions -Ast `$ast
    `$results.Functions = @{
        Success = `$true
        Count = `$functions.Count
        Names = `$functions | ForEach-Object { `$_.Name }
    }
}
catch {
    `$results.Functions = @{
        Success = `$false
        Error = `$_.Exception.Message
    }
}

# Test 2: Extraction des paramÃ¨tres
try {
    `$scriptParams = Get-AstParameters -Ast `$ast
    `$results.Parameters = @{
        Success = `$true
        Count = `$scriptParams.Count
        Names = `$scriptParams | ForEach-Object { `$_.Name }
    }
}
catch {
    `$results.Parameters = @{
        Success = `$false
        Error = `$_.Exception.Message
    }
}

# Test 3: Extraction des variables
try {
    `$variables = Get-AstVariables -Ast `$ast
    `$results.Variables = @{
        Success = `$true
        Count = `$variables.Count
        Names = `$variables | Select-Object -First 10 | ForEach-Object { `$_.Name }
    }
}
catch {
    `$results.Variables = @{
        Success = `$false
        Error = `$_.Exception.Message
    }
}

# Test 4: Extraction des commandes
try {
    `$commands = Get-AstCommands -Ast `$ast
    `$results.Commands = @{
        Success = `$true
        Count = `$commands.Count
        Names = `$commands | Select-Object -First 10 | ForEach-Object { `$_.Name }
    }
}
catch {
    `$results.Commands = @{
        Success = `$false
        Error = `$_.Exception.Message
    }
}

# Exporter les rÃ©sultats
`$results | ConvertTo-Json -Depth 5 | Out-File -FilePath "$tempResultPath"
"@
                
                # Ã‰crire le script de test dans le fichier temporaire
                Set-Content -Path $tempScriptPath -Value $testScript
                
                # ExÃ©cuter le script avec Windows PowerShell
                $powershellProcess = Start-Process -FilePath $powershell.Source -ArgumentList "-File `"$tempScriptPath`"" -NoNewWindow -Wait -PassThru
                
                if ($powershellProcess.ExitCode -eq 0) {
                    # Lire les rÃ©sultats
                    $results = Get-Content -Path $tempResultPath -Raw | ConvertFrom-Json
                    
                    Write-Host "  Version PowerShell: $($results.PSVersion)" -ForegroundColor Cyan
                    
                    # Afficher les rÃ©sultats
                    Assert-Condition -Condition $results.AstCreated -Message "L'AST a Ã©tÃ© crÃ©Ã© avec succÃ¨s"
                    
                    Write-Host "`n  Test 1: Extraction des fonctions" -ForegroundColor Yellow
                    if ($results.Functions.Success) {
                        Assert-Condition -Condition $true -Message "Les fonctions ont Ã©tÃ© extraites avec succÃ¨s"
                        Write-Host "    Fonctions trouvÃ©es: $($results.Functions.Count)" -ForegroundColor Cyan
                    }
                    else {
                        Assert-Condition -Condition $false -Message "Erreur lors de l'extraction des fonctions: $($results.Functions.Error)"
                    }
                    
                    Write-Host "`n  Test 2: Extraction des paramÃ¨tres" -ForegroundColor Yellow
                    if ($results.Parameters.Success) {
                        Assert-Condition -Condition $true -Message "Les paramÃ¨tres ont Ã©tÃ© extraits avec succÃ¨s"
                        Write-Host "    ParamÃ¨tres trouvÃ©s: $($results.Parameters.Count)" -ForegroundColor Cyan
                    }
                    else {
                        Assert-Condition -Condition $false -Message "Erreur lors de l'extraction des paramÃ¨tres: $($results.Parameters.Error)"
                    }
                    
                    Write-Host "`n  Test 3: Extraction des variables" -ForegroundColor Yellow
                    if ($results.Variables.Success) {
                        Assert-Condition -Condition $true -Message "Les variables ont Ã©tÃ© extraites avec succÃ¨s"
                        Write-Host "    Variables trouvÃ©es: $($results.Variables.Count)" -ForegroundColor Cyan
                    }
                    else {
                        Assert-Condition -Condition $false -Message "Erreur lors de l'extraction des variables: $($results.Variables.Error)"
                    }
                    
                    Write-Host "`n  Test 4: Extraction des commandes" -ForegroundColor Yellow
                    if ($results.Commands.Success) {
                        Assert-Condition -Condition $true -Message "Les commandes ont Ã©tÃ© extraites avec succÃ¨s"
                        Write-Host "    Commandes trouvÃ©es: $($results.Commands.Count)" -ForegroundColor Cyan
                    }
                    else {
                        Assert-Condition -Condition $false -Message "Erreur lors de l'extraction des commandes: $($results.Commands.Error)"
                    }
                }
                else {
                    Write-Host "  [ERREUR] L'exÃ©cution du script avec Windows PowerShell a Ã©chouÃ© avec le code de sortie $($powershellProcess.ExitCode)" -ForegroundColor Red
                }
            }
            catch {
                Write-Host "  [ERREUR] Erreur lors du test avec Windows PowerShell: $_" -ForegroundColor Red
            }
            finally {
                # Supprimer les fichiers temporaires
                if (Test-Path -Path $tempScriptPath) {
                    Remove-Item -Path $tempScriptPath -Force
                }
                if (Test-Path -Path $tempResultPath) {
                    Remove-Item -Path $tempResultPath -Force
                }
            }
        }
        else {
            Write-Host "`n  [INFO] Windows PowerShell n'est pas disponible sur ce systÃ¨me. Test ignorÃ©." -ForegroundColor Yellow
        }
    }
    
    Write-Host "`n=== Fin des tests de compatibilitÃ© ===" -ForegroundColor Cyan
    return $true
}

# Script de test pour la compatibilitÃ©
$testScript = @'
<#
.SYNOPSIS
    Script de test pour la compatibilitÃ© avec diffÃ©rentes versions de PowerShell.
#>

# ParamÃ¨tres du script
param (
    [string]$InputPath = "C:\Temp",
    [switch]$Recurse
)

# Variables globales
$Global:LogFile = "C:\Temp\log.txt"
$script:Counter = 0

# Fonction simple sans paramÃ¨tres
function Show-Welcome {
    Write-Host "Bienvenue dans le script de test!"
    $script:Counter++
}

# Fonction avec paramÃ¨tres et valeur de retour
function Get-FileCount {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [switch]$IncludeHidden
    )
    
    $files = Get-ChildItem -Path $Path -File
    if (-not $IncludeHidden) {
        $files = $files | Where-Object { -not $_.Attributes.HasFlag([System.IO.FileAttributes]::Hidden) }
    }
    
    return $files.Count
}

# Fonction avec pipeline
function Format-Size {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [long]$SizeInBytes
    )
    
    process {
        if ($SizeInBytes -lt 1KB) {
            return "$SizeInBytes B"
        }
        elseif ($SizeInBytes -lt 1MB) {
            return "{0:N2} KB" -f ($SizeInBytes / 1KB)
        }
        elseif ($SizeInBytes -lt 1GB) {
            return "{0:N2} MB" -f ($SizeInBytes / 1MB)
        }
        else {
            return "{0:N2} GB" -f ($SizeInBytes / 1GB)
        }
    }
}

# Appel des fonctions
Show-Welcome

$fileCount = Get-FileCount -Path $InputPath -IncludeHidden:$Recurse
Write-Output "Nombre de fichiers: $fileCount"

$totalSize = (Get-ChildItem -Path $InputPath -File | Measure-Object -Property Length -Sum).Sum
$formattedSize = $totalSize | Format-Size
Write-Output "Taille totale: $formattedSize"

# Utilisation de commandes externes
if (Test-Path $InputPath) {
    cmd /c "dir $InputPath /a"
}

# Utilisation de splatting
$params = @{
    Path = $Global:LogFile
    Value = "Script exÃ©cutÃ© le $(Get-Date)"
    Append = $true
}
Add-Content @params
'@

# ExÃ©cuter les tests de compatibilitÃ©
Test-PSVersionCompatibility -ScriptContent $testScript

Write-Host "`n=== Tous les tests de compatibilitÃ© sont terminÃ©s ===" -ForegroundColor Green
