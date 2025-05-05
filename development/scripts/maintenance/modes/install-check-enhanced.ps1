<#
.SYNOPSIS
    Script d'installation du mode CHECK amÃƒÂ©liorÃƒÂ©.

.DESCRIPTION
    Ce script installe le mode CHECK amÃƒÂ©liorÃƒÂ© en :
    1. Mettant ÃƒÂ  jour les scripts existants pour utiliser la nouvelle fonction amÃƒÂ©liorÃƒÂ©e
    2. CrÃƒÂ©ant des liens symboliques pour assurer la compatibilitÃƒÂ© avec les scripts existants
    3. Mettant ÃƒÂ  jour la documentation

.PARAMETER Force
    Indique si les modifications doivent ÃƒÂªtre appliquÃƒÂ©es sans confirmation.
    Par dÃƒÂ©faut : $false (mode simulation).

.PARAMETER BackupFiles
    Indique si des copies de sauvegarde des fichiers originaux doivent ÃƒÂªtre crÃƒÂ©ÃƒÂ©es.
    Par dÃƒÂ©faut : $true.

.EXAMPLE
    .\install-check-enhanced.ps1 -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.0
    Date de crÃƒÂ©ation: 2025-05-01
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

# Afficher les informations de dÃƒÂ©marrage
Write-Host "Installation du mode CHECK amÃƒÂ©liorÃƒÂ©" -ForegroundColor Cyan
Write-Host "Mode : " -NoNewline
if ($Force) {
    Write-Host "Installation" -ForegroundColor Yellow
} else {
    Write-Host "Simulation (utilisez -Force pour installer)" -ForegroundColor Gray
}
Write-Host "Sauvegarde des fichiers originaux : " -NoNewline
if ($BackupFiles) {
    Write-Host "ActivÃƒÂ©e" -ForegroundColor Green
} else {
    Write-Host "DÃƒÂ©sactivÃƒÂ©e" -ForegroundColor Yellow
}

# Ãƒâ€°tape 1 : Mettre ÃƒÂ  jour les scripts existants
Write-Host "`nÃƒâ€°tape 1 : Mise ÃƒÂ  jour des scripts existants" -ForegroundColor Cyan

# CrÃƒÂ©er les rÃƒÂ©pertoires nÃƒÂ©cessaires s'ils n'existent pas
$functionsPath = Join-Path -Path $basePath -ChildPath "tools\scripts\roadmap-parser\module\Functions\Public"
$modesPath = Join-Path -Path $basePath -ChildPath "tools\scripts\roadmap-parser\modes\check"

if (-not (Test-Path -Path $functionsPath)) {
    if ($Force -or $PSCmdlet.ShouldProcess($functionsPath, "CrÃƒÂ©er le rÃƒÂ©pertoire")) {
        New-Item -Path $functionsPath -ItemType Directory -Force | Out-Null
        Write-Host "  RÃƒÂ©pertoire crÃƒÂ©ÃƒÂ© : $functionsPath" -ForegroundColor Green
    } else {
        Write-Host "  Le rÃƒÂ©pertoire serait crÃƒÂ©ÃƒÂ© : $functionsPath (mode simulation)" -ForegroundColor Yellow
    }
}

if (-not (Test-Path -Path $modesPath)) {
    if ($Force -or $PSCmdlet.ShouldProcess($modesPath, "CrÃƒÂ©er le rÃƒÂ©pertoire")) {
        New-Item -Path $modesPath -ItemType Directory -Force | Out-Null
        Write-Host "  RÃƒÂ©pertoire crÃƒÂ©ÃƒÂ© : $modesPath" -ForegroundColor Green
    } else {
        Write-Host "  Le rÃƒÂ©pertoire serait crÃƒÂ©ÃƒÂ© : $modesPath (mode simulation)" -ForegroundColor Yellow
    }
}

# Copier la fonction amÃƒÂ©liorÃƒÂ©e
$enhancedFunctionPath = Join-Path -Path $functionsPath -ChildPath "Update-ActiveDocumentCheckboxes-Enhanced.ps1"
$enhancedFunctionContent = @'
<#
.SYNOPSIS
    Met ÃƒÂ  jour les cases ÃƒÂ  cocher dans le document actif pour les tÃƒÂ¢ches implÃƒÂ©mentÃƒÂ©es et testÃƒÂ©es ÃƒÂ  100%.
    Version amÃƒÂ©liorÃƒÂ©e avec support UTF-8 avec BOM.

.DESCRIPTION
    Cette fonction analyse le document actif pour identifier les tÃƒÂ¢ches qui ont ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es
    et testÃƒÂ©es avec succÃƒÂ¨s ÃƒÂ  100%, puis coche automatiquement les cases correspondantes.
    Cette version amÃƒÂ©liorÃƒÂ©e garantit que tous les fichiers sont enregistrÃƒÂ©s en UTF-8 avec BOM
    et prÃƒÂ©serve correctement les caractÃƒÂ¨res accentuÃƒÂ©s et l'indentation.

.PARAMETER DocumentPath
    Chemin vers le document actif ÃƒÂ  mettre ÃƒÂ  jour.

.PARAMETER ImplementationResults
    RÃƒÂ©sultats de l'implÃƒÂ©mentation des tÃƒÂ¢ches (hashtable).

.PARAMETER TestResults
    RÃƒÂ©sultats des tests des tÃƒÂ¢ches (hashtable).

.EXAMPLE
    Update-ActiveDocumentCheckboxes-Enhanced -DocumentPath "document.md" -ImplementationResults $implResults -TestResults $testResults

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de crÃƒÂ©ation: 2023-09-15
    Date de mise ÃƒÂ  jour: 2025-05-01 - AmÃƒÂ©lioration de l'encodage UTF-8 avec BOM
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

    # VÃƒÂ©rifier que le document existe
    if (-not (Test-Path -Path $DocumentPath)) {
        Write-Error "Le document spÃƒÂ©cifiÃƒÂ© n'existe pas : $DocumentPath"
        return 0
    }

    try {
        # Lire le contenu du document avec l'encodage appropriÃƒÂ©
        # Utiliser [System.IO.File]::ReadAllLines pour garantir la dÃƒÂ©tection correcte de l'encodage
        $content = [System.IO.File]::ReadAllLines($DocumentPath)
        $modified = $false
        $tasksUpdated = 0

        # Parcourir chaque ligne du document
        for ($i = 0; $i -lt $content.Count; $i++) {
            $line = $content[$i]

            # Rechercher les lignes avec des cases ÃƒÂ  cocher non cochÃƒÂ©es
            if ($line -match '^\s*-\s+\[\s*\]') {
                # Extraire le texte de la tÃƒÂ¢che en prÃƒÂ©servant l'indentation
                $indentation = [regex]::Match($line, '^\s*').Value
                $taskText = $line -replace '^\s*-\s+\[\s*\]\s*', ''

                # Rechercher cette tÃƒÂ¢che dans les rÃƒÂ©sultats d'implÃƒÂ©mentation et de tests
                $taskFound = $false
                $taskComplete = $false
                $matchedTaskId = $null

                # Essayer de trouver l'ID de la tÃƒÂ¢che dans le texte
                foreach ($taskId in $ImplementationResults.Keys) {
                    # Ãƒâ€°chapper les caractÃƒÂ¨res spÃƒÂ©ciaux dans l'ID de la tÃƒÂ¢che pour la regex
                    $escapedTaskId = [regex]::Escape($taskId)

                    # VÃƒÂ©rifier diffÃƒÂ©rents formats possibles d'ID de tÃƒÂ¢che dans le texte
                    if ($taskText -match "^\*\*$escapedTaskId\*\*" -or
                        $taskText -match "^$escapedTaskId\s" -or
                        $taskText -match "^$escapedTaskId$" -or
                        $taskText -match "\[$escapedTaskId\]" -or
                        $taskText -match "\($escapedTaskId\)" -or
                        # Format spÃƒÂ©cifique pour les IDs longs
                        $taskText -match "\*\*$escapedTaskId\*\*") {

                        $taskFound = $true
                        $matchedTaskId = $taskId

                        # VÃƒÂ©rifier si l'implÃƒÂ©mentation et les tests sont ÃƒÂ  100%
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

                # Si aucun ID n'a ÃƒÂ©tÃƒÂ© trouvÃƒÂ©, essayer de faire correspondre par titre
                if (-not $taskFound) {
                    foreach ($taskId in $ImplementationResults.Keys) {
                        $implementationResult = $ImplementationResults[$taskId]

                        # VÃƒÂ©rifier si le titre de la tÃƒÂ¢che correspond
                        if ($implementationResult.TaskTitle -and $taskText -match [regex]::Escape($implementationResult.TaskTitle)) {
                            $taskFound = $true
                            $matchedTaskId = $taskId

                            # VÃƒÂ©rifier si l'implÃƒÂ©mentation et les tests sont ÃƒÂ  100%
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

                # Si la tÃƒÂ¢che a ÃƒÂ©tÃƒÂ© trouvÃƒÂ©e et est complÃƒÂ¨te, mettre ÃƒÂ  jour la case ÃƒÂ  cocher
                if ($taskFound -and $taskComplete) {
                    # Mettre ÃƒÂ  jour la case ÃƒÂ  cocher en prÃƒÂ©servant l'indentation et le texte complet
                    $newLine = $line -replace '^\s*-\s+\[\s*\]', "$indentation- [x]"
                    $content[$i] = $newLine
                    $modified = $true
                    $tasksUpdated++

                    Write-Verbose "Case ÃƒÂ  cocher mise ÃƒÂ  jour pour la tÃƒÂ¢che : $taskText (ID: $matchedTaskId)"
                }
            }
        }

        # Enregistrer les modifications si nÃƒÂ©cessaire
        if ($modified -and $PSCmdlet.ShouldProcess($DocumentPath, "Mettre ÃƒÂ  jour les cases ÃƒÂ  cocher")) {
            # Utiliser UTF-8 avec BOM pour l'enregistrement
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($DocumentPath, $content, $utf8WithBom)

            # VÃƒÂ©rifier que le fichier a bien ÃƒÂ©tÃƒÂ© enregistrÃƒÂ© en UTF-8 avec BOM
            $bytes = [System.IO.File]::ReadAllBytes($DocumentPath)
            $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

            if (-not $hasBOM) {
                Write-Warning "Le fichier n'a pas ÃƒÂ©tÃƒÂ© correctement enregistrÃƒÂ© en UTF-8 avec BOM. Tentative de correction..."
                # Forcer l'encodage UTF-8 avec BOM
                $content = [System.IO.File]::ReadAllText($DocumentPath)
                [System.IO.File]::WriteAllText($DocumentPath, $content, $utf8WithBom)
            }

            Write-Output "$tasksUpdated cases ÃƒÂ  cocher mises ÃƒÂ  jour dans le document : $DocumentPath"
        } else {
            Write-Output "$tasksUpdated cases ÃƒÂ  cocher seraient mises ÃƒÂ  jour dans le document : $DocumentPath (mode simulation)"
        }

        return $tasksUpdated
    }
    catch {
        Write-Error "Erreur lors de la mise ÃƒÂ  jour des cases ÃƒÂ  cocher : $_"
        return 0
    }
}
'@

if ($Force -or $PSCmdlet.ShouldProcess($enhancedFunctionPath, "CrÃƒÂ©er la fonction amÃƒÂ©liorÃƒÂ©e")) {
    # Utiliser UTF-8 avec BOM pour l'enregistrement
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($enhancedFunctionPath, $enhancedFunctionContent, $utf8WithBom)
    Write-Host "  Fonction amÃƒÂ©liorÃƒÂ©e crÃƒÂ©ÃƒÂ©e : $enhancedFunctionPath" -ForegroundColor Green
} else {
    Write-Host "  La fonction amÃƒÂ©liorÃƒÂ©e serait crÃƒÂ©ÃƒÂ©e : $enhancedFunctionPath (mode simulation)" -ForegroundColor Yellow
}

# Ãƒâ€°tape 2 : CrÃƒÂ©er le script check-mode-enhanced.ps1
Write-Host "`nÃƒâ€°tape 2 : CrÃƒÂ©ation du script check-mode-enhanced.ps1" -ForegroundColor Cyan

$checkModeEnhancedPath = Join-Path -Path $modesPath -ChildPath "check-mode-enhanced.ps1"
$checkModeEnhancedContent = @'
<#
.SYNOPSIS
    Script pour vÃƒÂ©rifier si les tÃƒÂ¢ches sÃƒÂ©lectionnÃƒÂ©es ont ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% et testÃƒÂ©es avec succÃƒÂ¨s ÃƒÂ  100% (Mode CHECK).
    Version amÃƒÂ©liorÃƒÂ©e avec support UTF-8 avec BOM.

.DESCRIPTION
    Ce script permet de vÃƒÂ©rifier si les tÃƒÂ¢ches sÃƒÂ©lectionnÃƒÂ©es ont ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% et testÃƒÂ©es
    avec succÃƒÂ¨s ÃƒÂ  100%. Si c'est le cas, il peut mettre ÃƒÂ  jour automatiquement le statut des tÃƒÂ¢ches
    dans la roadmap en cochant les cases correspondantes. Il implÃƒÂ©mente le mode CHECK dÃƒÂ©crit dans
    la documentation des modes de fonctionnement.
    Cette version amÃƒÂ©liorÃƒÂ©e garantit que tous les fichiers sont enregistrÃƒÂ©s en UTF-8 avec BOM.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap ÃƒÂ  vÃƒÂ©rifier et mettre ÃƒÂ  jour.

.PARAMETER TaskIdentifier
    Identifiant de la tÃƒÂ¢che ÃƒÂ  vÃƒÂ©rifier (par exemple, "1.2.1.3.2.3").
    Si non spÃƒÂ©cifiÃƒÂ©, l'utilisateur sera invitÃƒÂ© ÃƒÂ  le saisir.

.PARAMETER ImplementationPath
    Chemin vers le rÃƒÂ©pertoire contenant l'implÃƒÂ©mentation.
    Si non spÃƒÂ©cifiÃƒÂ©, le script tentera de le dÃƒÂ©duire automatiquement.

.PARAMETER TestsPath
    Chemin vers le rÃƒÂ©pertoire contenant les tests.
    Si non spÃƒÂ©cifiÃƒÂ©, le script tentera de le dÃƒÂ©duire automatiquement.

.PARAMETER UpdateRoadmap
    Indique si la roadmap doit ÃƒÂªtre mise ÃƒÂ  jour automatiquement.
    Par dÃƒÂ©faut : $true.

.PARAMETER GenerateReport
    Indique si un rapport doit ÃƒÂªtre gÃƒÂ©nÃƒÂ©rÃƒÂ©.
    Par dÃƒÂ©faut : $true.

.PARAMETER ActiveDocumentPath
    Chemin vers le document actif ÃƒÂ  vÃƒÂ©rifier et mettre ÃƒÂ  jour.
    Si non spÃƒÂ©cifiÃƒÂ©, le script tentera de dÃƒÂ©tecter automatiquement le document actif.

.PARAMETER CheckActiveDocument
    Indique si le document actif doit ÃƒÂªtre vÃƒÂ©rifiÃƒÂ© et mis ÃƒÂ  jour.
    Par dÃƒÂ©faut : $true.

.PARAMETER Force
    Indique si les modifications doivent ÃƒÂªtre appliquÃƒÂ©es sans confirmation.
    Par dÃƒÂ©faut : $false (mode simulation).

.EXAMPLE
    .\check-mode-enhanced.ps1 -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3"

.EXAMPLE
    .\check-mode-enhanced.ps1 -FilePath "Roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de crÃƒÂ©ation: 2023-08-15
    Date de mise ÃƒÂ  jour: 2025-05-01 - AmÃƒÂ©lioration de l'encodage UTF-8 avec BOM
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

    [Parameter(Mandatory = $false, HelpMessage = "Chemin vers le document actif ÃƒÂ  vÃƒÂ©rifier et mettre ÃƒÂ  jour. Si non spÃƒÂ©cifiÃƒÂ©, le document actif sera dÃƒÂ©tectÃƒÂ© automatiquement.")]
    [string]$ActiveDocumentPath,

    [Parameter(Mandatory = $false)]
    [switch]$CheckActiveDocument = $true,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

# Importer les fonctions nÃƒÂ©cessaires
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

# Afficher les chemins pour le dÃƒÂ©bogage
Write-Host "Chemin du script : $scriptPath" -ForegroundColor Yellow
Write-Host "Chemin du module : $modulePath" -ForegroundColor Yellow
Write-Host "Chemin de Invoke-RoadmapCheck : $invokeCheckPath" -ForegroundColor Yellow
Write-Host "Chemin de Update-RoadmapTaskStatus : $updateTaskPath" -ForegroundColor Yellow
Write-Host "Chemin de Update-ActiveDocumentCheckboxes-Enhanced : $updateCheckboxesPath" -ForegroundColor Yellow

if (Test-Path -Path $invokeCheckPath) {
    . $invokeCheckPath
    Write-Host "Fonction Invoke-RoadmapCheck importÃƒÂ©e." -ForegroundColor Green
} else {
    throw "La fonction Invoke-RoadmapCheck est introuvable ÃƒÂ  l'emplacement : $invokeCheckPath"
}

if (Test-Path -Path $updateTaskPath) {
    . $updateTaskPath
    Write-Host "Fonction Update-RoadmapTaskStatus importÃƒÂ©e." -ForegroundColor Green
} else {
    throw "La fonction Update-RoadmapTaskStatus est introuvable ÃƒÂ  l'emplacement : $updateTaskPath"
}

if (Test-Path -Path $updateCheckboxesPath) {
    . $updateCheckboxesPath
    Write-Host "Fonction Update-ActiveDocumentCheckboxes-Enhanced importÃƒÂ©e." -ForegroundColor Green
} else {
    Write-Warning "La fonction Update-ActiveDocumentCheckboxes-Enhanced est introuvable ÃƒÂ  l'emplacement : $updateCheckboxesPath. La mise ÃƒÂ  jour automatique des cases ÃƒÂ  cocher dans le document actif ne sera pas disponible."
}

# VÃƒÂ©rifier que le fichier de roadmap existe
if (-not (Test-Path -Path $FilePath)) {
    throw "Le fichier de roadmap spÃƒÂ©cifiÃƒÂ© n'existe pas : $FilePath"
}

# DÃƒÂ©tecter automatiquement le document actif si nÃƒÂ©cessaire
if ($CheckActiveDocument -and -not $ActiveDocumentPath) {
    Write-Host "DÃƒÂ©tection automatique du document actif..." -ForegroundColor Cyan

    # MÃƒÂ©thode 1: VÃƒÂ©rifier la variable d'environnement VSCODE_ACTIVE_DOCUMENT
    if ($env:VSCODE_ACTIVE_DOCUMENT -and (Test-Path -Path $env:VSCODE_ACTIVE_DOCUMENT)) {
        $ActiveDocumentPath = $env:VSCODE_ACTIVE_DOCUMENT
        Write-Host "Document actif dÃƒÂ©tectÃƒÂ© via variable d'environnement : $ActiveDocumentPath" -ForegroundColor Green
    }
    # MÃƒÂ©thode 2: Rechercher les fichiers Markdown rÃƒÂ©cemment modifiÃƒÂ©s
    else {
        $projectRoot = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1"
        $recentMdFiles = Get-ChildItem -Path $projectRoot -Filter "*.md" -Recurse |
                         Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-30) } |
                         Sort-Object LastWriteTime -Descending

        if ($recentMdFiles.Count -gt 0) {
            $ActiveDocumentPath = $recentMdFiles[0].FullName
            Write-Host "Document actif dÃƒÂ©tectÃƒÂ© automatiquement (fichier rÃƒÂ©cemment modifiÃƒÂ©) : $ActiveDocumentPath" -ForegroundColor Green
        }
        else {
            Write-Warning "Aucun document actif n'a pu ÃƒÂªtre dÃƒÂ©tectÃƒÂ© automatiquement. La vÃƒÂ©rification du document actif sera dÃƒÂ©sactivÃƒÂ©e."
            $CheckActiveDocument = $false
        }
    }
}

# VÃƒÂ©rifier si le document actif existe
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    if (-not (Test-Path -Path $ActiveDocumentPath)) {
        Write-Warning "Le document actif spÃƒÂ©cifiÃƒÂ© n'existe pas : $ActiveDocumentPath. La vÃƒÂ©rification du document actif sera dÃƒÂ©sactivÃƒÂ©e."
        $CheckActiveDocument = $false
    }
}

# Appeler la fonction Invoke-RoadmapCheck
$result = Invoke-RoadmapCheck -FilePath $FilePath -TaskIdentifier $TaskIdentifier -ImplementationPath $ImplementationPath -TestsPath $TestsPath -UpdateRoadmap $UpdateRoadmap -GenerateReport $GenerateReport

# VÃƒÂ©rifier et mettre ÃƒÂ  jour les cases ÃƒÂ  cocher dans le document actif si demandÃƒÂ©
if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "`nVÃƒÂ©rification et mise ÃƒÂ  jour des cases ÃƒÂ  cocher dans le document actif : $ActiveDocumentPath" -ForegroundColor Cyan

    # Extraire les rÃƒÂ©sultats d'implÃƒÂ©mentation et de tests
    $implementationResults = @{}
    $testResults = @{}

    foreach ($task in $result.Tasks) {
        $implementationResults[$task.Id] = $task.Implementation
        $testResults[$task.Id] = $task.Tests
    }

    # Utiliser la fonction Update-ActiveDocumentCheckboxes-Enhanced si disponible
    if (Get-Command -Name Update-ActiveDocumentCheckboxes-Enhanced -ErrorAction SilentlyContinue) {
        # PrÃƒÂ©parer les paramÃƒÂ¨tres pour la fonction
        $updateParams = @{
            DocumentPath = $ActiveDocumentPath
            ImplementationResults = $implementationResults
            TestResults = $testResults
        }

        # Ajouter le paramÃƒÂ¨tre WhatIf si Force n'est pas spÃƒÂ©cifiÃƒÂ©
        if (-not $Force) {
            $updateParams.Add("WhatIf", $true)
        }

        # Appeler la fonction avec les paramÃƒÂ¨tres
        $updateResult = Update-ActiveDocumentCheckboxes-Enhanced @updateParams
        $tasksUpdated = $updateResult
    } else {
        # MÃƒÂ©thode alternative si la fonction n'est pas disponible
        Write-Warning "La fonction Update-ActiveDocumentCheckboxes-Enhanced n'est pas disponible. Utilisation d'une mÃƒÂ©thode alternative."

        # Lire le contenu du document actif
        $activeDocumentContent = Get-Content -Path $ActiveDocumentPath -Encoding UTF8
        $tasksUpdated = 0
        $modified = $false

        # Pour chaque tÃƒÂ¢che vÃƒÂ©rifiÃƒÂ©e
        foreach ($task in $result.Tasks) {
            # Si la tÃƒÂ¢che est implÃƒÂ©mentÃƒÂ©e ÃƒÂ  100% et testÃƒÂ©e avec succÃƒÂ¨s ÃƒÂ  100%
            if ($task.Implementation.ImplementationComplete -and $task.Tests.TestsComplete -and $task.Tests.TestsSuccessful) {
                # Rechercher la tÃƒÂ¢che dans le document actif (diffÃƒÂ©rents formats possibles)
                $taskPatterns = @(
                    "- \[ \] \*\*$($task.Id)\*\*",
                    "- \[ \] $($task.Id)",
                    "- \[ \] $($task.Title)"
                )

                foreach ($pattern in $taskPatterns) {
                    $newContent = $activeDocumentContent -replace $pattern, "- [x] $($task.Id)"

                    # Si le contenu a changÃƒÂ©, c'est que la tÃƒÂ¢che a ÃƒÂ©tÃƒÂ© trouvÃƒÂ©e et mise ÃƒÂ  jour
                    if ($newContent -ne $activeDocumentContent) {
                        $activeDocumentContent = $newContent
                        $modified = $true
                        $tasksUpdated++
                        Write-Host "  TÃƒÂ¢che $($task.Id) - $($task.Title) : Case ÃƒÂ  cocher mise ÃƒÂ  jour" -ForegroundColor Green
                        break
                    }
                }
            }
        }

        # Enregistrer les modifications si nÃƒÂ©cessaire
        if ($modified -and $Force) {
            # Utiliser UTF-8 avec BOM pour l'enregistrement
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($ActiveDocumentPath, $activeDocumentContent, $utf8WithBom)

            # VÃƒÂ©rifier que le fichier a bien ÃƒÂ©tÃƒÂ© enregistrÃƒÂ© en UTF-8 avec BOM
            $bytes = [System.IO.File]::ReadAllBytes($ActiveDocumentPath)
            $hasBOM = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF

            if (-not $hasBOM) {
                Write-Warning "Le fichier n'a pas ÃƒÂ©tÃƒÂ© correctement enregistrÃƒÂ© en UTF-8 avec BOM. Tentative de correction..."
                # Forcer l'encodage UTF-8 avec BOM
                $content = [System.IO.File]::ReadAllText($ActiveDocumentPath)
                [System.IO.File]::WriteAllText($ActiveDocumentPath, $content, $utf8WithBom)
            }

            Write-Host "  $tasksUpdated cases ÃƒÂ  cocher mises ÃƒÂ  jour dans le document actif." -ForegroundColor Green
        } elseif ($modified) {
            Write-Host "  $tasksUpdated cases ÃƒÂ  cocher seraient mises ÃƒÂ  jour dans le document actif (mode simulation)." -ForegroundColor Yellow
        } else {
            Write-Host "  Aucune case ÃƒÂ  cocher n'a ÃƒÂ©tÃƒÂ© mise ÃƒÂ  jour dans le document actif." -ForegroundColor Gray
        }
    }
}

# Afficher un rÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats
Write-Host "`nRÃƒÂ©sumÃƒÂ© des rÃƒÂ©sultats :" -ForegroundColor Cyan
Write-Host "  TÃƒÂ¢che principale : $($result.MainTaskId)" -ForegroundColor Cyan
Write-Host "  Nombre total de tÃƒÂ¢ches : $($result.Tasks.Count)" -ForegroundColor Cyan
Write-Host "  TÃƒÂ¢ches implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% : $($result.Tasks | Where-Object { $_.Implementation.ImplementationComplete } | Measure-Object).Count" -ForegroundColor Cyan
Write-Host "  TÃƒÂ¢ches testÃƒÂ©es ÃƒÂ  100% : $($result.Tasks | Where-Object { $_.Tests.TestsComplete -and $_.Tests.TestsSuccessful } | Measure-Object).Count" -ForegroundColor Cyan

if ($UpdateRoadmap) {
    Write-Host "  TÃƒÂ¢ches mises ÃƒÂ  jour dans la roadmap : $($result.TasksUpdated)" -ForegroundColor Cyan
}

if ($CheckActiveDocument -and $ActiveDocumentPath) {
    Write-Host "  TÃƒÂ¢ches mises ÃƒÂ  jour dans le document actif : $tasksUpdated" -ForegroundColor Cyan
}

# Afficher un message de fin
Write-Host "`nVÃƒÂ©rification terminÃƒÂ©e." -ForegroundColor Green
'@

if ($Force -or $PSCmdlet.ShouldProcess($checkModeEnhancedPath, "CrÃƒÂ©er le script check-mode-enhanced.ps1")) {
    # Utiliser UTF-8 avec BOM pour l'enregistrement
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($checkModeEnhancedPath, $checkModeEnhancedContent, $utf8WithBom)
    Write-Host "  Script check-mode-enhanced.ps1 crÃƒÂ©ÃƒÂ© : $checkModeEnhancedPath" -ForegroundColor Green
} else {
    Write-Host "  Le script check-mode-enhanced.ps1 serait crÃƒÂ©ÃƒÂ© : $checkModeEnhancedPath (mode simulation)" -ForegroundColor Yellow
}

# Ãƒâ€°tape 3 : Mettre ÃƒÂ  jour le script check.ps1
Write-Host "`nÃƒâ€°tape 3 : Mise ÃƒÂ  jour du script check.ps1" -ForegroundColor Cyan

$checkScriptPath = Join-Path -Path $basePath -ChildPath "tools\scripts\check.ps1"
$checkScriptContent = @'
<#
.SYNOPSIS
    Script pour exÃƒÂ©cuter le mode CHECK amÃƒÂ©liorÃƒÂ© et mettre ÃƒÂ  jour les cases ÃƒÂ  cocher dans le document actif.

.DESCRIPTION
    Ce script est un wrapper pour le mode CHECK amÃƒÂ©liorÃƒÂ© qui vÃƒÂ©rifie si les tÃƒÂ¢ches sont 100% implÃƒÂ©mentÃƒÂ©es
    et testÃƒÂ©es avec succÃƒÂ¨s, puis met ÃƒÂ  jour automatiquement les cases ÃƒÂ  cocher dans le document actif.
    Cette version amÃƒÂ©liorÃƒÂ©e garantit que tous les fichiers sont enregistrÃƒÂ©s en UTF-8 avec BOM.

.PARAMETER FilePath
    Chemin vers le fichier de roadmap ÃƒÂ  vÃƒÂ©rifier.
    Par dÃƒÂ©faut : "docs/plans/plan-modes-stepup.md"

.PARAMETER TaskIdentifier
    Identifiant de la tÃƒÂ¢che ÃƒÂ  vÃƒÂ©rifier (par exemple, "1.2.3").
    Si non spÃƒÂ©cifiÃƒÂ©, toutes les tÃƒÂ¢ches seront vÃƒÂ©rifiÃƒÂ©es.

.PARAMETER ActiveDocumentPath
    Chemin vers le document actif ÃƒÂ  mettre ÃƒÂ  jour.
    Si non spÃƒÂ©cifiÃƒÂ©, le script tentera de dÃƒÂ©tecter automatiquement le document actif.

.PARAMETER Force
    Indique si les modifications doivent ÃƒÂªtre appliquÃƒÂ©es sans confirmation.

.EXAMPLE
    .\check.ps1

.EXAMPLE
    .\check.ps1 -TaskIdentifier "1.2.3" -Force

.NOTES
    Auteur: RoadmapParser Team
    Version: 1.1
    Date de crÃƒÂ©ation: 2023-09-15
    Date de mise ÃƒÂ  jour: 2025-05-01 - AmÃƒÂ©lioration de l'encodage UTF-8 avec BOM
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

# DÃƒÂ©terminer le chemin du script check-mode-enhanced.ps1
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

# Si la version amÃƒÂ©liorÃƒÂ©e n'est pas trouvÃƒÂ©e, essayer la version standard
if (-not (Test-Path -Path $scriptPath)) {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "roadmap-parser\modes\check\check-mode.ps1"

    if (Test-Path -Path $scriptPath) {
        Write-Warning "La version amÃƒÂ©liorÃƒÂ©e du mode CHECK n'a pas ÃƒÂ©tÃƒÂ© trouvÃƒÂ©e. Utilisation de la version standard."
    }
}

# VÃƒÂ©rifier que le script existe
if (-not (Test-Path -Path $scriptPath)) {
    Write-Error "Le script check-mode-enhanced.ps1 ou check-mode.ps1 est introuvable."
    exit 1
}

# Construire les paramÃƒÂ¨tres pour le script check-mode.ps1
$params = @{
    FilePath = $FilePath
    CheckActiveDocument = $true
    ImplementationPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\scripts\roadmap-parser\module\Functions\Public"
    TestsPath = "D:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools\scripts\roadmap-parser\module\Tests"
}

# Ajouter les paramÃƒÂ¨tres optionnels s'ils sont spÃƒÂ©cifiÃƒÂ©s
if ($TaskIdentifier) {
    $params.Add("TaskIdentifier", $TaskIdentifier)
}

if ($ActiveDocumentPath) {
    $params.Add("ActiveDocumentPath", $ActiveDocumentPath)
}

if ($Force) {
    $params.Add("Force", $true)
}

# Afficher les informations de dÃƒÂ©marrage
Write-Host "ExÃƒÂ©cution du mode CHECK amÃƒÂ©liorÃƒÂ©..." -ForegroundColor Cyan
Write-Host "Fichier de roadmap : $FilePath" -ForegroundColor Cyan
if ($TaskIdentifier) {
    Write-Host "TÃƒÂ¢che ÃƒÂ  vÃƒÂ©rifier : $TaskIdentifier" -ForegroundColor Cyan
} else {
    Write-Host "VÃƒÂ©rification de toutes les tÃƒÂ¢ches" -ForegroundColor Cyan
}
if ($ActiveDocumentPath) {
    Write-Host "Document actif : $ActiveDocumentPath" -ForegroundColor Cyan
} else {
    Write-Host "DÃƒÂ©tection automatique du document actif" -ForegroundColor Cyan
}
if ($Force) {
    Write-Host "Mode force activÃƒÂ© : les modifications seront appliquÃƒÂ©es sans confirmation" -ForegroundColor Yellow
} else {
    Write-Host "Mode simulation activÃƒÂ© : les modifications ne seront pas appliquÃƒÂ©es" -ForegroundColor Gray
}

# ExÃƒÂ©cuter le script check-mode.ps1 avec les paramÃƒÂ¨tres
& $scriptPath @params

# Afficher un message de fin
Write-Host "`nExÃƒÂ©cution du mode CHECK amÃƒÂ©liorÃƒÂ© terminÃƒÂ©e." -ForegroundColor Cyan
'@

if ($Force -or $PSCmdlet.ShouldProcess($checkScriptPath, "CrÃƒÂ©er ou mettre ÃƒÂ  jour le script check.ps1")) {
    # Utiliser UTF-8 avec BOM pour l'enregistrement
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($checkScriptPath, $checkScriptContent, $utf8WithBom)
    Write-Host "  Script check.ps1 crÃƒÂ©ÃƒÂ© ou mis ÃƒÂ  jour : $checkScriptPath" -ForegroundColor Green
} else {
    Write-Host "  Le script check.ps1 serait crÃƒÂ©ÃƒÂ© ou mis ÃƒÂ  jour : $checkScriptPath (mode simulation)" -ForegroundColor Yellow
}

# Ãƒâ€°tape 4 : Mettre ÃƒÂ  jour la documentation
Write-Host "`nÃƒâ€°tape 4 : Mise ÃƒÂ  jour de la documentation" -ForegroundColor Cyan

$docsPath = Join-Path -Path $basePath -ChildPath "docs\guides\methodologies\modes"
$checkDocPath = Join-Path -Path $docsPath -ChildPath "mode_check.md"
$enhancedDocPath = Join-Path -Path $docsPath -ChildPath "mode_check_enhanced.md"

# CrÃƒÂ©er le rÃƒÂ©pertoire de documentation s'il n'existe pas
if (-not (Test-Path -Path $docsPath)) {
    if ($Force -or $PSCmdlet.ShouldProcess($docsPath, "CrÃƒÂ©er le rÃƒÂ©pertoire")) {
        New-Item -Path $docsPath -ItemType Directory -Force | Out-Null
        Write-Host "  RÃƒÂ©pertoire crÃƒÂ©ÃƒÂ© : $docsPath" -ForegroundColor Green
    } else {
        Write-Host "  Le rÃƒÂ©pertoire serait crÃƒÂ©ÃƒÂ© : $docsPath (mode simulation)" -ForegroundColor Yellow
    }
}

# Mettre ÃƒÂ  jour la documentation du mode CHECK
if (Test-Path -Path $checkDocPath) {
    Write-Host "  Mise ÃƒÂ  jour de la documentation du mode CHECK..." -ForegroundColor Cyan

    if ($Force -or $PSCmdlet.ShouldProcess($checkDocPath, "Mettre ÃƒÂ  jour la documentation")) {
        # CrÃƒÂ©er une sauvegarde du fichier existant si nÃƒÂ©cessaire
        if ($BackupFiles) {
            $backupPath = "$checkDocPath.bak"
            Copy-Item -Path $checkDocPath -Destination $backupPath -Force
            Write-Host "  Sauvegarde crÃƒÂ©ÃƒÂ©e : $backupPath" -ForegroundColor Gray
        }

        # Ajouter une note dans la documentation existante
        $checkDocContent = Get-Content -Path $checkDocPath -Encoding UTF8
        $noteAdded = $false

        for ($i = 0; $i -lt $checkDocContent.Count; $i++) {
            if ($checkDocContent[$i] -match "^# Mode CHECK$") {
                $checkDocContent[$i] = "# Mode CHECK`n`n> **Note importante** : Une version amÃƒÂ©liorÃƒÂ©e du mode CHECK est disponible. Voir [Mode CHECK AmÃƒÂ©liorÃƒÂ©](mode_check_enhanced.md) pour plus d'informations."
                $noteAdded = $true
                break
            }
        }

        if ($noteAdded) {
            # Utiliser UTF-8 avec BOM pour l'enregistrement
            $utf8WithBom = New-Object System.Text.UTF8Encoding $true
            [System.IO.File]::WriteAllLines($checkDocPath, $checkDocContent, $utf8WithBom)

            Write-Host "  Documentation mise ÃƒÂ  jour : $checkDocPath" -ForegroundColor Green
        } else {
            Write-Warning "Impossible d'ajouter la note dans la documentation existante : $checkDocPath"
        }
    } else {
        Write-Host "  La documentation serait mise ÃƒÂ  jour : $checkDocPath (mode simulation)" -ForegroundColor Yellow
    }
} else {
    Write-Warning "Le fichier de documentation du mode CHECK est introuvable : $checkDocPath"
}

# CrÃƒÂ©er la documentation du mode CHECK amÃƒÂ©liorÃƒÂ©
$enhancedDocContent = @'
# Mode CHECK AmÃƒÂ©liorÃƒÂ©

Le mode CHECK amÃƒÂ©liorÃƒÂ© est une version avancÃƒÂ©e du [mode CHECK](mode_check.md) qui vÃƒÂ©rifie si les tÃƒÂ¢ches sÃƒÂ©lectionnÃƒÂ©es ont ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% et testÃƒÂ©es avec succÃƒÂ¨s ÃƒÂ  100%, puis met ÃƒÂ  jour automatiquement les cases ÃƒÂ  cocher dans le document actif.

## AmÃƒÂ©liorations par rapport au mode CHECK standard

- **Encodage UTF-8 avec BOM** : Tous les fichiers sont enregistrÃƒÂ©s en UTF-8 avec BOM, ce qui garantit une meilleure compatibilitÃƒÂ© avec les caractÃƒÂ¨res accentuÃƒÂ©s.
- **PrÃƒÂ©servation des indentations** : Les indentations dans les documents sont correctement prÃƒÂ©servÃƒÂ©es lors de la mise ÃƒÂ  jour des cases ÃƒÂ  cocher.
- **Meilleure dÃƒÂ©tection des tÃƒÂ¢ches** : L'algorithme de dÃƒÂ©tection des tÃƒÂ¢ches a ÃƒÂ©tÃƒÂ© amÃƒÂ©liorÃƒÂ© pour mieux identifier les tÃƒÂ¢ches dans le document actif.
- **PrÃƒÂ©servation du texte complet des tÃƒÂ¢ches** : Le texte complet des tÃƒÂ¢ches est prÃƒÂ©servÃƒÂ© lors de la mise ÃƒÂ  jour des cases ÃƒÂ  cocher.

## Utilisation

Le mode CHECK amÃƒÂ©liorÃƒÂ© peut ÃƒÂªtre utilisÃƒÂ© de la mÃƒÂªme maniÃƒÂ¨re que le mode CHECK standard, mais avec des fonctionnalitÃƒÂ©s supplÃƒÂ©mentaires.

### VÃƒÂ©rification simple

Pour vÃƒÂ©rifier si les tÃƒÂ¢ches sÃƒÂ©lectionnÃƒÂ©es ont ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% et testÃƒÂ©es avec succÃƒÂ¨s ÃƒÂ  100% :

```powershell
.\development\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3"
```

### Mise ÃƒÂ  jour automatique des cases ÃƒÂ  cocher

Pour mettre ÃƒÂ  jour automatiquement les cases ÃƒÂ  cocher dans le document actif :

```powershell
.\development\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force
```

### SpÃƒÂ©cification du document actif

Si le document actif ne peut pas ÃƒÂªtre dÃƒÂ©tectÃƒÂ© automatiquement, vous pouvez le spÃƒÂ©cifier manuellement :

```powershell
.\development\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -ActiveDocumentPath "docs/roadmap/roadmap.md" -Force
```

### Mode simulation et mode force
Par dÃƒÂ©faut, le mode CHECK amÃƒÂ©liorÃƒÂ© fonctionne en mode simulation (`-Force` non spÃƒÂ©cifiÃƒÂ©) :
- Il affiche les modifications qui seraient apportÃƒÂ©es sans les appliquer
- Il indique le nombre de cases ÃƒÂ  cocher qui seraient mises ÃƒÂ  jour

Pour appliquer rÃƒÂ©ellement les modifications, utilisez le paramÃƒÂ¨tre `-Force` :
```powershell
.\development\tools\scripts\check.ps1 -FilePath "docs/roadmap/roadmap.md" -TaskIdentifier "1.2.3" -Force
```

## Fonctionnement interne

Le mode CHECK amÃƒÂ©liorÃƒÂ© utilise les fonctions suivantes :

1. `Invoke-RoadmapCheck` : VÃƒÂ©rifie si les tÃƒÂ¢ches sÃƒÂ©lectionnÃƒÂ©es ont ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% et testÃƒÂ©es avec succÃƒÂ¨s ÃƒÂ  100%.
2. `Update-RoadmapTaskStatus` : Met ÃƒÂ  jour le statut des tÃƒÂ¢ches dans la roadmap.
3. `Update-ActiveDocumentCheckboxes-Enhanced` : Met ÃƒÂ  jour les cases ÃƒÂ  cocher dans le document actif.

## DÃƒÂ©tection du document actif

Le mode CHECK amÃƒÂ©liorÃƒÂ© tente de dÃƒÂ©tecter automatiquement le document actif en utilisant les mÃƒÂ©thodes suivantes :

1. VÃƒÂ©rification de la variable d'environnement `VSCODE_ACTIVE_DOCUMENT`.
2. Recherche des fichiers Markdown rÃƒÂ©cemment modifiÃƒÂ©s.

Si aucun document actif ne peut ÃƒÂªtre dÃƒÂ©tectÃƒÂ© automatiquement, vous pouvez le spÃƒÂ©cifier manuellement avec le paramÃƒÂ¨tre `-ActiveDocumentPath`.

## RÃƒÂ©solution des problÃƒÂ¨mes

### ProblÃƒÂ¨mes d'encodage

Si vous rencontrez des problÃƒÂ¨mes d'encodage (caractÃƒÂ¨res accentuÃƒÂ©s mal affichÃƒÂ©s), assurez-vous que tous les fichiers sont enregistrÃƒÂ©s en UTF-8 avec BOM.

### ProblÃƒÂ¨mes de dÃƒÂ©tection du document actif

Si le document actif ne peut pas ÃƒÂªtre dÃƒÂ©tectÃƒÂ© automatiquement, utilisez le paramÃƒÂ¨tre `-ActiveDocumentPath` pour le spÃƒÂ©cifier manuellement.

### ProblÃƒÂ¨mes de mise ÃƒÂ  jour des cases ÃƒÂ  cocher

Si les cases ÃƒÂ  cocher ne sont pas mises ÃƒÂ  jour correctement, vÃƒÂ©rifiez que les tÃƒÂ¢ches ont bien ÃƒÂ©tÃƒÂ© implÃƒÂ©mentÃƒÂ©es ÃƒÂ  100% et testÃƒÂ©es avec succÃƒÂ¨s ÃƒÂ  100%.
'@

if ($Force -or $PSCmdlet.ShouldProcess($enhancedDocPath, "CrÃƒÂ©er la documentation du mode CHECK amÃƒÂ©liorÃƒÂ©")) {
    # Utiliser UTF-8 avec BOM pour l'enregistrement
    $utf8WithBom = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($enhancedDocPath, $enhancedDocContent, $utf8WithBom)
    Write-Host "  Documentation du mode CHECK amÃƒÂ©liorÃƒÂ© crÃƒÂ©ÃƒÂ©e : $enhancedDocPath" -ForegroundColor Green
} else {
    Write-Host "  La documentation du mode CHECK amÃƒÂ©liorÃƒÂ© serait crÃƒÂ©ÃƒÂ©e : $enhancedDocPath (mode simulation)" -ForegroundColor Yellow
}

# Afficher un message de fin
if ($Force) {
    Write-Host "`nInstallation du mode CHECK amÃƒÂ©liorÃƒÂ© terminÃƒÂ©e." -ForegroundColor Green
    Write-Host "Pour utiliser le mode CHECK amÃƒÂ©liorÃƒÂ©, exÃƒÂ©cutez :" -ForegroundColor Cyan
    Write-Host "  .\development\tools\scripts\check.ps1" -ForegroundColor Yellow
} else {
    Write-Host "`nSimulation de l'installation terminÃƒÂ©e. Utilisez -Force pour installer." -ForegroundColor Yellow
}
