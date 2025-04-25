<#
.SYNOPSIS
    Récupère les valeurs par défaut pour les paramètres des fonctions du module RoadmapParser.

.DESCRIPTION
    La fonction Get-RoadmapParameterDefault fournit des valeurs par défaut pour les paramètres
    des fonctions du module RoadmapParser. Elle permet de centraliser la gestion des valeurs
    par défaut et de les personnaliser selon les besoins.

.PARAMETER ParameterName
    Le nom du paramètre pour lequel récupérer la valeur par défaut.

.PARAMETER FunctionName
    Le nom de la fonction pour laquelle récupérer la valeur par défaut du paramètre.

.PARAMETER ConfigurationPath
    Le chemin vers un fichier de configuration contenant des valeurs par défaut personnalisées.
    Si non spécifié, les valeurs par défaut intégrées seront utilisées.

.EXAMPLE
    Get-RoadmapParameterDefault -ParameterName "Status" -FunctionName "Select-RoadmapTask"
    Récupère la valeur par défaut du paramètre "Status" pour la fonction "Select-RoadmapTask".

.EXAMPLE
    Get-RoadmapParameterDefault -ParameterName "BlockSize" -FunctionName "ConvertFrom-MarkdownToRoadmapOptimized" -ConfigurationPath "C:\config.json"
    Récupère la valeur par défaut du paramètre "BlockSize" pour la fonction "ConvertFrom-MarkdownToRoadmapOptimized"
    à partir du fichier de configuration spécifié.

.OUTPUTS
    La valeur par défaut du paramètre.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-07-10
#>
function Get-RoadmapParameterDefault {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ParameterName,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$FunctionName,

        [Parameter(Mandatory = $false)]
        [string]$ConfigurationPath
    )

    # Charger la configuration personnalisée si spécifiée
    $customConfig = $null
    if (-not [string]::IsNullOrEmpty($ConfigurationPath) -and (Test-Path -Path $ConfigurationPath)) {
        try {
            $customConfig = Get-Content -Path $ConfigurationPath -Raw | ConvertFrom-Json
        } catch {
            Write-Warning "Impossible de charger la configuration personnalisée : $_"
        }
    }

    # Définir les valeurs par défaut intégrées
    $defaultValues = @{
        "ConvertFrom-MarkdownToRoadmap" = @{
            # Aucun paramètre par défaut
        }
        "ConvertFrom-MarkdownToRoadmapExtended" = @{
            "IncludeMetadata" = $false
            "DetectDependencies" = $false
            "ValidateStructure" = $false
        }
        "ConvertFrom-MarkdownToRoadmapOptimized" = @{
            "IncludeMetadata" = $false
            "DetectDependencies" = $false
            "ValidateStructure" = $false
            "BlockSize" = 1000
        }
        "ConvertFrom-MarkdownToRoadmapWithDependencies" = @{
            "IncludeMetadata" = $false
            "DetectDependencies" = $true
            "ValidateStructure" = $false
        }
        "Test-MarkdownFormat" = @{
            "Strict" = $false
        }
        "Edit-RoadmapTask" = @{
            "PassThru" = $false
        }
        "Find-DependencyCycle" = @{
            # Aucun paramètre par défaut
        }
        "Get-TaskDependencies" = @{
            # Aucun paramètre par défaut
        }
        "Export-RoadmapToJson" = @{
            "IncludeMetadata" = $false
            "IncludeDependencies" = $false
            "PrettyPrint" = $false
        }
        "Import-RoadmapFromJson" = @{
            "DetectDependencies" = $false
        }
        "Select-RoadmapTask" = @{
            "Status" = "All"
            "Level" = -1
            "HasDependencies" = $false
            "HasDependentTasks" = $false
            "HasMetadata" = $false
            "IncludeSubTasks" = $false
            "Flatten" = $false
            "Skip" = 0
        }
        "Test-RoadmapParameter" = @{
            "AllowNull" = $false
            "ThrowOnFailure" = $false
        }
    }

    # Vérifier si la fonction existe dans les valeurs par défaut
    if (-not $defaultValues.ContainsKey($FunctionName)) {
        Write-Warning "Aucune valeur par défaut n'est définie pour la fonction '$FunctionName'."
        return $null
    }

    # Vérifier si le paramètre existe dans les valeurs par défaut de la fonction
    if (-not $defaultValues[$FunctionName].ContainsKey($ParameterName)) {
        Write-Warning "Aucune valeur par défaut n'est définie pour le paramètre '$ParameterName' de la fonction '$FunctionName'."
        return $null
    }

    # Récupérer la valeur par défaut
    $defaultValue = $defaultValues[$FunctionName][$ParameterName]

    # Vérifier si une valeur personnalisée existe dans la configuration
    if ($null -ne $customConfig -and 
        $customConfig.PSObject.Properties.Name -contains $FunctionName -and 
        $customConfig.$FunctionName.PSObject.Properties.Name -contains $ParameterName) {
        $defaultValue = $customConfig.$FunctionName.$ParameterName
    }

    return $defaultValue
}
