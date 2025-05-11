# Invoke-RetentionPolicies.ps1
# Script pour appliquer les politiques de rétention aux points de restauration
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ConfigName = "default",

    [Parameter(Mandatory = $false)]
    [ValidateSet("All", "TimeBasedRetention", "VersionBasedRetention", "ImportanceBasedRetention", "UsageBasedRetention", "CompositeRetention")]
    [string[]]$PolicyTypes = @("All"),

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [ValidateSet("Error", "Warning", "Info", "Debug", "None")]
    [string]$LogLevel = "Info"
)

# Importer le module de journalisation
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$parentPath = Split-Path -Parent $scriptPath
$rootPath = Split-Path -Parent $parentPath
$utilsPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $rootPath))) -ChildPath "utils"
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
            "Error"   = 0
            "Warning" = 1
            "Info"    = 2
            "Debug"   = 3
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

# Importer les scripts de rétention
$timeBasedRetentionPath = Join-Path -Path $scriptPath -ChildPath "Set-TimeBasedRetention.ps1"
$versionBasedRetentionPath = Join-Path -Path $scriptPath -ChildPath "Set-VersionBasedRetention.ps1"
$importanceBasedRetentionPath = Join-Path -Path $scriptPath -ChildPath "Set-ImportanceBasedRetention.ps1"
$usageBasedRetentionPath = Join-Path -Path $scriptPath -ChildPath "Set-UsageBasedRetention.ps1"
$compositeRetentionPath = Join-Path -Path $scriptPath -ChildPath "Set-CompositeRetention.ps1"

# Vérifier et importer les scripts
$requiredScripts = @(
    @{ Path = $timeBasedRetentionPath; Name = "Set-TimeBasedRetention.ps1" },
    @{ Path = $versionBasedRetentionPath; Name = "Set-VersionBasedRetention.ps1" },
    @{ Path = $importanceBasedRetentionPath; Name = "Set-ImportanceBasedRetention.ps1" },
    @{ Path = $usageBasedRetentionPath; Name = "Set-UsageBasedRetention.ps1" },
    @{ Path = $compositeRetentionPath; Name = "Set-CompositeRetention.ps1" }
)

foreach ($script in $requiredScripts) {
    if (Test-Path -Path $script.Path) {
        . $script.Path
    } else {
        Write-Log "Required script not found: $($script.Name)" -Level "Warning"
    }
}

# Fonction pour obtenir le chemin du fichier de configuration des politiques de rétention
function Get-RetentionConfigPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )

    $configPath = Join-Path -Path $parentPath -ChildPath "config"

    if (-not (Test-Path -Path $configPath)) {
        New-Item -Path $configPath -ItemType Directory -Force | Out-Null
    }

    $retentionPath = Join-Path -Path $configPath -ChildPath "retention"

    if (-not (Test-Path -Path $retentionPath)) {
        New-Item -Path $retentionPath -ItemType Directory -Force | Out-Null
    }

    return Join-Path -Path $retentionPath -ChildPath "$ConfigName.json"
}

# Fonction pour charger la configuration de rétention
function Get-RetentionConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default"
    )

    $configPath = Get-RetentionConfigPath -ConfigName $ConfigName

    if (Test-Path -Path $configPath) {
        try {
            $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            return $config
        } catch {
            Write-Log "Error loading retention configuration: $_" -Level "Error"
            return $null
        }
    } else {
        return $null
    }
}

# Fonction pour appliquer les politiques de rétention
function Invoke-RetentionPolicies {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ConfigName = "default",

        [Parameter(Mandatory = $false)]
        [ValidateSet("All", "TimeBasedRetention", "VersionBasedRetention", "ImportanceBasedRetention", "UsageBasedRetention")]
        [string[]]$PolicyTypes = @("All"),

        [Parameter(Mandatory = $false)]
        [switch]$WhatIf,

        [Parameter(Mandatory = $false)]
        [switch]$Force
    )

    # Charger la configuration de rétention
    $config = Get-RetentionConfig -ConfigName $ConfigName

    if ($null -eq $config) {
        Write-Log "No retention configuration found for $ConfigName" -Level "Warning"
        return $false
    }

    # Vérifier si la configuration contient des politiques
    if (-not $config.PSObject.Properties.Name.Contains("policies")) {
        Write-Log "No policies defined in retention configuration $ConfigName" -Level "Warning"
        return $false
    }

    # Initialiser les compteurs
    $successCount = 0
    $errorCount = 0

    # Déterminer les types de politiques à appliquer
    $applyAll = $PolicyTypes.Contains("All")

    # Appliquer les politiques de rétention basées sur le temps
    if ($applyAll -or $PolicyTypes.Contains("TimeBasedRetention")) {
        if ($config.policies.PSObject.Properties.Name.Contains("time_based")) {
            Write-Log "Applying time-based retention policies" -Level "Info"

            # Traiter chaque politique de rétention basée sur le temps
            foreach ($type in $config.policies.time_based.PSObject.Properties.Name) {
                $policy = $config.policies.time_based.$type

                if ($policy.PSObject.Properties.Name.Contains("retention_days")) {
                    $retentionDays = $policy.retention_days

                    Write-Log "Applying time-based retention for $type restore points: $retentionDays days" -Level "Info"

                    try {
                        $result = Apply-TimeBasedRetention -RestorePointType $type -RetentionDays $retentionDays -WhatIf:$WhatIf -Force:$Force

                        if ($result) {
                            $successCount++
                        } else {
                            $errorCount++
                        }
                    } catch {
                        Write-Log ("Error applying time-based retention for {0}: {1}" -f $type, $_.Exception.Message) -Level "Error"
                        $errorCount++
                    }
                }
            }
        } else {
            Write-Log "No time-based retention policies defined" -Level "Info"
        }
    }

    # Appliquer les politiques de rétention basées sur le nombre de versions
    if ($applyAll -or $PolicyTypes.Contains("VersionBasedRetention")) {
        if ($config.policies.PSObject.Properties.Name.Contains("version_based")) {
            Write-Log "Applying version-based retention policies" -Level "Info"

            # Traiter chaque politique de rétention basée sur le nombre de versions
            foreach ($key in $config.policies.version_based.PSObject.Properties.Name) {
                $policy = $config.policies.version_based.$key

                if ($policy.PSObject.Properties.Name.Contains("max_versions")) {
                    $maxVersions = $policy.max_versions
                    $configType = if ($policy.PSObject.Properties.Name.Contains("config_type")) { $policy.config_type } else { "" }
                    $configId = if ($policy.PSObject.Properties.Name.Contains("config_id")) { $policy.config_id } else { "" }

                    # Déterminer le type de point de restauration
                    $restorePointType = $key

                    if ($key.Contains("-")) {
                        $parts = $key.Split("-")
                        $restorePointType = $parts[0]
                    }

                    Write-Log "Applying version-based retention for $restorePointType restore points: $maxVersions versions" -Level "Info"

                    try {
                        $result = Apply-VersionBasedRetention -RestorePointType $restorePointType -ConfigType $configType -ConfigId $configId -MaxVersions $maxVersions -WhatIf:$WhatIf -Force:$Force

                        if ($result) {
                            $successCount++
                        } else {
                            $errorCount++
                        }
                    } catch {
                        Write-Log ("Error applying version-based retention for {0}: {1}" -f $restorePointType, $_.Exception.Message) -Level "Error"
                        $errorCount++
                    }
                }
            }
        } else {
            Write-Log "No version-based retention policies defined" -Level "Info"
        }
    }

    # Appliquer les politiques de rétention basées sur l'importance
    if ($applyAll -or $PolicyTypes.Contains("ImportanceBasedRetention")) {
        if ($config.policies.PSObject.Properties.Name.Contains("importance_based")) {
            Write-Log "Applying importance-based retention policies" -Level "Info"

            # Traiter chaque politique de rétention basée sur l'importance
            foreach ($level in $config.policies.importance_based.PSObject.Properties.Name) {
                $policy = $config.policies.importance_based.$level

                if ($policy.PSObject.Properties.Name.Contains("retention_days")) {
                    $retentionDays = $policy.retention_days

                    Write-Log "Applying importance-based retention for $level importance restore points: $retentionDays days" -Level "Info"

                    try {
                        $result = Apply-ImportanceBasedRetention -ImportanceLevel $level -RetentionDays $retentionDays -WhatIf:$WhatIf -Force:$Force

                        if ($result) {
                            $successCount++
                        } else {
                            $errorCount++
                        }
                    } catch {
                        Write-Log ("Error applying importance-based retention for {0}: {1}" -f $level, $_.Exception.Message) -Level "Error"
                        $errorCount++
                    }
                }
            }
        } else {
            Write-Log "No importance-based retention policies defined" -Level "Info"
        }
    }

    # Appliquer les politiques de rétention basées sur l'utilisation
    if ($applyAll -or $PolicyTypes.Contains("UsageBasedRetention")) {
        if ($config.policies.PSObject.Properties.Name.Contains("usage_based")) {
            Write-Log "Applying usage-based retention policies" -Level "Info"

            $policy = $config.policies.usage_based

            if ($policy.PSObject.Properties.Name.Contains("minimum_usage_count") -and
                $policy.PSObject.Properties.Name.Contains("retention_days") -and
                $policy.PSObject.Properties.Name.Contains("unused_retention_days")) {

                $minimumUsageCount = $policy.minimum_usage_count
                $retentionDays = $policy.retention_days
                $unusedRetentionDays = $policy.unused_retention_days

                Write-Log "Applying usage-based retention: $minimumUsageCount+ uses for $retentionDays days, unused for $unusedRetentionDays days" -Level "Info"

                try {
                    $result = Apply-UsageBasedRetention -MinimumUsageCount $minimumUsageCount -RetentionDays $retentionDays -UnusedRetentionDays $unusedRetentionDays -WhatIf:$WhatIf -Force:$Force

                    if ($result) {
                        $successCount++
                    } else {
                        $errorCount++
                    }
                } catch {
                    Write-Log ("Error applying usage-based retention: {0}" -f $_.Exception.Message) -Level "Error"
                    $errorCount++
                }
            }
        } else {
            Write-Log "No usage-based retention policies defined" -Level "Info"
        }
    }

    # Appliquer les politiques de rétention composites
    if ($applyAll -or $PolicyTypes.Contains("CompositeRetention")) {
        if ($config.policies.PSObject.Properties.Name.Contains("composite")) {
            Write-Log "Applying composite retention policies" -Level "Info"

            # Trier les règles par priorité (du plus petit au plus grand)
            $rules = $config.policies.composite.PSObject.Properties.Value | Sort-Object -Property priority

            foreach ($rule in $rules) {
                $ruleName = $rule.name

                Write-Log "Applying composite retention rule: $ruleName (Priority: $($rule.priority))" -Level "Info"

                try {
                    $result = Apply-CompositeRetention -RuleName $ruleName -ConfigName $ConfigName -WhatIf:$WhatIf -Force:$Force

                    if ($result) {
                        $successCount++
                    } else {
                        $errorCount++
                    }
                } catch {
                    Write-Log ("Error applying composite retention rule {0}: {1}" -f $ruleName, $_.Exception.Message) -Level "Error"
                    $errorCount++
                }
            }
        } else {
            Write-Log "No composite retention policies defined" -Level "Info"
        }
    }

    # Afficher le résumé
    if ($WhatIf) {
        Write-Log "WhatIf: Retention policies would be applied" -Level "Info"
    } else {
        Write-Log "Applied retention policies: $successCount successful, $errorCount errors" -Level "Info"
    }

    return $errorCount -eq 0
}

# Exécuter la fonction principale si le script est exécuté directement
if ($MyInvocation.InvocationName -eq $MyInvocation.MyCommand.Name) {
    Invoke-RetentionPolicies -ConfigName $ConfigName -PolicyTypes $PolicyTypes -WhatIf:$WhatIf -Force:$Force
}
