# Module d'analyse des patterns d'erreurs pour l'extension VS Code

# Importer le module d'analyse des patterns d'erreurs
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\..\..\scripts\maintenance\error-learning\ErrorPatternAnalyzer.psm1"
if (Test-Path -Path $modulePath) {
    Import-Module $modulePath -Force
} else {
    Write-Error "Module ErrorPatternAnalyzer not found at $modulePath"
}

<#
.SYNOPSIS
    Analyse un fichier PowerShell pour détecter les patterns d'erreurs potentiels.
.DESCRIPTION
    Cette fonction analyse un fichier PowerShell pour détecter les patterns d'erreurs potentiels
    en utilisant le module ErrorPatternAnalyzer.
.PARAMETER FilePath
    Chemin du fichier PowerShell à analyser.
.EXAMPLE
    Analyze-ErrorPatterns -FilePath "C:\Scripts\MyScript.ps1"
#>
function Analyze-ErrorPatterns {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Vérifier que le fichier existe
    if (-not (Test-Path -Path $FilePath)) {
        Write-Error "File not found: $FilePath"
        return @()
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $FilePath -Raw
    $lines = $content -split "`r?`n"

    # Initialiser les résultats
    $results = @()

    # Analyser chaque ligne pour détecter les patterns d'erreurs
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        
        # Détecter les patterns d'erreurs courants
        
        # 1. Références nulles
        if ($line -match '\$\w+\.') {
            $match = [regex]::Match($line, '\$(\w+)\.')
            if ($match.Success) {
                $varName = $match.Groups[1].Value
                $results += @{
                    id = "null-reference"
                    lineNumber = $i
                    startColumn = $match.Index
                    endColumn = $match.Index + $match.Length
                    message = "Potential null reference: $varName may be null"
                    severity = "warning"
                    description = "This line accesses a property of $varName without checking if it's null"
                    suggestion = "Add a null check before accessing properties"
                    codeExample = "if (`$$varName -ne `$null) { ... }"
                }
            }
        }
        
        # 2. Index hors limites
        if ($line -match '\$\w+\[\$?\w+\]') {
            $match = [regex]::Match($line, '\$(\w+)\[(\$?\w+)\]')
            if ($match.Success) {
                $arrayName = $match.Groups[1].Value
                $indexName = $match.Groups[2].Value
                $results += @{
                    id = "index-out-of-bounds"
                    lineNumber = $i
                    startColumn = $match.Index
                    endColumn = $match.Index + $match.Length
                    message = "Potential array index out of bounds: $arrayName[$indexName]"
                    severity = "warning"
                    description = "This line accesses an array element without checking the array bounds"
                    suggestion = "Add a bounds check before accessing array elements"
                    codeExample = "if (`$$arrayName.Length -gt $indexName) { ... }"
                }
            }
        }
        
        # 3. Conversion de type
        if ($line -match '\[(\w+(\.\w+)*)\]\$\w+') {
            $match = [regex]::Match($line, '\[(\w+(\.\w+)*)\]\$(\w+)')
            if ($match.Success) {
                $typeName = $match.Groups[1].Value
                $varName = $match.Groups[3].Value
                $results += @{
                    id = "type-conversion"
                    lineNumber = $i
                    startColumn = $match.Index
                    endColumn = $match.Index + $match.Length
                    message = "Potential type conversion error: [$typeName]`$$varName"
                    severity = "warning"
                    description = "This line attempts to convert a variable to a specific type without checking if the conversion is valid"
                    suggestion = "Add a type check before converting"
                    codeExample = "if (`$$varName -as [$typeName]) { ... }"
                }
            }
        }
        
        # 4. Utilisation de variables non initialisées
        if ($line -match '\$\w+' -and $line -notmatch '=') {
            $matches = [regex]::Matches($line, '\$(\w+)')
            foreach ($match in $matches) {
                $varName = $match.Groups[1].Value
                # Vérifier si la variable a été initialisée dans les lignes précédentes
                $initialized = $false
                for ($j = 0; $j -lt $i; $j++) {
                    if ($lines[$j] -match "\`$$varName\s*=") {
                        $initialized = $true
                        break
                    }
                }
                
                if (-not $initialized -and $varName -ne 'null' -and $varName -ne '_' -and $varName -ne 'true' -and $varName -ne 'false') {
                    $results += @{
                        id = "uninitialized-variable"
                        lineNumber = $i
                        startColumn = $match.Index
                        endColumn = $match.Index + $match.Length
                        message = "Potential use of uninitialized variable: $varName"
                        severity = "warning"
                        description = "This line uses a variable that may not have been initialized"
                        suggestion = "Initialize the variable before using it"
                        codeExample = "`$$varName = `$null # or appropriate default value"
                    }
                }
            }
        }
    }

    # Utiliser le module ErrorPatternAnalyzer si disponible
    if (Get-Command -Name "Get-ErrorPatterns" -ErrorAction SilentlyContinue) {
        try {
            $patterns = Get-ErrorPatterns -ScriptContent $content
            foreach ($pattern in $patterns) {
                $results += @{
                    id = $pattern.Id
                    lineNumber = $pattern.LineNumber
                    startColumn = $pattern.StartColumn
                    endColumn = $pattern.EndColumn
                    message = $pattern.Message
                    severity = $pattern.Severity
                    description = $pattern.Description
                    suggestion = $pattern.Suggestion
                    codeExample = $pattern.CodeExample
                }
            }
        } catch {
            Write-Error "Error using ErrorPatternAnalyzer module: $_"
        }
    }

    return $results
}

# Exporter les fonctions
Export-ModuleMember -Function Analyze-ErrorPatterns
