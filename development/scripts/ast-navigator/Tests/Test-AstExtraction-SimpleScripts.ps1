<#
.SYNOPSIS
    Tests d'extraction AST avec des scripts PowerShell simples.

.DESCRIPTION
    Ce script teste les fonctions d'extraction AST (Get-AstFunctions, Get-AstParameters, 
    Get-AstVariables, Get-AstCommands) avec des scripts PowerShell simples contenant 
    des fonctions basiques.

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

# Fonction pour exÃ©cuter les tests sur un script simple
function Test-SimpleScript {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ScriptName,
        
        [Parameter(Mandatory = $true)]
        [string]$ScriptContent
    )
    
    Write-Host "=== Test du script simple: $ScriptName ===" -ForegroundColor Cyan
    
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
    $functions = Get-AstFunctions -Ast $ast
    $functionsSuccess = Assert-Condition -Condition ($null -ne $functions) -Message "Les fonctions ont Ã©tÃ© extraites avec succÃ¨s"
    
    if ($functionsSuccess -and $functions.Count -gt 0) {
        Write-Host "    Fonctions trouvÃ©es: $($functions.Count)" -ForegroundColor Cyan
        foreach ($function in $functions) {
            Write-Host "      - $($function.Name) (Lignes $($function.StartLine)-$($function.EndLine))" -ForegroundColor Gray
        }
    }
    
    # Test 2: Extraction des paramÃ¨tres
    Write-Host "`n  Test 2: Extraction des paramÃ¨tres" -ForegroundColor Yellow
    $scriptParams = Get-AstParameters -Ast $ast
    $scriptParamsSuccess = Assert-Condition -Condition ($null -ne $scriptParams) -Message "Les paramÃ¨tres du script ont Ã©tÃ© extraits avec succÃ¨s"
    
    if ($scriptParamsSuccess -and $scriptParams.Count -gt 0) {
        Write-Host "    ParamÃ¨tres du script trouvÃ©s: $($scriptParams.Count)" -ForegroundColor Cyan
        foreach ($param in $scriptParams) {
            $defaultValue = if ($param.DefaultValue) { " = $($param.DefaultValue)" } else { "" }
            Write-Host "      - [$($param.Type)]`$$($param.Name)$defaultValue" -ForegroundColor Gray
        }
    }
    
    # Extraction des paramÃ¨tres de fonction (si des fonctions ont Ã©tÃ© trouvÃ©es)
    if ($functionsSuccess -and $functions.Count -gt 0) {
        $firstFunction = $functions[0].Name
        $functionParams = Get-AstParameters -Ast $ast -FunctionName $firstFunction
        $functionParamsSuccess = Assert-Condition -Condition ($null -ne $functionParams) -Message "Les paramÃ¨tres de la fonction '$firstFunction' ont Ã©tÃ© extraits avec succÃ¨s"
        
        if ($functionParamsSuccess -and $functionParams.Count -gt 0) {
            Write-Host "    ParamÃ¨tres de la fonction '$firstFunction' trouvÃ©s: $($functionParams.Count)" -ForegroundColor Cyan
            foreach ($param in $functionParams) {
                $defaultValue = if ($param.DefaultValue) { " = $($param.DefaultValue)" } else { "" }
                Write-Host "      - [$($param.Type)]`$$($param.Name)$defaultValue" -ForegroundColor Gray
            }
        }
    }
    
    # Test 3: Extraction des variables
    Write-Host "`n  Test 3: Extraction des variables" -ForegroundColor Yellow
    $variables = Get-AstVariables -Ast $ast
    $variablesSuccess = Assert-Condition -Condition ($null -ne $variables) -Message "Les variables ont Ã©tÃ© extraites avec succÃ¨s"
    
    if ($variablesSuccess -and $variables.Count -gt 0) {
        Write-Host "    Variables trouvÃ©es: $($variables.Count)" -ForegroundColor Cyan
        $uniqueVars = $variables | Select-Object -Property Name, Scope -Unique | Sort-Object -Property Name
        foreach ($var in $uniqueVars | Select-Object -First 10) {
            $scope = if ($var.Scope) { "$($var.Scope):" } else { "" }
            Write-Host "      - `$$scope$($var.Name)" -ForegroundColor Gray
        }
        if ($uniqueVars.Count -gt 10) {
            Write-Host "      - ... et $($uniqueVars.Count - 10) autres variables" -ForegroundColor Gray
        }
    }
    
    # Test 4: Extraction des commandes
    Write-Host "`n  Test 4: Extraction des commandes" -ForegroundColor Yellow
    $commands = Get-AstCommands -Ast $ast
    $commandsSuccess = Assert-Condition -Condition ($null -ne $commands) -Message "Les commandes ont Ã©tÃ© extraites avec succÃ¨s"
    
    if ($commandsSuccess -and $commands.Count -gt 0) {
        Write-Host "    Commandes trouvÃ©es: $($commands.Count)" -ForegroundColor Cyan
        $uniqueCommands = $commands | Select-Object -Property Name -Unique | Sort-Object -Property Name
        foreach ($cmd in $uniqueCommands | Select-Object -First 10) {
            Write-Host "      - $($cmd.Name)" -ForegroundColor Gray
        }
        if ($uniqueCommands.Count -gt 10) {
            Write-Host "      - ... et $($uniqueCommands.Count - 10) autres commandes" -ForegroundColor Gray
        }
    }
    
    # Test 5: Extraction dÃ©taillÃ©e
    Write-Host "`n  Test 5: Extraction dÃ©taillÃ©e" -ForegroundColor Yellow
    $detailedFunctions = Get-AstFunctions -Ast $ast -Detailed
    $detailedSuccess = Assert-Condition -Condition ($null -ne $detailedFunctions) -Message "Les fonctions dÃ©taillÃ©es ont Ã©tÃ© extraites avec succÃ¨s"
    
    if ($detailedSuccess -and $detailedFunctions.Count -gt 0) {
        $firstDetailedFunction = $detailedFunctions[0]
        Write-Host "    DÃ©tails de la fonction '$($firstDetailedFunction.Name)':" -ForegroundColor Cyan
        Write-Host "      - ParamÃ¨tres: $($firstDetailedFunction.Parameters.Count)" -ForegroundColor Gray
        Write-Host "      - Type de retour: $($firstDetailedFunction.ReturnType)" -ForegroundColor Gray
        Write-Host "      - Lignes: $($firstDetailedFunction.StartLine)-$($firstDetailedFunction.EndLine)" -ForegroundColor Gray
    }
    
    # Test 6: Extraction avec arguments
    Write-Host "`n  Test 6: Extraction avec arguments" -ForegroundColor Yellow
    $commandsWithArgs = Get-AstCommands -Ast $ast -IncludeArguments
    $argsSuccess = Assert-Condition -Condition ($null -ne $commandsWithArgs) -Message "Les commandes avec arguments ont Ã©tÃ© extraites avec succÃ¨s"
    
    if ($argsSuccess -and $commandsWithArgs.Count -gt 0) {
        $commandWithArgs = $commandsWithArgs | Where-Object { $_.Arguments -and $_.Arguments.Count -gt 0 } | Select-Object -First 1
        if ($commandWithArgs) {
            Write-Host "    Arguments de la commande '$($commandWithArgs.Name)':" -ForegroundColor Cyan
            foreach ($arg in $commandWithArgs.Arguments) {
                if ($arg.IsParameter) {
                    Write-Host "      - ParamÃ¨tre: -$($arg.ParameterName) = $($arg.Value)" -ForegroundColor Gray
                } else {
                    Write-Host "      - Valeur: $($arg.Value)" -ForegroundColor Gray
                }
            }
        }
    }
    
    Write-Host "`n=== Fin des tests pour le script: $ScriptName ===" -ForegroundColor Cyan
    return $true
}

# Script simple 1: Script avec fonctions basiques
$simpleScript1 = @'
<#
.SYNOPSIS
    Script simple avec des fonctions basiques.
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

# Script simple 2: Script avec manipulation de donnÃ©es
$simpleScript2 = @'
<#
.SYNOPSIS
    Script simple avec manipulation de donnÃ©es.
#>

# Fonction pour crÃ©er des donnÃ©es de test
function New-TestData {
    param (
        [int]$Count = 10
    )
    
    $data = @()
    for ($i = 1; $i -le $Count; $i++) {
        $data += [PSCustomObject]@{
            ID = $i
            Name = "Item-$i"
            Value = Get-Random -Minimum 1 -Maximum 100
            Created = (Get-Date).AddDays(-$i)
        }
    }
    
    return $data
}

# Fonction pour filtrer les donnÃ©es
function Select-HighValue {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject[]]$Data,
        
        [int]$Threshold = 50
    )
    
    process {
        $Data | Where-Object { $_.Value -gt $Threshold }
    }
}

# Fonction pour formater les donnÃ©es
function Format-DataReport {
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject[]]$Data
    )
    
    begin {
        $report = "ID,Name,Value,Created`n"
    }
    
    process {
        foreach ($item in $Data) {
            $report += "$($item.ID),$($item.Name),$($item.Value),$($item.Created.ToString('yyyy-MM-dd'))`n"
        }
    }
    
    end {
        return $report
    }
}

# GÃ©nÃ©rer des donnÃ©es
$testData = New-TestData -Count 20

# Filtrer et traiter les donnÃ©es
$highValueItems = $testData | Select-HighValue -Threshold 70
$report = $highValueItems | Format-DataReport

# Afficher les rÃ©sultats
Write-Output "Rapport des Ã©lÃ©ments de haute valeur:"
Write-Output $report

# Calculer des statistiques
$stats = $testData | Measure-Object -Property Value -Average -Maximum -Minimum -Sum
Write-Output "Statistiques:"
Write-Output "  Nombre: $($stats.Count)"
Write-Output "  Minimum: $($stats.Minimum)"
Write-Output "  Maximum: $($stats.Maximum)"
Write-Output "  Moyenne: $($stats.Average)"
Write-Output "  Somme: $($stats.Sum)"

# Exporter les donnÃ©es
$exportPath = "C:\Temp\report.csv"
$report | Out-File -FilePath $exportPath -Encoding utf8
Write-Output "Rapport exportÃ© vers: $exportPath"
'@

# Script simple 3: Script avec gestion d'erreurs
$simpleScript3 = @'
<#
.SYNOPSIS
    Script simple avec gestion d'erreurs.
#>

# ParamÃ¨tres du script
param (
    [string]$FilePath = "C:\Temp\test.txt",
    [string]$BackupPath = "C:\Temp\backup"
)

# Variables pour la journalisation
$ErrorActionPreference = "Stop"
$logFile = "C:\Temp\error_log.txt"

# Fonction pour journaliser les erreurs
function Write-ErrorLog {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] $Message"
    
    if ($ErrorRecord) {
        $logEntry += "`nException: $($ErrorRecord.Exception.Message)"
        $logEntry += "`nCatÃ©gorie: $($ErrorRecord.CategoryInfo.Category)"
        $logEntry += "`nCible: $($ErrorRecord.TargetObject)"
        $logEntry += "`nLigne: $($ErrorRecord.InvocationInfo.ScriptLineNumber)"
    }
    
    Add-Content -Path $logFile -Value $logEntry
    Write-Warning $Message
}

# Fonction pour crÃ©er une sauvegarde
function Backup-File {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Source,
        
        [Parameter(Mandatory = $true)]
        [string]$Destination
    )
    
    try {
        # VÃ©rifier si le fichier source existe
        if (-not (Test-Path -Path $Source -PathType Leaf)) {
            throw "Le fichier source n'existe pas: $Source"
        }
        
        # CrÃ©er le dossier de destination s'il n'existe pas
        $destFolder = Split-Path -Path $Destination -Parent
        if (-not (Test-Path -Path $destFolder -PathType Container)) {
            New-Item -Path $destFolder -ItemType Directory -Force | Out-Null
        }
        
        # Copier le fichier
        Copy-Item -Path $Source -Destination $Destination -Force
        Write-Output "Sauvegarde crÃ©Ã©e: $Destination"
        return $true
    }
    catch {
        Write-ErrorLog -Message "Erreur lors de la sauvegarde du fichier: $Source" -ErrorRecord $_
        return $false
    }
}

# Fonction pour traiter un fichier
function Invoke-File {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    try {
        # VÃ©rifier si le fichier existe
        if (-not (Test-Path -Path $Path -PathType Leaf)) {
            throw "Le fichier n'existe pas: $Path"
        }
        
        # Lire le contenu du fichier
        $content = Get-Content -Path $Path -Raw
        
        # Traiter le contenu (exemple: compter les lignes)
        $lineCount = ($content -split "`n").Length
        
        # Ajouter un horodatage
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $newContent = "# TraitÃ© le: $timestamp`n$content"
        
        # Ã‰crire le nouveau contenu
        Set-Content -Path $Path -Value $newContent
        
        return @{
            Success = $true
            LineCount = $lineCount
            Timestamp = $timestamp
        }
    }
    catch {
        Write-ErrorLog -Message "Erreur lors du traitement du fichier: $Path" -ErrorRecord $_
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Programme principal
try {
    Write-Output "DÃ©but du traitement..."
    
    # CrÃ©er une sauvegarde
    $backupFile = Join-Path -Path $BackupPath -ChildPath (Split-Path -Path $FilePath -Leaf)
    $backupSuccess = Backup-File -Source $FilePath -Destination $backupFile
    
    if ($backupSuccess) {
        # Traiter le fichier
        $result = Invoke-File -Path $FilePath
        
        if ($result.Success) {
            Write-Output "Traitement rÃ©ussi!"
            Write-Output "Nombre de lignes: $($result.LineCount)"
            Write-Output "Horodatage: $($result.Timestamp)"
        }
        else {
            Write-Output "Ã‰chec du traitement: $($result.Error)"
        }
    }
    else {
        Write-Output "Ã‰chec de la sauvegarde. Traitement annulÃ©."
    }
}
catch {
    Write-ErrorLog -Message "Erreur non gÃ©rÃ©e dans le programme principal" -ErrorRecord $_
    Write-Output "Une erreur critique s'est produite. Consultez le journal des erreurs: $logFile"
}
finally {
    Write-Output "Fin du traitement."
}
'@

# ExÃ©cuter les tests sur les scripts simples
Test-SimpleScript -ScriptName "Script avec fonctions basiques" -ScriptContent $simpleScript1
Write-Host "`n"
Test-SimpleScript -ScriptName "Script avec manipulation de donnÃ©es" -ScriptContent $simpleScript2
Write-Host "`n"
Test-SimpleScript -ScriptName "Script avec gestion d'erreurs" -ScriptContent $simpleScript3

Write-Host "`n=== Tous les tests sur les scripts simples sont terminÃ©s ===" -ForegroundColor Green

