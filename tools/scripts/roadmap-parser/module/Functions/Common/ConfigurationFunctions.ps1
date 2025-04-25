<#
.SYNOPSIS
    Fonctions de gestion de la configuration pour les modes RoadmapParser.

.DESCRIPTION
    Ce script contient des fonctions pour charger, fusionner et valider les configurations
    utilisées par les différents modes de RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de création: 2023-08-15
#>

<#
.SYNOPSIS
    Retourne la configuration par défaut pour les modes RoadmapParser.

.DESCRIPTION
    Cette fonction retourne un objet contenant la configuration par défaut
    pour tous les modes de RoadmapParser.

.EXAMPLE
    $config = Get-DefaultConfiguration

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-DefaultConfiguration {
    [CmdletBinding()]
    param()

    $defaultConfig = @{
        # Configuration générale
        General = @{
            LogLevel                 = "INFO"
            LogPath                  = "logs"
            LogRetentionDays         = 30
            OutputFormat             = "Markdown"
            BackupBeforeModification = $true
            MaxConcurrentTasks       = 4
        }

        # Configuration spécifique aux modes
        Modes   = @{
            # Mode ARCHI
            ARCHI     = @{
                DiagramType         = "C4"
                IncludeComponents   = $true
                IncludeInterfaces   = $true
                IncludeDependencies = $true
                OutputFormats       = @("Markdown", "PlantUML", "Mermaid")
            }

            # Mode DEBUG
            DEBUG     = @{
                GeneratePatch      = $true
                IncludeStackTrace  = $true
                MaxStackTraceDepth = 10
                AnalyzePerformance = $true
                SuggestFixes       = $true
            }

            # Mode TEST
            TEST      = @{
                CoverageThreshold   = 80
                GenerateReport      = $true
                IncludeCodeCoverage = $true
                TestFramework       = "Pester"
                ParallelTests       = $true
            }

            # Mode OPTI
            OPTI      = @{
                OptimizationTarget = "All"
                ProfileDepth       = 5
                MemoryThreshold    = 100
                TimeThreshold      = 1000
                GenerateReport     = $true
            }

            # Mode REVIEW
            REVIEW    = @{
                CheckStandards     = $true
                CheckDocumentation = $true
                CheckComplexity    = $true
                MaxComplexity      = 10
                MinDocRatio        = 0.2
                StandardsFile      = "standards.json"
            }

            # Mode DEV-R
            "DEV-R"   = @{
                GenerateTests       = $true
                UpdateRoadmap       = $true
                ImplementationStyle = "TDD"
                DocumentationStyle  = "XML"
                IncludeExamples     = $true
            }

            # Mode PREDIC
            PREDIC    = @{
                PredictionHorizon = 30
                AnomalyDetection  = $true
                TrendAnalysis     = $true
                AlertThreshold    = 0.95
                GenerateReport    = $true
            }

            # Mode C-BREAK
            "C-BREAK" = @{
                AutoFix            = $false
                GenerateGraph      = $true
                MaxCycleDepth      = 10
                BackupBeforeFix    = $true
                SuggestRefactoring = $true
            }

            # Mode GIT
            GIT       = @{
                CommitStyle           = "Thematic"
                SkipVerify            = $false
                FinalVerify           = $true
                PushAfterCommit       = $false
                CommitMessageTemplate = "feat({0}): {1}"
            }

            # Mode CHECK
            CHECK     = @{
                UpdateRoadmap                = $true
                GenerateReport               = $true
                IncludeImplementationDetails = $true
                IncludeTestResults           = $true
                FailOnIncomplete             = $false
            }

            # Mode GRAN
            GRAN      = @{
                IndentationStyle       = "Auto"
                CheckboxStyle          = "Auto"
                MaxSubTaskDepth        = 4
                UpdateRoadmap          = $true
                IncludeTaskDescription = $true
            }
        }

        # Configuration des chemins
        Paths   = @{
            ModulePath    = "roadmap-parser\module"
            FunctionsPath = "roadmap-parser\module\Functions"
            TemplatesPath = "roadmap-parser\module\Templates"
            TestsPath     = "roadmap-parser\module\Tests"
            OutputPath    = "output"
            BackupPath    = "backup"
        }
    }

    return $defaultConfig
}

<#
.SYNOPSIS
    Charge une configuration à partir d'un fichier.

.DESCRIPTION
    Cette fonction charge une configuration à partir d'un fichier JSON ou YAML.
    Elle peut également détecter automatiquement le format du fichier si l'extension n'est pas spécifiée.

.PARAMETER ConfigFile
    Chemin vers le fichier de configuration.

.PARAMETER Format
    Format du fichier de configuration (Auto, JSON ou YAML). Par défaut, le format est détecté automatiquement.

.PARAMETER ApplyDefaults
    Indique si les valeurs par défaut doivent être appliquées à la configuration chargée.

.PARAMETER Validate
    Indique si la configuration chargée doit être validée.

.EXAMPLE
    $config = Get-Configuration -ConfigFile "config.json"

.EXAMPLE
    $config = Get-Configuration -ConfigFile "config.dat" -Format "JSON" -ApplyDefaults -Validate

.OUTPUTS
    System.Collections.Hashtable
#>
function Get-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigFile,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Auto", "JSON", "YAML")]
        [string]$Format = "Auto",

        [Parameter(Mandatory = $false)]
        [switch]$ApplyDefaults,

        [Parameter(Mandatory = $false)]
        [switch]$Validate
    )

    if (-not (Test-Path -Path $ConfigFile)) {
        Write-Error "Le fichier de configuration est introuvable à l'emplacement : $ConfigFile"
        return $null
    }

    try {
        # Déterminer le format du fichier
        if ($Format -eq "Auto") {
            $extension = [System.IO.Path]::GetExtension($ConfigFile).ToLower()

            if ($extension -eq ".json") {
                $Format = "JSON"
            } elseif ($extension -eq ".yaml" -or $extension -eq ".yml") {
                $Format = "YAML"
            } else {
                # Essayer de détecter le format en lisant le contenu du fichier
                $content = Get-Content -Path $ConfigFile -Raw

                if ($content -match '^\s*{') {
                    $Format = "JSON"
                } elseif ($content -match '^\s*---') {
                    $Format = "YAML"
                } else {
                    Write-Warning "Impossible de détecter automatiquement le format du fichier. Utilisation du format JSON par défaut."
                    $Format = "JSON"
                }
            }
        }

        # Charger la configuration selon le format
        switch ($Format) {
            "JSON" {
                try {
                    $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
                } catch {
                    Write-Error "Erreur lors de la conversion du fichier JSON : $_"
                    return $null
                }
            }
            "YAML" {
                # Vérifier si le module PowerShell-Yaml est installé
                if (-not (Get-Module -ListAvailable -Name "powershell-yaml")) {
                    Write-Error "Le module PowerShell-Yaml est requis pour charger des fichiers YAML. Installez-le avec : Install-Module -Name powershell-yaml -Force"
                    return $null
                }

                try {
                    Import-Module -Name "powershell-yaml" -ErrorAction Stop
                    $config = Get-Content -Path $ConfigFile -Raw | ConvertFrom-Yaml -AsHashtable -ErrorAction Stop
                } catch {
                    Write-Error "Erreur lors de la conversion du fichier YAML : $_"
                    return $null
                }
            }
        }

        # Appliquer les valeurs par défaut si demandé
        if ($ApplyDefaults) {
            $defaultConfig = Get-DefaultConfiguration
            $config = Merge-Configuration -DefaultConfig $defaultConfig -CustomConfig $config
        }

        # Valider la configuration si demandé
        if ($Validate) {
            $isValid = Test-Configuration -Config $config
            if (-not $isValid) {
                Write-Warning "La configuration chargée n'est pas valide. Utilisez Test-Configuration pour plus de détails."
            }
        }

        return $config
    } catch {
        Write-Error "Erreur lors du chargement de la configuration : $_"
        return $null
    }
}

<#
.SYNOPSIS
    Fusionne deux configurations.

.DESCRIPTION
    Cette fonction fusionne une configuration personnalisée avec la configuration par défaut.
    Les valeurs de la configuration personnalisée remplacent celles de la configuration par défaut.
    Différentes stratégies de fusion peuvent être utilisées pour contrôler le comportement de fusion.

.PARAMETER DefaultConfig
    Configuration par défaut.

.PARAMETER CustomConfig
    Configuration personnalisée.

.PARAMETER Strategy
    Stratégie de fusion à utiliser. Les valeurs possibles sont :
    - Replace : Les valeurs de CustomConfig remplacent celles de DefaultConfig (par défaut)
    - Append : Les valeurs de CustomConfig sont ajoutées à celles de DefaultConfig (pour les tableaux)
    - KeepExisting : Les valeurs existantes dans DefaultConfig sont conservées si elles existent déjà

.PARAMETER ExcludeSections
    Sections à exclure de la fusion.

.PARAMETER IncludeSections
    Sections à inclure dans la fusion. Si spécifié, seules ces sections seront fusionnées.

.EXAMPLE
    $mergedConfig = Merge-Configuration -DefaultConfig $defaultConfig -CustomConfig $customConfig

.EXAMPLE
    $mergedConfig = Merge-Configuration -DefaultConfig $defaultConfig -CustomConfig $customConfig -Strategy "Append" -IncludeSections @("General", "Paths")

.OUTPUTS
    System.Collections.Hashtable
#>
function Merge-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$DefaultConfig,

        [Parameter(Mandatory = $true)]
        [hashtable]$CustomConfig,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Replace", "Append", "KeepExisting")]
        [string]$Strategy = "Replace",

        [Parameter(Mandatory = $false)]
        [string[]]$ExcludeSections = @(),

        [Parameter(Mandatory = $false)]
        [string[]]$IncludeSections = @()
    )

    try {
        $mergedConfig = $DefaultConfig.Clone()

        # Fonction récursive pour fusionner les hashtables
        function Merge-Hashtable {
            param(
                [hashtable]$Target,
                [hashtable]$Source,
                [string]$CurrentPath = "",
                [string]$Strategy,
                [string[]]$ExcludeSections,
                [string[]]$IncludeSections
            )

            foreach ($key in $Source.Keys) {
                $keyPath = if ([string]::IsNullOrEmpty($CurrentPath)) { $key } else { "$CurrentPath.$key" }

                # Vérifier si la section doit être exclue
                if ($ExcludeSections -contains $keyPath) {
                    Write-Verbose "Section exclue de la fusion : $keyPath"
                    continue
                }

                # Vérifier si la section doit être incluse (si IncludeSections est spécifié)
                if ($IncludeSections.Count -gt 0 -and -not ($IncludeSections -contains $keyPath) -and -not ($IncludeSections | Where-Object { $keyPath -like "$_*" })) {
                    Write-Verbose "Section non incluse dans la fusion : $keyPath"
                    continue
                }

                if ($Target.ContainsKey($key)) {
                    if ($Target[$key] -is [hashtable] -and $Source[$key] -is [hashtable]) {
                        # Fusion récursive des hashtables
                        Merge-Hashtable -Target $Target[$key] -Source $Source[$key] -CurrentPath $keyPath -Strategy $Strategy -ExcludeSections $ExcludeSections -IncludeSections $IncludeSections
                    } elseif ($Target[$key] -is [array] -and $Source[$key] -is [array] -and $Strategy -eq "Append") {
                        # Fusion des tableaux en mode Append
                        $Target[$key] = @($Target[$key]) + @($Source[$key]) | Select-Object -Unique
                    } elseif ($Strategy -eq "KeepExisting") {
                        # Ne rien faire, conserver la valeur existante
                        Write-Verbose "Valeur existante conservée pour $keyPath : $($Target[$key])"
                    } else {
                        # Remplacement de la valeur (stratégie par défaut)
                        $Target[$key] = $Source[$key]
                    }
                } else {
                    # Ajout de la nouvelle clé
                    $Target[$key] = $Source[$key]
                }
            }
        }

        Merge-Hashtable -Target $mergedConfig -Source $CustomConfig -Strategy $Strategy -ExcludeSections $ExcludeSections -IncludeSections $IncludeSections

        return $mergedConfig
    } catch {
        Write-Error "Erreur lors de la fusion des configurations : $_"
        return $DefaultConfig
    }
}

<#
.SYNOPSIS
    Valide une configuration.

.DESCRIPTION
    Cette fonction vérifie qu'une configuration contient toutes les clés requises
    et que les valeurs sont du type attendu. Elle peut également valider des règles
    personnalisées et vérifier les types de données.

.PARAMETER Config
    Configuration à valider.

.PARAMETER ValidationRules
    Règles de validation personnalisées sous forme de hashtable.

.PARAMETER SkipMissingKeys
    Indique si les clés manquantes doivent être ignorées lors de la validation.

.PARAMETER Detailed
    Indique si un rapport de validation détaillé doit être généré.

.EXAMPLE
    $isValid = Test-Configuration -Config $config

.EXAMPLE
    $validationReport = Test-Configuration -Config $config -Detailed

.EXAMPLE
    $customRules = @{
        "General.LogLevel" = @{
            Type = "String"
            AllowedValues = @("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")
        }
    }
    $isValid = Test-Configuration -Config $config -ValidationRules $customRules

.OUTPUTS
    System.Boolean ou System.Collections.Hashtable (si -Detailed est spécifié)
#>
function Test-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $false)]
        [hashtable]$ValidationRules = @{},

        [Parameter(Mandatory = $false)]
        [switch]$SkipMissingKeys,

        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )

    try {
        $isValid = $true
        $validationReport = @{
            IsValid       = $true
            Errors        = @()
            Warnings      = @()
            MissingKeys   = @()
            InvalidTypes  = @()
            InvalidValues = @()
        }

        # Définir les règles de validation par défaut
        $defaultRules = @{
            # Sections principales requises
            "General"                          = @{
                Type     = "Hashtable"
                Required = $true
            }
            "Modes"                            = @{
                Type     = "Hashtable"
                Required = $true
            }
            "Paths"                            = @{
                Type     = "Hashtable"
                Required = $true
            }

            # Clés requises dans la section General
            "General.LogLevel"                 = @{
                Type          = "String"
                Required      = $true
                AllowedValues = @("ERROR", "WARNING", "INFO", "VERBOSE", "DEBUG")
            }
            "General.LogPath"                  = @{
                Type     = "String"
                Required = $true
            }
            "General.OutputFormat"             = @{
                Type          = "String"
                Required      = $true
                AllowedValues = @("Markdown", "JSON", "YAML", "Text", "HTML")
            }
            "General.BackupBeforeModification" = @{
                Type         = "Boolean"
                Required     = $false
                DefaultValue = $true
            }

            # Clés requises dans la section Paths
            "Paths.ModulePath"                 = @{
                Type     = "String"
                Required = $true
            }
            "Paths.FunctionsPath"              = @{
                Type     = "String"
                Required = $true
            }
            "Paths.OutputPath"                 = @{
                Type     = "String"
                Required = $true
            }

            # Modes requis
            "Modes.ARCHI"                      = @{
                Type     = "Hashtable"
                Required = $true
            }
            "Modes.DEBUG"                      = @{
                Type     = "Hashtable"
                Required = $true
            }
            "Modes.TEST"                       = @{
                Type     = "Hashtable"
                Required = $true
            }
            "Modes.OPTI"                       = @{
                Type     = "Hashtable"
                Required = $true
            }
            "Modes.REVIEW"                     = @{
                Type     = "Hashtable"
                Required = $true
            }
            "Modes.DEV-R"                      = @{
                Type     = "Hashtable"
                Required = $true
            }
            "Modes.PREDIC"                     = @{
                Type     = "Hashtable"
                Required = $true
            }
            "Modes.C-BREAK"                    = @{
                Type     = "Hashtable"
                Required = $true
            }
            "Modes.GIT"                        = @{
                Type     = "Hashtable"
                Required = $true
            }
            "Modes.CHECK"                      = @{
                Type     = "Hashtable"
                Required = $true
            }
            "Modes.GRAN"                       = @{
                Type     = "Hashtable"
                Required = $true
            }
        }

        # Fusionner les règles par défaut avec les règles personnalisées
        $rules = Merge-Configuration -DefaultConfig $defaultRules -CustomConfig $ValidationRules

        # Fonction récursive pour valider la configuration
        function Test-ConfigValue {
            param(
                [hashtable]$Config,
                [hashtable]$Rules,
                [string]$CurrentPath = ""
            )

            $localValid = $true

            # Valider les règles pour le chemin actuel
            foreach ($rulePath in $Rules.Keys) {
                $rule = $Rules[$rulePath]

                # Ignorer les règles qui ne commencent pas par le chemin actuel
                if ($CurrentPath -and -not $rulePath.StartsWith($CurrentPath)) {
                    continue
                }

                # Obtenir le chemin relatif à partir du chemin actuel
                $relativePath = if ($CurrentPath -and $rulePath.Length -gt $CurrentPath.Length) {
                    $rulePath.Substring($CurrentPath.Length + 1)
                } else {
                    $rulePath
                }

                # Ignorer les règles qui contiennent des points (sous-chemins) à ce niveau
                if ($relativePath -and $relativePath.Contains(".")) {
                    continue
                }

                # Construire le chemin complet pour la valeur à valider
                $valuePath = if ($CurrentPath) { "$CurrentPath.$relativePath" } else { $relativePath }

                # Obtenir la valeur à valider
                $value = Get-ConfigValue -Config $Config -Path $valuePath

                # Vérifier si la valeur existe
                if ($null -eq $value) {
                    if ($rule.Required -and -not $SkipMissingKeys) {
                        $validationReport.MissingKeys += $valuePath
                        $validationReport.Errors += "La clé requise '$valuePath' est manquante."
                        $validationReport.IsValid = $false
                        $localValid = $false
                        Write-Warning "La clé requise '$valuePath' est manquante."
                    } elseif ($null -ne $rule.DefaultValue) {
                        # Appliquer la valeur par défaut
                        Set-ConfigValue -Config $Config -Path $valuePath -Value $rule.DefaultValue
                        Write-Verbose "Valeur par défaut appliquée pour '$valuePath' : $($rule.DefaultValue)"
                    }
                } else {
                    # Vérifier le type de la valeur
                    $typeValid = Test-ConfigValueType -Value $value -ExpectedType $rule.Type
                    if (-not $typeValid) {
                        $validationReport.InvalidTypes += $valuePath
                        $validationReport.Errors += "La valeur de '$valuePath' n'est pas du type attendu ($($rule.Type))."
                        $validationReport.IsValid = $false
                        $localValid = $false
                        Write-Warning "La valeur de '$valuePath' n'est pas du type attendu ($($rule.Type))."
                    }

                    # Vérifier les valeurs autorisées
                    if ($rule.AllowedValues -and $value -notin $rule.AllowedValues) {
                        $validationReport.InvalidValues += $valuePath
                        $validationReport.Errors += "La valeur de '$valuePath' ($value) n'est pas autorisée. Valeurs autorisées : $($rule.AllowedValues -join ', ')"
                        $validationReport.IsValid = $false
                        $localValid = $false
                        Write-Warning "La valeur de '$valuePath' ($value) n'est pas autorisée. Valeurs autorisées : $($rule.AllowedValues -join ', ')"
                    }

                    # Vérifier les règles personnalisées
                    if ($rule.Validator -is [scriptblock]) {
                        $validatorResult = & $rule.Validator $value
                        if (-not $validatorResult) {
                            $validationReport.InvalidValues += $valuePath
                            $validationReport.Errors += "La valeur de '$valuePath' ($value) n'a pas passé la validation personnalisée."
                            $validationReport.IsValid = $false
                            $localValid = $false
                            Write-Warning "La valeur de '$valuePath' ($value) n'a pas passé la validation personnalisée."
                        }
                    }

                    # Si la valeur est un hashtable, valider récursivement
                    if ($value -is [hashtable]) {
                        $subValid = Test-ConfigValue -Config $value -Rules $Rules -CurrentPath $valuePath
                        if (-not $subValid) {
                            $localValid = $false
                        }
                    }
                }
            }

            return $localValid
        }

        # Fonction pour obtenir une valeur à partir d'un chemin
        function Get-ConfigValue {
            param(
                [hashtable]$Config,
                [string]$Path
            )

            $parts = $Path -split "\."
            $current = $Config

            foreach ($part in $parts) {
                if (-not $current.ContainsKey($part)) {
                    return $null
                }

                $current = $current[$part]
            }

            return $current
        }

        # Fonction pour définir une valeur à partir d'un chemin
        function Set-ConfigValue {
            param(
                [hashtable]$Config,
                [string]$Path,
                [object]$Value
            )

            $parts = $Path -split "\."
            $current = $Config

            for ($i = 0; $i -lt $parts.Count - 1; $i++) {
                $part = $parts[$i]

                if (-not $current.ContainsKey($part)) {
                    $current[$part] = @{}
                }

                $current = $current[$part]
            }

            $current[$parts[-1]] = $Value
        }

        # Fonction pour vérifier le type d'une valeur
        function Test-ConfigValueType {
            param(
                [object]$Value,
                [string]$ExpectedType
            )

            switch ($ExpectedType) {
                "String" { return $Value -is [string] }
                "Integer" { return $Value -is [int] }
                "Number" { return $Value -is [int] -or $Value -is [double] -or $Value -is [decimal] }
                "Boolean" { return $Value -is [bool] }
                "Array" { return $Value -is [array] }
                "Hashtable" { return $Value -is [hashtable] }
                "DateTime" { return $Value -is [datetime] }
                "Any" { return $true }
                default { return $true }
            }
        }

        # Valider la configuration
        $isValid = Test-ConfigValue -Config $Config -Rules $rules

        # Mettre à jour le rapport de validation
        $validationReport.IsValid = $isValid

        # Retourner le résultat
        if ($Detailed) {
            return $validationReport
        } else {
            return $isValid
        }
    } catch {
        Write-Error "Erreur lors de la validation de la configuration : $_"

        if ($Detailed) {
            return @{
                IsValid       = $false
                Errors        = @("Erreur lors de la validation de la configuration : $_")
                Warnings      = @()
                MissingKeys   = @()
                InvalidTypes  = @()
                InvalidValues = @()
            }
        } else {
            return $false
        }
    }
}

<#
.SYNOPSIS
    Sauvegarde une configuration dans un fichier.

.DESCRIPTION
    Cette fonction sauvegarde une configuration dans un fichier JSON ou YAML.

.PARAMETER Config
    Configuration à sauvegarder.

.PARAMETER ConfigFile
    Chemin vers le fichier de configuration.

.PARAMETER Format
    Format du fichier de configuration (JSON ou YAML).

.EXAMPLE
    Save-Configuration -Config $config -ConfigFile "config.json" -Format "JSON"

.OUTPUTS
    None
#>
function Save-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $true)]
        [string]$ConfigFile,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "YAML")]
        [string]$Format = "JSON"
    )

    # Créer le répertoire parent s'il n'existe pas
    $parentDir = Split-Path -Parent $ConfigFile
    if (-not [string]::IsNullOrEmpty($parentDir) -and -not (Test-Path -Path $parentDir)) {
        New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
    }

    switch ($Format) {
        "JSON" {
            $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFile -Encoding UTF8
        }
        "YAML" {
            # Vérifier si le module PowerShell-Yaml est installé
            if (-not (Get-Module -ListAvailable -Name "powershell-yaml")) {
                throw "Le module PowerShell-Yaml est requis pour sauvegarder des fichiers YAML. Installez-le avec : Install-Module -Name powershell-yaml -Force"
            }

            Import-Module -Name "powershell-yaml"
            $Config | ConvertTo-Yaml | Set-Content -Path $ConfigFile -Encoding UTF8
        }
    }
}

<#
.SYNOPSIS
    Applique les valeurs par défaut à une configuration.

.DESCRIPTION
    Cette fonction applique les valeurs par défaut à une configuration incomplète.
    Elle utilise les règles de validation pour déterminer les valeurs par défaut à appliquer.

.PARAMETER Config
    Configuration à compléter.

.PARAMETER ValidationRules
    Règles de validation personnalisées sous forme de hashtable.

.PARAMETER DefaultConfig
    Configuration par défaut à utiliser. Si non spécifiée, la configuration par défaut du module est utilisée.

.EXAMPLE
    $completeConfig = Set-DefaultConfiguration -Config $config

.EXAMPLE
    $customRules = @{
        "General.LogLevel" = @{
            DefaultValue = "INFO"
        }
    }
    $completeConfig = Set-DefaultConfiguration -Config $config -ValidationRules $customRules

.OUTPUTS
    System.Collections.Hashtable
#>
function Set-DefaultConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $false)]
        [hashtable]$ValidationRules = @{},

        [Parameter(Mandatory = $false)]
        [hashtable]$DefaultConfig = $null
    )

    try {
        # Utiliser la configuration par défaut du module si non spécifiée
        if ($null -eq $DefaultConfig) {
            $DefaultConfig = Get-DefaultConfiguration
        }

        # Définir les règles de validation par défaut
        $defaultRules = @{
            # Sections principales requises
            "General"                          = @{
                Type         = "Hashtable"
                Required     = $true
                DefaultValue = $DefaultConfig.General
            }
            "Modes"                            = @{
                Type         = "Hashtable"
                Required     = $true
                DefaultValue = $DefaultConfig.Modes
            }
            "Paths"                            = @{
                Type         = "Hashtable"
                Required     = $true
                DefaultValue = $DefaultConfig.Paths
            }

            # Clés requises dans la section General
            "General.LogLevel"                 = @{
                Type         = "String"
                Required     = $true
                DefaultValue = $DefaultConfig.General.LogLevel
            }
            "General.LogPath"                  = @{
                Type         = "String"
                Required     = $true
                DefaultValue = $DefaultConfig.General.LogPath
            }
            "General.OutputFormat"             = @{
                Type         = "String"
                Required     = $true
                DefaultValue = $DefaultConfig.General.OutputFormat
            }
            "General.BackupBeforeModification" = @{
                Type         = "Boolean"
                Required     = $false
                DefaultValue = $DefaultConfig.General.BackupBeforeModification
            }

            # Clés requises dans la section Paths
            "Paths.ModulePath"                 = @{
                Type         = "String"
                Required     = $true
                DefaultValue = $DefaultConfig.Paths.ModulePath
            }
            "Paths.FunctionsPath"              = @{
                Type         = "String"
                Required     = $true
                DefaultValue = $DefaultConfig.Paths.FunctionsPath
            }
            "Paths.OutputPath"                 = @{
                Type         = "String"
                Required     = $true
                DefaultValue = $DefaultConfig.Paths.OutputPath
            }
        }

        # Ajouter les règles pour chaque mode
        foreach ($mode in $DefaultConfig.Modes.Keys) {
            $defaultRules["Modes.$mode"] = @{
                Type         = "Hashtable"
                Required     = $true
                DefaultValue = $DefaultConfig.Modes[$mode]
            }
        }

        # Fusionner les règles par défaut avec les règles personnalisées
        $rules = Merge-Configuration -DefaultConfig $defaultRules -CustomConfig $ValidationRules

        # Fonction pour obtenir une valeur à partir d'un chemin
        function Get-ConfigValue {
            param(
                [hashtable]$Config,
                [string]$Path
            )

            $parts = $Path -split "\."
            $current = $Config

            foreach ($part in $parts) {
                if (-not $current.ContainsKey($part)) {
                    return $null
                }

                $current = $current[$part]
            }

            return $current
        }

        # Fonction pour définir une valeur à partir d'un chemin
        function Set-ConfigValue {
            param(
                [hashtable]$Config,
                [string]$Path,
                [object]$Value
            )

            $parts = $Path -split "\."
            $current = $Config

            for ($i = 0; $i -lt $parts.Count - 1; $i++) {
                $part = $parts[$i]

                if (-not $current.ContainsKey($part)) {
                    $current[$part] = @{}
                }

                $current = $current[$part]
            }

            $current[$parts[-1]] = $Value
        }

        # Appliquer les valeurs par défaut
        foreach ($rulePath in $rules.Keys) {
            $rule = $rules[$rulePath]

            # Vérifier si la valeur existe
            $value = Get-ConfigValue -Config $Config -Path $rulePath

            if ($null -eq $value -and $null -ne $rule.DefaultValue) {
                # Appliquer la valeur par défaut
                Set-ConfigValue -Config $Config -Path $rulePath -Value $rule.DefaultValue
                Write-Verbose "Valeur par défaut appliquée pour '$rulePath' : $($rule.DefaultValue)"
            }
        }

        return $Config
    } catch {
        Write-Error "Erreur lors de l'application des valeurs par défaut : $_"
        return $Config
    }
}

<#
.SYNOPSIS
    Convertit une configuration en chaîne de caractères.

.DESCRIPTION
    Cette fonction convertit une configuration en chaîne de caractères au format JSON ou YAML.

.PARAMETER Config
    Configuration à convertir.

.PARAMETER Format
    Format de sortie (JSON ou YAML).

.PARAMETER Depth
    Profondeur maximale de conversion pour le format JSON.

.EXAMPLE
    $jsonString = Convert-ConfigurationToString -Config $config -Format "JSON"

.OUTPUTS
    System.String
#>
function Convert-ConfigurationToString {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Config,

        [Parameter(Mandatory = $false)]
        [ValidateSet("JSON", "YAML")]
        [string]$Format = "JSON",

        [Parameter(Mandatory = $false)]
        [int]$Depth = 10
    )

    try {
        switch ($Format) {
            "JSON" {
                return $Config | ConvertTo-Json -Depth $Depth
            }
            "YAML" {
                # Vérifier si le module PowerShell-Yaml est installé
                if (-not (Get-Module -ListAvailable -Name "powershell-yaml")) {
                    throw "Le module PowerShell-Yaml est requis pour convertir en YAML. Installez-le avec : Install-Module -Name powershell-yaml -Force"
                }

                Import-Module -Name "powershell-yaml"
                return $Config | ConvertTo-Yaml
            }
        }
    } catch {
        Write-Error "Erreur lors de la conversion de la configuration : $_"
        return $null
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Get-DefaultConfiguration, Get-Configuration, Merge-Configuration, Test-Configuration, Save-Configuration, Set-DefaultConfiguration, Convert-ConfigurationToString
