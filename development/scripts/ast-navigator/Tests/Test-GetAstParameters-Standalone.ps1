# Script de test autonome pour la fonction Get-AstParameters

# Definir la fonction Get-AstParameters
function Get-AstParameters {
    param (
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Language.Ast]$Ast,
        
        [Parameter(Mandatory = $false)]
        [string]$FunctionName
    )
    
    # Initialiser la liste des parametres
    $parameters = @()
    
    # Si un nom de fonction est specifie, rechercher cette fonction
    if ($FunctionName) {
        $function = $Ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $args[0].Name -eq $FunctionName
        }, $true) | Select-Object -First 1
        
        if ($function) {
            # Extraire les parametres de la fonction
            $paramBlock = $function.Body.ParamBlock
            if ($paramBlock) {
                $parameters = $paramBlock.Parameters
            }
        }
        else {
            Write-Warning "Fonction '$FunctionName' non trouvee."
            return @()
        }
    }
    else {
        # Extraire les parametres du script
        $paramBlock = $Ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.ParamBlockAst]
        }, $false) | Select-Object -First 1
        
        if ($paramBlock) {
            $parameters = $paramBlock.Parameters
        }
    }
    
    # Preparer les resultats
    $results = @()
    
    # Traiter chaque parametre
    foreach ($param in $parameters) {
        # Creer l'objet resultat simple
        $paramInfo = [PSCustomObject]@{
            Name = $param.Name.VariablePath.UserPath
            Type = if ($param.StaticType) { $param.StaticType.Name } else { "object" }
            DefaultValue = if ($param.DefaultValue) { $param.DefaultValue.Extent.Text } else { $null }
        }
        
        $results += $paramInfo
    }
    
    return $results
}

# Creer un script PowerShell de test tres simple
$sampleCode = @'
function Test-Function {
    param (
        [string]$Name,
        [int]$Count = 0
    )
    
    "Hello, $Name!"
}
'@

# Analyser le code avec l'AST
$tokens = $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseInput($sampleCode, [ref]$tokens, [ref]$errors)

# Tester la fonction Get-AstParameters
Write-Host "=== Test de Get-AstParameters ===" -ForegroundColor Cyan
$parameters = Get-AstParameters -Ast $ast -FunctionName "Test-Function"
Write-Host "Nombre de parametres trouves: $($parameters.Count)" -ForegroundColor Yellow
foreach ($param in $parameters) {
    Write-Host "  $($param.Name) ($($param.Type))" -ForegroundColor Green
    if ($param.DefaultValue) {
        Write-Host "    Valeur par defaut: $($param.DefaultValue)" -ForegroundColor Green
    }
}

Write-Host "Test termine avec succes!" -ForegroundColor Green
