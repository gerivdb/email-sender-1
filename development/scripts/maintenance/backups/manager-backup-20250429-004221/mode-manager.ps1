<#
.SYNOPSIS
    Script de gestion des modes opÃ©rationnels du projet.

.DESCRIPTION
    Ce script permet de gÃ©rer les diffÃ©rents modes opÃ©rationnels du projet (ARCHI, CHECK, C-BREAK, DEBUG, DEV-R, GRAN, OPTI, PREDIC, REVIEW, TEST).
    Il offre une interface unifiÃ©e pour basculer entre les modes, configurer les paramÃ¨tres et exÃ©cuter les modes de maniÃ¨re cohÃ©rente.

.PARAMETER Mode
    Le mode Ã  exÃ©cuter. Valeurs possibles : ARCHI, CHECK, C-BREAK, DEBUG, DEV-R, GRAN, OPTI, PREDIC, REVIEW, TEST.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap ou le document actif.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  traiter (ex: "1.2.3").

.PARAMETER ConfigPath
    Chemin vers le fichier de configuration. Par dÃ©faut, utilise le fichier de configuration standard.

.PARAMETER Force
    Indique si les modifications doivent Ãªtre appliquÃ©es sans confirmation.

.PARAMETER ListModes
    Affiche la liste des modes disponibles et leurs descriptions.

.PARAMETER ShowConfig
    Affiche la configuration actuelle du mode spÃ©cifiÃ©.

.PARAMETER Chain
    ChaÃ®ne de modes Ã  exÃ©cuter sÃ©quentiellement (ex: "GRAN,DEV-R,CHECK").

.EXAMPLE
    .\mode-manager.ps1 -Mode CHECK -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3" -Force
    ExÃ©cute le mode CHECK sur la tÃ¢che 1.2.3 du fichier spÃ©cifiÃ© avec l'option Force.

.EXAMPLE
    .\mode-manager.ps1 -Mode GRAN -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
    ExÃ©cute le mode GRAN sur la tÃ¢che 1.2.3 du fichier spÃ©cifiÃ©.

.EXAMPLE
    .\mode-manager.ps1 -ListModes
    Affiche la liste des modes disponibles et leurs descriptions.

.EXAMPLE
    .\mode-manager.ps1 -Chain "GRAN,DEV-R,CHECK" -FilePath "docs\plans\plan-modes-stepup.md" -TaskIdentifier "1.2.3"
    ExÃ©cute sÃ©quentiellement les modes GRAN, DEV-R et CHECK sur la tÃ¢che 1.2.3 du fichier spÃ©cifiÃ©.

.NOTES
    Auteur: Mode Manager Team
    Version: 1.0
    Date de crÃ©ation: 2023-08-15
#>

[CmdletBinding(DefaultParameterSetName = "Execute")]
param (
    [Parameter(Mandatory = $false, ParameterSetName = "Execute")]
    [ValidateSet("ARCHI", "CHECK", "C-BREAK", "DEBUG", "DEV-R", "GRAN", "OPTI", "PREDIC", "REVIEW", "TEST")]
    [string]$Mode,

    [Parameter(Mandatory = $false, ParameterSetName = "Execute")]
    [string]$FilePath,

    [Parameter(Mandatory = $false, ParameterSetName = "Execute")]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false, ParameterSetName = "Execute")]
    [string]$ConfigPath,

    [Parameter(Mandatory = $false, ParameterSetName = "Execute")]
    [switch]$Force,

    [Parameter(Mandatory = $true, ParameterSetName = "List")]
    [switch]$ListModes,

    [Parameter(Mandatory = $true, ParameterSetName = "ShowConfig")]
    [switch]$ShowConfig,

    [Parameter(Mandatory = $false, ParameterSetName = "Chain")]
    [string]$Chain
)

# DÃ©finir le chemin du projet
$projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
if (-not (Test-Path -Path $projectRoot)) {
    $projectRoot = $PSScriptRoot
    while ((Split-Path -Path $projectRoot -Leaf) -ne "EMAIL_SENDER_1" -and (Split-Path -Path $projectRoot) -ne "") {
        $projectRoot = Split-Path -Path $projectRoot
    }
}

# DÃ©finir le chemin de configuration par dÃ©faut
if (-not $ConfigPath) {
    $possibleConfigPaths = @(
        (Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\config\config.json"),
        (Join-Path -Path $projectRoot -ChildPath "tools\scripts\roadmap-parser\config\config.json")
    )

    foreach ($path in $possibleConfigPaths) {
        if (Test-Path -Path $path) {
            $ConfigPath = $path
            break
        }
    }

    if (-not $ConfigPath) {
        Write-Warning "Aucun fichier de configuration trouvÃ©. Utilisation des paramÃ¨tres par dÃ©faut."
        $ConfigPath = Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\config\config.json"
    }
}

# Fonction pour charger la configuration
function Get-ModeConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if (Test-Path -Path $ConfigPath) {
        try {
            $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
            return $config
        }
        catch {
            Write-Warning "Erreur lors du chargement de la configuration : $_"
        }
    }
    else {
        Write-Warning "Fichier de configuration introuvable : $ConfigPath"
    }

    # Configuration par dÃ©faut
    return [PSCustomObject]@{
        General = [PSCustomObject]@{
            RoadmapPath = "docs\plans\roadmap_complete_2.md"
            ActiveDocumentPath = "docs\plans\plan-modes-stepup.md"
            ReportPath = "reports"
        }
        Modes = [PSCustomObject]@{
            Check = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\check.ps1"
            }
            Debug = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\roadmap\parser\modes\debug\debug-mode.ps1"
            }
            Archi = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\archi-mode.ps1"
            }
            CBreak = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\c-break-mode.ps1"
            }
            Gran = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\roadmap\parser\modes\gran\gran-mode.ps1"
            }
            DevR = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\roadmap\parser\modes\dev-r\dev-r-mode.ps1"
            }
            Opti = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\opti-mode.ps1"
            }
            Predic = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\predic-mode.ps1"
            }
            Review = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\review-mode.ps1"
            }
            Test = [PSCustomObject]@{
                Enabled = $true
                ScriptPath = "development\scripts\maintenance\modes\test-mode.ps1"
            }
        }
    }
}

# Fonction pour obtenir le chemin du script d'un mode
function Get-ModeScriptPath {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Mode,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )

    $modeKey = switch ($Mode) {
        "ARCHI" { "Archi" }
        "CHECK" { "Check" }
        "C-BREAK" { "CBreak" }
        "DEBUG" { "Debug" }
        "DEV-R" { "DevR" }
        "GRAN" { "Gran" }
        "OPTI" { "Opti" }
        "PREDIC" { "Predic" }
        "REVIEW" { "Review" }
        "TEST" { "Test" }
        default { throw "Mode non reconnu : $Mode" }
    }

    if ($Config.Modes.$modeKey -and $Config.Modes.$modeKey.ScriptPath) {
        $scriptPath = $Config.Modes.$modeKey.ScriptPath
        
        # Convertir le chemin relatif en chemin absolu si nÃ©cessaire
        if (-not [System.IO.Path]::IsPathRooted($scriptPath)) {
            $scriptPath = Join-Path -Path $projectRoot -ChildPath $scriptPath
        }
        
        return $scriptPath
    }
    
    # Recherche alternative si le chemin n'est pas trouvÃ© dans la configuration
    $possiblePaths = @(
        (Join-Path -Path $projectRoot -ChildPath "development\scripts\maintenance\modes\$($Mode.ToLower())-mode.ps1"),
        (Join-Path -Path $projectRoot -ChildPath "development\roadmap\parser\modes\$($Mode.ToLower())\$($Mode.ToLower())-mode.ps1"),
        (Join-Path -Path $projectRoot -ChildPath "tools\scripts\roadmap-parser\modes\$($Mode.ToLower())\$($Mode.ToLower())-mode.ps1")
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path -Path $path) {
            return $path
        }
    }
    
    throw "Script pour le mode $Mode introuvable."
}

# Fonction pour afficher la liste des modes disponibles
function Show-AvailableModes {
    [CmdletBinding()]
    param ()
    
    $modes = @{
        "ARCHI" = "Structurer, modÃ©liser, anticiper les dÃ©pendances"
        "CHECK" = "VÃ©rifier l'Ã©tat d'avancement des tÃ¢ches"
        "C-BREAK" = "DÃ©tecter et rÃ©soudre les dÃ©pendances circulaires"
        "DEBUG" = "Isoler, comprendre, corriger les anomalies"
        "DEV-R" = "ImplÃ©menter ce qui est dans la roadmap"
        "GRAN" = "DÃ©composer les blocs complexes"
        "OPTI" = "RÃ©duire complexitÃ©, taille ou temps d'exÃ©cution"
        "PREDIC" = "Anticiper performances, dÃ©tecter anomalies, analyser tendances"
        "REVIEW" = "VÃ©rifier lisibilitÃ©, standards, documentation"
        "TEST" = "Maximiser couverture et fiabilitÃ©"
    }
    
    Write-Host "Modes disponibles :" -ForegroundColor Cyan
    Write-Host "===================" -ForegroundColor Cyan
    
    foreach ($key in $modes.Keys | Sort-Object) {
        Write-Host "$key".PadRight(10) -ForegroundColor Yellow -NoNewline
        Write-Host " : $($modes[$key])"
    }
    
    Write-Host "`nExemples d'utilisation :" -ForegroundColor Cyan
    Write-Host "======================" -ForegroundColor Cyan
    Write-Host ".\mode-manager.ps1 -Mode CHECK -FilePath `"docs\plans\plan-modes-stepup.md`" -TaskIdentifier `"1.2.3`" -Force"
    Write-Host ".\mode-manager.ps1 -Chain `"GRAN,DEV-R,CHECK`" -FilePath `"docs\plans\plan-modes-stepup.md`" -TaskIdentifier `"1.2.3`""
}

# Fonction pour afficher la configuration d'un mode
function Show-ModeConfiguration {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Mode,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )
    
    $modeKey = switch ($Mode) {
        "ARCHI" { "Archi" }
        "CHECK" { "Check" }
        "C-BREAK" { "CBreak" }
        "DEBUG" { "Debug" }
        "DEV-R" { "DevR" }
        "GRAN" { "Gran" }
        "OPTI" { "Opti" }
        "PREDIC" { "Predic" }
        "REVIEW" { "Review" }
        "TEST" { "Test" }
        default { throw "Mode non reconnu : $Mode" }
    }
    
    if ($Config.Modes.$modeKey) {
        $modeConfig = $Config.Modes.$modeKey
        
        Write-Host "Configuration du mode $Mode :" -ForegroundColor Cyan
        Write-Host "=============================" -ForegroundColor Cyan
        
        $modeConfig | Format-List
    }
    else {
        Write-Warning "Configuration pour le mode $Mode introuvable."
    }
}

# Fonction pour exÃ©cuter un mode
function Invoke-Mode {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Mode,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifier,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )
    
    try {
        # Obtenir le chemin du script du mode
        $scriptPath = Get-ModeScriptPath -Mode $Mode -Config $Config
        
        # VÃ©rifier que le script existe
        if (-not (Test-Path -Path $scriptPath)) {
            throw "Le script pour le mode $Mode est introuvable Ã  l'emplacement : $scriptPath"
        }
        
        # Construire les paramÃ¨tres pour le script
        $params = @{}
        
        if ($FilePath) {
            $params["FilePath"] = $FilePath
        }
        elseif ($Config.General.RoadmapPath) {
            $params["FilePath"] = $Config.General.RoadmapPath
            
            # Convertir le chemin relatif en chemin absolu si nÃ©cessaire
            if (-not [System.IO.Path]::IsPathRooted($params["FilePath"])) {
                $params["FilePath"] = Join-Path -Path $projectRoot -ChildPath $params["FilePath"]
            }
        }
        
        if ($TaskIdentifier) {
            $params["TaskIdentifier"] = $TaskIdentifier
        }
        
        if ($ConfigPath) {
            $params["ConfigPath"] = $ConfigPath
        }
        
        if ($Force) {
            $params["Force"] = $true
        }
        
        # Ajouter des paramÃ¨tres spÃ©cifiques au mode
        switch ($Mode) {
            "CHECK" {
                $params["CheckActiveDocument"] = $true
                if (-not $params.ContainsKey("ActiveDocumentPath") -and $Config.General.ActiveDocumentPath) {
                    $params["ActiveDocumentPath"] = $Config.General.ActiveDocumentPath
                    
                    # Convertir le chemin relatif en chemin absolu si nÃ©cessaire
                    if (-not [System.IO.Path]::IsPathRooted($params["ActiveDocumentPath"])) {
                        $params["ActiveDocumentPath"] = Join-Path -Path $projectRoot -ChildPath $params["ActiveDocumentPath"]
                    }
                }
            }
            "GRAN" {
                if (-not $params.ContainsKey("SubTasksFile") -and $Config.Modes.Gran.SubTasksFile) {
                    $params["SubTasksFile"] = $Config.Modes.Gran.SubTasksFile
                    
                    # Convertir le chemin relatif en chemin absolu si nÃ©cessaire
                    if (-not [System.IO.Path]::IsPathRooted($params["SubTasksFile"])) {
                        $params["SubTasksFile"] = Join-Path -Path $projectRoot -ChildPath $params["SubTasksFile"]
                    }
                }
            }
            "DEBUG" {
                if (-not $params.ContainsKey("ErrorLog") -and $Config.Modes.Debug.ErrorLog) {
                    $params["ErrorLog"] = $Config.Modes.Debug.ErrorLog
                    
                    # Convertir le chemin relatif en chemin absolu si nÃ©cessaire
                    if (-not [System.IO.Path]::IsPathRooted($params["ErrorLog"])) {
                        $params["ErrorLog"] = Join-Path -Path $projectRoot -ChildPath $params["ErrorLog"]
                    }
                }
                else {
                    $params["ErrorLog"] = Join-Path -Path $projectRoot -ChildPath "logs\error.log"
                }
                
                if (-not $params.ContainsKey("ScriptPath") -and $Config.Modes.Debug.ScriptPath) {
                    $params["ScriptPath"] = $Config.Modes.Debug.ScriptPath
                    
                    # Convertir le chemin relatif en chemin absolu si nÃ©cessaire
                    if (-not [System.IO.Path]::IsPathRooted($params["ScriptPath"])) {
                        $params["ScriptPath"] = Join-Path -Path $projectRoot -ChildPath $params["ScriptPath"]
                    }
                }
                else {
                    $params["ScriptPath"] = Join-Path -Path $projectRoot -ChildPath "scripts"
                }
            }
        }
        
        # ExÃ©cuter le script avec les paramÃ¨tres
        Write-Host "ExÃ©cution du mode $Mode avec les paramÃ¨tres suivants :" -ForegroundColor Cyan
        $params | Format-Table -AutoSize
        
        & $scriptPath @params
        
        if ($LASTEXITCODE -ne 0) {
            throw "Erreur lors de l'exÃ©cution du mode $Mode. Code de sortie : $LASTEXITCODE"
        }
        
        Write-Host "Mode $Mode exÃ©cutÃ© avec succÃ¨s." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Erreur lors de l'exÃ©cution du mode $Mode : $_"
        return $false
    }
}

# Fonction pour exÃ©cuter une chaÃ®ne de modes
function Invoke-ModeChain {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Chain,
        
        [Parameter(Mandatory = $false)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [string]$TaskIdentifier,
        
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force,
        
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Config
    )
    
    $modes = $Chain -split ',' | ForEach-Object { $_.Trim() }
    
    Write-Host "ExÃ©cution de la chaÃ®ne de modes : $Chain" -ForegroundColor Cyan
    
    foreach ($mode in $modes) {
        Write-Host "`nExÃ©cution du mode $mode..." -ForegroundColor Yellow
        
        $success = Invoke-Mode -Mode $mode -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ConfigPath $ConfigPath -Force:$Force -Config $Config
        
        if (-not $success) {
            Write-Warning "ArrÃªt de la chaÃ®ne de modes suite Ã  l'Ã©chec du mode $mode."
            return $false
        }
    }
    
    Write-Host "`nChaÃ®ne de modes exÃ©cutÃ©e avec succÃ¨s." -ForegroundColor Green
    return $true
}

# Charger la configuration
$config = Get-ModeConfiguration -ConfigPath $ConfigPath

# Traiter les paramÃ¨tres
if ($ListModes) {
    Show-AvailableModes
}
elseif ($ShowConfig) {
    if ($Mode) {
        Show-ModeConfiguration -Mode $Mode -Config $config
    }
    else {
        Write-Host "Configuration gÃ©nÃ©rale :" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan
        $config.General | Format-List
        
        Write-Host "`nConfiguration des modes :" -ForegroundColor Cyan
        Write-Host "======================" -ForegroundColor Cyan
        $config.Modes | Format-List
    }
}
elseif ($Chain) {
    Invoke-ModeChain -Chain $Chain -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ConfigPath $ConfigPath -Force:$Force -Config $config
}
elseif ($Mode) {
    Invoke-Mode -Mode $Mode -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ConfigPath $ConfigPath -Force:$Force -Config $config
}
else {
    Write-Host "Aucune action spÃ©cifiÃ©e. Utilisez -Mode, -Chain, -ListModes ou -ShowConfig." -ForegroundColor Yellow
    Show-AvailableModes
}
