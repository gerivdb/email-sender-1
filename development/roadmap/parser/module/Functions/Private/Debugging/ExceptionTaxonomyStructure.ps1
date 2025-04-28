<#
.SYNOPSIS
    DÃ©finit la structure de donnÃ©es pour la taxonomie des exceptions PowerShell.

.DESCRIPTION
    Ce script dÃ©finit les classes et fonctions nÃ©cessaires pour reprÃ©senter et manipuler
    la taxonomie des exceptions PowerShell. Il identifie les informations essentielles
    Ã  stocker pour chaque type d'exception et Ã©tablit les relations entre elles.

.NOTES
    Version:        1.0
    Author:         Augment Code
    Creation Date:  2023-06-15
#>

#Requires -Version 5.1

# Classe reprÃ©sentant une exception dans la taxonomie
class ExceptionInfo {
    # Informations d'identification
    [string]$TypeName                # Nom complet du type d'exception (ex: System.ArgumentException)
    [string]$ShortName               # Nom court de l'exception (ex: ArgumentException)
    [string]$Namespace               # Namespace de l'exception (ex: System)
    [guid]$Id                        # Identifiant unique pour cette exception dans la taxonomie

    # Informations de classification
    [string]$Category                # CatÃ©gorie principale (ex: Argument, IO, Security)
    [string]$Severity                # SÃ©vÃ©ritÃ© (ex: Critical, Error, Warning)
    [string[]]$Tags                  # Tags pour la recherche et le filtrage
    [bool]$IsPowerShellSpecific      # Indique si l'exception est spÃ©cifique Ã  PowerShell

    # Informations de hiÃ©rarchie
    [string]$ParentType              # Type parent dans la hiÃ©rarchie d'hÃ©ritage
    [string[]]$ChildTypes            # Types enfants dans la hiÃ©rarchie d'hÃ©ritage
    [int]$HierarchyLevel             # Niveau dans la hiÃ©rarchie (0 = System.Exception)

    # Informations de diagnostic
    [string]$DefaultMessage          # Message d'erreur par dÃ©faut ou modÃ¨le
    [string]$ErrorCategory           # CatÃ©gorie d'erreur PowerShell associÃ©e
    [string]$ErrorId                 # ID d'erreur PowerShell associÃ© (si applicable)
    [string]$CommonCause             # Cause commune de cette exception
    [string[]]$PossibleCauses        # Liste des causes possibles
    [string[]]$PreventionTips        # Conseils pour Ã©viter cette exception

    # Informations de correction
    [string[]]$ResolutionSteps       # Ã‰tapes pour rÃ©soudre cette exception
    [string]$CodeExample             # Exemple de code qui peut gÃ©nÃ©rer cette exception
    [string]$FixExample              # Exemple de code pour corriger l'exception

    # Informations de contexte
    [string[]]$RelatedCmdlets        # Cmdlets qui peuvent gÃ©nÃ©rer cette exception
    [string[]]$RelatedModules        # Modules qui peuvent gÃ©nÃ©rer cette exception
    [string[]]$RelatedExceptions     # Exceptions similaires ou liÃ©es

    # Informations de documentation
    [string]$DocumentationUrl        # URL vers la documentation officielle
    [string]$AdditionalNotes         # Notes supplÃ©mentaires
    [datetime]$LastUpdated           # Date de derniÃ¨re mise Ã  jour de cette entrÃ©e

    # Constructeur minimal
    ExceptionInfo([string]$typeName) {
        $this.TypeName = $typeName
        $this.ShortName = $typeName.Split('.')[-1]
        $this.Namespace = $typeName.Substring(0, $typeName.LastIndexOf('.'))
        $this.Id = [guid]::NewGuid()
        $this.LastUpdated = [datetime]::Now
    }

    # Constructeur complet
    ExceptionInfo(
        [string]$typeName,
        [string]$category,
        [string]$severity,
        [string[]]$tags,
        [bool]$isPowerShellSpecific,
        [string]$parentType,
        [string]$defaultMessage,
        [string]$errorCategory,
        [string[]]$possibleCauses,
        [string[]]$resolutionSteps
    ) {
        $this.TypeName = $typeName
        $this.ShortName = $typeName.Split('.')[-1]
        $this.Namespace = $typeName.Substring(0, $typeName.LastIndexOf('.'))
        $this.Id = [guid]::NewGuid()
        $this.Category = $category
        $this.Severity = $severity
        $this.Tags = $tags
        $this.IsPowerShellSpecific = $isPowerShellSpecific
        $this.ParentType = $parentType
        $this.DefaultMessage = $defaultMessage
        $this.ErrorCategory = $errorCategory
        $this.PossibleCauses = $possibleCauses
        $this.ResolutionSteps = $resolutionSteps
        $this.LastUpdated = [datetime]::Now
    }

    # MÃ©thode pour obtenir une reprÃ©sentation textuelle de l'exception
    [string] ToString() {
        return "$($this.TypeName) [$($this.Category)] - $($this.DefaultMessage)"
    }
}

# Classe reprÃ©sentant la taxonomie complÃ¨te des exceptions
class ExceptionTaxonomy {
    [hashtable]$Exceptions = @{}     # Table de hachage des exceptions par TypeName
    [hashtable]$Categories = @{}     # Table de hachage des exceptions par catÃ©gorie
    [hashtable]$Tags = @{}           # Table de hachage des exceptions par tag
    [hashtable]$Modules = @{}        # Table de hachage des exceptions par module
    [hashtable]$Cmdlets = @{}        # Table de hachage des exceptions par cmdlet
    [datetime]$LastUpdated           # Date de derniÃ¨re mise Ã  jour de la taxonomie

    # Constructeur
    ExceptionTaxonomy() {
        $this.LastUpdated = [datetime]::Now
    }

    # MÃ©thode pour ajouter une exception Ã  la taxonomie
    [void] AddException([ExceptionInfo]$exception) {
        # Ajouter Ã  la table des exceptions
        $this.Exceptions[$exception.TypeName] = $exception

        # Ajouter Ã  la table des catÃ©gories
        if (-not [string]::IsNullOrEmpty($exception.Category)) {
            if (-not $this.Categories.ContainsKey($exception.Category)) {
                $this.Categories[$exception.Category] = @()
            }
            $this.Categories[$exception.Category] += $exception
        }

        # Ajouter Ã  la table des tags
        foreach ($tag in $exception.Tags) {
            if (-not $this.Tags.ContainsKey($tag)) {
                $this.Tags[$tag] = @()
            }
            $this.Tags[$tag] += $exception
        }

        # Ajouter Ã  la table des modules
        foreach ($module in $exception.RelatedModules) {
            if (-not $this.Modules.ContainsKey($module)) {
                $this.Modules[$module] = @()
            }
            $this.Modules[$module] += $exception
        }

        # Ajouter Ã  la table des cmdlets
        foreach ($cmdlet in $exception.RelatedCmdlets) {
            if (-not $this.Cmdlets.ContainsKey($cmdlet)) {
                $this.Cmdlets[$cmdlet] = @()
            }
            $this.Cmdlets[$cmdlet] += $exception
        }

        # Mettre Ã  jour la date de derniÃ¨re mise Ã  jour
        $this.LastUpdated = [datetime]::Now
    }

    # MÃ©thode pour obtenir une exception par son nom de type
    [ExceptionInfo] GetExceptionByType([string]$typeName) {
        return $this.Exceptions[$typeName]
    }

    # MÃ©thode pour obtenir des exceptions par catÃ©gorie
    [ExceptionInfo[]] GetExceptionsByCategory([string]$category) {
        return $this.Categories[$category]
    }

    # MÃ©thode pour obtenir des exceptions par tag
    [ExceptionInfo[]] GetExceptionsByTag([string]$tag) {
        return $this.Tags[$tag]
    }

    # MÃ©thode pour obtenir des exceptions par module
    [ExceptionInfo[]] GetExceptionsByModule([string]$module) {
        return $this.Modules[$module]
    }

    # MÃ©thode pour obtenir des exceptions par cmdlet
    [ExceptionInfo[]] GetExceptionsByCmdlet([string]$cmdlet) {
        return $this.Cmdlets[$cmdlet]
    }

    # MÃ©thode pour obtenir des exceptions par niveau de sÃ©vÃ©ritÃ©
    [ExceptionInfo[]] GetExceptionsBySeverity([string]$severity) {
        return $this.Exceptions.Values | Where-Object { $_.Severity -eq $severity }
    }

    # MÃ©thode pour obtenir des exceptions spÃ©cifiques Ã  PowerShell
    [ExceptionInfo[]] GetPowerShellSpecificExceptions() {
        return $this.Exceptions.Values | Where-Object { $_.IsPowerShellSpecific -eq $true }
    }

    # MÃ©thode pour obtenir la hiÃ©rarchie d'une exception
    [hashtable] GetExceptionHierarchy([string]$typeName) {
        $result = @{
            Parent   = $null
            Current  = $null
            Children = @()
        }

        if ($this.Exceptions.ContainsKey($typeName)) {
            $exception = $this.Exceptions[$typeName]
            $result.Current = $exception

            if (-not [string]::IsNullOrEmpty($exception.ParentType) -and $this.Exceptions.ContainsKey($exception.ParentType)) {
                $result.Parent = $this.Exceptions[$exception.ParentType]
            }

            foreach ($childType in $exception.ChildTypes) {
                if ($this.Exceptions.ContainsKey($childType)) {
                    $result.Children += $this.Exceptions[$childType]
                }
            }
        }

        return $result
    }

    # MÃ©thode pour exporter la taxonomie au format JSON
    [string] ExportToJson() {
        return $this | ConvertTo-Json -Depth 10
    }

    # MÃ©thode pour importer la taxonomie depuis un fichier JSON
    [void] ImportFromJson([string]$jsonContent) {
        $importedData = $jsonContent | ConvertFrom-Json

        # RÃ©initialiser les tables
        $this.Exceptions = @{}
        $this.Categories = @{}
        $this.Tags = @{}
        $this.Modules = @{}
        $this.Cmdlets = @{}

        # Importer les exceptions
        foreach ($exceptionData in $importedData.Exceptions.PSObject.Properties) {
            $exceptionObj = $exceptionData.Value
            $exception = [ExceptionInfo]::new($exceptionObj.TypeName)

            # Copier les propriÃ©tÃ©s
            foreach ($property in $exceptionObj.PSObject.Properties) {
                if ($property.Name -ne "TypeName" -and $exception.PSObject.Properties.Name -contains $property.Name) {
                    $exception.$($property.Name) = $property.Value
                }
            }

            # Ajouter l'exception Ã  la taxonomie
            $this.AddException($exception)
        }

        # Mettre Ã  jour la date de derniÃ¨re mise Ã  jour
        $this.LastUpdated = [datetime]::Now
    }
}

# Fonction pour crÃ©er une nouvelle taxonomie d'exceptions
function New-ExceptionTaxonomy {
    [CmdletBinding()]
    [OutputType([ExceptionTaxonomy])]
    param()

    return [ExceptionTaxonomy]::new()
}

# Fonction pour crÃ©er une nouvelle entrÃ©e d'exception
function New-ExceptionInfo {
    [CmdletBinding()]
    [OutputType([ExceptionInfo])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TypeName,

        [Parameter(Mandatory = $false)]
        [string]$Category,

        [Parameter(Mandatory = $false)]
        [string]$Severity,

        [Parameter(Mandatory = $false)]
        [string[]]$Tags,

        [Parameter(Mandatory = $false)]
        [bool]$IsPowerShellSpecific,

        [Parameter(Mandatory = $false)]
        [string]$ParentType,

        [Parameter(Mandatory = $false)]
        [string]$DefaultMessage,

        [Parameter(Mandatory = $false)]
        [string]$ErrorCategory,

        [Parameter(Mandatory = $false)]
        [string[]]$PossibleCauses,

        [Parameter(Mandatory = $false)]
        [string[]]$ResolutionSteps
    )

    return [ExceptionInfo]::new(
        $TypeName,
        $Category,
        $Severity,
        $Tags,
        $IsPowerShellSpecific,
        $ParentType,
        $DefaultMessage,
        $ErrorCategory,
        $PossibleCauses,
        $ResolutionSteps
    )
}

# Fonction pour ajouter une exception Ã  la taxonomie
function Add-ExceptionToTaxonomy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ExceptionTaxonomy]$Taxonomy,

        [Parameter(Mandatory = $true)]
        [ExceptionInfo]$Exception
    )

    $Taxonomy.AddException($Exception)
}

# Fonction pour exporter la taxonomie vers un fichier JSON
function Export-ExceptionTaxonomy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ExceptionTaxonomy]$Taxonomy,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    $jsonContent = $Taxonomy.ExportToJson()
    $jsonContent | Out-File -FilePath $FilePath -Encoding utf8
}

# Fonction pour importer la taxonomie depuis un fichier JSON
function Import-ExceptionTaxonomy {
    [CmdletBinding()]
    [OutputType([ExceptionTaxonomy])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -Path $FilePath)) {
        throw "Le fichier spÃ©cifiÃ© n'existe pas: $FilePath"
    }

    $jsonContent = Get-Content -Path $FilePath -Raw
    $taxonomy = New-ExceptionTaxonomy
    $taxonomy.ImportFromJson($jsonContent)

    return $taxonomy
}

# Fonction pour obtenir un exemple de taxonomie avec des exceptions de base
function Get-ExampleExceptionTaxonomy {
    [CmdletBinding()]
    [OutputType([ExceptionTaxonomy])]
    param()

    $taxonomy = New-ExceptionTaxonomy

    # Ajouter System.Exception (base de toutes les exceptions)
    $baseException = New-ExceptionInfo -TypeName "System.Exception" -Category "General" -Severity "Error" `
        -Tags @("Base", "Common") -IsPowerShellSpecific $false `
        -DefaultMessage "Une exception s'est produite." `
        -ErrorCategory "NotSpecified" `
        -PossibleCauses @("Erreur gÃ©nÃ©rique", "Exception non gÃ©rÃ©e") `
        -ResolutionSteps @("VÃ©rifier le message d'erreur pour plus de dÃ©tails", "Consulter la stack trace")

    Add-ExceptionToTaxonomy -Taxonomy $taxonomy -Exception $baseException

    # Ajouter System.ArgumentException
    $argumentException = New-ExceptionInfo -TypeName "System.ArgumentException" -Category "Argument" -Severity "Error" `
        -Tags @("Argument", "Validation") -IsPowerShellSpecific $false `
        -ParentType "System.Exception" `
        -DefaultMessage "La valeur fournie pour l'argument n'est pas valide." `
        -ErrorCategory "InvalidArgument" `
        -PossibleCauses @("Valeur d'argument invalide", "Format d'argument incorrect") `
        -ResolutionSteps @("VÃ©rifier la valeur de l'argument", "Consulter la documentation pour les valeurs acceptÃ©es")

    Add-ExceptionToTaxonomy -Taxonomy $taxonomy -Exception $argumentException

    # Ajouter System.ArgumentNullException
    $argumentNullException = New-ExceptionInfo -TypeName "System.ArgumentNullException" -Category "Argument" -Severity "Error" `
        -Tags @("Argument", "Null", "Validation") -IsPowerShellSpecific $false `
        -ParentType "System.ArgumentException" `
        -DefaultMessage "La valeur fournie pour l'argument ne peut pas Ãªtre null." `
        -ErrorCategory "InvalidArgument" `
        -PossibleCauses @("Argument null", "Variable non initialisÃ©e") `
        -ResolutionSteps @("Initialiser la variable avant de l'utiliser", "Ajouter une vÃ©rification de null")

    Add-ExceptionToTaxonomy -Taxonomy $taxonomy -Exception $argumentNullException

    # Ajouter System.IO.IOException
    $ioException = New-ExceptionInfo -TypeName "System.IO.IOException" -Category "IO" -Severity "Error" `
        -Tags @("IO", "File", "Network") -IsPowerShellSpecific $false `
        -ParentType "System.Exception" `
        -DefaultMessage "Une erreur d'entrÃ©e/sortie s'est produite." `
        -ErrorCategory "WriteError" `
        -PossibleCauses @("Fichier inaccessible", "RÃ©seau indisponible", "PÃ©riphÃ©rique plein") `
        -ResolutionSteps @("VÃ©rifier les permissions du fichier", "VÃ©rifier la connexion rÃ©seau", "LibÃ©rer de l'espace disque")

    Add-ExceptionToTaxonomy -Taxonomy $taxonomy -Exception $ioException

    # Ajouter System.Management.Automation.CommandNotFoundException (spÃ©cifique Ã  PowerShell)
    $cmdNotFoundException = New-ExceptionInfo -TypeName "System.Management.Automation.CommandNotFoundException" -Category "PowerShell" -Severity "Error" `
        -Tags @("PowerShell", "Command", "NotFound") -IsPowerShellSpecific $true `
        -ParentType "System.Exception" `
        -DefaultMessage "La commande spÃ©cifiÃ©e n'a pas Ã©tÃ© trouvÃ©e." `
        -ErrorCategory "ObjectNotFound" `
        -PossibleCauses @("Commande mal orthographiÃ©e", "Module non importÃ©", "Commande non installÃ©e") `
        -ResolutionSteps @("VÃ©rifier l'orthographe de la commande", "Importer le module requis", "Installer le module manquant")

    Add-ExceptionToTaxonomy -Taxonomy $taxonomy -Exception $cmdNotFoundException

    # Mettre Ã  jour les relations parent-enfant
    $baseException.ChildTypes = @("System.ArgumentException", "System.IO.IOException", "System.Management.Automation.CommandNotFoundException")
    $argumentException.ChildTypes = @("System.ArgumentNullException")
    $argumentException.HierarchyLevel = 1
    $argumentNullException.HierarchyLevel = 2
    $ioException.HierarchyLevel = 1
    $cmdNotFoundException.HierarchyLevel = 1

    return $taxonomy
}

# Exporter les fonctions si nous sommes dans un module
if ($null -ne $MyInvocation.ScriptName -and $MyInvocation.ScriptName -ne '') {
    # Nous sommes dans un script, pas besoin d'exporter les fonctions
} else {
    # Nous sommes dans un module, exporter les fonctions
    Export-ModuleMember -Function New-ExceptionTaxonomy
    Export-ModuleMember -Function New-ExceptionInfo
    Export-ModuleMember -Function Add-ExceptionToTaxonomy
    Export-ModuleMember -Function Export-ExceptionTaxonomy
    Export-ModuleMember -Function Import-ExceptionTaxonomy
    Export-ModuleMember -Function Get-ExampleExceptionTaxonomy
}
