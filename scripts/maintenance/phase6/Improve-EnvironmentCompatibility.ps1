# Script pour améliorer la compatibilité entre environnements
# Ce script standardise la gestion des chemins et corrige les problèmes de compatibilité

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$ScriptsDirectory = (Join-Path -Path (Get-Location) -ChildPath "scripts"),

    [Parameter(Mandatory = $false)]
    [switch]$CreateBackup,

    [Parameter(Mandatory = $false)]
    [string]$LogFilePath = (Join-Path -Path (Get-Location) -ChildPath "logs\environment_compatibility.log")
)

# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()

# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }

    # Créer le répertoire de logs si nécessaire
    $logDir = Split-Path -Path $LogFilePath -Parent
    if (-not (Test-Path -Path $logDir -PathType Container)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    Add-Content -Path $LogFilePath -Value $logEntry -Encoding UTF8
}

try {
    # Fonction pour identifier les scripts avec des problèmes de compatibilité
    function Find-CompatibilityIssues {
        param (
            [string]$Directory
        )

        Write-Log "Recherche des scripts avec des problèmes de compatibilité dans $Directory"

        $results = @()

        # Récupérer tous les scripts PowerShell dans le répertoire
        $scripts = Get-ChildItem -Path $Directory -Recurse -File -Filter "*.ps1" | Where-Object { -not $_.FullName.Contains(".bak") }
        Write-Log "Nombre de scripts trouvés : $($scripts.Count)"

        foreach ($script in $scripts) {
            Write-Verbose "Analyse du script : $($script.FullName)"

            # Lire le contenu du script
            $content = Get-Content -Path $script.FullName -Raw -ErrorAction SilentlyContinue

            if ($null -eq $content) {
                Write-Log "Impossible de lire le contenu du script : $($script.FullName)" -Level "WARNING"
                continue
            }

            # Vérifier les problèmes de compatibilité
            $issues = @()

            # 1. Chemins codés en dur
            if ($content -match "([A-Z]:\\[^'`"]*\\[^'`"]*)" -or $content -match "([A-Z]:/[^'`"]*/[^'`"]*)") {
                $issues += "Chemins codés en dur"
            }

            # 2. Utilisation de séparateurs de chemin spécifiques à Windows
            if ($content -match "\\\\" -and -not $content -match "\\\\\\\\") {
                $issues += "Séparateurs de chemin spécifiques à Windows"
            }

            # 3. Commandes spécifiques à Windows
            if ($content -match "cmd\.exe|cmd /c|powershell\.exe|\.bat|\.cmd") {
                $issues += "Commandes spécifiques à Windows"
            }

            # 4. Utilisation de variables d'environnement spécifiques à Windows
            if ($content -match "\$env:USERPROFILE|\$env:APPDATA|\$env:ProgramFiles|\$env:SystemRoot") {
                $issues += "Variables d'environnement spécifiques à Windows"
            }

            # 5. Utilisation de fonctions spécifiques à PowerShell Windows
            if ($content -match "Get-WmiObject|Get-CimInstance|Get-EventLog") {
                $issues += "Fonctions spécifiques à PowerShell Windows"
            }

            # Si des problèmes ont été identifiés
            if ($issues.Count -gt 0) {
                $results += [PSCustomObject]@{
                    Path = $script.FullName
                    Issues = $issues -join ", "
                }
            }
        }

        return $results
    }

    # Fonction pour standardiser la gestion des chemins dans un script
    function Update-PathHandling {
        param (
            [string]$Path,
            [switch]$CreateBackup
        )

        Write-Verbose "Standardisation de la gestion des chemins dans $Path"

        # Créer une sauvegarde si demandé
        if ($CreateBackup) {
            $backupPath = "$Path.bak"
            Copy-Item -Path $Path -Destination $backupPath -Force
            Write-Verbose "Sauvegarde créée : $backupPath"
        }

        # Lire le contenu du script
        $content = Get-Content -Path $Path -Raw

        # 1. Remplacer les chemins codés en dur par des chemins relatifs

        # Extraire les chemins codés en dur
        $hardcodedPaths = [regex]::Matches($content, "([A-Z]:\\[^'`"]*\\[^'`"]*)|([A-Z]:/[^'`"]*/[^'`"]*)")

        foreach ($match in $hardcodedPaths) {
            $hardcodedPath = $match.Value

            # Ignorer les chemins qui font partie de commentaires
            $lineStart = $content.Substring(0, $match.Index).LastIndexOf("`n")
            if ($lineStart -eq -1) { $lineStart = 0 } else { $lineStart += 1 }
            $line = $content.Substring($lineStart, $content.IndexOf("`n", $match.Index) - $lineStart)

            if ($line.TrimStart().StartsWith("#")) {
                continue
            }

            # Remplacer par Join-Path
            $pathParts = $hardcodedPath -split "[\\/]"
            $rootPart = $pathParts[0]
            $remainingParts = $pathParts[1..($pathParts.Length - 1)]

            if ($rootPart -match "^[A-Z]:$") {
                # Chemin absolu avec lettre de lecteur
                $newPath = "Join-Path -Path `$PSScriptRoot -ChildPath `"..`""
                foreach ($part in $remainingParts) {
                    $newPath = "Join-Path -Path ($newPath) -ChildPath `"$part`""
                }

                $content = $content.Replace($hardcodedPath, "`$($newPath)")
            }
        }

        # 2. Standardiser les séparateurs de chemin
        $content = $content -replace "\\\\(?!\\\\)", [System.IO.Path]::DirectorySeparatorChar

        # 3. Remplacer les commandes spécifiques à Windows par des alternatives compatibles
        $content = $content -replace "cmd\.exe /c", "Invoke-Expression"
        $content = $content -replace "powershell\.exe", "pwsh"

        # 4. Remplacer les variables d'environnement spécifiques à Windows
        $content = $content -replace '\$env:USERPROFILE', '\$HOME'
        $content = $content -replace '\$env:APPDATA', "Join-Path -Path \$HOME -ChildPath '.config'"
        $content = $content -replace '\$env:ProgramFiles', "'/usr/local'"
        $content = $content -replace '\$env:SystemRoot', "'/'"

        # 5. Remplacer les fonctions spécifiques à PowerShell Windows
        $content = $content -replace "Get-WmiObject", "Get-CimInstance"
        $content = $content -replace "Get-EventLog", "Get-WinEvent"

        # Ajouter une vérification de l'environnement d'exécution
        $environmentCheck = @"
# Vérifier l'environnement d'exécution
`$IsWindows = `$PSVersionTable.PSVersion.Major -ge 6 -and `$PSVersionTable.Platform -eq 'Win32NT' -or `$PSVersionTable.PSVersion.Major -lt 6
`$IsLinux = `$PSVersionTable.PSVersion.Major -ge 6 -and `$PSVersionTable.Platform -eq 'Unix'
`$IsMacOS = `$PSVersionTable.PSVersion.Major -ge 6 -and `$PSVersionTable.Platform -eq 'Unix' -and (uname) -eq 'Darwin'

"@

        # Insérer la vérification de l'environnement après les paramètres
        $paramMatch = [regex]::Match($content, "(?s)^.*?param\s*\((.*?)\)", [System.Text.RegularExpressions.RegexOptions]::Singleline)
        if ($paramMatch.Success) {
            $content = $content.Insert($paramMatch.Length, "`n$environmentCheck")
        } else {
            $content = "$environmentCheck`n$content"
        }

        # Écrire le nouveau contenu dans le fichier
        Set-Content -Path $Path -Value $content -Encoding UTF8

        return $true
    }

    # Fonction principale
    function Start-EnvironmentCompatibilityImplementation {
        Write-Log "Démarrage de l'implémentation de la compatibilité entre environnements"

        # Trouver les scripts avec des problèmes de compatibilité
        $scriptsWithIssues = Find-CompatibilityIssues -Directory $ScriptsDirectory

        Write-Log "Nombre de scripts avec des problèmes de compatibilité : $($scriptsWithIssues.Count)"

        $results = @{
            Total = $scriptsWithIssues.Count
            Succeeded = 0
            Failed = 0
            Details = @()
        }

        # Standardiser la gestion des chemins dans les scripts
        foreach ($script in $scriptsWithIssues) {
            Write-Log "Traitement du script : $($script.Path)"
            Write-Log "Problèmes identifiés : $($script.Issues)" -Level "WARNING"

            try {
                $success = Update-PathHandling -Path $script.Path -CreateBackup:$CreateBackup

                if ($success) {
                    Write-Log "Compatibilité améliorée avec succès pour : $($script.Path)" -Level "INFO"
                    $results.Succeeded++
                    $results.Details += [PSCustomObject]@{
                        Path = $script.Path
                        Issues = $script.Issues
                        Status = "Success"
                        Message = "Compatibilité améliorée avec succès"
                    }
                }
                else {
                    Write-Log "Échec de l'amélioration de la compatibilité pour : $($script.Path)" -Level "ERROR"
                    $results.Failed++
                    $results.Details += [PSCustomObject]@{
                        Path = $script.Path
                        Issues = $script.Issues
                        Status = "Failed"
                        Message = "Échec de l'amélioration de la compatibilité"
                    }
                }
            }
            catch {
                Write-Log "Erreur lors du traitement du script $($script.Path) : $_" -Level "ERROR"
                $results.Failed++
                $results.Details += [PSCustomObject]@{
                    Path = $script.Path
                    Issues = $script.Issues
                    Status = "Failed"
                    Message = "Erreur : $_"
                }
            }
        }

        # Générer un rapport
        $reportPath = Join-Path -Path (Split-Path -Parent $LogFilePath) -ChildPath "environment_compatibility_report.json"
        $results | ConvertTo-Json -Depth 3 | Set-Content -Path $reportPath -Encoding UTF8

        Write-Log "Rapport généré : $reportPath"

        # Afficher un résumé
        Write-Host "`nRésumé de l'implémentation de la compatibilité entre environnements :" -ForegroundColor Cyan
        Write-Host "----------------------------------------" -ForegroundColor Cyan
        Write-Host "Scripts analysés : $($results.Total)" -ForegroundColor White
        Write-Host "Améliorations réussies : $($results.Succeeded)" -ForegroundColor Green
        Write-Host "Échecs : $($results.Failed)" -ForegroundColor Red

        return $results
    }

    # Exécuter la fonction principale
    Start-EnvironmentCompatibilityImplementation
}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
