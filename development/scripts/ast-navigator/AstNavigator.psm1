# AstNavigator.psm1
# Module pour la navigation et l'analyse des arbres syntaxiques PowerShell (AST)

# Importer les fonctions privÃ©es
$PrivateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Fonction privÃ©e chargÃ©e : $($Function.BaseName)"
    } catch {
        Write-Error -Message "Ã‰chec du chargement de la fonction privÃ©e $($Function.FullName): $_"
    }
}

# Importer les fonctions publiques
$PublicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Fonction publique chargÃ©e : $($Function.BaseName)"
    } catch {
        Write-Error -Message "Ã‰chec du chargement de la fonction publique $($Function.FullName): $_"
    }
}

# Exporter les fonctions publiques
$FunctionsToExport = @(
    'Invoke-AstTraversalDFS',
    'Invoke-AstTraversalDFS-Simple',
    'Invoke-AstTraversalDFS-Recursive',
    'Invoke-AstTraversalDFS-Enhanced',
    'Invoke-AstTraversalDFS-Optimized',
    'Invoke-AstTraversalBFS',
    'Invoke-AstTraversalBFSAdvanced',
    'Invoke-AstTraversalSafe',
    'Find-AstNode',
    'Find-AstNodeByType',
    'Get-AstNodeParent',
    'Get-AstNodeSiblings',
    'Get-AstNodePath',
    'Get-AstNodeDepth',
    'Test-AstNodeIsDescendant',
    'Get-AstNodeComplexity',
    'ConvertTo-AstNodePath',
    'Get-AstNodeTypeCount',
    'Get-AstFunctions',
    'Get-AstParameters',
    'Get-AstVariables',
    'Get-AstCommands',
    'Get-AstControlStructures',
    'Get-AstEventHandlers',
    'Optimize-AstExtraction',
    'Clear-AstExtractionCache',
    'Get-AstExtractionCacheStatistics'
)

# Exporter uniquement les fonctions qui existent
$ExistingFunctions = $PublicFunctions.BaseName
$FunctionsToExport = $FunctionsToExport | Where-Object { $ExistingFunctions -contains $_ }

Export-ModuleMember -Function $FunctionsToExport
