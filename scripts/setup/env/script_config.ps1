# Module de gestion de la configuration pour le Script Manager

function Get-ScriptConfig {
    param (
        [string]$ConfigPath = "src/config.json"
    )

    try {
        if (Test-Path $ConfigPath) {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            return $config
        } else {
            Write-Warning "Fichier de configuration non trouvÃ©: $ConfigPath. Utilisation des valeurs par dÃ©faut."
            return New-DefaultConfig
        }
    } catch {
        Write-Error "Erreur lors du chargement de la configuration: $_"
        return New-DefaultConfig
    }
}

function New-DefaultConfig {
    return [PSCustomObject]@{
        general = @{
            defaultCommand = "help"
            scanPath = "."
            dbPath = "scripts_db.json"
            verbose = $false
        }
        inventory = @{
            includeExtensions = @(".ps1", ".py", ".cmd")
            excludeFolders = @("node_modules", ".git")
            maxDepth = 10
        }
        analyze = @{
            detailedOutput = $true
            generateReport = $false
            reportPath = "reports"
        }
        organize = @{
            dryRun = $true
            backupBeforeChanges = $true
            backupPath = "backups"
        }
    }
}

function Save-ScriptConfig {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Config,
        [string]$ConfigPath = "src/config.json"
    )

    try {
        $configJson = $Config | ConvertTo-Json -Depth 5
        Set-Content -Path $ConfigPath -Value $configJson -Encoding UTF8
        Write-Host "Configuration sauvegardÃ©e avec succÃ¨s dans $ConfigPath"
    } catch {
        Write-Error "Erreur lors de la sauvegarde de la configuration: $_"
    }
}

function Update-ScriptConfig {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Section,
        [Parameter(Mandatory=$true)]
        [string]$Property,
        [Parameter(Mandatory=$true)]
        $Value,
        [string]$ConfigPath = "src/config.json"
    )

    try {
        $config = Get-ScriptConfig -ConfigPath $ConfigPath

        # VÃ©rifier si la section existe
        if (-not (Get-Member -InputObject $config -Name $Section -MemberType Properties)) {
            Write-Error "La section '$Section' n'existe pas dans la configuration"
            return $false
        }

        # VÃ©rifier si la propriÃ©tÃ© existe dans la section
        if (-not (Get-Member -InputObject $config.$Section -Name $Property -MemberType Properties)) {
            Write-Error "La propriÃ©tÃ© '$Property' n'existe pas dans la section '$Section'"
            return $false
        }

        # Mettre Ã  jour la valeur
        $config.$Section.$Property = $Value

        # Sauvegarder la configuration
        Save-ScriptConfig -Config $config -ConfigPath $ConfigPath
        return $true
    } catch {
        Write-Error "Erreur lors de la mise Ã  jour de la configuration: $_"
        return $false
    }
}

# Note: Nous n'exportons pas les fonctions car ce n'est pas un module PowerShell formel
# Les fonctions sont disponibles dans le script qui source ce fichier
