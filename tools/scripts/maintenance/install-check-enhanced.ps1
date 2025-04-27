<#
.SYNOPSIS
    Script d'installation du mode CHECK amÃ©liorÃ©.

.DESCRIPTION
    Ce script installe le mode CHECK amÃ©liorÃ© en :
    1. Mettant Ã  jour les scripts existants pour utiliser la nouvelle fonction amÃ©liorÃ©e
    2. CrÃ©ant des liens symboliques pour assurer la compatibilitÃ© avec les scripts existants
    3. Mettant Ã  jour la documentation

.PARAMETER Force
    Indique si les modifications doivent Ãªtre appliquÃ©es sans confirmation.
    Par dÃ©faut : $false (mode simulation).

.PARAMETER BackupFiles
    Indique si des copies de sauvegarde des fichiers originaux doivent Ãªtre crÃ©Ã©es.
    Par dÃ©faut : $true.

.EXAMPLE
    .\install-check-enhanced.ps1 -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃ©ation: 2025-05-01
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [switch]$BackupFiles = $true
)

# Chemin de base du projet
$basePath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"

# Afficher les informations de dÃ©marrage
Write-Host "Installation du mode CHECK amÃ©liorÃ©" -ForegroundColor Cyan
Write-Host "Mode : " -NoNewline
if ($Force) {
    Write-Host "Installation" -ForegroundColor Yellow
} else {
    Write-Host "Simulation (utilisez -Force pour installer)" -ForegroundColor Gray
}
Write-Host "Sauvegarde des fichiers originaux : " -NoNewline
if ($BackupFiles) {
    Write-Host "ActivÃ©e" -ForegroundColor Green
} else {
    Write-Host "DÃ©sactivÃ©e" -ForegroundColor Yellow
}

# Ã‰tape 1 : Mettre Ã  jour les scripts existants
Write-Host "`nÃ‰tape 1 : Mise Ã  jour des scripts existants" -ForegroundColor Cyan

# CrÃ©er les rÃ©pertoires nÃ©cessaires s'ils n'existent pas
$functionsPath = Join-Path -Path $basePath -ChildPath "tools\scripts\roadmap-parser\module\Functions\Public"
$modesPath = Join-Path -Path $basePath -ChildPath "tools\scripts\roadmap-parser\modes\check"

if (-not (Test-Path -Path $functionsPath)) {
    if ($Force -or $PSCmdlet.ShouldProcess($functionsPath, "CrÃ©er le rÃ©pertoire")) {
        New-Item -Path $functionsPath -ItemType Directory -Force | Out-Null
        Write-Host "  RÃ©pertoire crÃ©Ã© : $functionsPath" -ForegroundColor Green
    } else {
        Write-Host "  Le rÃ©pertoire serait crÃ©Ã© : $functionsPath (mode simulation)" -ForegroundColor Yellow
    }
}

if (-not (Test-Path -Path $modesPath)) {
    if ($Force -or $PSCmdlet.ShouldProcess($modesPath, "CrÃ©er le rÃ©pertoire")) {
        New-Item -Path $modesPath -ItemType Directory -Force | Out-Null
        Write-Host "  RÃ©pertoire crÃ©Ã© : $modesPath" -ForegroundColor Green
    } else {
        Write-Host "  Le rÃ©pertoire serait crÃ©Ã© : $modesPath (mode simulation)" -ForegroundColor Yellow
    }
}

# Copier la fonction amÃ©liorÃ©e
$enhancedFunctionPath = Join-Path -Path $functionsPath -ChildPath "Update-ActiveDocumentCheckboxes-Enhanced.ps1"
$enhancedFunctionContent = @'
<#
.SYNOPSIS
    Met Ã  jour les cases Ã  cocher dans le document actif pour les tÃ¢ches implÃ©mentÃ©es et testÃ©es Ã  100%.
    Version amÃ©liorÃ©e avec support UTF-8 avec BOM.

.DESCRIPTION
    Cette fonction analyse le document actif pour identifier les tÃ¢ches qui ont Ã©tÃ© implÃ©mentÃ©es
    et testÃ©es avec succÃ¨s Ã  100%, puis coche automatiquement les cases correspondantes.
    Cette version amÃ©liorÃ©e garantit que tous les fichiers sont enregistrÃ©s en UTF-8 avec BOM
    et prÃ©serve correctement les caractÃ¨res accentuÃ©s et l'indentation.

.PARAMETER DocumentPath
    Chemin vers le document actif Ã  mettre Ã  jour.

.PARAMETER ImplementationResults
    RÃ©sultats de l'implÃ©mentation des tÃ¢ches (hashtable).

.PARAMETER TestResults
    RÃ©sultats des tests des tÃ¢ches (hashtable).

.EXAMPLE
    Update-ActiveDocumentCheckboxes-Enhanced -DocumentPath "document.md" -ImplementationResults $implResults -TestResults $testResults

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de crÃ©ation: 2023-09-15
    Date de mise Ã  jour: 2025-05-01 - AmÃ©lioration de l'encodage UTF-8 avec BOM
#>
function Update-ActiveDocumentCheckboxes-Enhanced {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [Parameter(Mandatory = $true)]
        [string]$DocumentPath,

        [Parameter(Mandatory = $true)]
        [hashtable]$ImplementationResults,

        [Parameter(Mandatory = $true)]
        [hashtable]$TestResults
    )

    # VÃ©rifier que le document existe
    if (-not (Test-Path -Path $DocumentPath)) {
        Write-Error "Le document spÃ©cifiÃ© n'existe pas : $DocumentPath"
        return 0
    }

    try {
        # Lire le contenu du document avec l'encodage appropriÃ©
        # Utiliser [System.IO.File]::ReadAllLines pour garantir la dÃ©tection correcte de l'encodage
        $content = [System.IO.File]::ReadAllLines($DocumentPath)
        $modified = $false
        $tasksUpdated = 0

        # Parcourir chaque ligne du document
        for ($i = 0; $i -lt $content.Count; $i++) {
            $line = $content[$i]

            # Rechercher les lignes avec des cases Ã  cocher non cochÃ©es
            if ($line -match '^\s*-\s+\[\s*\]') {
                # Extraire le texte de la tÃ¢che en prÃ©servant l'indentation
                $indentation = [regex]::Match($line, '^\s*').Value
                $taskText = $line -replace '^\s*-\s+\[\s*\]\s*', ''

                # Rechercher cette tÃ¢che dans les rÃ©sultats d'implÃ©mentation et de tests
                $taskFound = $false
                $taskComplete = $false
                $matchedTaskId = $null

                # Essayer de trouver l'ID de la tÃ¢che dans le texte
                foreach ($taskId in $ImplementationResults.Keys) {
                    # Ã‰chapper les caractÃ¨res spÃ©ciaux dans l'ID de la tÃ¢che pour la regex
                    $escapedTaskId = [regex]::Escape($taskId)

                    # VÃ©rifier diffÃ©rents formats possibles d'ID de tÃ¢che dans le texte
                    if ($taskText -match "^\*\*$escapedTaskId\*\*" -or
                        $taskText -match "^$escapedTaskId\s" -or
                        $taskText -match "^$escapedTaskId$" -or
                        $taskText -match "\[$escapedTaskId\]" -or
                        $taskText -match "\($escapedTaskId\)" -or
                        # Format spÃ©cifique pour les IDs longs
                        $taskText -match "\*\*$escapedTaskId\*\*") {

                        $taskFound = $true
                        $matchedTaskId = $taskId

                        # VÃ©rifier si l'implÃ©mentation et les tests sont Ã  100%
                        $implementationResult = $ImplementationResults[$taskId]
                        $testResult = $TestResults[$taskId]

                        if ($implementationResult.ImplementationComplete -and
                            $testResult.TestsComplete -and
                            $testResult.TestsSuccessful) {
                            $taskComplete = $true
                        }

                        break
                    }
                }

                # Si aucun ID n'a Ã©tÃ© trouvÃ©, essayer de faire correspondre par titre
                if (-not $taskFound) {
                    foreach ($taskId in $ImplementationResults.Keys) {
                        $implementationResult = $ImplementationResults[$taskId]

                        # VÃ©rifier si le titre de la tÃ¢che correspond
                        if ($implementationResult.TaskTitle -and $taskText -match [regex]::Escape($implementationResult.TaskTitle)) {
                            $taskFound = $true
                            $matchedTaskId = $taskId

                            # VÃ©rifier si l'implÃ©mentation et les tests sont Ã  100%
                            $testResult = $TestResults[$taskId]

                            if ($implementationResult.ImplementationComplete -and
                                $testResult.TestsComplete -and
                                $testResult.TestsSuccessful) {
                                $taskComplete = $true
                            }

                            break
                        }
                    }
                }

                # Si la tÃ¢che a Ã©tÃ© trouvÃ©e et est complÃ¨te, mettre Ã  jour la case Ã  cocher
                if ($taskFound -and $taskComplete) {
                    # Mettre Ã  jour la case Ã  cocher en prÃ©servant l'indentation et le texte complet
                    $newLine = $line -replace '^\s*-\s+\[\s*\]', "$indentation- [x]"
                    $content[$i] = $newLine
                    $modified = $true
                    $tasksUpdated++

                    Write-Verbose "Case Ã  cocher mise Ã  jour pour la tÃ¢che : $taskText (ID: $matchedTaskId)"
                }
            }
        }

        # Enregistrer les modifications si nÃ©cessaire
        if ($modified -and $PSCmdlet.ShouldProcess($DocumentPath, "Mettre Ã  jour les cases Ã  cocher")) {
            # Utiliser UTF-8 avec BOM pour l'enregistrement
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($DocumentPath, $content, $utf8WithBom)

            # VÃ©rifier que le fichier a bien Ã©tÃ© enregistrÃ© en UTF-8 avec BOM
            $bytes = [System.IO.File]::ReadAllBytes($DocumentPath)
            $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

            if (-not $hasBOM) {
                Write-Warning "Le fichier n'a pas Ã©tÃ© correctement enregistrÃ© en UTF-8 avec BOM. Tentative de correction..."
                # Forcer l'encodage UTF-8 avec BOM
                $content = [System.IO.File]::ReadAllText($DocumentPath)
                [System.IO.File]::WriteAllText($DocumentPath, $content, $utf8WithBom)
            }

            Write-Output "$tasksUpdated cases Ã  cocher mises Ã  jour dans le document : $DocumentPath"
        } else {
            Write-Output "$tasksUpdated cases Ã  cocher seraient mises Ã  jour dans le document : $DocumentPath (mode simulation)"
        }

        return $tasksUpdated
    }
    catch {
        Write-Error "Erreur lors de la mise Ã  jour des cases Ã  cocher : $_"
        return 0
    }
}
'@

if ($Force -or $PSCmdlet.ShouldProcess($enhancedFunctionPath, "CrÃ©er la fonction amÃ©liorÃ©e")) {
    # Utiliser UTF-8 avec BOM pour l'enregistrement
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($enhancedFunctionPath, $enhancedFunctionContent, $utf8WithBom)
    Write-Host "  Fonction amÃ©liorÃ©e crÃ©Ã©e : $enhancedFunctionPath" -ForegroundColor Green
} else {
    Write-Host "  La fonction amÃ©liorÃ©e serait crÃ©Ã©e : $enhancedFunctionPath (mode simulation)" -ForegroundColor Yellow
}

# Ã‰tape 2 : CrÃ©er le script check-mode-enhanced.ps1
Write-Host "`nÃ‰tape 2 : CrÃ©ation du script check-mode-enhanced.ps1" -ForegroundColor Cyan

$checkModeEnhancedPath = Join-Path -Path $modesPath -ChildPath "check-mode-enhanced.ps1"
$checkModeEnhancedContent = @'
<#
.SYNOPSIS
    Script pour vÃ©rifier si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es avec succÃ¨s Ã  100% (Mode CHECK).
    Version amÃ©liorÃ©e avec support UTF-8 avec BOM.

.DESCRIPTION
    Ce script permet de vÃ©rifier si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es
    avec succÃ¨s Ã  100%. Si c'est le cas, il peut mettre Ã  jour automatiquement le statut des tÃ¢ches
    dans la roadmap en cochant les cases correspondantes. Il implÃ©mente le mode CHECK dÃ©crit dans
    la documentation des modes de fonctionnement.
    Cette version amÃ©liorÃ©e garantit que tous les fichiers sont enregistrÃ©s en UTF-8 avec BOM.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  vÃ©rifier et mettre Ã  jour.

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  vÃ©rifier (par exemple, "1.2.1.3.2.3").
    Si non spÃ©cifiÃ©, l'utilisateur sera invitÃ© Ã  le saisir.

.PARAMETER ImplementationPath
    Chemin vers le rÃ©pertoire contenant l'implÃ©mentation.
    Si non spÃ©cifiÃ©, le script tentera de le dÃ©duire automatiquement.

.PARAMETER TestsPath
    Chemin vers le rÃ©pertoire contenant les tests.
    Si non spÃ©cifiÃ©, le script tentera de le dÃ©duire automatiquement.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit Ãªtre mise Ã  jour automatiquement.
    Par dÃ©faut : $true.

.PARAMETER GenerateReport
    Indique si un rapport doit Ãªtre gÃ©nÃ©rÃ©.
    Par dÃ©faut : $true.

.PARAMETER ActiveDocumentPath
    Chemin vers le document actif Ã  vÃ©rifier et mettre Ã  jour.
    Si non spÃ©cifiÃ©, le script tentera de dÃ©tecter automatiquement le document actif.

.PARAMETER CheckActiveDocument
    Indique si le document actif doit Ãªtre vÃ©rifiÃ© et mis Ã  jour.
    Par dÃ©faut : $true.

.PARAMETER Force
    Indique si les modifications doivent Ãªtre appliquÃ©es sans confirmation.
    Par dÃ©faut : $false (mode simulation).

.EXAMPLE
    .\check-mode-enhanced.ps1 -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3"

.EXAMPLE
    .\check-mode-enhanced.ps1 -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de crÃ©ation: 2023-08-15
    Date de mise Ã  jour: 2025-05-01 - AmÃ©lioration de l'encodage UTF-8 avec BOM
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param (
    [Parameter(Mandatory = $true)]
    [string]$FilePath,

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$ImplementationPath,

    [Parameter(Mandatory = $false)]
    [string]$TestsPath,

    [Parameter(Mandatory = $false)]
    [switch]$UpdateRoadmap = $true,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport = $true,

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le document actif Ã  vÃ©rifier et mettre Ã  jour. Si non spÃ©cifiÃ©, le document actif sera dÃ©tectÃ© automatiquement.")]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false)]
    [switch]$CheckActiveDocument = $true,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer les fonctions nÃ©cessaires
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $scriptPath)) -ChildPath "module\Functions\Public"
$invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapCheck.ps1"
$updateTaskPath = Join-Path -Path $modulePath -ChildPath "Update-RoadmapTaskStatus.ps1"
$updateCheckboxesPath = Join-Path -Path $modulePath -ChildPath "Update-ActiveDocumentCheckboxes-Enhanced.ps1"

# Si les chemins n'existent pas, essayer d'autres chemins
if (-not (Test-Path -Path $modulePath)) {
    $modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath))) -ChildPath "module\Functions\Public"
    $invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapCheck.ps1"
    $updateTaskPath = Join-Path -Path $modulePath -ChildPath "Update-RoadmapTaskStatus.ps1"
    $updateCheckboxesPath = Join-Path -Path $modulePath -ChildPath "Update-ActiveDocumentCheckboxes-Enhanced.ps1"
}

# Si les chemins n'existent toujours pas, essayer d'autres chemins
if (-not (Test-Path -Path $modulePath)) {
    $modulePath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $scriptPath)))) -ChildPath "module\Functions\Public"
    $invokeCheckPath = Join-Path -Path $modulePath -ChildPath "Invoke-RoadmapCheck.ps1"
    $updateTaskPath = Join-Path -Path $modulePath -ChildPath "Update-RoadmapTaskStatus.ps1"
    $updateCheckboxesPath = Join-Path -Path $modulePath -ChildPath "Update-ActiveDocumentCheckboxes-Enhanced.ps1"
}

# Afficher les chemins pour le dÃ©bogage
Write-Host "Chemin du script : $scriptPath" -ForegroundColor Yellow
Write-Host "Chemin du module : $modulePath" -ForegroundColor Yellow
Write-Host "Chemin de Invoke-RoadmapCheck : $invokeCheckPath" -ForegroundColor Yellow
Write-Host "Chemin de Update-RoadmapTaskStatus : $updateTaskPath" -ForegroundColor Yellow
Write-Host "Chemin de Update-ActiveDocumentCheckboxes-Enhanced : $updateCheckboxesPath" -ForegroundColor Yellow

if (Test-Path -Path $invokeCheckPath) {
    . $invokeCheckPath
    Write-Host "Fonction Invoke-RoadmapCheck importÃ©e." -ForegroundColor Green
} else {
    throw "La fonction Invoke-RoadmapCheck est introuvable Ã  l'emplacement : $invokeCheckPath"
}

if (Test-Path -Path $updateTaskPath) {
    . $updateTaskPath
    Write-Host "Fonction Update-RoadmapTaskStatus importÃ©e." -ForegroundColor Green
} else {
    throw "La fonction Update-RoadmapTaskStatus est introuvable Ã  l'emplacement : $updateTaskPath"
}

if (Test-Path -Path $updateCheckboxesPath) {
    . $updateCheckboxesPath
    Write-Host "Fonction Update-ActiveDocumentCheckboxes-Enhanced importÃ©e." -ForegroundColor Green
} else {
    Write-Warning "La fonction Update-ActiveDocumentCheckboxes-Enhanced est introuvable Ã  l'emplacement : $updateCheckboxesPath. La mise Ã  jour automatique des cases Ã  cocher dans le document actif ne sera pas disponible."
}

# VÃ©rifier que le fichier de roadmap existe
if (-not (Test-Path -Path $FilePath)) {
    throw "Le fichier de roadmap spÃ©cifiÃ© n'existe pas : $FilePath"
}

# DÃ©tecter automatiquement le document actif si nÃ©cessaire
if ($CheckActiveDocument -and -not $ActiveDocumentPath) {
    Write-Host "DÃ©tection automatique du document actif..." -ForegroundColor Cyan

    # MÃ©thode 1: VÃ©rifier la variable d'environnement VSCODE_ACTIVE_DOCUMENT
    if ($env:VSCODE_ACTIVE_DOCUMENT -and (Test-Path -Path $env:VSCODE_ACTIVE_DOCUMENT)) {
        $ActiveDocumentPath = $env:VSCODE_ACTIVE_DOCUMENT
        Write-Host "Document actif dÃ©tectÃ© via variable d'environnement : $ActiveDocumentPath" -ForegroundColor Green
    }
    # MÃ©thode 2: Rechercher les fichiers Markdown rÃ©cemment modifiÃ©s
    else {
        $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
        $recentMdFiles = Get-ChildItem -Path $projectRoot -Filter "*.md" -Recurse |
                         Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-30) } |
                         Sort-Object LastWriteTime -Descending

        if ($recentMdFiles.Count -gt 0) {
            $ActiveDocumentPath = $recentMdFiles[0].FullName
            Write-Host "Document actif dÃ©tectÃ© automatiquement (fichier rÃ©cemment modifiÃ©) : $ActiveDocumentPath" -ForegroundColor Green
        }
        else {
            Write-Warning "Aucun document actif n'a pu Ãªtre dÃ©tectÃ© automatiquement. La vÃ©rification du document actif sera dÃ©sactivÃ©e."
            $CheckActiveDocument = $false
        }
    }
}

# VÃ©rifier si le document actif existe
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    if (-not (Test-Path -Path $ActiveDocumentPath)) {
        Write-Warning "Le document actif spÃ©cifiÃ© n'existe pas : $ActiveDocumentPath. La vÃ©rification du document actif sera dÃ©sactivÃ©e."
        $CheckActiveDocument = $false
    }
}

# Appeler la fonction Invoke-RoadmapCheck
$result = Invoke-RoadmapCheck -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ImplementationPath $ImplementationPath -TestsPath $TestsPath -UpdateRoadmap $UpdateRoadmap -GenerateReport $GenerateReport

# VÃ©rifier et mettre Ã  jour les cases Ã  cocher dans le document actif si demandÃ©
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "`nVÃ©rification et mise Ã  jour des cases Ã  cocher dans le document actif : $ActiveDocumentPath" -ForegroundColor Cyan

    # Extraire les rÃ©sultats d'implÃ©mentation et de tests
    $implementationResults = @{}
    $testResults = @{}

    foreach ($task in $result.Tasks) {
        $implementationResults[$task.Id] = $task.Implementation
        $testResults[$task.Id] = $task.Tests
    }

    # Utiliser la fonction Update-ActiveDocumentCheckboxes-Enhanced si disponible
    if (Get-Command -Name Update-ActiveDocumentCheckboxes-Enhanced -ErrorAction SilentlyContinue) {
        # PrÃ©parer les paramÃ¨tres pour la fonction
        $updateParams = @{
            DocumentPath = $ActiveDocumentPath
            ImplementationResults = $implementationResults
            TestResults = $testResults
        }

        # Ajouter le paramÃ¨tre WhatIf si Force n'est pas spÃ©cifiÃ©
        if (-not $Force) {
            $updateParams.Add("WhatIf", $true)
        }

        # Appeler la fonction avec les paramÃ¨tres
        $updateResult = Update-ActiveDocumentCheckboxes-Enhanced @updateParams
        $tasksUpdated = $updateResult
    } else {
        # MÃ©thode alternative si la fonction n'est pas disponible
        Write-Warning "La fonction Update-ActiveDocumentCheckboxes-Enhanced n'est pas disponible. Utilisation d'une mÃ©thode alternative."

        # Lire le contenu du document actif
        $activeDocumentContent = Get-Content -Path $ActiveDocumentPath -Encoding UTF8
        $tasksUpdated = 0
        $modified = $false

        # Pour chaque tÃ¢che vÃ©rifiÃ©e
        foreach ($task in $result.Tasks) {
            # Si la tÃ¢che est implÃ©mentÃ©e Ã  100% et testÃ©e avec succÃ¨s Ã  100%
            if ($task.Implementation.ImplementationComplete -and $task.Tests.TestsComplete -and $task.Tests.TestsSuccessful) {
                # Rechercher la tÃ¢che dans le document actif (diffÃ©rents formats possibles)
                $taskPatterns = @(
                    "- \[ \] \*\*$($task.Id)\*\*",
                    "- \[ \] $($task.Id)",
                    "- \[ \] $($task.Title)"
                )

                foreach ($pattern in $taskPatterns) {
                    $newContent = $activeDocumentContent -replace $pattern, "- [x] $($task.Id)"

                    # Si le contenu a changÃ©, c'est que la tÃ¢che a Ã©tÃ© trouvÃ©e et mise Ã  jour
                    if ($newContent -ne $activeDocumentContent) {
                        $activeDocumentContent = $newContent
                        $modified = $true
                        $tasksUpdated++
                        Write-Host "  TÃ¢che $($task.Id) - $($task.Title) : Case Ã  cocher mise Ã  jour" -ForegroundColor Green
                        break
                    }
                }
            }
        }

        # Enregistrer les modifications si nÃ©cessaire
        if ($modified -and $Force) {
            # Utiliser UTF-8 avec BOM pour l'enregistrement
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($ActiveDocumentPath, $activeDocumentContent, $utf8WithBom)

            # VÃ©rifier que le fichier a bien Ã©tÃ© enregistrÃ© en UTF-8 avec BOM
            $bytes = [System.IO.File]::ReadAllBytes($ActiveDocumentPath)
            $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

            if (-not $hasBOM) {
                Write-Warning "Le fichier n'a pas Ã©tÃ© correctement enregistrÃ© en UTF-8 avec BOM. Tentative de correction..."
                # Forcer l'encodage UTF-8 avec BOM
                $content = [System.IO.File]::ReadAllText($ActiveDocumentPath)
                [System.IO.File]::WriteAllText($ActiveDocumentPath, $content, $utf8WithBom)
            }

            Write-Host "  $tasksUpdated cases Ã  cocher mises Ã  jour dans le document actif." -ForegroundColor Green
        } elseif ($modified) {
            Write-Host "  $tasksUpdated cases Ã  cocher seraient mises Ã  jour dans le document actif (mode simulation)." -ForegroundColor Yellow
        } else {
            Write-Host "  Aucune case Ã  cocher n'a Ã©tÃ© mise Ã  jour dans le document actif." -ForegroundColor Gray
        }
    }
}

# Afficher un rÃ©sumÃ© des rÃ©sultats
Write-Host "`nRÃ©sumÃ© des rÃ©sultats :" -ForegroundColor Cyan
Write-Host "  TÃ¢che principale : $($result.MainTaskId)" -ForegroundColor Cyan
Write-Host "  Nombre total de tÃ¢ches : $($result.Tasks.Count)" -ForegroundColor Cyan
Write-Host "  TÃ¢ches implÃ©mentÃ©es Ã  100% : $($result.Tasks | Where-Object { $_.Implementation.ImplementationComplete } | Measure-Object).Count" -ForegroundColor Cyan
Write-Host "  TÃ¢ches testÃ©es Ã  100% : $($result.Tasks | Where-Object { $_.Tests.TestsComplete -and $_.Tests.TestsSuccessful } | Measure-Object).Count" -ForegroundColor Cyan

if ($UpdateRoadmap) {
    Write-Host "  TÃ¢ches mises Ã  jour dans la roadmap : $($result.TasksUpdated)" -ForegroundColor Cyan
}

if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "  TÃ¢ches mises Ã  jour dans le document actif : $tasksUpdated" -ForegroundColor Cyan
}

# Afficher un message de fin
Write-Host "`nVÃ©rification terminÃ©e." -ForegroundColor Green
'@

if ($Force -or $PSCmdlet.ShouldProcess($checkModeEnhancedPath, "CrÃ©er le script check-mode-enhanced.ps1")) {
    # Utiliser UTF-8 avec BOM pour l'enregistrement
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($checkModeEnhancedPath, $checkModeEnhancedContent, $utf8WithBom)
    Write-Host "  Script check-mode-enhanced.ps1 crÃ©Ã© : $checkModeEnhancedPath" -ForegroundColor Green
} else {
    Write-Host "  Le script check-mode-enhanced.ps1 serait crÃ©Ã© : $checkModeEnhancedPath (mode simulation)" -ForegroundColor Yellow
}

# Ã‰tape 3 : Mettre Ã  jour le script check.ps1
Write-Host "`nÃ‰tape 3 : Mise Ã  jour du script check.ps1" -ForegroundColor Cyan

$checkScriptPath = Join-Path -Path $basePath -ChildPath "tools\scripts\check.ps1"
$checkScriptContent = @'
<#
.SYNOPSIS
    Script pour exÃ©cuter le mode CHECK amÃ©liorÃ© et mettre Ã  jour les cases Ã  cocher dans le document actif.

.DESCRIPTION
    Ce script est un wrapper pour le mode CHECK amÃ©liorÃ© qui vÃ©rifie si les tÃ¢ches sont 100% implÃ©mentÃ©es
    et testÃ©es avec succÃ¨s, puis met Ã  jour automatiquement les cases Ã  cocher dans le document actif.
    Cette version amÃ©liorÃ©e garantit que tous les fichiers sont enregistrÃ©s en UTF-8 avec BOM.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap Ã  vÃ©rifier.
    Par dÃ©faut : "docs/plans/plan-modes-stepup.md"

.PARAMETER TaskIdentifier
    Identifiant de la tÃ¢che Ã  vÃ©rifier (par exemple, "1.2.3").
    Si non spÃ©cifiÃ©, toutes les tÃ¢ches seront vÃ©rifiÃ©es.

.PARAMETER ActiveDocumentPath
    Chemin vers le document actif Ã  mettre Ã  jour.
    Si non spÃ©cifiÃ©, le script tentera de dÃ©tecter automatiquement le document actif.

.PARAMETER Force
    Indique si les modifications doivent Ãªtre appliquÃ©es sans confirmation.

.EXAMPLE
    .\check.ps1

.EXAMPLE
    .\check.ps1 -TaskIdentifier "1.2.3" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de crÃ©ation: 2023-09-15
    Date de mise Ã  jour: 2025-05-01 - AmÃ©lioration de l'encodage UTF-8 avec BOM
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$FilePath = "docs/plans/plan-modes-stepup.md",

    [Parameter(Mandatory = $false)]
    [string]$TaskIdentifier,

    [Parameter(Mandatory = $false)]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# DÃ©terminer le chemin du script check-mode-enhanced.ps1
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-parser\modes\check\check-mode-enhanced.ps1"

# Si le chemin n'existe pas, essayer un autre chemin
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "..\roadmap-parser\modes\check\check-mode-enhanced.ps1"
}

# Si le chemin n'existe toujours pas, essayer un autre chemin
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path (Split-Path -Parent $PSScriptRoot) -ChildPath "roadmap-parser\modes\check\check-mode-enhanced.ps1"
}

# Si le chemin n'existe toujours pas, essayer un autre chemin
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) -ChildPath "roadmap-parser\modes\check\check-mode-enhanced.ps1"
}

# Si la version amÃ©liorÃ©e n'est pas trouvÃ©e, essayer la version standard
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-parser\modes\check\check-mode.ps1"

    if (Test-Path -Path $scriptPath) {
        Write-Warning "La version amÃ©liorÃ©e du mode CHECK n'a pas Ã©tÃ© trouvÃ©e. Utilisation de la version standard."
    }
}

# VÃ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script check-mode-enhanced.ps1 ou check-mode.ps1 est introuvable."
    exit 1
}

# Construire les paramÃ¨tres pour le script check-mode.ps1
$params = @{
    FilePath = $FilePath
    CheckActiveDocument = $true
    ImplementationPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\scripts\roadmap-parser\module\Functions\Public"
    TestsPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\scripts\roadmap-parser\module\Tests"
}

# Ajouter les paramÃ¨tres optionnels s'ils sont spÃ©cifiÃ©s
if ($TaskIdentifier) {
    $params.Add("TaskIdentifier", $TaskIdentifier)
}

if ($ActiveDocumentPath) {
    $params.Add("ActiveDocumentPath", $ActiveDocumentPath)
}

if ($Force) {
    $params.Add("Force", $true)
}

# Afficher les informations de dÃ©marrage
Write-Host "ExÃ©cution du mode CHECK amÃ©liorÃ©..." -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Cyan
if ($TaskIdentifier) {
    Write-Host "TÃ¢che Ã  vÃ©rifier : $TaskIdentifier" -ForegroundColor Cyan
} else {
    Write-Host "VÃ©rification de toutes les tÃ¢ches" -ForegroundColor Cyan
}
if ($ActiveDocumentPath) {
    Write-Host "Document actif : $ActiveDocumentPath" -ForegroundColor Cyan
} else {
    Write-Host "DÃ©tection automatique du document actif" -ForegroundColor Cyan
}
if ($Force) {
    Write-Host "Mode force activÃ© : les modifications seront appliquÃ©es sans confirmation" -ForegroundColor Yellow
} else {
    Write-Host "Mode simulation activÃ© : les modifications ne seront pas appliquÃ©es" -ForegroundColor Gray
}

# ExÃ©cuter le script check-mode.ps1 avec les paramÃ¨tres
& $scriptPath @params

# Afficher un message de fin
Write-Host "`nExÃ©cution du mode CHECK amÃ©liorÃ© terminÃ©e." -ForegroundColor Cyan
'@

if ($Force -or $PSCmdlet.ShouldProcess($checkScriptPath, "CrÃ©er ou mettre Ã  jour le script check.ps1")) {
    # Utiliser UTF-8 avec BOM pour l'enregistrement
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($checkScriptPath, $checkScriptContent, $utf8WithBom)
    Write-Host "  Script check.ps1 crÃ©Ã© ou mis Ã  jour : $checkScriptPath" -ForegroundColor Green
} else {
    Write-Host "  Le script check.ps1 serait crÃ©Ã© ou mis Ã  jour : $checkScriptPath (mode simulation)" -ForegroundColor Yellow
}

# Ã‰tape 4 : Mettre Ã  jour la documentation
Write-Host "`nÃ‰tape 4 : Mise Ã  jour de la documentation" -ForegroundColor Cyan

$docsPath = Join-Path -Path $basePath -ChildPath "docs\guides\methodologies\modes"
$checkDocPath = Join-Path -Path $docsPath -ChildPath "mode_check.md"
$enhancedDocPath = Join-Path -Path $docsPath -ChildPath "mode_check_enhanced.md"

# CrÃ©er le rÃ©pertoire de documentation s'il n'existe pas
if (-not (Test-Path -Path $docsPath)) {
    if ($Force -or $PSCmdlet.ShouldProcess($docsPath, "CrÃ©er le rÃ©pertoire")) {
        New-Item -Path $docsPath -ItemType Directory -Force | Out-Null
        Write-Host "  RÃ©pertoire crÃ©Ã© : $docsPath" -ForegroundColor Green
    } else {
        Write-Host "  Le rÃ©pertoire serait crÃ©Ã© : $docsPath (mode simulation)" -ForegroundColor Yellow
    }
}

# Mettre Ã  jour la documentation du mode CHECK
if (Test-Path -Path $checkDocPath) {
    Write-Host "  Mise Ã  jour de la documentation du mode CHECK..." -ForegroundColor Cyan

    if ($Force -or $PSCmdlet.ShouldProcess($checkDocPath, "Mettre Ã  jour la documentation")) {
        # CrÃ©er une sauvegarde du fichier existant si nÃ©cessaire
        if ($BackupFiles) {
            $backupPath = "$checkDocPath.bak"
            Copy-Item -Path $checkDocPath -Destination $backupPath -Force
            Write-Host "  Sauvegarde crÃ©Ã©e : $backupPath" -ForegroundColor Gray
        }

        # Ajouter une note dans la documentation existante
        $checkDocContent = Get-Content -Path $checkDocPath -Encoding UTF8
        $noteAdded = $false

        for ($i = 0; $i -lt $checkDocContent.Count; $i++) {
            if ($checkDocContent[$i] -match "^# Mode CHECK$") {
                $checkDocContent[$i] = "# Mode CHECK`n`n> **Note importante** : Une version amÃ©liorÃ©e du mode CHECK est disponible. Voir [Mode CHECK AmÃ©liorÃ©](mode_check_enhanced.md) pour plus d'informations."
                $noteAdded = $true
                break
            }
        }

        if ($noteAdded) {
            # Utiliser UTF-8 avec BOM pour l'enregistrement
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($checkDocPath, $checkDocContent, $utf8WithBom)

            Write-Host "  Documentation mise Ã  jour : $checkDocPath" -ForegroundColor Green
        } else {
            Write-Warning "Impossible d'ajouter la note dans la documentation existante : $checkDocPath"
        }
    } else {
        Write-Host "  La documentation serait mise Ã  jour : $checkDocPath (mode simulation)" -ForegroundColor Yellow
    }
} else {
    Write-Warning "Le fichier de documentation du mode CHECK est introuvable : $checkDocPath"
}

# CrÃ©er la documentation du mode CHECK amÃ©liorÃ©
$enhancedDocContent = @'
# Mode CHECK AmÃ©liorÃ©

Le mode CHECK amÃ©liorÃ© est une version avancÃ©e du [mode CHECK](mode_check.md) qui vÃ©rifie si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es avec succÃ¨s Ã  100%, puis met Ã  jour automatiquement les cases Ã  cocher dans le document actif.

## AmÃ©liorations par rapport au mode CHECK standard

- **Encodage UTF-8 avec BOM** : Tous les fichiers sont enregistrÃ©s en UTF-8 avec BOM, ce qui garantit une meilleure compatibilitÃ© avec les caractÃ¨res accentuÃ©s.
- **PrÃ©servation des indentations** : Les indentations dans les documents sont correctement prÃ©servÃ©es lors de la mise Ã  jour des cases Ã  cocher.
- **Meilleure dÃ©tection des tÃ¢ches** : L'algorithme de dÃ©tection des tÃ¢ches a Ã©tÃ© amÃ©liorÃ© pour mieux identifier les tÃ¢ches dans le document actif.
- **PrÃ©servation du texte complet des tÃ¢ches** : Le texte complet des tÃ¢ches est prÃ©servÃ© lors de la mise Ã  jour des cases Ã  cocher.

## Utilisation

Le mode CHECK amÃ©liorÃ© peut Ãªtre utilisÃ© de la mÃªme maniÃ¨re que le mode CHECK standard, mais avec des fonctionnalitÃ©s supplÃ©mentaires.

### VÃ©rification simple

Pour vÃ©rifier si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es avec succÃ¨s Ã  100% :

```powershell
.\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3"
```

### Mise Ã  jour automatique des cases Ã  cocher

Pour mettre Ã  jour automatiquement les cases Ã  cocher dans le document actif :

```powershell
.\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force
```

### SpÃ©cification du document actif

Si le document actif ne peut pas Ãªtre dÃ©tectÃ© automatiquement, vous pouvez le spÃ©cifier manuellement :

```powershell
.\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -ActiveDocumentPath "docs/roadmap/roadmap.md" -Force
```

### Mode simulation et mode force
Par dÃ©faut, le mode CHECK amÃ©liorÃ© fonctionne en mode simulation (`-Force` non spÃ©cifiÃ©) :
- Il affiche les modifications qui seraient apportÃ©es sans les appliquer
- Il indique le nombre de cases Ã  cocher qui seraient mises Ã  jour

Pour appliquer rÃ©ellement les modifications, utilisez le paramÃ¨tre `-Force` :
```powershell
.\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force
```

## Fonctionnement interne

Le mode CHECK amÃ©liorÃ© utilise les fonctions suivantes :

1. `Invoke-RoadmapCheck` : VÃ©rifie si les tÃ¢ches sÃ©lectionnÃ©es ont Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es avec succÃ¨s Ã  100%.
2. `Update-RoadmapTaskStatus` : Met Ã  jour le statut des tÃ¢ches dans la roadmap.
3. `Update-ActiveDocumentCheckboxes-Enhanced` : Met Ã  jour les cases Ã  cocher dans le document actif.

## DÃ©tection du document actif

Le mode CHECK amÃ©liorÃ© tente de dÃ©tecter automatiquement le document actif en utilisant les mÃ©thodes suivantes :

1. VÃ©rification de la variable d'environnement `VSCODE_ACTIVE_DOCUMENT`.
2. Recherche des fichiers Markdown rÃ©cemment modifiÃ©s.

Si aucun document actif ne peut Ãªtre dÃ©tectÃ© automatiquement, vous pouvez le spÃ©cifier manuellement avec le paramÃ¨tre `-ActiveDocumentPath`.

## RÃ©solution des problÃ¨mes

### ProblÃ¨mes d'encodage

Si vous rencontrez des problÃ¨mes d'encodage (caractÃ¨res accentuÃ©s mal affichÃ©s), assurez-vous que tous les fichiers sont enregistrÃ©s en UTF-8 avec BOM.

### ProblÃ¨mes de dÃ©tection du document actif

Si le document actif ne peut pas Ãªtre dÃ©tectÃ© automatiquement, utilisez le paramÃ¨tre `-ActiveDocumentPath` pour le spÃ©cifier manuellement.

### ProblÃ¨mes de mise Ã  jour des cases Ã  cocher

Si les cases Ã  cocher ne sont pas mises Ã  jour correctement, vÃ©rifiez que les tÃ¢ches ont bien Ã©tÃ© implÃ©mentÃ©es Ã  100% et testÃ©es avec succÃ¨s Ã  100%.
'@

if ($Force -or $PSCmdlet.ShouldProcess($enhancedDocPath, "CrÃ©er la documentation du mode CHECK amÃ©liorÃ©")) {
    # Utiliser UTF-8 avec BOM pour l'enregistrement
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($enhancedDocPath, $enhancedDocContent, $utf8WithBom)
    Write-Host "  Documentation du mode CHECK amÃ©liorÃ© crÃ©Ã©e : $enhancedDocPath" -ForegroundColor Green
} else {
    Write-Host "  La documentation du mode CHECK amÃ©liorÃ© serait crÃ©Ã©e : $enhancedDocPath (mode simulation)" -ForegroundColor Yellow
}

# Afficher un message de fin
if ($Force) {
    Write-Host "`nInstallation du mode CHECK amÃ©liorÃ© terminÃ©e." -ForegroundColor Green
    Write-Host "Pour utiliser le mode CHECK amÃ©liorÃ©, exÃ©cutez :" -ForegroundColor Cyan
    Write-Host "  .\tools\scripts\check.ps1" -ForegroundColor Yellow
} else {
    Write-Host "`nSimulation de l'installation terminÃ©e. Utilisez -Force pour installer." -ForegroundColor Yellow
}
