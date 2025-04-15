#
# Module FileContentIndexer
# Compatible avec PowerShell 5.1 et PowerShell 7+
#

# Détecter la version de PowerShell
$script:isPowerShell7 = $PSVersionTable.PSVersion.Major -ge 7
$script:isPowerShell5 = $PSVersionTable.PSVersion.Major -eq 5

# Fonction pour obtenir la version de PowerShell
function Get-PSVersionInfo {
    [CmdletBinding()]
    param()

    return [PSCustomObject]@{
        Major = $PSVersionTable.PSVersion.Major
        Minor = $PSVersionTable.PSVersion.Minor
        IsPowerShell7 = $script:isPowerShell7
        IsPowerShell5 = $script:isPowerShell5
        Edition = $PSVersionTable.PSEdition
        FullVersion = $PSVersionTable.PSVersion.ToString()
    }
}

# Fonction pour vérifier si une fonctionnalité est disponible
function Test-FeatureAvailability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FeatureName
    )

    $featureMap = @{
        'Classes' = $script:isPowerShell5 -or $script:isPowerShell7
        'AdvancedClasses' = $script:isPowerShell7
        'Ternary' = $script:isPowerShell7
        'PipelineChain' = $script:isPowerShell7
        'NullCoalescing' = $script:isPowerShell7
        'ForEachParallel' = $script:isPowerShell7
        'UsingVariables' = $script:isPowerShell5 -or $script:isPowerShell7
    }

    if ($featureMap.ContainsKey($FeatureName)) {
        return $featureMap[$FeatureName]
    }

    return $false
}

#
# Implémentation compatible avec les deux versions
#

# Exemple de factory function au lieu d'une classe
function New-FileContentIndexer {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Name = "FileContentIndexer",

        [Parameter()]
        [hashtable]$Properties = @{}
    )

    # Créer un objet de base
    $instance = [PSCustomObject]@{
        Name = $Name
        Properties = $Properties
        CreatedAt = Get-Date
        PSTypeName = "FileContentIndexer"
    }

    # Ajouter des méthodes en fonction de la version de PowerShell
    if ($script:isPowerShell7) {
        # Utiliser des fonctionnalités PowerShell 7
        $instance | Add-Member -MemberType ScriptMethod -Name "Process" -Value {
            param([string]$input)
            return $input ?? "Default" # Utilisation de l'opérateur null-coalescing
        }
    } else {
        # Version compatible PowerShell 5.1
        $instance | Add-Member -MemberType ScriptMethod -Name "Process" -Value {
            param([string]$input)
            if ($null -eq $input) { return "Default" } else { return $input }
        }
    }

    # Ajouter une méthode commune
    $instance | Add-Member -MemberType ScriptMethod -Name "ToString" -Value {
        return "$($this.Name) [Created: $($this.CreatedAt)]"
    }

    return $instance
}

# Fonction wrapper pour la parallélisation
function Invoke-Parallel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $true)]
        [object[]]$InputObject,

        [Parameter()]
        [int]$ThrottleLimit = 5
    )

    if ($script:isPowerShell7) {
        # Utiliser ForEach-Object -Parallel en PowerShell 7
        return $InputObject | ForEach-Object -Parallel $ScriptBlock -ThrottleLimit $ThrottleLimit
    } else {
        # Utiliser une approche compatible avec PowerShell 5.1
        $results = @()

        # Créer un pool de runspaces
        $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
        $pool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $ThrottleLimit, $sessionState, $Host)
        $pool.Open()

        try {
            $runspaces = @()

            # Créer un runspace pour chaque élément d'entrée
            foreach ($item in $InputObject) {
                $powershell = [System.Management.Automation.PowerShell]::Create()
                $powershell.RunspacePool = $pool
                [void]$powershell.AddScript($ScriptBlock)
                [void]$powershell.AddArgument($item)

                $runspaces += [PSCustomObject]@{
                    PowerShell = $powershell
                    AsyncResult = $powershell.BeginInvoke()
                    Item = $item
                }
            }

            # Collecter les résultats
            foreach ($runspace in $runspaces) {
                $results += $runspace.PowerShell.EndInvoke($runspace.AsyncResult)
                $runspace.PowerShell.Dispose()
            }
        }
        finally {
            # Nettoyer les ressources
            $pool.Close()
            $pool.Dispose()
        }

        return $results
    }
}

# Exporter les fonctions
Export-ModuleMember -Function New-FileContentIndexer, Invoke-Parallel, Get-PSVersionInfo, Test-FeatureAvailability
