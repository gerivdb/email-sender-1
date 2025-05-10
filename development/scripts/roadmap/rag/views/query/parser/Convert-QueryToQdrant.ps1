# Convert-QueryToQdrant.ps1
# Script pour convertir une requête du langage personnalisé en requête Qdrant
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$QueryString,
    
    [Parameter(Mandatory = $false)]
    [string]$CollectionName = "roadmap_tasks",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info",
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("Object", "JSON", "Curl")]
    [string]$OutputFormat = "Object",
    
    [Parameter(Mandatory = $false)]
    [switch]$ExecuteQuery,
    
    [Parameter(Mandatory = $false)]
    [string]$QdrantUrl = "http://localhost:6333"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent $rootPath) -ChildPath "utils"
$logModulePath = Join-Path -Path $utilsPath -ChildPath "Write-Log.ps1"

if (Test-Path -Path $logModulePath) {
    . $logModulePath
} else {
    function Write-Log {
        param (
            [string]$Message,
            [string]$Level = "Info"
        )
        
        if ($LogLevel -eq "None") {
            return
        }
        
        $logLevels = @{
            "Error" = 0
            "Warning" = 1
            "Info" = 2
            "Debug" = 3
        }
        
        if ($logLevels[$Level] -le $logLevels[$LogLevel]) {
            $color = switch ($Level) {
                "Error" { "Red" }
                "Warning" { "Yellow" }
                "Info" { "White" }
                "Debug" { "Gray" }
                default { "White" }
            }
            
            Write-Host "[$Level] $Message" -ForegroundColor $color
        }
    }
}

# Importer le parser
$parserPath = Join-Path -Path $scriptPath -ChildPath "Parse-QueryLanguage.ps1"
if (-not (Test-Path -Path $parserPath)) {
    Write-Log "Parser script not found at: $parserPath" -Level "Error"
    exit 1
}

. $parserPath

# Fonction pour convertir un nœud AST en filtre Qdrant
function Convert-ASTNodeToQdrantFilter {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ASTNode]$Node
    )
    
    Write-Log "Converting AST node: $($Node.Type) - $($Node.Value)" -Level "Debug"
    
    switch ($Node.Type) {
        "LogicalExpression" {
            $left = Convert-ASTNodeToQdrantFilter -Node $Node.Children[0]
            $right = Convert-ASTNodeToQdrantFilter -Node $Node.Children[1]
            
            switch ($Node.Value) {
                "And" {
                    return @{
                        must = @($left, $right)
                    }
                }
                "Or" {
                    return @{
                        should = @($left, $right)
                    }
                }
                default {
                    throw "Unknown logical operator: $($Node.Value)"
                }
            }
        }
        "UnaryExpression" {
            $operand = Convert-ASTNodeToQdrantFilter -Node $Node.Children[0]
            
            switch ($Node.Value) {
                "Not" {
                    return @{
                        must_not = @($operand)
                    }
                }
                default {
                    throw "Unknown unary operator: $($Node.Value)"
                }
            }
        }
        "Condition" {
            $field = $Node.Children[0].Value
            $value = $Node.Children[1].Value
            
            # Convertir les valeurs spéciales
            if ($value -eq "true") {
                $value = $true
            } elseif ($value -eq "false") {
                $value = $false
            } elseif ($value -eq "null") {
                $value = $null
            } elseif ($value -match "^\d+$") {
                $value = [int]$value
            } elseif ($value -match "^\d+\.\d+$") {
                $value = [double]$value
            }
            
            switch ($Node.Value) {
                "Equality" {
                    if ($null -eq $value) {
                        return @{
                            is_null = @{
                                key = $field
                            }
                        }
                    } else {
                        return @{
                            key = $field
                            match = @{
                                value = $value
                            }
                        }
                    }
                }
                "Inequality" {
                    if ($null -eq $value) {
                        return @{
                            is_not_null = @{
                                key = $field
                            }
                        }
                    } else {
                        return @{
                            must_not = @(
                                @{
                                    key = $field
                                    match = @{
                                        value = $value
                                    }
                                }
                            )
                        }
                    }
                }
                "GreaterThan" {
                    return @{
                        key = $field
                        range = @{
                            gt = $value
                        }
                    }
                }
                "LessThan" {
                    return @{
                        key = $field
                        range = @{
                            lt = $value
                        }
                    }
                }
                "GreaterThanOrEqual" {
                    return @{
                        key = $field
                        range = @{
                            gte = $value
                        }
                    }
                }
                "LessThanOrEqual" {
                    return @{
                        key = $field
                        range = @{
                            lte = $value
                        }
                    }
                }
                "Contains" {
                    return @{
                        key = $field
                        text_match = @{
                            query = $value
                        }
                    }
                }
                "StartsWith" {
                    return @{
                        key = $field
                        text_match = @{
                            query = "$value*"
                        }
                    }
                }
                "EndsWith" {
                    return @{
                        key = $field
                        text_match = @{
                            query = "*$value"
                        }
                    }
                }
                default {
                    throw "Unknown operator: $($Node.Value)"
                }
            }
        }
        default {
            throw "Unknown node type: $($Node.Type)"
        }
    }
}

# Fonction pour construire la requête Qdrant complète
function New-QdrantQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Filter,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $false)]
        [int]$Limit = 100,
        
        [Parameter(Mandatory = $false)]
        [int]$Offset = 0,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Fields = @("*")
    )
    
    Write-Log "Building Qdrant query for collection: $CollectionName" -Level "Debug"
    
    $query = @{
        collection_name = $CollectionName
        filter = $Filter
        limit = $Limit
        offset = $Offset
        with_payload = $Fields
    }
    
    return $query
}

# Fonction pour exécuter la requête Qdrant
function Invoke-QdrantQuery {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Query,
        
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )
    
    Write-Log "Executing Qdrant query on collection: $CollectionName" -Level "Info"
    
    $endpoint = "$QdrantUrl/collections/$CollectionName/points/scroll"
    $body = $Query | ConvertTo-Json -Depth 10
    
    try {
        $response = Invoke-RestMethod -Uri $endpoint -Method Post -Body $body -ContentType "application/json"
        return $response
    } catch {
        Write-Log "Error executing Qdrant query: $_" -Level "Error"
        throw $_
    }
}

# Fonction pour générer une commande curl
function Get-CurlCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Query,
        
        [Parameter(Mandatory = $true)]
        [string]$QdrantUrl,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName
    )
    
    $endpoint = "$QdrantUrl/collections/$CollectionName/points/scroll"
    $body = $Query | ConvertTo-Json -Depth 10 -Compress
    
    $curlCommand = "curl -X POST `"$endpoint`" -H `"Content-Type: application/json`" -d `'$body`'"
    
    return $curlCommand
}

# Fonction principale pour convertir la requête
function Convert-QueryToQdrant {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$QueryString,
        
        [Parameter(Mandatory = $true)]
        [string]$CollectionName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Object", "JSON", "Curl")]
        [string]$OutputFormat = "Object",
        
        [Parameter(Mandatory = $false)]
        [switch]$ExecuteQuery,
        
        [Parameter(Mandatory = $false)]
        [string]$QdrantUrl = "http://localhost:6333"
    )
    
    Write-Log "Converting query to Qdrant format: $QueryString" -Level "Info"
    
    try {
        # Analyser la requête
        $parseResult = Parse-Query -QueryString $QueryString -ReturnAST
        
        # Convertir l'AST en filtre Qdrant
        $qdrantFilter = Convert-ASTNodeToQdrantFilter -Node $parseResult
        
        # Construire la requête Qdrant complète
        $qdrantQuery = New-QdrantQuery -Filter $qdrantFilter -CollectionName $CollectionName
        
        # Retourner le résultat selon le format demandé
        switch ($OutputFormat) {
            "Object" {
                $result = $qdrantQuery
            }
            "JSON" {
                $result = $qdrantQuery | ConvertTo-Json -Depth 10
            }
            "Curl" {
                $result = Get-CurlCommand -Query $qdrantQuery -QdrantUrl $QdrantUrl -CollectionName $CollectionName
            }
        }
        
        # Exécuter la requête si demandé
        if ($ExecuteQuery) {
            $queryResult = Invoke-QdrantQuery -Query $qdrantQuery -QdrantUrl $QdrantUrl -CollectionName $CollectionName
            return @{
                Query = $result
                Result = $queryResult
            }
        } else {
            return $result
        }
        
    } catch {
        Write-Log "Error converting query: $_" -Level "Error"
        throw $_
    }
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Convert-QueryToQdrant -QueryString $QueryString -CollectionName $CollectionName -OutputFormat $OutputFormat -ExecuteQuery:$ExecuteQuery -QdrantUrl $QdrantUrl
}
