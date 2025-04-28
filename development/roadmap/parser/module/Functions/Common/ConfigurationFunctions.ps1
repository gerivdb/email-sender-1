<#
.SYNOPSIS
    Fonctions de gestion de la configuration pour les modes RoadmapParser.

.DESCRIPTION
    Ce script contient des fonctions pour charger, fusionner et valider les configurations
    utilisÃ©es par les diffÃ©rents modes de RoadmapParser.

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

<#
.SYNOPSIS
    Retourne la configuration par dÃ©faut pour les modes RoadmapParser.

.DESCRIPTION
    Cette fonction retourne un objet contenant la configuration par dÃ©faut
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
        # Configuration gÃ©nÃ©rale
        General = @{
            LogLevel                 = "INFO"
            LogPath                  = "logs"
            LogRetentionDays         = 30
            OutputFormat             = "Markdown"
            BackupBeforeModification = $true
            MaxConcurrentTasks       = 4
        }

        # Configuration spÃ©cifique aux modes
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
    Charge une configuration Ã  partir d'un fichier.

.DESCRIPTION
    Cette fonction charge une configuration Ã  partir d'un fichier JSON ou YAML.
    Elle peut Ã©galement dÃ©tecter automatiquement le format du fichier si l'extension n'est pas spÃ©cifiÃ©e.

.PARAMETER ConfigFile
    Chemin vers le fichier de configuration.

.PARAMETER Format
    Format du fichier de configuration (Auto, JSON ou YAML). Par dÃ©faut, le format est dÃ©tectÃ© automatiquement.

.PARAMETER ApplyDefaults
    Indique si les valeurs par dÃ©faut doivent Ãªtre appliquÃ©es Ã  la configuration chargÃ©e.

.PARAMETER Validate
    Indique si la configuration chargÃ©e doit Ãªtre validÃ©e.

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
        Write-Error "Le fichier de configuration est introuvable Ã  l'emplacement : $ConfigFile"
        return $null
    }

    try {
        # DÃ©terminer le format du fichier
        if ($Format -eq "Auto") {
            $extension = [System.IO.Path]::GetExtension($ConfigFile).ToLower()

            if ($extension -eq ".json") {
                $Format = "JSON"
            } elseif ($extension -eq ".yaml" -or $extension -eq ".yml") {
                $Format = "YAML"
            } else {
                # Essayer de dÃ©tecter le format en lisant le contenu du fichier
                $content = Get-Content -Path $ConfigFile -Raw

                if ($content -match '^\s*{') {
                    $Format = "JSON"
                } elseif ($content -match '^\s*---') {
                    $Format = "YAML"
                } else {
                    Write-Warning "Impossible de dÃ©tecter automatiquement le format du fichier. Utilisation du format JSON par dÃ©faut."
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
                # VÃ©rifier si le module PowerShell-Yaml est installÃ©
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

        # Appliquer les valeurs par dÃ©faut si demandÃ©
        if ($ApplyDefaults) {
            $defaultConfig = Get-DefaultConfiguration
            $config = Merge-Configuration -DefaultConfig $defaultConfig -CustomConfig $config
        }

        # Valider la configuration si demandÃ©
        if ($Validate) {
            $isValid = Test-Configuration -Config $config
            if (-not $isValid) {
                Write-Warning "La configuration chargÃ©e n'est pas valide. Utilisez Test-Configuration pour plus de dÃ©tails."
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
    Cette fonction fusionne une configuration personnalisÃ©e avec la configuration par dÃ©faut.
    Les valeurs de la configuration personnalisÃ©e remplacent celles de la configuration par dÃ©faut.
    DiffÃ©rentes stratÃ©gies de fusion peuvent Ãªtre utilisÃ©es pour contrÃ´ler le comportement de fusion.

.PARAMETER DefaultConfig
    Configuration par dÃ©faut.

.PARAMETER CustomConfig
    Configuration personnalisÃ©e.

.PARAMETER Strategy
    StratÃ©gie de fusion Ã  utiliser. Les valeurs possibles sont :
    - Replace : Les valeurs de CustomConfig remplacent celles de DefaultConfig (par dÃ©faut)
    - Append : Les valeurs de CustomConfig sont ajoutÃ©es Ã  celles de DefaultConfig (pour les tableaux)
    - KeepExisting : Les valeurs existantes dans DefaultConfig sont conservÃ©es si elles existent dÃ©jÃ 

.PARAMETER ExcludeSections
    Sections Ã  exclure de la fusion.

.PARAMETER IncludeSections
    Sections Ã  inclure dans la fusion. Si spÃ©cifiÃ©, seules ces sections seront fusionnÃ©es.

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

        # Fonction rÃ©cursive pour fusionner les hashtables
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

                # VÃ©rifier si la section doit Ãªtre exclue
                if ($ExcludeSections -contains $keyPath) {
                    Write-Verbose "Section exclue de la fusion : $keyPath"
                    continue
                }

                # VÃ©rifier si la section doit Ãªtre incluse (si IncludeSections est spÃ©cifiÃ©)
                if ($IncludeSections.Count -gt 0 -and -not ($IncludeSections -contains $keyPath) -and -not ($IncludeSections | Where-Object { $keyPath -like "$_*" })) {
                    Write-Verbose "Section non incluse dans la fusion : $keyPath"
                    continue
                }

                if ($Target.ContainsKey($key)) {
                    if ($Target[$key] -is [hashtable] -and $Source[$key] -is [hashtable]) {
                        # Fusion rÃ©cursive des hashtables
                        Merge-Hashtable -Target $Target[$key] -Source $Source[$key] -CurrentPath $keyPath -Strategy $Strategy -ExcludeSections $ExcludeSections -IncludeSections $IncludeSections
                    } elseif ($Target[$key] -is [array] -and $Source[$key] -is [array] -and $Strategy -eq "Append") {
                        # Fusion des tableaux en mode Append
                        $Target[$key] = @($Target[$key]) + @($Source[$key]) | Select-Object -Unique
                    } elseif ($Strategy -eq "KeepExisting") {
                        # Ne rien faire, conserver la valeur existante
                        Write-Verbose "Valeur existante conservÃ©e pour $keyPath : $($Target[$key])"
                    } else {
                        # Remplacement de la valeur (stratÃ©gie par dÃ©faut)
                        $Target[$key] = $Source[$key]
                    }
                } else {
                    # Ajout de la nouvelle clÃ©
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
    Cette fonction vÃ©rifie qu'une configuration contient toutes les clÃ©s requises
    et que les valeurs sont du type attendu. Elle peut Ã©galement valider des rÃ¨gles
    personnalisÃ©es et vÃ©rifier les types de donnÃ©es.

.PARAMETER Config
    Configuration Ã  valider.

.PARAMETER ValidationRules
    RÃ¨gles de validation personnalisÃ©es sous forme de hashtable.

.PARAMETER SkipMissingKeys
    Indique si les clÃ©s manquantes doivent Ãªtre ignorÃ©es lors de la validation.

.PARAMETER Detailed
    Indique si un rapport de validation dÃ©taillÃ© doit Ãªtre gÃ©nÃ©rÃ©.

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
    System.Boolean ou System.Collections.Hashtable (si -Detailed est spÃ©cifiÃ©)
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

        # DÃ©finir les rÃ¨gles de validation par dÃ©faut
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

            # ClÃ©s requises dans la section General
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

            # ClÃ©s requises dans la section Paths
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

        # Fusionner les rÃ¨gles par dÃ©faut avec les rÃ¨gles personnalisÃ©es
        $rules = Merge-Configuration -DefaultConfig $defaultRules -CustomConfig $ValidationRules

        # Fonction rÃ©cursive pour valider la configuration
        function Test-ConfigValue {
            param(
                [hashtable]$Config,
                [hashtable]$Rules,
                [string]$CurrentPath = ""
            )

            $localValid = $true

            # Valider les rÃ¨gles pour le chemin actuel
            foreach ($rulePath in $Rules.Keys) {
                $rule = $Rules[$rulePath]

                # Ignorer les rÃ¨gles qui ne commencent pas par le chemin actuel
                if ($CurrentPath -and -not $rulePath.StartsWith($CurrentPath)) {
                    continue
                }

                # Obtenir le chemin relatif Ã  partir du chemin actuel
                $relativePath = if ($CurrentPath -and $rulePath.Length -gt $CurrentPath.Length) {
                    $rulePath.Substring($CurrentPath.Length + 1)
                } else {
                    $rulePath
                }

                # Ignorer les rÃ¨gles qui contiennent des points (sous-chemins) Ã  ce niveau
                if ($relativePath -and $relativePath.Contains(".")) {
                    continue
                }

                # Construire le chemin complet pour la valeur Ã  valider
                $valuePath = if ($CurrentPath) { "$CurrentPath.$relativePath" } else { $relativePath }

                # Obtenir la valeur Ã  valider
                $value = Get-ConfigValue -Config $Config -Path $valuePath

                # VÃ©rifier si la valeur existe
                if ($null -eq $value) {
                    if ($rule.Required -and -not $SkipMissingKeys) {
                        $validationReport.MissingKeys += $valuePath
                        $validationReport.Errors += "La clÃ© requise '$valuePath' est manquante."
                        $validationReport.IsValid = $false
                        $localValid = $false
                        Write-Warning "La clÃ© requise '$valuePath' est manquante."
                    } elseif ($null -ne $rule.DefaultValue) {
                        # Appliquer la valeur par dÃ©faut
                        Set-ConfigValue -Config $Config -Path $valuePath -Value $rule.DefaultValue
                        Write-Verbose "Valeur par dÃ©faut appliquÃ©e pour '$valuePath' : $($rule.DefaultValue)"
                    }
                } else {
                    # VÃ©rifier le type de la valeur
                    $typeValid = Test-ConfigValueType -Value $value -ExpectedType $rule.Type
                    if (-not $typeValid) {
                        $validationReport.InvalidTypes += $valuePath
                        $validationReport.Errors += "La valeur de '$valuePath' n'est pas du type attendu ($($rule.Type))."
                        $validationReport.IsValid = $false
                        $localValid = $false
                        Write-Warning "La valeur de '$valuePath' n'est pas du type attendu ($($rule.Type))."
                    }

                    # VÃ©rifier les valeurs autorisÃ©es
                    if ($rule.AllowedValues -and $value -notin $rule.AllowedValues) {
                        $validationReport.InvalidValues += $valuePath
                        $validationReport.Errors += "La valeur de '$valuePath' ($value) n'est pas autorisÃ©e. Valeurs autorisÃ©es : $($rule.AllowedValues -join ', ')"
                        $validationReport.IsValid = $false
                        $localValid = $false
                        Write-Warning "La valeur de '$valuePath' ($value) n'est pas autorisÃ©e. Valeurs autorisÃ©es : $($rule.AllowedValues -join ', ')"
                    }

                    # VÃ©rifier les rÃ¨gles personnalisÃ©es
                    if ($rule.Validator -is [scriptblock]) {
                        $validatorResult = & $rule.Validator $value
                        if (-not $validatorResult) {
                            $validationReport.InvalidValues += $valuePath
                            $validationReport.Errors += "La valeur de '$valuePath' ($value) n'a pas passÃ© la validation personnalisÃ©e."
                            $validationReport.IsValid = $false
                            $localValid = $false
                            Write-Warning "La valeur de '$valuePath' ($value) n'a pas passÃ© la validation personnalisÃ©e."
                        }
                    }

                    # Si la valeur est un hashtable, valider rÃ©cursivement
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

        # Fonction pour obtenir une valeur Ã  partir d'un chemin
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

        # Fonction pour dÃ©finir une valeur Ã  partir d'un chemin
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

        # Fonction pour vÃ©rifier le type d'une valeur
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

        # Mettre Ã  jour le rapport de validation
        $validationReport.IsValid = $isValid

        # Retourner le rÃ©sultat
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
    Configuration Ã  sauvegarder.

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

    # CrÃ©er le rÃ©pertoire parent s'il n'existe pas
    $parentDir = Split-Path -Parent $ConfigFile
    if (-not [string]::IsNullOrEmpty($parentDir) -and -not (Test-Path -Path $parentDir)) {
        New-Item -Path $parentDir -ItemType Directory -Force | Out-Null
    }

    switch ($Format) {
        "JSON" {
            $Config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigFile -Encoding UTF8
        }
        "YAML" {
            # VÃ©rifier si le module PowerShell-Yaml est installÃ©
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
    Applique les valeurs par dÃ©faut Ã  une configuration.

.DESCRIPTION
    Cette fonction applique les valeurs par dÃ©faut Ã  une configuration incomplÃ¨te.
    Elle utilise les rÃ¨gles de validation pour dÃ©terminer les valeurs par dÃ©faut Ã  appliquer.

.PARAMETER Config
    Configuration Ã  complÃ©ter.

.PARAMETER ValidationRules
    RÃ¨gles de validation personnalisÃ©es sous forme de hashtable.

.PARAMETER DefaultConfig
    Configuration par dÃ©faut Ã  utiliser. Si non spÃ©cifiÃ©e, la configuration par dÃ©faut du module est utilisÃ©e.

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
        # Utiliser la configuration par dÃ©faut du module si non spÃ©cifiÃ©e
        if ($null -eq $DefaultConfig) {
            $DefaultConfig = Get-DefaultConfiguration
        }

        # DÃ©finir les rÃ¨gles de validation par dÃ©faut
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

            # ClÃ©s requises dans la section General
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

            # ClÃ©s requises dans la section Paths
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

        # Ajouter les rÃ¨gles pour chaque mode
        foreach ($mode in $DefaultConfig.Modes.Keys) {
            $defaultRules["Modes.$mode"] = @{
                Type         = "Hashtable"
                Required     = $true
                DefaultValue = $DefaultConfig.Modes[$mode]
            }
        }

        # Fusionner les rÃ¨gles par dÃ©faut avec les rÃ¨gles personnalisÃ©es
        $rules = Merge-Configuration -DefaultConfig $defaultRules -CustomConfig $ValidationRules

        # Fonction pour obtenir une valeur Ã  partir d'un chemin
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

        # Fonction pour dÃ©finir une valeur Ã  partir d'un chemin
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

        # Appliquer les valeurs par dÃ©faut
        foreach ($rulePath in $rules.Keys) {
            $rule = $rules[$rulePath]

            # VÃ©rifier si la valeur existe
            $value = Get-ConfigValue -Config $Config -Path $rulePath

            if ($null -eq $value -and $null -ne $rule.DefaultValue) {
                # Appliquer la valeur par dÃ©faut
                Set-ConfigValue -Config $Config -Path $rulePath -Value $rule.DefaultValue
                Write-Verbose "Valeur par dÃ©faut appliquÃ©e pour '$rulePath' : $($rule.DefaultValue)"
            }
        }

        return $Config
    } catch {
        Write-Error "Erreur lors de l'application des valeurs par dÃ©faut : $_"
        return $Config
    }
}

<#
.SYNOPSIS
    Convertit une configuration en chaÃ®ne de caractÃ¨res.

.DESCRIPTION
    Cette fonction convertit une configuration en chaÃ®ne de caractÃ¨res au format JSON ou YAML.

.PARAMETER Config
    Configuration Ã  convertir.

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
                # VÃ©rifier si le module PowerShell-Yaml est installÃ©
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
