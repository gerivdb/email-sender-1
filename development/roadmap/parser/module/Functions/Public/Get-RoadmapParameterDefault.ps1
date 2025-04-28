<#
.SYNOPSIS
    RÃ©cupÃ¨re les valeurs par dÃ©faut pour les paramÃ¨tres des fonctions du module RoadmapParser.

.DESCRIPTION
    La fonction Get-RoadmapParameterDefault fournit des valeurs par dÃ©faut pour les paramÃ¨tres
    des fonctions du module RoadmapParser. Elle permet de centraliser la gestion des valeurs
    par dÃ©faut et de les personnaliser selon les besoins.

.PARAMETER ParameterName
    Le nom du paramÃ¨tre pour lequel rÃ©cupÃ©rer la valeur par dÃ©faut.

.PARAMETER FunctionName
    Le nom de la fonction pour laquelle rÃ©cupÃ©rer la valeur par dÃ©faut du paramÃ¨tre.

.PARAMETER ConfigurationPath
    Le chemin vers un fichier de configuration contenant des valeurs par dÃ©faut personnalisÃ©es.
    Si non spÃ©cifiÃ©, les valeurs par dÃ©faut intÃ©grÃ©es seront utilisÃ©es.

.EXAMPLE
    Get-RoadmapParameterDefault -ParameterName "Status" -FunctionName "Select-RoadmapTask"
    RÃ©cupÃ¨re la valeur par dÃ©faut du paramÃ¨tre "Status" pour la fonction "Select-RoadmapTask".

.EXAMPLE
    Get-RoadmapParameterDefault -ParameterName "BlockSize" -FunctionName "ConvertFrom-MarkdownToRoadmapOptimized" -ConfigurationPath "C:\config.json"
    RÃ©cupÃ¨re la valeur par dÃ©faut du paramÃ¨tre "BlockSize" pour la fonction "ConvertFrom-MarkdownToRoadmapOptimized"
    Ã  partir du fichier de configuration spÃ©cifiÃ©.

.OUTPUTS
    La valeur par dÃ©faut du paramÃ¨tre.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-07-10
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

    # Charger la configuration personnalisÃ©e si spÃ©cifiÃ©e
    $customConfig = $null
    if (-not [string]::IsNullOrEmpty($ConfigurationPath) -and (Test-Path -Path $ConfigurationPath)) {
        try {
            $customConfig = Get-Content -Path $ConfigurationPath -Raw | ConvertFrom-Json
        } catch {
            Write-Warning "Impossible de charger la configuration personnalisÃ©e : $_"
        }
    }

    # DÃ©finir les valeurs par dÃ©faut intÃ©grÃ©es
    $defaultValues = @{
        "ConvertFrom-MarkdownToRoadmap" = @{
            # Aucun paramÃ¨tre par dÃ©faut
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
            # Aucun paramÃ¨tre par dÃ©faut
        }
        "Get-TaskDependencies" = @{
            # Aucun paramÃ¨tre par dÃ©faut
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

    # VÃ©rifier si la fonction existe dans les valeurs par dÃ©faut
    if (-not $defaultValues.ContainsKey($FunctionName)) {
        Write-Warning "Aucune valeur par dÃ©faut n'est dÃ©finie pour la fonction '$FunctionName'."
        return $null
    }

    # VÃ©rifier si le paramÃ¨tre existe dans les valeurs par dÃ©faut de la fonction
    if (-not $defaultValues[$FunctionName].ContainsKey($ParameterName)) {
        Write-Warning "Aucune valeur par dÃ©faut n'est dÃ©finie pour le paramÃ¨tre '$ParameterName' de la fonction '$FunctionName'."
        return $null
    }

    # RÃ©cupÃ©rer la valeur par dÃ©faut
    $defaultValue = $defaultValues[$FunctionName][$ParameterName]

    # VÃ©rifier si une valeur personnalisÃ©e existe dans la configuration
    if ($null -ne $customConfig -and 
        $customConfig.PSObject.Properties.Name -contains $FunctionName -and 
        $customConfig.$FunctionName.PSObject.Properties.Name -contains $ParameterName) {
        $defaultValue = $customConfig.$FunctionName.$ParameterName
    }

    return $defaultValue
}
